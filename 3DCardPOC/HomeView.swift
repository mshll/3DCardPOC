//
//  HomeView.swift
//  3DCardPOC
//

import Combine
import SwiftUI
import UIKit

// MARK: - Home View

struct HomeView: View {
    @StateObject private var viewModel = HomeViewModel()

    var body: some View {
        ZStack {
            NavigationView {
                ZStack(alignment: .top) {
                    // Background
                    Color(red: 0.949, green: 0.949, blue: 0.949)
                        .ignoresSafeArea()

                    VStack(spacing: 0) {
                        // Header with gradient - ignores safe area
                        headerSection

                        // White card container - everything below header
                        mainContentCard
                    }
                }
                .navigationBarHidden(true)
            }
            .navigationViewStyle(.stack)
            .preferredColorScheme(.light)

            if let expandedIndex = viewModel.expandedCardIndex,
               expandedIndex < viewModel.cards.count {
                ExpandedCardOverlay(
                    card: viewModel.cards[expandedIndex],
                    sourceFrame: viewModel.expandedSourceFrame,
                    sourceRotation: viewModel.expandedSourceRotation,
                    sourceScale: viewModel.expandedSourceScale,
                    onReady: { viewModel.hideSourceCard() },
                    onDismiss: { viewModel.collapseCard() }
                )
            }
        }
    }

    // MARK: - Header Section

    private var headerSection: some View {
        ZStack {
            LinearGradient(
                colors: [
                    Color(red: 0.35, green: 0.08, blue: 0.14),
                    Color(red: 0.25, green: 0.05, blue: 0.10)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
        }
        .frame(height: 140)
        .ignoresSafeArea(edges: .top)
    }

    // MARK: - Main Content Card

    private var mainContentCard: some View {
        VStack(spacing: 0) {
            // Card title and subtitle
            VStack(spacing: 2) {
                Text(viewModel.activeCard.cardName)
                    .font(.footnote.bold())
                    .foregroundColor(.black)

                Text("\(viewModel.activeCard.cardType) \(viewModel.activeCard.maskedNumber)")
                    .font(.caption)
                    .foregroundColor(.gray)
            }
            .padding(.top, 20)
            .animation(.easeInOut(duration: 0.2), value: viewModel.activeIndex)

            // Card carousel
            GeometryReader { geometry in
                cardCarousel(geometry: geometry)
            }
            .frame(height: 400)

            // Page indicator
            pageIndicator
                .padding(.top, 8)

            Spacer()

            // Balance section
            balanceSection
                .padding(.bottom, 20)

            // Quick actions
            quickActionsSection
                .padding(.bottom, 24)

            Spacer()
            
            // View 3D button
            view3DButton
                .padding(.bottom, 32)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            ZStack {
                Color(red: 0.949, green: 0.949, blue: 0.949)

                LinearGradient(
                    stops: [
                        .init(color: Color(red: 0.71, green: 0.71, blue: 0.71), location: 0.08),
                        .init(color: Color(red: 0.949, green: 0.949, blue: 0.949), location: 0.5)
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .opacity(viewModel.isActiveCardSleeping ? 1 : 0)
            }
            .animation(.easeInOut(duration: 0.5), value: viewModel.isActiveCardSleeping)
        )
        .clipShape(
            RoundedCorner(radius: 24, corners: [.topLeft, .topRight])
        )
        .offset(y: -50)
    }

    // MARK: - Card Carousel

    private func cardCarousel(geometry: GeometryProxy) -> some View {
        let cardWidth = geometry.size.width * 0.55
        let cardSpacing: CGFloat = 12
        let horizontalPadding = (geometry.size.width - cardWidth) / 2

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cardSpacing) {
                ForEach(Array(viewModel.cards.enumerated()), id: \.element.id) { index, card in
                    HomeCarouselCardView(
                        card: card,
                        index: index,
                        screenWidth: geometry.size.width,
                        viewModel: viewModel
                    )
                    .frame(width: cardWidth, height: 420)
                    .id(index)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, horizontalPadding)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $viewModel.scrollPosition)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 6) {
            ForEach(0..<viewModel.cards.count, id: \.self) { index in
                if index == viewModel.activeIndex {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.black)
                        .frame(width: 20, height: 8)
                } else {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color.gray.opacity(0.3))
                        .frame(width: 8, height: 8)
                }
            }
        }
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
        .background(
            Capsule()
                .fill(Color.white)
                .overlay(
                    Capsule()
                        .strokeBorder(Color.gray.opacity(0.2), lineWidth: 1)
                )
        )
        .animation(.easeInOut(duration: 0.2), value: viewModel.activeIndex)
    }

    // MARK: - Balance Section

