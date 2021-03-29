//
//  LexiconVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import ReactiveSwift
import os.log

protocol LexiconViewModelingActions {
}

protocol LexiconViewModeling {
	var actions: LexiconViewModelingActions { get }

    var data: Property<[AnimalData]> { get }

    func animal(at index: Int) -> AnimalData
    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM
    func rowHeightAt(_ index: Int) -> CGFloat
}

extension LexiconViewModeling where Self: LexiconViewModelingActions {
    var actions: LexiconViewModelingActions { self }
}

final class LexiconVM: BaseViewModel, LexiconViewModeling, LexiconViewModelingActions {
    typealias Dependencies = HasNetwork

    var data: Property<[AnimalData]>

    let animals: [AnimalData] = {
        let data1 = AnimalData(withId: 1)
        data1.name = "Adax"
        data1.latin_name = "Addax nasomaculatus"
        data1.location_in_zoo = "Pavilon XYZ"
        data1.image_url = "https://www.zoopraha.cz/images/lexikon/Adax_foto_Vaclav_Silha_3I4A6578_export.jpg"
        data1.base_summary = "Svetlé zbarvení srsti adaxe napovídá, že žije v poušti, vyprahlé krajine plné kamení a písku, daleko od vody."
        data1.class_ = "Savci"
        data1.class_latin = "Mammalia"
        data1.order = "Sudokopytníci"
        data1.order_latin = "Artiodactyla"
        data1.continent = "Afrika"
        data1.continent_detail = "Původně celá Sahara, dnes malé území v Nigeru"
        data1.biotop = "poušť a polopoušť"
        data1.biotop_detail = "kamenité i písčité pouště"
        data1.food = "části rostlin"
        data1.sizes = "Délka těla 1,2–1,8 m, délka ocasu 25–35 cm, výška v kohoutku 1–1,1 m, hmotnost 60–125 kg"
        data1.reproduction = "Březost 257–264 dny, počet mláďat 1"
        data1.interesting_data = "K nehostinnému prostředí je skvěle přizpůsoben. Nepotřebuje totiž pít každý den, protože dokáže hospodařit s vodou obsaženou v potravě. Navíc jsou adaxové aktivní za soumraku a v noci, kdy putují krajinou za potravou od jednoho ostrůvku rostlin k druhému; den tráví obvykle odpočinkem, ukrytí ve stín"
        data1.about_placement_in_zoo_prague = "Pražská zoo chová adaxy od roku 1979."
        data1.location_in_zoo = "Pláně"
        data1.map_locations.append(objectsIn: [Int64.init(4636937676)])

        let data2 = AnimalData(withId: 2)
        data2.name = "Name 2"
//        data2.location_in_zoo = "Horní část Zoo"
        data2.map_locations.append(21)
        data2.image_url = "https://www.zoopraha.cz/images/lexikon/bazant_palawansky_DSC_1416.jpg"

        let data3 = AnimalData(withId: 3)
        data3.name = "Name 3"
//        data3.map_locations.append(44)
        data3.image_url = "https://www.zoopraha.cz/images/lexikon-images/_22J6092.jpg"

        return [data1, data2, data3]
    }()

    // MARK: Initializers

    init(dependencies: Dependencies) {
        data = Property(initial: [], then: SignalProducer(value: animals))

        super.init()
        setupBindings()
    }

    private func setupBindings() {

    }
}

// MARK: VC Delegate/DataSource helpers

extension LexiconVM {
    func animal(at index: Int) -> AnimalData {
        let item = data.value[index]

        return item
    }

    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM {
        return LexiconItemCellVM(withAnimal: animal(at: index))
    }

    func rowHeightAt(_ index: Int) -> CGFloat {
        return 80.0
    }
}
