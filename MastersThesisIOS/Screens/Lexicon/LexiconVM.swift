//
//  LexiconVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import ReactiveSwift

protocol LexiconViewModelingActions {
    var animals: Array<AnimalData> { get }
}

protocol LexiconViewModeling {
	var actions: LexiconViewModelingActions { get }

    func getLabelLocation(using animal: AnimalData) -> String
}

extension LexiconViewModeling where Self: LexiconViewModelingActions {
    var actions: LexiconViewModelingActions { self }
}

final class LexiconVM: BaseViewModel, LexiconViewModeling, LexiconViewModelingActions {
    typealias Dependencies = HasNoDependency

    let animals: Array<AnimalData> = {
        let data1 = AnimalData(withId: 1)
        data1.name = "Name 1"
        data1.location_in_zoo = "Pavilon XYZ"
        data1.image_url = "www.zoopraha.cz/images/lexikon/Adax_foto_Vaclav_Silha_3I4A6578_export.jpg"

        let data2 = AnimalData(withId: 2)
        data2.name = "Name 2"
        data2.location_in_zoo = "Horní část Zoo"
        data2.map_locations.append(21)
        data2.image_url = "www.zoopraha.cz/images/lexikon/bazant_palawansky_DSC_1416.jpg"

        let data3 = AnimalData(withId: 3)
        data3.name = "Name 3"
        data3.map_locations.append(44)
        data3.image_url = "www.zoopraha.cz/images/lexikon-images/_22J6092.jpg"

        let data4 = AnimalData(withId: 4)
        data4.name = "Name 4"
        return [data1, data2, data3, data4]
    }()

    // MARK: Initializers

    init(dependencies: Dependencies) {

        super.init()
        setupBindings()
    }

    // MARK: Helpers

    public func getLabelLocation(using animal: AnimalData) -> String {
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

    private func setupBindings() {

    }
}
