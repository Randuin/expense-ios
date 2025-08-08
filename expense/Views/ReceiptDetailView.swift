//
//  ReceiptDetailView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI
import SwiftData

struct ReceiptDetailView: View {
    @Bindable var receipt: Receipt
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    
    @State private var isEditing = false
    @State private var showingShareSheet = false
    @State private var showingDeleteAlert = false
    @State private var exportedURL: URL?
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if let imageData = receipt.imageData,
                   let image = UIImage(data: imageData) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .cornerRadius(12)
                        .shadow(radius: 3)
                        .padding(.horizontal)
                        .onTapGesture {
                            // Could implement full-screen image viewer here
                        }
                }
                
                VStack(spacing: 16) {
                    detailSection
                    statusSection
                    if !receipt.notes.isEmpty {
                        notesSection
                    }
                    actionButtons
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(isEditing ? "Done" : "Edit") {
                    withAnimation {
                        isEditing.toggle()
                    }
                }
            }
        }
        .sheet(isPresented: $showingShareSheet) {
            if let url = exportedURL {
                ShareSheet(items: [url])
            }
        }
        .alert("Delete Receipt", isPresented: $showingDeleteAlert) {
            Button("Delete", role: .destructive) {
                deleteReceipt()
            }
            Button("Cancel", role: .cancel) { }
        } message: {
            Text("Are you sure you want to delete this receipt? This action cannot be undone.")
        }
    }
    
    private var detailSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Details")
                .font(.headline)
                .foregroundColor(.secondary)
            
            VStack(spacing: 12) {
                DetailRow(
                    label: "Merchant",
                    value: receipt.merchant,
                    icon: "building.2",
                    isEditing: isEditing,
                    onEdit: { newValue in
                        receipt.merchant = newValue
                        saveChanges()
                    }
                )
                
                DetailRow(
                    label: "Amount",
                    value: receipt.formattedAmount,
                    icon: "dollarsign.circle",
                    isEditing: false
                )
                
                if let taxAmount = receipt.taxAmount, taxAmount > 0 {
                    DetailRow(
                        label: "Tax",
                        value: formatAmount(taxAmount),
                        icon: "percent",
                        isEditing: false
                    )
                }
                
                HStack {
                    Label("Category", systemImage: "tag")
                        .foregroundColor(.secondary)
                        .frame(width: 100, alignment: .leading)
                    
                    if isEditing {
                        Menu {
                            ForEach(ReceiptCategory.allCases, id: \.self) { cat in
                                Button(action: { 
                                    receipt.category = cat
                                    saveChanges()
                                }) {
                                    Label(cat.rawValue, systemImage: cat.icon)
                                }
                            }
                        } label: {
                            HStack {
                                Image(systemName: receipt.category.icon)
                                    .foregroundColor(receipt.category.color)
                                Text(receipt.category.rawValue)
                                Spacer()
                                Image(systemName: "chevron.down")
                                    .font(.caption)
                            }
                            .padding(8)
                            .background(Color(.systemGray6))
                            .cornerRadius(6)
                        }
                    } else {
                        HStack {
                            Image(systemName: receipt.category.icon)
                                .foregroundColor(receipt.category.color)
                            Text(receipt.category.rawValue)
                        }
                    }
                }
                
                DetailRow(
                    label: "Date",
                    value: receipt.formattedDate,
                    icon: "calendar",
                    isEditing: false
                )
                
                if let paymentMethod = receipt.paymentMethod {
                    DetailRow(
                        label: "Payment",
                        value: paymentMethod,
                        icon: "creditcard",
                        isEditing: isEditing,
                        onEdit: { newValue in
                            receipt.paymentMethod = newValue
                            saveChanges()
                        }
                    )
                }
            }
            .padding()
            .background(Color(.systemGray6))
            .cornerRadius(12)
        }
    }
    
    private var statusSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Submission Status")
                .font(.headline)
                .foregroundColor(.secondary)
            
            HStack {
                Image(systemName: receipt.submissionStatus.icon)
                    .foregroundColor(receipt.submissionStatus.color)
                Text(receipt.submissionStatus.rawValue)
                    .fontWeight(.semibold)
                
                Spacer()
                
                if let submissionDate = receipt.submissionDate {
                    Text(submissionDate, style: .date)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .padding()
            .background(receipt.submissionStatus.color.opacity(0.1))
            .cornerRadius(12)
            
            if isEditing {
                HStack(spacing: 8) {
                    ForEach(SubmissionStatus.allCases, id: \.self) { status in
                        Button(action: {
                            receipt.submissionStatus = status
                            if status == .submitted {
                                receipt.submissionDate = Date()
                            }
                            saveChanges()
                        }) {
                            Text(status.rawValue)
                                .font(.caption)
                                .padding(.horizontal, 12)
                                .padding(.vertical, 6)
                                .background(receipt.submissionStatus == status ? status.color : Color(.systemGray5))
                                .foregroundColor(receipt.submissionStatus == status ? .white : .primary)
                                .cornerRadius(6)
                        }
                    }
                }
            }
        }
    }
    
    private var notesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Notes")
                .font(.headline)
                .foregroundColor(.secondary)
            
            if isEditing {
                TextEditor(text: Binding(
                    get: { receipt.notes },
                    set: { 
                        receipt.notes = $0
                        saveChanges()
                    }
                ))
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
            } else {
                Text(receipt.notes)
                    .padding()
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: exportReceipt) {
                Label("Export Receipt", systemImage: "square.and.arrow.up")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(12)
            }
            
            if receipt.submissionStatus == .pending {
                Button(action: submitToBookkeeper) {
                    Label("Submit to Bookkeeper", systemImage: "paperplane.fill")
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.green)
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
            }
            
            Button(action: { showingDeleteAlert = true }) {
                Label("Delete Receipt", systemImage: "trash")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color(.systemGray5))
                    .foregroundColor(.red)
                    .cornerRadius(12)
            }
        }
        .padding(.top)
    }
    
    private func formatAmount(_ amount: Double) -> String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = Locale.current
        return formatter.string(from: NSNumber(value: amount)) ?? "$0.00"
    }
    
    private func saveChanges() {
        try? modelContext.save()
    }
    
    private func exportReceipt() {
        // Create a simple text representation
        var exportText = """
        Receipt Details
        ===============
        
        Merchant: \(receipt.merchant)
        Date: \(receipt.formattedDate)
        Amount: \(receipt.formattedAmount)
        """
        
        if let taxAmount = receipt.taxAmount {
            exportText += "\nTax: \(formatAmount(taxAmount))"
        }
        
        exportText += """
        
        Category: \(receipt.category.rawValue)
        Status: \(receipt.submissionStatus.rawValue)
        """
        
        if let paymentMethod = receipt.paymentMethod {
            exportText += "\nPayment Method: \(paymentMethod)"
        }
        
        if !receipt.notes.isEmpty {
            exportText += "\n\nNotes:\n\(receipt.notes)"
        }
        
        // Save to temporary file
        let tempURL = FileManager.default.temporaryDirectory.appendingPathComponent("receipt_\(receipt.id).txt")
        
        do {
            try exportText.write(to: tempURL, atomically: true, encoding: .utf8)
            exportedURL = tempURL
            showingShareSheet = true
        } catch {
            print("Failed to export receipt: \(error)")
        }
    }
    
    private func submitToBookkeeper() {
        receipt.submissionStatus = .submitted
        receipt.submissionDate = Date()
        saveChanges()
        
        // In a real app, this would send the receipt data to an API or email
        // For now, we just update the status
    }
    
    private func deleteReceipt() {
        modelContext.delete(receipt)
        try? modelContext.save()
        dismiss()
    }
}

struct DetailRow: View {
    let label: String
    let value: String
    let icon: String
    let isEditing: Bool
    var onEdit: ((String) -> Void)?
    
    @State private var editValue: String = ""
    
    var body: some View {
        HStack {
            Label(label, systemImage: icon)
                .foregroundColor(.secondary)
                .frame(width: 100, alignment: .leading)
            
            if isEditing, let onEdit = onEdit {
                TextField(label, text: $editValue)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .onAppear { editValue = value }
                    .onChange(of: editValue) { _, newValue in
                        onEdit(newValue)
                    }
            } else {
                Text(value)
                    .fontWeight(.medium)
            }
            
            Spacer()
        }
    }
}

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}