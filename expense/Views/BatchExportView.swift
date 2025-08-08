//
//  BatchExportView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI
import SwiftData

struct BatchExportView: View {
    @Query(sort: \Receipt.timestamp, order: .reverse) private var receipts: [Receipt]
    @Environment(\.dismiss) private var dismiss
    
    @State private var selectedFormat = ExportManager.ExportFormat.csv
    @State private var filterByStatus: SubmissionStatus?
    @State private var filterByCategory: ReceiptCategory?
    @State private var startDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var endDate = Date()
    @State private var showingShareSheet = false
    @State private var exportedURL: URL?
    @State private var showingReport = false
    @State private var reportText = ""
    
    var filteredReceipts: [Receipt] {
        receipts.filter { receipt in
            let dateInRange = receipt.timestamp >= startDate && receipt.timestamp <= endDate
            let matchesStatus = filterByStatus == nil || receipt.submissionStatus == filterByStatus
            let matchesCategory = filterByCategory == nil || receipt.category == filterByCategory
            return dateInRange && matchesStatus && matchesCategory
        }
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Export Format") {
                    Picker("Format", selection: $selectedFormat) {
                        Text("CSV (Spreadsheet)").tag(ExportManager.ExportFormat.csv)
                        Text("Text Report").tag(ExportManager.ExportFormat.text)
                        Text("JSON (Data)").tag(ExportManager.ExportFormat.json)
                    }
                    .pickerStyle(SegmentedPickerStyle())
                }
                
                Section("Date Range") {
                    DatePicker("From", selection: $startDate, displayedComponents: .date)
                    DatePicker("To", selection: $endDate, displayedComponents: .date)
                }
                
                Section("Filters") {
                    Picker("Status", selection: $filterByStatus) {
                        Text("All Statuses").tag(nil as SubmissionStatus?)
                        ForEach(SubmissionStatus.allCases, id: \.self) { status in
                            Text(status.rawValue).tag(status as SubmissionStatus?)
                        }
                    }
                    
                    Picker("Category", selection: $filterByCategory) {
                        Text("All Categories").tag(nil as ReceiptCategory?)
                        ForEach(ReceiptCategory.allCases, id: \.self) { category in
                            Text(category.rawValue).tag(category as ReceiptCategory?)
                        }
                    }
                }
                
                Section("Summary") {
                    HStack {
                        Text("Receipts to Export")
                        Spacer()
                        Text("\(filteredReceipts.count)")
                            .fontWeight(.semibold)
                    }
                    
                    HStack {
                        Text("Total Amount")
                        Spacer()
                        Text(formattedTotal)
                            .fontWeight(.semibold)
                    }
                }
                
                Section {
                    Button(action: generateReport) {
                        HStack {
                            Image(systemName: "doc.text")
                            Text("Generate Summary Report")
                        }
                    }
                    
                    Button(action: exportReceipts) {
                        HStack {
                            Image(systemName: "square.and.arrow.up")
                            Text("Export \(filteredReceipts.count) Receipts")
                        }
                    }
                    .disabled(filteredReceipts.isEmpty)
                }
            }
            .navigationTitle("Export Receipts")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingShareSheet) {
                if let url = exportedURL {
                    ShareSheet(items: [url])
                }
            }
            .sheet(isPresented: $showingReport) {
                NavigationStack {
                    ScrollView {
                        Text(reportText)
                            .font(.system(.body, design: .monospaced))
                            .padding()
                    }
                    .navigationTitle("Expense Report")
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .navigationBarTrailing) {
                            Button("Share") {
                                shareReport()
                            }
                        }
                        ToolbarItem(placement: .navigationBarLeading) {
                            Button("Done") {
                                showingReport = false
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var formattedTotal: String {
        let total = filteredReceipts.reduce(0) { $0 + $1.amount }
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: total)) ?? "$0.00"
    }
    
    private func exportReceipts() {
        exportedURL = ExportManager.shared.exportReceipts(filteredReceipts, format: selectedFormat)
        if exportedURL != nil {
            showingShareSheet = true
        }
    }
    
    private func generateReport() {
        reportText = ExportManager.shared.createReceiptReport(filteredReceipts, groupBy: .month)
        showingReport = true
    }
    
    private func shareReport() {
        if let url = ExportManager.shared.saveToFile(content: reportText, filename: "expense_report.txt") {
            exportedURL = url
            showingShareSheet = true
        }
    }
}