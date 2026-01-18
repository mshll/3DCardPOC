//
//  Card3DScene.swift
//  3DCardPOC
//
//  Scene assembly for 3D credit card.
//

import SceneKit
import UIKit

/// Assembles the complete SceneKit scene for a 3D credit card.
/// Combines geometry, materials, lighting, and text nodes into a ready-to-render scene.
enum Card3DScene {

    // MARK: - Text Alignment

    enum TextAlignment {
        case left
        case center
        case right
    }

    enum VerticalAlignment {
        case top
        case center
        case bottom
    }

    // MARK: - Scene Building

    /// Builds a complete 3D card scene with all components assembled.
    /// - Parameters:
    ///   - data: Card data (number, name, expiry, cvv)
    ///   - style: Visual style configuration
    ///   - textVisibility: Which text elements to show
    /// - Returns: Tuple containing the scene and a reference to the card node for interaction
    static func build(
        data: Card3DData,
        style: Card3DStyle,
        textVisibility: Card3DTextVisibility
    ) -> (scene: SCNScene, cardNode: SCNNode) {
        let scene = SCNScene()

        // Setup lighting
        Card3DLighting.setup(in: scene)
        Card3DLighting.setupCamera(in: scene)

        // Create card geometry
        let cardGeometry = Card3DGeometry.createCardShape()

        // Apply materials based on style
        let materialSet = Card3DMaterials.build(style: style)
        cardGeometry.materials = [materialSet.front, materialSet.back, materialSet.edge, materialSet.edge, materialSet.edge]

        // Create the card node
        let cardShapeNode = SCNNode(geometry: cardGeometry)
        cardShapeNode.position = SCNVector3(0, 0, 0)

        // Create container node for the card
        let containerNode = SCNNode()
        containerNode.name = "creditCard"
        containerNode.addChildNode(cardShapeNode)

        // Add text nodes on the back of the card
        addTextNodes(
            to: containerNode,
            data: data,
            visibility: textVisibility,
            cardThickness: Float(Card3DGeometry.thickness)
        )

        scene.rootNode.addChildNode(containerNode)

        return (scene: scene, cardNode: containerNode)
    }

    // MARK: - Text Node Creation

    /// Adds all text nodes to the card based on visibility settings.
    private static func addTextNodes(
        to cardNode: SCNNode,
        data: Card3DData,
        visibility: Card3DTextVisibility,
        cardThickness: Float
    ) {
        // Text is positioned on the back face of the card
        // Back face is at negative Z (facing away from camera initially)
        let backZPosition = -cardThickness / 2 - 0.01

        // Card number (4 lines, one segment per line) - positioned near top for vertical card
        if visibility.cardNumber {
            let cardNumberParts = data.cardNumber.split(separator: " ")
            let lineSpacing: Float = 0.6
            let startY: Float = 3.35

            for (index, segment) in cardNumberParts.enumerated() {
                let lineNode = createTextNode(
                    text: String(segment),
                    fontSize: 0.45,
                    color: .white,
                    alignment: .left,
                    fontName: "Menlo-Bold"
                )
                lineNode.name = "cardNumberLine\(index + 1)"
                lineNode.position = SCNVector3(x: 1.95, y: startY - Float(index) * lineSpacing, z: backZPosition)
                lineNode.eulerAngles.y = .pi
                cardNode.addChildNode(lineNode)
            }
        }

        // Cardholder name (on back, near bottom) - adjusted for vertical card
        if visibility.cardholderName {
            let nameNode = createTextNode(
                text: data.cardholderName.uppercased(),
                fontSize: 0.28,
                color: .white,
                alignment: .left
            )
            nameNode.name = "cardholderName"
            nameNode.position = SCNVector3(x: 2.1, y: -3.2, z: backZPosition)
            nameNode.eulerAngles.y = .pi
            cardNode.addChildNode(nameNode)
        }

        // Expiry and CVV (on back, below card number) - no labels, just values
        if visibility.expiryDate || visibility.cvv {
            let expiryCvcNode = createExpiryCvcNode(
                expiryDate: data.expiryDate,
                cvv: data.cvv,
                showExpiry: visibility.expiryDate,
                showCvv: visibility.cvv
            )
            expiryCvcNode.name = "expiryCvc"
            expiryCvcNode.position = SCNVector3(x: 1.1, y: 0.85, z: backZPosition)
            expiryCvcNode.eulerAngles.y = .pi
            cardNode.addChildNode(expiryCvcNode)
        }
    }

