//
//  ReceiptEditView.swift
//  expense
//
//  Created by Robin Liao on 8/7/25.
//

import SwiftUI
import SwiftData

struct ReceiptEditView: View {
    let image: UIImage
    let modelContext: ModelContext
    var receipt: Receipt?  // Optional - if provided, we're editing an existing receipt
    var onSave: () -> Void
    
    @State private var merchant: String
    @State private var amount: String
    @State private var taxAmount: String
    @State private var category: ReceiptCategory
    @State private var notes: String
    @State private var paymentMethod: String
    @State private var date: Date
    @State private var showingDatePicker = false
    
    init(image: UIImage, modelContext: ModelContext, receipt: Receipt? = nil, onSave: @escaping () -> Void) {
        self.image = image
        self.modelContext = modelContext
        self.receipt = receipt
        self.onSave = onSave
        
        // Initialize state based on whether we're editing or creating
        if let receipt = receipt {
            _merchant = State(initialValue: receipt.merchant)
            _amount = State(initialValue: receipt.amount > 0 ? String(format: "%.2f", receipt.amount) : "")
            _taxAmount = State(initialValue: receipt.taxAmount != nil ? String(format: "%.2f", receipt.taxAmount!) : "")
            _category = State(initialValue: receipt.category)
            _notes = State(initialValue: receipt.notes)
            _paymentMethod = State(initialValue: receipt.paymentMethod ?? "")
            _date = State(initialValue: receipt.timestamp)
        } else {
            _merchant = State(initialValue: "")
            _amount = State(initialValue: "")
            _taxAmount = State(initialValue: "")
            _category = State(initialValue: .other)
            _notes = State(initialValue: "")
            _paymentMethod = State(initialValue: "")
            _date = State(initialValue: Date())
        }
    }
    
    @Environment(\.dismiss) private var dismiss
    @FocusState private var focusedField: Field?
    
    enum Field {
        case merchant, amount, tax, notes, payment
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                receiptImageView
                
                VStack(spacing: 16) {
                    merchantField
                    amountFields
                    categoryPicker
                    paymentField
                    datePicker
                    notesField
                }
                .padding(.horizontal)
            }
            .padding(.vertical)
        }
        .navigationTitle("Receipt Details")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button("Save") {
                    saveReceipt()
                }
                .fontWeight(.semibold)
                .disabled(merchant.isEmpty || amount.isEmpty)
            }
        }
        .onAppear {
            focusedField = .merchant
        }
    }
    
    private var receiptImageView: some View {
        Image(uiImage: image)
            .resizable()
            .scaledToFit()
            .frame(maxHeight: 250)
            .cornerRadius(12)
            .shadow(radius: 3)
            .padding(.horizontal)
    }
    
    private var merchantField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Merchant", systemImage: "building.2")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Store or Business Name", text: $merchant)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .merchant)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .amount
                }
        }
    }
    
    private var amountFields: some View {
        HStack(spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Label("Amount", systemImage: "dollarsign.circle")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $amount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .amount)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                Label("Tax", systemImage: "percent")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextField("0.00", text: $taxAmount)
                    .textFieldStyle(RoundedBorderTextFieldStyle())
                    .keyboardType(.decimalPad)
                    .focused($focusedField, equals: .tax)
            }
        }
    }
    
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Category", systemImage: "tag")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Menu {
                ForEach(ReceiptCategory.allCases, id: \.self) { cat in
                    Button(action: { category = cat }) {
                        Label(cat.rawValue, systemImage: cat.icon)
                    }
                }
            } label: {
                HStack {
                    Image(systemName: category.icon)
                        .foregroundColor(category.color)
                    Text(category.rawValue)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
        }
    }
    
    private var paymentField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Payment Method", systemImage: "creditcard")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextField("Cash, Credit Card, etc.", text: $paymentMethod)
                .textFieldStyle(RoundedBorderTextFieldStyle())
                .focused($focusedField, equals: .payment)
                .submitLabel(.next)
                .onSubmit {
                    focusedField = .notes
                }
        }
    }
    
    private var datePicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Date", systemImage: "calendar")
                .font(.caption)
                .foregroundColor(.secondary)
            
            Button(action: { showingDatePicker.toggle() }) {
                HStack {
                    Text(date, style: .date)
                    Spacer()
                    Image(systemName: "chevron.down")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemGray6))
                .cornerRadius(8)
            }
            .foregroundColor(.primary)
            
            if showingDatePicker {
                DatePicker("", selection: $date, displayedComponents: .date)
                    .datePickerStyle(GraphicalDatePickerStyle())
                    .padding(.top, 8)
            }
        }
    }
    
    private var notesField: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("Notes", systemImage: "note.text")
                .font(.caption)
                .foregroundColor(.secondary)
            
            TextEditor(text: $notes)
                .frame(minHeight: 80)
                .padding(8)
                .background(Color(.systemGray6))
                .cornerRadius(8)
                .focused($focusedField, equals: .notes)
        }
    }
    
    private func saveReceipt() {
        let amountValue = Double(amount) ?? 0.0
        let taxValue = taxAmount.isEmpty ? nil : Double(taxAmount)
        
        if let existingReceipt = receipt {
            // Update existing receipt
            existingReceipt.merchant = merchant
            existingReceipt.amount = amountValue
            existingReceipt.category = category
            existingReceipt.notes = notes
            existingReceipt.taxAmount = taxValue
            existingReceipt.paymentMethod = paymentMethod.isEmpty ? nil : paymentMethod
            existingReceipt.timestamp = date
            existingReceipt.isProcessed = true
        } else {
            // Create new receipt
            let newReceipt = Receipt(
                timestamp: date,
                imageData: image.jpegData(compressionQuality: 0.8),
                amount: amountValue,
                merchant: merchant,
                category: category,
                notes: notes,
                taxAmount: taxValue,
                paymentMethod: paymentMethod.isEmpty ? nil : paymentMethod,
                isProcessed: true
            )
            modelContext.insert(newReceipt)
        }
        
        do {
            try modelContext.save()
            onSave()
            dismiss()
        } catch {
            print("Failed to save receipt: \(error)")
        }
    }
}