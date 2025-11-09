//
//  CardTemplate.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import SwiftUI

enum CardTemplate: String, CaseIterable, Hashable {
    case premium = "Premium"
    case platinum = "Platinum"
    case pro = "Pro"

    var pattern: CardPattern {
        switch self {
        case .premium:
            return .imageWithColor(
                "pattern_02",
                Color(red: 0.05, green: 0.05, blue: 0.1)
            )
        case .platinum:
            return .gradient(
                colors: [
                    Color(red: 0.3, green: 0.3, blue: 0.35),
                    Color(red: 0.5, green: 0.5, blue: 0.55)
                ],
                type: .linear(startPoint: .top, endPoint: .bottom)
            )
        case .pro:
            return .imageWithColor(
                "pattern_01",
                Color(red: 0.05, green: 0.05, blue: 0.1)
            )
        }
    }

    var textColor: Color {
        switch self {
        case .premium:
            return .white
        case .platinum:
            return .white
        case .pro:
            return Color(red: 0.9, green: 0.8, blue: 0.5)
        }
    }

    var cardNetwork: CardNetwork {
        switch self {
        case .premium:
            return .visa
        case .platinum:
            return .mastercard
        case .pro:
            return .visa
        }
    }
}

enum CardPattern {
    case solid(Color)
    case gradient(colors: [Color], type: GradientType)
    case image(String) // Asset name
    case imageWithColor(String, Color) // Asset name with background color

    enum GradientType {
        case linear(startPoint: UnitPoint, endPoint: UnitPoint)
        case radial
    }

    // Convert to UIColor for SceneKit
    func toUIColor() -> UIColor {
        switch self {
        case .solid(let color):
            return UIColor(color)
        case .gradient(let colors, _):
            // For gradients, return the first color as base
            // We'll create a gradient image for the texture
            return UIColor(colors.first ?? .blue)
        case .image(_):
            // For images, return a default color
            return UIColor.gray
        case .imageWithColor(_, let color):
            return UIColor(color)
        }
    }

    // Create a UIImage for texture mapping
    func toImage(size: CGSize = CGSize(width: 512, height: 812)) -> UIImage? {
        switch self {
        case .solid(let color):
            return createSolidColorImage(color: color, size: size)
        case .gradient(let colors, let type):
            return createGradientImage(colors: colors, type: type, size: size)
        case .image(let assetName):
            return UIImage(named: assetName)
        case .imageWithColor(let assetName, let color):
            return createImageWithColorBackground(imageName: assetName, backgroundColor: color, size: size)
        }
    }

    private func createSolidColorImage(color: Color, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            UIColor(color).setFill()
            context.fill(CGRect(origin: .zero, size: size))
        }
    }

    private func createGradientImage(colors: [Color], type: GradientType, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            let cgColors = colors.map { UIColor($0).cgColor }
            guard let gradient = CGGradient(
                colorsSpace: CGColorSpaceCreateDeviceRGB(),
                colors: cgColors as CFArray,
                locations: nil
            ) else { return }

            switch type {
            case .linear(let startPoint, let endPoint):
                let start = CGPoint(
                    x: size.width * startPoint.x,
                    y: size.height * startPoint.y
                )
                let end = CGPoint(
                    x: size.width * endPoint.x,
                    y: size.height * endPoint.y
                )
                context.cgContext.drawLinearGradient(
                    gradient,
                    start: start,
                    end: end,
                    options: []
                )
            case .radial:
                let center = CGPoint(x: size.width / 2, y: size.height / 2)
                let radius = max(size.width, size.height) / 2
                context.cgContext.drawRadialGradient(
                    gradient,
                    startCenter: center,
                    startRadius: 0,
                    endCenter: center,
                    endRadius: radius,
                    options: []
                )
            }
        }
    }

    private func createImageWithColorBackground(imageName: String, backgroundColor: Color, size: CGSize) -> UIImage? {
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { context in
            // Fill with background color
            UIColor(backgroundColor).setFill()
            context.fill(CGRect(origin: .zero, size: size))

            // Draw pattern image on top
            if let patternImage = UIImage(named: imageName) {
                // Draw the pattern image to fill the entire area
                patternImage.draw(in: CGRect(origin: .zero, size: size))
            }
        }
    }
}

