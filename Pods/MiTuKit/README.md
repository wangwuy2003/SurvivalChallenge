# MiTuKit
[![Version](https://img.shields.io/cocoapods/v/MiTuKit.svg?style=flat)](https://cocoapods.org/pods/MiTuKit)
[![License](https://img.shields.io/cocoapods/l/MiTuKit.svg?style=flat)](https://cocoapods.org/pods/MiTuKit)
[![Platform](https://img.shields.io/cocoapods/p/MiTuKit.svg?style=flat)](https://cocoapods.org/pods/MiTuKit)

## About
    HI,
    MiTuKit is a lightweight and powerful Swift library designed to accelerate development with UIKit.
    It provides a collection of essential classes and extensions, simplifying coding by leveraging inheritance and reusable components.
    With MiTuKit, developers can write cleaner and more efficient code, enhancing productivity in iOS projects.
    This CocoaPods library is software development kit for iOS, the project depends on 'SnapKit', '~> 5.7.0' 


## Installation with CocoaPods
To integrate MiTuKit into your Xcode project using CocoaPods, specify it in your `Podfile`:

```ruby
target 'MyApp' do
  pod 'MiTuKit'
end
```

## Swift Package Manager

The [Swift Package Manager](https://swift.org/package-manager/) is a tool for automating the distribution of Swift code and is integrated into the `swift` compiler. It is in early development, but MiTuKit does support its use on supported platforms.

Once you have your Swift package set up, adding MiTuKit as a dependency is as easy as adding it to the `dependencies` value of your `Package.swift`.

```swift
dependencies: [
    .package(url: "https://github.com/hominhtuong/MiTuKit.git", .upToNextMajor(from: "1.0.1"))
]
```

## Example code:
The code would look like this:

```swift
import MiTuKit

//Add button to view
let helloButton = UIButton()
helloButton >>> view >>> {  //Add button to view then return this button in block
    $0.snp.makeConstraints {
        $0.top.equalTo(topSafe).offset(16)
        $0.centerX.equalToSuperview()
        $0.height.equalTo(39)
        $0.width.equalTo(343)
    }
    $0.setTitle("Hello", for: .normal)
    $0.setTitleColor(.link, for: .normal)
    $0.font = .bold(18)
    $0.setImage(UIImage(named: "imageName"), for: .normal)
    $0.handle {
        print("button tapped!")
    }
}
```

TextField with custom style:

```swift
import MiTuKit

let userNameTextField = TTextField()
userNameTextField >>> view >>> {
    $0.snp.makeConstraints {
        $0.top.equalTo(helloButton.snp.bottom).offset(32)
        $0.leading.equalToSuperview().offset(16)
        $0.trailing.equalToSuperview().offset(-16)
        $0.height.equalTo(50)
    }
    $0.placeholder = "Enter Username"
    $0.eventHandle(for: .editingDidBegin) {
        self.userNameTextField.text = ""
    }       
    $0.editingChangedHandle {
        let text = userNameTextField.text ?? ""
        print(text)
    }
    $0.editingDidEndHandle {
        guard let username = userNameTextField.text else {return}
        print("username: \(username)")
    }
}

```

CollectionView and TableView like this:

```swift
import MiTuKit

//MARK: - Add to view 
collectionView >>> view >>> {
    $0.snp.makeConstraints {
        $0.edges.equalToSuperview()
    }
    $0.backgroundColor = .from("0268FF")
    $0.registerReusedCell(AnyCollectionViewCell.self)
    $0.delegate = self
    $0.dataSource = self
}

//MARK: - In Cell
func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
    let cell = collectionView.dequeueReusable(cellClass: AnyCollectionViewCell.self, indexPath: indexPath)
    let item = items[indexPath.item]
    cell.configs(item)
    
    return cell
}

```

## License

  MiTuKit is released under the MIT license. [See LICENSE](https://github.com/hominhtuong/MiTuKit/blob/main/LICENSE) for details.  
<br>
My website: [Visit](https://mituultra.com/)
