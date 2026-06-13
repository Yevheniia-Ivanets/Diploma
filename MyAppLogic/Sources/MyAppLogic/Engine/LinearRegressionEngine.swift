/// The result of a least-squares linear regression fit.
public struct LinearRegressionResult: Sendable {
    /// Rate of change: how much y increases per unit of x.
    public let slope: Double
    /// The y-intercept: the value of y when x equals zero.
    public let intercept: Double

    /// Returns the predicted y value for a given x using y = slope * x + intercept.
    public func predict(x: Double) -> Double {
        slope * x + intercept
    }
}

/// Fits a simple ordinary least-squares linear regression model to (x, y) data points.
public struct LinearRegressionEngine: Sendable {

    public init() {}

    /// Fits a line **y = slope * x + intercept** to the input points.
    ///
    /// Uses the closed-form least-squares solution:
    /// - slope     = (n·Σxy − Σx·Σy) / (n·Σx² − (Σx)²)
    /// - intercept = (Σy − slope·Σx) / n
    ///
    /// - Parameter points: An array of (x, y) observations. Requires at least 2 distinct x values.
    /// - Returns: A `LinearRegressionResult`, or `nil` when fewer than 2 points are supplied
    ///   or when all x values are identical (degenerate vertical line).
    public func fit(points: [(x: Double, y: Double)]) -> LinearRegressionResult? {
        let n = Double(points.count)
        guard n >= 2 else { return nil }

        let sumX  = points.reduce(0.0) { $0 + $1.x }
        let sumY  = points.reduce(0.0) { $0 + $1.y }
        let sumXY = points.reduce(0.0) { $0 + $1.x * $1.y }
        let sumX2 = points.reduce(0.0) { $0 + $1.x * $1.x }

        let denominator = n * sumX2 - sumX * sumX
        guard denominator != 0 else { return nil }

        let slope     = (n * sumXY - sumX * sumY) / denominator
        let intercept = (sumY - slope * sumX) / n

        return LinearRegressionResult(slope: slope, intercept: intercept)
    }

    /// Generates predicted y values for the next `days` time steps beyond the last x value in `points`.
    ///
    /// Each forecasted point uses `lastX + day` as its x coordinate (day = 1, 2, …, days).
    ///
    /// - Parameters:
    ///   - points: Historical (x, y) observations used to fit the model.
    ///   - days:   Number of future steps to predict. Non-positive values produce an empty result.
    /// - Returns: An array of `(x, predicted)` tuples, or an empty array when `fit` returns `nil`
    ///   or `days` is not positive.
    public func forecast(
        points: [(x: Double, y: Double)],
        days: Int
    ) -> [(x: Double, predicted: Double)] {
        guard let model = fit(points: points), days > 0 else { return [] }
        let lastX = points.map(\.x).max() ?? 0
        return (1...days).map { day in
            let x = lastX + Double(day)
            return (x: x, predicted: model.predict(x: x))
        }
    }
}
