//
//  TabBarPage.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import Foundation

enum TabBarPage: String, CaseIterable {
    case lexicon = "Lexikon"
    case zooMap = "Mapa"

    init?(index: Int) {
        switch index {
        case 0:
            self = .lexicon
        case 1:
            self = .zooMap
        default:
            return nil
        }
    }

    func pageOrderNumber() -> Int {
        switch self {
        case .lexicon:
            return 0
        case .zooMap:
            return 1
        }
    }

    // Add tab icon value

    // Add tab icon selected / deselected color

    // etc
}
