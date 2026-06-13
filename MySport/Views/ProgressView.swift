import SwiftUI
import SwiftData

// MARK: - Color theme

extension Color {
    static let fitnessPrimary = Color(red: 19/255,  green: 236/255, blue: 164/255)
    static let fitnessDarkBg  = Color(red: 16/255,  green: 34/255,  blue: 28/255)
    static let fitnessSurface = Color(red: 26/255,  green: 46/255,  blue: 40/255)
    static let fitnessAccent  = Color(red: 255/255, green: 77/255,  blue: 0/255)
}

// MARK: - AnalyticsView

struct AnalyticsView: View {
    @Environment(HealthKitManager.self) private var healthKit
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = AnalyticsViewModel()

    var body: some View {
        NavigationView {
            ZStack {
                Color.fitnessDarkBg.ignoresSafeArea()

                if viewModel.isLoading {
                    VStack(spacing: 16) {
                        ProgressView()
                            .tint(.fitnessPrimary)
                            .scaleEffect(1.5)
                        Text(t(.loadingData))
                            .foregroundStyle(.gray)
                    }
                } else {
                    ScrollView {
                        VStack(spacing: 24) {
                            TimeRangeSelector(
                                selectedRange: Binding(
                                    get: { viewModel.timeRange.rawValue },
                                    set: { raw in
                                        viewModel.timeRange = TimeRange(rawValue: raw) ?? .week
                                    }
                                ),
                                ranges: TimeRange.allCases.map(\.rawValue)
                            )

                            RealHRVTrendCard(
                                history: viewModel.hrvHistory,
                                trend: viewModel.hrvTrend
                            )
                            .padding(.horizontal)

                            RealForecastCard(
                                history: viewModel.recoveryHistory,
                                forecast: viewModel.recoveryForecast,
                                forecastedBoost: viewModel.forecastedBoost
                            )
                            .padding(.horizontal)

                            RealMuscleHeatmapCard(loads: viewModel.muscleLoads)
                                .padding(.horizontal)

                            RecoverySummaryCard(score: Int(viewModel.latestRecovery))
                                .padding(.horizontal)
                                .padding(.bottom, 30)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationBarTitle(t(.analytics), displayMode: .inline)
            .toolbarColorScheme(.dark, for: .navigationBar)
            .toolbarBackground(Color.fitnessDarkBg.opacity(0.8), for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
        }
        .task {
            await viewModel.loadData(using: healthKit, modelContext: modelContext)
        }
        .onChange(of: viewModel.timeRange) {
            Task { await viewModel.loadData(using: healthKit, modelContext: modelContext) }
        }
    }
}

// MARK: - Time Range Selector

struct TimeRangeSelector: View {
    @Binding var selectedRange: String
    let ranges: [String]

    var body: some View {
        HStack {
            ForEach(ranges, id: \.self) { range in
                Button(action: { selectedRange = range }) {
                    Text(range)
                        .font(.system(size: 14, weight: .bold))
                        .padding(.vertical, 8)
                        .frame(maxWidth: .infinity)
                        .background(selectedRange == range ? Color.fitnessPrimary : Color.clear)
                        .foregroundStyle(selectedRange == range ? Color.fitnessDarkBg : Color.gray)
                        .cornerRadius(8)
                }
            }
        }
        .padding(4)
        .background(Color.white.opacity(0.05))
        .cornerRadius(12)
        .padding(.horizontal)
    }
}

// MARK: - Real HRV Trend Card

struct RealHRVTrendCard: View {
    let history: [(date: Date, value: Double)]
    let trend: Double

    private var latestHRV: Double { history.last?.value ?? 0 }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t(.hrvTrend))
                        .font(.caption).foregroundStyle(.gray)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(latestHRV > 0 ? String(format: "%.0f", latestHRV) : "--")
                            .font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                        Text("ms")
                            .font(.caption).foregroundStyle(.gray)
                        if latestHRV > 0 {
                            HStack(spacing: 2) {
                                Image(systemName: trend >= 0 ? "arrow.up.right" : "arrow.down.right")
                                Text(String(format: "%.0f%%", abs(trend)))
                            }
                            .font(.caption).fontWeight(.bold)
                            .foregroundStyle(trend >= 0 ? Color.fitnessPrimary : Color.fitnessAccent)
                            .padding(.leading, 4)
                        }
                    }
                }
                Spacer()
                Text("LAST \(history.count) DAYS")
                    .font(.caption2).fontWeight(.bold).foregroundStyle(.gray)
            }

            if history.isEmpty {
                EmptyDataView(message: t(.noHRVData))
            } else {
                LineChartView(data: history.map(\.value), color: .fitnessPrimary)
                    .frame(height: 120)

                HStack {
                    Text(formatDate(history.first?.date))
                        .font(.caption2).foregroundStyle(.gray)
                    Spacer()
                    Text(formatDate(history.last?.date))
                        .font(.caption2).foregroundStyle(.gray)
                }
            }
        }
        .padding()
        .background(Color.fitnessSurface.opacity(0.6))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func formatDate(_ date: Date?) -> String {
        guard let date else { return "" }
        let f = DateFormatter()
        f.dateFormat = "MMM d"
        return f.string(from: date)
    }
}

