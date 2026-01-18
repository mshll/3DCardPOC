//
//  Card3DModifiers.swift
//  3DCardPOC
//
//  Created on 2025-12-28.
//

import SwiftUI

// MARK: - SwiftUI-Style Modifiers

extension Card3DView {

    /// Sets the card's visual style.
    /// - Parameter style: The style to apply (opaque or alpha textured).
    /// - Returns: A new Card3DView with the updated style.
    func cardStyle(_ style: Card3DStyle) -> Card3DView {
        var copy = self
        copy.style = style
        return copy
    }

    /// Sets the visibility of card text elements.
    /// - Parameter visibility: The visibility configuration for card text.
    /// - Returns: A new Card3DView with the updated text visibility.
    func textVisibility(_ visibility: Card3DTextVisibility) -> Card3DView {
        var copy = self
        copy.textVisibility = visibility
        return copy
    }

    /// Sets the interaction mode for the card.
    /// - Parameter mode: The interaction mode (freeRotation, tapOnly, disabled, or custom).
    /// - Returns: A new Card3DView with the updated interaction mode.
    func interaction(_ mode: Card3DInteractionMode) -> Card3DView {
        var copy = self
        copy.interactionMode = mode
        return copy
    }

    /// Sets the scale of the 3D card in the scene.
    /// - Parameter scale: The scale factor (1.0 = normal size, 0.5 = half size, etc.).
    /// - Returns: A new Card3DView with the updated scale.
    func cardScale(_ scale: CGFloat) -> Card3DView {
        var copy = self
        copy.cardScale = scale
        return copy
    }

    /// Binds the card's rotation to an external value.
    /// - Parameter binding: A binding to the rotation angle in radians.
    /// - Returns: A new Card3DView with the updated rotation binding.
    func rotation(_ binding: Binding<Double>) -> Card3DView {
        var copy = Card3DView(
            data: data,
            style: style,
            textVisibility: textVisibility,
            interactionMode: interactionMode,
            cardScale: cardScale,
            rotation: binding
        )
        copy.xRotation = xRotation
        return copy
    }

    /// Sets the card's X-axis rotation (tilt up/down).
    /// - Parameter angle: The rotation angle in radians.
    /// - Returns: A new Card3DView with the updated X rotation.
    func xRotation(_ angle: Double) -> Card3DView {
        var copy = self
        copy.xRotation = angle
        return copy
    }

    /// Sets the animation duration for rotation and scale changes.
    /// - Parameter duration: The animation duration in seconds.
    /// - Returns: A new Card3DView with the updated animation duration.
    func animationDuration(_ duration: Double) -> Card3DView {
        var copy = self
        copy.animationDuration = duration
        return copy
    }
}

// MARK: - Convenience Initializer

extension Card3DView {

    /// Creates a Card3DView with default settings.
    /// Uses an internal rotation state when external binding is not needed.
    /// - Parameter data: The card data to display.
    init(data: Card3DData) {
        self.init(
            data: data,
            style: .opaqueTextured(design: 1),
            textVisibility: Card3DTextVisibility(),
            interactionMode: .freeRotation,
            cardScale: 1.0,
            rotation: .constant(0)
        )
    }
}
