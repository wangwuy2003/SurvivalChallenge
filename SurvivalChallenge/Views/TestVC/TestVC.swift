import UIKit
import AVFoundation
import Vision
import Stevia

class TestVC: UIViewController {
    @IBOutlet weak var coloringView: ColoringView!
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black
        
    }
    
    @objc private func backButtonTapped() { 
        dismiss(animated: true)
    }
    
}
