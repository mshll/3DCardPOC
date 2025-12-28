//
//  CardCarouselView.swift
//  3DCardPOC
//
//  Created by meshal on 11/10/25.
//

import Combine
import SwiftUI

struct CardCarouselView: View {
    @StateObject private var cardsData = CarouselCardsData()
    @State private var currentIndex = 0
    @State private var scrollPosition: Int?

    // Carousel layout constants (adjusted for vertical cards)
    private let cardWidthRatio: CGFloat = 0.42
    private let containerWidthRatio: CGFloat = 0.50
    private let carouselHeight: CGFloat = 420

    var body: some View {
        GeometryReader { geometry in
            let cardWidth = geometry.size.width * cardWidthRatio
            let containerWidth = geometry.size.width * containerWidthRatio
            let horizontalPadding = geometry.size.width * (1.0 - containerWidthRatio) / 2
            let spacerWidth = (containerWidth - cardWidth) / 2

            VStack(spacing: 0) {
                carouselSection(
                    geometry: geometry,
                    cardWidth: cardWidth,
                    containerWidth: containerWidth,
                    spacerWidth: spacerWidth,
                    horizontalPadding: horizontalPadding
                )

                pageIndicatorSection

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

    private func carouselSection(
        geometry: GeometryProxy,
        cardWidth: CGFloat,
        containerWidth: CGFloat,
        spacerWidth: CGFloat,
        horizontalPadding: CGFloat
    ) -> some View {
        ScrollViewReader { proxy in
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 0) {
                    ForEach(0..<cardsData.cards.count, id: \.self) { index in
                        HStack(spacing: 0) {
                            Spacer()
                                .frame(width: spacerWidth)

                            CarouselCardWrapper(
                                cardData: cardsData.cards[index],
                                design: cardsData.designs[index],
                                geometry: geometry
                            )
                            .frame(width: cardWidth)

                            Spacer()
                                .frame(width: spacerWidth)
                        }
                        .frame(width: containerWidth)
                        .id(index)
                    }
                }
                .scrollTargetLayout()
                .padding(.horizontal, horizontalPadding)
            }
            .scrollTargetBehavior(.viewAligned(limitBehavior: .always))
            .scrollPosition(id: $scrollPosition)
            .onChange(of: scrollPosition) { oldValue, newValue in
                if let newValue = newValue {
                    currentIndex = newValue
                }
            }
            .onAppear {
                scrollPosition = 0
            }
        }
        .frame(height: carouselHeight)
        .padding(.vertical)
    }

    // MARK: - Page Indicator Section

    private var pageIndicatorSection: some View {
        HStack(spacing: 8) {
            ForEach(0..<cardsData.cards.count, id: \.self) { index in
                Circle()
                    .fill(currentIndex == index ? Color.black : Color.gray.opacity(0.3))
                    .frame(width: 8, height: 8)
                    .animation(.easeInOut(duration: 0.2), value: currentIndex)
            }
        }
        .padding(.top, 20)
    }

    // MARK: - Card Info Section

    private var cardInfoSection: some View {
        let currentCard = cardsData.cards[currentIndex]

        return VStack(spacing: 20) {
            Text(currentCard.cardholderName)
                .font(.title2.bold())
                .foregroundColor(.black)

            HStack(spacing: 40) {
                cardInfoField(title: "Card Number", value: formatCardNumber(currentCard.cardNumber))
                cardInfoField(title: "Expires", value: currentCard.expiryDate)
                cardInfoField(title: "Design", value: "Design \(cardsData.designs[currentIndex])")
            }
        }
        .padding(.top, 30)
        .padding(.horizontal)
    }

    private func cardInfoField(title: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundColor(.gray)
            Text(value)
                .font(.body.bold())
                .foregroundColor(.black)
        }
    }

    // MARK: - Helper Methods

