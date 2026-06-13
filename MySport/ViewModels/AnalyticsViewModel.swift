import Foundation
import SwiftData
import Observation

// MARK: - TimeRange

enum TimeRange: String, CaseIterable {
    case week  = "Week"
    case month = "Month"

    var days: Int { self == .week ? 7 : 30 }
}

// MARK: - MuscleLoad

struct MuscleLoad: Identifiable {
    let id = UUID()
    let name: String
    let load: Double   // 0.0 – 1.0
    let colorKey: String
}

// MARK: - AnalyticsViewModel

@Observable
final class AnalyticsViewModel {

    // MARK: State

    var timeRange: TimeRange = .week
    var isLoading = false

    var hrvHistory:      [(date: Date, value: Double)] = []
    var rhrHistory:      [(date: Date, value: Double)] = []
    var sleepHistory:    [(date: Date, value: Double)] = []
    var recoveryHistory: [(date: Date, value: Double)] = []
    var recoveryForecast: [Double] = []
    var muscleLoads: [MuscleLoad] = []

    // MARK: Derived

    var latestHRV: Double { hrvHistory.last?.value ?? 0 }

    var hrvTrend: Double {
        guard hrvHistory.count >= 2 else { return 0 }
        let first = hrvHistory.first!.value
        let last  = hrvHistory.last!.value
        return (last - first) / max(first, 1) * 100
    }

    var latestRecovery: Double { recoveryHistory.last?.value ?? 0 }

    var forecastedBoost: Double {
        guard let last = recoveryHistory.last?.value,
              let predicted = recoveryForecast.last else { return 0 }
        return predicted - last
    }

    // MARK: Load

    @MainActor
    func loadData(using healthKit: HealthKitManager, modelContext: ModelContext) async {
        isLoading = true
        let days = timeRange.days

        async let hrv   = healthKit.fetchHRVHistory(days: days)
        async let rhr   = healthKit.fetchRHRHistory(days: days)
        async let sleep = healthKit.fetchSleepHistory(days: days)

        let (h, r, s) = await (hrv, rhr, sleep)
        hrvHistory   = h
        rhrHistory   = r
        sleepHistory = s

        recoveryHistory  = computeRecoveryHistory(hrv: h, rhr: r, sleep: s)

        if recoveryHistory.count >= 2 {
            recoveryForecast = LinearRegressionEngine.forecast(
                from: recoveryHistory.map(\.value),
                futureDays: 7
            )
        } else {
            recoveryForecast = []
        }

        muscleLoads = computeMuscleLoads(modelContext: modelContext, days: days)
        isLoading = false
    }

    // MARK: Private helpers

    private func computeRecoveryHistory(
        hrv:   [(date: Date, value: Double)],
        rhr:   [(date: Date, value: Double)],
        sleep: [(date: Date, value: Double)]
    ) -> [(date: Date, value: Double)] {
        let cal = Calendar.current
        let hrvMap   = Dictionary(hrv.map   { (cal.startOfDay(for: $0.date), $0.value) }, uniquingKeysWith: { $1 })
        let rhrMap   = Dictionary(rhr.map   { (cal.startOfDay(for: $0.date), $0.value) }, uniquingKeysWith: { $1 })
        let sleepMap = Dictionary(sleep.map { (cal.startOfDay(for: $0.date), $0.value) }, uniquingKeysWith: { $1 })

        let allDates = Set(hrvMap.keys).union(rhrMap.keys).union(sleepMap.keys)
        return allDates.sorted().map { date in
            let result = RecoveryEngine.calculate(
                hrv: hrvMap[date] ?? 0,
                restingHR: rhrMap[date] ?? 0,
                sleepHours: sleepMap[date] ?? 0
            )
            return (date: date, value: Double(result.score))
        }
    }

    private func computeMuscleLoads(modelContext: ModelContext, days: Int) -> [MuscleLoad] {
        let cutoff = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        let descriptor = FetchDescriptor<WorkoutPlan>(
            predicate: #Predicate { $0.isCompleted && $0.date >= cutoff }
        )
        let plans = (try? modelContext.fetch(descriptor)) ?? []

        var groupTotals: [String: Double] = [:]
        for plan in plans {
            for (group, weight) in muscleGroupWeights(for: plan.workoutType) {
                groupTotals[group, default: 0] += weight
            }
        }

        guard !groupTotals.isEmpty else { return [] }
        let maxLoad = groupTotals.values.max() ?? 1

        let order    = ["Quadriceps", "Chest", "Back", "Shoulders", "Hamstrings", "Core"]
        let colorMap: [String: String] = [
            "Quadriceps": "fitnessAccent",
            "Chest":      "orange",
            "Back":       "fitnessPrimary",
            "Shoulders":  "blue",
            "Hamstrings": "purple",
            "Core":       "yellow"
        ]

        return order.compactMap { group in
            guard let raw = groupTotals[group] else { return nil }
            return MuscleLoad(name: group, load: raw / maxLoad, colorKey: colorMap[group] ?? "white")
        }
    }

    private func muscleGroupWeights(for workoutType: String) -> [(String, Double)] {
        switch workoutType.lowercased() {
        case "hiit", "кардіо":
            return [("Quadriceps", 0.8), ("Hamstrings", 0.6), ("Core", 0.4)]
        case "силове", "strength":
            return [("Chest", 0.9), ("Back", 0.7), ("Shoulders", 0.6)]
        case "йога", "yoga", "розтяжка":
            return [("Core", 0.5), ("Hamstrings", 0.4), ("Back", 0.3)]
        default:
            return [("Core", 0.5)]
        }
    }
}
