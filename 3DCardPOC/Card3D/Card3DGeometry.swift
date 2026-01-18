//
//  Card3DGeometry.swift
//  3DCardPOC
//
//  Card shape building for 3D credit card rendering.
//  Handles geometry creation only - no materials or textures.
//

import SceneKit
import UIKit

/// Card geometry configuration and shape building.
/// Credit card standard: 85.6mm x 53.98mm (~1.585:1 aspect ratio)
enum Card3DGeometry {

    // MARK: - Dimensions

    /// Card width in SceneKit units (portrait orientation)
    static let width: CGFloat = 5.0

    /// Card height in SceneKit units (portrait orientation)
    static let height: CGFloat = 8.0

    /// Card thickness (extrusion depth)
    static let thickness: CGFloat = 0.056

    /// Corner radius for rounded rectangle
    static let cornerRadius: CGFloat = 0.6

    /// Chamfer radius for edge smoothing
    static let chamferRadius: CGFloat = 0.005

    /// Path flatness for smoother corner rendering
    static let pathFlatness: CGFloat = 0.01

    // MARK: - Geometry Creation

    /// Creates the extruded card shape geometry.
    /// - Returns: An SCNGeometry representing the 3D card shape with rounded corners and chamfered edges.
    static func createCardShape() -> SCNGeometry {
        // Create rounded rectangle path centered at origin
        let rect = CGRect(
            x: -width / 2,
            y: -height / 2,
            width: width,
            height: height
        )
        let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

        // Flatten path for smoother corner segments
        path.flatness = pathFlatness

        // Create extruded shape from path (extrudes along Z-axis)
        let cardGeometry = SCNShape(path: path, extrusionDepth: thickness)

        // Apply chamfer for smooth edges
        cardGeometry.chamferRadius = chamferRadius
        cardGeometry.chamferProfile = createChamferProfile()

        return cardGeometry
    }

    // MARK: - Chamfer Profile

    /// Creates a smooth bezier curve for the chamfer profile.
    /// The profile defines how the edge transitions from the face to the side.
    /// - Returns: A UIBezierPath representing the chamfer curve from (0,0) to (1,1).
    static func createChamferProfile() -> UIBezierPath {
        let chamferPath = UIBezierPath()

        // Start at origin
        chamferPath.move(to: CGPoint(x: 0, y: 0))

        // Smooth S-curve from (0,0) to (1,1) for a refined edge appearance
        chamferPath.addCurve(
            to: CGPoint(x: 1, y: 1),
            controlPoint1: CGPoint(x: 0.3, y: 0),
            controlPoint2: CGPoint(x: 0.7, y: 1)
        )

        return chamferPath
    }
}