    /// Creates a compound node containing expiry and CVV values (no labels).
    private static func createExpiryCvcNode(
        expiryDate: String,
        cvv: String,
        showExpiry: Bool,
        showCvv: Bool
    ) -> SCNNode {
        let containerNode = SCNNode()

        let lineSpacing: Float = 0.4

        if showExpiry {
            let expValue = createTextNode(
                text: expiryDate,
                fontSize: 0.28,
                color: .white,
                alignment: .left,
                verticalAlignment: .center,
                fontName: "Menlo-Bold"
            )
            expValue.name = "expiryValue"
            expValue.position = SCNVector3(x: 0, y: lineSpacing, z: 0)
            containerNode.addChildNode(expValue)
        }

        if showCvv {
            let cvcValue = createTextNode(
                text: cvv,
                fontSize: 0.28,
                color: .white,
                alignment: .left,
                verticalAlignment: .center,
                fontName: "Menlo-Bold"
            )
            cvcValue.name = "cvvValue"
            cvcValue.position = SCNVector3(x: 0, y: 0, z: 0)
            containerNode.addChildNode(cvcValue)
        }

        return containerNode
    }

    /// Creates a single text node with configurable font, color, and alignment.
    /// - Parameters:
    ///   - text: The text string to display
    ///   - fontSize: Font size in scene units
    ///   - color: Text color
    ///   - alignment: Horizontal alignment (affects pivot point)
    ///   - verticalAlignment: Vertical alignment (affects pivot point)
    ///   - fontName: Optional custom font name (e.g., "Menlo-Bold" for monospace)
    /// - Returns: Configured SCNNode containing SCNText geometry
    static func createTextNode(
        text: String,
        fontSize: CGFloat,
        color: UIColor,
        alignment: TextAlignment = .center,
        verticalAlignment: VerticalAlignment = .bottom,
        fontName: String? = nil
    ) -> SCNNode {
        let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
        if let fontName = fontName, let customFont = UIFont(name: fontName, size: fontSize) {
            textGeometry.font = customFont
        } else {
            textGeometry.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
        }
        textGeometry.firstMaterial?.diffuse.contents = color
        textGeometry.firstMaterial?.specular.contents = UIColor.white
        textGeometry.firstMaterial?.shininess = 0.1
        textGeometry.flatness = 0.1

        let textNode = SCNNode(geometry: textGeometry)

        // Calculate bounding box for alignment
        let (min, max) = textNode.boundingBox

        // Horizontal alignment pivot
        let dx: Float
        switch alignment {
        case .left:
            dx = min.x
        case .center:
            dx = (min.x + max.x) / 2
        case .right:
            dx = max.x
        }

        // Vertical alignment pivot
        let dy: Float
        switch verticalAlignment {
        case .top:
            dy = max.y
        case .center:
            dy = (min.y + max.y) / 2
        case .bottom:
            dy = min.y
        }

        textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)

        return textNode
    }

    // MARK: - Text Update Helpers

    /// Updates text nodes in an existing scene with new data.
    /// Useful for reactive updates without rebuilding the entire scene.
    static func updateTextNodes(
        in cardNode: SCNNode,
        data: Card3DData,
        visibility: Card3DTextVisibility
    ) {
        // Update card number
        if visibility.cardNumber {
            let cardNumberParts = data.cardNumber.split(separator: " ")
            let firstLine = cardNumberParts.prefix(2).joined(separator: "  ")
            let secondLine = cardNumberParts.suffix(from: min(2, cardNumberParts.count)).joined(separator: "  ")

            if let line1Node = cardNode.childNode(withName: "cardNumberLine1", recursively: true),
               let textGeometry = line1Node.geometry as? SCNText {
                textGeometry.string = firstLine
            }

            if let line2Node = cardNode.childNode(withName: "cardNumberLine2", recursively: true),
               let textGeometry = line2Node.geometry as? SCNText {
                textGeometry.string = secondLine
            }
        }

        // Update cardholder name
        if visibility.cardholderName {
            if let nameNode = cardNode.childNode(withName: "cardholderName", recursively: true),
               let textGeometry = nameNode.geometry as? SCNText {
                textGeometry.string = data.cardholderName.uppercased()
            }
        }

        // Update expiry and CVV
        if let expiryCvcNode = cardNode.childNode(withName: "expiryCvc", recursively: true) {
            if visibility.expiryDate,
               let expiryNode = expiryCvcNode.childNode(withName: "expiryValue", recursively: false),
               let textGeometry = expiryNode.geometry as? SCNText {
                textGeometry.string = data.expiryDate
            }

            if visibility.cvv,
               let cvvNode = expiryCvcNode.childNode(withName: "cvvValue", recursively: false),
               let textGeometry = cvvNode.geometry as? SCNText {
                textGeometry.string = data.cvv
            }
        }
    }
}
