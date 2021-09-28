import Foundation
import Combine
import UIKit
import os.log

struct ImageData: Decodable {
    let id: String
    let author: String
    let width: Int
    let height: Int
    let url: String
    let download_url: String
}

final class ImageService: ObservableObject {
    private var imageFetchCancellable: AnyCancellable? = nil
    let urlSession: URLSession
    @Published var imageData: [ImageData] = []

    var imageCache: [String: UIImage] = [:]
    var pageCount = 1

    enum ImageServiceError: Error {
        case jsonDecode(DecodingError)
        case general
    }

    init(urlSession: URLSession = URLSession.shared) {
        self.urlSession = urlSession
    }

    /// Fetches an array of items from the given URL
    func fetchItems<T: Decodable>(_ : T.Type, url: URL) -> AnyPublisher<[T], ImageServiceError> {
        urlSession.dataTaskPublisher(for: url).tryMap { (data, _) in
            try JSONDecoder().decode([T].self, from: data)
        }.mapError { err -> ImageServiceError in
            if let e = err as? DecodingError  {
                return ImageServiceError.jsonDecode(e)
            } else {
                return ImageServiceError.general
            }
        }.eraseToAnyPublisher()
    }

    func updateImages() {
        os_log(.debug, "Updating Images from Page \(self.pageCount)")
        guard let url = URL(string: "https://picsum.photos/v2/list?page=\(pageCount)&limit=25") else {
            return
        }

        imageFetchCancellable = fetchItems(ImageData.self, url: url)
            .sink(
                receiveCompletion: { completionInfo in
                    switch completionInfo {
                    case .finished:
                        break
                    case .failure(let error):
                        os_log(.error, "Error Fetching %s", String(describing: error))
                    }
                },
                receiveValue: { [weak self] data in
                    os_log("Values Received")
                    self?.imageData = data
                    self?.pageCount += 1
                    self?.updateImageCache()
                }
            )
    }

    func updateImageCache() {
        os_log("Prepping Cache for page \(self.pageCount)")
        guard let url = URL(string: "https://picsum.photos/v2/list?page=\(pageCount)&limit=25") else {
            return
        }
        imageFetchCancellable = fetchItems(ImageData.self, url: url)
            .sink(
                receiveCompletion: { completionInfo in
                    switch completionInfo {
                    case .finished:
                        break
                    case .failure(let error):
                        os_log(.error, "Error Fetching %s", String(describing: error))
                    }
                },
                receiveValue: { [weak self] data in
                    os_log("Values Received")
                    data.forEach { imageInfo in
                        self?.imageCache[imageInfo.id] = self?.getReadyImages(for: imageInfo.download_url)
                    }
                }
            )
    }

    func getImage(for index: Int) -> UIImage? {
        if let cachedImage = imageCache[imageData[index].id] {
            os_log("Image id '\(self.imageData[index].id)' is being fetched from Cache")
            return cachedImage
        } else {
            os_log("Image id '\(self.imageData[index].id)' is being fetched from API")
            guard let url = URL(string: imageData[index].download_url) else {
                os_log("Invalid URL: \(self.imageData[index].download_url)")
                return nil
            }

            guard let data = try? Data(contentsOf: url) else {
                os_log("Error downloading image")
                return nil
            }

            let image = UIImage(data: data)
            if imageCache[imageData[index].id] == nil {
                os_log("Adding image id '\(self.imageData[index].id)' to the cache")
                imageCache[imageData[index].id] = image
            }

            return image
        }
    }

    func getReadyImages(for urlString: String) -> UIImage? {
        guard let url = URL(string: urlString) else {
            os_log("Invalid URL: \(urlString)")
            return nil
        }

        guard let data = try? Data(contentsOf: url) else {
            os_log("Error downloading image")
            return nil
        }

        return UIImage(data: data)
    }
}
