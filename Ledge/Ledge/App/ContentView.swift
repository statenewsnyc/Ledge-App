// ContentView.swift
import SwiftUI

struct ContentView: View {
    @State private var selectedTab: Tab = .home
    @State private var showQuickAdd = false
    
    enum Tab {
        case home, wallet, calendar, analytics
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                HomeView()
                    .tag(Tab.home)
                
                WalletView()
                    .tag(Tab.wallet)
                
                FinancialCalendarView()
                    .tag(Tab.calendar)
                
                AnalyticsView()
                    .tag(Tab.analytics)
            }
            // Hide default tab bar
            .toolbar(.hidden, for: .tabBar)
            
            // Custom tab bar
            CustomTabBar(selectedTab: $selectedTab, showQuickAdd: $showQuickAdd)
        }
        .sheet(isPresented: $showQuickAdd) {
            QuickAddSheet()
        }
        .ignoresSafeArea(edges: .bottom)
    }
}

// MARK: - Custom Tab Bar
struct CustomTabBar: View {
    @Binding var selectedTab: ContentView.Tab
    @Binding var showQuickAdd: Bool
    
    var body: some View {
        HStack(spacing: 0) {
            TabBarItem(icon: "house.fill", label: "Inicio", isActive: selectedTab == .home) {
                selectedTab = .home
            }
            TabBarItem(icon: "creditcard.fill", label: "Wallet", isActive: selectedTab == .wallet) {
                selectedTab = .wallet
            }
            
            // FAB Center Button
            Button {
                showQuickAdd = true
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            } label: {
                ZStack {
                    Circle()
                        .fill(Color.accentColor)
                        .frame(width: 52, height: 52)
                        .shadow(color: Color.accentColor.opacity(0.35), radius: 8, y: 4)
                    Image(systemName: "plus")
                        .font(.system(size: 22, weight: .semibold))
                        .foregroundColor(.white)
                }
            }
            .frame(maxWidth: .infinity)
            .offset(y: -8)
            
            TabBarItem(icon: "calendar", label: "Agenda", isActive: selectedTab == .calendar) {
                selectedTab = .calendar
            }
            TabBarItem(icon: "chart.bar.fill", label: "Analytics", isActive: selectedTab == .analytics) {
                selectedTab = .analytics
            }
        }
        .padding(.horizontal, 8)
        .padding(.top, 10)
        .padding(.bottom, 24)
        .background(
            Rectangle()
                .fill(.regularMaterial)
                .ignoresSafeArea()
                .overlay(
                    Rectangle()
                        .frame(height: 0.5)
                        .foregroundColor(Color(.separator)),
                    alignment: .top
                )
        )
    }
}

struct TabBarItem: View {
    let icon: String
    let label: String
    let isActive: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.system(size: 20))
                    .foregroundColor(isActive ? .accentColor : Color(.secondaryLabel))
                Text(label)
                    .font(.system(size: 10, weight: .medium))
                    .foregroundColor(isActive ? .accentColor : Color(.secondaryLabel))
            }
        }
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Quick Add Sheet
struct QuickAddSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showAddExpense = false
    @State private var showAddPayment = false
    @State private var showAddCard = false
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Text("¿Qué quieres registrar?")
                    .font(.headline)
                    .padding(.top, 24)
                    .padding(.bottom, 8)
                
                VStack(spacing: 1) {
                    QuickAddOption(icon: "dollarsign.circle.fill", iconColor: .red,
                                  title: "Registrar gasto", subtitle: "Agregar una compra") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAddExpense = true }
                    }
                    QuickAddOption(icon: "arrow.down.circle.fill", iconColor: .green,
                                  title: "Registrar pago", subtitle: "Pago a tarjeta") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAddPayment = true }
                    }
                    QuickAddOption(icon: "plus.circle.fill", iconColor: .blue,
                                  title: "Nueva tarjeta", subtitle: "Agregar tarjeta de crédito") {
                        dismiss()
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { showAddCard = true }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.top, 16)
                
                Spacer()
            }
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancelar") { dismiss() }
                }
            }
        }
        .presentationDetents([.fraction(0.38)])
        .presentationDragIndicator(.visible)
        .sheet(isPresented: $showAddExpense) { AddExpenseView() }
        .sheet(isPresented: $showAddPayment) { AddPaymentView() }
        .sheet(isPresented: $showAddCard) { AddCardView() }
    }
}

struct QuickAddOption: View {
    let icon: String
    let iconColor: Color
    let title: String
    let subtitle: String
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(iconColor)
                    .frame(width: 36)
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.body)
                        .foregroundColor(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(Color(.tertiaryLabel))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }
}
