// NotificationService.swift
import UserNotifications
import Foundation

@MainActor
class NotificationService {
    static let shared = NotificationService()
    
    func requestPermission() async {
        try? await UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .badge, .sound])
    }
    
    func scheduleCardAlerts(for cards: [CreditCard]) async {
        let center = UNUserNotificationCenter.current()
        center.removeAllPendingNotificationRequests()
        
        for card in cards {
            await scheduleCutoffAlert(for: card)
            await schedulePaymentAlert(for: card)
            
            if card.utilizationRate >= 80 {
                await scheduleHighUtilizationAlert(for: card)
            }
        }
    }
    
    private func scheduleCutoffAlert(for card: CreditCard) async {
        let cutoffDate = card.nextCutoffDate
        guard let alertDate = Calendar.current.date(byAdding: .day, value: -3, to: cutoffDate),
              alertDate > Date() else { return }
        
        let content = UNMutableNotificationContent()
        content.title = "Corte próximo — \(card.displayName)"
        content.body = "Tu tarjeta cierra en 3 días. Balance actual: \(card.currentBalance.currencyString)"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "cutoff-\(card.id)", content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func schedulePaymentAlert(for card: CreditCard) async {
        let paymentDate = card.nextPaymentDate
        guard let alertDate = Calendar.current.date(byAdding: .day, value: -2, to: paymentDate),
              alertDate > Date() else { return }
        
        let minPayment = FinancialCalculator.minimumPayment(for: card)
        let content = UNMutableNotificationContent()
        content.title = "⚠️ Pago próximo — \(card.displayName)"
        content.body = "Pago mínimo: \(minPayment.currencyString). Fecha límite: \(FinancialCalculator.formatDate(paymentDate))"
        content.sound = .default
        
        let components = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: alertDate)
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "payment-\(card.id)", content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
    
    private func scheduleHighUtilizationAlert(for card: CreditCard) async {
        let content = UNMutableNotificationContent()
        content.title = "🔴 Uso alto — \(card.displayName)"
        content.body = "Estás usando el \(Int(card.utilizationRate))% de tu límite. Considera hacer un pago."
        content.sound = .default
        
        var components = DateComponents()
        components.hour = 10
        components.minute = 0
        let trigger = UNCalendarNotificationTrigger(dateMatching: components, repeats: false)
        let request = UNNotificationRequest(identifier: "util-\(card.id)", content: content, trigger: trigger)
        
        try? await UNUserNotificationCenter.current().add(request)
    }
}
