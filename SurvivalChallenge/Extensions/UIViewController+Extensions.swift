

import Foundation
import UIKit

extension UIViewController {
    func pushToVC(vc: UIViewController, animated: Bool = false) {
        self.navigationController?.pushViewController(vc, animated: animated)
    }
    func popToVC(animated: Bool = false) {
        self.navigationController?.popViewController(animated: animated)
    }
    func showAlertOK(title: String? = nil, message: String? = nil, okTitle: String = "OK", completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: okTitle, style: .default) { _ in
            completion?()
        }
        
        alertController.addAction(okAction)
        present(alertController, animated: true, completion: nil)
    }
    
    func showAlertWithCancel(title: String? = nil, message: String? = nil, okTitle: String = "OK", cancelTitle: String = "Cancel", completionCancel: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        
        let okAction = UIAlertAction(title: okTitle, style: .default) { _ in
            completion?()
        }
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .destructive, handler: { _ in 
            completionCancel?()
        })
        
        alertController.addAction(okAction)
        alertController.addAction(cancelAction)
        
        present(alertController, animated: true, completion: nil)
    }
}
