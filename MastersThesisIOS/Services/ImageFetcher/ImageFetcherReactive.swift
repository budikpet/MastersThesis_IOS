//
//  ImageFetcherReactive.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 23/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import ReactiveSwift

class ImageFetcherReactive {
    typealias Dependencies = HasNetwork

    private let network: Networking

    init(dependencies: Dependencies) {
        network = dependencies.network
    }

    /**
     Fetches an image from local cache. If it does not exist it fetches it from remote URL and stores it in the cache.
     - Parameters:
        - urlString: A remote URL from which the image is to be fetched. If null then it is expected to be looking for the image in local storage.
     */
    func fetchImage(from urlString: String?, options: FetchableImageOptionsReactive? = nil) -> SignalProducer<DataResponse, RequestError> {

        return SignalProducer<(URL, Bool), RequestError> { observer, lifetime in
            let opt = FetchableImageHelperReactive.getOptions(options)
            let localURL = self.localFileURL(for: urlString, options: options)

            if opt.allowLocalStorage, let localURL = localURL, FileManager.default.fileExists(atPath: localURL.path) {
                observer.send(value: (localURL, true))
            } else {
                guard let urlString = urlString, let url = URL(string: urlString) else {
//                    observer.send(nil)
                    observer.sendCompleted()
                    return
                }
                observer.send(value: (url, false))
            }

            observer.sendCompleted()
        }
        .flatMap(.concat) { (url, isLocal) -> SignalProducer<DataResponse, RequestError> in
            if(isLocal) {
                // Image exists locally!
                // Load it using the composed localURL.
                return FetchableImageHelperReactive.loadLocalImage(from: url)
            } else {
                // Image does not exist locally!
                // Download it.
                let address = RequestAddress(withUrl: url)

                return self.network.request(address, method: .get, parameters: [:], encoding: URLEncoding.default, headers: [:])
                    .on(event: {event in try? event.value?.data?.write(to: url) })
            }
        }
    }

    /**
     - Parameters:
        - imageURL: Remote URL of the image should be fetched from.
     - Returns:
        URL to the local file if it exists.
     */
    func localFileURL(for imageURL: String?, options: FetchableImageOptionsReactive? = nil) -> URL? {
        let opt = FetchableImageHelperReactive.getOptions(options)
        let targetDir = opt.storeInCachesDirectory ?
            FetchableImageHelperReactive.cachesDirectoryURL :
            FetchableImageHelperReactive.documentsDirectoryURL

        guard let urlString = imageURL else {
            guard let customFileName = opt.customFileName else { return nil }
            return targetDir.appendingPathComponent(customFileName)
        }

        guard let imageName = FetchableImageHelperReactive.getImageName(from: urlString) else { return nil }
        return targetDir.appendingPathComponent(imageName)
    }
}

/**
 Contains options that change the way the algorithm functions.
 */
struct FetchableImageOptionsReactive {
    /**
     If true then images are cached to the caches directory.
     Else images are cached to the documents directory.
     */
    var storeInCachesDirectory: Bool = true
    var allowLocalStorage: Bool = true
    var customFileName: String?
}

fileprivate struct FetchableImageHelperReactive {
    static var documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static var cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

    static func getOptions(_ options: FetchableImageOptionsReactive?) -> FetchableImageOptionsReactive {
        return options != nil ? options! : FetchableImageOptionsReactive()
    }

    /**
     Generates a unique image name using the given remote URL. Filenames can't contain any non-alphanumerical characters.
     - Returns:
        Filename of the cached remote image.
     */
    static func getImageName(from urlString: String) -> String? {
        guard var base64String = urlString.data(using: .utf8)?.base64EncodedString() else { return nil }

        // Remove non-alphanumerical characters from the string
        base64String = base64String.components(separatedBy: CharacterSet.alphanumerics.inverted).joined()

        guard base64String.count < 50 else {
            return String(base64String.dropFirst(base64String.count - 50))
        }

        return base64String
    }

    /**
     Download an image from the URL.
     - Parameters:
        - url: Remote URL from which the image is to be fetched.
     */
    static func downloadImage(from url: URL, completion: @escaping (_ imageData: Data?) -> Void) {
        let sessionConfiguration = URLSessionConfiguration.ephemeral
        let session = URLSession(configuration: sessionConfiguration)
        let task = session.dataTask(with: url) { (data, response, error) in
            completion(data)
        }
        task.resume()
    }

    /**
     Get image that is located behind the local URL.
     - Parameters:
        - url: The local URL which points to the image stored either in cache or documents directory.
     */
    static func loadLocalImage(from url: URL) -> SignalProducer<DataResponse, RequestError> {
        return SignalProducer { observer, lifetime in
            do {
                let imageData = try Data(contentsOf: url)
                let dataResponse = DataResponse(statusCode: 200, request: nil, response: nil, data: imageData)
                observer.send(value: dataResponse)
                observer.sendCompleted()
            } catch {
                print(error.localizedDescription)
            }
        }
    }
}
