import SceneKit
import UIKit
import SwiftUI

// MARK: - Material Set

/// Holds the complete set of materials for a 3D card
struct Card3DMaterialSet {
    let front: SCNMaterial
    let back: SCNMaterial
    let edge: SCNMaterial
}

// MARK: - Materials Builder

enum Card3DMaterials {

    // MARK: - PBR Constants

    private static let metalness: CGFloat = 0.1
    private static let shininess: CGFloat = 0.15

    // MARK: - Public API

    /// Builds a complete material set for the given card style
    static func build(style: Card3DStyle) -> Card3DMaterialSet {
        switch style {
        case .opaqueTextured(let design):
            return buildOpaqueMaterials(design: design)

        case .alphaTextured(let design, let backgroundColor):
            return buildAlphaMaterials(design: design, backgroundColor: backgroundColor)
        }
    }

    // MARK: - Opaque Textured Materials

    private static func buildOpaqueMaterials(design: Int) -> Card3DMaterialSet {
        let frontTexture = UIImage(named: "\(design)_front-min")
        let backTexture = UIImage(named: "\(design)_back-min")
        let frontRoughness = UIImage(named: "\(design)_front_roughness-min")
        let backRoughness = UIImage(named: "\(design)_back_roughness-min")

        let frontMaterial = createPBRMaterial(
            diffuse: frontTexture,
            roughness: frontRoughness
        )

        let backMaterial = createPBRMaterial(
            diffuse: backTexture,
            roughness: backRoughness
        )

        // Extract dominant color from front texture for edge, fallback to dark gray
        let edgeColor = frontTexture?.dominantEdgeColor ?? UIColor.darkGray
        let edgeMaterial = createSolidMaterial(color: edgeColor)

        return Card3DMaterialSet(front: frontMaterial, back: backMaterial, edge: edgeMaterial)
    }

    // MARK: - Alpha Textured Materials

    private static func buildAlphaMaterials(design: Int, backgroundColor: Color) -> Card3DMaterialSet {
        let frontAlpha = UIImage(named: "\(design)_front_alpha-min")
        let backAlpha = UIImage(named: "\(design)_back_alpha-min")
        let frontRoughness = UIImage(named: "\(design)_front_roughness-min")
        let backRoughness = UIImage(named: "\(design)_back_roughness-min")

        let uiBackgroundColor = UIColor(backgroundColor)

        // Composite alpha textures over background color
        let frontComposite = compositeTexture(alphaTexture: frontAlpha, backgroundColor: uiBackgroundColor)
        let backComposite = compositeTexture(alphaTexture: backAlpha, backgroundColor: uiBackgroundColor)

        let frontMaterial = createPBRMaterial(
            diffuse: frontComposite,
            roughness: frontRoughness
        )

        let backMaterial = createPBRMaterial(
            diffuse: backComposite,
            roughness: backRoughness
        )

        let edgeMaterial = createSolidMaterial(color: uiBackgroundColor)

        return Card3DMaterialSet(front: frontMaterial, back: backMaterial, edge: edgeMaterial)
    }

    // MARK: - PBR Material Creation

    private static func createPBRMaterial(diffuse: UIImage?, roughness: UIImage?) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased

        material.diffuse.contents = diffuse
        material.roughness.contents = roughness
        material.metalness.contents = metalness
        material.shininess = shininess

        material.isDoubleSided = false

        return material
    }

    private static func createSolidMaterial(color: UIColor) -> SCNMaterial {
        let material = SCNMaterial()
        material.lightingModel = .physicallyBased

        material.diffuse.contents = color
        material.metalness.contents = metalness
        material.roughness.contents = 0.5
        material.shininess = shininess

        return material
    }

    // MARK: - Texture Compositing

    /// Composites an alpha texture over a solid background color
    private static func compositeTexture(alphaTexture: UIImage?, backgroundColor: UIColor) -> UIImage? {
        guard let alphaTexture = alphaTexture else {
            // Return solid color image if no alpha texture
            return createSolidColorImage(color: backgroundColor, size: CGSize(width: 512, height: 512))
        }

        let size = alphaTexture.size
        let renderer = UIGraphicsImageRenderer(size: size)

        return renderer.image { context in
            // Draw background color
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw alpha texture on top
            alphaTexture.draw(in: CGRect(origin: .zero, size: size))
        }
    }

    private static func createSolidColorImage(color: UIColor, size: CGSize) -> UIImage {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            color.setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }
}

// MARK: - UIImage Extension for Dominant Color

private extension UIImage {
    /// Extracts a dominant color from the edge of the image for seamless edge material
    var dominantEdgeColor: UIColor? {
        guard let cgImage = self.cgImage else { return nil }

        // Sample from left edge center
        let width = cgImage.width
        let height = cgImage.height

        guard width > 0, height > 0 else { return nil }

        // Create a 1x1 context to sample the edge pixel
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        var pixelData: [UInt8] = [0, 0, 0, 0]

        guard let context = CGContext(
            data: &pixelData,
            width: 1,
            height: 1,
            bitsPerComponent: 8,
            bytesPerRow: 4,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
        ) else { return nil }

        // Sample from left edge, center vertically
        let sampleX = 2
        let sampleY = height / 2

        context.draw(
            cgImage,
            in: CGRect(x: -sampleX, y: -sampleY, width: width, height: height)
        )

        let red = CGFloat(pixelData[0]) / 255.0
        let green = CGFloat(pixelData[1]) / 255.0
        let blue = CGFloat(pixelData[2]) / 255.0

        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
}
