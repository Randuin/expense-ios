# App Icon Setup Instructions

## Quick Setup

The app icon has been designed and is ready to be exported. Follow these steps:

### Method 1: Using the In-App Exporter (Recommended)
1. Run the app in Simulator or on device
2. Go to the History tab
3. Tap the menu (···) button in the top right
4. Select "App Icon"
5. Take a screenshot of the 1024x1024 icon
6. Save it as `AppIcon-1024.png`
7. Add it to this folder in Xcode

### Method 2: Using SwiftUI Preview
1. Open `expense/Views/AppIconView.swift` in Xcode
2. In the Canvas preview, click on the 1024x1024 icon
3. Right-click and select "Export Preview"
4. Save as `AppIcon-1024.png`
5. Drag it into this folder in Xcode

### Method 3: Manual Screenshot
1. Add this temporary code to `ContentView.swift`:
```swift
AppIconView(size: 1024)
    .frame(width: 1024, height: 1024)
```
2. Run the app
3. Take a screenshot (Cmd+S in Simulator)
4. Crop to 1024x1024
5. Save as `AppIcon-1024.png` in this folder

## File Naming
When you add the icon, name it: `AppIcon-1024.png`

## Xcode Configuration
The `Contents.json` file is already configured to look for `AppIcon-1024.png`. Once you add this file, Xcode will automatically generate all required icon sizes.

## Icon Design Details
- **Main Design**: Receipt with camera lens, blue gradient background
- **Colors**: Blue gradient (#3366E6 to #6699FF)
- **Elements**: Camera lens, receipt lines, dollar sign, checkmark
- **Style**: Modern, clean, professional

## Alternative Designs
Two designs are available:
1. **Main Design** (default): Feature-rich with camera and receipt elements
2. **Minimal Design**: Simplified version with camera icon

Choose the design that best fits your brand in the AppIconExporter view.