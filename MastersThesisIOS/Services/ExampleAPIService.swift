//
//  ExampleAPIService.swift
//  ProjectTemplate
//
//  Created by Jan Misar on 28.08.18.
//

import ReactiveSwift

protocol HasExampleAPI {
    var exampleAPI: ExampleAPIServicing { get }
}

protocol ExampleAPIServicing {
    func fetchPhoto(_ id: Int) -> SignalProducer<String, RequestError>
}

final class ExampleAPIService: ExampleAPIServicing {
    typealias Dependencies = HasJSONAPI

    private let jsonAPI: JSONAPIServicing

    // MARK: Initializers

    init(dependencies: Dependencies) {
        self.jsonAPI = dependencies.jsonAPI
    }

    func fetchPhoto(_ id: Int) -> SignalProducer<String, RequestError> {
        // swiftlint:disable force_unwrapping
        let address = RequestAddress(path: "photos/\(id)", baseURL: URL(string: "https://jsonplaceholder.typicode.com")!)

        return jsonAPI.request(address).compactMap { response in
            (response.data as? [String: Any])?["url"] as? String
        }
    }
}
