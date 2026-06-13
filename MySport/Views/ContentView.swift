import SwiftUI
import SwiftData

struct ContentView: View {
    @Environment(HealthKitManager.self) private var healthKit
    @AppStorage("onboardingComplete") private var onboardingComplete = false

    var body: some View {
        if onboardingComplete {
            MainTabView()
        } else {
            OnboardingView(isOnboardingComplete: $onboardingComplete)
        }
    }
}

struct MainTabView: View {
    @State private var selectedTab = 0
    @AppStorage("appLanguage") private var appLanguage: String = "uk"

    var body: some View {
        TabView(selection: $selectedTab) {
            TodayRecoveryView(selectedTab: $selectedTab)
                .tabItem { Label(t(.tabToday), systemImage: "heart.fill") }
                .tag(0)

            WorkoutsView()
                .tabItem { Label(t(.tabWorkouts), systemImage: "figure.run") }
                .tag(1)

            AnalyticsView()
                .tabItem { Label(t(.tabAnalytics), systemImage: "chart.line.uptrend.xyaxis") }
                .tag(2)

            SettingsView()
                .tabItem { Label(t(.tabProfile), systemImage: "person.fill") }
                .tag(3)
        }
        .tint(.fitnessPrimary)
        .id(appLanguage)
    }
}

#Preview {
    ContentView()
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self], inMemory: true)
}
