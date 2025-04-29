//
//  TabbarViewController.swift
//  HeartRate
//
//  Created by Pham Van Thai on 28/11/24.
//

import UIKit
//import AppTrackingTransparency
//import AdjustSdk
//import FirebaseAnalytics

protocol ContainerViewControllerDelegate: AnyObject {
    func navigateToCreateCode()
}

class ContainerVC: UIViewController {
    weak var delegate: ContainerViewControllerDelegate?
    
    @IBOutlet weak var tabbarView: UIView!
    @IBOutlet weak var contentView: UIView!
    @IBOutlet weak var bannerView: UIView!
    @IBOutlet weak var heightBannerAds: NSLayoutConstraint!
    
    @IBOutlet weak var homeImage: UIImageView!
    @IBOutlet weak var homeLB: UILabel!
    @IBOutlet weak var myVideosImage: UIImageView!
    @IBOutlet weak var myVideosLB: UILabel!
    
    
    @IBOutlet weak var cameraView: UIView!
    private var currentViewController: UIViewController?
    private var isTabbarHidden: Bool = false
    private var originalTabBarHeight: CGFloat = 0
    private weak var observer: NSObjectProtocol?
    
    private let homeVC = HomeVC(viewModel: HomeViewModel.shared)
    private lazy var cameraVC = CameraVC()
    private let myVideos = MyVideosVC()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        switchToViewController(homeVC)
//        requestNotificationAuthorization()
        setupView()
//        setupBannerAds()
        DispatchQueue.main.async {
            self.goToHomeVC()
            self.cameraView.layer.cornerRadius = self.cameraView.bounds.width / 2
            self.cameraView.backgroundColor = .hexC8D4FF
            self.cameraView.clipsToBounds = true
        }
//        addObservers()
//        Analytics.logEvent(EventConstraint.HOME_SCREEN, parameters: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        updateLanguage()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
    }
    
    func setupView() {
        tabbarView.layer.masksToBounds = false
        tabbarView.layer.shadowColor = UIColor.black.cgColor
        tabbarView.layer.shadowOpacity = 0.2
        tabbarView.layer.shadowOffset = CGSize(width: -1, height: 1)
        tabbarView.layer.shadowRadius = 8
        tabbarView.layer.cornerRadius = 8
        tabbarView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
    }
    
    // MARK: - Add observers
//    private func addObservers() {
//        NotificationManager.shared.addObserver(observer: self, selector: #selector(handleRemoveAds(_:)), name: .custom_removeAds)
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(updateLanguage),
//                                               name: NSNotification.Name("LanguageChanged"),
//                                               object: nil)
//    }
    
    @objc
    private func updateLanguage() {
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self,
                                                  name: NSNotification.Name("LanguageChanged"),
                                                  object: nil)
//        removeObserver()
    }
    
    private func switchToViewController(_ viewController: UIViewController) {
        // Xóa nội dung cũ
        contentView.subviews.forEach { $0.removeFromSuperview() }
        // Thêm view controller mới
        addChild(viewController)
        contentView.addSubview(viewController.view)
        
        viewController.view.frame = contentView.bounds
        viewController.didMove(toParent: self)
    }
    
    func goToHomeVC() {
        switchToViewController(homeVC)
        homeImage.image = .homeSelectedIc
        homeLB.textColor = .hex212121
        myVideosImage.image = .myvideoUnselectedIc
        myVideosLB.textColor = .hexA5A5A5
    }
    
    func goToMyVideosVC() {
        switchToViewController(myVideos)
        homeImage.image = .homeUnselectedIc
        homeLB.textColor = .hexA5A5A5
        myVideosImage.image = .myvideoSelectedIc
        myVideosLB.textColor = .hex212121
    }
    
    func goToCameraVC() {
        cameraVC.challenges = HomeViewModel.shared.allChallenges.prefix(13).map { $0 }
        navigationController?.pushViewController(cameraVC, animated: false)
    }
    
    @IBAction func didTapCameraButton(_ sender: Any) {
        goToCameraVC()
    }
    
    @IBAction func didTapHomeButton(_ sender: Any) {
        goToHomeVC()
    }
    
    @IBAction func didTapMyVideosButton(_ sender: Any) {
        goToMyVideosVC()
    }
}

