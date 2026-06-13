import Observation

@Observable
final class TodayViewModel {
    var recoveryScore: Int = 82
    var recommendation: WorkoutRecommendation = RecoveryEngine
        .calculate(hrv: 0, restingHR: 0, sleepHours: 0)
        .recommendation
    var isLoading = false

    func refresh(using healthKit: HealthKitManager) async {
        isLoading = true
        if healthKit.isAvailable {
            await healthKit.fetchAllMetrics()
        }
        let result = RecoveryEngine.calculate(
            hrv: healthKit.latestHRV,
            restingHR: healthKit.latestRestingHR,
            sleepHours: healthKit.lastSleepHours
        )
        recoveryScore = result.score
        recommendation = result.recommendation
        isLoading = false
    }
}
