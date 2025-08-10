//
//  BacklogView.swift
//  expense
//
//  Created by Assistant on 8/8/25.
//

import SwiftUI
import SwiftData

struct BacklogView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var syncManager: SyncManager
    @EnvironmentObject private var authManager: AuthManager
    @Query(filter: #Predicate<Receipt> { !$0.isProcessed }, sort: \Receipt.timestamp, order: .reverse) 
    private var unprocessedReceipts: [Receipt]
    
    @State private var receiptToEdit: Receipt?
    @State private var selectedReceipts: Set<Receipt> = []
    @State private var isSelecting = false
    
    private let columns = [
        GridItem(.flexible()),
        GridItem(.flexible())
    ]
    
    var body: some View {
        NavigationStack {
            ZStack {
                if unprocessedReceipts.isEmpty {
                    emptyState
                } else {
                    ScrollView {
                        LazyVGrid(columns: columns, spacing: 16) {
                            ForEach(unprocessedReceipts) { receipt in
                                ReceiptThumbnail(
                                    receipt: receipt,
                                    isSelected: selectedReceipts.contains(receipt),
                                    isSelecting: isSelecting
                                ) {
                                    if isSelecting {
                                        toggleSelection(receipt)
                                    } else {
                                        receiptToEdit = receipt
                                    }
                                }
                                .contextMenu {
                                    contextMenuButtons(for: receipt)
                                }
                            }
                        }
                        .padding()
                    }
                    .refreshable {
                        if authManager.isAuthenticated {
                            await syncManager.performFullSync()
                        }
                    }
                }
            }
            .navigationTitle("Backlog")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                toolbarContent
            }
            .sheet(item: $receiptToEdit) { receipt in
                if let imageData = receipt.imageData,
                   let image = UIImage(data: imageData) {
                    NavigationStack {
                        ReceiptEditView(
                            image: image,
                            modelContext: modelContext,
                            receipt: receipt
                        ) {
                            receiptToEdit = nil
                        }
                    }
                } else {
                    VStack {
                        Text("Error: Unable to load receipt image")
                            .foregroundColor(.red)
                            .padding()
                        Button("Close") {
                            receiptToEdit = nil
                        }
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                }
            }
        }
    }
    
    private var emptyState: some View {
        VStack(spacing: 20) {
            Image(systemName: "tray")
                .font(.system(size: 60))
                .foregroundColor(.gray)
            
            Text("No Photos to Process")
                .font(.title2)
                .fontWeight(.semibold)
            
            Text("Captured photos will appear here for processing")
                .font(.body)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
    
    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            if !unprocessedReceipts.isEmpty {
                Text("\(unprocessedReceipts.count) to process")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        
        ToolbarItem(placement: .navigationBarTrailing) {
            if !unprocessedReceipts.isEmpty {
                if isSelecting {
                    Button("Done") {
                        withAnimation {
                            isSelecting = false
                            selectedReceipts.removeAll()
                        }
                    }
                } else {
                    Menu {
                        Button(action: { 
                            withAnimation {
                                isSelecting = true
                            }
                        }) {
                            Label("Select", systemImage: "checkmark.circle")
                        }
                        
                        Button(action: processAll) {
                            Label("Process All", systemImage: "text.badge.checkmark")
                        }
                        .disabled(unprocessedReceipts.isEmpty)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
            }
        }
        
        if isSelecting && !selectedReceipts.isEmpty {
            ToolbarItem(placement: .bottomBar) {
                HStack {
                    Button(role: .destructive, action: deleteSelected) {
                        Label("Delete", systemImage: "trash")
                    }
                    
                    Spacer()
                    
                    Text("\(selectedReceipts.count) selected")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    
                    Spacer()
                    
                    Button(action: processSelected) {
                        Label("Process", systemImage: "text.badge.checkmark")
                    }
                }
            }
        }
    }
    
    @ViewBuilder
    private func contextMenuButtons(for receipt: Receipt) -> some View {
        Button(action: {
            receiptToEdit = receipt
        }) {
            Label("Process", systemImage: "text.badge.checkmark")
        }
        
        Button(role: .destructive, action: {
            deleteReceipt(receipt)
        }) {
            Label("Delete", systemImage: "trash")
        }
    }
    
    private func toggleSelection(_ receipt: Receipt) {
        withAnimation(.spring(duration: 0.3)) {
            if selectedReceipts.contains(receipt) {
                selectedReceipts.remove(receipt)
            } else {
                selectedReceipts.insert(receipt)
            }
        }
    }
    
    private func deleteReceipt(_ receipt: Receipt) {
        withAnimation {
            modelContext.delete(receipt)
            try? modelContext.save()
        }
    }
    
    private func deleteSelected() {
        withAnimation {
            for receipt in selectedReceipts {
                modelContext.delete(receipt)
            }
            try? modelContext.save()
            selectedReceipts.removeAll()
            isSelecting = false
        }
    }
    
    private func processSelected() {
        // For now, just mark the first one for editing
        // In a future enhancement, could create a batch processing view
        if let firstReceipt = selectedReceipts.first {
            receiptToEdit = firstReceipt
            selectedReceipts.removeAll()
            isSelecting = false
        }
    }
    
    private func processAll() {
        // For now, just mark the first one for editing
        // In a future enhancement, could create a batch processing view
        if let firstReceipt = unprocessedReceipts.first {
            receiptToEdit = firstReceipt
        }
    }
}

struct ReceiptThumbnail: View {
    let receipt: Receipt
    let isSelected: Bool
    let isSelecting: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            ZStack(alignment: .topTrailing) {
                if let imageData = receipt.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.blue : Color.clear, lineWidth: 3)
                        )
                } else {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color.gray.opacity(0.2))
                        .frame(height: 200)
                        .overlay(
                            Image(systemName: "photo")
                                .font(.largeTitle)
                                .foregroundColor(.gray)
                        )
                }
                
                VStack(alignment: .trailing) {
                    if isSelecting {
                        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                            .font(.title2)
                            .foregroundColor(isSelected ? .blue : .white)
                            .background(Circle().fill(Color.black.opacity(0.5)).padding(-4))
                            .padding(8)
                    }
                    
                    Spacer()
                    
                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                        Text(receipt.timestamp, style: .relative)
                            .font(.caption)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(Color.black.opacity(0.7))
                    .foregroundColor(.white)
                    .cornerRadius(8)
                    .padding(8)
                }
            }
        }
        .buttonStyle(PlainButtonStyle())
    }
}

