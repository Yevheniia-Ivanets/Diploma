import Foundation

/// Generates a daily `WorkoutPlan` based on a recovery score.
public struct WorkoutPlanGenerator: Sendable {

    public init() {}

    /// Creates a `WorkoutPlan` matched to the given recovery score.
    ///
    /// Recovery zones:
    /// - 0 – 25 : rest
    /// - 26 – 45 : mobility / low
    /// - 46 – 65 : cardio / medium
    /// - 66 – 85 : strength light / medium
    /// - 86 – 100: strength heavy / high
    ///
    /// - Parameters:
    ///   - recoveryScore: A value in 0–100 produced by `RecoveryScoreEngine`.
    ///   - date: The date for which the plan is generated (defaults to today).
    /// - Returns: A fully populated `WorkoutPlan`.
    public func generate(recoveryScore: Double, date: Date = Date()) -> WorkoutPlan {
        switch recoveryScore {
        case ..<26:
            return WorkoutPlan(date: date, type: .rest,          intensity: .none,   durationMinutes: 0)
        case ..<46:
            return WorkoutPlan(date: date, type: .mobility,      intensity: .low,    durationMinutes: 20)
        case ..<66:
            return WorkoutPlan(date: date, type: .cardio,        intensity: .medium, durationMinutes: 40)
        case ..<86:
            return WorkoutPlan(date: date, type: .strengthLight, intensity: .medium, durationMinutes: 50)
        default:
            return WorkoutPlan(date: date, type: .strengthHeavy, intensity: .high,   durationMinutes: 60)
        }
    }
}
