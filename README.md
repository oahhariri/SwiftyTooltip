# SwiftyTooltip

**SwiftyTooltip** is a lightweight, 100% SwiftUI-native library for displaying animated, safe-area-aware tooltips in your iOS apps. It intelligently positions each tooltip exactly where it should appear and fully supports both **Left-to-Right (LTR)** and **Right-to-Left (RTL)** layout directions.

---

## 🛠 Requirements

- iOS 15+  
- Xcode 16.0+  
- SwiftUI  

---

## ✨ Features

- ✅ Built entirely with SwiftUI  
- ✅ Works with any SwiftUI view  
- ✅ Auto-positions tooltips based on available space  
- ✅ RTL & LTR layout direction support  
- ✅ Safe area protection  
- ✅ Smooth built-in animations  
- ✅ Simple and lightweight API  

---

## 📦 Installation

### Swift Package Manager

In Xcode:

1. Go to `File` > `Add Packages`  
2. Enter the package URL:

   ```
   https://github.com/oahhariri/SwiftyTooltip
   ```

3. Choose the latest version and add it to your target.

---

## 📌 Before You Start: Define Tooltip Context and Items

Before using SwiftyTooltip in your views, you need to define a **Tooltip Context** and **Tooltip Items**.

---

### 🧭 Define a Tooltip Context

Each context helps group tooltips based on the current screen or flow. This ensures tooltips don’t overlap or conflict.

```swift
enum MainTooltipContext: String, TooltipContextType {
    var id: String { rawValue }

    case homeView
    case settings
    case onboarding
}
```

---

### 🏗 Define Tooltip Items

You should create a new `TooltipItemConfigType` enum for each screen that shows tooltips. Ideally, each tooltip context should have a matching tooltip item configuration.

Tooltip items define how each tooltip looks and behaves — like its position, style, and spacing.

```swift
enum HomeToolTips: TooltipItemConfigType {
    case firstLabel
    case secondLabel

    var id: String { rawValue }

    var side: TooltipSide {
        switch self {
        case .firstLabel: return .top
        case .secondLabel: return .bottom
        }
    }

    var spacing: CGFloat { 8 }

    var backgroundColor: Color { .black.opacity(0.9) }

    var arrowWidth: CGFloat { 12 }

    var spotlightCutInteractive: Bool { true }

    var spotlightCutPadding: CGFloat { 4 }

    var spotlightCutCornerRadius: CornerRadius { .rounded(8) }

    private var rawValue: String {
        switch self {
        case .firstLabel: return "firstLabel"
        case .secondLabel: return "secondLabel"
        }
    }
}
```

---

## 🚀 Usage

### 🧱 Step 1: Add `.tooltipContainer()` to the Root View of Your App

This sets up the tooltip environment and must be placed at the root of your SwiftUI view hierarchy.

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .tooltipContainer()
        }
    }
}
```

---

### 🎯 Step 2: Add a Tooltip Target to a View

Use `.tooltipTarget` to mark the view that the tooltip should point to. This tells SwiftyTooltip where to anchor the tooltip on screen.

```swift
.tooltipTarget(
    context: MainTooltipContext.homeView,
    HomeToolTips.firstLabel.id
)
```

For improved readability and cleaner usage, you can also create a custom view extension:

```swift
extension View {
    @ViewBuilder
    func tooltipTarget(context: MainTooltipContext, _ item: HomeToolTips) -> some View {
        self.tooltipTarget(context: context, item.id)
    }
}
```

And then use it like this:

```swift
.tooltipTarget(context: .homeView, .firstLabel)
```

This helps keep your view code simple and expressive.

---
