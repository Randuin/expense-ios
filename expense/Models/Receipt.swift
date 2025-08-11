//
//  Receipt.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import Foundation
import SwiftData
import SwiftUI

enum ReceiptCategory: String, CaseIterable, Codable {
    case meals = "Meals & Entertainment"
    case travel = "Travel"
    case office = "Office & Supplies"
    case vehicle = "Vehicle"
    case utilities = "Utilities"
    case professional = "Professional Services"
    case advertising = "Advertising & Marketing"
    case insurance = "Insurance"
    case equipment = "Equipment"
    case other = "Other"
    
    var icon: String {
        switch self {
        case .meals: return "fork.knife"
        case .travel: return "airplane"
        case .office: return "paperclip"
        case .vehicle: return "car"
        case .utilities: return "bolt"
        case .professional: return "briefcase"
        case .advertising: return "megaphone"
        case .insurance: return "shield"
        case .equipment: return "wrench.and.screwdriver"
        case .other: return "ellipsis.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .meals: return .orange
        case .travel: return .blue
        case .office: return .purple
        case .vehicle: return .green
        case .utilities: return .yellow
        case .professional: return .indigo
        case .advertising: return .pink
        case .insurance: return .teal
        case .equipment: return .brown
        case .other: return .gray
        }
    }
    
    /// Tax deductibility percentage (0.0 to 1.0)
    var taxDeductiblePercentage: Double {
        switch self {
        case .meals: return 0.5 // 50% deductible for business meals
        case .travel: return 1.0 // 100% deductible for business travel
        case .office: return 1.0 // 100% deductible for office supplies
        case .vehicle: return 1.0 // 100% deductible (varies by method - actual vs. standard mileage)
        case .utilities: return 1.0 // 100% deductible for business utilities
        case .professional: return 1.0 // 100% deductible for professional services
        case .advertising: return 1.0 // 100% deductible for advertising
        case .insurance: return 1.0 // 100% deductible for business insurance
        case .equipment: return 1.0 // 100% deductible or depreciable
        case .other: return 1.0 // Assume 100%, user should verify
        }
    }
    
    /// IRS Schedule C line item mapping for sole proprietors
    var scheduleCAteory: String {
        switch self {
        case .meals: return "Line 24b - Meals (50% limit)"
        case .travel: return "Line 24a - Travel"
        case .office: return "Line 22 - Supplies"
        case .vehicle: return "Line 9 - Car and truck expenses"
        case .utilities: return "Line 25 - Utilities"
        case .professional: return "Line 17 - Legal and professional services"
        case .advertising: return "Line 8 - Advertising"
        case .insurance: return "Line 15 - Insurance (other than health)"
        case .equipment: return "Line 13 - Depreciation (Form 4562)"
        case .other: return "Line 27a - Other business expenses"
        }
    }
    
    /// Common QuickBooks expense account mapping
    var quickBooksAccount: String {
        switch self {
        case .meals: return "Meals and Entertainment"
        case .travel: return "Travel Expense"
        case .office: return "Office Supplies"
        case .vehicle: return "Auto Expense"
        case .utilities: return "Utilities"
        case .professional: return "Professional Services"
        case .advertising: return "Advertising and Promotion"
        case .insurance: return "Insurance Expense"
        case .equipment: return "Equipment"
        case .other: return "Miscellaneous Expense"
        }
    }
    
    /// Tax guidance for users
    var taxGuidance: String {
        switch self {
        case .meals: 
            return "Business meals are 50% deductible. Must be ordinary and necessary for your business."
        case .travel: 
            return "100% deductible when traveling away from home for business purposes."
        case .office: 
            return "Office supplies and materials used in your business are 100% deductible."
        case .vehicle: 
            return "Use actual expenses or standard mileage rate. Keep detailed records."
        case .utilities: 
            return "100% deductible for dedicated business space or proportional for home office."
        case .professional: 
            return "Legal, accounting, and consulting fees are 100% deductible."
        case .advertising: 
            return "Marketing and advertising expenses are 100% deductible."
        case .insurance: 
            return "Business insurance premiums are 100% deductible."
        case .equipment: 
            return "May be 100% deductible under Section 179 or depreciated over time."
        case .other: 
            return "Must be ordinary and necessary for your business. Consult tax professional."
        }
    }
}

enum SubmissionStatus: String, CaseIterable, Codable {
    case pending = "Pending"
    case submitted = "Submitted"
    case approved = "Approved"
    case rejected = "Rejected"
    
    var icon: String {
        switch self {
        case .pending: return "clock"
        case .submitted: return "paperplane"
        case .approved: return "checkmark.circle"
        case .rejected: return "xmark.circle"
        }
    }
    
    var color: Color {
        switch self {
        case .pending: return .orange
        case .submitted: return .blue
        case .approved: return .green
        case .rejected: return .red
        }
    }
}

@Model
final class Receipt {
    var id: UUID
    var timestamp: Date
    var imageData: Data?
    var amount: Double
    var merchant: String
    var category: ReceiptCategory
    var notes: String
    var submissionStatus: SubmissionStatus
    var submissionDate: Date?
    var taxAmount: Double?
    var paymentMethod: String?
    var isProcessed: Bool
    
    init(
        timestamp: Date = Date(),
        imageData: Data? = nil,
        amount: Double = 0.0,
        merchant: String = "",
        category: ReceiptCategory = .other,
        notes: String = "",
        submissionStatus: SubmissionStatus = .pending,
        submissionDate: Date? = nil,
        taxAmount: Double? = nil,
        paymentMethod: String? = nil,
        isProcessed: Bool = false
    ) {
        self.id = UUID()
        self.timestamp = timestamp
        self.imageData = imageData
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.notes = notes
        self.submissionStatus = submissionStatus
        self.submissionDate = submissionDate
        self.taxAmount = taxAmount
        self.paymentMethod = paymentMethod
        self.isProcessed = isProcessed
    }
    
    var formattedAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    var formattedDate: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: timestamp)
    }
    
    /// Calculate tax-deductible amount based on category rules
    var taxDeductibleAmount: Double {
        return amount * category.taxDeductiblePercentage
    }
    
    /// Formatted tax-deductible amount
    var formattedTaxDeductibleAmount: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: taxDeductibleAmount)) ?? "$0.00"
    }
    
    /// Check if this receipt is fully tax deductible
    var isFullyDeductible: Bool {
        return category.taxDeductiblePercentage >= 1.0
    }
    
    /// Get the tax year for this receipt
    var taxYear: Int {
        return Calendar.current.component(.year, from: timestamp)
    }
    
    /// Format receipt for QuickBooks import
    var quickBooksExportString: String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "MM/dd/yyyy"
        
        return [
            dateFormatter.string(from: timestamp),
            category.quickBooksAccount,
            merchant.isEmpty ? "Unknown Vendor" : merchant,
            String(format: "%.2f", amount),
            notes.isEmpty ? category.rawValue : notes
        ].joined(separator: ",")
    }
}