// MARK: - Real Forecast Card

struct RealForecastCard: View {
    let history: [(date: Date, value: Double)]
    let forecast: [Double]
    let forecastedBoost: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(t(.resultsForecast))
                        .font(.caption).foregroundStyle(.gray)
                    HStack(alignment: .firstTextBaseline) {
                        Text(String(format: "%+.0f%%", forecastedBoost))
                            .font(.system(size: 32, weight: .bold)).foregroundStyle(.white)
                        Text(t(.recoveryTrend))
                            .font(.caption).fontWeight(.bold).foregroundStyle(Color.fitnessPrimary)
                    }
                }
                Spacer()
                Text(t(.aiInsight))
                    .font(.caption2).fontWeight(.bold)
                    .padding(.horizontal, 8).padding(.vertical, 4)
                    .background(Color.fitnessPrimary.opacity(0.2))
                    .foregroundStyle(Color.fitnessPrimary)
                    .cornerRadius(8)
            }

            if history.isEmpty {
                EmptyDataView(message: t(.noForecastData))
            } else {
                ForecastChartView(history: history.map(\.value), forecast: forecast)
                    .frame(height: 120)

                if !forecast.isEmpty {
                    HStack {
                        VStack(spacing: 2) {
                            Text(t(.nowLabel)).font(.caption2).fontWeight(.bold).foregroundStyle(.gray)
                            Text(String(format: "%.0f", history.last?.value ?? 0))
                                .font(.caption).fontWeight(.bold).foregroundStyle(.white)
                        }
                        Spacer()
                        if forecast.count >= 4 {
                            VStack(spacing: 2) {
                                Text("+\(forecast.count / 2)D").font(.caption2).fontWeight(.bold).foregroundStyle(.gray)
                                Text(String(format: "%.0f", forecast[forecast.count / 2 - 1]))
                                    .font(.caption).fontWeight(.bold).foregroundStyle(.white)
                            }
                        }
                        Spacer()
                        VStack(spacing: 2) {
                            Text("+\(forecast.count)D").font(.caption2).fontWeight(.bold).foregroundStyle(.gray)
                            Text(String(format: "%.0f", forecast.last ?? 0))
                                .font(.caption).fontWeight(.bold).foregroundStyle(Color.fitnessPrimary)
                        }
                    }
                    .padding(.top, 8)
                }
            }
        }
        .padding()
        .background(Color.fitnessSurface.opacity(0.6))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }
}

// MARK: - Real Muscle Heatmap Card

struct RealMuscleHeatmapCard: View {
    let loads: [MuscleLoad]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(t(.muscleHeatmap))
                .font(.title3).fontWeight(.bold).foregroundStyle(.white)

            if loads.isEmpty {
                EmptyDataView(message: t(.noMuscleData))
            } else {
                HStack(alignment: .top, spacing: 16) {
                    VStack(alignment: .leading, spacing: 16) {
                        ForEach(loads) { load in
                            MuscleBar(
                                label: load.name,
                                percent: load.load,
                                color: colorForKey(load.colorKey)
                            )
                        }
                    }
                    .frame(width: 130)

                    Spacer()

                    ZStack {
                        Image(systemName: "figure.arms.open")
                            .resizable().aspectRatio(contentMode: .fit)
                            .foregroundStyle(Color.gray.opacity(0.3))
                            .frame(height: 200)

                        ForEach(loads) { load in
                            Circle()
                                .fill(colorForKey(load.colorKey).opacity(0.5 + load.load * 0.4))
                                .frame(width: 36, height: 36)
                                .blur(radius: 10)
                                .offset(heatmapOffset(for: load.name))
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.fitnessSurface.opacity(0.6))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private func colorForKey(_ key: String) -> Color {
        switch key {
        case "fitnessAccent":  return .fitnessAccent
        case "fitnessPrimary": return .fitnessPrimary
        case "orange":         return .orange
        case "blue":           return .blue
        case "purple":         return .purple
        case "yellow":         return .yellow
        default:               return .white
        }
    }

    private func heatmapOffset(for muscle: String) -> CGSize {
        switch muscle {
        case "Shoulders":  return CGSize(width: 0, height: -70)
        case "Chest":      return CGSize(width: 0, height: -45)
        case "Back":       return CGSize(width: 0, height: -20)
        case "Core":       return CGSize(width: 0, height: 5)
        case "Quadriceps": return CGSize(width: 0, height: 35)
        case "Hamstrings": return CGSize(width: 0, height: 55)
        default:           return .zero
        }
    }
}

// MARK: - MuscleBar

struct MuscleBar: View {
    let label: String
    let percent: CGFloat
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(label)
                .font(.subheadline).fontWeight(.bold).foregroundStyle(.white)
            ZStack(alignment: .leading) {
                RoundedRectangle(cornerRadius: 4)
                    .fill(Color.white.opacity(0.1))
                    .frame(height: 6)
                RoundedRectangle(cornerRadius: 4)
                    .fill(color)
                    .frame(width: max(4, 100 * percent), height: 6)
            }
        }
    }
}

// MARK: - Recovery Summary Card

struct RecoverySummaryCard: View {
    let score: Int

