//
//  AnimalFilterItemCellVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 02/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit

struct AnimalFilterItemCellVM {
    let value: String
    let isChecked: Bool

    static let checkmarkImg =  UIImage(named: "checkmark")!

    init(withValue value: String, checked: Bool) {
        self.value = value
        self.isChecked = checked
    }
}
