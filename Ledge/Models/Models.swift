// Models.swift
import SwiftUI
import SwiftData
import Foundation

// MARK: - CreditCard
@Model
final class CreditCard {
    var id: UUID
    var bankName: String
    var cardName: String
    var lastFourDigits: String
    var creditLimit: Decimal
    var cutoffDay: Int          // Day of month (1-31)
    var paymentDueDay: Int      // Day of month
    var minimumPaymentAmount: Decimal?
    var apr: Double?
    var colorHex: String        // Primary gradient color
    var colorHex2: String?      // Secondary gradient color
    var notes: String?
    var isFavorite: Bool
    var sortOrder: Int
    var createdAt: Date
    
    @Relationship(deleteRule: .cascade, inverse: \Transaction.card)
    var transactions: [Transaction] = []
    
    @Relationship(deleteRule: .cascade, inverse: \Payment.card)
    var payments: [Payment] = []
    
    @Relationship(deleteRule: .cascade, inverse: \BillingCycle.card)
    var billingCycles: [BillingCycle] = []
    
    init(bankName: String, cardName: String, lastFourDigits: String,
         creditLimit: Decimal, cutoffDay: Int, paymentDueDay: Int,
         minimumPaymentAmount: Decimal? = nil, apr: Double? = nil,
         colorHex: String = "#007AFF", colorHex2: String? = nil,
         notes: String? = nil, isFavorite: Bool = false, sortOrder: Int = 0) {
        self.id = UUID()
        self.bankName = bankName
        self.cardName = cardName
        self.lastFourDigits = lastFourDigits
        self.creditLimit = creditLimit
        self.cutoffDay = cutoffDay
        self.paymentDueDay = paymentDueDay
        self.minimumPaymentAmount = minimumPaymentAmount
        self.apr = apr
        self.colorHex = colorHex
        self.colorHex2 = colorHex2
        self.notes = notes
        self.isFavorite = isFavorite
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
    
    // Computed: current balance from active cycle transactions and payments
    var currentBalance: Decimal {
        let cycleStart = FinancialCalculator.currentCycleStartDate(cutoffDay: cutoffDay)
        let cycleTransactions = transactions.filter { $0.date >= cycleStart }
        let cyclePayments = payments.filter { $0.date >= cycleStart }
        let totalSpent = cycleTransactions.reduce(Decimal(0)) { $0 + $1.amount }
        let totalPaid = cyclePayments.reduce(Decimal(0)) { $0 + $1.amount }
        return max(0, totalSpent - totalPaid)
    }
    
    var availableCredit: Decimal {
        return max(0, creditLimit - currentBalance)
    }
    
    var utilizationRate: Double {
        guard creditLimit > 0 else { return 0 }
        return Double(truncating: (currentBalance / creditLimit * 100) as NSDecimalNumber)
    }
    
    var riskLevel: RiskLevel {
        switch utilizationRate {
        case ..<30: return .healthy
        case 30..<60: return .moderate
        case 60..<90: return .high
        default: return .critical
        }
    }
    
    var nextCutoffDate: Date {
        FinancialCalculator.nextOccurrence(ofDay: cutoffDay)
    }
    
    var nextPaymentDate: Date {
        FinancialCalculator.nextOccurrence(ofDay: paymentDueDay, after: nextCutoffDate)
    }
    
    var daysUntilCutoff: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextCutoffDate).day ?? 0
    }
    
    var daysUntilPayment: Int {
        Calendar.current.dateComponents([.day], from: Date(), to: nextPaymentDate).day ?? 0
    }
    
    var gradientColors: [Color] {
        var colors: [Color] = [Color(hex: colorHex)]
        if let hex2 = colorHex2 { colors.append(Color(hex: hex2)) }
        else { colors.append(Color(hex: colorHex).opacity(0.7)) }
        return colors
    }
    
    var displayName: String { "\(bankName) \(cardName)" }
    var maskedNumber: String { "•••• \(lastFourDigits)" }
}

// MARK: - Transaction
@Model
final class Transaction {
    var id: UUID
    var amount: Decimal
    var merchant: String?
    var category: TransactionCategory
    var date: Date
    var notes: String?
    var isRecurring: Bool
    var installments: Int?
    var installmentNumber: Int?
    var tag: String?
    
    var card: CreditCard?
    var billingCycle: BillingCycle?
    
