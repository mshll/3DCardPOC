//
//  CardNetwork.swift
//  3DCardPOC
//
//  Created by meshal on 11/4/25.
//

import Foundation

enum CardNetwork: String, CaseIterable {
  case visa = "Visa"
  case mastercard = "Mastercard"

  var logoImageName: String {
    switch self {
    case .visa:
      return "visa_default"
    case .mastercard:
      return "mastercard_default"
    }
  }
}
