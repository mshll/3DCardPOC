//
//  CardCarouselView.swift
//  3DCardPOC
//
//  Created by meshal on 11/10/25.
//

import Combine
import SwiftUI

// MARK: - Card Carousel View

struct CardCarouselView: View {
    @StateObject private var viewModel = CarouselViewModel()

    var body: some View {
        GeometryReader { geometry in
            VStack(spacing: 24) {
                carouselSection(geometry: geometry)
                pageIndicator
                Spacer()
                cardInfoSection
                Spacer()
            }
            .background(Color.white)
        }
        .navigationTitle("My Cards")
        .navigationBarTitleDisplayMode(.inline)
    }

    // MARK: - Carousel Section

    private func carouselSection(geometry: GeometryProxy) -> some View {
        let config = CarouselConfig(screenWidth: geometry.size.width)

        return ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: config.cardSpacing) {
                ForEach(viewModel.cardIndices, id: \.self) { index in
                    CarouselCardView(
                        cardData: viewModel.cards[index],
                        cardStyle: viewModel.cardStyles[index],
                        screenWidth: geometry.size.width
                    )
                    .frame(width: config.cardWidth, height: config.cardHeight)
                    .allowsHitTesting(index == viewModel.activeIndex)
                    .id(index)
                }
            }
            .scrollTargetLayout()
            .padding(.horizontal, config.horizontalPadding)
        }
        .scrollTargetBehavior(.viewAligned)
        .scrollPosition(id: $viewModel.scrollPosition)
        .frame(height: config.carouselHeight)
    }

    // MARK: - Page Indicator

    private var pageIndicator: some View {
        HStack(spacing: 8) {
            ForEach(viewModel.cardIndices, id: \.self) { index in
                Circle()
                    .fill(index == viewModel.activeIndex ? Color.black : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
            }
        }
        .animation(.easeInOut(duration: 0.2), value: viewModel.activeIndex)
    }

    // MARK: - Card Info Section

    private var cardInfoSection: some View {
        VStack(spacing: 20) {
            Text(viewModel.activeCard.cardholderName)
                .font(.title2.bold())
                .foregroundColor(.black)

            HStack(spacing: 40) {
                InfoField(title: "Card Number", value: viewModel.maskedCardNumber)
                InfoField(title: "Expires", value: viewModel.activeCard.expiryDate)
                InfoField(title: "Design", value: "Design \(viewModel.activeDesign)")
            }
        }
        .padding(.horizontal)
        .animation(.easeInOut(duration: 0.2), value: viewModel.activeIndex)
    }
}

// MARK: - Info Field

private struct InfoField: View {
    let title: String
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.body.bold())
                .foregroundColor(.black)
        }
    }
}

// MARK: - Carousel Card View

private struct CarouselCardView: View {
    let cardData: Card3DData
    let cardStyle: CarouselCardStyle
    let screenWidth: CGFloat

    private let maxRotationDegrees: Double = 35.0

    var body: some View {
        GeometryReader { geometry in
            let cardMidX = geometry.frame(in: .global).midX
            let screenCenterX = screenWidth / 2
            let offsetFromCenter = cardMidX - screenCenterX
            let normalizedOffset = offsetFromCenter / (screenWidth / 2)
            let tiltRotation = -normalizedOffset * maxRotationDegrees * .pi / 180.0

            Card3DView(data: cardData)
                .cardStyle(cardStyle.style)
                .interaction(.tapOnly)
                .rotation(.constant(tiltRotation))
        }
    }
}

// MARK: - Carousel Configuration

private struct CarouselConfig {
    let screenWidth: CGFloat

    var cardWidth: CGFloat { screenWidth * 0.52 }
    var cardHeight: CGFloat { 380 }
    var cardSpacing: CGFloat { 16 }
    var carouselHeight: CGFloat { 420 }
    var horizontalPadding: CGFloat { (screenWidth - cardWidth) / 2 }
}

// MARK: - Carousel Card Style

struct CarouselCardStyle {
    let design: Int
    let isAlpha: Bool
    let backgroundColor: Color?

    var style: Card3DStyle {
        if isAlpha, let color = backgroundColor {
            return .alphaTextured(design: design, backgroundColor: color)
        } else {
            return .opaqueTextured(design: design)
        }
    }
}

// MARK: - Carousel View Model

@MainActor
final class CarouselViewModel: ObservableObject {
    @Published var scrollPosition: Int? = 0
    @Published private(set) var cards: [Card3DData] = []
    @Published private(set) var cardStyles: [CarouselCardStyle] = []

    // Modern credit card colors
    private let modernColors: [Color] = [
        Color(red: 0.10, green: 0.21, blue: 0.36),  // Navy
        Color(red: 0.22, green: 0.25, blue: 0.32),  // Charcoal
        Color(red: 0.83, green: 0.69, blue: 0.22),  // Gold
        Color(red: 0.72, green: 0.43, blue: 0.47),  // Rose Gold
        Color(red: 0.12, green: 0.16, blue: 0.22),  // Midnight
    ]

    var activeIndex: Int {
        scrollPosition ?? 0
    }

    var cardIndices: Range<Int> {
        0..<cards.count
    }

    var activeCard: Card3DData {
        guard activeIndex < cards.count else { return cards[0] }
        return cards[activeIndex]
    }

    var activeStyle: CarouselCardStyle {
        guard activeIndex < cardStyles.count else { return cardStyles[0] }
        return cardStyles[activeIndex]
    }

    var activeDesign: Int {
        activeStyle.design
    }

    var maskedCardNumber: String {
        let parts = activeCard.cardNumber.split(separator: " ")
        guard parts.count == 4 else { return activeCard.cardNumber }
        return "•••• \(parts[3])"
    }

    init() {
        generateCards()
    }

    private func generateCards() {
        let names = [
            "Meshal Almutairi",
            "Forsan Alsharabati",
            "Abdulaziz Karam",
            "Abdullah Almukhaizeem",
            "Mohammed Ramadan",
            "Khalid Alsaif",
            "Omar Alharbi",
            "Yousef Aldosari",
            "Faisal Alqahtani",
            "Tariq Alsultan"
        ]

        // Generate 10 cards: 5 opaque + 5 alpha with colors
        cards = names.map { name in
            Card3DData(
                cardholderName: name,
                cardNumber: generateCardNumber(),
                expiryDate: generateExpiryDate(),
                cvv: String(format: "%03d", Int.random(in: 100...999))
            )
        }

        // First 5: opaque textures (designs 1-5)
        // Next 5: alpha textures with modern colors (designs 1-5)
        cardStyles = (0..<10).map { index in
            if index < 5 {
                return CarouselCardStyle(design: index + 1, isAlpha: false, backgroundColor: nil)
            } else {
                return CarouselCardStyle(design: index - 4, isAlpha: true, backgroundColor: modernColors[index - 5])
            }
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
    NavigationStack {
        CardCarouselView()
    }
}
