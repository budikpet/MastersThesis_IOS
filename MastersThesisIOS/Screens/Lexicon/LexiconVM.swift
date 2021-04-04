//
//  LexiconVM.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 21/03/2021.
//

import UIKit
import ReactiveSwift
import RealmSwift
import os.log

protocol LexiconViewModelingActions {
    var updateLocalDB: Action<Bool, UpdateStatus, UpdateError> { get }
}

protocol LexiconViewModeling {
	var actions: LexiconViewModelingActions { get }

    var filteredAnimalData: MutableProperty<[AnimalData]> { get }

    func animal(at index: Int) -> AnimalData
    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM
    func rowHeightAt(_ index: Int) -> CGFloat
}

extension LexiconViewModeling where Self: LexiconViewModelingActions {
    var actions: LexiconViewModelingActions { self }
}

final class LexiconVM: BaseViewModel, LexiconViewModeling, LexiconViewModelingActions {
    typealias Dependencies = HasNetwork & HasRealmDBManager
    let realmDbManager: RealmDBManaging

    // MARK: Protocol
    internal var updateLocalDB: Action<Bool, UpdateStatus, UpdateError>

    internal var filteredAnimalData: MutableProperty<[AnimalData]>

    // MARK: Internal
    internal var animalData: Results<AnimalData>
    internal var animalFilters: Results<AnimalFilter>

    private var animalFiltersToken: NotificationToken!
    private var animalDataToken: NotificationToken!

//    let animals: [AnimalData] = {
//        let data1 = AnimalData(withId: 1)
//        data1.name = "Adax"
//        data1.name_latin = "Addax nasomaculatus"
//        data1.location_in_zoo = "Pavilon XYZ"
//        data1.image_url = "https://www.zoopraha.cz/images/lexikon/Adax_foto_Vaclav_Silha_3I4A6578_export.jpg"
//        data1.base_summary = "Svetlé zbarvení srsti adaxe napovídá, že žije v poušti, vyprahlé krajine plné kamení a písku, daleko od vody."
//        data1.class_ = "Savci"
//        data1.class_latin = "Mammalia"
//        data1.order = "Sudokopytníci"
//        data1.order_latin = "Artiodactyla"
//        data1.continent = "Afrika"
//        data1.continent_detail = "Původně celá Sahara, dnes malé území v Nigeru"
//        data1.biotop = "poušť a polopoušť"
//        data1.biotop_detail = "kamenité i písčité pouště"
//        data1.food = "části rostlin"
//        data1.sizes = "Délka těla 1,2–1,8 m, délka ocasu 25–35 cm, výška v kohoutku 1–1,1 m, hmotnost 60–125 kg"
//        data1.reproduction = "Březost 257–264 dny, počet mláďat 1"
//        data1.interesting_data = """
//            K nehostinnému prostředí je skvěle přizpůsoben. Nepotřebuje totiž pít každý den, protože dokáže hospodařit s vodou obsaženou v potravě. Navíc jsou adaxové aktivní za soumraku a v noci, kdy putují krajinou za potravou od jednoho ostrůvku rostlin k druhému; den tráví obvykle odpočinkem, ukrytí ve stínu izolovaných ostrůvků stromů. Široká kopyta zabraňují adaxům, aby se při chůzi probořili do sypkého podkladu. Adaxové se sdružují do málo početných, pevně semknutých skupin, ve kterých samce od samic jen těžko poznáte – spirálovité rohy mají totiž obě pohlaví. Mláďata se rodí hnědavá a teprve ve věku několika měsíců se začínají zbarvovat jako dospělí.
//            """
//        data1.about_placement_in_zoo_prague = "Pražská zoo chová adaxy od roku 1979."
//        data1.location_in_zoo = "Pláně"
//        data1.map_locations.append(objectsIn: [Int64.init(4636937676)])
//
//        let data2 = AnimalData(withId: 2)
//        data2.name = "Name 2"
////        data2.location_in_zoo = "Horní část Zoo"
//        data2.map_locations.append(21)
//        data2.image_url = "https://www.zoopraha.cz/images/lexikon/bazant_palawansky_DSC_1416.jpg"
//
//        let data3 = AnimalData(withId: 3)
//        data3.name = "Name 3"
////        data3.map_locations.append(44)
//        data3.image_url = "https://www.zoopraha.cz/images/lexikon-images/_22J6092.jpg"
//
//        return [data1, data2, data3]
//    }()

