//
//  ImageFetcher.swift
//  MastersThesisIOS
//
//  Created by Petr Budík on 22/03/2021.
//  Copyright © 2021 Petr Budík. All rights reserved.
//

import Foundation

protocol FetchableImage {
    func fetchBatchImages(using urlStrings: [String?], options: FetchableImageOptions?,
             partialFetchHandler: @escaping (_ imageData: Data?, _ index: Int) -> Void,
             completion: @escaping () -> Void)
}

extension FetchableImage {
    func fetchBatchImages(using urlStrings: [String?],
                          options: FetchableImageOptions? = nil,
                          partialFetchHandler: @escaping (_ imageData: Data?, _ index: Int) -> Void,
                          completion: @escaping () -> Void) {

        let partialHandlerClosure = { (imageData, index) in
            partialFetchHandler(imageData, index)
        }

        performBatchImageFetching(using: urlStrings, currentImageIndex: 0, options: options, partialFetchHandler: partialHandlerClosure) {
            completion()
        }

    }

    private func performBatchImageFetching(using urlStrings: [String?], currentImageIndex: Int,
        options: FetchableImageOptions?,
        partialFetchHandler: @escaping (_ imageData: Data?, _ index: Int) -> Void,
        completion: @escaping () -> Void) {

        if(currentImageIndex >= urlStrings.count) {
            // Recursion completed
            completion()
            return
        }

        fetchImage(from: urlStrings[currentImageIndex], options: options) { (imageData) in
            // Pass current image data to the caller
            partialFetchHandler(imageData, currentImageIndex)

            // Continue recursion
            self.performBatchImageFetching(using: urlStrings,
                currentImageIndex: currentImageIndex + 1,
                options: options, partialFetchHandler: partialFetchHandler) {
                completion()
            }
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

    /**
     Fetches an image from local cache. If it does not exist it fetches it from remote URL and stores it in the cache.
     - Parameters:
        - urlString: A remote URL from which the image is to be fetched. If null then it is expected to be looking for the image in local storage.
     */
    func fetchImage(from urlString: String?, options: FetchableImageOptions? = nil, completion: @escaping (_ imageData: Data?) -> Void) {
        DispatchQueue.global(qos: .background).async {

            let opt = FetchableImageHelper.getOptions(options)
            let localURL = self.localFileURL(for: urlString, options: options)

            // Determine if image exists locally first.
            if opt.allowLocalStorage, let localURL = localURL, FileManager.default.fileExists(atPath: localURL.path) {
                // Image exists locally!
                // Load it using the composed localURL.
                let loadedImageData = FetchableImageHelper.loadLocalImage(from: localURL)
                completion(loadedImageData)

            } else {
                // Image does not exist locally!
                // Download it.

                guard let urlString = urlString, let url = URL(string: urlString) else {
                    completion(nil)
                    return
                }

                FetchableImageHelper.downloadImage(from: url) { (imageData) in
                    if opt.allowLocalStorage, let localURL = localURL {
                        try? imageData?.write(to: localURL)
                    }

                    completion(imageData)
                }

            }
        }
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
    static func loadLocalImage(from url: URL) -> Data? {
        do {
            let imageData = try Data(contentsOf: url)
            return imageData
        } catch {
            print(error.localizedDescription)
            return nil
        }
    }
}
