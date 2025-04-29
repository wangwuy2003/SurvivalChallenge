//
//  ATAccessoryView.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit

public enum ATTextModeType {
    case light
    case dark
    case auto
}

open class ATAccessoryView: UIInputView {
    public override init(frame: CGRect, inputViewStyle: UIInputView.Style) {
        super.init(frame: frame, inputViewStyle: .keyboard)
        self.setupView()
    }
    
    public required init?(coder: NSCoder) { fatalError()}
    
    open override var intrinsicContentSize: CGSize {
        let textSize = self.textView.sizeThatFits(CGSize(width: self.textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
        let height = min (self.tvMaxHeight, textSize.height + 16)
        return CGSize(width: self.bounds.width, height: height)
    }

    
    //Variables
    public var maxLine: Int = 5 {
        didSet {
            let textSize = self.textView.sizeThatFits(CGSize(width: self.textView.bounds.width, height: CGFloat.greatestFiniteMagnitude))
            self.tvMaxHeight = (textSize.height * self.maxLine.cgFloat)
        }
    }
    
    public var buttonTitle: String = "Send" {
        didSet {
            self.sendButton.setTitle(buttonTitle, for: .normal)
            if let font = self.sendButton.titleLabel?.font {
                let width = buttonTitle.width(height: 40, font: font)
                self.tvMaxWidth = width + 16 // padding
            }
        }
    }
    
    public var textModeType: ATTextModeType = .auto {
        didSet {
            self.updateUI(self.textModeType)
        }
    }
    
    public var doneHandle: ((String?) -> Void)?
    public let textView = UITextView()
    public var textFont = UIFont.systemFont(ofSize: 17) {
        didSet {
            self.textView.font = textFont
        }
    }
    public var buttonFont = UIFont.boldSystemFont(ofSize: 17) {
        didSet {
            self.sendButton.titleLabel?.font = buttonFont
        }
    }
    public let sendButton = UIButton()
    
    private var tvMaxWidth: CGFloat = 79
    private var tvMaxHeight: CGFloat = 79
    
    
    
}

extension ATAccessoryView: UITextViewDelegate {
    public func textViewDidChange(_ textView: UITextView) {
        self.updateTextFieldUI()
    }
}


//MARK: Functions
public extension ATAccessoryView {
   private func setupView() {
       self.autoresizingMask = UIView.AutoresizingMask.flexibleHeight
       
       self.maxLine = 3
       
       sendButton >>> self >>> {
           $0.snp.makeConstraints {
              $0.trailing.bottom.equalToSuperview().offset(-8)
              $0.height.equalTo(40)
              $0.width.equalTo(0)
           }
           $0.isHidden = true
           $0.setTitle("Send", for: .normal)
           $0.titleLabel?.font = buttonFont
           let width = buttonTitle.width(height: 40, font: buttonFont)
           self.tvMaxWidth = width + 16
           $0.handle {
               if let handle = self.doneHandle {
                   handle(self.textView.text)
                   DispatchQueue.main.asyncAfter(deadline: .now() + 0.39, execute: {
                       self.textView.text = ""
                       self.updateTextFieldUI()
                   })
               }
               
           }
      }
       
        textView >>> self >>> {
            $0.snp.makeConstraints {
                $0.leading.top.equalToSuperview().offset(8)
                $0.bottom.equalToSuperview().offset(-8)
                $0.trailing.equalTo(sendButton.snp.leading).offset(-8)
            }
            $0.textContainer.lineFragmentPadding = 0
            $0.textContainerInset = UIEdgeInsets(top: 8, left: 12, bottom: 8, right: 0)
            $0.backgroundColor = .clear
            $0.font = textFont
            $0.delegate = self
            $0.layer.borderWidth = 1
            $0.layer.borderColor = UIColor.lightGray.cgColor
            $0.layer.cornerRadius = 12
        }
        
       self.updateUI(self.textModeType)
    }
    
    private func updateTextFieldUI() {
        self.invalidateIntrinsicContentSize()
        UIView.animate(withDuration: 0.39, delay: 0, options: .curveEaseInOut, animations: {
            self.layoutIfNeeded()
        })
        
        if let text = textView.text, !text.trimmingCharacters(in: .whitespaces).isEmpty {
            self.sendButton.isHidden = false
            self.sendButton.snp.updateConstraints {
                $0.width.equalTo(self.tvMaxWidth)
            }
            UIView.animate(withDuration: 0.39, delay: 0, options: .curveEaseInOut, animations: {
                self.layoutIfNeeded()
            })
        } else {
            self.sendButton.snp.updateConstraints {
                $0.width.equalTo(0)
            }
            self.sendButton.isHidden = true
            UIView.animate(withDuration: 0.39, delay: 0, options: .curveEaseInOut, animations: {
                self.layoutIfNeeded()
            })
        }
    }
    
    private func updateUI(_ type: ATTextModeType = .light) {
        switch type {
        case .light:
            self.UpdateUserInterfaceStyle(mode: .light)
            break
        case .dark:
            self.UpdateUserInterfaceStyle(mode: .dark)
            break
        case .auto:
            self.UpdateUserInterfaceStyle(mode: self.traitCollection.userInterfaceStyle)
            break
        }
    }
    
    private func UpdateUserInterfaceStyle(mode: UIUserInterfaceStyle = .light) {
        if mode == .light {
            self.textView.textColor = .white
            self.textView.layer.borderColor = UIColor.white.cgColor
            self.sendButton.setTitleColor(.white, for: .normal)
            self.sendButton.setTitleColor(.white.withAlphaComponent(0.5), for: .highlighted)
        } else {
            self.textView.textColor = .black
            self.textView.layer.borderColor = UIColor.lightGray.cgColor
            self.sendButton.setTitleColor(.black, for: .normal)
            self.sendButton.setTitleColor(.black.withAlphaComponent(0.5), for: .highlighted)
        }
    }

    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        if self.textModeType == .auto {
            self.updateUI(.auto)
        }
    }
}

#endif

