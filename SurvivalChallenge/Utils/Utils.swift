//
//  Utils.swift
//  QUIZZ_REEL_IOS
//
//  Created by Tran Nghia Pro on 20/8/24.
//

import Foundation
import UIKit
import AVFoundation
//import IceCream

open class Utils {
    
    static let nameIcloud = "iCloud.com.authenticator.app.two.factor.otp"
    static let nameAppGroup = "group.com.authenticator.app.two.factor.otp"
    static let realmVersion: UInt64 = 1
    static let privacyURL = "http://bambooglobal.site/privacy-policy-ios-dcl.html?store=HUYNH%20DUONG%20VAN&app=Authenticator%20App:%20Secure%202FA"
    static let termOfUseURL = "http://bambooglobal.site/termsofuse-ios-dcl.html?store=HUYNH"
    
    
    static var copyAlert: UIAlertController?
    static var settingAlert: UIAlertController?
    static var internetAlert: UIAlertController?
    static var forgotAlert: UIAlertController?
    static var notiAlert: UIAlertController?
    
    static var showIAP = false
    
    
    private static var overlayView: UIView?
    
    static func secureCompare(_ array1: [UInt8], _ array2: [UInt8]) -> Bool {
        guard array1.count == array2.count else { return false }
        return zip(array1, array2).reduce(true) { $0 && ($1.0 == $1.1) }
    }
    
    static func getNameDevice() -> String {
        return UIDevice.current.name
    }
    
    static func openLink(urlString: String) {
        guard let url = URL(string: urlString) else {
            print("URL không hợp lệ: \(urlString)")
            return
        }
        
        if UIApplication.shared.canOpenURL(url) {
            UIApplication.shared.open(url, options: [:]) { success in
                if success {
                    print("Mở liên kết thành công: \(urlString)")
                } else {
                    print("Không thể mở liên kết: \(urlString)")
                }
            }
        } else {
            print("Không thể mở URL: \(urlString)")
        }
    }
    
    static func showIndicator() {
        overlayView?.removeFromSuperview()
        overlayView = nil
        guard let topVC = UIApplication.shared.topViewController() else { return }
        
        // Create an overlay view if it doesn't exist
        overlayView = UIView(frame: topVC.view.bounds)
        guard let overlayView = self.overlayView else { return }
        overlayView.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        // Add an activity indicator
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.color = .white
        activityIndicator.center = overlayView.center
        activityIndicator.startAnimating()
        overlayView.addSubview(activityIndicator)
        topVC.view.addSubview(overlayView)
    }
    
    static func removeIndicator() {
        overlayView?.removeFromSuperview()
        overlayView = nil
    }
    
    static func isIpad() -> Bool {
        return UIDevice.current.userInterfaceIdiom == .pad
    }
    
    static func appDelegate() -> AppDelegate? {
        guard let delegate = UIApplication.shared.delegate as? AppDelegate else {
            return nil
        }
        return delegate
    }
    
    static func displayCopyAlert() {
        copyAlert = UIAlertController(title: nil, message: "Copied to the clipboard!", preferredStyle: .alert)
        guard let copyAlert = copyAlert else { return }
        copyAlert.addAction(UIAlertAction(title: "OK", style: .default, handler: {  _  in
            self.copyAlert = nil
        }))
        // Giả sử bạn gọi từ ViewController
        if let topVC = UIApplication.shared.topViewController() {
            topVC.present(copyAlert, animated: true)
        }
    }
    
    static func showAlertWithCancel(title: String? = nil, message: String? = nil, okTitle: String = "OK", cancelTitle: String = "Cancel", completionCancel: (() -> Void)? = nil, completion: (() -> Void)? = nil) {
        notiAlert = UIAlertController(title: Localizable.localizedString(title ?? ""), message: Localizable.localizedString(message ?? ""), preferredStyle: .alert)
        guard let notiAlert = notiAlert else { return }
        let okAction = UIAlertAction(title: okTitle, style: .destructive) { _ in
            completion?()
        }
        let cancelAction = UIAlertAction(title: cancelTitle, style: .default) {
            _ in
            completionCancel?()
        }
        
        notiAlert.addAction(cancelAction)
        notiAlert.addAction(okAction)
        UIApplication.shared.topViewController()?.present(notiAlert, animated: true, completion: nil)
    }
    
    static func showAlertOK(title: String? = nil, message: String? = nil, okTitle: String = Localizable.localizedString("OK"), completion: (() -> Void)? = nil) {
        notiAlert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        guard let notiAlert = self.notiAlert else { return }
        let okAction = UIAlertAction(title: okTitle, style: .default) { _ in
            completion?()
        }
        notiAlert.addAction(okAction)
        UIApplication.shared.topViewController()?.present(notiAlert, animated: true, completion: nil)
    }
    
//    static func showIAPVC(nameVC: String) {
//        if !showIAP {
//            showIAP = true
//            let vc = IAPVC()
//            vc.fromVC = nameVC
//            UIApplication.shared.topViewController()?.navigationController?.pushViewController(vc, animated: true)
//        }
//    }
    
