import SwiftUI

struct TransactionsView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var showingAddSheet = false
    @State private var filterType: TransactionType? = nil
    @State private var selectedMonth = Date()

    var body: some View {
        NavigationView {
            VStack(spacing: 0) {
                filterBar
                    .padding(.horizontal)
                    .padding(.top, 8)
                    .padding(.bottom, 4)

                monthPicker
                    .padding(.horizontal)
                    .padding(.bottom, 8)

                transactionList
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("İşlemler")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: { showingAddSheet = true }) {
                        Image(systemName: "plus.circle.fill")
                            .font(.title2)
                            .foregroundColor(.indigo)
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddTransactionSheet()
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Filter Bar

    private var filterBar: some View {
        HStack(spacing: 8) {
            FilterChip(title: "Tümü", isSelected: filterType == nil) {
                filterType = nil
            }
            FilterChip(title: "Gelir", isSelected: filterType == .income, color: .green) {
                filterType = .income
            }
            FilterChip(title: "Gider", isSelected: filterType == .expense, color: .red) {
                filterType = .expense
            }
            Spacer()
        }
    }

    // MARK: - Month Picker

    private var monthPicker: some View {
        HStack {
            Button(action: { changeMonth(by: -1) }) {
                Image(systemName: "chevron.left")
                    .foregroundColor(.indigo)
            }
            Spacer()
            Text(selectedMonth.monthYearString.capitalized)
                .font(.subheadline)
                .fontWeight(.semibold)
            Spacer()
            Button(action: { changeMonth(by: 1) }) {
                Image(systemName: "chevron.right")
                    .foregroundColor(.indigo)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(10)
    }

    private func changeMonth(by value: Int) {
        if let newDate = Calendar.current.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newDate
        }
    }

    // MARK: - Transaction List

    private var filteredGroups: [(date: Date, transactions: [Transaction])] {
        let groups = store.groupedTransactions(for: selectedMonth)
        guard let filter = filterType else { return groups }
        return groups.compactMap { group in
            let filtered = group.transactions.filter { $0.type == filter }
            return filtered.isEmpty ? nil : (date: group.date, transactions: filtered)
        }
    }

    private var transactionList: some View {
        Group {
            if filteredGroups.isEmpty {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "doc.text.magnifyingglass")
                        .font(.system(size: 50))
                        .foregroundColor(.secondary.opacity(0.5))
                    Text("Bu ay için işlem bulunamadı")
                        .foregroundColor(.secondary)
                    Spacer()
                }
            } else {
                List {
                    ForEach(filteredGroups, id: \.date) { group in
                        Section(header: Text(group.date.shortDateString).font(.subheadline)) {
                            ForEach(group.transactions) { tx in
                                TransactionDetailRow(transaction: tx)
                                    .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 4, trailing: 16))
                                    .listRowBackground(Color(.secondarySystemGroupedBackground))
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            store.deleteTransaction(tx)
                                        } label: {
                                            Label("Sil", systemImage: "trash")
                                        }
                                    }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
    }
}

// MARK: - Transaction Detail Row

struct TransactionDetailRow: View {
    let transaction: Transaction

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(transaction.category.color.opacity(0.15))
                    .frame(width: 44, height: 44)
                Image(systemName: transaction.category.icon)
                    .font(.system(size: 18))
                    .foregroundColor(transaction.category.color)
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(transaction.note.isEmpty ? transaction.category.label : transaction.note)
                    .font(.subheadline)
                    .fontWeight(.medium)
                    .lineLimit(1)
                Text(transaction.category.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 3) {
                Text("\(transaction.type.sign)\(transaction.amount.currency)")
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundColor(transaction.type.color)
                Text(transaction.type.label)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Add Transaction Sheet

struct AddTransactionSheet: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.presentationMode) var presentationMode

    @State private var type: TransactionType = .expense
    @State private var amountText = ""
    @State private var category: ExpenseCategory = .food
    @State private var note = ""
    @State private var date = Date()

    private var categories: [ExpenseCategory] {
        type == .expense ? ExpenseCategory.expenseCategories : ExpenseCategory.incomeCategories
    }

    var body: some View {
        NavigationView {
            Form {
                Section {
                    Picker("Tür", selection: $type) {
                        Text("Gider").tag(TransactionType.expense)
                        Text("Gelir").tag(TransactionType.income)
                    }
                    .pickerStyle(.segmented)
                    .onChange(of: type) { _ in
                        category = categories.first ?? .other
                    }
                }

                Section(header: Text("Tutar")) {
                    HStack {
                        Text("₺")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("0,00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }

                Section(header: Text("Kategori")) {
                    Picker("Kategori", selection: $category) {
                        ForEach(categories, id: \.self) { cat in
                            Label(cat.label, systemImage: cat.icon).tag(cat)
                        }
                    }
                }

                Section(header: Text("Not (İsteğe Bağlı)")) {
                    TextField("Açıklama girin...", text: $note)
                }

                Section(header: Text("Tarih")) {
                    DatePicker("Tarih", selection: $date, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "tr_TR"))
                }
            }
            .navigationTitle("Yeni İşlem")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveTransaction()
                    }
                    .fontWeight(.semibold)
                    .disabled(parsedAmount == nil)
                }
            }
        }
    }

    private var parsedAmount: Double? {
        let clean = amountText.replacingOccurrences(of: ",", with: ".")
        return Double(clean)
    }

    private func saveTransaction() {
        guard let amount = parsedAmount, amount > 0 else { return }
        let tx = Transaction(type: type, amount: amount, category: category, note: note, date: date)
        store.addTransaction(tx)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Filter Chip

struct FilterChip: View {
    let title: String
    let isSelected: Bool
    var color: Color = .indigo
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(isSelected ? .semibold : .regular)
                .padding(.horizontal, 14)
                .padding(.vertical, 6)
                .background(isSelected ? color.opacity(0.15) : Color(.systemFill))
                .foregroundColor(isSelected ? color : .secondary)
                .cornerRadius(20)
                .overlay(
                    RoundedRectangle(cornerRadius: 20)
                        .stroke(isSelected ? color : Color.clear, lineWidth: 1)
                )
        }
    }
}
