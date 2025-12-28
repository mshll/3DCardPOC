import SwiftUI

// MARK: - Card Style

enum Card3DStyle: Equatable {
    case opaqueTextured(design: Int)
    case alphaTextured(design: Int, backgroundColor: Color)

    // MARK: - Design Number

    var designNumber: Int {
        switch self {
        case .opaqueTextured(let design):
            return clamp(design, min: 1, max: 5)
        case .alphaTextured(let design, _):
            return clamp(design, min: 1, max: 5)
        }
    }

    // MARK: - Texture Names

    var frontTextureName: String {
        let n = designNumber
        switch self {
        case .opaqueTextured:
            return "\(n)_front-min"
        case .alphaTextured:
            return "\(n)_front_alpha-min"
        }
    }

    var backTextureName: String {
        let n = designNumber
        switch self {
        case .opaqueTextured:
            return "\(n)_back-min"
        case .alphaTextured:
            return "\(n)_back_alpha-min"
        }
    }

    var frontRoughnessName: String {
        return "\(designNumber)_front_roughness-min"
    }

    var backRoughnessName: String {
        return "\(designNumber)_back_roughness-min"
    }

    // MARK: - Background Color

    var backgroundColor: Color? {
        switch self {
        case .opaqueTextured:
            return nil
        case .alphaTextured(_, let color):
            return color
        }
    }

    // MARK: - Helpers

    private func clamp(_ value: Int, min: Int, max: Int) -> Int {
        return Swift.min(Swift.max(value, min), max)
    }
}
