import SwiftData
import Foundation

@Model
final class HealthMetric {
    var date: Date
    var hrv: Double
    var restingHeartRate: Double
    var sleepHours: Double
    var recoveryScore: Int

    init(
        date: Date = .now,
        hrv: Double = 0,
        restingHeartRate: Double = 0,
        sleepHours: Double = 0,
        recoveryScore: Int = 0
    ) {
        self.date = date
        self.hrv = hrv
        self.restingHeartRate = restingHeartRate
        self.sleepHours = sleepHours
        self.recoveryScore = recoveryScore
    }
}
