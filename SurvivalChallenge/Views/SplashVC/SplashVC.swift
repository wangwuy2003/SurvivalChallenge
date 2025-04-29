//
//  SplashVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 12/4/25.
//

import UIKit
import SDWebImage

class SplashVC: UIViewController {
    
    var firstSplash = false
    
    let languageVC = LanguageVC()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        fetchDataAndNavigate()
    }
    
    private func fetchDataAndNavigate() {
        showLoadingIndicator()
        
        HomeViewModel.shared.fetchChallenges()
        
        HomeViewModel.shared.onDataUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.hideLoadingIndicator()
                self.pushToVC()
            }
        }
    }
    
    private func prefetchImages() {
        let imageUrls = HomeViewModel.shared.allChallenges.compactMap { challenge -> URL? in
            guard let thumpUrl = challenge.thumpUrl else { return nil }
            return URL(string: thumpUrl)
        }
        
        print("Prefetching \(imageUrls.count) images...")
        
        SDWebImagePrefetcher.shared.prefetchURLs(imageUrls) { [weak self] completedCount, skippedCount in
            print("Prefetched \(completedCount) images, skipped \(skippedCount) images.")
            DispatchQueue.main.async {
                self?.hideLoadingIndicator()
                self?.pushToVC()
            }
        }
    }
}

extension SplashVC {
    private func pushToVC() {
        if firstSplash {
            languageVC.isSplashPush = true
            self.navigationController?.setViewControllers([languageVC], animated: false)
        } else {
            let containerVC = ContainerVC()
            self.navigationController?.setViewControllers([containerVC], animated: false)
        }
    }
    
    private func showLoadingIndicator() {
        let activityIndicator = UIActivityIndicatorView(style: .large)
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }
    
    private func hideLoadingIndicator() {
        view.subviews
            .filter { $0 is UIActivityIndicatorView }
            .forEach { $0.removeFromSuperview() }
    }
}
