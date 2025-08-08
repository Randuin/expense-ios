//
//  CameraView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI
import AVFoundation
import PhotosUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()
    @Environment(\.modelContext) private var modelContext
    @State private var capturedImage: UIImage?
    @State private var showingReceiptEdit = false
    @State private var showingImagePicker = false
    @State private var flashMode: AVCaptureDevice.FlashMode = .auto
    
    var body: some View {
        ZStack {
            // Black background as fallback
            Color.black
                .ignoresSafeArea()
            
            // Camera preview
            if viewModel.isCameraReady {
                CameraPreview(session: viewModel.session)
                    .ignoresSafeArea()
                    .transition(.opacity)
            } else {
                // Placeholder while camera loads
                VStack(spacing: 20) {
                    Image(systemName: "camera.fill")
                        .font(.system(size: 60))
                        .foregroundColor(.white.opacity(0.5))
                    
                    if viewModel.isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.2)
                        
                        Text("Initializing camera...")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                    } else {
                        Text("Camera not available")
                            .font(.headline)
                            .foregroundColor(.white.opacity(0.7))
                        
                        Text("Use photo library instead")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.5))
                    }
                }
            }
            
            // Camera controls overlay
            VStack {
                cameraControls
                    .padding(.top, 50)
                Spacer()
                captureControls
                    .padding(.bottom, 40)
            }
            
            // Loading overlay for operations
            if viewModel.isLoading && viewModel.isCameraReady {
                Color.black.opacity(0.5)
                    .ignoresSafeArea()
                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.5)
            }
        }
        .onAppear {
            viewModel.checkPermissions()
        }
        .onDisappear {
            viewModel.stopSession()
        }
        .sheet(isPresented: $showingReceiptEdit, onDismiss: {
            viewModel.startSession()
        }) {
            if let image = capturedImage {
                NavigationStack {
                    ReceiptEditView(image: image, modelContext: modelContext) {
                        capturedImage = nil
                        showingReceiptEdit = false
                    }
                }
            }
        }
        .sheet(isPresented: $showingImagePicker, onDismiss: {
            if capturedImage == nil {
                viewModel.startSession()
            }
        }) {
            ImagePicker(image: $capturedImage, onImagePicked: {
                showingReceiptEdit = true
            })
        }
        .alert("Camera Permission Required", isPresented: $viewModel.showPermissionAlert) {
            Button("Open Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Please enable camera access in Settings to capture receipts.")
        }
    }
    
    private var cameraControls: some View {
        HStack {
            Button(action: toggleFlash) {
                Image(systemName: flashIcon)
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .disabled(!viewModel.isCameraReady)
            
            Spacer()
            
            Text("Capture Receipt")
                .font(.headline)
                .foregroundColor(.white)
                .padding(.horizontal, 20)
                .padding(.vertical, 10)
                .background(Color.black.opacity(0.5))
                .clipShape(Capsule())
            
            Spacer()
            
            Button(action: { viewModel.switchCamera() }) {
                Image(systemName: "camera.rotate")
                    .font(.title2)
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            .disabled(!viewModel.isCameraReady)
        }
        .padding(.horizontal)
    }
    
    private var captureControls: some View {
        HStack(spacing: 50) {
            Button(action: { showingImagePicker = true }) {
                Image(systemName: "photo.on.rectangle")
                    .font(.title)
                    .foregroundColor(.white)
                    .frame(width: 60, height: 60)
                    .background(Color.black.opacity(0.5))
                    .clipShape(Circle())
            }
            
            Button(action: capturePhoto) {
                ZStack {
                    Circle()
                        .fill(viewModel.isCameraReady ? Color.white : Color.white.opacity(0.3))
                        .frame(width: 75, height: 75)
                    Circle()
                        .stroke(viewModel.isCameraReady ? Color.white : Color.white.opacity(0.3), lineWidth: 3)
                        .frame(width: 85, height: 85)
                }
            }
            .disabled(!viewModel.isCameraReady)
            
            Rectangle()
                .fill(Color.clear)
                .frame(width: 60, height: 60)
        }
    }
    
    private var flashIcon: String {
        switch flashMode {
        case .auto:
            return "bolt.badge.automatic"
        case .on:
            return "bolt.fill"
        case .off:
            return "bolt.slash"
        @unknown default:
            return "bolt.badge.automatic"
        }
    }
    
    private func toggleFlash() {
        switch flashMode {
        case .auto:
            flashMode = .on
        case .on:
            flashMode = .off
        case .off:
            flashMode = .auto
        @unknown default:
            flashMode = .auto
        }
        viewModel.setFlashMode(flashMode)
    }
    
    private func capturePhoto() {
        viewModel.capturePhoto { image in
            capturedImage = image
            showingReceiptEdit = true
        }
    }
}

class CameraViewModel: NSObject, ObservableObject {
    @Published var session = AVCaptureSession()
    @Published var isLoading = false
    @Published var showPermissionAlert = false
    @Published var isCameraReady = false
    
    private var photoOutput = AVCapturePhotoOutput()
    private var currentCameraPosition: AVCaptureDevice.Position = .back
    private var photoCompletion: ((UIImage?) -> Void)?
    private var isSessionConfigured = false
    private var isConfiguring = false
    
    override init() {
        super.init()
    }
    
    func checkPermissions() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            if !isSessionConfigured {
                setupSession()
            } else {
                startSession()
            }
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
                if granted {
                    DispatchQueue.main.async {
                        if !(self?.isSessionConfigured ?? false) {
                            self?.setupSession()
                        } else {
                            self?.startSession()
                        }
                    }
                } else {
                    DispatchQueue.main.async {
                        self?.showPermissionAlert = true
                    }
                }
            }
        case .denied, .restricted:
            showPermissionAlert = true
        @unknown default:
            break
        }
    }
    
    private func setupSession() {
        guard !isConfiguring else { return }
        
        isLoading = true
        isConfiguring = true
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            self.session.sessionPreset = .photo
            
            // Remove any existing inputs
            self.session.inputs.forEach { self.session.removeInput($0) }
            self.session.outputs.forEach { self.session.removeOutput($0) }
            
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                self.session.commitConfiguration()
                self.isConfiguring = false
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            if self.session.canAddOutput(self.photoOutput) {
                self.session.addOutput(self.photoOutput)
            }
            
            self.session.commitConfiguration()
            self.isSessionConfigured = true
            self.isConfiguring = false
            
            // Start the session after configuration is complete
            self.startSession()
            
            DispatchQueue.main.async {
                self.isLoading = false
                self.isCameraReady = true
            }
        }
    }
    
    func startSession() {
        guard !isConfiguring else { return }
        
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async { [weak self] in
                guard let self = self, !self.isConfiguring else { return }
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isCameraReady = true
                }
            }
        }
    }
    
    func stopSession() {
        if session.isRunning {
            session.stopRunning()
        }
    }
    
    func switchCamera() {
        guard !isConfiguring else { return }
        
        isLoading = true
        isConfiguring = true
        currentCameraPosition = currentCameraPosition == .back ? .front : .back
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            guard let self = self else { return }
            
            self.session.beginConfiguration()
            
            // Remove current input
            if let currentInput = self.session.inputs.first as? AVCaptureDeviceInput {
                self.session.removeInput(currentInput)
            }
            
            // Add new input
            guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: self.currentCameraPosition),
                  let input = try? AVCaptureDeviceInput(device: camera) else {
                self.session.commitConfiguration()
                self.isConfiguring = false
                DispatchQueue.main.async {
                    self.isLoading = false
                }
                return
            }
            
            if self.session.canAddInput(input) {
                self.session.addInput(input)
            }
            
            self.session.commitConfiguration()
            self.isConfiguring = false
            
            DispatchQueue.main.async {
                self.isLoading = false
            }
        }
    }
    
    func setFlashMode(_ mode: AVCaptureDevice.FlashMode) {
        // Flash mode will be set when capturing photo
    }
    
    func capturePhoto(completion: @escaping (UIImage?) -> Void) {
        photoCompletion = completion
        
        let settings = AVCapturePhotoSettings()
        if photoOutput.supportedFlashModes.contains(.auto) {
            settings.flashMode = .auto
        }
        
        photoOutput.capturePhoto(with: settings, delegate: self)
    }
}

