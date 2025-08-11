//
//  QuickCaptureView.swift
//  expense
//
//  Created by Claude on 8/10/25.
//

import SwiftUI
import AVFoundation
import SwiftData

struct QuickCaptureView: View {
    @StateObject private var viewModel = CameraViewModel()
    @StateObject private var syncManager = SyncManager()
    @EnvironmentObject private var authManager: AuthManager
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var showSuccessFeedback = false
    @State private var captureCount = 0
    @State private var batchMode = false
    @State private var batchImages: [UIImage] = []
    @State private var showBatchReview = false
    
    var body: some View {
        ZStack {
            // Black background
            Color.black
                .ignoresSafeArea()
            
            // Camera preview
            if viewModel.isCameraReady {
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 20) {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                        .scaleEffect(1.5)
                    
                    Text("Preparing camera...")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            
            // Minimal UI overlay
            VStack {
                // Top bar with exit, mode toggle, and controls
                VStack(spacing: 12) {
                    HStack {
                        Button(action: { dismiss() }) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        
                        Spacer()
                        
                        VStack(spacing: 4) {
                            Text(batchMode ? "Batch Capture" : "Quick Capture")
                                .font(.headline)
                                .foregroundColor(.white)
                            if batchMode && !batchImages.isEmpty {
                                Text("\(batchImages.count) photos")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(Color.black.opacity(0.6))
                        .clipShape(Capsule())
                        
                        Spacer()
                        
                        Button(action: { viewModel.switchCamera() }) {
                            Image(systemName: "camera.rotate")
                                .font(.title2)
                                .foregroundColor(.white)
                                .padding()
                                .background(Color.black.opacity(0.6))
                                .clipShape(Circle())
                        }
                        .disabled(!viewModel.isCameraReady)
                    }
                    
                    // Mode toggle
                    HStack {
                        Button(action: { toggleBatchMode() }) {
                            HStack(spacing: 8) {
                                Image(systemName: batchMode ? "photo.stack" : "camera")
                                    .font(.caption)
                                Text(batchMode ? "Batch Mode" : "Single Mode")
                                    .font(.caption)
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 6)
                            .background(batchMode ? Color.blue.opacity(0.8) : Color.black.opacity(0.6))
                            .foregroundColor(.white)
                            .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal)
                .padding(.top, 50)
                
                Spacer()
                
                // Capture controls
                VStack(spacing: 20) {
                    if batchMode && !batchImages.isEmpty {
                        // Batch mode: show thumbnails and controls
                        VStack(spacing: 16) {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(0..<batchImages.count, id: \.self) { index in
                                        ZStack(alignment: .topTrailing) {
                                            Image(uiImage: batchImages[index])
                                                .resizable()
                                                .aspectRatio(contentMode: .fill)
                                                .frame(width: 60, height: 60)
                                                .clipShape(RoundedRectangle(cornerRadius: 8))
                                                .overlay(
                                                    RoundedRectangle(cornerRadius: 8)
                                                        .stroke(Color.white, lineWidth: 2)
                                                )
                                            
                                            Button(action: { removeBatchImage(at: index) }) {
                                                Image(systemName: "xmark.circle.fill")
                                                    .foregroundColor(.red)
                                                    .background(Color.white, in: Circle())
                                            }
                                            .offset(x: 5, y: -5)
                                        }
                                    }
                                }
                                .padding(.horizontal)
                            }
                            
                            HStack(spacing: 30) {
                                Button(action: { showBatchReview = true }) {
                                    VStack {
                                        Image(systemName: "checkmark.circle")
                                            .font(.title)
                                            .foregroundColor(.green)
                                        Text("Review & Save")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                }
                                
                                Button(action: capturePhoto) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.white.opacity(0.2))
                                            .frame(width: 80, height: 80)
                                        Circle()
                                            .fill(viewModel.isCameraReady ? Color.white : Color.white.opacity(0.3))
                                            .frame(width: 65, height: 65)
                                        Circle()
                                            .stroke(Color.white, lineWidth: 3)
                                            .frame(width: 90, height: 90)
                                    }
                                }
                                .disabled(!viewModel.isCameraReady)
                                
                                Button(action: clearBatch) {
                                    VStack {
                                        Image(systemName: "trash.circle")
                                            .font(.title)
                                            .foregroundColor(.red)
                                        Text("Clear All")
                                            .font(.caption)
                                            .foregroundColor(.white)
                                    }
                                }
                            }
                        }
                    } else {
                        // Single mode or empty batch: show large capture button
                        Button(action: capturePhoto) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 100, height: 100)
                                Circle()
                                    .fill(viewModel.isCameraReady ? Color.white : Color.white.opacity(0.3))
                                    .frame(width: 80, height: 80)
                                Circle()
                                    .stroke(Color.white, lineWidth: 4)
                                    .frame(width: 110, height: 110)
                            }
                        }
                        .disabled(!viewModel.isCameraReady)
                        .scaleEffect(viewModel.isCameraReady ? 1.0 : 0.8)
                        .animation(.spring(), value: viewModel.isCameraReady)
                        
                        Text(batchMode ? "Tap to capture first receipt" : "Tap to capture receipt")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.8))
                    }
                }
                .padding(.bottom, 60)
            }
            
            // Success feedback
            if showSuccessFeedback {
                VStack {
                    Spacer()
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.title)
                            .foregroundColor(.green)
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Receipt \(captureCount) saved!")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Tap capture again for next receipt")
                                .font(.caption)
                                .foregroundColor(.white.opacity(0.8))
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.8))
                    .cornerRadius(12)
                    .padding(.bottom, 140)
                }
                .transition(.scale.combined(with: .opacity))
            }
            
            // Loading overlay
            if viewModel.isLoading && viewModel.isCameraReady {
                Color.black.opacity(0.3)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.2)
            }
        }
        .onAppear {
            viewModel.checkPermissions()
            syncManager.setModelContext(modelContext)
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .sheet(isPresented: $showBatchReview) {
            BatchReviewView(images: batchImages, onSave: { saveBatchReceipts() }, onCancel: { showBatchReview = false })
        }
        .alert("Camera Permission Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please enable camera access in Settings to capture receipts.")
        }
    }
    
    private func toggleBatchMode() {
        withAnimation(.spring()) {
            batchMode.toggle()
            if !batchMode {
                // Switching from batch to single mode - clear batch
                clearBatch()
            }
        }
    }
    
    private func capturePhoto() {
        viewModel.capturePhoto { image in
            guard let image = image else { return }
            
            if batchMode {
                // Add to batch
                batchImages.append(image)
                
                withAnimation(.spring()) {
                    showSuccessFeedback = true
                }
                
                // Hide success feedback after 1 second
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                    withAnimation {
                        showSuccessFeedback = false
                    }
                }
            } else {
                // Single mode - save immediately
                saveSingleReceipt(image: image)
            }
        }
    }
    
    private func saveSingleReceipt(image: UIImage) {
        let receipt = Receipt(
            timestamp: Date(),
            imageData: image.jpegData(compressionQuality: 0.8),
            isProcessed: false
        )
        
        modelContext.insert(receipt)
        
        do {
            try modelContext.save()
            captureCount += 1
            
            withAnimation(.spring()) {
                showSuccessFeedback = true
            }
            
            // Upload to backend if authenticated
            if authManager.isAuthenticated {
                Task {
                    await syncManager.uploadReceipt(receipt)
                }
            }
            
            // Hide success feedback after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                withAnimation {
                    showSuccessFeedback = false
                }
            }
        } catch {
            print("Failed to save receipt: \(error)")
        }
    }
    
    private func saveBatchReceipts() {
        for image in batchImages {
            let receipt = Receipt(
                timestamp: Date(),
                imageData: image.jpegData(compressionQuality: 0.8),
                isProcessed: false
            )
            
            modelContext.insert(receipt)
            
            // Upload to backend if authenticated
            if authManager.isAuthenticated {
                Task {
                    await syncManager.uploadReceipt(receipt)
                }
            }
        }
        
        do {
            try modelContext.save()
            captureCount += batchImages.count
            
            withAnimation(.spring()) {
                showSuccessFeedback = true
            }
            
            // Clear batch after saving
            clearBatch()
            showBatchReview = false
            
            // Hide success feedback after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                withAnimation {
                    showSuccessFeedback = false
                }
            }
        } catch {
            print("Failed to save batch receipts: \(error)")
        }
    }
    
    private func removeBatchImage(at index: Int) {
        withAnimation(.spring()) {
            batchImages.remove(at: index)
        }
    }
    
    private func clearBatch() {
        withAnimation(.spring()) {
            batchImages.removeAll()
        }
    }
}

#Preview {
    QuickCaptureView()
        .modelContainer(for: Receipt.self, inMemory: true)
        .environmentObject(AuthManager())
}