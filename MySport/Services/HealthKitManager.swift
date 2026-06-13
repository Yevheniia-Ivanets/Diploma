import HealthKit
import Observation

@Observable
final class HealthKitManager {
    private let store = HKHealthStore()

    var isAuthorized = false
    var latestHRV: Double = 0
    var latestRestingHR: Double = 0
    var lastSleepHours: Double = 0

    var isAvailable: Bool { HKHealthStore.isHealthDataAvailable() }

    private var readTypes: Set<HKObjectType> {
        var types = Set<HKObjectType>()
        if let hrv = HKObjectType.quantityType(forIdentifier: .heartRateVariabilitySDNN) { types.insert(hrv) }
        if let rhr = HKObjectType.quantityType(forIdentifier: .restingHeartRate) { types.insert(rhr) }
        if let sleep = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) { types.insert(sleep) }
        return types
    }

    func requestAuthorization() async {
        guard isAvailable else { return }
        do {
            try await store.requestAuthorization(toShare: [], read: readTypes)
            isAuthorized = true
            await fetchAllMetrics()
        } catch {
            print("HealthKit authorization error: \(error)")
        }
    }

    func fetchAllMetrics() async {
        async let hrv = fetchLatestHRV()
        async let rhr = fetchLatestRestingHeartRate()
        async let sleep = fetchLastNightSleep()
        latestHRV = await hrv
        latestRestingHR = await rhr
        lastSleepHours = await sleep
    }

    private func fetchLatestHRV() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return 0 }
        return await fetchLatestSample(type: type, unit: .secondUnit(with: .milli))
    }

    private func fetchLatestRestingHeartRate() async -> Double {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return 0 }
        return await fetchLatestSample(type: type, unit: HKUnit.count().unitDivided(by: .minute()))
    }

    private func fetchLatestSample(type: HKQuantityType, unit: HKUnit) async -> Double {
        let startDate = Calendar.current.date(byAdding: .day, value: -7, to: .now)
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: .now)
        let sort = NSSortDescriptor(key: HKSampleSortIdentifierEndDate, ascending: false)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: 1,
                sortDescriptors: [sort]
            ) { _, samples, _ in
                let value = (samples?.first as? HKQuantitySample)?.quantity.doubleValue(for: unit) ?? 0
                continuation.resume(returning: value)
            }
            store.execute(query)
        }
    }

    private func fetchLastNightSleep() async -> Double {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return 0 }
        let yesterday = Calendar.current.date(byAdding: .day, value: -1, to: .now) ?? .now
        let predicate = HKQuery.predicateForSamples(withStart: yesterday, end: .now)

        return await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, samples, _ in
                let asleepValues: Set<Int> = [
                    HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
                    HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                    HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                    HKCategoryValueSleepAnalysis.asleepREM.rawValue
                ]
                let total = ((samples as? [HKCategorySample]) ?? [])
                    .filter { asleepValues.contains($0.value) }
                    .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }
                continuation.resume(returning: total / 3600)
            }
            store.execute(query)
        }
    }

    // MARK: - History (for Analytics)

    func fetchHRVHistory(days: Int) async -> [(date: Date, value: Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .heartRateVariabilitySDNN) else { return [] }
        return await fetchDailyQuantityHistory(type: type, unit: .secondUnit(with: .milli), days: days)
    }

    func fetchRHRHistory(days: Int) async -> [(date: Date, value: Double)] {
        guard let type = HKQuantityType.quantityType(forIdentifier: .restingHeartRate) else { return [] }
        return await fetchDailyQuantityHistory(type: type, unit: HKUnit.count().unitDivided(by: .minute()), days: days)
    }

    func fetchSleepHistory(days: Int) async -> [(date: Date, value: Double)] {
        guard let type = HKObjectType.categoryType(forIdentifier: .sleepAnalysis) else { return [] }
        let calendar = Calendar.current
        let endDate = Date()
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        let samples: [HKCategorySample] = await withCheckedContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: nil
            ) { _, results, _ in
                continuation.resume(returning: (results as? [HKCategorySample]) ?? [])
            }
            store.execute(query)
        }

        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        var dailyTotals: [Date: Double] = [:]
        for sample in samples where asleepValues.contains(sample.value) {
            let day = calendar.startOfDay(for: sample.startDate)
            let hours = sample.endDate.timeIntervalSince(sample.startDate) / 3600
            dailyTotals[day, default: 0] += hours
        }

        return dailyTotals.sorted(by: { $0.key < $1.key }).map { (date: $0.key, value: $0.value) }
    }

    private func fetchDailyQuantityHistory(type: HKQuantityType, unit: HKUnit, days: Int) async -> [(date: Date, value: Double)] {
        let calendar = Calendar.current
        let endDate = calendar.startOfDay(for: Date()).addingTimeInterval(86400)
        guard let startDate = calendar.date(byAdding: .day, value: -days, to: endDate) else { return [] }
        let predicate = HKQuery.predicateForSamples(withStart: startDate, end: endDate)

        return await withCheckedContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: type,
                quantitySamplePredicate: predicate,
                options: [.discreteAverage],
                anchorDate: calendar.startOfDay(for: endDate),
                intervalComponents: DateComponents(day: 1)
            )
            query.initialResultsHandler = { _, results, _ in
                guard let results else {
                    continuation.resume(returning: [])
                    return
                }
                var output: [(date: Date, value: Double)] = []
                results.enumerateStatistics(from: startDate, to: endDate) { stats, _ in
                    if let avg = stats.averageQuantity() {
                        output.append((date: stats.startDate, value: avg.doubleValue(for: unit)))
                    }
                }
                continuation.resume(returning: output)
            }
            self.store.execute(query)
        }
    }
}
