//
//  ZooAPIService.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 29/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import ReactiveSwift
import os.log

protocol HasZooAPI {
    var zooAPI: ZooAPIServicing { get }
}

protocol ZooAPIServicing {
    func getAnimals() -> SignalProducer<(DetachedMetadata, [DetachedAnimalData]), RequestError>
    func getClasses() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError>
    func getBiotops() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError>
    func getFoods() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError>
    func getZooHouses() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError>
    func getMapMetadata() -> SignalProducer<MapMetadata, RequestError>
}

/**
 Each function calls endpoints of the pythons server which provides Zoo Prague data.
 */
final class ZooAPIService: ZooAPIServicing {
    typealias Dependencies = HasJSONAPI & HasNetwork

    private let jsonAPI: JSONAPIServicing

    // MARK: Initializers

    init(dependencies: Dependencies) {
        self.jsonAPI = dependencies.jsonAPI
    }

    func getAnimals() -> SignalProducer<(DetachedMetadata, [DetachedAnimalData]), RequestError> {
        os_log("Fetching all animals.", log: Logger.networkingLog(), type: .info)
        return jsonAPI.request(path: "/api/animals").compactMap { response in
            guard let responseData = (response.data as? [String: Any]) else { return nil }
            guard let metadataDict = responseData["metadata"] as? [String: Any] else { return nil }
            guard let animalDict = responseData["data"] as? Array<[String: Any]> else { return nil }

            let metadata: DetachedMetadata = DetachedMetadata(using: metadataDict)
            let animalData = animalDict.map() { DetachedAnimalData(using: $0) }
            return (metadata, animalData)
        }
    }

    func getClasses() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError> {
        os_log("Fetching all classes.", log: Logger.networkingLog(), type: .info)
        return jsonAPI.request(path: "/api/classes").compactMap { response in
            guard let responseData = (response.data as? [String: Any]) else { return nil }
            guard let metadataDict = responseData["metadata"] as? [String: Any] else { return nil }
            guard let values = responseData["data"] as? [String] else { return nil }

            let metadata: DetachedMetadata = DetachedMetadata(using: metadataDict)
            let animalsFilter: DetachedAnimalFilter = DetachedAnimalFilter(ofType: "class_", values)
            return (metadata, animalsFilter)
        }
    }

    func getBiotops() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError> {
        os_log("Fetching all biotops.", log: Logger.networkingLog(), type: .info)
        return jsonAPI.request(path: "/api/biotops").compactMap { response in
            guard let responseData = (response.data as? [String: Any]) else { return nil }
            guard let metadataDict = responseData["metadata"] as? [String: Any] else { return nil }
            guard let values = responseData["data"] as? [String] else { return nil }

            let metadata: DetachedMetadata = DetachedMetadata(using: metadataDict)
            let animalsFilter: DetachedAnimalFilter = DetachedAnimalFilter(ofType: "biotop", values)
            return (metadata, animalsFilter)
        }
    }

    func getFoods() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError> {
        os_log("Fetching all foods.", log: Logger.networkingLog(), type: .info)
        return jsonAPI.request(path: "/api/foods").compactMap { response in
            guard let responseData = (response.data as? [String: Any]) else { return nil }
            guard let metadataDict = responseData["metadata"] as? [String: Any] else { return nil }
            guard let values = responseData["data"] as? [String] else { return nil }

            let metadata: DetachedMetadata = DetachedMetadata(using: metadataDict)
            let animalsFilter: DetachedAnimalFilter = DetachedAnimalFilter(ofType: "food", values)
            return (metadata, animalsFilter)
        }
    }

    func getZooHouses() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError> {
        os_log("Fetching all zoo houses.", log: Logger.networkingLog(), type: .info)
        return jsonAPI.request(path: "/api/zooHouses").compactMap { response in
            guard let responseData = (response.data as? [String: Any]) else { return nil }
            guard let metadataDict = responseData["metadata"] as? [String: Any] else { return nil }
            guard let values = responseData["data"] as? [String] else { return nil }

            let metadata: DetachedMetadata = DetachedMetadata(using: metadataDict)
            let animalsFilter: DetachedAnimalFilter = DetachedAnimalFilter(ofType: "location_in_zoo", values)
            return (metadata, animalsFilter)
        }
    }

    func getMapMetadata() -> SignalProducer<MapMetadata, RequestError> {
        os_log("Fetching map metadata.", log: Logger.networkingLog(), type: .info)
        return jsonAPI.request(path: "/api/map/metadata").compactMap { response in
            guard let responseData = (response.data as? [String: Any]) else { return nil }

            let mapMetadata: MapMetadata = MapMetadata(using: responseData)
            return mapMetadata
        }
    }

//    func getMapData() -> SignalProducer<(DetachedMetadata, DetachedAnimalFilter), RequestError> {
//        os_log("Fetching all foods.", log: Logger.networkingLog(), type: .info)
//        return jsonAPI.request(path: "/api/map/data").compactMap { response in
//            guard let responseData = (response.data as? [String: Any]) else { return nil }
//            guard let metadataDict = responseData["metadata"] as? [String: Any] else { return nil }
//            guard let values = responseData["data"] as? [String] else { return nil }
//
//            let metadata: DetachedMetadata = DetachedMetadata(using: metadataDict)
//            let animalsFilter: DetachedAnimalFilter = DetachedAnimalFilter(ofType: "food", values)
//            return (metadata, animalsFilter)
//        }
//    }
}
