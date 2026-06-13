import Foundation

/// Categories of workout activity.
public enum WorkoutType: String, Sendable, CaseIterable {
    case rest
    case mobility
    case cardio
    case strengthLight
    case strengthHeavy
}

/// Effort level for a workout session.
public enum IntensityLevel: String, Sendable, CaseIterable {
    case none
    case low
    case medium
    case high
}

/// A generated daily workout plan.
public struct WorkoutPlan: Sendable, Identifiable {
    public let id: UUID
    /// Date the plan was generated for.
    public let date: Date
    /// The type of workout recommended.
    public var type: WorkoutType
    /// The recommended effort level.
    public var intensity: IntensityLevel
    /// Duration of the workout in minutes.
    public var durationMinutes: Int
    /// Whether the user has marked this workout as completed.
    public var isCompleted: Bool

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        type: WorkoutType,
        intensity: IntensityLevel,
        durationMinutes: Int,
        isCompleted: Bool = false
    ) {
        self.id = id
        self.date = date
        self.type = type
        self.intensity = intensity
        self.durationMinutes = durationMinutes
        self.isCompleted = isCompleted
    }
}
