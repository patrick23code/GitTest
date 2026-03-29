import SwiftUI

struct ContentView: View {
    @StateObject private var store = BudgetStore()

    var body: some View {
        TabView {
            DashboardView()
                .tabItem {
                    Label("Ana Sayfa", systemImage: "house.fill")
                }

            TransactionsView()
                .tabItem {
                    Label("İşlemler", systemImage: "list.bullet.rectangle.fill")
                }

            DebtsView()
                .tabItem {
                    Label("Borçlar", systemImage: "creditcard.fill")
                }

            ReportsView()
                .tabItem {
                    Label("Raporlar", systemImage: "chart.pie.fill")
                }
        }
        .environmentObject(store)
        .accentColor(.indigo)
    }
}
