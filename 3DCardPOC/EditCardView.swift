//
//  EditCardView.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import SwiftUI

struct EditCardView: View {
    @ObservedObject var cardDetails: CardDetailsModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Card Information")) {
                    TextField("Cardholder Name", text: $cardDetails.cardholderName)
                        .textCase(.uppercase)
                        .autocapitalization(.allCharacters)

                    TextField("Card Number", text: $cardDetails.cardNumber)
                        .keyboardType(.numberPad)

                    HStack {
                        TextField("Expiry Date", text: $cardDetails.expiryDate)
                            .frame(maxWidth: .infinity)

                        TextField("CVV", text: $cardDetails.cvv)
                            .keyboardType(.numberPad)
                            .frame(width: 80)
                    }

//                    TextField("Bank Name", text: $cardDetails.bankName)
//                        .textCase(.uppercase)
//                        .autocapitalization(.allCharacters)
                }

                Section {
                    Button(action: resetToDefaults) {
                        Label("Reset to Defaults", systemImage: "arrow.counterclockwise")
                            .foregroundColor(.blue)
                    }
                }
            }
            .navigationTitle("Edit Card Details")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                    .fontWeight(.semibold)
                }
            }
        }
    }

    func resetToDefaults() {
        cardDetails.cardholderName = "JOHN DOE"
        cardDetails.cardNumber = "4532 1234 5678 9010"
        cardDetails.expiryDate = "12/28"
        cardDetails.cvv = "123"
        cardDetails.bankName = "SWIFT BANK"
        cardDetails.cardTemplate = .premium
    }
}
