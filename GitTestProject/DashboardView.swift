import SwiftUI

struct DashboardView: View {
    @EnvironmentObject var store: BudgetStore
    private let today = Date()

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    balanceCard
                    monthSummaryRow
                    recentTransactionsSection
                    debtsSection
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle(today.monthYearString.capitalized)
            .navigationBarTitleDisplayMode(.large)
        }
    }

    // MARK: - Balance Card

    private var balanceCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color.indigo, Color(red: 0.4, green: 0.2, blue: 0.9)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 8) {
                Text("Toplam Bakiye")
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .foregroundColor(.white.opacity(0.8))

                Text(store.totalBalance.currency)
                    .font(.system(size: 38, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Divider()
                    .background(Color.white.opacity(0.3))
                    .padding(.horizontal, 20)

                HStack(spacing: 30) {
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.down.circle.fill")
                                .foregroundColor(.green)
                            Text("Gelir")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                        Text(store.monthlyIncome(for: today).currency)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }

                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Image(systemName: "arrow.up.circle.fill")
                                .foregroundColor(.red)
                            Text("Gider")
                                .foregroundColor(.white.opacity(0.8))
                                .font(.caption)
                        }
                        Text(store.monthlyExpenses(for: today).currency)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
            }
            .padding(.vertical, 20)
            .padding(.horizontal, 16)
        }
        .shadow(color: Color.indigo.opacity(0.4), radius: 12, x: 0, y: 6)
    }

    // MARK: - Month Summary Row

    private var monthSummaryRow: some View {
        let income = store.monthlyIncome(for: today)
        let expenses = store.monthlyExpenses(for: today)
        let net = income - expenses

        return HStack(spacing: 12) {
            SummaryCard(
                title: "Bu Ay Net",
                amount: net,
                icon: "equal.circle.fill",
                color: net >= 0 ? .green : .red
            )
            SummaryCard(
                title: "Toplam Borç",
                amount: store.totalDebt,
                icon: "exclamationmark.circle.fill",
                color: .orange
            )
        }
    }

    // MARK: - Recent Transactions

    private var recentTransactionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Son İşlemler")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if store.recentTransactions().isEmpty {
                EmptyStateSmall(message: "Henüz işlem yok", icon: "tray.fill")
            } else {
                VStack(spacing: 2) {
                    ForEach(store.recentTransactions()) { tx in
                        TransactionRowView(transaction: tx)
                    }
                }
                .background(Color(.secondarySystemGroupedBackground))
                .cornerRadius(12)
            }
        }
    }

    // MARK: - Debts Section

    private var debtsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Borçlarım")
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            if store.debts.isEmpty {
                EmptyStateSmall(message: "Borç kaydı yok", icon: "checkmark.seal.fill")
            } else {
                VStack(spacing: 8) {
                    ForEach(store.debts.prefix(3)) { debt in
                        DebtSummaryRow(debt: debt)
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct SummaryCard: View {
    let title: String
    let amount: Double
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundColor(.secondary)
                Text(amount.currency)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(color)
            }
            Spacer()
        }
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct TransactionRowView: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.15))
                    .frame(width: 40, height: 40)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 16))
                    .foregroundColor(transaction.category.color)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(transaction.note.isEmpty ? transaction.category.label : transaction.note)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(transaction.date.dayMonthString)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            Text("\(transaction.type.sign)\(transaction.amount.currency)")
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(transaction.type.color)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color(.secondarySystemGroupedBackground))
    }
}

struct DebtSummaryRow: View {
    let debt: Debt

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: debt.type.icon)
                    .foregroundColor(debt.type.color)
                Text(debt.name)
                    .font(.subheadline)
                    .fontWeight(.medium)
                Spacer()
                Text(debt.remainingAmount.currency)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(.red)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 4)
                        .fill(Color(.systemFill))
                        .frame(height: 6)
                    RoundedRectangle(cornerRadius: 4)
                        .fill(debt.type.color)
                        .frame(width: geo.size.width * debt.progressRatio, height: 6)
                }
            }
            .frame(height: 6)

            Text("Ödenen: \(debt.paidAmount.currency) / \(debt.totalAmount.currency)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}

struct EmptyStateSmall: View {
    let message: String
    let icon: String

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .foregroundColor(.secondary)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(12)
    }
}
