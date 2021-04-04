//
//  OtherExtensions.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 04/04/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import UIKit
import ReactiveSwift

public extension Reactive where Base: UISearchBar {

    /// Sends true if the search bar was opened. Sends false if the search bar was cancelled.
    var visibility: Signal<Bool, Never> {
        Signal.merge(base.reactive.textDidBeginEditing.map() { _ in true }, base.reactive.textDidEndEditing.map() { _ in false })
    }
}
