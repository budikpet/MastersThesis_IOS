//
//  ZooAPIService.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 29/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import ReactiveSwift

protocol HasZooAPI {
    var zooAPI: ZooAPIServicing { get }
}

protocol ZooAPIServicing {
    func fetchPhoto(_ id: Int) -> SignalProducer<String, RequestError>
}

final class ZooAPIService: ZooAPIServicing {
    typealias Dependencies = HasJSONAPI

    private let jsonAPI: JSONAPIServicing

    // MARK: Initializers

    init(dependencies: Dependencies) {
        self.jsonAPI = dependencies.jsonAPI
    }

    func fetchPhoto(_ id: Int) -> SignalProducer<String, RequestError> {
        jsonAPI.request(path: "photos/\(id)").compactMap { response in
            (response.data as? [String: Any])?["url"] as? String
        }
    }

    func getAnimals() -> SignalProducer<(Metadata, [AnimalData]), RequestError> {
        let path = "/api/animals"
        fatalError("init(coder:) has not been implemented")
    }

    func getClasses() -> SignalProducer<(Metadata, [AnimalsFilter]), RequestError> {
        let path = "/api/classes"
        fatalError("init(coder:) has not been implemented")
    }
}
