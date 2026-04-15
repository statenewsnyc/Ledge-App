// MockData.swift
import Foundation
import SwiftUI

struct MockData {
    static let cards: [CreditCard] = {
        let bbva = CreditCard(
            bankName: "BBVA", cardName: "Azul", lastFourDigits: "4421",
            creditLimit: 20000, cutoffDay: 17, paymentDueDay: 7,
            minimumPaymentAmount: 680, apr: 36.0,
            colorHex: "#0078D4", colorHex2: "#00B0F0", sortOrder: 0
        )
        
        let santander = CreditCard(
            bankName: "Santander", cardName: "Zero", lastFourDigits: "7832",
            creditLimit: 15000, cutoffDay: 22, paymentDueDay: 12,
            minimumPaymentAmount: 315, apr: 29.0,
            colorHex: "#CC0000", colorHex2: "#FF4444", sortOrder: 1
        )
        
        let banamex = CreditCard(
            bankName: "Banamex", cardName: "Oro", lastFourDigits: "2219",
            creditLimit: 10000, cutoffDay: 28, paymentDueDay: 18,
            minimumPaymentAmount: 455, apr: 34.5,
            colorHex: "#B8860B", colorHex2: "#FFD700", sortOrder: 2
        )
        
        let hsbc = CreditCard(
            bankName: "HSBC", cardName: "2Now", lastFourDigits: "5500",
            creditLimit: 12000, cutoffDay: 5, paymentDueDay: 25,
            minimumPaymentAmount: 108, apr: 32.0,
            colorHex: "#CC0000", colorHex2: "#8B0000", sortOrder: 3
        )
        
        return [bbva, santander, banamex, hsbc]
    }()
    
    static func sampleTransactions(for card: CreditCard) -> [Transaction] {
        [
            Transaction(amount: 850, merchant: "Walmart", category: .shopping, date: Date()),
            Transaction(amount: 299, merchant: "Netflix", category: .subscriptions, date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!),
            Transaction(amount: 700, merchant: "Gasolinera", category: .transport, date: Calendar.current.date(byAdding: .day, value: -2, to: Date())!),
            Transaction(amount: 1200, merchant: "Amazon", category: .shopping, date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!),
            Transaction(amount: 320, merchant: "Uber Eats", category: .food, date: Calendar.current.date(byAdding: .day, value: -4, to: Date())!),
            Transaction(amount: 4200, merchant: "Aeromexico", category: .travel, date: Calendar.current.date(byAdding: .day, value: -7, to: Date())!),
        ]
    }
    
    static func insertSampleData(context: Any) {
        // Use this function to seed SwiftData context in preview
        // modelContext.insert(card) for each card and transaction
    }
}
