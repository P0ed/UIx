# UIx

[![Swift](https://img.shields.io/badge/Swift-6.1+-orange.svg)](https://swift.org)
[![iOS](https://img.shields.io/badge/iOS-14.0+-blue.svg)](https://developer.apple.com/ios/)
[![License](https://img.shields.io/badge/License-MIT-green.svg)](LICENSE)

A Swift library that brings functional reactive programming and declarative UI patterns to UIKit development. UIx builds on top of [Fx](https://github.com/P0ed/Fx) to provide reactive UIKit components, layout utilities, and async action management.

## Overview

UIx extends UIKit with functional programming concepts and reactive patterns, making iOS development more declarative and maintainable. It provides:

- **Reactive UI Components**: UIKit views that automatically update based on data changes
- **Declarative Layout System**: Simplified Auto Layout with functional composition
- **Async Action Management**: Type-safe async operations with loading states
- **View Styling System**: Composable view styling with functional patterns
- **Chain-based View Discovery**: Powerful view hierarchy traversal utilities

## Features

### Reactive UI Binding

Automatically bind UI components to reactive properties using the Fx library's `Property` and `Signal` types:

```swift
final class ViewController: UIViewController {
    @MutableProperty private var count = 0
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let label = UILabel()
        // Automatically updates when count changes
        label.bind(\.text, to: $count.map { "Count: \($0)" })
        
        let button = UIButton()
        button.setTitle("Increment", for: .normal)
        button.setButtonAction { [self] _ in count += 1 }
    }
}
```

### Declarative Layout System

Simplified Auto Layout with functional composition and reactive constraints:

```swift
// Pin subview with insets
containerView.pinSubview(childView, edges: .all, insets: .all(16))

// Reactive constraints
let dynamicHeight = MutableProperty<CGFloat>(100)
view.matchHeight(to: dynamicHeight.readonly) // Updates automatically

// Layout utilities
view.pinCenter(to: containerView)
view.matchSize(to: CGSize(width: 200, height: 100))
```

### Composable View Styling

Functional approach to view styling with composition:

```swift
extension ViewStyle where View: UIButton {

    static var primaryButton: ViewStyle {
        ∑[
            .color(.systemBlue),
            .roundCorners(8),
            .height(44),
            .tintColor(.white)
        ]
    }

    static var secondaryButton: ViewStyle {
        ∑[
            .border(width: 1, color: .systemBlue),
            .roundCorners(8),
            .height(44),
            .tintColor(.systemBlue)
        ]
    }
}

// Apply styles
button.applyStyle(.primaryButton)
let styledButton = UIButton().applyingStyle(.secondaryButton)
```

### Chain-based View Discovery

Powerful utilities for traversing view hierarchies:

```swift
// Find views by type
let stackView = view.findSubview(UIStackView.self)
let textField = responder.findResponder(UITextField.self)

// Find with custom patterns
let horizontalStack = view.findSubview(.stack(.horizontal))
let enabledButton = view.findSubview(.type(UIButton.self).and { $0.isEnabled })
```

### Specialized Layout Views

Purpose-built views for common layout scenarios:

```swift
// Reactive layout based on size changes
let layoutView = LayoutView { size in
    // Layout updates automatically when size changes
    configureLayout(for: size.value)
}

// Trait collection aware views
let traitsView = TraitsView { traits in
    // Returns different views based on traits
    traits.value.horizontalSizeClass == .compact ? compactView : regularView
}

// Safe area aware views
let safeAreaView = SafeAreaView()
safeAreaView.$insets.observe { insets in
    // React to safe area changes
}
```

## Installation

### Swift Package Manager

Add UIx to your project using Swift Package Manager. In Xcode:

1. Go to **File → Add Package Dependencies**
2. Enter the repository URL: `https://github.com/P0ed/UIx.git`
3. Choose the version or branch you want to use

Or add it to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/P0ed/UIx.git", branch: "main")
]
```

## Requirements

- **iOS 14.0+**
- **Swift 6.1+**
- **Xcode 16.0+**

## Dependencies

UIx depends on [Fx](https://github.com/P0ed/Fx), a functional programming library that provides:
- Reactive programming primitives (`Signal`, `Property`, `MutableProperty`)
- Functional utilities (`curry`, `compose`, `with`, `modify`)
- Async operations (`Promise`, `AsyncTask`)
- Resource management (`Disposable`, `CompositeDisposable`)

## Core Components

### Reactive Binding

UIx extends NSObject with reactive capabilities:

```swift
// Automatic cleanup with object lifetime
view.lifetime += someSignal.observe { value in
    // Handle value changes
}

// Property binding
view.bind(\.backgroundColor, to: colorProperty)
view.apply(textProperty) { view, text in
    view.attributedText = NSAttributedString(string: text)
}
```

### Layout Extensions

Comprehensive layout utilities built on Auto Layout:

```swift
// Edge constraints
let constraints = view.pin(to: containerView, edges: .all, insets: .all(16))
constraints.setInsets(.horizontal(20)) // Update insets dynamically

// Size constraints
view.matchSize(to: .square(100))
view.matchWidth(to: containerView, priority: .defaultHigh)
view.matchHeight(to: dynamicHeightProperty) // Reactive constraints
```

### Async Actions

Manage async operations with built-in state tracking:

```swift
// Simple async action
let saveAction = AsyncAction { data in
    try await repository.save(data)
}

// Cancellable actions
let searchAction = AsyncAction { query in
    AsyncTask { try await searchService.search(query) }
}

// Pagination support
let paginationAction = AsyncAction.pagination { page in
    let results = try await api.loadPage(page.page)
    return .isEmpty(results.isEmpty)
}
```

## Advanced Usage

### Custom View Styles

Create reusable, composable view styles:

```swift
extension ViewStyle where View: UIView {
    static func card(cornerRadius: CGFloat = 12) -> ViewStyle {
        ∑[
            .roundCorners(cornerRadius),
            .color(.systemBackground),
            .border(width: 1, color: .separator)
        ]
    }
    
    static func animated<T: Equatable>(
        _ keyPath: ReferenceWritableKeyPath<View, T>,
        duration: TimeInterval = 0.3
    ) -> (Property<T>) -> ViewStyle {
        { property in
            .animating(keyPath, in: duration, with: property)
        }
    }
}
```

## License

UIx is available under the MIT license. See the [LICENSE](LICENSE) file for more info.
