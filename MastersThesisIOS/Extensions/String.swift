//
//  String.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//  Copyright © 2021 Ackee, s.r.o. All rights reserved.
//

import Foundation

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
