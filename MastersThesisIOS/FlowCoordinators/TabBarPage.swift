//
//  TabBarPage.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit

/**
 A helper Enum for the main UITabBar modeling.
 
 Each of its cases is a UITabBar item.
 */
enum TabBarPage: CaseIterable {
    /// Animal lexicon tab
    case lexicon

    /// Map of the Zoo Prague tab
    case zooMap

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

    /**
     - Returns:
        A localized name of the tab item.
     */
    func localizedName() -> String {
        switch self {
        case .lexicon:
            return L10n.Tab.lexicon
        case .zooMap:
            return L10n.Tab.zooMap
        }
    }

    /**
     Decides order of tab items in UITabBar.
     */
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
                return "zooPragueLexiconIcon"
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
