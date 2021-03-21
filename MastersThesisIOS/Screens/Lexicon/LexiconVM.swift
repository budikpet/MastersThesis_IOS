//
//  LexiconVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import ReactiveSwift

protocol LexiconViewModelingActions {
    var fetchPhoto: Action<Void, UIImage?, RequestError> { get }
}

protocol LexiconViewModeling {
	var actions: LexiconViewModelingActions { get }

    var photo: Property<UIImage?> { get }
}

extension LexiconViewModeling where Self: LexiconViewModelingActions {
    var actions: LexiconViewModelingActions { self }
}

final class LexiconVM: BaseViewModel, LexiconViewModeling, LexiconViewModelingActions {
    typealias Dependencies = HasExampleAPI

    let fetchPhoto: Action<Void, UIImage?, RequestError>

    var photo: Property<UIImage?>

    // MARK: Initializers

    init(dependencies: Dependencies) {
        fetchPhoto = Action { dependencies.exampleAPI.fetchPhoto(1)  // wired photo ID just for example
            .compactMap { URL(string: $0) }
            .observe(on: QueueScheduler())
            .compactMap { try? Data(contentsOf: $0) }
            .observe(on: QueueScheduler.main)
            .map { UIImage(data: $0) }
        }

        photo = Property(initial: nil, then: fetchPhoto.values)

        super.init()
        setupBindings()
    }

    // MARK: Helpers

    private func setupBindings() {

    }
}