    init(amount: Decimal, merchant: String? = nil,
         category: TransactionCategory = .other, date: Date = Date(),
         notes: String? = nil, isRecurring: Bool = false,
         installments: Int? = nil, tag: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.merchant = merchant
        self.category = category
        self.date = date
        self.notes = notes
        self.isRecurring = isRecurring
        self.installments = installments
        self.tag = tag
    }
    
    var displayMerchant: String { merchant ?? "Sin nombre" }
}

// MARK: - Payment
@Model
final class Payment {
    var id: UUID
    var amount: Decimal
    var date: Date
    var paymentType: PaymentType
    var sourceAccount: String?
    var notes: String?
    
    var card: CreditCard?
    var billingCycle: BillingCycle?
    
    init(amount: Decimal, date: Date = Date(), paymentType: PaymentType = .partial,
         sourceAccount: String? = nil, notes: String? = nil) {
        self.id = UUID()
        self.amount = amount
        self.date = date
        self.paymentType = paymentType
        self.sourceAccount = sourceAccount
        self.notes = notes
    }
}

// MARK: - BillingCycle
@Model
final class BillingCycle {
    var id: UUID
    var startDate: Date
    var cutoffDate: Date
    var paymentDueDate: Date
    var openingBalance: Decimal
    var closingBalance: Decimal?
    var isPaid: Bool
    
    var card: CreditCard?
    
    @Relationship(inverse: \Transaction.billingCycle)
    var transactions: [Transaction] = []
    
    @Relationship(inverse: \Payment.billingCycle)
    var payments: [Payment] = []
    
    init(startDate: Date, cutoffDate: Date, paymentDueDate: Date,
         openingBalance: Decimal = 0) {
        self.id = UUID()
        self.startDate = startDate
        self.cutoffDate = cutoffDate
        self.paymentDueDate = paymentDueDate
        self.openingBalance = openingBalance
        self.closingBalance = nil
        self.isPaid = false
    }
}

// MARK: - Enums
enum TransactionCategory: String, Codable, CaseIterable {
    case food = "Comida"
    case transport = "Transporte"
    case entertainment = "Entretenimiento"
    case health = "Salud"
    case shopping = "Compras"
    case utilities = "Servicios"
    case travel = "Viajes"
    case education = "Educación"
    case subscriptions = "Suscripciones"
    case other = "Otro"
    
    var icon: String {
        switch self {
        case .food: return "fork.knife"
        case .transport: return "car.fill"
        case .entertainment: return "theatermasks.fill"
        case .health: return "cross.fill"
        case .shopping: return "bag.fill"
        case .utilities: return "bolt.fill"
        case .travel: return "airplane"
        case .education: return "book.fill"
        case .subscriptions: return "repeat"
        case .other: return "ellipsis.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .food: return .green
        case .transport: return .blue
        case .entertainment: return .purple
        case .health: return .red
        case .shopping: return .orange
        case .utilities: return .yellow
        case .travel: return .cyan
        case .education: return .indigo
        case .subscriptions: return .pink
        case .other: return .gray
        }
    }
    
    var emoji: String {
        switch self {
        case .food: return "🍔"
        case .transport: return "🚗"
        case .entertainment: return "🎬"
        case .health: return "💊"
        case .shopping: return "🛒"
        case .utilities: return "💡"
        case .travel: return "✈️"
        case .education: return "📚"
        case .subscriptions: return "📺"
        case .other: return "📌"
        }
    }
}

enum PaymentType: String, Codable, CaseIterable {
    case minimum = "Mínimo"
    case partial = "Parcial"
    case full = "Total"
    
    var icon: String {
        switch self {
        case .minimum: return "arrow.down.circle"
        case .partial: return "minus.circle"
        case .full: return "checkmark.circle.fill"
        }
    }
    
    var color: Color {
        switch self {
        case .minimum: return .orange
        case .partial: return .blue
        case .full: return .green
        }
    }
}

enum RiskLevel {
    case healthy, moderate, high, critical
    
    var color: Color {
        switch self {
        case .healthy: return .green
        case .moderate: return .yellow
        case .high: return .orange
        case .critical: return .red
        }
    }
    
    var label: String {
        switch self {
        case .healthy: return "Saludable"
        case .moderate: return "Moderado"
        case .high: return "Alto"
        case .critical: return "Crítico"
        }
    }
}
