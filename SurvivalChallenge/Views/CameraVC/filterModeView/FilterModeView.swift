//
//  FilterModeView.swift
//  EyeTrendFilter

import UIKit
import SDWebImage

protocol FilterModeDelegate: AnyObject {
    func selectedFocusItem()
    func getSelectedFocusItem(filter: FilterType, designType: DesignType?, challenge: SurvivalChallengeEntity?)
}

class FilterModeView: UIView {
    private var collectionView: UICollectionView!
    private var currentFocusedIndexPath: IndexPath?
    private var isFirstScroll: Bool = false
    
    weak var delegate: FilterModeDelegate?
    
    var challenges: [SurvivalChallengeEntity] = [] {
        didSet {
            collectionView.reloadData()
        }
    }
    
    deinit {
        print("⚙️ deinit \(Self.self)")
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupView()
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
    }
    
    private func setupView() {
        let layout = CenterZoomFlowLayout()
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.backgroundColor = .clear
        collectionView.decelerationRate = .fast
        collectionView.showsHorizontalScrollIndicator = false
        
        collectionView.register(UINib(nibName: "FilterCollectionViewCell", bundle: nil), forCellWithReuseIdentifier: "filterCell")
        collectionView.delegate = self
        collectionView.dataSource = self
        
        addSubview(collectionView)
        
        NSLayoutConstraint.activate([
            collectionView.leadingAnchor.constraint(equalTo: leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: trailingAnchor),
            collectionView.topAnchor.constraint(equalTo: topAnchor),
            collectionView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func firstScroll() {
        self.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        
        let inset = (self.frame.width - 52) / 2
        collectionView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        collectionView.contentOffset = .zero
        collectionView.reloadData()
        
        DispatchQueue.main.async {
            self.collectionView.layoutIfNeeded()
            
            if !self.challenges.isEmpty {
                let indexPath = IndexPath(item: 0, section: 0)
                self.collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: false)
                self.scrollViewDidScroll(self.collectionView)
                self.isFirstScroll = true
                print("yolo First scroll to index 0, challenge: \(self.challenges[0].name)")
            } else {
                print("yolo Challenges are empty, skipping scroll")
            }
        }
    }
}

// MARK: - Collection View
extension FilterModeView: UICollectionViewDelegate, UICollectionViewDataSource {
        
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        print("yolo: \(challenges.count)")
        return challenges.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "filterCell", for: indexPath) as! FilterCollectionViewCell
        
        let challenge = challenges[indexPath.row]
        
        cell.configure(with: challenge)
        
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        print("yolo: Selected indexPath: \(indexPath), Current focused: \(String(describing: currentFocusedIndexPath))")
        let challenge = challenges[indexPath.row]
        let filterType: FilterType
        let designType: DesignType?
                
        switch challenge.category.lowercased() {
        case "ranking":
            filterType = .ranking
            designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
        case "guess":
            filterType = .guess
            designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
        case "coloring":
            filterType = .coloring
            designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
        default:
            filterType = .none
            designType = nil
        }
        
        let center = self.convert(collectionView.center, to: collectionView)
           if let focusedIndexPath = collectionView.indexPathForItem(at: center),
              focusedIndexPath == indexPath {
               // This is the focused item - trigger selectedFocusItem
               self.delegate?.selectedFocusItem()
           } else {
               // Not the focused item - trigger getSelectedFocusItem
               self.delegate?.getSelectedFocusItem(filter: filterType, designType: designType, challenge: challenge)
           }
    }

    func scrollViewDidScroll(_ scrollView: UIScrollView) {
        let centerX = collectionView.bounds.size.width / 2 + scrollView.contentOffset.x
                
        var focusedIndexPath: IndexPath?

        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let cameraCell = cell as? FilterCollectionViewCell else { continue }

            let attributes = collectionView.layoutAttributesForItem(at: indexPath)!
            let distance = abs(attributes.center.x - centerX)
            
            // Scale logic
            let maxScale: CGFloat = 1.2
            let minScale: CGFloat = 1.0
            let scale = max(minScale, maxScale - (distance / collectionView.bounds.width))
            cameraCell.transform = CGAffineTransform(scaleX: scale, y: scale)
            
            if distance < 10 {
                focusedIndexPath = indexPath
            }
        }
        