extension CameraViewModel: AVCapturePhotoCaptureDelegate {
    func photoOutput(_ output: AVCapturePhotoOutput, didFinishProcessingPhoto photo: AVCapturePhoto, error: Error?) {
        guard let data = photo.fileDataRepresentation(),
              let image = UIImage(data: data) else {
            photoCompletion?(nil)
            return
        }
        
        DispatchQueue.main.async {
            self.photoCompletion?(image)
        }
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession
    
    class VideoPreviewView: UIView {
        override class var layerClass: AnyClass {
            AVCaptureVideoPreviewLayer.self
        }
        
        var videoPreviewLayer: AVCaptureVideoPreviewLayer {
            return layer as! AVCaptureVideoPreviewLayer
        }
        
        override func layoutSubviews() {
            super.layoutSubviews()
            videoPreviewLayer.frame = bounds
        }
    }
    
    func makeUIView(context: Context) -> VideoPreviewView {
        let view = VideoPreviewView()
        view.backgroundColor = .black
        view.videoPreviewLayer.session = session
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        return view
    }
    
    func updateUIView(_ uiView: VideoPreviewView, context: Context) {
        // Session is already set, just ensure the connection is active
        DispatchQueue.main.async {
            uiView.videoPreviewLayer.session = session
        }
    }
}

struct ImagePicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    var onImagePicked: () -> Void
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .images
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: ImagePicker
        
        init(_ parent: ImagePicker) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            picker.dismiss(animated: true)
            
            guard let provider = results.first?.itemProvider else { return }
            
            if provider.canLoadObject(ofClass: UIImage.self) {
                provider.loadObject(ofClass: UIImage.self) { image, _ in
                    DispatchQueue.main.async {
                        self.parent.image = image as? UIImage
                        if self.parent.image != nil {
                            self.parent.onImagePicked()
                        }
                    }
                }
            }
        }
    }
}