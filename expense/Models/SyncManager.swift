import Foundation
import SwiftData
import SwiftUI
import BackgroundTasks

@MainActor
class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var uploadQueue: [Receipt] = []
    @Published var isOnline = true
    @Published var backgroundUploadCount = 0
    
    private let apiClient = APIClient.shared
    private var modelContext: ModelContext?
    private let backgroundTaskIdentifier = "com.expense.sync"
    private var backgroundTaskID: UIBackgroundTaskIdentifier = .invalid
    
    // Timer for periodic background sync
    private var backgroundSyncTimer: Timer?
    private var isSetupComplete = false
    
    init() {
        // Setup will happen when setModelContext is called
    }
    
    deinit {
        backgroundSyncTimer?.invalidate()
        backgroundSyncTimer = nil
    }
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
        
        // Perform one-time setup
        if !isSetupComplete {
            startBackgroundSyncTimer()
            loadPersistentQueue()
            setupNetworkMonitoring()
            isSetupComplete = true
        }
    }
    
    // MARK: - Background Task Management
    
    private func startBackgroundSyncTimer() {
        backgroundSyncTimer = Timer.scheduledTimer(withTimeInterval: 30.0, repeats: true) { _ in
            Task {
                await self.backgroundSyncIfNeeded()
            }
        }
    }
    
    private func stopBackgroundSyncTimer() {
        backgroundSyncTimer?.invalidate()
        backgroundSyncTimer = nil
    }
    
    private func beginBackgroundTask() {
        endBackgroundTask() // End any existing task
        
        backgroundTaskID = UIApplication.shared.beginBackgroundTask(withName: "SyncReceipts") {
            // Called when the system is about to kill the task
            self.endBackgroundTask()
        }
    }
    
    private func endBackgroundTask() {
        guard backgroundTaskID != .invalid else { return }
        UIApplication.shared.endBackgroundTask(backgroundTaskID)
        backgroundTaskID = .invalid
    }
    
    private func backgroundSyncIfNeeded() async {
        guard !uploadQueue.isEmpty && isOnline else { return }
        
        beginBackgroundTask()
        defer { endBackgroundTask() }
        
        await syncAllPendingUploads()
    }
    
    // MARK: - Persistent Queue Management
    
    private func loadPersistentQueue() {
        if let data = UserDefaults.standard.data(forKey: "uploadQueue"),
           let queue = try? JSONDecoder().decode([PersistentReceiptInfo].self, from: data) {
            
            // Convert persistent info back to receipts when model context is available
            Task {
                await loadQueuedReceipts(from: queue)
            }
        }
    }
    
    private func saveQueueToPersistence() {
        let persistentQueue = uploadQueue.map { receipt in
            PersistentReceiptInfo(
                id: receipt.id.uuidString,
                timestamp: receipt.timestamp,
                failedAttempts: 0
            )
        }
        
        if let data = try? JSONEncoder().encode(persistentQueue) {
            UserDefaults.standard.set(data, forKey: "uploadQueue")
        }
    }
    
    private func loadQueuedReceipts(from persistentQueue: [PersistentReceiptInfo]) async {
        guard let context = modelContext else { return }
        
        for persistentInfo in persistentQueue {
            // Find the actual receipt in the local database
            guard let persistentUUID = UUID(uuidString: persistentInfo.id) else {
                continue // Skip invalid UUID
            }
            
            let fetchDescriptor = FetchDescriptor<Receipt>(
                predicate: #Predicate<Receipt> { receipt in
                    receipt.id == persistentUUID
                }
            )
            
            do {
                let receipts = try context.fetch(fetchDescriptor)
                if let receipt = receipts.first {
                    if !uploadQueue.contains(where: { $0.id == receipt.id }) {
                        uploadQueue.append(receipt)
                    }
                }
            } catch {
                print("Failed to load queued receipt: \(error)")
            }
        }
    }
    
    // MARK: - Network Monitoring
    
    private func setupNetworkMonitoring() {
        // Simple network check - in a production app, you'd use Network framework
        isOnline = true // Assume online for now
        
        // Monitor network changes and trigger sync when back online
        NotificationCenter.default.addObserver(
            forName: UIApplication.didBecomeActiveNotification,
            object: nil,
            queue: .main
        ) { _ in
            Task {
                await self.syncWhenOnline()
            }
        }
    }
    
    private func syncWhenOnline() async {
        guard !uploadQueue.isEmpty else { return }
        
        await syncAllPendingUploads()
    }
    
    // MARK: - App Lifecycle Management
    
    func handleAppWillEnterBackground() {
        // Save current queue state when app goes to background
        saveQueueToPersistence()
        
        // Start background task for any pending uploads
        if !uploadQueue.isEmpty {
            Task {
                await backgroundSyncIfNeeded()
            }
        }
    }
    
    func handleAppDidBecomeActive() {
        // Trigger sync when app becomes active
        Task {
            await syncWhenOnline()
        }
    }
    
    // MARK: - Manual Retry
    
    func retryFailedUploads() async {
        // Force retry all queued uploads
        await syncAllPendingUploads()
    }
    
    func clearUploadQueue() {
        uploadQueue.removeAll()
        saveQueueToPersistence()
        backgroundUploadCount = 0
        syncError = nil
    }
    
    func uploadReceipt(_ receipt: Receipt) async {
        // Always add to queue first for offline support
        if !uploadQueue.contains(where: { $0.id == receipt.id }) {
            uploadQueue.append(receipt)
            saveQueueToPersistence()
            backgroundUploadCount = uploadQueue.count
        }
        
        // Try immediate upload if online
        if isOnline {
            await uploadSingleReceipt(receipt)
        }
    }
    
    private func uploadSingleReceipt(_ receipt: Receipt) async {
        guard let imageData = receipt.imageData else {
            print("No image data for receipt \(receipt.id)")
            return
        }
        
        let receiptRequest = ReceiptRequest(
            id: receipt.id.uuidString,
            amount: receipt.amount,
            merchant: receipt.merchant,
            category: mapCategoryToAPI(receipt.category),
            notes: receipt.notes,
            submissionStatus: mapStatusToAPI(receipt.submissionStatus),
            taxAmount: receipt.taxAmount,
            paymentMethod: receipt.paymentMethod,
            isProcessed: receipt.isProcessed,
            timestamp: ISO8601DateFormatter().string(from: receipt.timestamp),
            submissionDate: receipt.submissionDate?.description
        )
        
        do {
            let uploadedReceipt = try await apiClient.uploadReceiptWithImage(
                receipt: receiptRequest,
                imageData: imageData
            )
            
            print("Successfully uploaded receipt: \(uploadedReceipt.id)")
            
            // Remove from upload queue on success
            uploadQueue.removeAll { $0.id == receipt.id }
            saveQueueToPersistence()
            backgroundUploadCount = uploadQueue.count
            
        } catch {
            print("Failed to upload receipt: \(error)")
            syncError = error.localizedDescription
            
            // Receipt remains in queue for retry
        }
    }
    
    func syncAllPendingUploads() async {
        guard !isSyncing, !uploadQueue.isEmpty else { return }
        
        isSyncing = true
        syncError = nil
        
        // Upload all queued receipts
        let receiptsToUpload = Array(uploadQueue) // Copy to avoid modification during iteration
        for receipt in receiptsToUpload {
            await uploadSingleReceipt(receipt)
        }
        
        isSyncing = false
    }
    
    func downloadAllReceipts() async {
        guard let context = modelContext else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            let serverReceipts = try await apiClient.getReceipts()
            
            for serverReceipt in serverReceipts {
                // Check if receipt already exists locally
                guard let serverReceiptUUID = UUID(uuidString: serverReceipt.id) else {
                    print("❌ Failed to parse UUID from server receipt ID: '\(serverReceipt.id)'")
                    continue // Skip invalid UUID
                }
                
                let fetchDescriptor = FetchDescriptor<Receipt>(
                    predicate: #Predicate<Receipt> { receipt in
                        receipt.id == serverReceiptUUID
                    }
                )
                
                let existingReceipts = try context.fetch(fetchDescriptor)
                
                if existingReceipts.isEmpty {
                    // Create new local receipt from server data
                    let newReceipt = Receipt(
                        timestamp: ISO8601DateFormatter().date(from: serverReceipt.timestamp) ?? Date(),
                        imageData: serverReceipt.imageData != nil ? Data(base64Encoded: serverReceipt.imageData!) : nil,
                        amount: serverReceipt.amount,
                        merchant: serverReceipt.merchant,
                        category: mapCategoryFromAPI(serverReceipt.category),
                        notes: serverReceipt.notes,
                        submissionStatus: mapStatusFromAPI(serverReceipt.submissionStatus),
                        submissionDate: serverReceipt.submissionDate != nil ? ISO8601DateFormatter().date(from: serverReceipt.submissionDate!) : nil,
                        taxAmount: serverReceipt.taxAmount,
                        paymentMethod: serverReceipt.paymentMethod,
                        isProcessed: serverReceipt.isProcessed
                    )
                    
                    // Set the ID from server
                    newReceipt.id = serverReceiptUUID
                    
                    context.insert(newReceipt)
                }
            }
            
            try context.save()
            
        } catch {
            print("Failed to download receipts: \(error)")
            syncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    /// Download receipts from server and overwrite local data - used for History tab
    func downloadAndOverwriteReceipts() async {
        guard let context = modelContext else { return }
        
        isSyncing = true
        syncError = nil
        
        do {
            let serverReceipts = try await apiClient.getReceipts()
            print("📥 Downloaded \(serverReceipts.count) receipts from server")
            
            // Debug: Print first server receipt details
            if let first = serverReceipts.first {
                print("📝 Sample server receipt - ID: '\(first.id)', Merchant: '\(first.merchant)', Amount: \(first.amount)")
            }
            
            // Get all existing local receipts
            let allLocalReceipts = try context.fetch(FetchDescriptor<Receipt>())
            print("📱 Found \(allLocalReceipts.count) existing local receipts")
            
            // Track server receipt IDs for comparison
            let serverReceiptIds = Set(serverReceipts.compactMap { UUID(uuidString: $0.id) })
            print("✅ Successfully parsed \(serverReceiptIds.count) UUIDs from server receipts")
            
            // Delete local receipts that don't exist on server
            for localReceipt in allLocalReceipts {
                if !serverReceiptIds.contains(localReceipt.id) {
                    context.delete(localReceipt)
                }
            }
            
            // Update or create receipts from server
            for serverReceipt in serverReceipts {
                guard let serverReceiptUUID = UUID(uuidString: serverReceipt.id) else {
                    print("❌ Failed to parse UUID from server receipt ID: '\(serverReceipt.id)'")
                    continue // Skip invalid UUID
                }
                
                let fetchDescriptor = FetchDescriptor<Receipt>(
                    predicate: #Predicate<Receipt> { receipt in
                        receipt.id == serverReceiptUUID
                    }
                )
                
                let existingReceipts = try context.fetch(fetchDescriptor)
                
                if let existingReceipt = existingReceipts.first {
                    // Update existing receipt with server data
                    print("🔄 Updating existing receipt: \(existingReceipt.id)")
                    existingReceipt.timestamp = ISO8601DateFormatter().date(from: serverReceipt.timestamp) ?? existingReceipt.timestamp
                    existingReceipt.imageData = serverReceipt.imageData != nil ? Data(base64Encoded: serverReceipt.imageData!) : nil
                    existingReceipt.amount = serverReceipt.amount
                    existingReceipt.merchant = serverReceipt.merchant
                    existingReceipt.category = mapCategoryFromAPI(serverReceipt.category)
                    existingReceipt.notes = serverReceipt.notes
                    existingReceipt.submissionStatus = mapStatusFromAPI(serverReceipt.submissionStatus)
                    existingReceipt.submissionDate = serverReceipt.submissionDate != nil ? ISO8601DateFormatter().date(from: serverReceipt.submissionDate!) : nil
                    existingReceipt.taxAmount = serverReceipt.taxAmount
                    existingReceipt.paymentMethod = serverReceipt.paymentMethod
                    existingReceipt.isProcessed = serverReceipt.isProcessed
                } else {
                    // Create new local receipt from server data
                    print("✨ Creating new receipt from server data - ID: \(serverReceipt.id)")
                    let parsedTimestamp = ISO8601DateFormatter().date(from: serverReceipt.timestamp)
                    print("📅 Parsed timestamp: \(parsedTimestamp?.description ?? "nil") from: \(serverReceipt.timestamp)")
                    
                    let newReceipt = Receipt(
                        timestamp: parsedTimestamp ?? Date(),
                        imageData: serverReceipt.imageData != nil ? Data(base64Encoded: serverReceipt.imageData!) : nil,
                        amount: serverReceipt.amount,
                        merchant: serverReceipt.merchant,
                        category: mapCategoryFromAPI(serverReceipt.category),
                        notes: serverReceipt.notes,
                        submissionStatus: mapStatusFromAPI(serverReceipt.submissionStatus),
                        submissionDate: serverReceipt.submissionDate != nil ? ISO8601DateFormatter().date(from: serverReceipt.submissionDate!) : nil,
                        taxAmount: serverReceipt.taxAmount,
                        paymentMethod: serverReceipt.paymentMethod,
                        isProcessed: serverReceipt.isProcessed
                    )
                    
                    // Set the ID from server
                    newReceipt.id = serverReceiptUUID
                    print("💾 Inserting receipt with final ID: \(newReceipt.id)")
                    
                    context.insert(newReceipt)
                }
            }
            
            try context.save()
            
            // Debug: Count receipts after sync
            let finalReceiptCount = try context.fetch(FetchDescriptor<Receipt>()).count
            print("✅ Successfully synced \(serverReceipts.count) receipts from server")
            print("📊 Total local receipts after sync: \(finalReceiptCount)")
            
        } catch {
            print("Failed to download and overwrite receipts: \(error)")
            syncError = error.localizedDescription
        }
        
        isSyncing = false
    }
    
    func performFullSync() async {
        await syncAllPendingUploads()
        await downloadAllReceipts()
    }
    
    // MARK: - Category Mapping
    private func mapCategoryToAPI(_ category: ReceiptCategory) -> String {
        switch category {
        case .meals: return "meals"
        case .travel: return "travel"
        case .office: return "office"
        case .vehicle: return "vehicle"
        case .utilities: return "utilities"
        case .professional: return "professional"
        case .advertising: return "advertising"
        case .insurance: return "insurance"
        case .equipment: return "equipment"
        case .other: return "other"
        }
    }
    
    private func mapCategoryFromAPI(_ category: String) -> ReceiptCategory {
        switch category {
        case "meals": return .meals
        case "travel": return .travel
        case "office": return .office
        case "vehicle": return .vehicle
        case "utilities": return .utilities
        case "professional": return .professional
        case "advertising": return .advertising
        case "insurance": return .insurance
        case "equipment": return .equipment
        default: return .other
        }
    }
    
    // MARK: - Status Mapping
    private func mapStatusToAPI(_ status: SubmissionStatus) -> String {
        switch status {
        case .pending: return "pending"
        case .submitted: return "submitted"
        case .approved: return "approved"
        case .rejected: return "rejected"
        }
    }
    
    private func mapStatusFromAPI(_ status: String) -> SubmissionStatus {
        switch status {
        case "pending": return .pending
        case "submitted": return .submitted
        case "approved": return .approved
        case "rejected": return .rejected
        default: return .pending
        }
    }
}

// MARK: - Supporting Data Structures

struct PersistentReceiptInfo: Codable {
    let id: String
    let timestamp: Date
    let failedAttempts: Int
}