//
//  ContentView.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @State private var cardRotation: Double = 0
    @State private var navigateToCarousel = false
    @State private var selectedDesign: Int = 1
    @State private var useAlphaTexture: Bool = true
    @State private var backgroundColor: Color = .blue

    private let maxCardHeight: CGFloat = 500

    // Sample card data
    private let cardData = Card3DData(
        cardholderName: "Meshal Almutairi",
        cardNumber: "4532 1234 5678 9010",
        expiryDate: "12/28",
        cvv: "123"
    )

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                // New Card3DView with builder pattern
                Card3DView(data: cardData)
                    .cardStyle(currentStyle)
                    .interaction(.freeRotation)
                    .rotation($cardRotation)
                    .frame(maxHeight: maxCardHeight)

                Spacer()

                styleControlsSection

                carouselNavigationButton
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .background(
                NavigationLink(
                    destination: CardCarouselView(),
                    isActive: $navigateToCarousel
                ) {
                    EmptyView()
                }
                .hidden()
            )
        }
        .preferredColorScheme(.light)
    }

    // MARK: - Current Style

    private var currentStyle: Card3DStyle {
        if useAlphaTexture {
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
                HStack(spacing: 15) {
                    Text("Background Color")
                        .font(.caption)
                        .foregroundColor(.gray)

                    ForEach([Color.blue, Color.purple, Color.green, Color.orange, Color.red], id: \.self) { color in
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

    // MARK: - Carousel Navigation Button

    private var carouselNavigationButton: some View {
        Button(action: {
            navigateToCarousel = true
        }) {
            Text("View Card Carousel")
                .font(.body.bold())
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .padding()
                .background(.black)
                .cornerRadius(.infinity)
        }
        .padding(.horizontal, 30)
        .padding(.bottom, 20)
    }
}

#Preview {
    ContentView()
}
