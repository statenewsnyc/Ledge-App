// CreditCardView.swift
import SwiftUI

struct CreditCardView: View {
    let card: CreditCard
    var isCompact: Bool = false
    
    var body: some View {
        if isCompact { compactCard } else { fullCard }
    }
    
    private var fullCard: some View {
        ZStack(alignment: .bottomLeading) {
            // Gradient background
            LinearGradient(
                colors: card.gradientColors,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            
            // Decorative circles
            Circle()
                .fill(Color.white.opacity(0.08))
                .frame(width: 200, height: 200)
                .offset(x: 140, y: -80)
            Circle()
                .fill(Color.white.opacity(0.05))
                .frame(width: 160, height: 160)
                .offset(x: 180, y: 60)
            
            VStack(alignment: .leading, spacing: 0) {
                // Bank + card name
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.bankName)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(.white.opacity(0.75))
                        Text(card.cardName)
                            .font(.system(size: 18, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    // Chip icon
                    RoundedRectangle(cornerRadius: 3)
                        .fill(Color.white.opacity(0.25))
                        .frame(width: 32, height: 24)
                        .overlay(
                            RoundedRectangle(cornerRadius: 1)
                                .stroke(Color.white.opacity(0.3), lineWidth: 0.5)
                        )
                }
                
                Spacer()
                
                // Card number
                Text(card.maskedNumber)
                    .font(.system(size: 14, weight: .medium, design: .monospaced))
                    .foregroundColor(.white.opacity(0.7))
                    .tracking(2)
                    .padding(.bottom, 12)
                
                // Balance row
                HStack(alignment: .bottom) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Balance")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.white.opacity(0.6))
                        Text(card.currentBalance.currencyString)
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    }
                    Spacer()
                    VStack(alignment: .trailing, spacing: 2) {
                        Text("Disponible")
                            .font(.system(size: 11))
                            .foregroundColor(.white.opacity(0.6))
                        Text(card.availableCredit.currencyString)
                            .font(.system(size: 15, weight: .semibold))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
            }
            .padding(22)
        }
        .frame(height: 196)
        .clipShape(RoundedRectangle(cornerRadius: LedgeDesign.cardRadius))
        .overlay(alignment: .bottom) {
            // Utilization bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Color.white.opacity(0.15)
                    Color.white.opacity(0.6)
                        .frame(width: geo.size.width * min(card.utilizationRate / 100, 1.0))
                }
            }
            .frame(height: 3)
            .clipShape(RoundedRectangle(cornerRadius: 0))
        }
        .shadow(color: card.gradientColors.first?.opacity(0.3) ?? .clear, radius: 16, x: 0, y: 8)
    }
    
    private var compactCard: some View {
        LinearGradient(colors: card.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing)
            .frame(height: 72)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(alignment: .leading) {
                HStack {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(card.bankName)
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(card.cardName)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    Spacer()
                    Text(card.maskedNumber)
                        .font(.caption.monospaced())
                        .foregroundColor(.white.opacity(0.65))
                        .tracking(1)
                }
                .padding(.horizontal, 16)
            }
    }
}

// MARK: - Card Stack (Wallet-style)
struct CardStackView: View {
    let cards: [CreditCard]
    @State private var expandedIndex: Int? = nil
    var onCardTap: (CreditCard) -> Void
    
    var body: some View {
        if cards.isEmpty {
            EmptyStateView(
                icon: "creditcard.fill",
                title: "Sin tarjetas",
                subtitle: "Toca + para agregar tu primera tarjeta de crédito"
            )
        } else {
            ZStack(alignment: .top) {
                ForEach(Array(cards.enumerated()), id: \.element.id) { index, card in
                    CreditCardView(card: card)
                        .padding(.horizontal, LedgeDesign.pagePadding)
                        .offset(y: cardOffset(for: index))
                        .zIndex(Double(index))
                        .onTapGesture {
                            if expandedIndex == index {
                                onCardTap(card)
                            } else {
                                withAnimation(.spring(response: 0.4, dampingFraction: 0.75)) {
                                    expandedIndex = index
                                }
                                LedgeHaptics.selection()
                            }
                        }
                }
            }
            .frame(height: stackHeight)
        }
    }
    
    private func cardOffset(for index: Int) -> CGFloat {
        if let expanded = expandedIndex {
            if index <= expanded {
                return CGFloat(index) * 212
            } else {
                return CGFloat(expanded) * 212 + 220 + CGFloat(index - expanded - 1) * 56
            }
        }
        return CGFloat(index) * 56
    }
    
    private var stackHeight: CGFloat {
        if let expanded = expandedIndex {
            return CGFloat(expanded + 1) * 212 + CGFloat(cards.count - expanded - 1) * 56 + 196
        }
        return CGFloat(cards.count - 1) * 56 + 196
    }
}

// MARK: - Card Row (Summary list)
struct CardRowView: View {
    let card: CreditCard
    
    var body: some View {
        HStack(spacing: 12) {
            // Mini card color swatch
            RoundedRectangle(cornerRadius: 8)
                .fill(LinearGradient(colors: card.gradientColors, startPoint: .topLeading, endPoint: .bottomTrailing))
                .frame(width: 40, height: 28)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(card.displayName)
                    .font(.subheadline.weight(.medium))
                Text(card.maskedNumber)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            VStack(alignment: .trailing, spacing: 2) {
                Text(card.currentBalance.currencyString)
                    .font(.subheadline.weight(.semibold))
                Text(String(format: "%.0f%%", card.utilizationRate))
                    .font(.caption.weight(.semibold))
                    .foregroundColor(card.riskLevel.color)
            }
        }
        .padding(.vertical, 10)
    }
}
