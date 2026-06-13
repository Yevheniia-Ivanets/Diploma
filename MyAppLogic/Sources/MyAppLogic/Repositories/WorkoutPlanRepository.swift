import Foundation

/// Persistence contract for `WorkoutPlan` objects.
/// Conform to this protocol to provide a real (SwiftData / Firebase) storage back-end.
public protocol WorkoutPlanRepository {
    /// Persists a new workout plan.
    mutating func save(_ plan: WorkoutPlan)
    /// Returns all stored plans in insertion order.
    func fetchAll() -> [WorkoutPlan]
    /// Marks the plan with the given identifier as completed.
    mutating func markAsCompleted(id: UUID)
}

/// In-memory implementation for unit tests and SwiftUI previews.
public struct MockWorkoutPlanRepository: WorkoutPlanRepository, Sendable {

    private var plans: [WorkoutPlan] = []

    public init() {}

    public mutating func save(_ plan: WorkoutPlan) {
        plans.append(plan)
    }

    public func fetchAll() -> [WorkoutPlan] {
        plans
    }

    public mutating func markAsCompleted(id: UUID) {
        guard let index = plans.firstIndex(where: { $0.id == id }) else { return }
        plans[index].isCompleted = true
    }
}
