//
//  Card3DLighting.swift
//  3DCardPOC
//
//  Created on 2025-12-28.
//

import SceneKit

/// Handles lighting and camera setup for 3D card scenes.
/// 3-point lighting for depth and dimension.
enum Card3DLighting {

    // MARK: - Camera Constants

    private static let cameraFieldOfView: CGFloat = 45
    private static let cameraPosition = SCNVector3(0, 0, 13)

    // MARK: - Setup Functions

    /// Configures 3-point lighting for the 3D card scene.
    /// - Parameter scene: The SceneKit scene to add lights to.
    static func setup(in scene: SCNScene) {
        // Ambient - soft base fill
        let ambientLight = SCNLight()
        ambientLight.type = .ambient
        ambientLight.intensity = 100
        ambientLight.color = UIColor(white: 0.98, alpha: 1.0)
        let ambientNode = SCNNode()
        ambientNode.light = ambientLight
        scene.rootNode.addChildNode(ambientNode)

        // Key light - front-left-above
        let keyLight = SCNLight()
        keyLight.type = .omni
        keyLight.intensity = 550
        keyLight.color = UIColor.white
        let keyNode = SCNNode()
        keyNode.light = keyLight
        keyNode.position = SCNVector3(-6, 5, 8)
        scene.rootNode.addChildNode(keyNode)

        // Fill light - front-right-center
        let fillLight = SCNLight()
        fillLight.type = .omni
        fillLight.intensity = 400
        fillLight.color = UIColor(white: 0.95, alpha: 1.0)
        let fillNode = SCNNode()
        fillNode.light = fillLight
        fillNode.position = SCNVector3(5, 0, 7)
        scene.rootNode.addChildNode(fillNode)

        // Back light - behind card for rim/edge separation
        let backLight = SCNLight()
        backLight.type = .omni
        backLight.intensity = 500
        backLight.color = UIColor(white: 0.9, alpha: 1.0)
        let backNode = SCNNode()
        backNode.light = backLight
        backNode.position = SCNVector3(0, 3, -5)
        scene.rootNode.addChildNode(backNode)
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
