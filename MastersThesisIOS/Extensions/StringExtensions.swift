//
//  String.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension String {
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}
