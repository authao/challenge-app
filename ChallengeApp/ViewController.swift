import UIKit
import os.log
import Combine


class ViewController: UIViewController {

    @IBOutlet weak var getImagesButton: UIButton!
    @IBOutlet weak var imagesCollectionView: UICollectionView!

    private var cancellable: AnyCancellable?
    var imageService: ImageService?

    let imageCellIdentifier = "ImageCollectionViewCell"
    let vowelsList: [Character] = ["a", "e", "i", "o", "u", "A", "E", "I", "O", "U"]

    lazy var longPressGestureRecognizer: UILongPressGestureRecognizer = {
        let recognizer = UILongPressGestureRecognizer(target: self, action: #selector(longPressGestureAction(_:)))
        recognizer.minimumPressDuration = 1
        return recognizer
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        imageService?.updateImages()

        cancellable = imageService?.objectWillChange.sink { [weak self] data in
            DispatchQueue.main.async {
                self?.imagesCollectionView.reloadData()
            }
        }

        imagesCollectionView.addGestureRecognizer(longPressGestureRecognizer)
        getImagesButton.addTarget(self, action: #selector(getImagesButtonTapped), for: .touchUpInside)
    }

    override func didReceiveMemoryWarning() {
        imageService?.imageCache = [:]
    }

    @objc func getImagesButtonTapped() {
        // upon tapping the button the application fetches from https://picsum.photos 100 images
        imageService?.updateImages()
    }

    @objc func longPressGestureAction(_ gestureRecognizer: UILongPressGestureRecognizer) {
        let pressedItemLocation = gestureRecognizer.location(in: imagesCollectionView)

        guard let indexPath = imagesCollectionView.indexPathForItem(at: pressedItemLocation) else {
            return
        }

        let cell = imagesCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell

        if gestureRecognizer.state == .began {
            os_log("Long Press Detected at index %d: %s", indexPath.row, String(describing: cell?.authorLabel.text))
            cell?.authorLabel.startShimmering()
        } else if gestureRecognizer.state == .ended {
            cell?.authorLabel.stopShimmering()
        }
    }

    /// recursive function that removes all the vowels in a string
    fileprivate func removeVowelsFrom(_ name: String, _ offset: Int = 0) -> String {
        var result = name
        print("result: \(result) | offset \(offset) | nameCount: \(name.count)")
        if offset == name.count {
            return result
        } else {
            let index = name.index(name.startIndex, offsetBy: offset)
            print("Checking for letter \(name[index])")
            if vowelsList.contains(name[index]) {
                print("letter removed from \(name)")
                result.remove(at: index)
                print("calling recursive function with '\(result)' and offset \(offset)")
                return removeVowelsFrom(result, offset)
            }
            print("calling recursive function with '\(result)' and offset \(offset + 1)")
            return removeVowelsFrom(result, offset + 1)
        }
    }
}

extension ViewController: UICollectionViewDelegate, UICollectionViewDataSource {

    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
//        imagesList.count
        guard let imageData = imageService?.imageData else {
            os_log(.debug, "No Image Data")
            return 0
        }
        return imageData.count
    }

    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: imageCellIdentifier, for: indexPath) as? ImageCollectionViewCell else {
            preconditionFailure("Cell with reuseidentifier \(imageCellIdentifier) does not exist")
        }

        cell.configureCell()
        cell.imageView.image = imageService?.getImage(for: indexPath.row)
        cell.authorLabel.text = imageService?.imageData[indexPath.row].author
        return cell
    }

    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        /*
            execute a recursive function that removes all the vowels in the
            author name on the tapped item and updates the name label on the image item tapped
        */
        if let cell = imagesCollectionView.cellForItem(at: indexPath) as? ImageCollectionViewCell, let authorName = cell.authorLabel.text {
            DispatchQueue.main.async {
//                cell.authorLabel.text?.removeAll(where: { self.vowelsList.contains($0) })
                cell.authorLabel.text = self.removeVowelsFrom(authorName)
            }
        }

    }

}

