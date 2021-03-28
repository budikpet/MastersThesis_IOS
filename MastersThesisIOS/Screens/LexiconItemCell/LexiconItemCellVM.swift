//
//  LexiconItemCellVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 28/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit

struct LexiconItemCellVM {
    let name: String
    let location: String
    let imageUrl: URL?

    static let placeholder_image =  UIImage(systemName: "photo")!

    init(withAnimal animal: AnimalData) {
        self.name = animal.name
        self.location = LexiconItemCellVM.createShownLocation(using: animal)
        self.imageUrl = URL(string: animal.image_url)
    }

    // MARK: Helpers

    private static func createShownLocation(using animal: AnimalData) -> String {
        var res: String = ""
        if(animal.location_in_zoo == "-" && animal.map_locations.count == 0) {
            res = "-"
        } else if(animal.location_in_zoo == "-") {
            res = L10n.Label.externalPen
        } else if(animal.map_locations.count == 0) {
            res = animal.location_in_zoo
        } else {
            res = "\(animal.location_in_zoo) - \(L10n.Label.externalPen)"
        }
        res = res.trimmed().lowercased().capitalizingFirstLetter()

        return res
    }
}
