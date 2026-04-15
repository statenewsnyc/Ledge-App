// HomeView.swift
import SwiftUI
import SwiftData

struct HomeView: View {
    @Query(sort: \CreditCard.sortOrder) private var cards: [CreditCard]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    
    private var totalDebt: Decimal { FinancialCalculator.totalDebt(cards: cards) }
    private var totalAvailable: Decimal { FinancialCalculator.totalAvailableCredit(cards: cards) }
    private var utilization: Double { FinancialCalculator.overallUtilization(cards: cards) }
    private var upcomingEvents: [FinancialCalculator.UpcomingEvent] {
        FinancialCalculator.upcomingEvents(cards: cards)
    }
    private var recentTransactions: [Transaction] {
        Array(allTransactions.prefix(5))
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Hero section
                    heroSection
                        .padding(.bottom, 20)
                    
                    // Stats row
                    statsRow
                        .padding(.bottom, 20)
                    
                    // Upcoming events
                    if !upcomingEvents.isEmpty {
                        upcomingSection
                            .padding(.bottom, 20)
                    }
                    
                    // Recent transactions
                    if !recentTransactions.isEmpty {
                        recentTransactionsSection
                    }
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Ledge")
                        .font(.headline)
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button { } label: {
                        Image(systemName: "bell")
                            .font(.system(size: 16))
                    }
                }
            }
        }
    }
    
    // MARK: - Hero
    private var heroSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                Text(totalDebt.currencyString)
                    .font(.system(size: 42, weight: .bold, design: .default))
                    .minimumScaleFactor(0.7)
                    .lineLimit(1)
                Text("deuda total en \(cards.count) tarjeta\(cards.count == 1 ? "" : "s")")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
            
            VStack(spacing: 6) {
                HStack {
                    Text("Utilización")
                        .font(.caption.weight(.medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(String(format: "%.0f%%", utilization))
                        .font(.caption.weight(.bold))
                        .foregroundColor(utilizationColor)
                }
                UtilizationBar(value: utilization, height: 8)
            }
        }
        .padding(20)
        .background(Color(.secondarySystemGroupedBackground))
    }
    
    // MARK: - Stats
    private var statsRow: some View {
        LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
            StatCard(label: "Disponible", value: totalAvailable.currencyString, valueColor: .green)
            StatCard(label: "Gastos del mes", value: monthlySpending.currencyString)
        }
        .padding(.horizontal, LedgeDesign.pagePadding)
    }
    
    // MARK: - Upcoming
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Próximos eventos")
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 10) {
                    ForEach(upcomingEvents) { event in
                        UpcomingEventChip(event: event)
                    }
                }
                .padding(.horizontal, LedgeDesign.pagePadding)
            }
        }
    }
    
    // MARK: - Recent Transactions
    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Gastos recientes")
            
            VStack(spacing: 0) {
                ForEach(recentTransactions) { tx in
                    TransactionRowView(transaction: tx)
                    if tx.id != recentTransactions.last?.id {
                        Divider().padding(.leading, 72)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
            .padding(.horizontal, LedgeDesign.pagePadding)
        }
    }
    
    // MARK: - Helpers
    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12: return "Buenos días ☀️"
        case 12..<18: return "Buenas tardes 👋"
        default: return "Buenas noches 🌙"
        }
    }
    
    private var utilizationColor: Color {
        switch utilization {
        case ..<30: return .green
        case 30..<60: return .orange
        default: return .red
        }
    }
    
    private var monthlySpending: Decimal {
        FinancialCalculator.monthlySpending(transactions: allTransactions)
    }
}

// MARK: - Upcoming Event Chip
struct UpcomingEventChip: View {
    let event: FinancialCalculator.UpcomingEvent
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            HStack(spacing: 4) {
                Image(systemName: event.type.icon)
                    .font(.system(size: 11, weight: .semibold))
                    .foregroundColor(event.urgencyColor)
                Text(event.type.label)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(event.urgencyColor)
            }
            Text(event.card.displayName)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.primary)
            Text(FinancialCalculator.relativeDate(event.date))
                .font(.caption)
                .foregroundColor(event.urgencyColor)
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(event.daysAway <= 3 ? event.urgencyColor.opacity(0.3) : Color.clear, lineWidth: 1)
        )
    }
}

// MARK: - Transaction Row
struct TransactionRowView: View {
    let transaction: Transaction
    
    var body: some View {
        HStack(spacing: 12) {
            // Category icon
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(transaction.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(transaction.category.color)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.displayMerchant)
                    .font(.subheadline.weight(.medium))
                Text(transaction.category.rawValue)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text("-\(transaction.amount.currencyString)")
                    .font(.subheadline.weight(.semibold))
                Text(relativeDate(transaction.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
    
    private func relativeDate(_ date: Date) -> String {
        if Calendar.current.isDateInToday(date) { return "Hoy" }
        if Calendar.current.isDateInYesterday(date) { return "Ayer" }
        let formatter = DateFormatter()
        formatter.dateFormat = "d MMM"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: date)
    }
}

#Preview {
    HomeView()
        .modelContainer(for: [CreditCard.self, Transaction.self, Payment.self], inMemory: true)
}
