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
        paymentMethod: String? = nil
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
}