    private var trimAmount: CGFloat { CGFloat(score) / 100 }

    private var statusText: String {
        switch score {
        case 70...: return t(.readyToTrain)
        case 40..<70: return t(.moderateLoad)
        default: return t(.restToday)
        }
    }

    private var descriptionText: String {
        switch score {
        case 70...: return t(.readyToTrainDesc)
        case 40..<70: return t(.moderateLoadDesc)
        default: return t(.restTodayDesc)
        }
    }

    var body: some View {
        HStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.fitnessPrimary.opacity(0.2), lineWidth: 8)
                Circle()
                    .trim(from: 0, to: score > 0 ? trimAmount : 0)
                    .stroke(Color.fitnessPrimary, style: StrokeStyle(lineWidth: 8, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                    .animation(.easeInOut, value: score)

                Text(score > 0 ? "\(score)" : "--")
                    .font(.title2).fontWeight(.bold).foregroundStyle(.white)
            }
            .frame(width: 70, height: 70)

            VStack(alignment: .leading, spacing: 4) {
                Text(statusText)
                    .font(.headline).fontWeight(.bold).foregroundStyle(.white)
                Text(descriptionText)
                    .font(.caption).foregroundStyle(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding()
        .background(Color.fitnessPrimary.opacity(0.1))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.fitnessPrimary.opacity(0.3), lineWidth: 1))
    }
}

// MARK: - Canvas Charts

struct LineChartView: View {
    let data: [Double]
    let color: Color

    var body: some View {
        Canvas { ctx, size in
            guard data.count >= 2 else { return }
            let minVal = data.min()!
            let maxVal = data.max()!
            let range  = max(maxVal - minVal, 1)
            let stepX  = size.width / CGFloat(data.count - 1)
            let vPad   = CGFloat(6)

            func pt(_ i: Int) -> CGPoint {
                CGPoint(
                    x: CGFloat(i) * stepX,
                    y: size.height - vPad - CGFloat((data[i] - minVal) / range) * (size.height - vPad * 2)
                )
            }

            var fill = Path()
            fill.move(to: CGPoint(x: 0, y: size.height))
            fill.addLine(to: pt(0))
            for i in 1..<data.count { fill.addLine(to: pt(i)) }
            fill.addLine(to: CGPoint(x: size.width, y: size.height))
            fill.closeSubpath()
            ctx.fill(fill, with: .color(color.opacity(0.2)))

            var line = Path()
            line.move(to: pt(0))
            for i in 1..<data.count { line.addLine(to: pt(i)) }
            ctx.stroke(line, with: .color(color),
                       style: StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        }
    }
}

struct ForecastChartView: View {
    let history: [Double]
    let forecast: [Double]

    var body: some View {
        Canvas { ctx, size in
            let combined = history + forecast
            guard combined.count >= 2 else { return }

            let minVal = combined.min()!
            let maxVal = combined.max()!
            let range  = max(maxVal - minVal, 1)
            let total  = combined.count
            let stepX  = size.width / CGFloat(total - 1)
            let vPad   = CGFloat(6)

            func pt(_ i: Int) -> CGPoint {
                CGPoint(
                    x: CGFloat(i) * stepX,
                    y: size.height - vPad - CGFloat((combined[i] - minVal) / range) * (size.height - vPad * 2)
                )
            }

            let split = history.count - 1

            // Solid history line
            if history.count >= 2 {
                var hist = Path()
                hist.move(to: pt(0))
                for i in 1...split { hist.addLine(to: pt(i)) }
                ctx.stroke(hist, with: .color(Color.fitnessPrimary),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round))
            }

            // Dashed forecast line
            if !forecast.isEmpty {
                var fc = Path()
                fc.move(to: pt(split))
                for i in (split + 1)..<total { fc.addLine(to: pt(i)) }
                ctx.stroke(fc, with: .color(Color.fitnessPrimary.opacity(0.6)),
                           style: StrokeStyle(lineWidth: 2.5, lineCap: .round, dash: [5, 5]))
            }

            // TODAY dot
            let todayPt = pt(split)
            ctx.fill(Path(ellipseIn: CGRect(x: todayPt.x - 5, y: todayPt.y - 5, width: 10, height: 10)),
                     with: .color(Color.fitnessPrimary))
        }
    }
}

// MARK: - Empty Data Placeholder

struct EmptyDataView: View {
    let message: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: "chart.xyaxis.line")
                .font(.system(size: 28))
                .foregroundStyle(.gray.opacity(0.5))
            Text(message)
                .font(.caption)
                .foregroundStyle(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
    }
}

#Preview {
    AnalyticsView()
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self], inMemory: true)
}
