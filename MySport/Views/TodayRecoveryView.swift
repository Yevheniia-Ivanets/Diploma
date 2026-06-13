import SwiftUI
import SwiftData

struct TodayRecoveryView: View {
    @Binding var selectedTab: Int

    @Environment(HealthKitManager.self) private var healthKit
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = TodayViewModel()

    var recoveryColor: Color {
        switch viewModel.recoveryScore {
        case 0..<40: return .red
        case 40..<70: return .yellow
        default:     return .green
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                Color.fitnessDarkBg.ignoresSafeArea()

                ScrollView {
                    VStack(spacing: 30) {
                        HeaderView(onProfileTap: { selectedTab = 3 })
                        RecoveryRingView(score: viewModel.recoveryScore, color: recoveryColor)
                        CoachRecommendationView(
                            color: recoveryColor,
                            title: viewModel.recommendation.title,
                            workout: viewModel.recommendation.subtitle,
                            onStart: {
                                saveRecommendedPlan()
                                selectedTab = 1
                            }
                        )
                        Spacer()
                    }
                    .padding()
                }
            }
            .navigationBarHidden(true)
        }
        .task {
            await viewModel.refresh(using: healthKit)
        }
    }

    private func saveRecommendedPlan() {
        let rec = viewModel.recommendation
        let plan = WorkoutPlan(
            title: rec.subtitle,
            workoutType: rec.workoutType,
            intensity: rec.intensity,
            durationMinutes: rec.durationMinutes,
            recoveryScoreAtCreation: viewModel.recoveryScore
        )
        modelContext.insert(plan)
    }
}

// MARK: - Subviews

struct HeaderView: View {
    var onProfileTap: () -> Void

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(t(.greeting))
                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                Text(Date.now, format: .dateTime.day().month().weekday())
                    .font(.subheadline).foregroundColor(.gray)
            }
            Spacer()
            Button(action: onProfileTap) {
                Image(systemName: "person.crop.circle.fill")
                    .resizable().frame(width: 40, height: 40).foregroundColor(.gray)
            }
        }
        .padding(.top, 10)
    }
}

struct RecoveryRingView: View {
    var score: Int
    var color: Color

    var body: some View {
        VStack(spacing: 20) {
            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 25)
                    .frame(width: 250, height: 250)

                Circle()
                    .trim(from: 0, to: CGFloat(score) / 100)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(colors: [color.opacity(0.6), color]),
                            center: .center,
                            startAngle: .degrees(0),
                            endAngle: .degrees(360)
                        ),
                        style: StrokeStyle(lineWidth: 25, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .frame(width: 250, height: 250)
                    .animation(.easeOut(duration: 1.5), value: score)

                VStack {
                    Text("\(score)%")
                        .font(.system(size: 60, weight: .bold, design: .rounded))
                        .foregroundColor(.white)
                    Text(t(.recoveryScore))
                        .font(.headline).foregroundColor(.gray)
                }
            }

            Text(t(.basedOnHRV))
                .font(.footnote).multilineTextAlignment(.center)
                .foregroundColor(.gray.opacity(0.8))
        }
    }
}

struct CoachRecommendationView: View {
    var color: Color
    var title: String
    var workout: String
    var onStart: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            HStack {
                Image(systemName: "brain.head.profile")
                    .font(.title2).foregroundColor(color)
                Text(t(.aiCoach))
                    .font(.headline).foregroundColor(.white)
                Spacer()
            }

            Divider().background(Color.gray)

            VStack(alignment: .leading, spacing: 5) {
                Text(title)
                    .font(.subheadline).foregroundColor(.gray)
                Text(workout)
                    .font(.title3).fontWeight(.bold).foregroundColor(.white)
            }

            Button(action: onStart) {
                HStack {
                    Text(t(.startWorkout)).fontWeight(.semibold)
                    Image(systemName: "play.fill")
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(color)
                .foregroundColor(.black)
                .cornerRadius(12)
            }
            .padding(.top, 10)
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.15))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(color.opacity(0.5), lineWidth: 1))
    }
}

#Preview {
    TodayRecoveryView(selectedTab: .constant(0))
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self], inMemory: true)
}
