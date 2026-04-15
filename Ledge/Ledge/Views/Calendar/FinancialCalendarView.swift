// FinancialCalendarView.swift
import SwiftUI
import SwiftData

struct FinancialCalendarView: View {
    @Query(sort: \CreditCard.sortOrder) private var cards: [CreditCard]
    @State private var selectedDate: Date? = nil
    @State private var currentMonth = Date()
    
    private var calendar = Calendar.current
    
    private var upcomingEvents: [FinancialCalculator.UpcomingEvent] {
        FinancialCalculator.upcomingEvents(cards: cards, days: 60)
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 0) {
                    // Calendar grid
                    calendarSection
                        .padding(.bottom, 20)
                    
                    // Upcoming events list
                    upcomingSection
                    
                    Spacer(minLength: 100)
                }
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Agenda")
        }
    }
    
    // MARK: - Calendar
    private var calendarSection: some View {
        VStack(spacing: 0) {
            // Month navigation
            HStack {
                Button {
                    withAnimation { currentMonth = calendar.date(byAdding: .month, value: -1, to: currentMonth) ?? currentMonth }
                } label: {
                    Image(systemName: "chevron.left")
                        .font(.system(size: 16, weight: .semibold))
                }
                
                Spacer()
                
                Text(monthYearString(currentMonth))
                    .font(.title3.bold())
                
                Spacer()
                
                Button {
                    withAnimation { currentMonth = calendar.date(byAdding: .month, value: 1, to: currentMonth) ?? currentMonth }
                } label: {
                    Image(systemName: "chevron.right")
                        .font(.system(size: 16, weight: .semibold))
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            .background(Color(.secondarySystemGroupedBackground))
            
            // Weekday headers
            HStack {
                ForEach(["Dom","Lun","Mar","Mié","Jue","Vie","Sáb"], id: \.self) { day in
                    Text(day)
                        .font(.caption.weight(.semibold))
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
            
            Divider()
            
            // Day grid
            LazyVGrid(columns: Array(repeating: GridItem(.flexible(), spacing: 4), count: 7), spacing: 4) {
                ForEach(calendarDays, id: \.self) { date in
                    if let date = date {
                        CalendarDayView(
                            date: date,
                            events: eventsForDate(date),
                            isToday: calendar.isDateInToday(date),
                            isSelected: selectedDate.map { calendar.isDate($0, inSameDayAs: date) } ?? false
                        )
                        .onTapGesture {
                            selectedDate = date
                            LedgeHaptics.selection()
                        }
                    } else {
                        Color.clear
                            .aspectRatio(1, contentMode: .fit)
                    }
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 8)
            .background(Color(.secondarySystemGroupedBackground))
        }
    }
    
    // MARK: - Upcoming Events
    private var upcomingSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            SectionHeader(title: "Próximos eventos")
            
            if upcomingEvents.isEmpty {
                Text("Sin eventos próximos")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(24)
                    .background(Color(.secondarySystemGroupedBackground))
                    .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
                    .padding(.horizontal, LedgeDesign.pagePadding)
            } else {
                VStack(spacing: 0) {
                    ForEach(upcomingEvents) { event in
                        EventRowView(event: event)
                        if event.id != upcomingEvents.last?.id {
                            Divider().padding(.leading, 68)
                        }
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
                .padding(.horizontal, LedgeDesign.pagePadding)
            }
        }
    }
    
    // MARK: - Helpers
    private var calendarDays: [Date?] {
        var days: [Date?] = []
        let components = calendar.dateComponents([.year, .month], from: currentMonth)
        guard let firstDay = calendar.date(from: components),
              let range = calendar.range(of: .day, in: .month, for: currentMonth) else { return days }
        
        let firstWeekday = calendar.component(.weekday, from: firstDay) - 1
        days.append(contentsOf: Array(repeating: nil, count: firstWeekday))
        
        for day in range {
            days.append(calendar.date(byAdding: .day, value: day - 1, to: firstDay))
        }
        return days
    }
    
    private func eventsForDate(_ date: Date) -> [FinancialCalculator.UpcomingEvent] {
        upcomingEvents.filter { calendar.isDate($0.date, inSameDayAs: date) }
    }
    
    private func monthYearString(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "MMMM yyyy"
        formatter.locale = Locale(identifier: "es_MX")
        return formatter.string(from: date).capitalized
    }
}

struct CalendarDayView: View {
    let date: Date
    let events: [FinancialCalculator.UpcomingEvent]
    let isToday: Bool
    let isSelected: Bool
    
    var body: some View {
        VStack(spacing: 2) {
            ZStack {
                if isToday {
                    Circle().fill(Color.accentColor)
                        .frame(width: 30, height: 30)
                } else if isSelected {
                    Circle().fill(Color.accentColor.opacity(0.15))
                        .frame(width: 30, height: 30)
                }
                Text("\(Calendar.current.component(.day, from: date))")
                    .font(.system(size: 15, weight: isToday || !events.isEmpty ? .bold : .regular))
                    .foregroundColor(isToday ? .white : .primary)
            }
            
            // Event dots
            HStack(spacing: 2) {
                ForEach(Array(events.prefix(2).enumerated()), id: \.offset) { _, event in
                    Circle()
                        .fill(event.type == .cutoff ? Color.red : Color.green)
                        .frame(width: 4, height: 4)
                }
            }
            .frame(height: 6)
        }
        .frame(maxWidth: .infinity)
        .aspectRatio(1, contentMode: .fit)
    }
}

struct EventRowView: View {
    let event: FinancialCalculator.UpcomingEvent
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                RoundedRectangle(cornerRadius: 10)
                    .fill(event.type == .cutoff ? Color.red.opacity(0.12) : Color.green.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: event.type.icon)
                    .font(.system(size: 18))
                    .foregroundColor(event.type == .cutoff ? .red : .green)
            }
            
            VStack(alignment: .leading, spacing: 2) {
                Text("\(event.type.label) — \(event.card.displayName)")
                    .font(.subheadline.weight(.medium))
                Text(FinancialCalculator.formatDate(event.date))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Text(FinancialCalculator.relativeDate(event.date))
                .font(.caption.weight(.semibold))
                .foregroundColor(event.urgencyColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
    }
}

// MARK: - Analytics View
struct AnalyticsView: View {
    @Query(sort: \CreditCard.sortOrder) private var cards: [CreditCard]
    @Query(sort: \Transaction.date, order: .reverse) private var allTransactions: [Transaction]
    
    private var monthlySpending: Decimal {
        FinancialCalculator.monthlySpending(transactions: allTransactions)
    }
    
    private var spendingByCategory: [(category: TransactionCategory, amount: Decimal)] {
        let dict = FinancialCalculator.spendingByCategory(transactions: allTransactions)
        return dict.sorted { $0.value > $1.value }
            .map { (category: $0.key, amount: $0.value) }
    }
    
    private var maxCategoryAmount: Decimal {
        spendingByCategory.first?.amount ?? 1
    }
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(alignment: .leading, spacing: 12) {
                    // Monthly spending card
                    monthlyCard
                    
                    // Category breakdown
                    if !spendingByCategory.isEmpty {
                        categoryCard
                    }
                    
                    // Utilization by card
                    utilizationCard
                    
                    Spacer(minLength: 100)
                }
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Analytics")
        }
    }
    
    private var monthlyCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 2) {
                Text("GASTO ESTE MES")
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.secondary)
                Text(monthlySpending.currencyString)
                    .font(.system(size: 32, weight: .bold))
            }
            
            // Placeholder bar chart (last 4 months)
            VStack(spacing: 8) {
                ForEach(["Ene","Feb","Mar","Abr"].indices, id: \.self) { i in
                    let isCurrentMonth = i == 3
                    let mockWidths = [0.72, 0.85, 0.78, 0.65]
                    HStack(spacing: 10) {
                        Text(["Ene","Feb","Mar","Abr"][i])
                            .font(.caption)
                            .foregroundColor(isCurrentMonth ? .primary : .secondary)
                            .frame(width: 28, alignment: .leading)
                        GeometryReader { geo in
                            RoundedRectangle(cornerRadius: 4)
                                .fill(isCurrentMonth ? Color.accentColor : Color(.systemFill))
                                .frame(width: geo.size.width * mockWidths[i])
                        }
                        .frame(height: 10)
                        Text(["$9,100","$10,400","$9,570","$8,420"][i])
                            .font(.caption.weight(isCurrentMonth ? .bold : .regular))
                            .foregroundColor(isCurrentMonth ? .accentColor : .secondary)
                            .frame(width: 55, alignment: .trailing)
                    }
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
        .padding(.horizontal, LedgeDesign.pagePadding)
    }
    
    private var categoryCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("POR CATEGORÍA")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            
            ForEach(spendingByCategory.prefix(6), id: \.category) { item in
                HStack(spacing: 10) {
                    Image(systemName: item.category.icon)
                        .font(.system(size: 14))
                        .foregroundColor(item.category.color)
                        .frame(width: 20)
                    Text(item.category.rawValue)
                        .font(.subheadline)
                        .frame(width: 100, alignment: .leading)
                    GeometryReader { geo in
                        RoundedRectangle(cornerRadius: 4)
                            .fill(item.category.color.opacity(0.3))
                            .frame(width: max(4, geo.size.width * Double(truncating: (item.amount / maxCategoryAmount) as NSDecimalNumber)))
                            .overlay(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(item.category.color)
                                    .frame(width: max(4, geo.size.width * Double(truncating: (item.amount / maxCategoryAmount) as NSDecimalNumber)))
                            }
                    }
                    .frame(height: 10)
                    Text(item.amount.currencyString)
                        .font(.caption.weight(.semibold))
                        .frame(width: 65, alignment: .trailing)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
        .padding(.horizontal, LedgeDesign.pagePadding)
    }
    
    private var utilizationCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("UTILIZACIÓN POR TARJETA")
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)
            
            ForEach(cards.sorted { $0.utilizationRate > $1.utilizationRate }) { card in
                VStack(spacing: 4) {
                    HStack {
                        Text(card.displayName)
                            .font(.subheadline)
                        Spacer()
                        Text(String(format: "%.0f%%", card.utilizationRate))
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(card.riskLevel.color)
                    }
                    UtilizationBar(value: card.utilizationRate, height: 8)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.componentRadius))
        .padding(.horizontal, LedgeDesign.pagePadding)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [CreditCard.self, Transaction.self, Payment.self], inMemory: true)
}
