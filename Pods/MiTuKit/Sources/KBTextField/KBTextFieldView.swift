//
//  KBTextFieldView.swift
//  
//
//  Created by Admin on 19/5/24.
//

import UIKit

@available(iOS 15.0, *)
class KBTextFieldView: UIView {
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented")}
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    //Variables
    var edgeInsets: UIEdgeInsets = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: -16) {
        didSet {
            self.layoutIfNeeded()
        }
    }
    
    var maxheightTextField: CGFloat = 150.0 {
        didSet {
            self.layoutIfNeeded()
        }
    }
    var minheightTextField: CGFloat = 50.0 {
        didSet {
            self.layoutIfNeeded()
        }
    }
    
    let emojiView = UIView()
    let textField = TTextField()
    
    private var _textFieldConfig: TTextFieldConfigs?
    
    var textFieldConfig: TTextFieldConfigs {
        get {
            if let configs = _textFieldConfig {
                return configs
            }
            
            var tfConfigs = TTextFieldConfigs()
            tfConfigs.borderWidth = 0.5
            tfConfigs.cornerRadius = 5
            tfConfigs.backgroundColor = .white
            tfConfigs.placeHolderFont = .systemFont(ofSize: 17)
            tfConfigs.placeHolderTextColor = .gray
            tfConfigs.hiddenPlaceholderOnTop = true
            
            return tfConfigs
        }
        set {
            _textFieldConfig = newValue
        }
    }
}


//MARK: Functions
@available(iOS 15.0, *)
extension KBTextFieldView {
    func setupView() {
        backgroundColor = .white
        
        textField >>> self >>> {
            $0.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(edgeInsets.left)
                $0.trailing.equalToSuperview().offset(edgeInsets.right)
                $0.bottom.equalTo(self.keyboardLayoutGuide.snp.top).offset(edgeInsets.bottom)
                $0.height.equalTo(minheightTextField)
            }
            $0.configs = textFieldConfig
        }
        
        emojiView >>> self >>> {
            $0.snp.makeConstraints {
                $0.leading.equalToSuperview().offset(edgeInsets.left)
                $0.trailing.equalToSuperview().offset(edgeInsets.right)
                $0.bottom.equalTo(textField.snp.top)
                $0.top.equalToSuperview()
            }
        }
        
        
    }

}
