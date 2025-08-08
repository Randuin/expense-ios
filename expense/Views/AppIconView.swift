//
//  AppIconView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI

struct AppIconView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),  // Deep blue
                    Color(red: 0.4, green: 0.6, blue: 1.0)   // Lighter blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Main receipt icon with modern design
            ZStack {
                // Background receipt shape with shadow
                RoundedRectangle(cornerRadius: size * 0.08)
                    .fill(Color.white)
                    .frame(width: size * 0.55, height: size * 0.7)
                    .shadow(color: .black.opacity(0.2), radius: size * 0.03, x: 0, y: size * 0.02)
                
                // Receipt content
                VStack(spacing: size * 0.02) {
                    // Camera lens at top
                    ZStack {
                        Circle()
                            .fill(LinearGradient(
                                gradient: Gradient(colors: [
                                    Color(red: 0.3, green: 0.5, blue: 0.95),
                                    Color(red: 0.5, green: 0.7, blue: 1.0)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ))
                            .frame(width: size * 0.22, height: size * 0.22)
                        
                        Circle()
                            .fill(Color.white.opacity(0.9))
                            .frame(width: size * 0.18, height: size * 0.18)
                        
                        // Camera aperture design
                        ForEach(0..<6) { index in
                            Rectangle()
                                .fill(Color(red: 0.3, green: 0.5, blue: 0.95))
                                .frame(width: size * 0.02, height: size * 0.08)
                                .offset(y: -size * 0.055)
                                .rotationEffect(Angle(degrees: Double(index) * 60))
                        }
                        
                        Circle()
                            .fill(Color(red: 0.2, green: 0.4, blue: 0.9))
                            .frame(width: size * 0.06, height: size * 0.06)
                    }
                    .offset(y: -size * 0.05)
                    
                    // Receipt lines
                    VStack(spacing: size * 0.025) {
                        ForEach(0..<4) { index in
                            RoundedRectangle(cornerRadius: size * 0.01)
                                .fill(Color.gray.opacity(index == 0 ? 0.6 : 0.3))
                                .frame(
                                    width: size * (index == 0 ? 0.35 : 0.42),
                                    height: size * (index == 0 ? 0.025 : 0.02)
                                )
                        }
                    }
                    .offset(y: -size * 0.02)
                    
                    // Dollar sign badge
                    ZStack {
                        Circle()
                            .fill(Color.green)
                            .frame(width: size * 0.12, height: size * 0.12)
                        
                        Text("$")
                            .font(.system(size: size * 0.08, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                    }
                    .offset(y: size * 0.02)
                    
                    // Checkmark at bottom
                    ZStack {
                        RoundedRectangle(cornerRadius: size * 0.02)
                            .fill(Color(red: 0.3, green: 0.5, blue: 0.95).opacity(0.15))
                            .frame(width: size * 0.42, height: size * 0.08)
                        
                        HStack(spacing: size * 0.02) {
                            Image(systemName: "checkmark.circle.fill")
                                .font(.system(size: size * 0.05))
                                .foregroundColor(.green)
                            
                            Text("TRACKED")
                                .font(.system(size: size * 0.04, weight: .semibold, design: .rounded))
                                .foregroundColor(Color(red: 0.3, green: 0.5, blue: 0.95))
                        }
                    }
                    .offset(y: size * 0.05)
                }
            }
        }
        .frame(width: size, height: size)
    }
}

// Alternative minimalist design
struct AppIconMinimalView: View {
    let size: CGFloat
    
    init(size: CGFloat = 1024) {
        self.size = size
    }
    
    var body: some View {
        ZStack {
            // Gradient background
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.1, green: 0.2, blue: 0.5),  // Dark blue
                    Color(red: 0.2, green: 0.5, blue: 0.8)   // Bright blue
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Simple receipt with camera
            ZStack {
                // Receipt shape
                RoundedRectangle(cornerRadius: size * 0.1)
                    .fill(Color.white)
                    .frame(width: size * 0.6, height: size * 0.75)
                    .overlay(
                        RoundedRectangle(cornerRadius: size * 0.1)
                            .strokeBorder(Color.white.opacity(0.5), lineWidth: size * 0.01)
                    )
                
                VStack(spacing: size * 0.05) {
                    // Camera icon
                    Image(systemName: "camera.fill")
                        .font(.system(size: size * 0.25))
                        .foregroundColor(Color(red: 0.2, green: 0.5, blue: 0.8))
                    
                    // Receipt indicator lines
                    VStack(spacing: size * 0.02) {
                        ForEach(0..<3) { _ in
                            Rectangle()
                                .fill(Color.gray.opacity(0.3))
                                .frame(width: size * 0.4, height: size * 0.015)
                                .cornerRadius(size * 0.01)
                        }
                    }
                }
            }
            
            // Scan line effect
            Rectangle()
                .fill(LinearGradient(
                    gradient: Gradient(colors: [
                        Color.green.opacity(0),
                        Color.green.opacity(0.6),
                        Color.green.opacity(0)
                    ]),
                    startPoint: .leading,
                    endPoint: .trailing
                ))
                .frame(width: size * 0.7, height: size * 0.01)
                .offset(y: size * 0.1)
        }
        .frame(width: size, height: size)
    }
}

// Preview for both designs
struct AppIconView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 20) {
            HStack(spacing: 20) {
                // Main design
                AppIconView(size: 256)
                    .cornerRadius(57.6) // iOS app icon corner radius
                    .shadow(radius: 10)
                
                // Minimal design
                AppIconMinimalView(size: 256)
                    .cornerRadius(57.6)
                    .shadow(radius: 10)
            }
            
            Text("Main Design | Minimal Design")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .previewLayout(.sizeThatFits)
    }
}

// Helper view to export icon at different sizes
struct IconExporter: View {
    var body: some View {
        VStack(spacing: 30) {
            Text("App Icon Sizes")
                .font(.title)
                .fontWeight(.bold)
            
            HStack(spacing: 20) {
                VStack {
                    AppIconView(size: 180)
                        .cornerRadius(40)
                    Text("180x180")
                        .font(.caption)
                }
                
                VStack {
                    AppIconView(size: 120)
                        .cornerRadius(27)
                    Text("120x120")
                        .font(.caption)
                }
                
                VStack {
                    AppIconView(size: 60)
                        .cornerRadius(13.5)
                    Text("60x60")
                        .font(.caption)
                }
            }
            
            Text("To export: Take screenshots of each size")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}