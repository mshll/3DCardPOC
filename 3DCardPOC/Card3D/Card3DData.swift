import SwiftUI

// MARK: - Card Data

struct Card3DData: Equatable {
    let cardholderName: String
    let cardNumber: String      // "4532 1234 5678 9010"
    let expiryDate: String      // "12/28"
    let cvv: String             // "123"
}

// MARK: - Card Display Info

struct CardDisplayInfo: Identifiable {
    let id = UUID()
    let cardName: String        // "World Mastercard"
    let cardType: String        // "Credit Card"
    let data: Card3DData
    let style: Card3DStyle

    var maskedNumber: String {
        let parts = data.cardNumber.split(separator: " ")
        guard parts.count == 4 else { return data.cardNumber }
        return "****\(parts[3])"
    }
}

// MARK: - Text Visibility

struct Card3DTextVisibility: Equatable {
    var cardNumber: Bool = true
    var cardholderName: Bool = true
    var expiryDate: Bool = true
    var cvv: Bool = true

    init(
        cardNumber: Bool = true,
        cardholderName: Bool = true,
        expiryDate: Bool = true,
        cvv: Bool = true
    ) {
        self.cardNumber = cardNumber
        self.cardholderName = cardholderName
        self.expiryDate = expiryDate
        self.cvv = cvv
    }
}
