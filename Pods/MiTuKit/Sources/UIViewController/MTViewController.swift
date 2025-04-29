//
//  MTViewController.swift
//  MiTuKit
//
//  Created by Hồ Minh Tường on 21/11/21.
//  Copyright © 2021 - Present MiTu Ultra

#if os(iOS)
import UIKit
import Foundation
import MessageUI

public extension UIViewController {
    
    /// - parameter cancelTitle: default is nil
    /// - parameter userInterface: force to darkmode or light mode
    func showAlert(title: String? = nil, message: String? = nil, actionTile: String = "", cancelTitle: String? = nil, userInterface: UIUserInterfaceStyle = .light, completion: ((Bool) -> Void)? = nil) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.overrideUserInterfaceStyle = userInterface
        let action = UIAlertAction(title: actionTile, style: .default, handler: { _ in
            if completion != nil {
                completion!(true)
            }
        })
        alertVC.addAction(action)
        if let popoverController = alertVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        
        if let cancel = cancelTitle {
            let cancelAction = UIAlertAction(title: cancel, style: .cancel, handler: { _ in
                if completion != nil {
                    completion!(false)
                }
            })
            alertVC.addAction(cancelAction)
        }
        self.present(alertVC, animated: true, completion: {
            
        })
    }
    
    /// - parameter cancelTitle: default is nil
    /// - parameter userInterface: force to darkmode or light mode
    func showInputAlert(title: String? = nil, message: String? = nil, actionTile: String = "", cancelTitle: String? = nil, textFieldColor: UIColor? = nil, defaultText: String = "", placeHolder: String = "", userInterface: UIUserInterfaceStyle = .light, completion: @escaping(String?) -> Void) {
        let alertVC = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alertVC.overrideUserInterfaceStyle = userInterface
        alertVC.addTextField(configurationHandler: { textField in
            textField.text = defaultText
            textField.placeholder = placeHolder
            textField.clearButtonMode = .always
            if textFieldColor != nil {
                textField.textColor = textFieldColor
            }
        })
        
        let action = UIAlertAction(title: actionTile, style: .default, handler: { _ in
            let text = alertVC.textFields?.first?.text
            completion(text)
        })
        alertVC.addAction(action)
        
        if let popoverController = alertVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        
        let cancelAction = UIAlertAction(title: cancelTitle, style: .cancel, handler: { _ in
            completion(nil)
        })
        alertVC.addAction(cancelAction)
        self.present(alertVC, animated: true, completion: nil)
    }
    
    func openURL(_ urlAddress: String) {
        guard let url = URL(string: urlAddress) else {return}
        UIApplication.shared.open(url, options: [:], completionHandler: nil)
    }
    
    func share(items: [Any], completion: ((Bool) -> Void)? = nil) {
        let activityVC = UIActivityViewController(activityItems: items, applicationActivities: [])
        if let popoverController = activityVC.popoverPresentationController {
            popoverController.sourceView = self.view
            popoverController.sourceRect = CGRect(x: self.view.bounds.midX, y: self.view.bounds.midY, width: 0, height: 0)
        }
        activityVC.completionWithItemsHandler = {(activityType: UIActivity.ActivityType?, completed: Bool, returnedItems: [Any]?, error: Error?) in
            if !completed {
                if completion != nil {
                    completion!(false)
                }
                return
            }
            if completion != nil {
                completion!(true)
            }
        }
        
        present(activityVC, animated: true)
    }
    
}

public extension UIViewController {
    func hideKeyboardEvent() {
        let tapView = UIView()
        tapView >>> view >>> {
            $0.snp.makeConstraints {
                $0.edges.equalToSuperview()
            }
            $0.backgroundColor = .clear
        }
        view.sendSubviewToBack(tapView)
        let tap: UITapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        tapView.addGestureRecognizer(tap)
    }
    
    @objc func dismissKeyboard() {
        view.endEditing(true)
    }
    
    func hideKeyboardWhenTappedAround() {
        let tap = UITapGestureRecognizer(target: self, action: #selector(UIViewController.dismissKeyboard))
        tap.cancelsTouchesInView = false
        view.addGestureRecognizer(tap)
    }
}

public extension UIViewController {
    func add(_ child: UIViewController, completion: ((UIView) -> Void)? = nil) {
        child.view.frame = .zero
        addChild(child)
        view.addSubview(child.view)
        child.didMove(toParent: self)
        if let completion = completion {
            completion(child.view)
        }
    }
    
    func remove() {
        guard parent != nil else {
            return
        }
        willMove(toParent: nil)
        view.removeFromSuperview()
        removeFromParent()
    }
}

//MARK: Snapkit
public extension UIViewController {
    var topSafe: ConstraintRelatableTarget {
        return view.safeAreaLayoutGuide.snp.top
    }
    
