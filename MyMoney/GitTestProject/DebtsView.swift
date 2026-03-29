import SwiftUI

struct DebtsView: View {
    @EnvironmentObject var store: BudgetStore
    @State private var showingAddSheet = false
    @State private var selectedDebt: Debt? = nil
    @State private var showingPaymentSheet = false

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 16) {
                    totalDebtCard
                    debtsByType
                    Spacer(minLength: 20)
                }
                .padding(.horizontal)
                .padding(.top, 8)
            }
            .background(Color(.systemGroupedBackground))
            .navigationTitle("Borçlarım")
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
                AddDebtSheet()
                    .environmentObject(store)
            }
            .sheet(item: $selectedDebt) { debt in
                PaymentSheet(debt: debt)
                    .environmentObject(store)
            }
        }
    }

    // MARK: - Total Card

    private var totalDebtCard: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(
                    LinearGradient(
                        colors: [Color(red: 0.9, green: 0.3, blue: 0.3), Color(red: 0.7, green: 0.2, blue: 0.5)],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )

            VStack(spacing: 6) {
                Text("Toplam Borç")
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.8))

                Text(store.totalDebt.currency)
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                    .foregroundColor(.white)

                Text("\(store.debts.count) borç kaydı")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
            .padding(.vertical, 20)
        }
        .shadow(color: Color.red.opacity(0.3), radius: 10, x: 0, y: 5)
    }

    // MARK: - Debts by Type

    private var debtsByType: some View {
        VStack(spacing: 16) {
            ForEach(DebtType.allCases, id: \.self) { debtType in
                let typeDebts = store.debts.filter { $0.type == debtType }
                if !typeDebts.isEmpty {
                    debtTypeSection(type: debtType, debts: typeDebts)
                }
            }

            if store.debts.isEmpty {
                VStack(spacing: 16) {
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 50))
                        .foregroundColor(.green.opacity(0.7))
                    Text("Borç kaydınız yok!")
                        .font(.headline)
                        .foregroundColor(.secondary)
                    Text("Borç eklemek için sağ üstteki + butonuna tıklayın")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 40)
            }
        }
    }

    private func debtTypeSection(type: DebtType, debts: [Debt]) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 6) {
                Image(systemName: type.icon)
                    .foregroundColor(type.color)
                Text(type.label)
                    .font(.headline)
                    .fontWeight(.semibold)
                Spacer()
            }

            VStack(spacing: 8) {
                ForEach(debts) { debt in
                    DebtCard(debt: debt) {
                        selectedDebt = debt
                    }
                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                        Button(role: .destructive) {
                            store.deleteDebt(debt)
                        } label: {
                            Label("Sil", systemImage: "trash")
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Debt Card

struct DebtCard: View {
    let debt: Debt
    let onPayment: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(debt.name)
                        .font(.subheadline)
                        .fontWeight(.semibold)
                    if let due = debt.dueDate {
                        HStack(spacing: 4) {
                            Image(systemName: "calendar")
                                .font(.caption2)
                            Text("Son ödeme: \(due.dayMonthString)")
                                .font(.caption)
                        }
                        .foregroundColor(isOverdue(due) ? .red : .secondary)
                    }
                    if !debt.note.isEmpty {
                        Text(debt.note)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .lineLimit(1)
                    }
                }

                Spacer()

                VStack(alignment: .trailing, spacing: 2) {
                    Text(debt.remainingAmount.currency)
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.red)
                    Text("kalan")
                        .font(.caption2)
                        .foregroundColor(.secondary)
                }
            }

            // Progress bar
            VStack(alignment: .leading, spacing: 4) {
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        RoundedRectangle(cornerRadius: 5)
                            .fill(Color(.systemFill))
                            .frame(height: 8)
                        RoundedRectangle(cornerRadius: 5)
                            .fill(
                                LinearGradient(
                                    colors: [debt.type.color, debt.type.color.opacity(0.6)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .frame(width: max(geo.size.width * debt.progressRatio, 0), height: 8)
                    }
                }
                .frame(height: 8)

                HStack {
                    Text("Ödenen: \(debt.paidAmount.currency)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Spacer()
                    Text("Toplam: \(debt.totalAmount.currency)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.0f%%", debt.progressRatio * 100))
                        .font(.caption)
                        .fontWeight(.semibold)
                        .foregroundColor(debt.type.color)
                }
            }

            Button(action: onPayment) {
                HStack {
                    Image(systemName: "plus.circle")
                    Text("Ödeme Ekle")
                        .fontWeight(.medium)
                }
                .font(.subheadline)
                .foregroundColor(debt.type.color)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 8)
                .background(debt.type.color.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding(14)
        .background(Color(.secondarySystemGroupedBackground))
        .cornerRadius(14)
    }

    private func isOverdue(_ date: Date) -> Bool {
        date < Date()
    }
}

// MARK: - Add Debt Sheet

struct AddDebtSheet: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.presentationMode) var presentationMode

    @State private var name = ""
    @State private var type: DebtType = .creditCard
    @State private var totalAmountText = ""
    @State private var remainingAmountText = ""
    @State private var hasDueDate = false
    @State private var dueDate = Date()
    @State private var note = ""

    var body: some View {
        NavigationView {
            Form {
                Section(header: Text("Borç Bilgileri")) {
                    TextField("Borç adı (ör. Garanti Kredi Kartı)", text: $name)

                    Picker("Tür", selection: $type) {
                        ForEach(DebtType.allCases, id: \.self) { t in
                            Label(t.label, systemImage: t.icon).tag(t)
                        }
                    }
                }

                Section(header: Text("Tutarlar")) {
                    HStack {
                        Text("Toplam Borç ₺")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("0,00", text: $totalAmountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                    HStack {
                        Text("Kalan Borç ₺")
                            .foregroundColor(.secondary)
                        Spacer()
                        TextField("0,00", text: $remainingAmountText)
                            .keyboardType(.decimalPad)
                            .multilineTextAlignment(.trailing)
                    }
                }

                Section(header: Text("Son Ödeme")) {
                    Toggle("Son ödeme tarihi var", isOn: $hasDueDate)
                    if hasDueDate {
                        DatePicker("Tarih", selection: $dueDate, displayedComponents: .date)
                            .environment(\.locale, Locale(identifier: "tr_TR"))
                    }
                }

                Section(header: Text("Not (İsteğe Bağlı)")) {
                    TextField("Notunuz...", text: $note)
                }
            }
            .navigationTitle("Yeni Borç")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        saveDebt()
                    }
                    .fontWeight(.semibold)
                    .disabled(!isValid)
                }
            }
        }
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty &&
        parseAmount(totalAmountText) != nil &&
        parseAmount(remainingAmountText) != nil
    }

    private func parseAmount(_ text: String) -> Double? {
        let clean = text.replacingOccurrences(of: ",", with: ".")
        return Double(clean)
    }

    private func saveDebt() {
        guard let total = parseAmount(totalAmountText),
              let remaining = parseAmount(remainingAmountText) else { return }
        let debt = Debt(
            name: name.trimmingCharacters(in: .whitespaces),
            type: type,
            totalAmount: total,
            remainingAmount: remaining,
            dueDate: hasDueDate ? dueDate : nil,
            note: note
        )
        store.addDebt(debt)
        presentationMode.wrappedValue.dismiss()
    }
}

