import SwiftUI

struct ReportsView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var selectedMonth = Date()

    private var income: Double { store.monthlyIncome(for: selectedMonth) }
    private var expenses: Double { store.monthlyExpenses(for: selectedMonth) }
    private var net: Double { income - expenses }
    private var breakdown: [(category: ExpenseCategory, amount: Double)] {
        store.categoryBreakdown(for: selectedMonth)
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    monthSelector
                    summaryCards
                    if !breakdown.isEmpty {
                        incomeSavingsCard
                        categoryBreakdownSection
                    } else {
                        emptyState
                    }
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Raporlar")
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Month Selector

    private var monthSelector: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left.circle.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
            }
            Spacer()
            Text(selectedMonth.monthYearString.capitalized)
                .font(.headline)
                .fontWeight(.semibold)
            Spacer()
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right.circle.fill")
                    .font(.title2)
                    .foregroundColor(.indigo)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    // MARK: - Summary Cards

    private var summaryCards: some View {
        HStack(spacing: 12) {
            ReportCard(title: "Toplam Gelir", amount: income, icon: "arrow.down.circle.fill", color: .green)
            ReportCard(title: "Toplam Gider", amount: expenses, icon: "arrow.up.circle.fill", color: .red)
        }
    }

    // MARK: - Income/Savings Card

    private var incomeSavingsCard: some View {
        VStack(spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(net >= 0 ? "Aylık Tasarruf" : "Aylık Açık")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text(net.currency)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(net >= 0 ? .green : .red)
                }
                Spacer()
                Image(systemName: net >= 0 ? "arrow.up.right.circle.fill" : "arrow.down.right.circle.fill")
                    .font(.system(size: 36))
                    .foregroundColor(net >= 0 ? .green : .red)
            }

            if income > 0 {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 6)
                            .fill(Color.red.opacity(0.2))
                            .frame(height: 12)
                        RoundedRectangle(cornerRadius: 6)
                            .fill(
                                LinearGradient(
                                    colors: [.green, Color(red: 0.2, green: 0.8, blue: 0.4)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(
                                width: min(geo.size.width * (income > 0 ? (income - expenses) / income : 0), geo.size.width),
                                height: 12
                            )
                    }
                }
                .frame(height: 12)

                HStack {
                    Text("Tasarruf oranı")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(income > 0 ? String(format: "%.1f%%", max(0, (net / income) * 100)) : "—")
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(net >= 0 ? .green : .red)
                }
            }
        }
        .padding(16)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    // MARK: - Category Breakdown

    private var categoryBreakdownSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Harcama Dağılımı")
                .font(.headline)
                .fontWeight(.semibold)

            VStack(spacing: 0) {
                ForEach(breakdown.indices, id: \.self) { idx in
                    let item = breakdown[idx]
                    CategoryBreakdownRow(
                        category: item.category,
                        amount: item.amount,
                        total: expenses
                    )
                    if idx < breakdown.count - 1 {
                        Divider()
                            .padding(.leading, 56)
                    }
                }
            }
            .background(Color(.secondarySystemGroupedBackground))
            .cornerRadius(14)

            // Visual bar chart
            VStack(alignment: .leading, spacing: 8) {
                Text("Kategori Grafiği")
                    .font(.subheadline)
                    .fontWeight(.semibold)

                VStack(spacing: 10) {
                    ForEach(breakdown.prefix(6).indices, id: \.self) { idx in
                        let item = breakdown[idx]
                        CategoryBar(
                            category: item.category,
                            amount: item.amount,
                            maxAmount: breakdown.first?.amount ?? 1
                        )
                    }
                }
                .padding(14)
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(14)
            }
        }
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "chart.pie")
                .font(.system(size: 50))
                .foregroundColor(.secondary.opacity(0.4))
            Text("Bu ay için veri yok")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("İşlem ekledikçe raporlar burada görünecek")
                .font(.caption)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.top, 40)
    }
}

// MARK: - Report Card

struct ReportCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .foregroundColor(color)
                    .font(.title3)
                Spacer()
            }
            Text(amount.currency)
                .font(.title3)
                .fontWeight(.bold)
                .foregroundColor(color)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }
}

// MARK: - Category Breakdown Row

struct CategoryBreakdownRow: View {
    let category: ExpenseCategory
    let amount: Double
    let total: Double

    private var ratio: Double { total > 0 ? amount / total : 0 }

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(category.color.opacity(0.15))
                    .frame(width: 36, height: 36)
                Image(systemName: category.icon)
                    .font(.system(size: 14))
                    .foregroundColor(category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(category.label)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Text(String(format: "%.1f%%", ratio * 100))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text(amount.currency)
                .font(.subheadline)
                .fontWeight(.semibold)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
    }
}

// MARK: - Category Bar

struct CategoryBar: View {
    let category: ExpenseCategory
    let amount: Double
    let maxAmount: Double

    private var ratio: Double { maxAmount > 0 ? amount / maxAmount : 0 }

    var body: some View {
        HStack(spacing: 10) {
            Text(category.label)
                .font(.caption)
                .foregroundColor(.secondary)
                .frame(width: 70, alignment: .leading)
                .lineLimit(1)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                        .frame(height: 16)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(category.color)
                        .frame(width: max(geo.size.width * ratio, 4), height: 16)
                }
            }
            .frame(height: 16)

            Text(amount.currency)
                .font(.caption)
                .fontWeight(.semibold)
                .foregroundColor(category.color)
                .frame(width: 72, alignment: .trailing)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
        }
    }
}
