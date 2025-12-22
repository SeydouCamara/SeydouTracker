import SwiftUI

struct MainTabView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayView()
                .tabItem {
                    Label("Aujourd'hui", systemImage: "checkmark.circle.fill")
                }
                .tag(0)

            CycleView()
                .tabItem {
                    Label("Cycle", systemImage: "calendar.circle.fill")
                }
                .tag(1)

            HistoryView()
                .tabItem {
                    Label("Historique", systemImage: "clock.fill")
                }
                .tag(2)

            SettingsView()
                .tabItem {
                    Label("Réglages", systemImage: "gearshape.fill")
                }
                .tag(3)
        }
        .tint(.appPrimary)
    }
}

#Preview {
    MainTabView()
}
