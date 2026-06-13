import Foundation

struct LinearRegressionEngine {

    /// Returns `futureDays` predicted values following the last value in `values`.
    static func forecast(from values: [Double], futureDays: Int) -> [Double] {
        guard values.count >= 2 else {
            return Array(repeating: values.first ?? 0, count: futureDays)
        }

        let n = Double(values.count)
        let xMean = (n - 1) / 2
        let yMean = values.reduce(0, +) / n

        var numerator: Double = 0
        var denominator: Double = 0
        for (i, y) in values.enumerated() {
            let x = Double(i)
            numerator   += (x - xMean) * (y - yMean)
            denominator += (x - xMean) * (x - xMean)
        }

        let slope     = denominator != 0 ? numerator / denominator : 0
        let intercept = yMean - slope * xMean
        let lastIndex = values.count - 1

        return (1...futureDays).map { day in
            let x = Double(lastIndex + day)
            return slope * x + intercept
        }
    }
}
