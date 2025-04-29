//
//  TTextField.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

//Textfield with placeholder on top border
public class TTextField: UIView {
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupView()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        self.setupView()
    }
    
    public let containerView = UIView()
    public let textfield = MTTextfield()
    private let placeHolderLabel = UILabel()
    
    private var _placeholder: String?
    public var placeholder: String? {
        get {
            return self.textfield.placeholder
        }
        set {
            self._placeholder = newValue
            self.updatePlaceHolder()
        }
    }
    
    public var textFieldInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 8, bottom: 0, right: 8) {
        didSet {
            let inset = self.textFieldInsets
            self.textfield.snp.remakeConstraints {
                $0.top.equalToSuperview().offset(inset.top)
                $0.bottom.equalToSuperview().offset(-inset.bottom)
                $0.leading.equalToSuperview().offset(inset.left)
                $0.trailing.equalToSuperview().offset(-inset.right)
            }
            self.layoutIfNeeded()
        }
    }
    
    public var text: String? {
        get {
            return textfield.text
        }
        set {
            textfield.text = newValue
        }
    }
    
    public var textColor: UIColor? {
        get {
            return textfield.textColor
        }
        set {
            textfield.textColor = newValue
        }
    }
    
    public var clearButtonColor: UIColor = .white {
        didSet {
            textfield.clearButtonColor = self.clearButtonColor
        }
    }
    
    public var clearImage: UIImage? {
        didSet {
            textfield.clearImage = self.clearImage
        }
    }
    
    public func deleteHandle(handle: @escaping () -> Void) {
        self.textfield.deleteHandle {
            handle()
        }
    }
    
    public var displayRequired: Bool = false {
        didSet {
            self.updatePlaceHolder()
        }
    }
    public var displayOptional: Bool = false {
        didSet {
            self.updatePlaceHolder()
        }
    }
    
    private var _configs: TTextFieldConfigs?
    public var configs: TTextFieldConfigs {
        get {
            if _configs != nil {return _configs!}
            return globalTTextFieldConfigs
        }
        set {
            _configs = newValue
            self.updateUI()
        }
    }
    
    public var globalConfigs: TTextFieldConfigs {
        get {
            if _configs != nil {return _configs!}
            return globalTTextFieldConfigs
        }
        set {
            _configs = newValue
            globalTTextFieldConfigs = newValue
            self.updateUI()
        }
    }
    
    public var hidePassImageName: String {
        get {
            return self.textfield.hidePassImageName
        }
        set {
            self.textfield.hidePassImageName = newValue
        }
    }
    
    public var showPassImageName: String {
        get {
            return self.textfield.showPassImageName
        }
        set {
            self.textfield.showPassImageName = newValue
        }
    }
    
    public var delegate: UITextFieldDelegate? {
        get {
            return self.textfield.delegate
        }
        set {
            self.textfield.delegate = newValue
        }
    }
    
    public var returnKeyType: UIReturnKeyType {
        get {
            return self.textfield.returnKeyType
        }
        set {
            self.textfield.returnKeyType = newValue
        }
    }
    
    public override var tag: Int {
        get {
            return self.textfield.tag
        }
        set {
            self.textfield.tag = newValue
        }
    }
    
    public var textContentType: UITextContentType {
        get {
            return self.textfield.textContentType
        }
        set {
            self.textfield.textContentType = newValue
        }
    }
    
    public var keyboardType: UIKeyboardType {
        get {
            return self.textfield.keyboardType
        }
        set {
            self.textfield.keyboardType = newValue
        }
    }
    
    public var clearButtonMode: UITextField.ViewMode {
        get {
            return self.textfield.clearButtonMode
        }
        set {
            self.textfield.clearButtonMode = newValue
        }
    }
    
    public func eventHandle(for controlEvent: UIControl.Event, _ closure: @escaping ()->()) {
        self.textfield.eventHandle(for: controlEvent, closure)
    }
    
    public func editingChangedHandle(_ closure: @escaping ()->()) {
        self.textfield.editingChangedHandle(closure)
    }
    
    public func editingDidEndHandle(_ closure: @escaping ()->()) {
        self.textfield.editingDidEndHandle(closure)
    }
    
    public func errorState(color: UIColor = UIColor.red) {
        self.textfield.errorState(color: color)
    }
    
    public func normalState(color: UIColor = UIColor.lightGray) {
        self.textfield.normalState(color: color)
    }
    
    public func addSecureTextEntry(imageframe: CGRect = CGRect(x: 0, y: 0, width: 30, height: 20)) {
        self.textfield.addSecureTextEntry(imageframe: imageframe)
    }
    
    public func toggleSecureTextEntry() {
        self.textfield.toggleSecureTextEntry()
    }
    
}

