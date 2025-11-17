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
  @Environment(\.dismiss) private var dismiss

  var body: some View {
    GeometryReader { geometry in
      VStack(spacing: 0) {
        // Header
        HStack {
          Button(action: {
            dismiss()
          }) {
            HStack(spacing: 8) {
              Image(systemName: "chevron.left")
                .font(.title3.bold())
            }
            .foregroundColor(.primary)
          }
          .padding()

          Spacer()

          Text("My Cards")
            .font(.title2.bold())
            .foregroundColor(.primary)

          Spacer()

          // Placeholder for symmetry
          Button(action: {}) {
            Image(systemName: "chevron.left")
              .font(.title3.bold())
          }
          .opacity(0)
          .padding()
        }
        .padding(.top, 10)

        // Page indicator
        HStack(spacing: 8) {
          ForEach(0..<cardsData.cards.count, id: \.self) { index in
            Circle()
              .fill(currentIndex == index ? Color.blue : Color.gray.opacity(0.3))
              .frame(width: 8, height: 8)
              .animation(.easeInOut(duration: 0.2), value: currentIndex)
          }
        }
        .padding(.top, 20)

        // Carousel
        TabView(selection: $currentIndex) {
          ForEach(0..<cardsData.cards.count, id: \.self) { index in
            CarouselCardWrapper(
              cardData: cardsData.cards[index],
              geometry: geometry
            )
            .tag(index)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
        .frame(maxHeight: geometry.size.height * 0.6)

        // Card info section
        VStack(spacing: 20) {
          Text(cardsData.cards[currentIndex].cardholderName)
            .font(.title2.bold())
            .foregroundColor(.black)

          HStack(spacing: 40) {
            VStack(alignment: .leading, spacing: 4) {
              Text("Card Number")
                .font(.caption)
                .foregroundColor(.gray)
              Text(formatCardNumber(cardsData.cards[currentIndex].cardNumber))
                .font(.body.bold())
                .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 4) {
              Text("Expires")
                .font(.caption)
                .foregroundColor(.gray)
              Text(cardsData.cards[currentIndex].expiryDate)
                .font(.body.bold())
                .foregroundColor(.black)
            }

            VStack(alignment: .leading, spacing: 4) {
              Text("Type")
                .font(.caption)
                .foregroundColor(.gray)
              Text(cardsData.cards[currentIndex].cardTemplate.rawValue)
                .font(.body.bold())
                .foregroundColor(.black)
            }
          }
        }
        .padding(.top, 30)
        .padding(.horizontal)

        Spacer()
      }
      .background(Color.white)
    }
    .navigationBarHidden(true)
  }

  private func formatCardNumber(_ number: String) -> String {
    let parts = number.split(separator: " ")
    guard parts.count == 4 else { return number }
    return "•••• \(parts[3])"
  }
}

// Wrapper to hold card data and rotation state
struct CarouselCardWrapper: View {
  @ObservedObject var cardData: CardDetailsModel
  @State private var rotationAngle: Double = 0
  let geometry: GeometryProxy

  var body: some View {
    GeometryReader { cardGeometry in
      CarouselCardView(cardDetails: cardData, rotationAngle: $rotationAngle)
        .frame(width: geometry.size.width * 0.85, height: geometry.size.height * 0.5)
        .onChange(of: cardGeometry.frame(in: .global).midX) { newMidX in
          // Performance optimization: Calculate rotation directly without extra function calls
          let screenCenterX = geometry.size.width / 2
          let offsetFromCenter = newMidX - screenCenterX
          let normalizedOffset = offsetFromCenter / (geometry.size.width / 2)

          // Calculate rotation with reduced precision to minimize updates
          let rotationDegrees = (normalizedOffset * 50.0).rounded(.toNearestOrEven)
          let newRotation = rotationDegrees * .pi / 180.0

          // Only update if rotation actually changed (reduces unnecessary updates)
          if abs(newRotation - rotationAngle) > 0.001 {
            rotationAngle = newRotation
          }
        }
    }
    .padding(.horizontal, geometry.size.width * 0.075)
  }
}

// Data manager for carousel cards
class CarouselCardsData: ObservableObject {
  @Published var cards: [CardDetailsModel] = []

  init() {
    cards = generateRandomCards(count: 5)
  }

  private func generateRandomCards(count: Int) -> [CardDetailsModel] {
    let names = [
      "Meshal Almutairi", "Forsan Alsharabati", "Abdulaziz Karam", "Abdullah Almukhaizeem",
      "Mohammed Ramadan", "Abdullah Alshammari",
    ]

    let templates = CardTemplate.allCases

    var generatedCards: [CardDetailsModel] = []

    for i in 0..<count {
      let card = CardDetailsModel()

      // Random name
      card.cardholderName = names[i % names.count]

      // Random card number (using different starting digits for variety)
      let prefixes = ["4532", "5412", "4916", "5234", "4024"]
      let prefix = prefixes.randomElement() ?? "4532"
      card.cardNumber = "\(prefix) \(randomDigits(4)) \(randomDigits(4)) \(randomDigits(4))"

      // Random expiry date (future dates)
      let month = Int.random(in: 1...12)
      let year = Int.random(in: 25...30)
      card.expiryDate = String(format: "%02d/%02d", month, year)

      // Random CVV
      card.cvv = String(format: "%03d", Int.random(in: 100...999))

      // Random template
      card.cardTemplate = templates[i % templates.count]

      generatedCards.append(card)
    }

    return generatedCards
  }

  private func randomDigits(_ count: Int) -> String {
    var result = ""
    for _ in 0..<count {
      result += String(Int.random(in: 0...9))
    }
    return result
  }
}

#Preview {
  CardCarouselView()
}
