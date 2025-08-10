import Foundation
import SwiftData
import SwiftUI

@MainActor
class SyncManager: ObservableObject {
    @Published var isSyncing = false
    @Published var syncError: String?
    @Published var uploadQueue: [Receipt] = []
    
    private let apiClient = APIClient.shared
    private var modelContext: ModelContext?
    
    func setModelContext(_ context: ModelContext) {
        self.modelContext = context
    }
    
    func uploadReceipt(_ receipt: Receipt) async {
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
            
            // Remove from upload queue if it was there
            uploadQueue.removeAll { $0.id == receipt.id }
            
        } catch {
            print("Failed to upload receipt: \(error)")
            syncError = error.localizedDescription
            
            // Add to upload queue for retry
            if !uploadQueue.contains(where: { $0.id == receipt.id }) {
                uploadQueue.append(receipt)
            }
        }
    }
    
    func syncAllPendingUploads() async {
        guard !isSyncing else { return }
        
        isSyncing = true
        syncError = nil
        
        // Upload all queued receipts
        for receipt in uploadQueue {
            await uploadReceipt(receipt)
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
                let fetchDescriptor = FetchDescriptor<Receipt>(
                    predicate: #Predicate<Receipt> { receipt in
                        receipt.id.uuidString == serverReceipt.id
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
                    newReceipt.id = UUID(uuidString: serverReceipt.id) ?? UUID()
                    
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