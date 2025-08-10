//
//  ReceiptListView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI
import SwiftData

struct ReceiptListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Receipt.timestamp, order: .reverse) private var allReceipts: [Receipt]
    
    @State private var searchText = ""
    @State private var selectedCategory: ReceiptCategory?
    @State private var selectedStatus: SubmissionStatus?
    @State private var showingFilters = false
    @State private var selectedReceipt: Receipt?
    @State private var showingBatchExport = false
    @State private var showingIconExporter = false
    @State private var showUnprocessed = false
    
    private var receipts: [Receipt] {
        allReceipts.filter { showUnprocessed || $0.isProcessed }
    }
    
    var filteredReceipts: [Receipt] {
        receipts.filter { receipt in
            let matchesSearch = searchText.isEmpty || 
                receipt.merchant.localizedCaseInsensitiveContains(searchText) ||
                receipt.notes.localizedCaseInsensitiveContains(searchText)
            
            let matchesCategory = selectedCategory == nil || receipt.category == selectedCategory
            let matchesStatus = selectedStatus == nil || receipt.submissionStatus == selectedStatus
            
            return matchesSearch && matchesCategory && matchesStatus
        }
    }
    
    var groupedReceipts: [(String, [Receipt])] {
        Dictionary(grouping: filteredReceipts) { receipt in
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: receipt.timestamp)
        }
        .sorted { $0.value.first?.timestamp ?? Date() > $1.value.first?.timestamp ?? Date() }
        .map { ($0.key, $0.value) }
    }
    
    var totalAmount: Double {
        filteredReceipts.reduce(0) { $0 + $1.amount }
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if !receipts.isEmpty {
                summaryHeader
            }
            
            if receipts.isEmpty {
                emptyState
            } else {
                List {
                    ForEach(groupedReceipts, id: \.0) { date, dayReceipts in
                        Section(header: sectionHeader(date: date, count: dayReceipts.count)) {
                            ForEach(dayReceipts) { receipt in
                                ReceiptRowView(receipt: receipt)
                                    .contentShape(Rectangle())
                                    .onTapGesture {
                                        selectedReceipt = receipt
                                    }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            deleteReceipt(receipt)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        if receipt.submissionStatus == .pending {
                                            Button {
                                                markAsSubmitted(receipt)
                                            } label: {
                                                Label("Submit", systemImage: "paperplane")
                                            }
                                            .tint(.blue)
                                        }
                                    }
                            }
                        }
                    }
                }
                .searchable(text: $searchText, prompt: "Search receipts...")
            }
        }
        .navigationTitle("Receipt History")
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button(action: { showingFilters.toggle() }) {
                        Label("Filter", systemImage: "line.3.horizontal.decrease.circle")
                            .symbolVariant(hasActiveFilters ? .fill : .none)
                    }
                    Button(action: { showingBatchExport.toggle() }) {
                        Label("Export", systemImage: "square.and.arrow.up")
                    }
                    Divider()
                    Button(action: { showingIconExporter.toggle() }) {
                        Label("App Icon", systemImage: "app.badge")
                    }
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilters) {
            NavigationStack {
                FilterView(
                    selectedCategory: $selectedCategory,
                    selectedStatus: $selectedStatus,
                    showUnprocessed: $showUnprocessed
                )
            }
        }
        .sheet(item: $selectedReceipt) { receipt in
            NavigationStack {
                ReceiptDetailView(receipt: receipt)
            }
        }
        .sheet(isPresented: $showingBatchExport) {
            BatchExportView()
        }
        .sheet(isPresented: $showingIconExporter) {
            AppIconExporter()
        }
    }
    
    private var summaryHeader: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading) {
                    Text("Total Expenses")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(formattedAmount(totalAmount))
                        .font(.title2)
                        .fontWeight(.bold)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    Text("\(filteredReceipts.count) receipts")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    if hasActiveFilters {
                        Text("Filtered")
                            .font(.caption2)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 2)
                            .background(Color.blue.opacity(0.2))
                            .cornerRadius(4)
                    }
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 12)
            
            Divider()
        }
        .background(Color(.systemBackground))
    }
    
    private func sectionHeader(date: String, count: Int) -> some View {
        HStack {
            Text(date)
                .font(.headline)
            Spacer()
            Text("\(count) receipt\(count == 1 ? "" : "s")")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "camera.on.rectangle")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Receipts Yet")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Tap the camera tab to capture your first receipt")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    private var hasActiveFilters: Bool {
        selectedCategory != nil || selectedStatus != nil
    }
    
    private func formattedAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func deleteReceipt(_ receipt: Receipt) {
        withAnimation {
            modelContext.delete(receipt)
            try? modelContext.save()
        }
    }
    
    private func markAsSubmitted(_ receipt: Receipt) {
        withAnimation {
            receipt.submissionStatus = .submitted
            receipt.submissionDate = Date()
            try? modelContext.save()
        }
    }
}

