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
    /**
     - Returns:
        A string with only its first letter capitalized.
     */
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }

    /**
     - Returns:
        A constructed URL from this url string which could possibly contain disallowed characters.
     */
    func getCleanedURL() -> URL? {
        guard self.isEmpty == false else {
            return nil
        }
        if let url = URL(string: self) {
            return url
        } else {
            // Some URL strings may contains characters which aren't usually allowed in swift. This encodes them so that the URL can be used.
            if let urlEscapedString = self.addingPercentEncoding(withAllowedCharacters: CharacterSet.urlQueryAllowed), let escapedURL = URL(string: urlEscapedString){
                return escapedURL
            }
        }
        return nil
     }
}
