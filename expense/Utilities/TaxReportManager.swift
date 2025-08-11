//
//  TaxReportManager.swift
//  expense
//
//  Created by Claude on 8/10/25.
//

import Foundation
import SwiftData

struct TaxReportManager {
    
    /// Generate a tax summary for a specific year
    static func generateTaxSummary(for receipts: [Receipt], taxYear: Int) -> TaxSummary {
        let yearReceipts = receipts.filter { $0.taxYear == taxYear }
        
        var categoryTotals: [ReceiptCategory: Double] = [:]
        var categoryDeductibles: [ReceiptCategory: Double] = [:]
        var totalAmount: Double = 0
        var totalDeductible: Double = 0
        
        for receipt in yearReceipts {
            categoryTotals[receipt.category, default: 0] += receipt.amount
            categoryDeductibles[receipt.category, default: 0] += receipt.taxDeductibleAmount
            totalAmount += receipt.amount
            totalDeductible += receipt.taxDeductibleAmount
        }
        
        return TaxSummary(
            taxYear: taxYear,
            totalExpenses: totalAmount,
            totalDeductible: totalDeductible,
            categoryBreakdown: categoryTotals,
            categoryDeductibles: categoryDeductibles,
            receiptCount: yearReceipts.count
        )
    }
    
    /// Generate QuickBooks-compatible CSV export
    static func generateQuickBooksCSV(for receipts: [Receipt]) -> String {
        let header = "Date,Account,Vendor,Amount,Description\n"
        let sortedReceipts = receipts.sorted { $0.timestamp < $1.timestamp }
        
        let csvRows = sortedReceipts.map { receipt in
            receipt.quickBooksExportString
        }.joined(separator: "\n")
        
        return header + csvRows
    }
    
    /// Generate IRS Schedule C summary
    static func generateScheduleCSummary(for receipts: [Receipt], taxYear: Int) -> ScheduleCSummary {
        let yearReceipts = receipts.filter { $0.taxYear == taxYear }
        
        var scheduleCLines: [String: Double] = [:]
        
        for receipt in yearReceipts {
            let lineItem = receipt.category.scheduleCAteory
            scheduleCLines[lineItem, default: 0] += receipt.taxDeductibleAmount
        }
        
        return ScheduleCSummary(
            taxYear: taxYear,
            lineItems: scheduleCLines,
            totalDeductions: scheduleCLines.values.reduce(0, +)
        )
    }
    
    /// Generate quarterly tax report
    static func generateQuarterlyReport(for receipts: [Receipt], year: Int, quarter: Int) -> QuarterlyReport {
        let quarterReceipts = receipts.filter { receipt in
            let receiptYear = receipt.taxYear
            let receiptQuarter = Calendar.current.quarter(from: receipt.timestamp)
            return receiptYear == year && receiptQuarter == quarter
        }
        
        let totalExpenses = quarterReceipts.reduce(0) { $0 + $1.amount }
        let totalDeductible = quarterReceipts.reduce(0) { $0 + $1.taxDeductibleAmount }
        
        var categoryBreakdown: [ReceiptCategory: Double] = [:]
        for receipt in quarterReceipts {
            categoryBreakdown[receipt.category, default: 0] += receipt.taxDeductibleAmount
        }
        
        return QuarterlyReport(
            year: year,
            quarter: quarter,
            totalExpenses: totalExpenses,
            totalDeductible: totalDeductible,
            categoryBreakdown: categoryBreakdown,
            receiptCount: quarterReceipts.count
        )
    }
}

// MARK: - Report Data Structures

struct TaxSummary {
    let taxYear: Int
    let totalExpenses: Double
    let totalDeductible: Double
    let categoryBreakdown: [ReceiptCategory: Double]
    let categoryDeductibles: [ReceiptCategory: Double]
    let receiptCount: Int
    
    var formattedTotalExpenses: String {
        return formatCurrency(totalExpenses)
    }
    
    var formattedTotalDeductible: String {
        return formatCurrency(totalDeductible)
    }
    
    var deductiblePercentage: Double {
        guard totalExpenses > 0 else { return 0 }
        return (totalDeductible / totalExpenses) * 100
    }
    
    private func formatCurrency(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
}

struct ScheduleCSummary {
    let taxYear: Int
    let lineItems: [String: Double]
    let totalDeductions: Double
    
    var formattedTotalDeductions: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalDeductions)) ?? "$0.00"
    }
}

struct QuarterlyReport {
    let year: Int
    let quarter: Int
    let totalExpenses: Double
    let totalDeductible: Double
    let categoryBreakdown: [ReceiptCategory: Double]
    let receiptCount: Int
    
    var quarterName: String {
        return "Q\(quarter) \(year)"
    }
    
    var formattedTotalExpenses: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalExpenses)) ?? "$0.00"
    }
    
    var formattedTotalDeductible: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: totalDeductible)) ?? "$0.00"
    }
}

// MARK: - Calendar Extension for Quarter

extension Calendar {
    func quarter(from date: Date) -> Int {
        let month = self.component(.month, from: date)
        return (month - 1) / 3 + 1
    }
}