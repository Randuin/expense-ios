//
//  BatchReviewView.swift
//  expense
//
//  Created by Claude on 8/10/25.
//

import SwiftUI

struct BatchReviewView: View {
    let images: [UIImage]
    let onSave: () -> Void
    let onCancel: () -> Void
    
    @State private var selectedImageIndex = 0
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Main image display
                if !images.isEmpty {
                    TabView(selection: $selectedImageIndex) {
                        ForEach(0..<images.count, id: \.self) { index in
                            ZStack {
                                Image(uiImage: images[index])
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .background(Color.black)
                                
                                // Image counter overlay
                                VStack {
                                    HStack {
                                        Spacer()
                                        Text("\(index + 1) of \(images.count)")
                                            .font(.caption)
                                            .padding(.horizontal, 12)
                                            .padding(.vertical, 6)
                                            .background(Color.black.opacity(0.7))
                                            .foregroundColor(.white)
                                            .clipShape(Capsule())
                                            .padding()
                                    }
                                    Spacer()
                                }
                            }
                            .tag(index)
                        }
                    }
                    .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))
                    .background(Color.black)
                } else {
                    Spacer()
                    Text("No images to review")
                        .foregroundColor(.gray)
                    Spacer()
                }
                
                // Thumbnail strip
                if images.count > 1 {
                    ScrollView(.horizontal, showsIndicators: false) {
                        ScrollViewReader { proxy in
                            HStack(spacing: 8) {
                                ForEach(0..<images.count, id: \.self) { index in
                                    Button(action: {
                                        withAnimation {
                                            selectedImageIndex = index
                                        }
                                    }) {
                                        Image(uiImage: images[index])
                                            .resizable()
                                            .aspectRatio(contentMode: .fill)
                                            .frame(width: 60, height: 60)
                                            .clipShape(RoundedRectangle(cornerRadius: 8))
                                            .overlay(
                                                RoundedRectangle(cornerRadius: 8)
                                                    .stroke(
                                                        selectedImageIndex == index ? Color.blue : Color.clear,
                                                        lineWidth: 3
                                                    )
                                            )
                                            .scaleEffect(selectedImageIndex == index ? 1.1 : 1.0)
                                            .animation(.spring(response: 0.3), value: selectedImageIndex)
                                    }
                                }
                            }
                            .padding(.horizontal)
                            .onChange(of: selectedImageIndex) { oldValue, newValue in
                                withAnimation {
                                    proxy.scrollTo(newValue, anchor: .center)
                                }
                            }
                        }
                    }
                    .frame(height: 80)
                    .padding(.vertical, 8)
                    .background(Color(.systemGray6))
                }
            }
            .navigationTitle("Review Batch")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        onCancel()
                    }
                }
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Save All (\(images.count))") {
                        onSave()
                    }
                    .fontWeight(.semibold)
                    .disabled(images.isEmpty)
                }
            }
        }
    }
}

#Preview {
    // Create sample images for preview
    let sampleImages = (1...3).compactMap { _ in
        UIGraphicsBeginImageContext(CGSize(width: 200, height: 300))
        let context = UIGraphicsGetCurrentContext()
        context?.setFillColor(UIColor.systemBlue.cgColor)
        context?.fill(CGRect(x: 0, y: 0, width: 200, height: 300))
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
    
    BatchReviewView(
        images: sampleImages,
        onSave: { print("Save batch") },
        onCancel: { print("Cancel batch") }
    )
}