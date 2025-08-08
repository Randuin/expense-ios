//
//  AppIconExporter.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI

struct AppIconExporter: View {
    @State private var selectedDesign = 0
    @State private var showExportInstructions = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 30) {
                // Icon preview at 1024x1024
                Group {
                    if selectedDesign == 0 {
                        AppIconView(size: 300)
                            .cornerRadius(67.2) // iOS 18 corner radius ratio
                            .shadow(radius: 10)
                    } else {
                        AppIconMinimalView(size: 300)
                            .cornerRadius(67.2)
                            .shadow(radius: 10)
                    }
                }
                .frame(width: 300, height: 300)
                
                // Design selector
                Picker("Design", selection: $selectedDesign) {
                    Text("Main Design").tag(0)
                    Text("Minimal Design").tag(1)
                }
                .pickerStyle(SegmentedPickerStyle())
                .padding(.horizontal, 40)
                
                // Full size for export
                VStack(spacing: 10) {
                    Text("Export Size: 1024x1024")
                        .font(.headline)
                    
                    Text("Take a screenshot of the icon below")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    ZStack {
                        // Checkerboard background to show transparency
                        CheckerboardPattern()
                            .frame(width: 1024, height: 1024)
                        
                        if selectedDesign == 0 {
                            AppIconView(size: 1024)
                        } else {
                            AppIconMinimalView(size: 1024)
                        }
                    }
                    .frame(width: 1024, height: 1024)
                    .background(Color.white)
                    .overlay(
                        Rectangle()
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
                }
                
                Button("Show Export Instructions") {
                    showExportInstructions = true
                }
                .buttonStyle(.borderedProminent)
                
                Spacer()
            }
            .padding()
            .navigationTitle("App Icon Exporter")
            .sheet(isPresented: $showExportInstructions) {
                ExportInstructionsView()
            }
        }
    }
}

struct ExportInstructionsView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    Text("How to Export and Set App Icon")
                        .font(.title2)
                        .fontWeight(.bold)
                    
                    VStack(alignment: .leading, spacing: 15) {
                        InstructionStep(
                            number: "1",
                            title: "Take Screenshot",
                            description: "In the Simulator or on device, take a screenshot of the 1024x1024 icon (Cmd+S in Simulator)"
                        )
                        
                        InstructionStep(
                            number: "2",
                            title: "Save as PNG",
                            description: "Save the screenshot as 'AppIcon.png' in your Downloads folder"
                        )
                        
                        InstructionStep(
                            number: "3",
                            title: "Open Xcode",
                            description: "Open your project in Xcode and navigate to Assets.xcassets"
                        )
                        
                        InstructionStep(
                            number: "4",
                            title: "Select AppIcon",
                            description: "Click on 'AppIcon' in the asset catalog"
                        )
                        
                        InstructionStep(
                            number: "5",
                            title: "Drag and Drop",
                            description: "Drag your AppIcon.png file to the 1024x1024 slot (iOS App Store)"
                        )
                        
                        InstructionStep(
                            number: "6",
                            title: "Automatic Generation",
                            description: "Xcode will automatically generate all required sizes from your 1024x1024 image"
                        )
                    }
                    
                    Divider()
                    
                    Text("Alternative Method: Command Line")
                        .font(.headline)
                    
                    Text("You can also use ImageMagick to generate all sizes:")
                        .font(.subheadline)
                    
                    Text("""
                    brew install imagemagick
                    
                    # Generate all iOS icon sizes
                    convert AppIcon.png -resize 20x20 Icon-20.png
                    convert AppIcon.png -resize 40x40 Icon-40.png
                    convert AppIcon.png -resize 60x60 Icon-60.png
                    convert AppIcon.png -resize 58x58 Icon-58.png
                    convert AppIcon.png -resize 87x87 Icon-87.png
                    convert AppIcon.png -resize 80x80 Icon-80.png
                    convert AppIcon.png -resize 120x120 Icon-120.png
                    convert AppIcon.png -resize 180x180 Icon-180.png
                    """)
                    .font(.system(.caption, design: .monospaced))
                    .padding()
                    .background(Color.gray.opacity(0.1))
                    .cornerRadius(8)
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
            .navigationTitle("Export Instructions")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

struct InstructionStep: View {
    let number: String
    let title: String
    let description: String
    
    var body: some View {
        HStack(alignment: .top, spacing: 15) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 30, height: 30)
                
                Text(number)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(.white)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.headline)
                
                Text(description)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

struct CheckerboardPattern: View {
    var body: some View {
        GeometryReader { geometry in
            Path { path in
                let squareSize: CGFloat = 20
                let rows = Int(geometry.size.height / squareSize)
                let columns = Int(geometry.size.width / squareSize)
                
                for row in 0..<rows {
                    for column in 0..<columns {
                        if (row + column) % 2 == 0 {
                            let rect = CGRect(
                                x: CGFloat(column) * squareSize,
                                y: CGFloat(row) * squareSize,
                                width: squareSize,
                                height: squareSize
                            )
                            path.addRect(rect)
                        }
                    }
                }
            }
            .fill(Color.gray.opacity(0.1))
        }
    }
}

// Preview wrapper to show in app
struct AppIconConfigView: View {
    var body: some View {
        VStack(spacing: 20) {
            Text("App Icon Configuration")
                .font(.largeTitle)
                .fontWeight(.bold)
            
            Text("Your app icon is ready to export!")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack(spacing: 40) {
                VStack {
                    AppIconView(size: 180)
                        .cornerRadius(40)
                        .shadow(radius: 5)
                    Text("Main Design")
                        .font(.caption)
                }
                
                VStack {
                    AppIconMinimalView(size: 180)
                        .cornerRadius(40)
                        .shadow(radius: 5)
                    Text("Minimal Design")
                        .font(.caption)
                }
            }
            
            Text("To set as app icon:")
                .font(.headline)
                .padding(.top)
            
            VStack(alignment: .leading, spacing: 10) {
                Label("Run the app", systemImage: "1.circle.fill")
                Label("Navigate to Icon Exporter in app", systemImage: "2.circle.fill")
                Label("Take screenshot of 1024x1024 icon", systemImage: "3.circle.fill")
                Label("Add to Xcode's Assets.xcassets", systemImage: "4.circle.fill")
            }
            .font(.subheadline)
            
            Spacer()
        }
        .padding()
    }
}

struct AppIconExporter_Previews: PreviewProvider {
    static var previews: some View {
        AppIconExporter()
    }
}