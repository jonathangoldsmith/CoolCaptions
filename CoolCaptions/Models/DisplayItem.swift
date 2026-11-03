//
//  DisplayItem.swift
//  CoolCaptions
//
//  Created by Jonathan Goldsmith on 11/3/26.
//

import Foundation

enum DisplayItem: Identifiable {
  case caption(Caption)
  case gap(Gap)

  var id: UUID {
    switch self {
      case .caption(let caption): caption.id
      case .gap(let gap): gap.id
    }
  }
}
