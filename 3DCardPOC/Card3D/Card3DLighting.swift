//
//  Card3DLighting.swift
//  3DCardPOC
//
//  Created on 2025-12-28.
//

import SceneKit

/// Handles lighting and camera setup for 3D card scenes.
/// Clean, minimal Apple-style lighting for product shots.
enum Card3DLighting {

    // MARK: - Lighting Constants

    private static let ambientIntensity: CGFloat = 200
    private static let ambientColor = UIColor(white: 0.98, alpha: 1.0)

    private static let directionalIntensity: CGFloat = 600
    private static let directionalPosition = SCNVector3(0, 5, 10)
    private static let directionalAngle: Float = -.pi / 6

    // MARK: - Camera Constants

    private static let cameraFieldOfView: CGFloat = 45
    private static let cameraPosition = SCNVector3(0, 0, 13)

    // MARK: - Setup Functions

    /// Configures lighting for the 3D card scene.
    /// - Parameter scene: The SceneKit scene to add lights to.
    static func setup(in scene: SCNScene) {
        // Ambient light - soft fill
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = ambientIntensity
        ambientLight.color = ambientColor

        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)

        // Directional light - main light from front-above
        let directionalLight = SCNLight()
        directionalLight.type = .directional
        directionalLight.intensity = directionalIntensity
        directionalLight.color = UIColor.white
        directionalLight.castsShadow = false

        let directionalNode = SCNNode()
        directionalNode.light = directionalLight
        directionalNode.position = directionalPosition
        directionalNode.eulerAngles.x = directionalAngle
        scene.rootNode.addChildNode(directionalNode)
    }

    /// Configures the camera for the 3D card scene.
    /// - Parameter scene: The SceneKit scene to add the camera to.
    static func setupCamera(in scene: SCNScene) {
        let camera = SCNCamera()
        camera.fieldOfView = cameraFieldOfView

        let cameraNode = SCNNode()
        cameraNode.camera = camera
        cameraNode.position = cameraPosition
        scene.rootNode.addChildNode(cameraNode)
    }
}
