import Foundation
import SwiftData
import Observation

@Observable
final class WorkoutsViewModel {

    var todaysPlans: [WorkoutPlan] = []
    var showHistory = false

    // MARK: - Load

    func loadTodaysPlans(from allPlans: [WorkoutPlan], context: ModelContext) {
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: Date())
        let endOfDay   = calendar.date(byAdding: .day, value: 1, to: startOfDay)!

        todaysPlans = allPlans.filter { $0.date >= startOfDay && $0.date < endOfDay }

        if todaysPlans.isEmpty {
            generateTodaysPlan(recentPlans: allPlans, into: context)
        }
    }

    // MARK: - Generation

    private func generateTodaysPlan(recentPlans: [WorkoutPlan], into context: ModelContext) {
        // Use the most recent stored recovery score so the recommendation
        // reflects actual fitness state rather than fixed demo values.
        let lastScore = recentPlans.first?.recoveryScoreAtCreation ?? 75
        let result = RecoveryEngine.calculate(
            hrv: scoreToHRV(lastScore),
            restingHR: scoreToRHR(lastScore),
            sleepHours: 7.5
        )
        let rec = result.recommendation
        let plan = WorkoutPlan(
            title: rec.subtitle,
            workoutType: rec.workoutType,
            intensity: rec.intensity,
            durationMinutes: rec.durationMinutes,
            recoveryScoreAtCreation: result.score
        )
        context.insert(plan)
        todaysPlans = [plan]
    }

    // Map a stored 0–100 score back to plausible HRV / RHR inputs so that
    // RecoveryEngine produces the same tier recommendation as yesterday.
    private func scoreToHRV(_ score: Int) -> Double {
        // HRV range used by RecoveryEngine: 20 ms (0%) → 80 ms (100%)
        return 20 + Double(score) / 100.0 * 60
    }

    private func scoreToRHR(_ score: Int) -> Double {
        // RHR range: 75 bpm (0%) → 50 bpm (100%)
        return 75 - Double(score) / 100.0 * 25
    }
}