// MARK: - Payment Sheet

struct PaymentSheet: View {
    @EnvironmentObject var store: BudgetStore
    @Environment(\.presentationMode) var presentationMode
    let debt: Debt

    @State private var amountText = ""

    var body: some View {
        NavigationView {
            Form {
                Section {
                    VStack(spacing: 4) {
                        Text(debt.name)
                            .font(.headline)
                        Text("Kalan: \(debt.remainingAmount.currency)")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }

                Section(header: Text("Ödeme Tutarı")) {
                    HStack {
                        Text("₺")
                            .font(.title2)
                            .foregroundColor(.secondary)
                        TextField("0,00", text: $amountText)
                            .keyboardType(.decimalPad)
                            .font(.title2)
                    }
                }

                Section {
                    Button("Tamamını Öde") {
                        amountText = String(debt.remainingAmount)
                    }
                    .foregroundColor(.indigo)
                }
            }
            .navigationTitle("Ödeme Ekle")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("İptal") {
                        presentationMode.wrappedValue.dismiss()
                    }
                }
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Kaydet") {
                        makePayment()
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

    private func makePayment() {
        guard let amount = parsedAmount, amount > 0 else { return }
        store.makePayment(debtId: debt.id, amount: amount)
        presentationMode.wrappedValue.dismiss()
    }
}