    private var balanceSection: some View {
        VStack(spacing: 8) {
            HStack(alignment: .lastTextBaseline, spacing: 2) {
                Text("KD")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
                Text("4,526")
                    .font(.system(size: 48, weight: .bold))
                    .foregroundColor(.black)
                Text(".050")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.black)
            }

            HStack(spacing: 6) {
                Image(systemName: "creditcard.fill")
                    .font(.caption)
                    .foregroundColor(.gray)
                Text("Available balance")
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
    }

    // MARK: - Quick Actions Section

    private var quickActionsSection: some View {
        HStack(spacing: 24) {
            QuickActionButton(icon: "plus", label: "Pay")
            QuickActionButton(
                icon: viewModel.isActiveCardSleeping ? "moon.zzz.fill" : "moon.fill",
                label: viewModel.isActiveCardSleeping ? "Wake" : "Sleep",
                action: { viewModel.toggleActiveCardSleep() }
            )
            QuickActionButton(icon: "doc.text.fill", label: "Card details")
            QuickActionButton(icon: "ellipsis", label: "More")
        }
        .padding(.horizontal, 24)
        .animation(.easeInOut(duration: 0.2), value: viewModel.isActiveCardSleeping)
    }

    // MARK: - View 3D Button

    private var view3DButton: some View {
        let buttonColor = Color(red: 0.17, green: 0.17, blue: 0.17) // #2B2B2B

        return NavigationLink(destination: ContentView(selectedCard: viewModel.activeCard)) {
            HStack(spacing: 8) {
                Image(systemName: "cube.fill")
                    .font(.subheadline.bold())
                Text("View in 3D")
                    .font(.subheadline.bold())
            }
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .background(buttonColor)
            .clipShape(Capsule())
        }
        .padding(.horizontal, 24)
    }
}

// MARK: - Quick Action Button

private struct QuickActionButton: View {
    let icon: String
    let label: String
    var action: (() -> Void)? = nil

    private let buttonColor = Color(red: 0.17, green: 0.17, blue: 0.17) // #2B2B2B

