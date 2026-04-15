// LedgeApp.swift
import SwiftUI
import SwiftData

@main
struct LedgeApp: App {
    let modelContainer: ModelContainer
    
    init() {
        let schema = Schema([CreditCard.self, Transaction.self, Payment.self, BillingCycle.self])
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        do {
            modelContainer = try ModelContainer(for: schema, configurations: [config])
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(modelContainer)
        }
    }
}