    private func formatCardNumber(_ number: String) -> String {
        let parts = number.split(separator: " ")
        guard parts.count == 4 else { return number }
        return "•••• \(parts[3])"
    }
}

// MARK: - Carousel Card Wrapper

struct CarouselCardWrapper: View {
    let cardData: Card3DData
    let design: Int
    @State private var rotationAngle: Double = 0
    let geometry: GeometryProxy

    private let cardWidthRatio: CGFloat = 0.48
    private let cardHeightRatio: CGFloat = 0.75
    private let maxRotationDegrees: CGFloat = 50.0
    private let rotationThreshold: Double = 0.001

    // Cycle through some colors for variety
    private var backgroundColor: Color {
        let colors: [Color] = [.blue, .purple, .green, .orange, .red]
        return colors[design % colors.count]
    }

    var body: some View {
        GeometryReader { cardGeometry in
            Card3DView(data: cardData)
                .cardStyle(.alphaTextured(design: design, backgroundColor: backgroundColor))
                .interaction(.tapOnly)
                .rotation($rotationAngle)
                .frame(
                    width: geometry.size.width * cardWidthRatio,
                    height: geometry.size.height * cardHeightRatio
                )
                .onChange(of: cardGeometry.frame(in: .global).midX) { oldMidX, newMidX in
                    updateRotation(for: newMidX, in: geometry)
                }
        }
        .frame(
            width: geometry.size.width * cardWidthRatio,
            height: geometry.size.height * cardHeightRatio
        )
    }

    private func updateRotation(for cardMidX: CGFloat, in geometry: GeometryProxy) {
        let screenCenterX = geometry.size.width / 2
        let offsetFromCenter = cardMidX - screenCenterX
        let normalizedOffset = offsetFromCenter / (geometry.size.width / 2)

        let rotationDegrees = -(normalizedOffset * maxRotationDegrees).rounded(.toNearestOrEven)
        let newRotation = rotationDegrees * .pi / 180.0

        if abs(newRotation - rotationAngle) > rotationThreshold {
            rotationAngle = newRotation
        }
    }
}

// MARK: - Carousel Cards Data Manager

class CarouselCardsData: ObservableObject {
    @Published var cards: [Card3DData] = []
    @Published var designs: [Int] = []

    private let defaultCardCount = 5
    private let cardholderNames = [
        "Meshal Almutairi",
        "Forsan Alsharabati",
        "Abdulaziz Karam",
        "Abdullah Almukhaizeem",
        "Mohammed Ramadan",
    ]
    private let cardPrefixes = ["4532", "5412", "4916", "5234", "4024"]
    private let expiryYearRange = 25...30
    private let cvvRange = 100...999

    init() {
        let generatedCards = generateRandomCards(count: defaultCardCount)
        cards = generatedCards
        designs = (0..<defaultCardCount).map { ($0 % 5) + 1 }
    }

    private func generateRandomCards(count: Int) -> [Card3DData] {
        (0..<count).map { index in
            createCard(at: index)
        }
    }

    private func createCard(at index: Int) -> Card3DData {
        Card3DData(
            cardholderName: cardholderNames[index % cardholderNames.count],
            cardNumber: generateCardNumber(),
            expiryDate: generateExpiryDate(),
            cvv: String(format: "%03d", Int.random(in: cvvRange))
        )
    }

    private func generateCardNumber() -> String {
        let prefix = cardPrefixes.randomElement() ?? cardPrefixes[0]
        let segments = (0..<3).map { _ in randomDigits(4) }
        return "\(prefix) \(segments.joined(separator: " "))"
    }

    private func generateExpiryDate() -> String {
        let month = Int.random(in: 1...12)
        let year = Int.random(in: expiryYearRange)
        return String(format: "%02d/%02d", month, year)
    }

    private func randomDigits(_ count: Int) -> String {
        (0..<count).map { _ in String(Int.random(in: 0...9)) }.joined()
    }
}

#Preview {
    CardCarouselView()
}
