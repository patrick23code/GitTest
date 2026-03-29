import SwiftUI

// MARK: - Transaction

enum TransactionType: String, Codable, CaseIterable {
    case income, expense

    var label: String { self == .income ? "Gelir" : "Gider" }
    var color: Color { self == .income ? .green : .red }
    var sign: String { self == .income ? "+" : "-" }
}

enum ExpenseCategory: String, Codable, CaseIterable {
    case food, transport, housing, entertainment, health, shopping, bills, education, salary, investment, other

    var label: String {
        switch self {
        case .food:          return "Yemek"
        case .transport:     return "Ulaşım"
        case .housing:       return "Kira/Ev"
        case .entertainment: return "Eğlence"
        case .health:        return "Sağlık"
        case .shopping:      return "Alışveriş"
        case .bills:         return "Faturalar"
        case .education:     return "Eğitim"
        case .salary:        return "Maaş"
        case .investment:    return "Yatırım"
        case .other:         return "Diğer"
        }
    }

    var icon: String {
        switch self {
        case .food:          return "fork.knife"
        case .transport:     return "car.fill"
        case .housing:       return "house.fill"
        case .entertainment: return "tv.fill"
        case .health:        return "heart.fill"
        case .shopping:      return "bag.fill"
        case .bills:         return "bolt.fill"
        case .education:     return "book.fill"
        case .salary:        return "banknote.fill"
        case .investment:    return "chart.line.uptrend.xyaxis"
        case .other:         return "ellipsis.circle.fill"
        }
    }

    var color: Color {
        switch self {
        case .food:          return Color.orange
        case .transport:     return Color.blue
        case .housing:       return Color.purple
        case .entertainment: return Color.pink
        case .health:        return Color.red
        case .shopping:      return Color.teal
        case .bills:         return Color.yellow
        case .education:     return Color.green
        case .salary:        return Color(red: 0.2, green: 0.8, blue: 0.4)
        case .investment:    return Color(red: 0.1, green: 0.6, blue: 1.0)
        case .other:         return Color.gray
        }
    }

    static var expenseCategories: [ExpenseCategory] {
        [.food, .transport, .housing, .entertainment, .health, .shopping, .bills, .education, .other]
    }

    static var incomeCategories: [ExpenseCategory] {
        [.salary, .investment, .other]
    }
}

struct Transaction: Identifiable, Codable {
    var id: UUID = UUID()
    var type: TransactionType
    var amount: Double
    var category: ExpenseCategory
    var note: String
    var date: Date

    init(type: TransactionType, amount: Double, category: ExpenseCategory, note: String = "", date: Date = Date()) {
        self.type = type
        self.amount = amount
        self.category = category
        self.note = note
        self.date = date
    }
}

// MARK: - Debt

enum DebtType: String, Codable, CaseIterable {
    case creditCard, loan, personal

    var label: String {
        switch self {
        case .creditCard: return "Kredi Kartı"
        case .loan:       return "Kredi"
        case .personal:   return "Kişisel Borç"
        }
    }

    var icon: String {
        switch self {
        case .creditCard: return "creditcard.fill"
        case .loan:       return "building.columns.fill"
        case .personal:   return "person.2.fill"
        }
    }

    var color: Color {
        switch self {
        case .creditCard: return Color.orange
        case .loan:       return Color.indigo
        case .personal:   return Color.pink
        }
    }
}

struct Debt: Identifiable, Codable {
    var id: UUID = UUID()
    var name: String
    var type: DebtType
    var totalAmount: Double
    var remainingAmount: Double
    var dueDate: Date?
    var note: String
    var createdDate: Date = Date()

    var paidAmount: Double { totalAmount - remainingAmount }
    var progressRatio: Double { totalAmount > 0 ? min(paidAmount / totalAmount, 1.0) : 0 }

    init(name: String, type: DebtType, totalAmount: Double, remainingAmount: Double,
         dueDate: Date? = nil, note: String = "") {
        self.name = name
        self.type = type
        self.totalAmount = totalAmount
        self.remainingAmount = remainingAmount
        self.dueDate = dueDate
        self.note = note
    }
}

// MARK: - Formatting Helpers

extension Double {
    var currency: String {
        let formatter = NumberFormatter()
        formatter.numberStyle = .decimal
        formatter.minimumFractionDigits = 2
        formatter.maximumFractionDigits = 2
        formatter.groupingSeparator = "."
        formatter.decimalSeparator = ","
        let formatted = formatter.string(from: NSNumber(value: self)) ?? "0,00"
        return "₺\(formatted)"
    }
}

extension Date {
    var monthYearString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "MMMM yyyy"
        return f.string(from: self)
    }

    var shortDateString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM yyyy"
        return f.string(from: self)
    }

    var dayMonthString: String {
        let f = DateFormatter()
        f.locale = Locale(identifier: "tr_TR")
        f.dateFormat = "d MMMM"
        return f.string(from: self)
    }

    func isSameDay(as other: Date) -> Bool {
        Calendar.current.isDate(self, inSameDayAs: other)
    }

    func isSameMonth(as other: Date) -> Bool {
        let c = Calendar.current
        return c.component(.year, from: self) == c.component(.year, from: other) &&
               c.component(.month, from: self) == c.component(.month, from: other)
    }
}
