//
//  ExpandedCardOverlay.swift
//  3DCardPOC
//

import SwiftUI
import UIKit

struct ExpandedCardOverlay: View {
    let card: CardDisplayInfo
    let sourceFrame: CGRect
    let sourceRotation: Double
    let sourceScale: CGFloat
    let onReady: () -> Void
    let onDismiss: () -> Void

    @State private var isExpanded = false
    @State private var currentRotation: Double
    @State private var currentScale: CGFloat
    @State private var isTransitioning = false

    private let haptic = UIImpactFeedbackGenerator(style: .medium)
    private let expandedScale: CGFloat = 1.1
    private let flipDuration: Double = 0.8

    init(
        card: CardDisplayInfo,
        sourceFrame: CGRect,
        sourceRotation: Double,
        sourceScale: CGFloat,
        onReady: @escaping () -> Void,
        onDismiss: @escaping () -> Void
    ) {
        self.card = card
        self.sourceFrame = sourceFrame
        self.sourceRotation = sourceRotation
        self.sourceScale = sourceScale
        self.onReady = onReady
        self.onDismiss = onDismiss
        _currentRotation = State(initialValue: sourceRotation)
        _currentScale = State(initialValue: sourceScale)
    }

    var body: some View {
        GeometryReader { screen in
            let screenFrame = screen.frame(in: .global)

            // Convert source position from global to local coordinates
            let sourceX = sourceFrame.midX - screenFrame.minX
            let sourceY = sourceFrame.midY - screenFrame.minY
            let expandedX = screen.size.width / 2
            let expandedY = screen.size.height * 0.45

            // Frame sizes - start from source, expand to larger size
            let expandedWidth = sourceFrame.width * 1.3
            let expandedHeight = sourceFrame.height * 1.3

            let currentX = isExpanded ? expandedX : sourceX
            let currentY = isExpanded ? expandedY : sourceY
            let currentWidth = isExpanded ? expandedWidth : sourceFrame.width
            let currentHeight = isExpanded ? expandedHeight : sourceFrame.height

            ZStack {
                // Dimmed background
                Color.black
                    .opacity(isExpanded ? 0.6 : 0)
                    .ignoresSafeArea()
                    .animation(.easeInOut(duration: 0.3), value: isExpanded)
                    .onTapGesture {
                        guard !isTransitioning else { return }
                        dismiss(flipBack: false)
                    }

                Card3DView(data: card.data)
                    .cardStyle(card.style)
                    .interaction(.disabled)
                    .cardScale(currentScale)
                    .xRotation(0)
                    .rotation(.constant(currentRotation))
                    .animationDuration(flipDuration)
                    .frame(width: currentWidth, height: currentHeight)
                    .position(x: currentX, y: currentY)
                    .animation(.easeInOut(duration: flipDuration), value: isExpanded)
                    .onTapGesture {
                        guard !isTransitioning else { return }
                        dismiss(flipBack: true)
                    }
            }
            .onAppear {
                haptic.prepare()
                expand()
            }
        }
        .ignoresSafeArea()
    }

    private func expand() {
        // Small delay to let overlay render at source position first
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) {
            // Hide source card now that overlay is in place
            onReady()

            isTransitioning = true
            haptic.impactOccurred()

            // Animate position with SwiftUI
            withAnimation(.easeInOut(duration: flipDuration)) {
                isExpanded = true
            }

            // Set rotation and scale directly - SceneKit will animate via animationDuration
            currentRotation = .pi
            currentScale = expandedScale

            DispatchQueue.main.asyncAfter(deadline: .now() + flipDuration) {
                isTransitioning = false
            }
        }
    }

    private func dismiss(flipBack: Bool) {
        isTransitioning = true
        haptic.impactOccurred()

        let dismissDuration = flipDuration * 0.85

        // Animate position with SwiftUI
        withAnimation(.easeInOut(duration: dismissDuration)) {
            isExpanded = false
        }

        // Set rotation and scale directly - SceneKit will animate
        if flipBack {
            currentRotation = sourceRotation
        }
        currentScale = sourceScale

        // Extra buffer to ensure animation fully completes before removal
        DispatchQueue.main.asyncAfter(deadline: .now() + dismissDuration + 0.1) {
            onDismiss()
        }
    }
}
