import XCTest
@testable import MyAppLogic

final class RecoveryScoreEngineTests: XCTestCase {

    private let engine = RecoveryScoreEngine()

    // MARK: – Perfect recovery

    func testPerfectRecovery() {
        // hrv=80 → 100%, sleep=9 → 100%, rhr=40 → 100%  →  score = 100
        let metric = HealthMetric(hrv: 80, restingHeartRate: 40, sleepHours: 9)
        XCTAssertEqual(engine.calculate(from: metric), 100.0, accuracy: 0.001)
    }

    // MARK: – Poor recovery

    func testPoorRecovery() {
        // hrv=20 → 0%, sleep=5 → 0%, rhr=80 → 0%  →  score = 0
        let metric = HealthMetric(hrv: 20, restingHeartRate: 80, sleepHours: 5)
        XCTAssertEqual(engine.calculate(from: metric), 0.0, accuracy: 0.001)
    }

    // MARK: – Average recovery

    func testAverageRecovery() {
        // hrv=50  → (50-20)/60*100 = 50
        // sleep=7 → (7-5)/4*100   = 50
        // rhr=60  → (80-60)/40*100 = 50
        // score   = 50*0.4 + 50*0.35 + 50*0.25 = 50
        let metric = HealthMetric(hrv: 50, restingHeartRate: 60, sleepHours: 7)
        XCTAssertEqual(engine.calculate(from: metric), 50.0, accuracy: 0.001)
    }

    // MARK: – Edge cases

    func testValuesBeforeMinimumClampToZero() {
        let metric = HealthMetric(hrv: 0, restingHeartRate: 120, sleepHours: 0)
        XCTAssertEqual(engine.calculate(from: metric), 0.0, accuracy: 0.001)
    }

    func testValuesAboveMaximumClampToHundred() {
        let metric = HealthMetric(hrv: 200, restingHeartRate: 20, sleepHours: 24)
        XCTAssertEqual(engine.calculate(from: metric), 100.0, accuracy: 0.001)
    }

    func testScoreIsAlwaysWithinBounds() {
        let metric = HealthMetric(hrv: 55, restingHeartRate: 58, sleepHours: 7.5)
        let score = engine.calculate(from: metric)
        XCTAssertGreaterThanOrEqual(score, 0)
        XCTAssertLessThanOrEqual(score, 100)
    }

    func testWeightedContributionOfHRV() {
        // Only HRV contributes: perfect HRV, worst sleep and RHR
        // hrv=80 → 100%*0.4 = 40 | sleep=5 → 0 | rhr=80 → 0  →  score = 40
        let metric = HealthMetric(hrv: 80, restingHeartRate: 80, sleepHours: 5)
        XCTAssertEqual(engine.calculate(from: metric), 40.0, accuracy: 0.001)
    }

    func testWeightedContributionOfSleep() {
        // Only Sleep contributes: worst HRV and RHR, perfect sleep
        // hrv=20 → 0 | sleep=9 → 100%*0.35 = 35 | rhr=80 → 0  →  score = 35
        let metric = HealthMetric(hrv: 20, restingHeartRate: 80, sleepHours: 9)
        XCTAssertEqual(engine.calculate(from: metric), 35.0, accuracy: 0.001)
    }

    func testWeightedContributionOfRHR() {
        // Only RHR contributes: worst HRV and sleep, perfect RHR
        // hrv=20 → 0 | sleep=5 → 0 | rhr=40 → 100%*0.25 = 25  →  score = 25
        let metric = HealthMetric(hrv: 20, restingHeartRate: 40, sleepHours: 5)
        XCTAssertEqual(engine.calculate(from: metric), 25.0, accuracy: 0.001)
    }
}
