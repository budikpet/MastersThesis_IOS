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
    var searchText: MutableProperty<String> { get }

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
    internal var searchText: MutableProperty<String>

    // MARK: Internal
    internal var animalData: Results<AnimalData>
    internal var animalFilters: Results<AnimalFilter>
    internal var transformationAnimalData: MutableProperty<[TransformedData]>

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

        transformationAnimalData = MutableProperty([])
        filteredAnimalData = MutableProperty([])
        searchText = MutableProperty("")

        super.init()
        setupBindings()
    }

    deinit {
        animalFiltersToken.invalidate()
        animalDataToken.invalidate()
    }

    private func setupBindings() {
        // Pass data from transformationAnimalData to filteredAnimalData. Use only data that is marked as visible.
        filteredAnimalData <~ transformationAnimalData.signal.map() { list in
            list.compactMap() { $0.pickedBySearch && $0.pickedByFilters ? $0.animalData : nil }
        }

        transformationAnimalData <~ searchText.signal
            .debounce(0.5, on: QueueScheduler.main)
            .map() { [weak self] partialName -> [TransformedData] in
                guard let self = self else { return [] }
                return self.getFilteredAnimals(from: self.transformationAnimalData.value, withSearchString: partialName)
            }

        animalFiltersToken = animalFilters.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
//                self.transformationAnimalData.value = self.getFilteredAnimals(from: self.animalData, using: self.animalFilters)
                break
            case .update(let newAnimalFilters, _, _, _):
                self.transformationAnimalData.value = self.getFilteredAnimals(from: self.animalData, using: newAnimalFilters)
                break
            case .error:
                fatalError("Error occured during observation.")
            }
        }

        animalDataToken = animalData.observe { [weak self] (changes: RealmCollectionChange) in
            guard let self = self else { return }
            switch changes {
            case .initial:
                self.transformationAnimalData.value = self.getFilteredAnimals(from: self.animalData, using: self.animalFilters)
                break
            case .update(let newAnimalData, _, _, _):
                // Filter new AnimalData using search text and filters
                let res =  self.getFilteredAnimals(from: newAnimalData, using: self.animalFilters)
                self.transformationAnimalData.value = self.getFilteredAnimals(from: res, withSearchString: self.searchText.value)
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
    private func getFilteredAnimals(from animalData: Results<AnimalData>, using animalFilters: Results<AnimalFilter>) -> [TransformedData] {
        // First member of tuple is the type of filter (the filtered property of AnimalData), second member are all picked values
        let pickedFiltersList: [PickedFilters] = getPickedFilters(allFilters: Array(animalFilters))

        return Array(self.animalData)
            .map { (animalData: AnimalData) -> TransformedData in
                let res = pickedFiltersList.reduce(true) { (fullRes: Bool, filter) -> Bool in
                    if(filter.pickedFilters.isEmpty) {
                        return fullRes
                    }

                    guard var propertyValue = animalData.value(forKey: filter.type) as? String else { return false }
                    propertyValue = propertyValue.lowercased()

                    return fullRes && filter.pickedFilters.reduce(false) { (currRes, filterValue) -> Bool in
                        currRes || propertyValue.contains(filterValue)
                    }
                }

                return TransformedData(pickedByFilters: res, pickedBySearch: true, animalData: animalData)
            }
    }

    private func getPickedFilters(allFilters: [AnimalFilter]) -> [PickedFilters] {
        allFilters
            .map { (filter: AnimalFilter) -> PickedFilters in
                let pickedValues = Array(zip(filter.values, filter.checkmarkValues))
                    .compactMap { (value, checkmarkValue) -> String? in
                        return checkmarkValue ? value.lowercased() : nil
                    }

                return PickedFilters(type: filter.type, pickedFilters: pickedValues)
            }
    }

    private func getFilteredAnimals(from data: [TransformedData], withSearchString partialName: String) -> [TransformedData] {
        return data.map { currData -> TransformedData in
                let res = partialName == "" ? true : currData.animalData.name.lowercased().contains(partialName.lowercased())
                return TransformedData(pickedByFilters: currData.pickedByFilters, pickedBySearch: res, animalData: currData.animalData)
            }
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

public struct TransformedData {
    fileprivate var pickedByFilters: Bool
    fileprivate var pickedBySearch: Bool
    fileprivate var animalData: AnimalData
}
