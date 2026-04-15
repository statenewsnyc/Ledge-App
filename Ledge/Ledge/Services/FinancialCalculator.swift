// FinancialCalculator.swift
import Foundation

struct FinancialCalculator {
    
    // MARK: - Cycle Dates
    
    /// Returns the start date of the current billing cycle based on cutoff day
    static func currentCycleStartDate(cutoffDay: Int) -> Date {
        let calendar = Calendar.current
        let today = Date()
        let currentDay = calendar.component(.day, from: today)
        
        var components = calendar.dateComponents([.year, .month], from: today)
        
        if currentDay > cutoffDay {
            // Cycle started this month on cutoffDay
            components.day = cutoffDay + 1
        } else {
            // Cycle started last month
            if components.month == 1 {
                components.month = 12
                components.year = (components.year ?? 2024) - 1
            } else {
                components.month = (components.month ?? 1) - 1
            }
            components.day = cutoffDay + 1
        }
        
        return calendar.date(from: components) ?? today
    }
    
    /// Next occurrence of a given day of month (today or future)
    static func nextOccurrence(ofDay day: Int, after date: Date = Date()) -> Date {
        let calendar = Calendar.current
        let currentDay = calendar.component(.day, from: date)
        var components = calendar.dateComponents([.year, .month], from: date)
        
        if currentDay < day {
            components.day = day
            return calendar.date(from: components) ?? date
        } else {
            // Next month
            if (components.month ?? 1) == 12 {
                components.month = 1
                components.year = (components.year ?? 2024) + 1
            } else {
                components.month = (components.month ?? 1) + 1
            }
            components.day = day
            return calendar.date(from: components) ?? date
        }
    }
    
    // MARK: - Totals
    
    static func totalDebt(cards: [CreditCard]) -> Decimal {
        cards.reduce(Decimal(0)) { $0 + $1.currentBalance }
    }
    
    static func totalAvailableCredit(cards: [CreditCard]) -> Decimal {
        cards.reduce(Decimal(0)) { $0 + $1.availableCredit }
    }
    
    static func totalCreditLimit(cards: [CreditCard]) -> Decimal {
        cards.reduce(Decimal(0)) { $0 + $1.creditLimit }
    }
    
    static func overallUtilization(cards: [CreditCard]) -> Double {
        let totalLimit = totalCreditLimit(cards: cards)
        guard totalLimit > 0 else { return 0 }
        let totalDebtVal = totalDebt(cards: cards)
        return Double(truncating: (totalDebtVal / totalLimit * 100) as NSDecimalNumber)
    }
    
    // MARK: - Monthly spending
    
    static func monthlySpending(transactions: [Transaction], month: Date = Date()) -> Decimal {
        let calendar = Calendar.current
        let monthTxs = transactions.filter {
            calendar.isDate($0.date, equalTo: month, toGranularity: .month)
        }
        return monthTxs.reduce(Decimal(0)) { $0 + $1.amount }
    }
    
    static func spendingByCategory(transactions: [Transaction]) -> [TransactionCategory: Decimal] {
        var result: [TransactionCategory: Decimal] = [:]
        for tx in transactions {
            result[tx.category, default: 0] += tx.amount
        }
        return result
    }
    
    // MARK: - Upcoming Events
    
    struct UpcomingEvent: Identifiable {
        let id = UUID()
        let card: CreditCard
        let type: EventType
        let date: Date
        var daysAway: Int {
            Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        }
        
        enum EventType {
            case cutoff, payment
            var icon: String { self == .cutoff ? "scissors" : "creditcard.fill" }
            var label: String { self == .cutoff ? "Corte" : "Pago" }
        }
        
        var urgencyColor: Color {
            switch daysAway {
            case ...3: return .red
            case 4...7: return .orange
            default: return .secondary
            }
        }
    }
    
    static func upcomingEvents(cards: [CreditCard], days: Int = 30) -> [UpcomingEvent] {
        var events: [UpcomingEvent] = []
        let cutoff = Calendar.current.date(byAdding: .day, value: days, to: Date()) ?? Date()
        
        for card in cards {
            let cutoffDate = card.nextCutoffDate
            let paymentDate = card.nextPaymentDate
            
            if cutoffDate <= cutoff {
                events.append(UpcomingEvent(card: card, type: .cutoff, date: cutoffDate))
            }
            if paymentDate <= cutoff {
                events.append(UpcomingEvent(card: card, type: .payment, date: paymentDate))
            }
        }
        
        return events.sorted { $0.date < $1.date }
    }
    
    // MARK: - Minimum Payment
    
    static func minimumPayment(for card: CreditCard) -> Decimal {
        if let min = card.minimumPaymentAmount { return min }
        // Default: 1.5% of balance or $200, whichever is greater
        let percentage = card.currentBalance * Decimal(0.015)
        return max(percentage, 200)
    }
    
    // MARK: - Risk Assessment
    
    static func financialHealthScore(cards: [CreditCard]) -> Int {
        // 0-100 score
        let util = overallUtilization(cards: cards)
        let baseScore = max(0, Int(100 - util))
        
        // Penalty for cards over 90%
        let criticalCards = cards.filter { $0.riskLevel == .critical }.count
        let penalty = criticalCards * 10
        
        return max(0, baseScore - penalty)
    }
    
    // MARK: - Date formatting
    
    static func formatDate(_ date: Date, style: DateFormatter.Style = .medium) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = style
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: date)
    }
    
    static func relativeDate(_ date: Date) -> String {
        let days = Calendar.current.dateComponents([.day], from: Date(), to: date).day ?? 0
        switch days {
        case 0: return "Hoy"
        case 1: return "Mañana"
        case 2...6: return "en \(days) días"
        default: return formatDate(date, style: .short)
        }
    }
}
