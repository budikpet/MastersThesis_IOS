//
//  ImageFetcherService.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 23/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation
import ReactiveSwift

class ImageFetcherService {
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
    func fetchImage(from urlString: String?, options: FetchableImageOptions? = nil) -> SignalProducer<Data, RequestError> {

        return SignalProducer<(URL, Bool), RequestError> { observer, lifetime in
            let opt = FetchableImageHelper.getOptions(options)
            let localURL = self.localFileURL(for: urlString, options: options)

            if opt.allowLocalStorage, let localURL = localURL, FileManager.default.fileExists(atPath: localURL.path) {
                print("Sending local: \(localURL)")
                observer.send(value: (localURL, true))
            } else {
                guard let urlString = urlString, let url = URL(string: urlString) else {
//                    observer.send(nil)
                    observer.sendCompleted()
                    return
                }
                print("Sending global: \(url)")
                observer.send(value: (url, false))
            }

            observer.sendCompleted()
        }
        .observe(on: QueueScheduler())
        .compactMap { url, islocal in
            // Get data from global/local url
            let localURL = self.localFileURL(for: urlString, options: options)
            let opt = FetchableImageHelper.getOptions(options)
            let data = try? Data(contentsOf: url)

            if let localURL = localURL, !islocal, opt.allowLocalStorage {
                // Write to local cache if the global url was used
                print("Writing to cache")
                try? data?.write(to: localURL)
            }

            return data
        }
    }

    /**
     - Parameters:
        - imageURL: Remote URL of the image should be fetched from.
     - Returns:
        URL to the local file if it exists.
     */
    func localFileURL(for imageURL: String?, options: FetchableImageOptions? = nil) -> URL? {
        let opt = FetchableImageHelper.getOptions(options)
        let targetDir = opt.storeInCachesDirectory ?
            FetchableImageHelper.cachesDirectoryURL :
            FetchableImageHelper.documentsDirectoryURL

        guard let urlString = imageURL else {
            guard let customFileName = opt.customFileName else { return nil }
            return targetDir.appendingPathComponent(customFileName)
        }

        guard let imageName = FetchableImageHelper.getImageName(from: urlString) else { return nil }
        return targetDir.appendingPathComponent(imageName)
    }
}

/**
 Contains options that change the way the algorithm functions.
 */
struct FetchableImageOptions {
    /**
     If true then images are cached to the caches directory.
     Else images are cached to the documents directory.
     */
    var storeInCachesDirectory: Bool = true
    var allowLocalStorage: Bool = true
    var customFileName: String?
}

fileprivate struct FetchableImageHelper {
    static var documentsDirectoryURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
    static var cachesDirectoryURL = FileManager.default.urls(for: .cachesDirectory, in: .userDomainMask)[0]

    static func getOptions(_ options: FetchableImageOptions?) -> FetchableImageOptions {
        // swiftlint:disable force_cast
        return options != nil ? options! : FetchableImageOptions()
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
}