        currentFocusedIndexPath = focusedIndexPath
        
        for cell in collectionView.visibleCells {
            guard let indexPath = collectionView.indexPath(for: cell),
                  let cameraCell = cell as? FilterCollectionViewCell else { continue }

            cameraCell.layer.cornerRadius = 52 / 2
            let isFocused = indexPath == focusedIndexPath

            if isFirstScroll {
                UIView.animate(withDuration: 0.2) {
                    cameraCell.layer.borderWidth = isFocused ? 0 : 1
                    cameraCell.layer.borderColor = isFocused ? UIColor.clear.cgColor : UIColor.white.cgColor
                }
            } else {
                cameraCell.layer.borderWidth = isFocused ? 0 : 1
                cameraCell.layer.borderColor = isFocused ? UIColor.clear.cgColor : UIColor.white.cgColor
            }
        }
    }
    
    func scrollViewDidEndDecelerating(_ scrollView: UIScrollView) {
        centerCurrentItem()
    }

    func scrollViewDidEndDragging(_ scrollView: UIScrollView, willDecelerate decelerate: Bool) {
        if !decelerate {
            centerCurrentItem()
        }
    }

    private func centerCurrentItem() {
        let center = self.convert(collectionView.center, to: collectionView)
        if let indexPath = collectionView.indexPathForItem(at: center) {
            let challenge = challenges[indexPath.row]
            let filterType: FilterType
            let designType: DesignType?
                    
            switch challenge.category.lowercased() {
            case "ranking":
                filterType = .ranking
                designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
            case "guess":
                filterType = .guess
                designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
            case "coloring":
                filterType = .coloring
                designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
            default:
                filterType = .none
                designType = nil
            }
            
            self.delegate?.getSelectedFocusItem(filter: filterType, designType: designType, challenge: challenge)
        }
    }
}

extension FilterModeView {
    func scrollToItem(at index: Int) {
        guard index < challenges.count else {
            print("yolo Invalid index \(index) for challenges count \(challenges.count)")
            return
        }
        let indexPath = IndexPath(item: index, section: 0)
        
        // Reset state
        currentFocusedIndexPath = nil
        isFirstScroll = false
        collectionView.contentOffset = .zero
        
        // Ensure layout is updated
        self.layoutIfNeeded()
        collectionView.layoutIfNeeded()
        
        // Set content inset
        let itemWidth: CGFloat = 52
        let inset = (self.frame.width - itemWidth) / 2
        collectionView.contentInset = UIEdgeInsets(top: 0, left: inset, bottom: 0, right: inset)
        
        print("yolo Scrolling to index \(index), challenge: \(challenges[index].name)")
        
        // Scroll to item
        collectionView.scrollToItem(at: indexPath, at: .centeredHorizontally, animated: true)
        
        // Update UI and notify delegate
        DispatchQueue.main.async {
            self.scrollViewDidScroll(self.collectionView)
            
            // Log visible item after scroll
            let center = self.convert(self.collectionView.center, to: self.collectionView)
            if let visibleIndexPath = self.collectionView.indexPathForItem(at: center) {
                print("yolo Visible item after scroll: index \(visibleIndexPath.item), challenge: \(self.challenges[visibleIndexPath.item].name)")
            }
            
            let challenge = self.challenges[index]
            let filterType: FilterType
            let designType: DesignType?
            switch challenge.category.lowercased() {
            case "ranking":
                filterType = .ranking
                designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
            case "guess":
                filterType = .guess
                designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
            case "coloring":
                filterType = .coloring
                designType = HomeViewModel.shared.getDesignType(for: challenge.category, name: challenge.name)
            default:
                filterType = .none
                designType = nil
            }
            print("yolo Notifying delegate for challenge: \(challenge.name), filter: \(filterType)")
            self.delegate?.getSelectedFocusItem(filter: filterType, designType: designType, challenge: challenge)
        }
    }
}
