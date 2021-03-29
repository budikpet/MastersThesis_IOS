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
        self.location = animal.createShownLocation()
        self.imageUrl = URL(string: animal.image_url)
    }
}
