import Foundation
import UIKit

extension UIView {
    /// adds a shimmering effect to the view
    public func startShimmering() {
        let alpha = UIColor.white.withAlphaComponent(0.3).cgColor
        let white = UIColor.white.cgColor

        let gradient = CAGradientLayer()
        gradient.frame = self.bounds
        gradient.colors = [alpha, white, alpha]
        gradient.startPoint = CGPoint(x: 0, y: 1)
        gradient.endPoint = CGPoint(x: 1, y: 0)
        gradient.locations = [-0.25, 0.5, 1.25]
        self.layer.mask = gradient

        let animation = CABasicAnimation(keyPath: "locations")
        animation.duration = 3
        animation.repeatCount = .infinity
        animation.autoreverses = true
        animation.fromValue = [0.0, 0.1, 0.2]
        animation.toValue = [0.8, 0.9, 1.0]
        gradient.add(animation, forKey: nil)
    }

    /// stops the shimmering effect on the view
    public func stopShimmering() {
        self.layer.mask = nil
    }
}
