// AddExpenseView.swift
import SwiftUI
import SwiftData

struct AddExpenseView: View {
    var preselectedCard: CreditCard? = nil
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CreditCard.sortOrder) private var cards: [CreditCard]
    
    @State private var amountString = ""
    @State private var merchant = ""
    @State private var selectedCategory: TransactionCategory = .shopping
    @State private var selectedCard: CreditCard? = nil
    @State private var date = Date()
    @State private var notes = ""
    @State private var isRecurring = false
    @State private var showFullMode = false
    @State private var showSaved = false
    
    private var amount: Decimal {
        Decimal(string: amountString) ?? 0
    }
    private var canSave: Bool { amount > 0 && selectedCard != nil }
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Amount display
                amountDisplay
                
                ScrollView {
                    VStack(spacing: 0) {
                        // Category picker
                        categoryPicker
                            .padding(.bottom, 8)
                        
                        // Card selector
                        cardSelector
                            .padding(.bottom, 8)
                        
                        if showFullMode {
                            fullModeFields
                        }
                        
                        // Toggle full mode
                        Button {
                            withAnimation { showFullMode.toggle() }
                        } label: {
                            Label(showFullMode ? "Modo rápido" : "Más detalles",
                                  systemImage: showFullMode ? "chevron.up" : "chevron.down")
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 12)
                    }
                }
                
                // Numpad
                numpad
                    .padding(.horizontal, 20)
                    .padding(.bottom, 8)
                
                // Save button
                Button {
                    saveExpense()
                } label: {
                    HStack {
                        if showSaved {
                            Image(systemName: "checkmark.circle.fill")
                        }
                        Text(showSaved ? "¡Guardado!" : "Registrar gasto")
                    }
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 18)
                    .background(canSave ? Color.accentColor : Color(.systemFill))
                    .foregroundColor(canSave ? .white : .secondary)
                    .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
                }
                .disabled(!canSave)
                .padding(.horizontal, 20)
                .padding(.bottom, 8)
                .animation(.spring(), value: showSaved)
            }
            .navigationTitle("Nuevo gasto")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .onAppear {
            selectedCard = preselectedCard ?? cards.first
        }
    }
    
    // MARK: - Amount Display
    private var amountDisplay: some View {
        VStack(spacing: 4) {
            Text(amountString.isEmpty ? "$0" : "$\(amountString)")
                .font(.system(size: 56, weight: .light))
                .foregroundColor(amountString.isEmpty ? .secondary : .primary)
                .minimumScaleFactor(0.5)
                .lineLimit(1)
                .animation(.spring(response: 0.3), value: amountString)
            Text("monto del gasto")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 24)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Category Picker
    private var categoryPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("CATEGORÍA")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
                .padding(.horizontal, 20)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(TransactionCategory.allCases, id: \.self) { cat in
                        Button {
                            selectedCategory = cat
                            LedgeHaptics.selection()
                        } label: {
                            HStack(spacing: 5) {
                                Image(systemName: cat.icon)
                                    .font(.system(size: 13))
                                Text(cat.rawValue)
                                    .font(.subheadline)
                            }
                            .padding(.horizontal, 14)
                            .padding(.vertical, 8)
                            .background(selectedCategory == cat ? Color.accentColor : Color(.secondarySystemGroupedBackground))
                            .foregroundColor(selectedCategory == cat ? .white : .primary)
                            .clipShape(Capsule())
                            .overlay(Capsule().stroke(selectedCategory == cat ? Color.clear : Color(.separator), lineWidth: 0.5))
                        }
                    }
                }
                .padding(.horizontal, 20)
            }
        }
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Card Selector
    private var cardSelector: some View {
        VStack(spacing: 0) {
            HStack {
                Text("Tarjeta")
                    .font(.body)
                Spacer()
                Menu {
                    ForEach(cards) { card in
                        Button(card.displayName) {
                            selectedCard = card
                        }
                    }
                } label: {
                    HStack(spacing: 6) {
                        if let card = selectedCard {
                            RoundedRectangle(cornerRadius: 3)
                                .fill(LinearGradient(colors: card.gradientColors, startPoint: .leading, endPoint: .trailing))
                                .frame(width: 20, height: 14)
                        }
                        Text(selectedCard?.displayName ?? "Seleccionar")
                            .foregroundColor(selectedCard == nil ? .secondary : .primary)
                        Image(systemName: "chevron.up.chevron.down")
                            .font(.system(size: 11))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
        }
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Full Mode
    private var fullModeFields: some View {
        VStack(spacing: 1) {
            HStack {
                Text("Comercio")
                    .font(.body)
                Spacer()
                TextField("Nombre del comercio", text: $merchant)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            
            HStack {
                Text("Fecha")
                    .font(.body)
                Spacer()
                DatePicker("", selection: $date, displayedComponents: .date)
                    .labelsHidden()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            
            HStack {
                Text("Recurrente")
                    .font(.body)
                Spacer()
                Toggle("", isOn: $isRecurring)
                    .labelsHidden()
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
            
            HStack(alignment: .top) {
                Text("Notas")
                    .font(.body)
                Spacer()
                TextField("Opcional", text: $notes, axis: .vertical)
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(.secondary)
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
        }
        .padding(.bottom, 8)
    }
    
    // MARK: - Numpad
    private var numpad: some View {
        LazyVGrid(columns: Array(repeating: GridItem(.flexible()), count: 3), spacing: 1) {
            ForEach(["1","2","3","4","5","6","7","8","9",".","0","⌫"], id: \.self) { key in
                Button {
                    handleNumpad(key)
                } label: {
                    Text(key)
                        .font(.system(size: 24, weight: .regular))
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color(.secondarySystemGroupedBackground))
                }
                .buttonStyle(.plain)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
    }
    
    private func handleNumpad(_ key: String) {
        LedgeHaptics.impact(.light)
        switch key {
        case "⌫":
            if !amountString.isEmpty { amountString.removeLast() }
        case ".":
            if !amountString.contains(".") { amountString += "." }
        default:
            if amountString.count < 9 { amountString += key }
        }
    }
    
    private func saveExpense() {
        guard let card = selectedCard, amount > 0 else { return }
        
        let tx = Transaction(
            amount: amount,
            merchant: merchant.isEmpty ? nil : merchant,
            category: selectedCategory,
            date: date,
            notes: notes.isEmpty ? nil : notes,
            isRecurring: isRecurring
        )
        tx.card = card
        modelContext.insert(tx)
        
        LedgeHaptics.notification(.success)
        showSaved = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            dismiss()
        }
    }
}

// MARK: - Add Payment View
struct AddPaymentView: View {
    var preselectedCard: CreditCard? = nil
    
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CreditCard.sortOrder) private var cards: [CreditCard]
    
    @State private var selectedCard: CreditCard? = nil
    @State private var paymentType: PaymentType = .partial
    @State private var customAmount = ""
    @State private var date = Date()
    @State private var sourceAccount = ""
    @State private var notes = ""
    
    private var paymentAmount: Decimal {
        guard let card = selectedCard else { return 0 }
        switch paymentType {
        case .minimum: return FinancialCalculator.minimumPayment(for: card)
        case .full: return card.currentBalance
        case .partial: return Decimal(string: customAmount) ?? 0
        }
    }
    
    private var canSave: Bool { paymentAmount > 0 && selectedCard != nil }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Tarjeta") {
                    Picker("Tarjeta", selection: $selectedCard) {
                        ForEach(cards) { card in
                            Text(card.displayName).tag(Optional(card))
                        }
                    }
                }
                
                Section("Tipo de pago") {
                    Picker("Tipo", selection: $paymentType) {
                        ForEach(PaymentType.allCases, id: \.self) { type in
                            Label(type.rawValue, systemImage: type.icon).tag(type)
                        }
                    }
                    .pickerStyle(.segmented)
                    
                    if paymentType == .partial {
                        HStack {
                            Text("Monto")
                            Spacer()
                            TextField("$0.00", text: $customAmount)
                                .keyboardType(.decimalPad)
                                .multilineTextAlignment(.trailing)
                        }
                    } else {
                        HStack {
                            Text("Monto")
                            Spacer()
                            Text(paymentAmount.currencyString)
                                .foregroundColor(.secondary)
                        }
                    }
                }
                
                Section("Detalles") {
                    DatePicker("Fecha", selection: $date, displayedComponents: .date)
                    HStack {
                        Text("Desde cuenta")
                        Spacer()
                        TextField("Opcional", text: $sourceAccount)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Notas")
                        Spacer()
                        TextField("Opcional", text: $notes)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                if let card = selectedCard {
                    Section("Resumen") {
                        HStack {
                            Text("Balance actual")
                            Spacer()
                            Text(card.currentBalance.currencyString).foregroundColor(.secondary)
                        }
                        HStack {
                            Text("Pago a registrar")
                            Spacer()
                            Text(paymentAmount.currencyString).foregroundColor(.green).bold()
                        }
                        HStack {
                            Text("Balance estimado")
                            Spacer()
                            Text(max(0, card.currentBalance - paymentAmount).currencyString).foregroundColor(.secondary)
                        }
                    }
                }
            }
            .navigationTitle("Registrar pago")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        savePayment()
                    }
                    .disabled(!canSave)
                }
            }
        }
        .onAppear {
            selectedCard = preselectedCard ?? cards.first
        }
    }
    
    private func savePayment() {
        guard let card = selectedCard, paymentAmount > 0 else { return }
        
        let payment = Payment(
            amount: paymentAmount,
            date: date,
            paymentType: paymentType,
            sourceAccount: sourceAccount.isEmpty ? nil : sourceAccount,
            notes: notes.isEmpty ? nil : notes
        )
        payment.card = card
        modelContext.insert(payment)
        
        LedgeHaptics.notification(.success)
        dismiss()
    }
}

// MARK: - Add Card View
struct AddCardView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \CreditCard.sortOrder) private var existingCards: [CreditCard]
    
    @State private var bankName = ""
    @State private var cardName = ""
    @State private var lastFourDigits = ""
    @State private var creditLimitString = ""
    @State private var cutoffDayString = ""
    @State private var paymentDueDayString = ""
    @State private var minPaymentString = ""
    @State private var aprString = ""
    @State private var selectedGradientIndex = 0
    @State private var notes = ""
    
    private var canSave: Bool {
        !bankName.isEmpty && !cardName.isEmpty &&
        lastFourDigits.count == 4 && (Decimal(string: creditLimitString) ?? 0) > 0 &&
        (Int(cutoffDayString) ?? 0).isBetween(1, 31) && (Int(paymentDueDayString) ?? 0).isBetween(1, 31)
    }
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Datos básicos") {
                    TextField("Nombre del banco", text: $bankName)
                    TextField("Nombre de la tarjeta", text: $cardName)
                    TextField("Últimos 4 dígitos", text: $lastFourDigits)
                        .keyboardType(.numberPad)
                        .onChange(of: lastFourDigits) { _, new in
                            if new.count > 4 { lastFourDigits = String(new.prefix(4)) }
                        }
                }
                
                Section("Límite y fechas") {
                    HStack {
                        Text("Límite de crédito")
                        Spacer()
                        TextField("$0", text: $creditLimitString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Día de corte")
                        Spacer()
                        TextField("1-31", text: $cutoffDayString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Día límite de pago")
                        Spacer()
                        TextField("1-31", text: $paymentDueDayString)
                            .keyboardType(.numberPad)
                            .multilineTextAlignment(.trailing)
                    }
                }
                
                Section("Opcional") {
                    HStack {
                        Text("Pago mínimo")
                        Spacer()
                        TextField("Automático", text: $minPaymentString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("APR (%)")
                        Spacer()
                        TextField("0.0", text: $aprString)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    TextField("Notas", text: $notes)
                }
                
                Section("Estilo visual") {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 10) {
                            ForEach(Array(LedgeDesign.cardGradients.enumerated()), id: \.offset) { idx, gradient in
                                ZStack {
                                    RoundedRectangle(cornerRadius: 10)
                                        .fill(LinearGradient(
                                            colors: [Color(hex: gradient.hex1), Color(hex: gradient.hex2)],
                                            startPoint: .topLeading, endPoint: .bottomTrailing
                                        ))
                                        .frame(width: 60, height: 40)
                                    if selectedGradientIndex == idx {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.white)
                                    }
                                }
                                .onTapGesture {
                                    selectedGradientIndex = idx
                                    LedgeHaptics.selection()
                                }
                            }
                        }
                        .padding(.vertical, 8)
                    }
                    Text(LedgeDesign.cardGradients[selectedGradientIndex].name)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }
            .navigationTitle("Nueva tarjeta")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Guardar") {
                        saveCard()
                    }
                    .disabled(!canSave)
                }
            }
        }
    }
    
    private func saveCard() {
        let gradient = LedgeDesign.cardGradients[selectedGradientIndex]
        let card = CreditCard(
            bankName: bankName,
            cardName: cardName,
            lastFourDigits: lastFourDigits,
            creditLimit: Decimal(string: creditLimitString) ?? 0,
            cutoffDay: Int(cutoffDayString) ?? 15,
            paymentDueDay: Int(paymentDueDayString) ?? 5,
            minimumPaymentAmount: Decimal(string: minPaymentString),
            apr: Double(aprString),
            colorHex: gradient.hex1,
            colorHex2: gradient.hex2,
            notes: notes.isEmpty ? nil : notes,
            sortOrder: existingCards.count
        )
        modelContext.insert(card)
        LedgeHaptics.notification(.success)
        dismiss()
    }
}

extension Int {
    func isBetween(_ a: Int, _ b: Int) -> Bool { self >= a && self <= b }
}