extension TTextField {
    private func updateUI() {
        let config = self.configs
        
        self.containerView.backgroundColor = config.backgroundColor
        self.containerView.layer.cornerRadius = config.cornerRadius
        self.containerView.layer.borderWidth = config.borderWidth
        self.containerView.layer.borderColor = config.borderColor
        
        self.updatePlaceHolder()
    }
    
    private func updatePlaceHolder() {
        let config = self.configs
        
        guard var _placeHolder = self._placeholder, !_placeHolder.isEmpty else {return}
        
        let placeHolderAttribute = [ NSAttributedString.Key.foregroundColor: config.placeHolderTextColor, NSAttributedString.Key.font : config.placeHolderFont]
        let placeHolderStringAttribute = NSMutableAttributedString(string: _placeHolder, attributes: placeHolderAttribute)
        
        let attributedText: NSMutableAttributedString = NSMutableAttributedString(string: _placeHolder, attributes: placeHolderAttribute)
        
        if displayOptional {
            let optionalAttribute = [ NSAttributedString.Key.font: UIFont.italicSystemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: config.placeHolderTextColor]
            let optionalStringAttribute = NSMutableAttributedString(string: "(optional)", attributes: optionalAttribute)
            attributedText.append(optionalStringAttribute)
            _placeHolder += "(optional)"
        } else if displayRequired {
            let requiredAttribute = [ NSAttributedString.Key.font: UIFont.systemFont(ofSize: 15), NSAttributedString.Key.foregroundColor: UIColor.red]
            let requiredStringAttribute = NSMutableAttributedString(string: "*", attributes: requiredAttribute)
            attributedText.append(requiredStringAttribute)
            _placeHolder += "*"
        }

        self.textfield.attributedPlaceholder = placeHolderStringAttribute
        
        if globalTTextFieldConfigs.hiddenPlaceholderOnTop {return}
        
        self.placeHolderLabel.attributedText = attributedText
        
        let widthLabel: CGFloat = _placeHolder.width(height: 20, font: config.placeHolderFont)
        self.placeHolderLabel.snp.updateConstraints {
            $0.width.equalTo(max(widthLabel + 16, 20))
        }
        
        self.placeHolderLabel.backgroundColor = config.placeHolderBackgroundColor
    }
    
    private func setupView() {
        containerView >>> self >>> {
            $0.snp.makeConstraints {
                $0.top.equalToSuperview().offset(8)
                $0.trailing.leading.equalToSuperview()
                $0.bottom.equalToSuperview()
            }
            $0.backgroundColor = globalTTextFieldConfigs.backgroundColor
            $0.layer.cornerRadius = globalTTextFieldConfigs.cornerRadius
            $0.layer.borderWidth = globalTTextFieldConfigs.borderWidth
            $0.layer.borderColor = globalTTextFieldConfigs.borderColor
        }
        
        textfield >>> containerView >>> {
            let inset = self.textFieldInsets
            $0.snp.makeConstraints {
                $0.top.equalToSuperview().offset(inset.top)
                $0.leading.equalToSuperview().offset(inset.left)
                
                $0.bottom.equalToSuperview().offset(-inset.bottom)
                $0.trailing.equalToSuperview().offset(-inset.right)
            }
            $0.editingChangedHandle {
                if globalTTextFieldConfigs.hiddenPlaceholderOnTop {return}
                
                if let text = self.textfield.text, !text.isEmpty {
                    self.placeHolderLabel.isHidden = false
                } else {
                    self.placeHolderLabel.isHidden = true
                }
            }
            $0.editingDidEndHandle {
                if globalTTextFieldConfigs.hiddenPlaceholderOnTop {return}
                
                if let text = self.textfield.text, !text.isEmpty {
                    self.placeHolderLabel.isHidden = false
                } else {
                    self.placeHolderLabel.isHidden = true
                }
            }
        }
        
        placeHolderLabel >>> self >>> {
            $0.snp.makeConstraints {
                $0.centerY.equalTo(containerView.snp.top)
                $0.height.equalTo(20)
                $0.width.equalTo(20)
                $0.leading.equalTo(containerView.snp.leading).offset(8)
            }
            $0.font = globalTTextFieldConfigs.placeHolderFont
            $0.textAlignment = .center
            $0.backgroundColor = globalTTextFieldConfigs.placeHolderBackgroundColor
            $0.isHidden = true
        }
    }
}

//TTextFile Configs
public struct TTextFieldConfigs {
    public init() {}
    
    public var hiddenPlaceholderOnTop: Bool = false
    public var cornerRadius: CGFloat = 8.0
    public var borderWidth: CGFloat = 1.0
    public var borderColor: CGColor = UIColor.lightGray.cgColor
    public var backgroundColor: UIColor = UIColor.white
    public var placeHolderFont: UIFont = UIFont.systemFont(ofSize: 15)
    public var placeHolderTextColor: UIColor = UIColor.darkGray
    public var placeHolderBackgroundColor: UIColor = UIColor.white
}

private var globalTTextFieldConfigs = TTextFieldConfigs()

#endif