    // MARK: Initializers

    init(dependencies: Dependencies) {
        realmDbManager = dependencies.realmDBManager
        updateLocalDB = realmDbManager.actions.updateLocalDB

        animalData = realmDbManager.realm.objects(AnimalData.self)
            .sorted(byKeyPath: "name", ascending: true)
        animalFilters = realmDbManager.realm.objects(AnimalFilter.self)

        filteredAnimalData = MutableProperty([])

        super.init()
        setupBindings()
    }

    deinit {
        animalFiltersToken.invalidate()
        animalDataToken.invalidate()
    }

    private func setupBindings() {
        animalFiltersToken = animalFilters.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.filteredAnimalData.value = self.getFilteredAnimals(from: self.animalData, using: self.animalFilters)
                break
            case .update(let newAnimalFilters, _, _, _):
                self.filteredAnimalData.value = self.getFilteredAnimals(from: self.animalData, using: newAnimalFilters)
                break
            case .error:
                fatalError("Error occured during observation.")
            }
        }

        animalDataToken = animalData.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.filteredAnimalData.value = self.getFilteredAnimals(from: self.animalData, using: self.animalFilters)
                break
            case .update(let newAnimalData, _, _, _):
                self.filteredAnimalData.value = self.getFilteredAnimals(from: newAnimalData, using: self.animalFilters)
                break
            case .error:
                fatalError("Error occured during observation.")
            }
        }
    }
}

// MARK: Helpers

extension LexiconVM {

    /**
     - Parameters:
        - animalFilters: Filters that are used on all AnimalData objects received from the database.
     - Returns:
        New list of AnimalData objects that should be shown. The list is filtered by the given filters.
     */
    private func getFilteredAnimals(from animalData: Results<AnimalData>, using animalFilters: Results<AnimalFilter>) -> [AnimalData] {
        // First member of tuple is the type of filter (the filtered property of AnimalData), second member are all picked values
        let pickedFiltersList: [PickedFilters] = Array(animalFilters)
            .map { (filter: AnimalFilter) -> PickedFilters in
                let pickedValues = Array(zip(filter.values, filter.checkmarkValues))
                    .compactMap { (value, checkmarkValue) -> String? in
                        return checkmarkValue ? value.lowercased() : nil
                    }

                return PickedFilters(type: filter.type, pickedFilters: pickedValues)
            }

        let res =  Array(self.animalData)
            .filter { (animalData: AnimalData) -> Bool in
                pickedFiltersList.reduce(true) { (fullRes: Bool, filter) -> Bool in
                    if(filter.pickedFilters.isEmpty) {
                        return fullRes
                    }

                    guard var propertyValue = animalData.value(forKey: filter.type) as? String else { return false }
                    propertyValue = propertyValue.lowercased()

                    return fullRes && filter.pickedFilters.reduce(false) { (currRes, filterValue) -> Bool in
                        currRes || propertyValue.contains(filterValue)
                    }
                }
            }

        return res
    }
}

// MARK: VC Delegate/DataSource helpers

extension LexiconVM {
    func animal(at index: Int) -> AnimalData {
        let item = filteredAnimalData.value[index]

        return item
    }

    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM {
        return LexiconItemCellVM(withAnimal: animal(at: index))
    }

    func rowHeightAt(_ index: Int) -> CGFloat {
        return 100.0
    }
}

private struct PickedFilters {
    public let type: String

    /// Contains only filter values that were picked by a user
    public let pickedFilters: [String]
}
