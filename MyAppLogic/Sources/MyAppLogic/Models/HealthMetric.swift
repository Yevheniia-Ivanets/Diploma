import Foundation

/// A single biometric snapshot captured on a given date.
public struct HealthMetric: Sendable, Identifiable {
    public let id: UUID
    /// Date of the measurement.
    public let date: Date
    /// Heart Rate Variability in milliseconds.
    public var hrv: Double
    /// Resting Heart Rate in beats per minute.
    public var restingHeartRate: Double
    /// Total sleep duration in hours.
    public var sleepHours: Double

    public init(
        id: UUID = UUID(),
        date: Date = Date(),
        hrv: Double,
        restingHeartRate: Double,
        sleepHours: Double
    ) {
        self.id = id
        self.date = date
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.sleepHours = sleepHours
    }
}
