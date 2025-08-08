//
//  LaunchScreenView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI

struct LaunchScreenView: View {
    @State private var isAnimating = false
    @State private var scanLineOffset: CGFloat = -200
    
    var body: some View {
        ZStack {
            // Gradient background matching app icon
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(red: 0.2, green: 0.4, blue: 0.9),
                    Color(red: 0.4, green: 0.6, blue: 1.0)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Animated logo
                ZStack {
                    // Receipt background
                    RoundedRectangle(cornerRadius: 20)
                        .fill(Color.white)
                        .frame(width: 140, height: 180)
                        .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        .scaleEffect(isAnimating ? 1.0 : 0.8)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    
                    VStack(spacing: 15) {
                        // Camera icon
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
                                .frame(width: 60, height: 60)
                            
                            Image(systemName: "camera.fill")
                                .font(.system(size: 28))
                                .foregroundColor(.white)
                        }
                        .scaleEffect(isAnimating ? 1.0 : 0.5)
                        
                        // Receipt lines
                        VStack(spacing: 8) {
                            ForEach(0..<3) { index in
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(Color.gray.opacity(0.3))
                                    .frame(width: 80 - CGFloat(index * 10), height: 4)
                                    .opacity(isAnimating ? 1.0 : 0.0)
                                    .animation(
                                        .easeInOut(duration: 0.5)
                                        .delay(Double(index) * 0.1 + 0.5),
                                        value: isAnimating
                                    )
                            }
                        }
                    }
                }
                
                // App name
                VStack(spacing: 8) {
                    Text("Receipt Tracker")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                        .opacity(isAnimating ? 1.0 : 0.0)
                    
                    Text("Scan • Organize • Submit")
                        .font(.system(size: 16, weight: .medium, design: .rounded))
                        .foregroundColor(.white.opacity(0.8))
                        .opacity(isAnimating ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5).delay(0.8), value: isAnimating)
                }
                
                // Scanning animation
                ZStack {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.white.opacity(0.3), lineWidth: 2)
                        .frame(width: 200, height: 60)
                    
                    // Scan line
                    Rectangle()
                        .fill(LinearGradient(
                            gradient: Gradient(colors: [
                                Color.green.opacity(0),
                                Color.green.opacity(0.8),
                                Color.green.opacity(0)
                            ]),
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(width: 180, height: 2)
                        .offset(y: scanLineOffset)
                        .onAppear {
                            withAnimation(
                                .linear(duration: 2)
                                .repeatForever(autoreverses: true)
                            ) {
                                scanLineOffset = 30
                            }
                        }
                }
                .opacity(isAnimating ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.5).delay(1.0), value: isAnimating)
            }
        }
        .onAppear {
            withAnimation(.easeOut(duration: 0.8)) {
                isAnimating = true
            }
        }
    }
}

// Alternative splash screen with different animation
struct SplashScreenView: View {
    @State private var rotationAngle: Double = 0
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        ZStack {
            Color(red: 0.1, green: 0.2, blue: 0.5)
                .ignoresSafeArea()
            
            VStack(spacing: 40) {
                // Animated receipt icon
                ZStack {
                    // Multiple receipt layers for depth
                    ForEach(0..<3) { index in
                        RoundedRectangle(cornerRadius: 15)
                            .fill(Color.white.opacity(0.9 - Double(index) * 0.2))
                            .frame(width: 100, height: 130)
                            .rotationEffect(.degrees(Double(index) * 5))
                            .offset(x: CGFloat(index) * 5, y: CGFloat(index) * 5)
                    }
                    
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                        .offset(y: 30)
                }
                .scaleEffect(scale)
                .rotationEffect(.degrees(rotationAngle))
                .opacity(opacity)
                
                Text("Receipt Tracker")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .foregroundColor(.white)
                    .opacity(opacity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.8, dampingFraction: 0.6)) {
                scale = 1.0
                opacity = 1.0
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                rotationAngle = 360
            }
        }
    }
}

struct LaunchScreenView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LaunchScreenView()
                .previewDisplayName("Main Launch Screen")
            
            SplashScreenView()
                .previewDisplayName("Alternative Splash")
        }
    }
}