//extension ContainerVC {
//    func requestNotificationAuthorization() {
//        guard !UserDefaultsManager.shared.isShowATT else { return }
//        UserDefaultsManager.shared.onResumeCanLoad = false
//        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { _, _ in
//            UserDefaultsManager.shared.onResumeCanLoad = true
//            DispatchQueue.main.asyncAfter(deadline: .now() + 1) { [weak self] in
//                guard let self = self else { return }
//                self.requestTrackingAuthorization()
//            }
//        }
//    }
//    
//    func requestTrackingAuthorization() {
//        self.removeObserver()
//        UserDefaultsManager.shared.onResumeCanLoad = false
//        
//        ATTrackingManager.requestTrackingAuthorization {
//            [weak self] status in
//            UserDefaultsManager.shared.onResumeCanLoad = true
//            guard let self = self else { return }
//            self.setupAdjust()
//            if status == .denied,
//               ATTrackingManager.trackingAuthorizationStatus == .notDetermined {
//                debugPrint("iOS 17.4 authorization bug detected")
//                self.addObserver()
//                return
//            }
//            if !UserDefaultsManager.shared.isShowATT {
//                UserDefaultsManager.shared.isShowATT = true
//                Analytics.logEvent("show_ATT_\(EventConstraint.VERSION_APP)", parameters: nil)
//                if status == .denied {
//                    Analytics.logEvent("denied_ATT_\(EventConstraint.VERSION_APP)", parameters: nil)
//                } else if status == .authorized {
//                    Analytics.logEvent("allowed_ATT_\(EventConstraint.VERSION_APP)", parameters: nil)
//                } else if status == .notDetermined {
//                    Analytics.logEvent("not_determined_ATT_\(EventConstraint.VERSION_APP)", parameters: nil)
//                } else if status == .restricted {
//                    Analytics.logEvent("restricted_ATT_\(EventConstraint.VERSION_APP)", parameters: nil)
//                } else {
//                    Analytics.logEvent("unknown_ATT_\(EventConstraint.VERSION_APP)", parameters: nil)
//                }
//            }
//            debugPrint("status = \(status)")
//        }
//    }
//    
//    
//    private func addObserver() {
//        self.removeObserver()
//        self.observer = NotificationCenter.default.addObserver(
//            forName: UIApplication.didBecomeActiveNotification,
//            object: nil,
//            queue: .main
//        ) { [weak self] _ in
//            self?.requestTrackingAuthorization()
//        }
//    }
//
//    private func removeObserver() {
//        if let observer {
//            NotificationCenter.default.removeObserver(observer)
//        }
//        self.observer = nil
//    }
//    
//    private func setupAdjust() {
//        let yourAppToken = AdMobConstants.APP_ID_ADJUST
//#if DEBUG
//        let environment = ADJEnvironmentSandbox
//        let adjustConfig = ADJConfig(
//            appToken: yourAppToken,
//            environment: environment)
//        adjustConfig?.logLevel = .verbose
//        
//#else
//        let environment = ADJEnvironmentProduction
//        let adjustConfig = ADJConfig(
//            appToken: yourAppToken,
//            environment: environment)
//        adjustConfig?.logLevel = .suppress
//#endif
//        Adjust.initSdk(adjustConfig)
//    }
//    
//}

// MARK: - set up banner
//extension ContainerVC {
//    private func setupBannerAds() {
//        if !UserDefaultsManager.shared.isRemoveAllAds {
//            if RemoteConfigManager.shared.banner_home == 1 {
//                let id = AdMobConstants.BANNER_HOME
//                let config = BannerPlugin.Config(defaultAdUnitId: id, defaultBannerType: .Adaptive)
//                let _ = BannerPlugin(rootViewController: self, adContainer: bannerView, config: config)
//            }
//        }
//    }
//}
//
//extension ContainerVC {
//    @objc private func handleRemoveAds(_ notification: Notification) {
//        DispatchQueue.main.async { [weak self] in
//            guard let self = self else { return }
//            //iapBtn.isHidden = true
//            heightBannerAds.constant = 0
//            heightBannerAds.priority = UILayoutPriority(1000)
//            //sideMenu.hideIAP()
//            removeChildAds()
////            menuBtn.isHidden = true
//            view.layoutIfNeeded()
//        }
//    }
//    
//    private func removeChildAds() {
//        for child in children {
//            if child is NativeAdViewController || child is BannerAdViewController {
//                child.willMove(toParent: nil)
//                child.view.removeFromSuperview()
//                child.removeFromParent()
//            }
//        }
//    }
//}
