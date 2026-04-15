// WalletView.swift
import SwiftUI
import SwiftData

struct WalletView: View {
    @Query(sort: \CreditCard.sortOrder) private var cards: [CreditCard]
    @State private var selectedCard: CreditCard? = nil
    @State private var showAddCard = false
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 20) {
                    if cards.isEmpty {
                        EmptyStateView(
                            icon: "creditcard.fill",
                            title: "Sin tarjetas",
                            subtitle: "Agrega tu primera tarjeta para empezar a controlar tus gastos",
                            actionTitle: "Agregar tarjeta"
                        ) { showAddCard = true }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 60)
                    } else {
                        // Card stack
                        CardStackView(cards: cards) { card in
                            selectedCard = card
                        }
                        .padding(.top, 8)
                        
                        // Summary section
                        VStack(alignment: .leading, spacing: 12) {
                            SectionHeader(title: "Resumen")
                            
                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                                StatCard(label: "Deuda total",
                                         value: FinancialCalculator.totalDebt(cards: cards).currencyString)
                                StatCard(label: "Utilización",
                                         value: String(format: "%.0f%%", FinancialCalculator.overallUtilization(cards: cards)),
                                         valueColor: utilizationColor)
                            }
                            .padding(.horizontal, LedgeDesign.pagePadding)
                        }
                        
                        // Cards list
                        VStack(alignment: .leading, spacing: 10) {
                            SectionHeader(title: "Todas las tarjetas")
                            
                            VStack(spacing: 0) {
                                ForEach(cards) { card in
                                    Button {
                                        selectedCard = card
                                    } label: {
                                        CardRowView(card: card)
                                            .padding(.horizontal, 16)
                                    }
                                    .buttonStyle(.plain)
                                    
                                    if card.id != cards.last?.id {
                                        Divider().padding(.leading, 68)
                                    }
                                }
                            }
                            .background(Color(.secondarySystemGroupedBackground))
                            .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
                            .padding(.horizontal, LedgeDesign.pagePadding)
                        }
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Wallet")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAddCard = true } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                    }
                }
            }
            .navigationDestination(item: $selectedCard) { card in
                CardDetailView(card: card)
            }
            .sheet(isPresented: $showAddCard) { AddCardView() }
        }
    }
    
    private var utilizationColor: Color {
        let util = FinancialCalculator.overallUtilization(cards: cards)
        return util >= 60 ? .orange : util >= 30 ? .yellow : .green
    }
}

// MARK: - Card Detail View
struct CardDetailView: View {
    let card: CreditCard
    @State private var selectedTab = 0
    @State private var showAddExpense = false
    @State private var showAddPayment = false
    
    private var cycleTransactions: [Transaction] {
        let start = FinancialCalculator.currentCycleStartDate(cutoffDay: card.cutoffDay)
        return card.transactions.filter { $0.date >= start }.sorted { $0.date > $1.date }
    }
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 0) {
                // Mini card header
                CreditCardView(card: card, isCompact: false)
                    .padding(.horizontal, LedgeDesign.pagePadding)
                    .padding(.top, 8)
                    .padding(.bottom, 20)
                
                // Balance row
                balanceSection
                    .padding(.horizontal, LedgeDesign.pagePadding)
                    .padding(.bottom, 20)
                
                // Info grid
                infoGrid
                    .padding(.horizontal, LedgeDesign.pagePadding)
                    .padding(.bottom, 20)
                
                // Action buttons
                actionButtons
                    .padding(.horizontal, LedgeDesign.pagePadding)
                    .padding(.bottom, 24)
                
                // Transactions
                transactionsSection
                
                Spacer(minLength: 100)
            }
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(card.displayName)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showAddExpense) { AddExpenseView(preselectedCard: card) }
        .sheet(isPresented: $showAddPayment) { AddPaymentView(preselectedCard: card) }
    }
    
    // MARK: - Balance Section
    private var balanceSection: some View {
        VStack(spacing: 14) {
            HStack(alignment: .bottom) {
                VStack(alignment: .leading, spacing: 2) {
                    Text("Balance actual")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    Text(card.currentBalance.currencyString)
                        .font(.system(size: 36, weight: .bold))
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text("Disponible")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(card.availableCredit.currencyString)
                        .font(.title3.bold())
                        .foregroundColor(.green)
                }
            }
            
            VStack(spacing: 6) {
                HStack {
                    Text("Usando \(String(format: "%.0f", card.utilizationRate))% de \(card.creditLimit.currencyString)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(card.riskLevel.label)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(card.riskLevel.color)
                }
                UtilizationBar(value: card.utilizationRate, height: 10)
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
    }
    
    // MARK: - Info Grid
    private var infoGrid: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 1) {
            infoCell(label: "Límite", value: card.creditLimit.currencyString)
            infoCell(label: "Pago mínimo",
                     value: (card.minimumPaymentAmount ?? FinancialCalculator.minimumPayment(for: card)).currencyString)
            infoCell(label: "Fecha de corte", value: "Día \(card.cutoffDay)")
            infoCell(label: "Fecha límite pago", value: "Día \(card.paymentDueDay)")
        }
        .background(Color(.separator))
        .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
        .overlay(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius).stroke(Color(.separator), lineWidth: 0.5))
    }
    
    private func infoCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label)
                .font(.system(size: 10, weight: .semibold))
                .foregroundColor(.secondary)
                .textCase(.uppercase)
                .tracking(0.5)
            Text(value)
                .font(.headline)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Actions
    private var actionButtons: some View {
        HStack(spacing: 12) {
            Button {
                showAddExpense = true
                LedgeHaptics.impact(.medium)
            } label: {
                Label("Registrar gasto", systemImage: "plus.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.accentColor)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
            }
            
            Button {
                showAddPayment = true
                LedgeHaptics.impact(.medium)
            } label: {
                Label("Pagar", systemImage: "arrow.down.circle.fill")
                    .font(.subheadline.weight(.semibold))
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Color.green)
                    .foregroundColor(.white)
                    .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
            }
        }
    }
    
    // MARK: - Transactions
    private var transactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Ciclo actual")
            
            if cycleTransactions.isEmpty {
                Text("Sin gastos en este ciclo")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
                    .padding(.horizontal, LedgeDesign.pagePadding)
            } else {
                VStack(spacing: 0) {
                    ForEach(cycleTransactions) { tx in
                        TransactionRowView(transaction: tx)
                        if tx.id != cycleTransactions.last?.id {
                            Divider().padding(.leading, 72)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
                .padding(.horizontal, LedgeDesign.pagePadding)
            }
        }
    }
}

#Preview {
    NavigationStack {
        CardDetailView(card: MockData.cards[0])
            .modelContainer(for: [CreditCard.self, Transaction.self, Payment.self], inMemory: true)
    }
}
