//
//  ContentView.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var cardDetails = CardDetailsModel()
    @State private var showEditSheet = false
    @State private var cardRotation: Double = 0
    @State private var navigateToCarousel = false

    private let maxCardHeight: CGFloat = 500
    private let templateButtonSize: CGFloat = 50
    private let templateButtonSpacing: CGFloat = 20
    private let sectionSpacing: CGFloat = 20

    var body: some View {
        NavigationView {
            VStack {
                Spacer()

                CreditCard3DView(cardDetails: cardDetails, rotationAngle: $cardRotation)
                    .frame(maxHeight: maxCardHeight)

                Spacer()

                templateSelectorSection

                carouselNavigationButton
            }
            .background(Color.white)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showEditSheet = true
                    }) {
                        Label("Edit", systemImage: "pencil.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
            }
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
        .sheet(isPresented: $showEditSheet) {
            EditCardView(cardDetails: cardDetails)
        }
    }

    // MARK: - Template Selector Section

    private var templateSelectorSection: some View {
        VStack(spacing: sectionSpacing) {
            Text("Select card type")
                .font(.caption.bold())
                .foregroundStyle(.black)

            HStack(spacing: templateButtonSpacing) {
                ForEach(CardTemplate.allCases, id: \.self) { template in
                    templateButton(for: template)
                }
            }
        }
        .padding(.bottom, 30)
    }

    private func templateButton(for template: CardTemplate) -> some View {
        Button(action: {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                cardDetails.cardTemplate = template
            }
        }) {
            VStack(spacing: 8) {
                Circle()
                    .fill(Color.clear)
                    .frame(width: templateButtonSize, height: templateButtonSize)
                    .overlay(
                        Circle()
                            .strokeBorder(
                                Color.black,
                                lineWidth: cardDetails.cardTemplate == template ? 2 : 0
                            )
                    )
                    .overlay(
                        templatePreviewColor(for: template)
                            .clipShape(Circle())
                            .padding(4)
                    )

                Text(template.rawValue)
                    .font(.caption)
                    .foregroundColor(.black)
            }
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

    // MARK: - Helper Methods

    private func templatePreviewColor(for template: CardTemplate) -> Color {
        switch template.pattern {
        case .solid(let color):
            return color
        case .gradient(let colors, _):
            return colors.first ?? .black
        case .image(_):
            return .gray
        case .imageWithColor(_, let color):
            return color
        }
    }
}

#Preview {
  ContentView()
}
