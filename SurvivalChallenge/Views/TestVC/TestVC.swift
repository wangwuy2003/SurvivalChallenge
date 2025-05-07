import UIKit
import AVFoundation
import Vision
import Stevia

class TestVC: UIViewController {
    @IBOutlet weak var imageView: UIImageView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
        if let image = UIImage(named: "paint_roller_bottom_ic") {
            let coloredImage = image.fillWhiteAreas(with: .red)
            imageView.image = coloredImage
        }
    }
    
    @objc private func backButtonTapped() {
        dismiss(animated: true)
    }
}

extension CGPoint {
    static func + (left: CGPoint, right: CGPoint) -> CGPoint {
        return CGPoint(x: left.x + right.x, y: left.y + right.y)
    }
    
    static func / (point: CGPoint, scalar: CGFloat) -> CGPoint {
        return CGPoint(x: point.x / scalar, y: point.y / scalar)
    }
}
