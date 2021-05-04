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

    func numberOfSelectedFilters() -> Int

    func animal(at index: Int) -> AnimalData
    func getLexiconItemCellVM(at index: Int) -> LexiconItemCellVM
    func rowHeightAt(_ index: Int) -> CGFloat
}

extension LexiconViewModeling where Self: LexiconViewModelingActions {
    var actions: LexiconViewModelingActions { self }
}

final class LexiconVM: BaseViewModel, LexiconViewModeling, LexiconViewModelingActions {
    typealias Dependencies = HasNetwork & HasStorageManager
    let storageManager: StorageManaging

    // MARK: Protocol
    internal var updateLocalDB: Action<Bool, UpdateStatus, UpdateError>

    internal var filteredAnimalData: MutableProperty<[AnimalData]>
    internal var searchText: MutableProperty<String>

    // MARK: Internal
    internal var animalData: Results<AnimalData>
    internal var animalFilters: Results<AnimalFilter>

    /// Holds all AnimalData from Realm DB in `TransformedData` structs. All filtering is directly applied on this collection only.
    internal var transformationAnimalData: MutableProperty<[TransformedData]>

    private var animalFiltersToken: NotificationToken!
    private var animalDataToken: NotificationToken!

    // MARK: Initializers

    init(dependencies: Dependencies) {
        storageManager = dependencies.storageManager
        updateLocalDB = storageManager.actions.updateLocalDB

        animalData = storageManager.realm.objects(AnimalData.self)
            .sorted(byKeyPath: "name", ascending: true)
        animalFilters = storageManager.realm.objects(AnimalFilter.self)

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

// MARK: Protocol

extension LexiconVM {
    func numberOfSelectedFilters() -> Int {
        return self.animalFilters
            .flatMap { (filter: AnimalFilter) -> [Bool] in
                return Array(filter.checkmarkValues)
            }
            .filter { $0 == true }
            .count
    }
}

// MARK: Helpers

extension LexiconVM {

    /**
     Applies selected filters to all AnimalData from Realm DB.
     - Parameters:
        - animalData: All animal data from realm DB
        - animalFilters: Filters that are used on all AnimalData objects received from the database.
     - Returns:
        New list of `TransformedData` objects where each objects was had its property `TransformedData.pickedByFilters` modified.
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

    /**
     Picks only filters that were selected in each category.
     - Parameters:
        - allFilters: A list of all possible filters.
     - Returns:
        A list of PickedFilters.
     */
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

    /**
     Applies search bar string to the provided `TransformedData`.
     - Parameters:
        - data: All transformed data.
        - partialName: String from search bar. It is used for filtering the provided data by name.
     - Returns:
        New list of `TransformedData` objects where each objects was had its property `TransformedData.pickedBySearch` modified.
     */
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

/**
 Helper struct that holds `AnimalData` value and an information if it was picked by filters or search bar.
 
 Only AnimalData that was picked by both filters and search bar should be visible.
 */
public struct TransformedData {
    /// True if if was filtered by filters and selected as visible.
    fileprivate var pickedByFilters: Bool
    /// True if if was filtered by search bar and selected as visible.
    fileprivate var pickedBySearch: Bool
    fileprivate var animalData: AnimalData
}
