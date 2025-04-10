# SwiftyTooltip

**SwiftyTooltip** is a lightweight, 100% SwiftUI-native library that makes it easy to display beautiful, animated, and safe-area-aware tooltips in your iOS apps. It handles smart positioning, adapts to screen space, and fully supports both **Left-to-Right (LTR)** and **Right-to-Left (RTL)** layouts.

---

## 🛠 Requirements

- iOS 15+  
- Xcode 16.0+  
- SwiftUI  

---

## ✨ Features

- ✅ Built entirely with SwiftUI  
- ✅ Works with any SwiftUI view  
- ✅ Auto-positions tooltips
- ✅ RTL & LTR layout direction support  
- ✅ Avoids safe area overlaps  
- ✅ Smooth built-in animations  
- ✅ Clean, simple API — easy to integrate  

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

Before you can show a tooltip, you need to define two things:
1. **A tooltip context** — to group tooltips by screen or section.
2. **Tooltip items** — to describe how each tooltip should behave and look.

---

### 🧭 Define a Tooltip Context

`TooltipContextType` tells SwiftyTooltip *where* tooltips belong (which screen or flow), and helps prevent overlapping or conflicting tooltips.

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

`TooltipItemConfigType` defines the *style and layout* of each tooltip.  
You should create a new enum for each screen or view that displays tooltips.

This is where you specify how the tooltip should appear — including direction, spacing, background, etc.

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

You must attach `.tooltipContainer()` to your root view — usually inside the main `App` entry point.  
This sets up the tooltip system for the entire app.

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

### 🎯 Step 2: Mark the View You Want the Tooltip to Point To

SwiftyTooltip needs to know **which view** on the screen the tooltip should be attached to — this is called the **tooltip target**.

To do this, apply the `.tooltipTarget` modifier directly to the view you want the tooltip to anchor to (for example, a button, label, or icon).

```swift
.tooltipTarget(
    context: MainTooltipContext.homeView,
    HomeToolTips.firstLabel.id
)
```

This tells the system:  
> “When showing a tooltip for `firstLabel`, place it relative to this view.”

---

✅ **Optional: Make it cleaner with a helper extension**

To simplify usage and improve readability, you can add a small extension to `View`:

```swift
extension View {
    @ViewBuilder
    func tooltipTarget(context: MainTooltipContext, _ item: HomeToolTips) -> some View {
        self.tooltipTarget(context: context, item.id)
    }
}
```

Now your code looks like this:

```swift
.tooltipTarget(context: .homeView, .firstLabel)
```

Much cleaner and easier to read, especially with multiple tooltips.

---

### ✨ Step 3: Show the Tooltip

Now you're ready to show a tooltip!  
Just call `.tooltip()` on your main container view. SwiftyTooltip handles the rest — it figures out where and how to display the tooltip.

```swift
@State var tooltipItem: HomeToolTips? = .firstLabel

.tooltip(
    context: MainTooltipContext.homeView,
    item: $tooltipItem,
    backgroundColor: Color.gray.opacity(0.5),
    content: { toolTipView($0) }
)
```

This binds the current tooltip item to the view, and shows a custom tooltip whenever the state matches a target.

---

### 🧱 Example Tooltip Content

Here’s a simple example of how to show different tooltip content based on the active tooltip item:

```swift
@ViewBuilder
func toolTipView(_ item: HomeToolTips) -> some View {
    switch item {
    case .firstLabel:
        VStack {
            Text("This is the first tooltip")
        }
        .frame(width: 180, height: 100)

    case .secondLabel:
        VStack {
            Text("Need help?")
            Button("Got it") {
                // Handle dismiss here
            }
        }
        .frame(width: 200, height: 120)
    }
}
```

You can customize this view to include anything — images, icons, links, buttons, or entire layouts — all inside SwiftUI.
