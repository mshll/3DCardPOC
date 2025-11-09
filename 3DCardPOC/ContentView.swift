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

  var body: some View {
    NavigationView {

      VStack {
        Spacer()

        CreditCard3DView(cardDetails: cardDetails, rotationAngle: $cardRotation)
              .frame(maxHeight: 500)

        Spacer()

        // Template selector buttons
          VStack(spacing: 20) {
              Text("Select card type")
                  .font(.caption.bold())
                  .foregroundStyle(.black)
              
              HStack(spacing: 20) {
                ForEach(CardTemplate.allCases, id: \.self) { template in
                  Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                      cardDetails.cardTemplate = template
                    }
                  }) {
                    VStack(spacing: 8) {
                      Circle()
                        .fill(Color.clear)
                        .frame(width: 50, height: 50)
                        .overlay(
                          Circle()
                            .strokeBorder(
                              Color.black, lineWidth: cardDetails.cardTemplate == template ? 2 : 0)
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
              }

          }        .padding(.bottom, 30)
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
    }
    .sheet(isPresented: $showEditSheet) {
      EditCardView(cardDetails: cardDetails)
    }
  }

  // Helper function to get preview color for template
  func templatePreviewColor(for template: CardTemplate) -> Color {
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
