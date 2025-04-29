//
//  MTTextField.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import Foundation
import UIKit

public extension UITextField {
    func eventHandle(for controlEvent: UIControl.Event, _ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: controlEvent)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func editingDidEndHandle(_ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: .editingDidEnd)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func editingChangedHandle(_ closure: @escaping ()->()) {
        let sleeve = ClosureSleeve(closure)
        addTarget(sleeve, action: #selector(ClosureSleeve.invoke), for: .editingChanged)
        objc_setAssociatedObject(self, "[\(arc4random())]", sleeve, objc_AssociationPolicy.OBJC_ASSOCIATION_RETAIN)
    }
    
    func errorState(color: UIColor = UIColor.red) {
        self.layer.borderColor = color.cgColor
    }
    
    func normalState(color: UIColor = UIColor.lightGray) {
        self.layer.borderColor = color.cgColor
    }
}

//MARK: Custom class
public class MTTextfield: UITextField {
    //Variables
    public var hidePassImageName: String = ""
    public var showPassImageName: String = ""
    
    public var clearButtonColor: UIColor = .white {
        didSet {
            self.layoutIfNeeded()
        }
    }
    
    private var didUpdated: Bool = false
    public var clearImage: UIImage?
    
    private var _deleteHandle: (() -> Void)?
    public func deleteHandle(handle: @escaping () -> Void) {
        self._deleteHandle = handle
    }
    
    public override func deleteBackward() {
        super.deleteBackward()
        if let handle = self._deleteHandle {
            handle()
        }
    }
    
    public override func layoutSubviews() {
        super.layoutSubviews()
        if didUpdated {return}
        for view in subviews {
            if let button = view as? UIButton {
                if let clearImage = self.clearImage, let buttonImage = button.image(for: .normal) {
                    let image = clearImage.resize(targetSize: buttonImage.size)
                    button.setImage(image.withRenderingMode(.alwaysTemplate), for: .normal)
                } else {
                    button.setImage(button.image(for: .normal)?.withRenderingMode(.alwaysTemplate), for: .normal)
                }
                button.tintColor = self.clearButtonColor
                self.didUpdated = true
            }
        }
    }
}

public extension MTTextfield {
    func addSecureTextEntry(imageframe: CGRect = CGRect(x: 0, y: 0, width: 30, height: 20)) {
        let view = UIView(frame: imageframe)
        let rightButton = UIButton()
        rightButton.imageView?.contentMode = .scaleAspectFit
        rightButton.setImage(UIImage(named: self.hidePassImageName) , for: .normal)
        rightButton >>> view >>> {
            let frame = CGRect(x: 0, y: 0, width: view.frame.width - 10, height: view.frame.height)
            $0.frame = frame
            $0.handle {
                self.toggleSecureTextEntry()
            }
        }

        self.rightView = view
        rightViewMode = .unlessEditing
        isSecureTextEntry = true
    }

    func toggleSecureTextEntry() {
        isSecureTextEntry.toggle()
        
        guard let rightButton = self.rightView?.subviews.map({$0 as! UIButton}).first else {return}
        if isSecureTextEntry {
            rightButton.setImage(UIImage(named: self.hidePassImageName) , for: .normal)
        } else {
            rightButton.setImage(UIImage(named: self.showPassImageName) , for: .normal)
        }
    }
}

#endif
