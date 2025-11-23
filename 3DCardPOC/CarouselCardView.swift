//
//  CarouselCardView.swift
//  3DCardPOC
//
//  Created by meshal on 11/10/25.
//

import SceneKit
import SwiftUI

/// A simplified 3D card view for use in carousels
/// Disables pan gesture rotation, only allows tap to flip
struct CarouselCardView: UIViewRepresentable {
  @ObservedObject var cardDetails: CardDetailsModel
  @Binding var rotationAngle: Double

  // Animation properties
  private let springStiffness: Float = 100
  private let springDamping: Float = 10

  // Caches and constants
  private enum Constants {
    static let cardWidth: CGFloat = 5.4
    static let cardHeight: CGFloat = 8.56
    static let cardThickness: CGFloat = 0.08
    static let cornerRadius: CGFloat = 0.6
    static let logoBaseWidth: CGFloat = 1.2
    static let logoBaseHeight: CGFloat = 0.8
    static let chipBaseWidth: CGFloat = 0.8
    static let chipBaseHeight: CGFloat = 1.0
  }

  private static let imageCache = NSCache<NSString, UIImage>()
  private static let materialCache = NSCache<NSString, SCNMaterial>()

  func makeUIView(context: Context) -> SCNView {
    let sceneView = SCNView()
    sceneView.scene = createScene()
    sceneView.allowsCameraControl = false
    sceneView.autoenablesDefaultLighting = false
    sceneView.backgroundColor = UIColor.clear
    sceneView.antialiasingMode = .multisampling4X

    // Performance optimizations
    sceneView.rendersContinuously = false  // Only render when needed
    sceneView.isJitteringEnabled = false  // Disable jittering for better performance

    // Preload common assets to avoid stalls when nodes are first created
    preloadAssets()

    // ONLY add tap gesture recognizer for flipping - NO pan gesture for carousel
    let tapGesture = UITapGestureRecognizer(
      target: context.coordinator, action: #selector(Coordinator.handleTap(_:)))
    sceneView.addGestureRecognizer(tapGesture)

    return sceneView
  }

  func updateUIView(_ uiView: SCNView, context: Context) {
    // Performance optimization: Only update appearance/texts once on initial render
    // After that, only update rotation since card data doesn't change
    if !context.coordinator.hasInitializedCard {
      updateCardTexts(in: uiView.scene, coordinator: context.coordinator)
      updateCardAppearance(in: uiView.scene, coordinator: context.coordinator)
      context.coordinator.hasInitializedCard = true
    }

    // Only update rotation during scrolling (lightweight operation)
    updateCardRotation(in: uiView.scene, coordinator: context.coordinator)
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
    let cardWidth = Constants.cardWidth
    let cardHeight = Constants.cardHeight
    let cardThickness = Constants.cardThickness
    let cornerRadius = Constants.cornerRadius

    // Create container node that will be rotated
    let containerNode = SCNNode()
    containerNode.name = "creditCard"
    containerNode.eulerAngles.y = Float(rotationAngle)

    // Create rounded rectangle path in XY plane with smooth corners
    let rect = CGRect(x: -cardWidth / 2, y: -cardHeight / 2, width: cardWidth, height: cardHeight)
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
    inquiryNode.position = SCNVector3(x: -2.4, y: 2.3, z: Float(-cardThickness / 2 - 0.01))
    containerNode.addChildNode(inquiryNode)

    // Add magnetic stripe bar on back (grey vertical bar)
    let magneticStripeNode = createMagneticStripe(
      cardWidth: Float(cardWidth), cardThickness: Float(cardThickness))
    magneticStripeNode.position = SCNVector3(x: -1.8, y: 0, z: Float(-cardThickness / 2 - 0.005))
    containerNode.addChildNode(magneticStripeNode)

    // Add website text on back (bottom center)
    let websiteNode = createWebsiteText()
    websiteNode.position = SCNVector3(x: 1, y: -3.9, z: Float(-cardThickness / 2 - 0.01))
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
    stripeNode.eulerAngles.y = .pi

    return stripeNode
  }

  func createWebsiteText() -> SCNNode {
    let websiteText = createTextNode(
      text: CardConstants.websiteText, fontSize: 0.2, color: .white, alignment: .center)
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
    return createImageNode(
      named: "boubyan_logo_white", baseWidth: Constants.logoBaseWidth,
      baseHeight: Constants.logoBaseHeight, metalness: 0.0)
  }

  func createNetworkLogoNode() -> SCNNode {
    return createImageNode(
      named: cardDetails.cardNetwork.logoImageName, baseWidth: Constants.logoBaseWidth,
      baseHeight: Constants.logoBaseHeight, metalness: 0.0)
  }

  func createChipNode() -> SCNNode {
    return createImageNode(
      named: "chip", baseWidth: Constants.chipBaseWidth, baseHeight: Constants.chipBaseHeight,
      metalness: 0.3, fallbackColor: UIColor.gray)
  }

  // MARK: - Helpers for image nodes and materials (DRY)

  private func makePBRMaterial(
    image: UIImage?, metalness: CGFloat = 0.0, roughness: CGFloat = 0.3, isDoubleSided: Bool = true,
    fallbackColor: UIColor = .red
  ) -> SCNMaterial {
    // Use a simple cache key based on image pointer or fallback
    let key: String
    if let img = image, let imgName = img.accessibilityIdentifier {
      key = "mat:\(imgName):m:\(metalness)"
    } else {
      key = "mat:anon:m:\(metalness):fallback:\(fallbackColor.description)"
    }

    if let cached = Self.materialCache.object(forKey: key as NSString) {
      return cached
    }

    let material = SCNMaterial()
    material.diffuse.contents = image ?? fallbackColor
    material.lightingModel = .physicallyBased
    material.isDoubleSided = isDoubleSided
    material.transparency = 1.0
    material.writesToDepthBuffer = false
    material.readsFromDepthBuffer = true
    material.blendMode = .alpha
    material.transparencyMode = .default
    material.metalness.contents = metalness
    material.roughness.contents = roughness

    Self.materialCache.setObject(material, forKey: key as NSString)
    return material
  }

  private func loadImage(named name: String) -> UIImage? {
    let key = name as NSString
    if let cached = Self.imageCache.object(forKey: key) {
      return cached
    }
    let img = UIImage(named: name)
    if let img = img {
      // tag for material cache keying
      img.accessibilityIdentifier = name
      Self.imageCache.setObject(img, forKey: key)
    }
    return img
  }

  private func createImageNode(
    named imageName: String, baseWidth: CGFloat = 1.0, baseHeight: CGFloat = 1.0,
    metalness: CGFloat = 0.0, fallbackColor: UIColor = .red
  ) -> SCNNode {
    var width = baseWidth
    var height = baseHeight

    let image = loadImage(named: imageName)
    if let img = image {
      let aspect = img.size.width / img.size.height
      if aspect > 1 {
        height = width / aspect
      } else {
        width = height * aspect
      }
    }

    let geom = SCNPlane(width: width, height: height)
    let mat = makePBRMaterial(
      image: image, metalness: metalness, roughness: 0.3, isDoubleSided: true,
      fallbackColor: fallbackColor)
    // store base sizes on the material (KVC) so we can read them later; SCNNode.userData is not available in some contexts
    mat.setValue(baseWidth, forKey: "baseWidth")
    mat.setValue(baseHeight, forKey: "baseHeight")
    geom.firstMaterial = mat
    let node = SCNNode(geometry: geom)
    node.renderingOrder = 100
    return node
  }

  private func preloadAssets() {
    // Preload the common images used by the card so the first render doesn't stall
    _ = loadImage(named: "boubyan_logo_white")
    _ = loadImage(named: cardDetails.cardNetwork.logoImageName)
    _ = loadImage(named: "chip")

    // Cache current pattern image if available
    if let patternImg = cardDetails.cardTemplate.pattern.toImage() {
      Self.imageCache.setObject(patternImg, forKey: "__pattern__" as NSString)
    }
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
      dx = min.x  // Pivot at left edge (use min.x)
    case .center:
      dx = (min.x + max.x) / 2  // Pivot at center (average of min and max)
    case .right:
      dx = max.x  // Pivot at right edge (use max.x)
    }

    // Vertical alignment
    let dy: Float
    switch verticalAlignment {
    case .top:
      dy = max.y  // Pivot at top edge (use max.y)
    case .center:
      dy = (min.y + max.y) / 2  // Pivot at center (average of min and max)
    case .bottom:
      dy = min.y  // Pivot at bottom edge (use min.y)
    }

    textNode.pivot = SCNMatrix4MakeTranslation(dx, dy, 0)

    return textNode
  }

