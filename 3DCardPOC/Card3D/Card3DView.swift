//
//  Card3DView.swift
//  3DCardPOC
//
//  Created on 2025-12-28.
//

import SceneKit
import SwiftUI

// MARK: - Interaction Mode

enum Card3DInteractionMode {
    case freeRotation
    case tapOnly
    case disabled
    case custom(Card3DInteractionHandler)
}

// MARK: - Interaction Protocol

protocol Card3DInteractionHandler {
    func attach(to sceneView: SCNView, cardNode: SCNNode, coordinator: Card3DView.Coordinator)
    func detach()
}

// MARK: - Card3DView

struct Card3DView: UIViewRepresentable {
    let data: Card3DData
    var style: Card3DStyle = .opaqueTextured(design: 1)
    var textVisibility: Card3DTextVisibility = .init()
    var interactionMode: Card3DInteractionMode = .freeRotation
    @Binding var rotation: Double

    // MARK: - UIViewRepresentable

    func makeUIView(context: Context) -> SCNView {
        let sceneView = SCNView()

        // Configure SCNView properties
        sceneView.backgroundColor = .clear
        sceneView.antialiasingMode = .multisampling4X
        sceneView.autoenablesDefaultLighting = false
        sceneView.allowsCameraControl = false

        // Build scene using Card3DScene
        let (scene, cardNode) = Card3DScene.build(
            data: data,
            style: style,
            textVisibility: textVisibility
        )

        // Apply initial rotation
        cardNode.eulerAngles.y = Float(rotation)

        sceneView.scene = scene

        // Store references in coordinator
        context.coordinator.cardNode = cardNode
        context.coordinator.sceneView = sceneView

        // Attach interaction handler
        attachInteractionHandler(to: sceneView, cardNode: cardNode, coordinator: context.coordinator)

        return sceneView
    }

    func updateUIView(_ uiView: SCNView, context: Context) {
        let coordinator = context.coordinator

        // Check if we need to rebuild the scene (data, style, or visibility changed)
        let needsRebuild = coordinator.previousData != data ||
                          coordinator.previousStyle != style ||
                          coordinator.previousTextVisibility != textVisibility

        if needsRebuild {
            rebuildScene(in: uiView, coordinator: coordinator)
        } else {
            // Just update rotation if changed externally
            guard let cardNode = coordinator.cardNode else { return }
            let currentRotation = Double(cardNode.eulerAngles.y)
            if abs(currentRotation - rotation) > 0.01 {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = 0.1
                cardNode.eulerAngles.y = Float(rotation)
                SCNTransaction.commit()
            }
        }
    }

    private func rebuildScene(in sceneView: SCNView, coordinator: Coordinator) {
        // Detach old interaction handler
        coordinator.interactionHandler?.detach()

        // Build new scene
        let (scene, cardNode) = Card3DScene.build(
            data: data,
            style: style,
            textVisibility: textVisibility
        )

        // Apply current rotation
        cardNode.eulerAngles.y = Float(rotation)

        // Update scene
        sceneView.scene = scene

        // Update coordinator references
        coordinator.cardNode = cardNode
        coordinator.previousData = data
        coordinator.previousStyle = style
        coordinator.previousTextVisibility = textVisibility

        // Reattach interaction handler
        attachInteractionHandler(to: sceneView, cardNode: cardNode, coordinator: coordinator)
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    // MARK: - Private Helpers

    private func attachInteractionHandler(to sceneView: SCNView, cardNode: SCNNode, coordinator: Coordinator) {
        switch interactionMode {
        case .freeRotation:
            let handler = FreeRotationHandler()
            handler.attach(to: sceneView, cardNode: cardNode, coordinator: coordinator)
            coordinator.interactionHandler = handler

        case .tapOnly:
            let handler = TapOnlyHandler()
            handler.attach(to: sceneView, cardNode: cardNode, coordinator: coordinator)
            coordinator.interactionHandler = handler

        case .disabled:
            // No interaction
            break

        case .custom(let handler):
            handler.attach(to: sceneView, cardNode: cardNode, coordinator: coordinator)
            coordinator.interactionHandler = handler
        }
    }

    // MARK: - Coordinator

    class Coordinator: NSObject {
        var parent: Card3DView
        weak var cardNode: SCNNode?
        weak var sceneView: SCNView?
        var interactionHandler: Card3DInteractionHandler?

        // Track previous values to detect changes
        var previousData: Card3DData
        var previousStyle: Card3DStyle
        var previousTextVisibility: Card3DTextVisibility

        // Flip state
        var isShowingBack = false

        // Haptic generators
        let lightHaptic = UIImpactFeedbackGenerator(style: .light)
        let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
        let softHaptic = UIImpactFeedbackGenerator(style: .soft)

        init(_ parent: Card3DView) {
            self.parent = parent
            self.previousData = parent.data
            self.previousStyle = parent.style
            self.previousTextVisibility = parent.textVisibility
            super.init()
            prepareHaptics()
        }

        func prepareHaptics() {
            lightHaptic.prepare()
            mediumHaptic.prepare()
            softHaptic.prepare()
        }

        func updateRotation(_ newRotation: Double) {
            parent.rotation = newRotation
        }
    }
}

// MARK: - FreeRotationHandler

final class FreeRotationHandler: Card3DInteractionHandler {
    private weak var sceneView: SCNView?
    private weak var cardNode: SCNNode?
    private weak var coordinator: Card3DView.Coordinator?