struct ReceiptRowView: View {
    let receipt: Receipt
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack(alignment: .topLeading) {
                if let imageData = receipt.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(width: 60, height: 60)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                } else {
                    RoundedRectangle(cornerRadius: 8)
                        .fill(Color.gray.opacity(0.2))
                        .frame(width: 60, height: 60)
                        .overlay(
                            Image(systemName: "photo")
                                .foregroundColor(.gray)
                        )
                }
                
                if !receipt.isProcessed {
                    Image(systemName: "exclamationmark.circle.fill")
                        .font(.caption2)
                        .foregroundColor(.orange)
                        .background(Circle().fill(Color.white).padding(-2))
                        .offset(x: -4, y: -4)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(receipt.merchant.isEmpty && !receipt.isProcessed ? "Unprocessed" : receipt.merchant)
                        .font(.headline)
                        .lineLimit(1)
                        .foregroundColor(receipt.merchant.isEmpty && !receipt.isProcessed ? .secondary : .primary)
                }
                
                HStack {
                    Label(receipt.category.rawValue, systemImage: receipt.category.icon)
                        .font(.caption)
                        .foregroundColor(receipt.category.color)
                    
                    Spacer()
                    
                    Text(receipt.formattedAmount)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                }
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 4) {
                Image(systemName: receipt.submissionStatus.icon)
                    .foregroundColor(receipt.submissionStatus.color)
                    .font(.caption)
                
                Text(receipt.timestamp, style: .time)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

struct FilterView: View {
    @Binding var selectedCategory: ReceiptCategory?
    @Binding var selectedStatus: SubmissionStatus?
    @Binding var showUnprocessed: Bool
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        Form {
            Section("Display Options") {
                Toggle("Show Unprocessed Receipts", isOn: $showUnprocessed)
            }
            
            Section("Category") {
                ForEach([nil] + ReceiptCategory.allCases.map { $0 as ReceiptCategory? }, id: \.self) { category in
                    HStack {
                        if let cat = category {
                            Label(cat.rawValue, systemImage: cat.icon)
                                .foregroundColor(cat.color)
                        } else {
                            Label("All Categories", systemImage: "square.grid.2x2")
                        }
                        
                        Spacer()
                        
                        if selectedCategory == category {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedCategory = category
                    }
                }
            }
            
            Section("Status") {
                ForEach([nil] + SubmissionStatus.allCases.map { $0 as SubmissionStatus? }, id: \.self) { status in
                    HStack {
                        if let stat = status {
                            Label(stat.rawValue, systemImage: stat.icon)
                                .foregroundColor(stat.color)
                        } else {
                            Label("All Statuses", systemImage: "circle.grid.2x2")
                        }
                        
                        Spacer()
                        
                        if selectedStatus == status {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        selectedStatus = status
                    }
                }
            }
        }
        .navigationTitle("Filters")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Clear") {
                    selectedCategory = nil
                    selectedStatus = nil
                    showUnprocessed = false
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Done") {
                    dismiss()
                }
                .fontWeight(.semibold)
            }
        }
    }
}