import Foundation
import Observation

@Observable
final class UnitsViewModel {

    // MARK: - Ground truth (always metric, persisted immediately)

    var weightKg: Double {
        didSet { UserDefaults.standard.set(weightKg, forKey: "userWeightKg") }
    }
    var heightCm: Double {
        didSet { UserDefaults.standard.set(heightCm, forKey: "userHeightCm") }
    }
    var useMetric: Bool {
        didSet { UserDefaults.standard.set(useMetric, forKey: "useMetricUnits") }
    }

    init() {
        let w = UserDefaults.standard.double(forKey: "userWeightKg")
        let h = UserDefaults.standard.double(forKey: "userHeightCm")
        weightKg = w > 0 ? w : 70.0
        heightCm = h > 0 ? h : 175.0
        useMetric = UserDefaults.standard.object(forKey: "useMetricUnits") as? Bool ?? true
    }

    // MARK: - Imperial read-only derivations

    var weightLbs: Double { weightKg * 2.20462 }
    var heightFeet: Int   { Int(heightCm / 2.54) / 12 }
    var heightInches: Int { Int(heightCm / 2.54) % 12 }

    // MARK: - Write-back from imperial inputs

    func setFromImperialWeight(_ lbs: Double) {
        // round to 1 decimal to avoid float drift
        weightKg = (lbs / 2.20462 * 10).rounded() / 10
    }

    func setFromImperialHeight(feet: Int, inches: Int) {
        // round to nearest cm to guarantee clean round-trips
        heightCm = (Double(feet * 12 + inches) * 2.54).rounded()
    }
}
