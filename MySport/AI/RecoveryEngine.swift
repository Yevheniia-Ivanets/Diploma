import Foundation

struct WorkoutRecommendation {
    let title: String
    let subtitle: String
    let workoutType: String
    let intensity: String
    let durationMinutes: Int
}

struct RecoveryResult {
    let score: Int
    let recommendation: WorkoutRecommendation
}

struct RecoveryEngine {

    static func calculate(hrv: Double, restingHR: Double, sleepHours: Double) -> RecoveryResult {
        // HRV component (40%): 20 ms → 0 %, 80 ms → 100 %
        let hrvScore: Double = hrv > 0
            ? min(max((hrv - 20) / 60.0, 0), 1) * 100
            : 68

        // Sleep component (40%): 5 h → 0 %, 8 h → 100 %
        let sleepScore: Double = sleepHours > 0
            ? min(max((sleepHours - 5) / 3.0, 0), 1) * 100
            : 75

        // RHR component (20%): 75 bpm → 0 %, 50 bpm → 100 % (lower is better)
        let rhrScore: Double = restingHR > 0
            ? min(max((75 - restingHR) / 25.0, 0), 1) * 100
            : 80

        let score = Int(0.4 * hrvScore + 0.4 * sleepScore + 0.2 * rhrScore)
        return RecoveryResult(score: score, recommendation: buildRecommendation(score: score))
    }

    private static func buildRecommendation(score: Int) -> WorkoutRecommendation {
        switch score {
        case 70...:
            return WorkoutRecommendation(
                title: "Ви готові до рекордів!",
                subtitle: "Рекомендуємо: Інтенсивне кардіо (HIIT)",
                workoutType: "HIIT",
                intensity: "Висока",
                durationMinutes: 40
            )
        case 40..<70:
            return WorkoutRecommendation(
                title: "Помірне навантаження",
                subtitle: "Рекомендуємо: Силове тренування (база)",
                workoutType: "Силове",
                intensity: "Середня",
                durationMinutes: 45
            )
        default:
            return WorkoutRecommendation(
                title: "Тілу потрібен відпочинок",
                subtitle: "Рекомендуємо: Йога або розтяжка",
                workoutType: "Йога",
                intensity: "Низька",
                durationMinutes: 20
            )
        }
    }
}