    private var panGesture: UIPanGestureRecognizer?
    private var tapGesture: UITapGestureRecognizer?

    private var initialRotationY: Float = 0
    private var initialRotationX: Float = 0

    private let maxVerticalTilt: Float = 0.15
    private let verticalDamping: Float = 0.4

    func attach(to sceneView: SCNView, cardNode: SCNNode, coordinator: Card3DView.Coordinator) {
        self.sceneView = sceneView
        self.cardNode = cardNode
        self.coordinator = coordinator

        let pan = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        sceneView.addGestureRecognizer(pan)
        panGesture = pan

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        tap.require(toFail: pan)
        sceneView.addGestureRecognizer(tap)
        tapGesture = tap
    }

    func detach() {
        if let pan = panGesture {
            sceneView?.removeGestureRecognizer(pan)
        }
        if let tap = tapGesture {
            sceneView?.removeGestureRecognizer(tap)
        }
    }

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let cardNode = cardNode, let coordinator = coordinator else { return }

        let translation = gesture.translation(in: sceneView)
        let rotationSpeed: Float = 0.012

        switch gesture.state {
        case .began:
            initialRotationY = cardNode.eulerAngles.y
            initialRotationX = cardNode.eulerAngles.x
            coordinator.softHaptic.impactOccurred(intensity: 0.8)

        case .changed:
            let newRotationY = initialRotationY + Float(translation.x) * rotationSpeed
            let rawRotationX = initialRotationX - Float(translation.y) * rotationSpeed * verticalDamping
            let newRotationX = max(-maxVerticalTilt, min(maxVerticalTilt, rawRotationX))

            SCNTransaction.begin()
            SCNTransaction.animationDuration = 0.08
            cardNode.eulerAngles.y = newRotationY
            cardNode.eulerAngles.x = newRotationX
            SCNTransaction.commit()

            coordinator.updateRotation(Double(newRotationY))

        case .ended, .cancelled:
            coordinator.softHaptic.impactOccurred(intensity: 0.8)

        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let cardNode = cardNode, let coordinator = coordinator else { return }

        coordinator.isShowingBack.toggle()
        coordinator.mediumHaptic.impactOccurred(intensity: 0.8)

        let targetY: Float = coordinator.isShowingBack ? .pi : 0

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.35, 0.64, 1.0)
        cardNode.eulerAngles.y = targetY
        cardNode.eulerAngles.x = 0
        SCNTransaction.commit()

        coordinator.updateRotation(Double(targetY))
    }
}

// MARK: - TapOnlyHandler

final class TapOnlyHandler: Card3DInteractionHandler {
    private weak var sceneView: SCNView?
    private weak var cardNode: SCNNode?
    private weak var coordinator: Card3DView.Coordinator?

    private var tapGesture: UITapGestureRecognizer?

    func attach(to sceneView: SCNView, cardNode: SCNNode, coordinator: Card3DView.Coordinator) {
        self.sceneView = sceneView
        self.cardNode = cardNode
        self.coordinator = coordinator

        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        sceneView.addGestureRecognizer(tap)
        tapGesture = tap
    }

    func detach() {
        if let tap = tapGesture {
            sceneView?.removeGestureRecognizer(tap)
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let cardNode = cardNode, let coordinator = coordinator else { return }

        coordinator.isShowingBack.toggle()
        coordinator.mediumHaptic.impactOccurred(intensity: 0.8)

        let targetY: Float = coordinator.isShowingBack ? .pi : 0

        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.5
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.34, 1.35, 0.64, 1.0)
        cardNode.eulerAngles.y = targetY
        cardNode.eulerAngles.x = 0
        SCNTransaction.commit()

        coordinator.updateRotation(Double(targetY))
    }
}
