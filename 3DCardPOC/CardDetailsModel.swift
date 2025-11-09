//
//  CardDetailsModel.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import SwiftUI
import Combine


class CardDetailsModel: ObservableObject {
    @Published var cardholderName: String = "Meshal Almutairi"
    @Published var cardNumber: String = "4532 1234 5678 9010"
    @Published var expiryDate: String = "12/28"
    @Published var cvv: String = "123"
    @Published var bankName: String = "Boubyan"

    // Card template and appearance
    @Published var cardTemplate: CardTemplate = .premium

    // Computed properties from template
    var cardColor: Color {
        cardTemplate.pattern.toUIColor().toColor()
    }

    var textColor: Color {
        cardTemplate.textColor
    }

    var cardNetwork: CardNetwork {
        cardTemplate.cardNetwork
    }
}

extension UIColor {
    func toColor() -> Color {
        return Color(self)
    }
}

