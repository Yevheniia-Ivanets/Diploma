/// Persistence contract for `HealthMetric` objects.
/// Conform to this protocol to provide a real (SwiftData / Firebase) storage back-end.
public protocol HealthMetricRepository {
    /// Persists a new metric.
    mutating func save(_ metric: HealthMetric)
    /// Returns all stored metrics in insertion order.
    func fetchAll() -> [HealthMetric]
    /// Returns the most recently saved metric, or `nil` if the store is empty.
    func fetchLatest() -> HealthMetric?
}

/// In-memory implementation for unit tests and SwiftUI previews.
public struct MockHealthMetricRepository: HealthMetricRepository, Sendable {

    private var metrics: [HealthMetric] = []

    public init() {}

    public mutating func save(_ metric: HealthMetric) {
        metrics.append(metric)
    }

    public func fetchAll() -> [HealthMetric] {
        metrics
    }

    public func fetchLatest() -> HealthMetric? {
        metrics.last
    }
}
