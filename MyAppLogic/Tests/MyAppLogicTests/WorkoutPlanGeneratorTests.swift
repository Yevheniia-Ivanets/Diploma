import XCTest
@testable import MyAppLogic

final class WorkoutPlanGeneratorTests: XCTestCase {

    private let generator = WorkoutPlanGenerator()

    // MARK: – Rest zone (0–25)

    func testRestZone_lowerBound() {
        let plan = generator.generate(recoveryScore: 0)
        XCTAssertEqual(plan.type, .rest)
        XCTAssertEqual(plan.intensity, .none)
        XCTAssertEqual(plan.durationMinutes, 0)
    }

    func testRestZone_midpoint() {
        let plan = generator.generate(recoveryScore: 12)
        XCTAssertEqual(plan.type, .rest)
    }

    func testRestZone_upperBound() {
        let plan = generator.generate(recoveryScore: 25)
        XCTAssertEqual(plan.type, .rest)
        XCTAssertEqual(plan.intensity, .none)
        XCTAssertEqual(plan.durationMinutes, 0)
    }

    // MARK: – Mobility zone (26–45)

    func testMobilityZone_lowerBound() {
        let plan = generator.generate(recoveryScore: 26)
        XCTAssertEqual(plan.type, .mobility)
        XCTAssertEqual(plan.intensity, .low)
        XCTAssertEqual(plan.durationMinutes, 20)
    }

    func testMobilityZone_midpoint() {
        let plan = generator.generate(recoveryScore: 35)
        XCTAssertEqual(plan.type, .mobility)
    }

    func testMobilityZone_upperBound() {
        let plan = generator.generate(recoveryScore: 45)
        XCTAssertEqual(plan.type, .mobility)
        XCTAssertEqual(plan.intensity, .low)
        XCTAssertEqual(plan.durationMinutes, 20)
    }

    // MARK: – Cardio zone (46–65)

    func testCardioZone_lowerBound() {
        let plan = generator.generate(recoveryScore: 46)
        XCTAssertEqual(plan.type, .cardio)
        XCTAssertEqual(plan.intensity, .medium)
        XCTAssertEqual(plan.durationMinutes, 40)
    }

    func testCardioZone_midpoint() {
        let plan = generator.generate(recoveryScore: 55)
        XCTAssertEqual(plan.type, .cardio)
    }

    func testCardioZone_upperBound() {
        let plan = generator.generate(recoveryScore: 65)
        XCTAssertEqual(plan.type, .cardio)
        XCTAssertEqual(plan.intensity, .medium)
        XCTAssertEqual(plan.durationMinutes, 40)
    }

    // MARK: – Strength Light zone (66–85)

    func testStrengthLightZone_lowerBound() {
        let plan = generator.generate(recoveryScore: 66)
        XCTAssertEqual(plan.type, .strengthLight)
        XCTAssertEqual(plan.intensity, .medium)
        XCTAssertEqual(plan.durationMinutes, 50)
    }

    func testStrengthLightZone_midpoint() {
        let plan = generator.generate(recoveryScore: 75)
        XCTAssertEqual(plan.type, .strengthLight)
    }

    func testStrengthLightZone_upperBound() {
        let plan = generator.generate(recoveryScore: 85)
        XCTAssertEqual(plan.type, .strengthLight)
        XCTAssertEqual(plan.intensity, .medium)
        XCTAssertEqual(plan.durationMinutes, 50)
    }

    // MARK: – Strength Heavy zone (86–100)

    func testStrengthHeavyZone_lowerBound() {
        let plan = generator.generate(recoveryScore: 86)
        XCTAssertEqual(plan.type, .strengthHeavy)
        XCTAssertEqual(plan.intensity, .high)
        XCTAssertEqual(plan.durationMinutes, 60)
    }

    func testStrengthHeavyZone_midpoint() {
        let plan = generator.generate(recoveryScore: 93)
        XCTAssertEqual(plan.type, .strengthHeavy)
    }

    func testStrengthHeavyZone_upperBound() {
        let plan = generator.generate(recoveryScore: 100)
        XCTAssertEqual(plan.type, .strengthHeavy)
        XCTAssertEqual(plan.intensity, .high)
        XCTAssertEqual(plan.durationMinutes, 60)
    }

    // MARK: – General

    func testNewPlanIsNotCompleted() {
        let plan = generator.generate(recoveryScore: 75)
        XCTAssertFalse(plan.isCompleted)
    }

    func testFractionalScoreInRestZone() {
        // 25.9 should still be rest (< 26)
        let plan = generator.generate(recoveryScore: 25.9)
        XCTAssertEqual(plan.type, .rest)
    }

    func testFractionalScoreBoundaryMobility() {
        // 26.1 should be mobility
        let plan = generator.generate(recoveryScore: 26.1)
        XCTAssertEqual(plan.type, .mobility)
    }
}
