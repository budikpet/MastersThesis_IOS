//
//  TabBarPage.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit

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

    func pageImage() throws -> UIImage {
        let name: String = {
            switch self {
            case .lexicon:
                return "zooPragueLexicon"
            case .zooMap:
                return "zooMapIcon"
            }
        }()

        guard let img: UIImage = UIImage(named: name) else {
            throw "Image named '\(name)' not found"
        }
        return img
    }

    // Add tab icon selected / deselected color

    // etc
}
