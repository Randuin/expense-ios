//
//  ExportManager.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import Foundation
import SwiftUI
import UniformTypeIdentifiers

class ExportManager {
    static let shared = ExportManager()
    
    private init() {}
    
    enum ExportFormat {
        case csv
        case text
        case json
    }
    
    func exportReceipts(_ receipts: [Receipt], format: ExportFormat) -> URL? {
        switch format {
        case .csv:
            return exportAsCSV(receipts)
        case .text:
            return exportAsText(receipts)
        case .json:
            return exportAsJSON(receipts)
        }
    }
    
    func exportSingleReceipt(_ receipt: Receipt, format: ExportFormat) -> URL? {
        return exportReceipts([receipt], format: format)
    }
    
    private func exportAsCSV(_ receipts: [Receipt]) -> URL? {
        var csvString = "Date,Merchant,Category,Amount,Tax,Payment Method,Status,Notes\n"
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .short
        
        for receipt in receipts {
            let date = dateFormatter.string(from: receipt.timestamp)
            let merchant = receipt.merchant.replacingOccurrences(of: ",", with: ";")
            let category = receipt.category.rawValue
            let amount = String(format: "%.2f", receipt.amount)
            let tax = receipt.taxAmount != nil ? String(format: "%.2f", receipt.taxAmount!) : ""
            let payment = receipt.paymentMethod ?? ""
            let status = receipt.submissionStatus.rawValue
            let notes = receipt.notes.replacingOccurrences(of: ",", with: ";").replacingOccurrences(of: "\n", with: " ")
            
            csvString += "\(date),\(merchant),\(category),\(amount),\(tax),\(payment),\(status),\(notes)\n"
        }
        
        return saveToFile(content: csvString, filename: "receipts_export.csv")
    }
    
    private func exportAsText(_ receipts: [Receipt]) -> URL? {
        var textContent = "EXPENSE RECEIPTS EXPORT\n"
        textContent += "Generated: \(Date().formatted())\n"
        textContent += "Total Receipts: \(receipts.count)\n"
        textContent += String(repeating: "=", count: 50) + "\n\n"
        
        let totalAmount = receipts.reduce(0) { $0 + $1.amount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        textContent += "Total Amount: \(formatter.string(from: NSNumber(value: totalAmount)) ?? "$0.00")\n"
        textContent += String(repeating: "-", count: 50) + "\n\n"
        
        for (index, receipt) in receipts.enumerated() {
            textContent += "Receipt #\(index + 1)\n"
            textContent += "Date: \(receipt.formattedDate)\n"
            textContent += "Merchant: \(receipt.merchant)\n"
            textContent += "Amount: \(receipt.formattedAmount)\n"
            
            if let taxAmount = receipt.taxAmount {
                textContent += "Tax: \(formatter.string(from: NSNumber(value: taxAmount)) ?? "$0.00")\n"
            }
            
            textContent += "Category: \(receipt.category.rawValue)\n"
            textContent += "Status: \(receipt.submissionStatus.rawValue)\n"
            
            if let paymentMethod = receipt.paymentMethod {
                textContent += "Payment Method: \(paymentMethod)\n"
            }
            
            if !receipt.notes.isEmpty {
                textContent += "Notes: \(receipt.notes)\n"
            }
            
            textContent += "\n" + String(repeating: "-", count: 30) + "\n\n"
        }
        
        return saveToFile(content: textContent, filename: "receipts_export.txt")
    }
    
    private func exportAsJSON(_ receipts: [Receipt]) -> URL? {
        let dateFormatter = ISO8601DateFormatter()
        
        var jsonArray: [[String: Any]] = []
        
        for receipt in receipts {
            var receiptDict: [String: Any] = [
                "id": receipt.id.uuidString,
                "timestamp": dateFormatter.string(from: receipt.timestamp),
                "merchant": receipt.merchant,
                "amount": receipt.amount,
                "category": receipt.category.rawValue,
                "status": receipt.submissionStatus.rawValue,
                "notes": receipt.notes
            ]
            
            if let taxAmount = receipt.taxAmount {
                receiptDict["taxAmount"] = taxAmount
            }
            
            if let paymentMethod = receipt.paymentMethod {
                receiptDict["paymentMethod"] = paymentMethod
            }
            
            if let submissionDate = receipt.submissionDate {
                receiptDict["submissionDate"] = dateFormatter.string(from: submissionDate)
            }
            
            jsonArray.append(receiptDict)
        }
        
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: jsonArray, options: .prettyPrinted)
            if let jsonString = String(data: jsonData, encoding: .utf8) {
                return saveToFile(content: jsonString, filename: "receipts_export.json")
            }
        } catch {
            print("Failed to create JSON: \(error)")
        }
        
        return nil
    }
    
    
    
    private func formatDateForFilename(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd_HHmm"
        return formatter.string(from: date)
    }
    
    func saveToFile(content: String, filename: String) -> URL? {
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent(filename)
        
        do {
            try content.write(to: tempURL, atomically: true, encoding: .utf8)
            return tempURL
        } catch {
            print("Failed to save file: \(error)")
            return nil
        }
    }
    
    func createReceiptReport(_ receipts: [Receipt], groupBy: GroupingOption = .month) -> String {
        var report = "EXPENSE REPORT\n"
        report += "Generated: \(Date().formatted())\n"
        report += String(repeating: "=", count: 50) + "\n\n"
        
        let grouped = groupReceipts(receipts, by: groupBy)
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        
        for (key, groupReceipts) in grouped.sorted(by: { $0.key > $1.key }) {
            let total = groupReceipts.reduce(0) { $0 + $1.amount }
            report += "\(key)\n"
            report += "Total: \(formatter.string(from: NSNumber(value: total)) ?? "$0.00")\n"
            report += "Count: \(groupReceipts.count) receipts\n"
            
            let categories = Dictionary(grouping: groupReceipts) { $0.category }
            report += "By Category:\n"
            for (category, catReceipts) in categories.sorted(by: { $0.value.count > $1.value.count }) {
                let catTotal = catReceipts.reduce(0) { $0 + $1.amount }
                report += "  - \(category.rawValue): \(formatter.string(from: NSNumber(value: catTotal)) ?? "$0.00") (\(catReceipts.count) receipts)\n"
            }
            report += "\n"
        }
        
        let grandTotal = receipts.reduce(0) { $0 + $1.amount }
        report += String(repeating: "-", count: 50) + "\n"
        report += "GRAND TOTAL: \(formatter.string(from: NSNumber(value: grandTotal)) ?? "$0.00")\n"
        report += "TOTAL RECEIPTS: \(receipts.count)\n"
        
        return report
    }
    
    enum GroupingOption {
        case day, week, month, year
    }
    
    private func groupReceipts(_ receipts: [Receipt], by option: GroupingOption) -> [String: [Receipt]] {
        let formatter = DateFormatter()
        
        switch option {
        case .day:
            formatter.dateStyle = .medium
        case .week:
            formatter.dateFormat = "YYYY 'Week' w"
        case .month:
            formatter.dateFormat = "MMMM yyyy"
        case .year:
            formatter.dateFormat = "yyyy"
        }
        
        return Dictionary(grouping: receipts) { receipt in
            formatter.string(from: receipt.timestamp)
        }
    }
}