    static func dismissAllAlerts() {
        copyAlert?.dismiss(animated: false)
        copyAlert = nil
        settingAlert?.dismiss(animated: false)
        settingAlert = nil
        forgotAlert?.dismiss(animated: false)
        forgotAlert = nil
        notiAlert?.dismiss(animated: false)
        notiAlert = nil
        dismisNoInternet()
    }
    
    static func dismisNoInternet() {
        internetAlert?.dismiss(animated: false)
        internetAlert = nil
    }
    
    
    static func showNoInternetAlert() {
        dismissAllAlerts()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01, execute: {
            guard internetAlert == nil else { return }
            internetAlert = UIAlertController(title: Localizable.localizedString("No Internet!"),
                                             message: "You need internet to load data. Please check your network settings.",
                                             preferredStyle: .alert)
            guard let internetAlert = self.internetAlert else { return }
            let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { _ in
                self.goToWifiSetting()
                self.internetAlert = nil
            }
            internetAlert.addAction(settingsAction)
            UIApplication.shared.topViewController()?.present(internetAlert, animated: true, completion: nil)
        })
    }
    
    static func showSettingsAlert(title: String = "Permission Required", message: String = "Please go to Settings and allow the FaceID or TouchID for this app.") {
        settingAlert = UIAlertController(title: title,
                                         message: message,
                                         preferredStyle: .alert)
        guard let settingAlert = self.settingAlert else { return }
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { _ in
            self.showSystemSetting()
            self.settingAlert = nil
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.settingAlert = nil
        })
        settingAlert.addAction(settingsAction)
        settingAlert.addAction(cancelAction)
        UIApplication.shared.topViewController()?.present(settingAlert, animated: true, completion: nil)
    }
    
    static func showCameraSettingsAlert() {
        settingAlert = UIAlertController(title: "Camera Access Denied",
                                         message: "Please allow camera access in Settings to scan QR codes.",
                                         preferredStyle: .alert)
        guard let settingAlert = self.settingAlert else { return }
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { _ in
            self.goToSetting()
            self.settingAlert = nil
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.settingAlert = nil
        })
        settingAlert.addAction(settingsAction)
        settingAlert.addAction(cancelAction)
        UIApplication.shared.topViewController()?.present(settingAlert, animated: true, completion: nil)
    }
    
    static func showPhotoSettingsAlert() {
        settingAlert =  UIAlertController(title: "Photo Library Access Denied",
                                          message: "Please allow photo library access in Settings to select a photo.",
                                          preferredStyle: .alert)
        guard let settingAlert = self.settingAlert else { return }
        let settingsAction = UIAlertAction(title: "Go to Settings", style: .default) { _ in
            self.goToSetting()
            self.settingAlert = nil
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { _ in
            self.settingAlert = nil
        })
        settingAlert.addAction(settingsAction)
        settingAlert.addAction(cancelAction)
        UIApplication.shared.topViewController()?.present(settingAlert, animated: true, completion: nil)
    }
    
    
    static func showSystemSetting() {
        if let settingsURL = URL(string: "App-prefs:") {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UserDefaultsManager.shared.isRequestRate = true
                UIApplication.shared.open(settingsURL)
            } else {
                print("Cannot open Settings")
            }
        }
    }
    
    static func showGeneralSetting() {
        if let settingsURL = URL(string: "App-Prefs:") {
            if UIApplication.shared.canOpenURL(settingsURL) {
                UserDefaultsManager.shared.isRequestRate = true
                UIApplication.shared.open(settingsURL)
            } else {
                print("Cannot open Settings")
            }
        }
    }
    
    static func goToWifiSetting() {
        if let url = URL(string: "App-Prefs:WIFI") {
            if UIApplication.shared.canOpenURL(url) {
                UserDefaultsManager.shared.isRequestRate = true
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            } else {
                if let urls = URL(string: UIApplication.openSettingsURLString) {
                    if UIApplication.shared.canOpenURL(urls) {
                        UserDefaultsManager.shared.isRequestRate = true
                        UIApplication.shared.open(urls, options: [:], completionHandler: nil)
                    }
                }
            }
        } else {
            if let url = URL(string: UIApplication.openSettingsURLString) {
                if UIApplication.shared.canOpenURL(url) {
                    UserDefaultsManager.shared.isRequestRate = true
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
            }
        }
    }
    
    static func goToSetting() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UserDefaultsManager.shared.isRequestRate = true
            UIApplication.shared.open(settingsURL)
        }
    }
    
    static func imageOrientation(
            fromDevicePosition devicePosition: AVCaptureDevice.Position,
            deviceOrientation: UIDeviceOrientation
    ) -> UIImage.Orientation {
        switch deviceOrientation {
        case .portrait:
            return devicePosition == .front ? .leftMirrored : .right
        case .landscapeLeft:
            return devicePosition == .front ? .downMirrored : .up
        case .portraitUpsideDown:
            return devicePosition == .front ? .rightMirrored : .left
        case .landscapeRight:
            return devicePosition == .front ? .upMirrored : .down
        case .faceDown, .faceUp, .unknown:
            return devicePosition == .front ? .leftMirrored : .right
        @unknown default:
            return devicePosition == .front ? .leftMirrored : .right
        }
    }
}

