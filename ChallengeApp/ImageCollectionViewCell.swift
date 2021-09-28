import UIKit
import os.log


class ImageCollectionViewCell: UICollectionViewCell {
    @IBOutlet weak var authorLabel: UILabel!
    @IBOutlet weak var imageView: UIImageView!

    func configureCell() {
        // rotate author label here and ensure rounded corners on the cells

        layer.cornerRadius = 10
        layer.masksToBounds = true

        let angle: CGFloat = -45 * .pi / 180
        authorLabel.transform = CGAffineTransform(rotationAngle: angle)
    }
    
}
