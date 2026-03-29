import SwiftUI
import Combine

class BudgetStore: ObservableObject {
    @Published var transactions: [Transaction] = []
    @Published var debts: [Debt] = []

    init() {
        load()
    }

    // MARK: - Computed Properties

    var totalBalance: Double {
        transactions.reduce(0) { sum, t in
            t.type == .income ? sum + t.amount : sum - t.amount
        }
    }

    var totalDebt: Double {
        debts.reduce(0) { $0 + $1.remainingAmount }
    }

    // MARK: - Monthly Queries

    func monthlyIncome(for date: Date) -> Double {
        transactionsFor(month: date).filter { $0.type == .income }.reduce(0) { $0 + $1.amount }
    }

    func monthlyExpenses(for date: Date) -> Double {
        transactionsFor(month: date).filter { $0.type == .expense }.reduce(0) { $0 + $1.amount }
    }

    func transactionsFor(month date: Date) -> [Transaction] {
        transactions.filter { $0.date.isSameMonth(as: date) }
    }

    func categoryBreakdown(for date: Date) -> [(category: ExpenseCategory, amount: Double)] {
        let expenses = transactionsFor(month: date).filter { $0.type == .expense }
        var breakdown: [ExpenseCategory: Double] = [:]
        for t in expenses {
            breakdown[t.category, default: 0] += t.amount
        }
        return breakdown.map { (category: $0.key, amount: $0.value) }
            .sorted { $0.amount > $1.amount }
    }

    func groupedTransactions(for month: Date) -> [(date: Date, transactions: [Transaction])] {
        let monthTxs = transactionsFor(month: month).sorted { $0.date > $1.date }
        var grouped: [Date: [Transaction]] = [:]
        for tx in monthTxs {
            let day = Calendar.current.startOfDay(for: tx.date)
            grouped[day, default: []].append(tx)
        }
        return grouped.map { (date: $0.key, transactions: $0.value) }
            .sorted { $0.date > $1.date }
    }

    func recentTransactions(limit: Int = 5) -> [Transaction] {
        Array(transactions.sorted { $0.date > $1.date }.prefix(limit))
    }

    // MARK: - Transaction CRUD

    func addTransaction(_ t: Transaction) {
        transactions.insert(t, at: 0)
        save()
    }

    func deleteTransaction(_ t: Transaction) {
        transactions.removeAll { $0.id == t.id }
        save()
    }

    // MARK: - Debt CRUD

    func addDebt(_ d: Debt) {
        debts.append(d)
        save()
    }

    func updateDebt(_ d: Debt) {
        if let idx = debts.firstIndex(where: { $0.id == d.id }) {
            debts[idx] = d
            save()
        }
    }

    func deleteDebt(_ d: Debt) {
        debts.removeAll { $0.id == d.id }
        save()
    }

    func makePayment(debtId: UUID, amount: Double) {
        if let idx = debts.firstIndex(where: { $0.id == debtId }) {
            debts[idx].remainingAmount = max(0, debts[idx].remainingAmount - amount)
            save()
        }
    }

    // MARK: - Persistence

    private let txKey = "budget_transactions"
    private let debtKey = "budget_debts"

    private func save() {
        if let data = try? JSONEncoder().encode(transactions) {
            UserDefaults.standard.set(data, forKey: txKey)
        }
        if let data = try? JSONEncoder().encode(debts) {
            UserDefaults.standard.set(data, forKey: debtKey)
        }
    }

    private func load() {
        if let data = UserDefaults.standard.data(forKey: txKey),
           let decoded = try? JSONDecoder().decode([Transaction].self, from: data) {
            transactions = decoded
        }
        if let data = UserDefaults.standard.data(forKey: debtKey),
           let decoded = try? JSONDecoder().decode([Debt].self, from: data) {
            debts = decoded
        }
    }
}
