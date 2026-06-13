import SwiftData
import Foundation

@Model
final class WorkoutPlan {
    var title: String
    var workoutType: String
    var intensity: String
    var durationMinutes: Int
    var isCompleted: Bool
    var date: Date
    var recoveryScoreAtCreation: Int

    init(
        title: String,
        workoutType: String,
        intensity: String,
        durationMinutes: Int,
        recoveryScoreAtCreation: Int = 0
    ) {
        self.title = title
        self.workoutType = workoutType
        self.intensity = intensity
        self.durationMinutes = durationMinutes
        self.isCompleted = false
        self.date = .now
        self.recoveryScoreAtCreation = recoveryScoreAtCreation
    }
}
