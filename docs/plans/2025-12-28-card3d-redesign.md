# Card3D Redesign - Production-Ready 3D Card Component

## Overview

Complete redesign of the 3D card system for a modern banking app. Replaces the existing POC with a clean, modular, production-ready implementation.

## Goals

- Modular architecture where each part can be edited independently
- Builder pattern API (SwiftUI-native)
- Extensible interaction system
- Support for both opaque and alpha-textured card designs
- Clean, minimal lighting (Apple-style)
- Carousel support with perspective tilt

## Architecture

```
┌─────────────────────────────────────────────────────────────┐
│ Card3DView (SwiftUI)                                        │
│   - Thin wrapper, holds configuration                       │
│   - Passes config to scene builder                          │
└─────────────────┬───────────────────────────────────────────┘
                  │
    ┌─────────────┼─────────────┬─────────────────┐
    ▼             ▼             ▼                 ▼
┌────────┐  ┌──────────┐  ┌────────────┐  ┌─────────────┐
│ Style  │  │ Geometry │  │ Interaction│  │  Lighting   │
│ Module │  │  Module  │  │   Module   │  │   Module    │
└────────┘  └──────────┘  └────────────┘  └─────────────┘
```

## File Structure

```
3DCardPOC/
├── Card3D/
│   ├── Card3DView.swift           # Main SwiftUI view with builder API
│   ├── Card3DScene.swift          # SceneKit scene setup
│   ├── Card3DData.swift           # Data model for card details
│   ├── Card3DStyle.swift          # Appearance configuration
│   ├── Card3DInteraction.swift    # Interaction protocols & handlers
│   ├── Card3DGeometry.swift       # Card shape building
│   ├── Card3DMaterials.swift      # PBR material setup
│   ├── Card3DLighting.swift       # Light configuration
│   └── Card3DModifiers.swift      # SwiftUI-style modifiers
```

## API Design

### Basic Usage

```swift
Card3DView(data: cardData)
    .cardStyle(.alphaTextured(design: 1, backgroundColor: .blue))
    .interaction(.freeRotation)
```

### Carousel Usage

```swift
Card3DView(data: cardData)
    .cardStyle(.opaqueTextured(design: 3))
    .interaction(.tapOnly)
    .rotation($rotationAngle)  // External control for carousel tilt
```

### With Text Visibility Control

```swift
Card3DView(data: cardData)
    .cardStyle(.alphaTextured(design: 2, backgroundColor: .navy))
    .textVisibility(Card3DTextVisibility(cvv: false))
    .interaction(.freeRotation)
```

## Data Models

### Card3DData

```swift
struct Card3DData {
    let cardholderName: String
    let cardNumber: String      // "4532 1234 5678 9010"
    let expiryDate: String      // "12/28"
    let cvv: String             // "123"
}
```

### Card3DStyle

```swift
enum Card3DStyle {
    case opaqueTextured(design: Int)  // Uses {n}_front-min textures
    case alphaTextured(design: Int, backgroundColor: Color)  // Uses {n}_front_alpha-min + color
}
```

### Card3DTextVisibility

```swift
struct Card3DTextVisibility {
    var cardNumber: Bool = true
    var cardholderName: Bool = true
    var expiryDate: Bool = true
    var cvv: Bool = true
}
```

### Card3DInteractionMode

```swift
enum Card3DInteractionMode {
    case freeRotation    // Pan to rotate, tap to flip
    case tapOnly         // Only tap to flip
    case disabled        // No interaction
    case custom(Card3DInteractionHandler)
}
```

## Interaction System

Protocol-based for extensibility:

```swift
protocol Card3DInteractionHandler {
    func attach(to sceneView: SCNView, cardNode: SCNNode, coordinator: Card3DCoordinator)
    func detach()
}
```

### FreeRotationHandler
- Pan gesture rotates card (360° horizontal, limited vertical tilt ~8°)
- Tap gesture flips card front/back
- Momentum + spring-back animation on release
- Haptic feedback

### TapOnlyHandler
- Tap gesture flips card
- Accepts external rotation binding for carousel control
- Haptic feedback on flip

## Materials & Textures

### Available Assets (per design 1-5)

| Asset | Purpose |
|-------|---------|
| `{n}_front-min` | Opaque front texture |
| `{n}_back-min` | Opaque back texture |
| `{n}_front_alpha-min` | Front with transparency |
| `{n}_back_alpha-min` | Back with transparency |
| `{n}_front_roughness-min` | Roughness map for front |
| `{n}_back_roughness-min` | Roughness map for back |

### Material Setup

For alpha-textured style:
- Diffuse: alpha texture with backgroundColor behind
- Roughness: roughness map
- Metalness: 0.1
- Lighting: physically based

For opaque style:
- Diffuse: opaque texture directly
- Roughness: roughness map
- Metalness: 0.1
- Lighting: physically based

## Lighting

Clean & minimal (Apple-style product shots):
- Ambient light: intensity 200, neutral white
- Directional light: intensity 600, from front-above
- No shadows (clean look)

## Geometry

- Credit card aspect ratio: 85.6mm × 53.98mm (~1.585:1)
- Rounded corners via UIBezierPath + SCNShape
- Thin extrusion for thickness
- Corner radius: 0.3 (adjustable)

## Text Rendering

3D text nodes (SCNText) for sensitive data:
- Card number (on back)
- Cardholder name (on back)
- Expiry date (on back)
- CVV (on back)

Positioned on back face, flipped for correct reading when card is flipped.

## Carousel Integration

Cards in carousel:
- Use `.interaction(.tapOnly)`
- Use `.rotation($angle)` for external rotation control
- Parent view calculates tilt based on scroll position
- Perspective tilt: cards on edges angle toward center

## Files to Delete (Old Implementation)

- `CreditCard3DView.swift`
- `CarouselCardView.swift`
- `CardTemplate.swift`
- `CardConstants.swift`
- `CardNetwork.swift`

## Implementation Tasks

1. **Card3DData.swift** - Data models (Card3DData, Card3DTextVisibility)
2. **Card3DStyle.swift** - Style enum and configuration
3. **Card3DGeometry.swift** - Card shape building
4. **Card3DMaterials.swift** - PBR material setup with texture loading
5. **Card3DLighting.swift** - Light configuration
6. **Card3DInteraction.swift** - Interaction protocol and handlers
7. **Card3DScene.swift** - Scene assembly, text nodes
8. **Card3DView.swift** - SwiftUI wrapper
9. **Card3DModifiers.swift** - Builder pattern modifiers
10. **Update ContentView.swift** - Demo both modes
11. **Update CardCarouselView.swift** - Use new Card3DView
12. **Delete old files**
