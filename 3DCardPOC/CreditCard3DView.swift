//
//  CreditCard3DView.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import SceneKit
import SwiftUI

struct CreditCard3DView: UIViewRepresentable {
  @ObservedObject var cardDetails: CardDetailsModel
  @Binding var rotationAngle: Double

  // Animation properties
  private let springStiffness: Float = 100
  private let springDamping: Float = 10

  func makeUIView(context: Context) -> SCNView {
    let sceneView = SCNView()
    sceneView.scene = createScene()
    sceneView.allowsCameraControl = false
    sceneView.autoenablesDefaultLighting = false
    sceneView.backgroundColor = UIColor.clear
    sceneView.antialiasingMode = .multisampling4X

    // Add gesture recognizer for rotation
    let panGesture = UIPanGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.handlePan(_:)))
    sceneView.addGestureRecognizer(panGesture)

    return sceneView
  }

  func updateUIView(_ uiView: SCNView, context: Context) {
    updateCardTexts(in: uiView.scene)
    updateCardAppearance(in: uiView.scene)
  }

  func createScene() -> SCNScene {
    let scene = SCNScene()

    // Create camera - moved back for smaller card appearance
    let cameraNode = SCNNode()
    cameraNode.camera = SCNCamera()
    cameraNode.camera?.fieldOfView = 45
    cameraNode.position = SCNVector3(x: 0, y: 0, z: 13)
    scene.rootNode.addChildNode(cameraNode)

    // Create lights
    setupLighting(in: scene)

    // Create card
    let cardNode = createCreditCard()
    scene.rootNode.addChildNode(cardNode)

    return scene
  }

  func createSmoothChamferProfile() -> UIBezierPath {
    // Create a smooth bezier curve for the chamfer profile
    let chamferPath = UIBezierPath()
    chamferPath.move(to: CGPoint(x: 0, y: 0))

    // Smooth curve from (0,0) to (1,1)
    chamferPath.addCurve(
      to: CGPoint(x: 1, y: 1),
      controlPoint1: CGPoint(x: 0.3, y: 0),
      controlPoint2: CGPoint(x: 0.7, y: 1)
    )

    return chamferPath
  }

  func setupLighting(in scene: SCNScene) {
    // Soft ambient light for base illumination - provides subtle fill
    let ambientLight = SCNNode()
    ambientLight.light = SCNLight()
    ambientLight.light?.type = .ambient
    ambientLight.light?.intensity = 200  // Gentle base lighting
    ambientLight.light?.color = UIColor(white: 0.98, alpha: 1.0)  // Clean, neutral white
    scene.rootNode.addChildNode(ambientLight)

    // Main directional light from front - creates smooth, even lighting
    let mainLight = SCNNode()
    mainLight.light = SCNLight()
    mainLight.light?.type = .directional
    mainLight.light?.intensity = 600  // Strong enough for clean visibility
    mainLight.light?.color = UIColor.white
    mainLight.light?.castsShadow = false  // No harsh shadows for clean look
    mainLight.eulerAngles = SCNVector3(x: -Float.pi / 6, y: 0, z: 0)  // Angled slightly down
    mainLight.position = SCNVector3(x: 0, y: 5, z: 10)
    scene.rootNode.addChildNode(mainLight)

  }

  func createCreditCard() -> SCNNode {
    // Portrait card dimensions (aspect ratio ~1.58:1)
    let cardWidth: CGFloat = 5.4
    let cardHeight: CGFloat = 8.56
    let cardThickness: CGFloat = 0.08  // Extrusion depth - thin like a real card
    let cornerRadius: CGFloat = 0.3

    // Create container node that will be rotated
    let containerNode = SCNNode()
    containerNode.name = "creditCard"
    containerNode.eulerAngles.y = Float(rotationAngle)

    // Create rounded rectangle path in XY plane with smooth corners
    let rect = CGRect(
      x: -cardWidth / 2,
      y: -cardHeight / 2,
      width: cardWidth,
      height: cardHeight
    )
    let path = UIBezierPath(roundedRect: rect, cornerRadius: cornerRadius)

    // Flatten the path to make corners smoother with more segments
    path.flatness = 0.01

    // Create extruded shape from path (extrudes along Z-axis)
    let cardGeometry = SCNShape(path: path, extrusionDepth: cardThickness)
    cardGeometry.chamferRadius = 0.005  // Very small chamfer for smooth edges
    cardGeometry.chamferProfile = createSmoothChamferProfile()

    // Front material with pattern
    let frontMaterial = SCNMaterial()
    let patternImage = cardDetails.cardTemplate.pattern.toImage()
    frontMaterial.diffuse.contents = patternImage ?? UIColor(cardDetails.cardColor)
    frontMaterial.specular.contents = UIColor(white: 0.15, alpha: 1.0)
    frontMaterial.shininess = 0.15
    frontMaterial.metalness.contents = 0.1
    frontMaterial.roughness.contents = 0.8
    frontMaterial.lightingModel = .physicallyBased

    // Back material with solid color
    let backMaterial = SCNMaterial()
    backMaterial.diffuse.contents = UIColor(cardDetails.cardColor)
    backMaterial.specular.contents = UIColor(white: 0.15, alpha: 1.0)
    backMaterial.shininess = 0.15
    backMaterial.metalness.contents = 0.1
    backMaterial.roughness.contents = 0.8
    backMaterial.lightingModel = .physicallyBased

    // Side material (edges) with solid color
    let sideMaterial = SCNMaterial()
    sideMaterial.diffuse.contents = UIColor(cardDetails.cardColor)
    sideMaterial.specular.contents = UIColor(white: 0.15, alpha: 1.0)
    sideMaterial.shininess = 0.15
    sideMaterial.metalness.contents = 0.1
    sideMaterial.roughness.contents = 0.8
    sideMaterial.lightingModel = .physicallyBased

    // Apply materials: front, back, sides, chamfer sides, chamfer back
    cardGeometry.materials = [
      frontMaterial, backMaterial, sideMaterial, sideMaterial, sideMaterial,
    ]

    // Card node - SCNShape extrudes from z=0 to z=depth, so shift back to center it
    let cardNode = SCNNode(geometry: cardGeometry)
    cardNode.position = SCNVector3(0, 0, 0)
    containerNode.addChildNode(cardNode)

    // Add card texts
    addCardTexts(to: containerNode, cardThickness: Float(cardThickness))

    // Add inquiry text on back (left side, rotated sideways)
    let inquiryNode = createInquiryText()
    inquiryNode.position = SCNVector3(x: -2.5, y: 2.3, z: Float(-cardThickness / 2 - 0.01))
    containerNode.addChildNode(inquiryNode)

    // Add magnetic stripe bar on back (grey vertical bar)
    let magneticStripeNode = createMagneticStripe(
      cardWidth: Float(cardWidth), cardThickness: Float(cardThickness))
    magneticStripeNode.position = SCNVector3(x: -1.8, y: 0, z: Float(-cardThickness / 2 - 0.005))
    containerNode.addChildNode(magneticStripeNode)

    // Add website text on back (bottom center)
    let websiteNode = createWebsiteText()
      websiteNode.position = SCNVector3(x: 0, y: -3.5, z: Float(-cardThickness / 2 - 0.01))
    containerNode.addChildNode(websiteNode)

    return containerNode
  }

  func createInquiryText() -> SCNNode {
    let inquiryText = createTextNode(
      text: CardConstants.inquiryText, fontSize: 0.2, color: .white, alignment: .left)
    // Rotate 90 degrees to make it vertical/sideways, and flip for back of card
    inquiryText.eulerAngles = SCNVector3(0, Double.pi, Double.pi / 2)
    return inquiryText
  }

  func createMagneticStripe(cardWidth: Float, cardThickness: Float) -> SCNNode {
    // Create a dark grey/black bar that spans the height of the card vertically
    let stripeWidth: CGFloat = 0.8  // Width of the vertical magnetic stripe
    let stripeGeometry = SCNBox(
      width: stripeWidth, height: 8.56, length: 0.02, chamferRadius: 0)

    let stripeMaterial = SCNMaterial()
    stripeMaterial.diffuse.contents = UIColor(white: 0.2, alpha: 1.0)  // Dark grey
    stripeMaterial.specular.contents = UIColor(white: 0.3, alpha: 1.0)
    stripeMaterial.shininess = 0.3
    stripeMaterial.metalness.contents = 0.2
    stripeMaterial.roughness.contents = 0.6
    stripeMaterial.lightingModel = .physicallyBased

    stripeGeometry.firstMaterial = stripeMaterial

    let stripeNode = SCNNode(geometry: stripeGeometry)
    stripeNode.eulerAngles.y = .pi  // Rotate to face back

    return stripeNode
  }

  func createWebsiteText() -> SCNNode {
    let websiteText = createTextNode(
      text: CardConstants.websiteText, fontSize: 0.2, color: .white, alignment: .right)
    websiteText.eulerAngles.y = .pi
    return websiteText
  }

  func createExpiryCvcText() -> SCNNode {
    let containerNode = SCNNode()

    // Create individual text nodes with different sizes, center-aligned vertically
    let expLabel = createTextNode(
      text: "EXP", fontSize: 0.15, color: .white, alignment: .left, verticalAlignment: .center)
    expLabel.position = SCNVector3(x: 0, y: 0, z: 0)
    containerNode.addChildNode(expLabel)

    let expValue = createTextNode(
      text: cardDetails.expiryDate, fontSize: 0.3, color: .white, alignment: .left,
      verticalAlignment: .center)
    expValue.position = SCNVector3(x: 0.5, y: 0, z: 0)
    containerNode.addChildNode(expValue)

    let cvcLabel = createTextNode(
      text: "CVC", fontSize: 0.15, color: .white, alignment: .left, verticalAlignment: .center)
    cvcLabel.position = SCNVector3(x: 1.7, y: 0, z: 0)
    containerNode.addChildNode(cvcLabel)

    let cvcValue = createTextNode(
      text: cardDetails.cvv, fontSize: 0.3, color: .white, alignment: .left,
      verticalAlignment: .center)
    cvcValue.position = SCNVector3(x: 2.2, y: 0, z: 0)
    containerNode.addChildNode(cvcValue)

    return containerNode
  }

  func createBankLogoNode() -> SCNNode {
    let logoImageName = "boubyan_logo_white"

    // Configure material for proper image display
    let material = SCNMaterial()

    // Create a plane for the logo with proper aspect ratio
    var logoWidth: CGFloat = 1.2
    var logoHeight: CGFloat = 0.8

    // Apply logo image as texture and adjust dimensions to maintain aspect ratio
    if let logoImage = UIImage(named: logoImageName) {
      let imageAspectRatio = logoImage.size.width / logoImage.size.height

      // Adjust dimensions to maintain aspect ratio
      if imageAspectRatio > 1 {
        // Wider than tall
        logoHeight = logoWidth / imageAspectRatio
      } else {
        // Taller than wide
        logoWidth = logoHeight * imageAspectRatio
      }

      material.diffuse.contents = logoImage
      material.lightingModel = .physicallyBased  // Respond to scene lighting
      material.isDoubleSided = true  // Make it visible from both sides
      material.transparency = 1.0
      material.writesToDepthBuffer = false  // Don't write to depth buffer
      material.readsFromDepthBuffer = true
      material.blendMode = .alpha  // Handle PNG transparency
      material.transparencyMode = .default
      material.metalness.contents = 0.0  // Non-metallic for clean look
      material.roughness.contents = 0.3  // Slightly glossy for modern feel
    } else {
      // Fallback if image doesn't load
      print("Warning: Could not load bank logo image: \(logoImageName)")
      material.diffuse.contents = UIColor.red  // Use red for visibility if image fails
    }

    let logoGeometry = SCNPlane(width: logoWidth, height: logoHeight)
    logoGeometry.firstMaterial = material

    let logoNode = SCNNode(geometry: logoGeometry)
    logoNode.renderingOrder = 100  // Render on top of other elements

    return logoNode
  }

  func createNetworkLogoNode() -> SCNNode {
    let logoImageName = cardDetails.cardNetwork.logoImageName

    // Configure material for proper image display
    let material = SCNMaterial()

    // Create a plane for the logo with proper aspect ratio
    var logoWidth: CGFloat = 1.2
    var logoHeight: CGFloat = 0.8

    // Apply logo image as texture and adjust dimensions to maintain aspect ratio
    if let logoImage = UIImage(named: logoImageName) {
      let imageAspectRatio = logoImage.size.width / logoImage.size.height

      // Adjust dimensions to maintain aspect ratio
      if imageAspectRatio > 1 {
        // Wider than tall
        logoHeight = logoWidth / imageAspectRatio
      } else {
        // Taller than wide
        logoWidth = logoHeight * imageAspectRatio
      }

      material.diffuse.contents = logoImage
      material.lightingModel = .physicallyBased  // Respond to scene lighting
      material.isDoubleSided = true  // Make it visible from both sides
      material.transparency = 1.0
      material.writesToDepthBuffer = false  // Don't write to depth buffer
      material.readsFromDepthBuffer = true
      material.blendMode = .alpha  // Handle PNG transparency
      material.transparencyMode = .default
      material.metalness.contents = 0.0  // Non-metallic for clean look
      material.roughness.contents = 0.3  // Slightly glossy for modern feel
    } else {
      // Fallback if image doesn't load
      print("Warning: Could not load network logo image: \(logoImageName)")
      material.diffuse.contents = UIColor.red  // Use red for visibility if image fails
    }

    let logoGeometry = SCNPlane(width: logoWidth, height: logoHeight)
    logoGeometry.firstMaterial = material

    let logoNode = SCNNode(geometry: logoGeometry)
    logoNode.renderingOrder = 100  // Render on top of other elements

    return logoNode
  }

  func createChipNode() -> SCNNode {
    let chipImageName = "chip"

    // Configure material for proper image display
    let material = SCNMaterial()

    // Create a plane for the chip with proper aspect ratio
    var chipWidth: CGFloat = 0.8
    var chipHeight: CGFloat = 1

    // Apply chip image as texture and adjust dimensions to maintain aspect ratio
    if let chipImage = UIImage(named: chipImageName) {
      let imageAspectRatio = chipImage.size.width / chipImage.size.height

      // Adjust dimensions to maintain aspect ratio
      if imageAspectRatio > 1 {
        // Wider than tall
        chipHeight = chipWidth / imageAspectRatio
      } else {
        // Taller than wide
        chipWidth = chipHeight * imageAspectRatio
      }

      material.diffuse.contents = chipImage
      material.lightingModel = .physicallyBased  // Respond to scene lighting
      material.isDoubleSided = true  // Make it visible from both sides
      material.transparency = 1.0
      material.writesToDepthBuffer = false  // Don't write to depth buffer
      material.readsFromDepthBuffer = true
      material.blendMode = .alpha  // Handle PNG transparency
      material.transparencyMode = .default
      material.metalness.contents = 0.3  // Slightly metallic for chip look
      material.roughness.contents = 0.4  // Slightly glossy for metallic feel
    } else {
      // Fallback if image doesn't load
      print("Warning: Could not load chip image: \(chipImageName)")
      material.diffuse.contents = UIColor.gray  // Use gray for visibility if image fails
    }

    let chipGeometry = SCNPlane(width: chipWidth, height: chipHeight)
    chipGeometry.firstMaterial = material

    let chipNode = SCNNode(geometry: chipGeometry)
    chipNode.renderingOrder = 100  // Render on top of other elements

    return chipNode
  }

  func addCardTexts(to cardNode: SCNNode, cardThickness: Float) {
    // With SCNShape, the front face is at z=0 and back at z=extrusionDepth
    // Since we shifted the card by -thickness/2, front is at -thickness/2, back at +thickness/2
    let frontZPosition = cardThickness / 2 + 0.01  // Front face (facing camera)
    let backZPosition = -cardThickness / 2 - 0.01  // Back face (away from camera)

    // FRONT: Bank logo - top right corner
    let bankLogoNode = createBankLogoNode()
    bankLogoNode.name = "bankLogo"
    bankLogoNode.position = SCNVector3(x: 1.8, y: 3.5, z: frontZPosition)
    cardNode.addChildNode(bankLogoNode)

    // FRONT: Network logo - bottom right corner
    let networkLogoNode = createNetworkLogoNode()
    networkLogoNode.name = "networkLogo"
    networkLogoNode.position = SCNVector3(x: 1.8, y: -3.5, z: frontZPosition)
    cardNode.addChildNode(networkLogoNode)

    // FRONT: Chip - bottom center
    let chipNode = createChipNode()
    chipNode.name = "chip"
    chipNode.position = SCNVector3(x: 0, y: -3.0, z: frontZPosition)
    cardNode.addChildNode(chipNode)

    // BACK: Card number split into two lines with extra spacing between 4-digit groups
    let cardNumberParts = cardDetails.cardNumber.split(separator: " ")
    let firstLine = cardNumberParts.prefix(2).joined(separator: "  ")
    let secondLine = cardNumberParts.suffix(from: 2).joined(separator: "  ")

    let cardNumberLine1Node = createTextNode(
      text: firstLine, fontSize: 0.45, color: .white,
      alignment: .left)
    cardNumberLine1Node.name = "cardNumberLine1"
    cardNumberLine1Node.position = SCNVector3(x: 2.2, y: 3.4, z: backZPosition)
    cardNumberLine1Node.eulerAngles.y = .pi
    cardNode.addChildNode(cardNumberLine1Node)

    let cardNumberLine2Node = createTextNode(
      text: secondLine, fontSize: 0.45, color: .white,
      alignment: .left)
    cardNumberLine2Node.name = "cardNumberLine2"
    cardNumberLine2Node.position = SCNVector3(x: 2.2, y: 2.8, z: backZPosition)
    cardNumberLine2Node.eulerAngles.y = .pi
    cardNode.addChildNode(cardNumberLine2Node)

    // BACK: Cardholder name (lower, left side)
    let nameNode = createTextNode(
      text: cardDetails.cardholderName.uppercased(), fontSize: 0.3, color: .white,
      alignment: .left)
    nameNode.name = "cardholderName"
    nameNode.position = SCNVector3(x: 2.3, y: -1.5, z: backZPosition)
    nameNode.eulerAngles.y = .pi
    cardNode.addChildNode(nameNode)

    // BACK: Expiry and CVC with mixed font sizes (positioned under card number)
    let expiryCvcNode = createExpiryCvcText()
    expiryCvcNode.name = "expiryCvc"
    expiryCvcNode.position = SCNVector3(x: 2.2, y: 1, z: backZPosition)
    expiryCvcNode.eulerAngles.y = .pi
    cardNode.addChildNode(expiryCvcNode)
  }

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

  func createTextNode(
    text: String,
    fontSize: CGFloat,
    color: UIColor,
    alignment: TextAlignment = .center,
    verticalAlignment: VerticalAlignment = .bottom
  )
    -> SCNNode
  {
    let textGeometry = SCNText(string: text, extrusionDepth: 0.01)
    textGeometry.font = UIFont.systemFont(ofSize: fontSize, weight: .medium)
    textGeometry.firstMaterial?.diffuse.contents = color
    textGeometry.firstMaterial?.specular.contents = UIColor.white
    textGeometry.firstMaterial?.shininess = 0.1
    textGeometry.flatness = 0.1

    let textNode = SCNNode(geometry: textGeometry)

    // Adjust pivot based on alignment
    let (min, max) = textNode.boundingBox

    // Horizontal alignment
    let dx: Float
    switch alignment {
    case .left:
      dx = min.x  // Pivot at left edge
    case .center:
      dx = (max.x - min.x) / 2  // Pivot at center
    case .right:
      dx = max.x  // Pivot at right edge
    }

    // Vertical alignment
    let dy: Float
    switch verticalAlignment {
    case .top:
      dy = min.y  // Pivot at top edge
    case .center:
      dy = (max.y - min.y) / 2  // Pivot at center
    case .bottom:
      dy = max.y  // Pivot at bottom edge
    }

    textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)

    return textNode
  }

  func updateCardTexts(in scene: SCNScene?) {
    guard let cardNode = scene?.rootNode.childNode(withName: "creditCard", recursively: true) else {
      return
    }

    // Update card number lines on back with extra spacing
    let cardNumberParts = cardDetails.cardNumber.split(separator: " ")
    let firstLine = cardNumberParts.prefix(2).joined(separator: "  ")  // Double space for extra spacing
    let secondLine = cardNumberParts.suffix(from: 2).joined(separator: "  ")  // Double space for extra spacing

    if let cardNumberLine1Node = cardNode.childNode(withName: "cardNumberLine1", recursively: true),
      let textGeometry = cardNumberLine1Node.geometry as? SCNText
    {
      textGeometry.string = firstLine
    }

    if let cardNumberLine2Node = cardNode.childNode(withName: "cardNumberLine2", recursively: true),
      let textGeometry = cardNumberLine2Node.geometry as? SCNText
    {
      textGeometry.string = secondLine
    }

    // Update cardholder name on back
    if let nameNode = cardNode.childNode(withName: "cardholderName", recursively: true),
      let textGeometry = nameNode.geometry as? SCNText
    {
      textGeometry.string = cardDetails.cardholderName.uppercased()
    }

    // Update expiry/CVC on back (compound node with multiple text elements)
    if let expiryCvcNode = cardNode.childNode(withName: "expiryCvc", recursively: true) {
      // Update the expiry value (second child)
      if expiryCvcNode.childNodes.count > 1,
        let expValueGeometry = expiryCvcNode.childNodes[1].geometry as? SCNText
      {
        expValueGeometry.string = cardDetails.expiryDate
      }

      // Update the CVC value (fourth child)
      if expiryCvcNode.childNodes.count > 3,
        let cvcValueGeometry = expiryCvcNode.childNodes[3].geometry as? SCNText
      {
        cvcValueGeometry.string = cardDetails.cvv
      }
    }
  }

  func updateCardAppearance(in scene: SCNScene?) {
    guard let cardNode = scene?.rootNode.childNode(withName: "creditCard", recursively: true)
    else { return }

    // Update card materials with new pattern and color
    if let cardShape = cardNode.childNodes.first(where: { $0.geometry is SCNShape }),
      let cardGeometry = cardShape.geometry as? SCNShape
    {
      let patternImage = cardDetails.cardTemplate.pattern.toImage()
      let solidColor = UIColor(cardDetails.cardColor)

      // Update front material (pattern)
      if cardGeometry.materials.count > 0 {
        cardGeometry.materials[0].diffuse.contents = patternImage ?? solidColor
      }

      // Update back material (solid color)
      if cardGeometry.materials.count > 1 {
        cardGeometry.materials[1].diffuse.contents = solidColor
      }

      // Update side materials (solid color)
      for i in 2..<cardGeometry.materials.count {
        cardGeometry.materials[i].diffuse.contents = solidColor
      }
    }

    // Update network logo when template changes (since different templates have different networks)
    if let networkLogoNode = cardNode.childNode(withName: "networkLogo", recursively: true) {
      let position = networkLogoNode.position
      networkLogoNode.removeFromParentNode()
      let newNetworkLogoNode = createNetworkLogoNode()
      newNetworkLogoNode.name = "networkLogo"
      newNetworkLogoNode.position = position
      cardNode.addChildNode(newNetworkLogoNode)
    }
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject {
    var parent: CreditCard3DView
    var initialRotation: Float = 0
    var autoReturnTimer: Timer?
    var displayLink: CADisplayLink?
    var targetRotation: Float = 0
    var currentVelocity: Float = 0

    // Haptic feedback
    private let lightHaptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private var hapticTimer: Timer?
    private let hapticInterval: TimeInterval = 0.05  // Trigger haptic every 50ms for continuous feel
    private var lastRotationForHaptic: Float = 0
    private var isRotating = false

    // Friction properties
    private var hasOvercomeFriction = false
    private let frictionThreshold: Float = 20.0  // Pixels of movement needed to overcome friction

    init(_ parent: CreditCard3DView) {
      self.parent = parent
      super.init()
      // Prepare haptic generators
      lightHaptic.prepare()
      mediumHaptic.prepare()
    }

    @objc private func continuousHaptic() {
      lightHaptic.impactOccurred(intensity: 1)
      lightHaptic.prepare()
    }

    // Helper function to limit rotation to ~200 degrees (slightly more than 180)
    // Returns the clamped value and stops at limits instead of wrapping
    private func limitRotation(_ rotation: Float) -> Float {
      let maxRotation: Float = Float.pi * 1.11  // ~200 degrees (slightly more than 180)
      let minRotation: Float = -maxRotation

      // Clamp between -200 and +200 degrees
      if rotation < minRotation {
        return minRotation
      } else if rotation > maxRotation {
        return maxRotation
      }

      return rotation
    }

    @objc func handlePan(_ gesture: UIPanGestureRecognizer) {
      guard let view = gesture.view as? SCNView,
        let cardNode = view.scene?.rootNode.childNode(withName: "creditCard", recursively: true)
      else { return }

      let translation = gesture.translation(in: view)
      let velocity = gesture.velocity(in: view)
      var rotationSpeed: Float = 0.01

      // Cancel any existing timers
      autoReturnTimer?.invalidate()
      displayLink?.invalidate()

      switch gesture.state {
      case .began:
        initialRotation = cardNode.eulerAngles.y
        targetRotation = initialRotation
        lastRotationForHaptic = initialRotation
        hasOvercomeFriction = false
        isRotating = false

        // Prepare haptics for upcoming feedback
        lightHaptic.prepare()
        mediumHaptic.prepare()

      case .changed:
        let absTranslation = abs(translation.x)

        // Apply friction at the start
        if !hasOvercomeFriction {
          if absTranslation < CGFloat(frictionThreshold) {
            // Reduce rotation speed based on how far from threshold
            let frictionFactor = Float(absTranslation) / frictionThreshold
            rotationSpeed *= frictionFactor * 0.5  // 50% reduced speed during friction
          } else {
            // Overcome friction with a medium haptic
            hasOvercomeFriction = true
            mediumHaptic.impactOccurred(intensity: 0.8)
          }
        }

        targetRotation = initialRotation + Float(translation.x) * rotationSpeed

        // Limit rotation to 0-360 degrees (stop at edges, don't wrap)
        targetRotation = limitRotation(targetRotation)

        // Detect if actually rotating (movement threshold)
        let rotationDelta = abs(targetRotation - lastRotationForHaptic)
        let movementThreshold: Float = 0.01  // Small threshold to detect actual movement

        if rotationDelta > movementThreshold {
          // Card is actively rotating
          if !isRotating {
            // Just started rotating - start haptic timer
            isRotating = true
            hapticTimer?.invalidate()
            hapticTimer = Timer.scheduledTimer(
              timeInterval: hapticInterval,
              target: self,
              selector: #selector(continuousHaptic),
              userInfo: nil,
              repeats: true
            )
          }
          lastRotationForHaptic = targetRotation
        } else {
          // Card is held still - stop haptics
          if isRotating {
            isRotating = false
            hapticTimer?.invalidate()
            hapticTimer = nil
          }
        }

        // Apply spring animation
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.1
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeOut)
        cardNode.eulerAngles.y = targetRotation
        SCNTransaction.commit()

        parent.rotationAngle = Double(targetRotation)

      case .ended, .cancelled:
        // Stop continuous haptic feedback
        hapticTimer?.invalidate()
        hapticTimer = nil

        // Medium haptic when releasing only if was rotating
        if isRotating || hasOvercomeFriction {
          mediumHaptic.impactOccurred(intensity: 0.7)
        }
        isRotating = false

        // Add momentum based on velocity
        let momentumRotation = Float(velocity.x) * 0.0001
        targetRotation = cardNode.eulerAngles.y + momentumRotation
        currentVelocity = Float(velocity.x) * 0.001

        // Limit rotation to 0-360 degrees (stop at edges, don't wrap)
        targetRotation = limitRotation(targetRotation)

        // Apply momentum with spring
        SCNTransaction.begin()
        SCNTransaction.animationDuration = 0.3
        SCNTransaction.animationTimingFunction = CAMediaTimingFunction(
          controlPoints: 0.25, 0.46, 0.45, 0.94)
        cardNode.eulerAngles.y = targetRotation
        SCNTransaction.commit()

        parent.rotationAngle = Double(targetRotation)

        // Start timer to return to center
        autoReturnTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: false) {
          [weak self] _ in
          self?.animateToCenter(cardNode: cardNode)
        }
      default:
        break
      }
    }

    func animateToCenter(cardNode: SCNNode) {
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.3
      SCNTransaction.animationTimingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
      cardNode.eulerAngles.y = 0
      SCNTransaction.commit()

      parent.rotationAngle = 0
    }
  }
}

#Preview {
  ContentView()
}