    var body: some View {
        Button(action: { action?() }) {
            VStack(spacing: 6) {
                ZStack {
                    Circle()
                        .fill(buttonColor)
                        .frame(width: 50, height: 50)

                    Image(systemName: icon)
                        .font(.system(size: 18))
                        .foregroundColor(.white)
                }

                Text(label)
                    .font(.caption2)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Home Carousel Card View

private struct HomeCarouselCardView: View {
    let card: CardDisplayInfo
    let index: Int
    let screenWidth: CGFloat
    @ObservedObject var viewModel: HomeViewModel

    private let maxYRotationDegrees: Double = 25.0
    private let maxXRotationDegrees: Double = 5.0
    private let minScale: CGFloat = 0.8
    private let sleepTiltDegrees: Double = 45.0
    private let sleepScaleMultiplier: CGFloat = 0.85

    var body: some View {
        GeometryReader { geometry in
            let cardMidX = geometry.frame(in: .global).midX
            let screenCenterX = screenWidth / 2
            let offsetFromCenter = cardMidX - screenCenterX
            let normalizedOffset = offsetFromCenter / (screenWidth / 2)
            let absOffset = abs(normalizedOffset)

            let yTilt = -normalizedOffset * maxYRotationDegrees * .pi / 180.0
            let baseTilt = -absOffset * maxXRotationDegrees * .pi / 180.0
            let isSleeping = viewModel.isSleeping(cardId: card.id)
            let isSleepAnimating = viewModel.isSleepAnimating(cardId: card.id)
            let sleepTilt = sleepTiltDegrees * .pi / 180.0
            let xTilt = baseTilt - (isSleeping ? sleepTilt : 0)
            let baseScale = 1.0 - (absOffset * (1.0 - minScale))
            let scale = isSleeping ? baseScale * sleepScaleMultiplier : baseScale
            let animDuration = isSleepAnimating ? 1.2 : 0.15

            Card3DView(data: card.data)
                .cardStyle(card.style)
                .interaction(.disabled)
                .cardScale(scale)
                .xRotation(xTilt)
                .rotation(.constant(yTilt))
                .animationDuration(animDuration)
            .opacity(viewModel.shouldHideSourceCard && viewModel.expandedCardIndex == index ? 0 : 1)
            .onTapGesture {
                viewModel.expandCard(
                    index: index,
                    frame: geometry.frame(in: .global),
                    rotation: yTilt,
                    scale: scale
                )
            }
        }
    }
}

// MARK: - Rounded Corner Shape

struct RoundedCorner: Shape {
    var radius: CGFloat = .infinity
    var corners: UIRectCorner = .allCorners

    func path(in rect: CGRect) -> Path {
        let path = UIBezierPath(
            roundedRect: rect,
            byRoundingCorners: corners,
            cornerRadii: CGSize(width: radius, height: radius)
        )
        return Path(path.cgPath)
    }
}

// MARK: - Home View Model

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var scrollPosition: Int? = 0 {
        didSet {
            if scrollPosition != oldValue {
                haptic.impactOccurred(intensity: 0.6)
            }
        }
    }
    @Published private(set) var cards: [CardDisplayInfo] = []

    // Expansion state
    @Published var expandedCardIndex: Int? = nil
    @Published var expandedSourceFrame: CGRect = .zero
    @Published var expandedSourceRotation: Double = 0
    @Published var expandedSourceScale: CGFloat = 1.0
    @Published var shouldHideSourceCard: Bool = false

    // Sleep state
    @Published var sleepingCardIds: Set<UUID> = []
    @Published var sleepAnimatingCardIds: Set<UUID> = []

    private let haptic = UIImpactFeedbackGenerator(style: .light)
    private let mediumHaptic = UIImpactFeedbackGenerator(style: .medium)

    private let modernColors: [Color] = [
        Color(red: 0.10, green: 0.21, blue: 0.36),
        Color(red: 0.22, green: 0.25, blue: 0.32),
        Color(red: 0.83, green: 0.69, blue: 0.22),
        Color(red: 0.72, green: 0.43, blue: 0.47),
        Color(red: 0.12, green: 0.16, blue: 0.22),
    ]

    var activeIndex: Int {
        scrollPosition ?? 0
    }

    var activeCard: CardDisplayInfo {
        guard activeIndex < cards.count, !cards.isEmpty else {
            return cards.first ?? CardDisplayInfo(
                cardName: "Card",
                cardType: "Card",
                data: Card3DData(cardholderName: "", cardNumber: "", expiryDate: "", cvv: ""),
                style: .opaqueTextured(design: 1)
            )
        }
        return cards[activeIndex]
    }

    var isActiveCardSleeping: Bool {
        sleepingCardIds.contains(activeCard.id)
    }

    func isSleeping(cardId: UUID) -> Bool {
        sleepingCardIds.contains(cardId)
    }

    func isSleepAnimating(cardId: UUID) -> Bool {
        sleepAnimatingCardIds.contains(cardId)
    }

    func toggleActiveCardSleep() {
        let cardId = activeCard.id
        mediumHaptic.impactOccurred()

        sleepAnimatingCardIds.insert(cardId)

        if sleepingCardIds.contains(cardId) {
            sleepingCardIds.remove(cardId)
        } else {
            sleepingCardIds.insert(cardId)
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.3) { [weak self] in
            self?.sleepAnimatingCardIds.remove(cardId)
        }
    }

    init() {
        haptic.prepare()
        mediumHaptic.prepare()
        generateCards()
    }

    func expandCard(index: Int, frame: CGRect, rotation: Double, scale: CGFloat) {
        expandedSourceFrame = frame
        expandedSourceRotation = rotation
        expandedSourceScale = scale
        expandedCardIndex = index
    }

    func hideSourceCard() {
        shouldHideSourceCard = true
    }

    func collapseCard() {
        shouldHideSourceCard = false
        expandedCardIndex = nil
    }

    private func generateCards() {
        let cardSpecs: [(name: String, type: String, holderName: String)] = [
            ("World Mastercard", "Credit Card", "Meshal Almutairi"),
            ("Platinum Visa", "Credit Card", "Forsan Alsharabati"),
            ("Gold Mastercard", "Debit Card", "Abdulaziz Karam"),
            ("Prime Card", "Credit Card", "Abdullah Almukhaizeem"),
            ("Business Elite", "Corporate Card", "Mohammed Ramadan"),
            ("Rewards Plus", "Credit Card", "Khalid Alsaif"),
            ("Travel Card", "Prepaid Card", "Omar Alharbi"),
            ("Student Card", "Debit Card", "Yousef Aldosari"),
            ("Family Card", "Credit Card", "Faisal Alqahtani"),
            ("Digital Card", "Virtual Card", "Tariq Alsultan")
        ]

        cards = cardSpecs.enumerated().map { index, spec in
            let data = Card3DData(
                cardholderName: spec.holderName,
                cardNumber: generateCardNumber(),
                expiryDate: generateExpiryDate(),
                cvv: String(format: "%03d", Int.random(in: 100...999))
            )

            let style: Card3DStyle
            if index < 5 {
                style = .opaqueTextured(design: index + 1)
            } else {
                style = .alphaTextured(design: index - 4, backgroundColor: modernColors[index - 5])
            }

            return CardDisplayInfo(
                cardName: spec.name,
                cardType: spec.type,
                data: data,
                style: style
            )
        }
    }

    private func generateCardNumber() -> String {
        let prefixes = ["4532", "5412", "4916", "5234", "4024"]
        let prefix = prefixes.randomElement() ?? "4532"
        let segments = (0..<3).map { _ in
            (0..<4).map { _ in String(Int.random(in: 0...9)) }.joined()
        }
        return "\(prefix) \(segments.joined(separator: " "))"
    }

    private func generateExpiryDate() -> String {
        let month = Int.random(in: 1...12)
        let year = Int.random(in: 25...30)
        return String(format: "%02d/%02d", month, year)
    }
}

// MARK: - Preview

#Preview {
    HomeView()
}