    var botSafe: ConstraintRelatableTarget {
        return view.safeAreaLayoutGuide.snp.bottom
    }
    
    var leadingSafe: ConstraintRelatableTarget {
        return view.safeAreaLayoutGuide.snp.leading
    }
    
    var trailingSafe: ConstraintRelatableTarget {
        return view.safeAreaLayoutGuide.snp.trailing
    }
}

//MARK:: - send email
extension UIViewController {
    public func sendEmail(to: String, body: String, subject: String? = nil, delegate: MFMailComposeViewControllerDelegate) {
        
        if MFMailComposeViewController.canSendMail() {
            let mail = MFMailComposeViewController()
            mail.mailComposeDelegate = delegate
            
            mail.setToRecipients([to])
            mail.setMessageBody(body, isHTML: false)
            if let subject = subject {
                mail.setSubject(subject)
            }
            
            present(mail, animated: true)
        } else {
            print("Cannot open Email")
        }
    }
    
 //MARK: Copy this delegate
//    func mailComposeController(_ controller: MFMailComposeViewController, didFinishWith result: MFMailComposeResult, error: Error?) {
//        controller.dismiss(animated: true)
//    }
    
    public func canSendMail() -> Bool {
        return MFMailComposeViewController.canSendMail()
    }
}



// MARK: - Notification
extension UIViewController {
    public func requestNotification(title: String, subtitle: String, body: String, timeInterval: TimeInterval, repeats: Bool, requestIdentifier: String = UUID().uuidString, removeOldNotifications: Bool = false, delegate: UNUserNotificationCenterDelegate, completionHandler: ((Error?, String?) -> Void)? = nil) {
        
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (allowed, error) in
            if !allowed {
                if let block = completionHandler {
                    if let error = error {
                        block(error, nil)
                    } else {
                        block(MTError(title: "", description: "Permission denied!", code: 0), nil)
                    }
                }
                return
            }
            
            UNUserNotificationCenter.current().delegate = delegate
            
            if removeOldNotifications {
                UNUserNotificationCenter.current().removeAllDeliveredNotifications()
                UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            }
            self.sendNotification(title: title,
                                  subtitle: subtitle,
                                  body: body,
                                  timeInterval: timeInterval,
                                  repeats: repeats,
                                  requestIdentifier: requestIdentifier,
                                  completionHandler: completionHandler)
        }
    }
    
    public func sendNotification(title: String, subtitle: String, body: String, timeInterval: TimeInterval, repeats: Bool, requestIdentifier: String, completionHandler: ((Error?, String?) -> Void)? = nil) {
        let center = UNUserNotificationCenter.current()
        center.getPendingNotificationRequests(completionHandler: { pendingNotificationRequests in
            
            //Use the main thread since we want to access UIApplication.shared.applicationIconBadgeNumber
            DispatchQueue.main.sync {
                
                //Create the new content
                let content = UNMutableNotificationContent()
                content.title = title
                content.subtitle = subtitle
                content.body = body
                
                //Let's store the firing date of this notification in content.userInfo
                let firingDate = Date().timeIntervalSince1970 + timeInterval
                content.userInfo = ["timeInterval": firingDate]
                
                //get the count of pending notification that will be fired earlier than this one
                let earlierNotificationsCount: Int = pendingNotificationRequests.filter { request in
                    
                    let userInfo = request.content.userInfo
                    if let time = userInfo["timeInterval"] as? Double {
                        if time < firingDate {
                            return true
                        } else {
                            
                            //Here we update the notofication that have been created earlier, BUT have a later firing date
                            let newContent: UNMutableNotificationContent = request.content.mutableCopy() as! UNMutableNotificationContent
                            newContent.badge = (Int(truncating: request.content.badge ?? 0) + 1) as NSNumber
                            let newRequest: UNNotificationRequest =
                            UNNotificationRequest(identifier: request.identifier,
                                                  content: newContent,
                                                  trigger: request.trigger)
                            center.add(newRequest, withCompletionHandler: { (error) in
                                // Handle error
                            })
                            return false
                        }
                    }
                    return false
                }.count
                
                //Set the badge
                content.badge =  NSNumber(integerLiteral: UIApplication.shared.applicationIconBadgeNumber + earlierNotificationsCount + 1)
                let trigger = UNTimeIntervalNotificationTrigger(timeInterval: timeInterval,
                                                                repeats: repeats)
                
                let request = UNNotificationRequest(identifier: requestIdentifier,
                                                    content: content, trigger: trigger)
                
                center.add(request, withCompletionHandler: { error in
                    if let block = completionHandler {
                        block(error, requestIdentifier)
                    }
                })
            }
        })
    }
}

#endif
