//
//  HomeVC.swift
//  SurvivalChallenge
//
//  Created by Apple on 14/4/25.
//

import UIKit
import Stevia
import AVFoundation

class HomeVC: UIViewController {
    private let viewModel: HomeViewModel
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var strokeTitleLabel: UILabel!
    @IBOutlet weak var topStackView: UIStackView!
    @IBOutlet weak var collectionView: UICollectionView!
    
    private let activityIndicator = UIActivityIndicatorView(style: .large)
    
    private var selectedTopCategory: TopCategory = .hot {
        didSet {
            updateButtonColors()
        }
    }
    
    var challenges: [SurvivalChallengeEntity] = HomeViewModel.shared.allChallenges
    
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupViews()
        observeViewModelUpdates()
        setupCollectionView()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
//        collectionView.reloadData()
    }
    
    @objc private func didTapTopButton(_ sender: UIButton) {
        guard let tag = TopCategory(rawValue: sender.tag) else {
            return
        }
        
        selectedTopCategory = tag
        viewModel.selectCategory(selectedTopCategory)
    }
    
    @IBAction func didTapSettingBtn(_ sender: Any) {
        navigationController?.pushViewController(SettingVC(), animated: false)
    }
    
    deinit {
        Utils.removeIndicator()
    }
}

extension HomeVC {
    private func showLoadingIndicator() {
        activityIndicator.center = view.center
        activityIndicator.startAnimating()
        view.addSubview(activityIndicator)
    }

    private func hideLoadingIndicator() {
        activityIndicator.stopAnimating()
        activityIndicator.removeFromSuperview()
    }
    
    private func observeViewModelUpdates() {
        viewModel.onDataUpdated = { [weak self] in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.collectionView.reloadData()
            }
        }
    }
}

// MARK: - Setup View
extension HomeVC {
    func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(UINib(nibName: "HomeCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "homeCell")
        collectionView.backgroundColor = .white
    }
    
    func setupViews() {
        titleLabel.style {
            $0.clipsToBounds = true
            strokeTitleLabel.text = Localized.Home.survivalChallenge
            strokeTitleLabel.font = UIFont.luckiestGuyRegular(ofSize: 28)
            strokeTitleLabel.textColor = .hex212121
            let strokeAttr: [NSAttributedString.Key: Any] = [
                .strokeColor: UIColor.hex212121,
                .foregroundColor: UIColor.hex212121,
                .strokeWidth: 5
            ]
            strokeTitleLabel.attributedText = NSAttributedString(string: strokeTitleLabel.text!, attributes: strokeAttr)
     
            titleLabel.text = strokeTitleLabel.text
            titleLabel.font = strokeTitleLabel.font
            titleLabel.layer.shadowColor = UIColor.hex431B00.cgColor
            titleLabel.layer.shadowOffset = CGSize(width: 0, height: 4)
            titleLabel.layer.shadowOpacity = 1
            titleLabel.layer.shadowRadius = 0
            
            let success = $0.applyGradientWith(
                startColor: .hexFFA1A1,
                endColor: .hex4E75FF,
                direction: .leftToRight
            )
            if !success {
                print("Failed to apply gradient to label")
            }
        }
        
        setupTopStackViewButtons()
        updateButtonColors()
    }
    
    private func setupTopStackViewButtons() {
        TopCategory.allCases.forEach { category in
            let button = UIButton()
            button.setTitle(category.displayTitle, for: .normal)
            button.tag = category.rawValue
            button.addTarget(self, action: #selector(didTapTopButton(_:)), for: .touchUpInside)
            styleButton(button)
            topStackView.addArrangedSubview(button)
        }
    }
    
    private func styleButton(_ button: UIButton) {
        var config = UIButton.Configuration.borderedProminent()
        config.baseBackgroundColor = .hexE7E8E6
        config.baseForegroundColor = .hex212121.withAlphaComponent(0.45)
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { incoming in
            var outgoing = incoming
            outgoing.font = UIFont.sfProDisplayMedium(ofSize: 15)
            return outgoing
        }
        config.contentInsets = NSDirectionalEdgeInsets(
            top: 8,
            leading: 10,
            bottom: 8,
            trailing: 10
        )
        config.cornerStyle = .capsule
        
        button.configuration = config
        button.clipsToBounds = true
    }
    
    func updateButtonColors() {
        topStackView.arrangedSubviews.forEach { button in
            guard let button = button as? UIButton,
                  let categoryType = TopCategory(rawValue: button.tag) else {
                return
            }
            
            let isSelected = categoryType == selectedTopCategory
            
            if var config = button.configuration {
                config.baseBackgroundColor = isSelected ? .hexFFA1A1 : .hexE7E8E6
                config.baseForegroundColor = isSelected ? .hex212121 : .hex212121.withAlphaComponent(0.45)
                config.cornerStyle = .capsule
                button.configuration = config
            }
        }
    }
}

// MARK: - Collection Viewdes
extension HomeVC: UICollectionViewDataSource, UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return challenges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "homeCell", for: indexPath) as? HomeCollectionViewCell else {
            return UICollectionViewCell()
        }
        
        let challenge = HomeViewModel.shared.allChallenges[indexPath.item]
        cell.configureCell(model: challenge)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let item = challenges[indexPath.item]
        
        let previewVC = PreviewVC()
        previewVC.trendItem = item
        self.navigationController?.pushViewController(previewVC, animated: true)
    }
}

extension HomeVC: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = Utils.isIpad() ? 56 : 16
        let totalPadding = padding * 2
        let interitemSpacing: CGFloat = 10
        let totalWidth = UIScreen.main.bounds.width - totalPadding - interitemSpacing
        let itemWidth = totalWidth / 2
        
        return CGSize(width: Int(itemWidth), height: 266)
    }
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        20
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumInteritemSpacingForSectionAt section: Int) -> CGFloat {
        return 10
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, insetForSectionAt section: Int) -> UIEdgeInsets {
        let padding: CGFloat = Utils.isIpad() ? 56 : 16
        return UIEdgeInsets(top: 0, left: padding, bottom: 0, right: padding)
    }
}
