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

    /// Simple type identifier for comparison (ignores associated values)
    var modeType: Int {
        switch self {
        case .freeRotation: return 0
        case .tapOnly: return 1
        case .disabled: return 2
        case .custom: return 3
        }
    }
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
    var cardScale: CGFloat = 1.0
    @Binding var rotation: Double
    var xRotation: Double = 0
    var animationDuration: Double = 0.15

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

        // Apply initial rotation and scale
        cardNode.eulerAngles.y = Float(rotation)
        cardNode.eulerAngles.x = Float(xRotation)
        let scale = Float(cardScale)
        cardNode.scale = SCNVector3(scale, scale, scale)

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

        // Update parent reference so coordinator stays in sync
        coordinator.parent = self

        // Check if we need to rebuild the scene (data, style, or visibility changed)
        let needsRebuild = coordinator.previousData != data ||
                          coordinator.previousStyle != style ||
                          coordinator.previousTextVisibility != textVisibility

        // Check if interaction mode changed
        let interactionModeChanged = coordinator.previousInteractionModeType != interactionMode.modeType

        if needsRebuild {
            rebuildScene(in: uiView, coordinator: coordinator)
            coordinator.previousInteractionModeType = interactionMode.modeType
        } else if interactionModeChanged {
            // Just update interaction handler without rebuilding scene
            coordinator.interactionHandler?.detach()
            coordinator.interactionHandler = nil
            if let cardNode = coordinator.cardNode {
                attachInteractionHandler(to: uiView, cardNode: cardNode, coordinator: coordinator)
            }
            coordinator.previousInteractionModeType = interactionMode.modeType
        } else {
            // Just update rotation if changed externally
            guard let cardNode = coordinator.cardNode else { return }
            let currentRotationY = Double(cardNode.eulerAngles.y)
            let currentRotationX = Double(cardNode.eulerAngles.x)
            let currentScale = Double(cardNode.scale.x)

            let needsUpdate = abs(currentRotationY - rotation) > 0.001 ||
                              abs(currentRotationX - xRotation) > 0.001 ||
                              abs(currentScale - cardScale) > 0.001

            if needsUpdate {
                SCNTransaction.begin()
                SCNTransaction.animationDuration = animationDuration
                SCNTransaction.animationTimingFunction = CAMediaTimingFunction(controlPoints: 0.25, 0.1, 0.25, 1.0)
                cardNode.eulerAngles.y = Float(rotation)
                cardNode.eulerAngles.x = Float(xRotation)
                let scale = Float(cardScale)
                cardNode.scale = SCNVector3(scale, scale, scale)
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

        // Apply current rotation and scale
        cardNode.eulerAngles.y = Float(rotation)
        cardNode.eulerAngles.x = Float(xRotation)
        let scale = Float(cardScale)
        cardNode.scale = SCNVector3(scale, scale, scale)

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
        var previousInteractionModeType: Int

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
            self.previousInteractionModeType = parent.interactionMode.modeType
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

    // Inertia properties
    private var displayLink: CADisplayLink?
    private var velocityY: Float = 0
    private var velocityX: Float = 0
    private let decelerationRate: Float = 0.95
    private let minimumVelocity: Float = 0.001
    private let velocityScale: Float = 0.00002

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
        stopInertia()
        if let pan = panGesture {
            sceneView?.removeGestureRecognizer(pan)
        }
        if let tap = tapGesture {
            sceneView?.removeGestureRecognizer(tap)
        }
    }

    // MARK: - Inertia

    private func startInertia() {
        stopInertia()
        let link = CADisplayLink(target: self, selector: #selector(updateInertia))
        link.add(to: .main, forMode: .common)
        displayLink = link
    }

    private func stopInertia() {
        displayLink?.invalidate()
        displayLink = nil
        velocityY = 0
        velocityX = 0
    }

    @objc private func updateInertia() {
        guard let cardNode = cardNode, let coordinator = coordinator else {
            stopInertia()
            return
        }

        // Apply velocity
        cardNode.eulerAngles.y += velocityY
        let newX = cardNode.eulerAngles.x + velocityX
        cardNode.eulerAngles.x = max(-maxVerticalTilt, min(maxVerticalTilt, newX))

        coordinator.updateRotation(Double(cardNode.eulerAngles.y))

        // Apply deceleration
        velocityY *= decelerationRate
        velocityX *= decelerationRate

        // Stop when velocity is negligible
        if abs(velocityY) < minimumVelocity && abs(velocityX) < minimumVelocity {
            stopInertia()
        }
    }

    // MARK: - Gestures

    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let cardNode = cardNode, let coordinator = coordinator else { return }

        let translation = gesture.translation(in: sceneView)
        let rotationSpeed: Float = 0.012

        switch gesture.state {
        case .began:
            stopInertia()
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
            let velocity = gesture.velocity(in: sceneView)
            velocityY = Float(velocity.x) * velocityScale
            velocityX = -Float(velocity.y) * velocityScale * verticalDamping

            if abs(velocityY) > minimumVelocity || abs(velocityX) > minimumVelocity {
                startInertia()
            }

            coordinator.softHaptic.impactOccurred(intensity: 0.8)

        default:
            break
        }
    }

    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let cardNode = cardNode, let coordinator = coordinator else { return }

        stopInertia()
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
