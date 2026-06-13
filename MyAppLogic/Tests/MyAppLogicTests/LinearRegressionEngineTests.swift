import XCTest
@testable import MyAppLogic

final class LinearRegressionEngineTests: XCTestCase {

    private let engine = LinearRegressionEngine()

    // MARK: - fit() - perfect linear data

    func testPerfectLinearFit_slope() {
        // y = 2x + 1  ->  (0,1) (1,3) (2,5) (3,7)
        // denom = 4*14 - 6*6 = 20  ->  slope = (4*34 - 6*16)/20 = 40/20 = 2.0
        let pts: [(x: Double, y: Double)] = [(0, 1), (1, 3), (2, 5), (3, 7)]
        let result = engine.fit(points: pts)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.slope, 2.0, accuracy: 1e-9)
    }

    func testPerfectLinearFit_intercept() {
        // intercept = (16 - 2.0*6) / 4 = 1.0
        let pts: [(x: Double, y: Double)] = [(0, 1), (1, 3), (2, 5), (3, 7)]
        let result = engine.fit(points: pts)!
        XCTAssertEqual(result.intercept, 1.0, accuracy: 1e-9)
    }

    func testPerfectLinearFit_predict() {
        let pts: [(x: Double, y: Double)] = [(0, 1), (1, 3), (2, 5), (3, 7)]
        let result = engine.fit(points: pts)!
        // predict(x: 10) = 2*10 + 1 = 21
        XCTAssertEqual(result.predict(x: 10), 21.0, accuracy: 1e-9)
    }

    // MARK: - fit() - flat data

    func testFlatData_slopeIsZero() {
        // y = 5 for all x  ->  slope must be 0
        let pts: [(x: Double, y: Double)] = [(0, 5), (1, 5), (2, 5)]
        let result = engine.fit(points: pts)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.slope, 0.0, accuracy: 1e-9)
    }

    func testFlatData_interceptIsConstant() {
        let pts: [(x: Double, y: Double)] = [(0, 5), (1, 5), (2, 5)]
        let result = engine.fit(points: pts)!
        XCTAssertEqual(result.intercept, 5.0, accuracy: 1e-9)
    }

    // MARK: - fit() - degenerate / edge cases

    func testSinglePoint_returnsNil() {
        let pts: [(x: Double, y: Double)] = [(1, 2)]
        XCTAssertNil(engine.fit(points: pts))
    }

    func testEmptyArray_returnsNil() {
        let pts: [(x: Double, y: Double)] = []
        XCTAssertNil(engine.fit(points: pts))
    }

    func testVerticalLine_returnsNil() {
        // All x values identical -> denominator = 0 -> undefined slope
        let pts: [(x: Double, y: Double)] = [(3, 1), (3, 5), (3, 9)]
        XCTAssertNil(engine.fit(points: pts))
    }

    func testTwoPoints_exactFit() {
        // (1,3) and (3,7): slope = (7-3)/(3-1) = 2, intercept = 3 - 2*1 = 1
        // Verify: n=2, sumX=4, sumY=10, sumXY=24, sumX2=10
        // denom = 2*10 - 4*4 = 4  ->  slope = (2*24 - 4*10)/4 = 8/4 = 2, intercept = (10-8)/2 = 1
        let pts: [(x: Double, y: Double)] = [(1, 3), (3, 7)]
        let result = engine.fit(points: pts)
        XCTAssertNotNil(result)
        XCTAssertEqual(result!.slope,     2.0, accuracy: 1e-9)
        XCTAssertEqual(result!.intercept, 1.0, accuracy: 1e-9)
    }

    // MARK: - forecast()

    func testForecast_returnsCorrectCount() {
        let pts: [(x: Double, y: Double)] = [(0, 0), (1, 2), (2, 4)]
        let result = engine.forecast(points: pts, days: 5)
        XCTAssertEqual(result.count, 5)
    }

    func testForecast_xValuesStartAfterLastPoint() {
        // lastX = 2  ->  forecasted x must be 3, 4, 5
        let pts: [(x: Double, y: Double)] = [(0, 0), (1, 2), (2, 4)]
        let result = engine.forecast(points: pts, days: 3)
        XCTAssertEqual(result[0].x, 3.0, accuracy: 1e-9)
        XCTAssertEqual(result[1].x, 4.0, accuracy: 1e-9)
        XCTAssertEqual(result[2].x, 5.0, accuracy: 1e-9)
    }

    func testForecast_predictedValuesMatchModel() {
        // y = 2x (slope=2, intercept=0)  ->  predict(3)=6, predict(4)=8, predict(5)=10
        // Verify: n=3, sumX=3, sumY=6, sumXY=10, sumX2=5
        // denom = 3*5 - 3*3 = 6  ->  slope = (3*10-3*6)/6 = 12/6 = 2, intercept = (6-6)/3 = 0
        let pts: [(x: Double, y: Double)] = [(0, 0), (1, 2), (2, 4)]
        let result = engine.forecast(points: pts, days: 3)
        XCTAssertEqual(result[0].predicted,  6.0, accuracy: 1e-9)
        XCTAssertEqual(result[1].predicted,  8.0, accuracy: 1e-9)
        XCTAssertEqual(result[2].predicted, 10.0, accuracy: 1e-9)
    }

    func testForecast_zeroDays_returnsEmpty() {
        let pts: [(x: Double, y: Double)] = [(0, 1), (1, 3)]
        XCTAssertTrue(engine.forecast(points: pts, days: 0).isEmpty)
    }

    func testForecast_negativeDays_returnsEmpty() {
        let pts: [(x: Double, y: Double)] = [(0, 1), (1, 3)]
        XCTAssertTrue(engine.forecast(points: pts, days: -3).isEmpty)
    }

    func testForecast_insufficientPoints_returnsEmpty() {
        // Single point -> fit() returns nil -> forecast must propagate []
        let pts: [(x: Double, y: Double)] = [(0, 1)]
        XCTAssertTrue(engine.forecast(points: pts, days: 7).isEmpty)
    }

    func testForecast_trendingData_valuesIncrease() {
        // Upward trend: slope = 2 > 0  ->  each predicted value must exceed the previous
        let pts: [(x: Double, y: Double)] = [(0, 10), (1, 12), (2, 14), (3, 16)]
        let result = engine.forecast(points: pts, days: 4)
        XCTAssertEqual(result.count, 4)
        for i in 1..<result.count {
            XCTAssertGreaterThan(result[i].predicted, result[i - 1].predicted)
        }
    }
}
