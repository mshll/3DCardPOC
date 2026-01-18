//
//  ContentView.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    let selectedCard: CardDisplayInfo?

    @State private var cardRotation: Double = 0
    @State private var selectedDesign: Int = 1
    @State private var useAlphaTexture: Bool = false
    @State private var backgroundColor: Color = Color(red: 0.10, green: 0.21, blue: 0.36)

    private let cardColors: [Color] = [
        Color(red: 0.10, green: 0.21, blue: 0.36),
        Color(red: 0.22, green: 0.25, blue: 0.32),
        Color(red: 0.83, green: 0.69, blue: 0.22),
        Color(red: 0.72, green: 0.43, blue: 0.47),
        Color(red: 0.12, green: 0.16, blue: 0.22),
    ]

    private let maxCardHeight: CGFloat = 500

    private var cardData: Card3DData {
        selectedCard?.data ?? Card3DData(
            cardholderName: "Meshal Almutairi",
            cardNumber: "4532 1234 5678 9010",
            expiryDate: "12/28",
            cvv: "123"
        )
    }

    init(selectedCard: CardDisplayInfo? = nil) {
        self.selectedCard = selectedCard
    }

    var body: some View {
        VStack {
            Spacer()

            Card3DView(data: cardData)
                .cardStyle(currentStyle)
                .interaction(.freeRotation)
                .rotation($cardRotation)
                .frame(maxHeight: maxCardHeight)

            Spacer()

            if selectedCard == nil {
                styleControlsSection
            }
        }
        .background(Color.white)
        .navigationTitle(selectedCard?.cardName ?? "3D Card")
        .navigationBarTitleDisplayMode(.inline)
        .preferredColorScheme(.light)
    }

    // MARK: - Current Style

    private var currentStyle: Card3DStyle {
        if let card = selectedCard {
            return card.style
        } else if useAlphaTexture {
            return .alphaTextured(design: selectedDesign, backgroundColor: backgroundColor)
        } else {
            return .opaqueTextured(design: selectedDesign)
        }
    }

    // MARK: - Style Controls Section

    private var styleControlsSection: some View {
        VStack(spacing: 20) {
            // Design selector
            VStack(spacing: 10) {
                Text("Card Design")
                    .font(.caption.bold())
                    .foregroundStyle(.black)

                HStack(spacing: 15) {
                    ForEach(1...5, id: \.self) { design in
                        designButton(for: design)
                    }
                }
            }

            // Texture mode toggle
            Toggle("Use Alpha Texture + Color", isOn: $useAlphaTexture)
                .padding(.horizontal, 30)
                .foregroundColor(.black)

            // Color picker (only when alpha texture is enabled)
            if useAlphaTexture {
                HStack(spacing: 12) {
                    Text("Background")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ForEach(Array(cardColors.enumerated()), id: \.offset) { _, color in
                        colorButton(for: color)
                    }
                }
            }
        }
        .padding(.bottom, 30)
    }

    private func designButton(for design: Int) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                selectedDesign = design
            }
        }) {
            Circle()
                .fill(Color.gray.opacity(0.2))
                .frame(width: 44, height: 44)
                .overlay(
                    Text("\(design)")
                        .font(.body.bold())
                        .foregroundColor(selectedDesign == design ? .white : .black)
                )
                .background(
                    Circle()
                        .fill(selectedDesign == design ? Color.black : Color.clear)
                )
        }
    }

    private func colorButton(for color: Color) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                backgroundColor = color
            }
        }) {
            Circle()
                .fill(color)
                .frame(width: 30, height: 30)
                .overlay(
                    Circle()
                        .strokeBorder(
                            Color.black,
                            lineWidth: backgroundColor == color ? 2 : 0
                        )
                )
        }
    }

}

#Preview {
    ContentView()
}