  func updateCardTexts(in scene: SCNScene?, coordinator: Coordinator) {
    // Use cached node references to avoid expensive recursive traversals
    if coordinator.cachedCardNode == nil {
      coordinator.cachedCardNode = scene?.rootNode.childNode(
        withName: "creditCard", recursively: true)
    }

    guard let cardNode = coordinator.cachedCardNode else { return }

    // Update card number lines on back with extra spacing
    let cardNumberParts = cardDetails.cardNumber.split(separator: " ")
    let firstLine = cardNumberParts.prefix(2).joined(separator: "  ")
    let secondLine = cardNumberParts.suffix(from: 2).joined(separator: "  ")

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

  func updateCardAppearance(in scene: SCNScene?, coordinator: Coordinator) {
    // Use cached node reference
    if coordinator.cachedCardNode == nil {
      coordinator.cachedCardNode = scene?.rootNode.childNode(
        withName: "creditCard", recursively: true)
    }

    guard let cardNode = coordinator.cachedCardNode else { return }

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

    // Update network logo when template changes
    if let networkLogoNode = cardNode.childNode(withName: "networkLogo", recursively: true),
      let plane = networkLogoNode.geometry as? SCNPlane
    {
      let newImage = loadImage(named: cardDetails.cardNetwork.logoImageName)
      if let mat = plane.firstMaterial {
        mat.diffuse.contents = newImage ?? mat.diffuse.contents
      } else {
        plane.firstMaterial = makePBRMaterial(
          image: newImage, metalness: 0.0, roughness: 0.3, isDoubleSided: true, fallbackColor: .red)
      }

      // Fix stretching: if we have base sizes stored on the material, recompute plane dimensions
      if let mat = plane.firstMaterial,
        let bw = mat.value(forKey: "baseWidth") as? CGFloat,
        let bh = mat.value(forKey: "baseHeight") as? CGFloat
      {
        if let img = newImage {
          let aspect = img.size.width / img.size.height
          if aspect > 1 {
            plane.width = bw
            plane.height = bw / aspect
          } else {
            plane.width = bh * aspect
            plane.height = bh
          }
        } else {
          // no image: keep base sizes
          plane.width = bw
          plane.height = bh
        }
      }
    }
  }

  func updateCardRotation(in scene: SCNScene?, coordinator: Coordinator) {
    // Use cached node reference
    if coordinator.cachedCardNode == nil {
      coordinator.cachedCardNode = scene?.rootNode.childNode(
        withName: "creditCard", recursively: true)
    }

    guard let cardNode = coordinator.cachedCardNode else { return }

    cardNode.eulerAngles.y = Float(rotationAngle)
  }

  func makeCoordinator() -> Coordinator {
    Coordinator(self)
  }

  class Coordinator: NSObject {
    var parent: CarouselCardView

    // Cached node references to avoid recursive scene traversals
    weak var cachedCardNode: SCNNode?

    // Card flip state
    private var isShowingBack = false

    // Performance optimization: Track if card has been initialized
    var hasInitializedCard = false

    // Haptic feedback
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)
    private let softHaptic = UIImpactFeedbackGenerator(style: .soft)

    init(_ parent: CarouselCardView) {
      self.parent = parent
      super.init()
      // Prepare haptic generators
      mediumHaptic.prepare()
      softHaptic.prepare()
    }

    @objc func handleTap(_ gesture: UITapGestureRecognizer) {
      guard let view = gesture.view as? SCNView,
        let cardNode = view.scene?.rootNode.childNode(withName: "creditCard", recursively: true)
      else { return }

      // Toggle flip state
      isShowingBack.toggle()

      // Medium haptic for flip action
      mediumHaptic.impactOccurred(intensity: 0.8)
      mediumHaptic.prepare()

      // Calculate target rotation (flip to back is π radians / 180 degrees)
      let targetY: Float = isShowingBack ? .pi : 0

      // Smooth flip animation with spring effect
      SCNTransaction.begin()
      SCNTransaction.animationDuration = 0.5
      SCNTransaction.animationTimingFunction = CAMediaTimingFunction(
        controlPoints: 0.34, 1.35, 0.64, 1.0)  // Springy feel
      cardNode.eulerAngles.y = targetY
      cardNode.eulerAngles.x = 0  // Reset vertical tilt on flip
      SCNTransaction.commit()

      parent.rotationAngle = Double(targetY)

      // Subtle haptic at the end of the flip
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { [weak self] in
        self?.softHaptic.impactOccurred(intensity: 0.6)
      }
    }
  }
}
