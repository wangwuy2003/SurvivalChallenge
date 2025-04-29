//
//  MTNavigationController.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

//MARK: - template to create a new class navigation
open class MTNavigationController: UINavigationController, UINavigationControllerDelegate {
    public init(_ rootVC: UIViewController) {
        super.init(rootViewController: rootVC)
        self.delegate = self
    }

    required public init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    open override var preferredStatusBarStyle: UIStatusBarStyle {return .lightContent}
    open override var childForStatusBarStyle: UIViewController? {return topViewController }

    open override func viewDidLoad() {
        super.viewDidLoad()
        
        let titleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
        let largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor: UIColor.white, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 34)]

        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .clear
        appearance.titleTextAttributes = titleTextAttributes
        appearance.largeTitleTextAttributes = largeTitleTextAttributes
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    open func navigationController(_ navigationController: UINavigationController, willShow viewController: UIViewController, animated: Bool) {
        
        viewController.navigationItem.largeTitleDisplayMode = .always
        viewController.navigationController?.navigationBar.prefersLargeTitles = true
        viewController.navigationController?.navigationBar.barTintColor = .yellow
        viewController.navigationController?.navigationBar.isTranslucent = true
        viewController.navigationController?.navigationBar.tintColor = UIColor.red
        viewController.navigationController?.navigationBar.titleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 20)]
        viewController.navigationController?.navigationBar.largeTitleTextAttributes = [NSAttributedString.Key.foregroundColor : UIColor.black, NSAttributedString.Key.font: UIFont.boldSystemFont(ofSize: 34)]
        let appearance = UINavigationBarAppearance()
        appearance.configureWithTransparentBackground()
        appearance.backgroundColor = .yellow
        UINavigationBar.appearance().standardAppearance = appearance
        UINavigationBar.appearance().scrollEdgeAppearance = appearance
    }
    
    open func navigationController(_ navigationController: UINavigationController, didShow viewController: UIViewController, animated: Bool) {
        
    }
}

public extension UINavigationController {
    /**
     Pop current view controller to previous view controller.

     - parameter type:     transition animation type.
     - parameter duration: transition animation duration.
     */
    func pop(transitionType type: CATransitionType = .fade, subType: CATransitionSubtype? = nil, duration: CFTimeInterval = 0.3) {
        self.addTransition(transitionType: type, subType: subType, duration: duration)
        self.popViewController(animated: false)
    }
    
    /**
     Pop current view controller to previous view controller.

     - parameter type:     transition animation type.
     - parameter duration: transition animation duration.
     */
    func popTo(view: UIViewController, transitionType type: CATransitionType = .fade, subType: CATransitionSubtype? = nil, duration: CFTimeInterval = 0.3) {
        self.addTransition(transitionType: type, subType: subType, duration: duration)
        self.popToViewController(view, animated: false)
    }
    
    func popToRootView(transitionType type: CATransitionType = .fade, subType: CATransitionSubtype? = nil, duration: CFTimeInterval = 0.3) {
        self.addTransition(transitionType: type, subType: subType, duration: duration)
        self.popToRootViewController(animated: false)
    }

    /**
     Push a new view controller on the view controllers's stack.

     - parameter vc:       view controller to push.
     - parameter type:     transition animation type.
     - parameter subType:  transition animation sub type.
     - parameter duration: transition animation duration.
     */
    func push(_ vc: UIViewController, transitionType type: CATransitionType = .fade, subType: CATransitionSubtype? = nil, duration: CFTimeInterval = 0.3) {
        self.addTransition(transitionType: type, subType: subType, duration: duration)
        self.pushViewController(vc, animated: false)
    }

    private func addTransition(transitionType type: CATransitionType = .fade, subType: CATransitionSubtype? = nil, duration: CFTimeInterval = 0.3) {
        let transition = CATransition()
        transition.duration = duration
        transition.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
        transition.type = type
        transition.subtype = subType
        
        self.view.layer.add(transition, forKey: nil)
    }

    
}

public extension UINavigationController {
    
    func getViewController<T: UIViewController>(of type: T.Type) -> UIViewController? {
        return self.viewControllers.first(where: { $0 is T })
    }

    func popToViewController<T: UIViewController>(of type: T.Type, animated: Bool) {
        guard let viewController = self.getViewController(of: type) else { return }
        self.popToViewController(viewController, animated: animated)
    }
}

#endif
