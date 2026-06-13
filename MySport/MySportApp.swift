import SwiftUI
import SwiftData

@main
struct MySportApp: App {
    @State private var healthKit = HealthKitManager()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(healthKit)
        }
        .modelContainer(
            for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self],
            onSetup: { result in
                if case .success(let container) = result {
                    seedSampleWorkouts(into: container.mainContext)
                }
            }
        )
    }

    private func seedSampleWorkouts(into context: ModelContext) {
        let descriptor = FetchDescriptor<WorkoutPlan>()
        guard (try? context.fetchCount(descriptor)) == 0 else { return }

        let samples: [WorkoutPlan] = [
            WorkoutPlan(title: "Ранкова мобілізація", workoutType: "Йога",    intensity: "Низька",   durationMinutes: 15),
            WorkoutPlan(title: "HIIT Кардіо",         workoutType: "Кардіо",  intensity: "Висока",   durationMinutes: 30),
            WorkoutPlan(title: "Сила спини",           workoutType: "Силове", intensity: "Середня",  durationMinutes: 45)
        ]
        samples.forEach { context.insert($0) }
        try? context.save()
    }
}
