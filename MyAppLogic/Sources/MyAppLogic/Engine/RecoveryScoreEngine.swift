/// Calculates a composite recovery score (0–100) from biometric data.
///
/// Weights:
/// - HRV      40 % — 20 ms → 0 %, 80 ms → 100 %
/// - Sleep    35 % — 5 h  → 0 %, 9 h  → 100 %
/// - RHR      25 % — 80 bpm → 0 %, 40 bpm → 100 %
public struct RecoveryScoreEngine: Sendable {

    public init() {}

    /// Computes a recovery score clamped to 0–100.
    ///
    /// - Parameter metric: The biometric snapshot to evaluate.
    /// - Returns: A `Double` in the range [0, 100].
    public func calculate(from metric: HealthMetric) -> Double {
        let hrvScore   = normalise(metric.hrv, low: 20, high: 80)
        let sleepScore = normalise(metric.sleepHours, low: 5, high: 9)
        // RHR is inverted: lower bpm is better. Map 80→0, 40→100 by inverting.
        let rhrScore   = normalise(80 - metric.restingHeartRate, low: 0, high: 40)

        let raw = (hrvScore * 0.4) + (sleepScore * 0.35) + (rhrScore * 0.25)
        return min(max(raw, 0), 100)
    }

    /// Linearly maps `value` into [0, 100] between `low` (→ 0) and `high` (→ 100).
    private func normalise(_ value: Double, low: Double, high: Double) -> Double {
        let clamped = min(max(value, low), high)
        return (clamped - low) / (high - low) * 100
    }
}
