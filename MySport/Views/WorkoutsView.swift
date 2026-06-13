import SwiftUI
import SwiftData
import UIKit

struct WorkoutsView: View {
    @Query(sort: \WorkoutPlan.date, order: .reverse) private var allPlans: [WorkoutPlan]
    @Environment(\.modelContext) private var modelContext

    @State private var viewModel = WorkoutsViewModel()
    @State private var showCamera = false

    private var displayedPlans: [WorkoutPlan] {
        viewModel.showHistory ? allPlans : viewModel.todaysPlans
    }

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 25) {

                    // Adaptive Plans
                    VStack(alignment: .leading, spacing: 15) {
                        // Section header row
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(t(.adaptivePlans))
                                    .font(.title2).fontWeight(.bold).foregroundColor(.white)
                                if viewModel.showHistory {
                                    Text(t(.allWorkoutHistory))
                                        .font(.caption).foregroundColor(.gray)
                                } else {
                                    Text("\(t(.todayDate)), \(Date().formatted(.dateTime.day().month(.wide)))")
                                        .font(.caption).foregroundColor(.secondary)
                                }
                            }
                            Spacer()
                            Button {
                                withAnimation(.easeInOut(duration: 0.2)) {
                                    viewModel.showHistory.toggle()
                                }
                            } label: {
                                Text(viewModel.showHistory ? t(.todayDate) : t(.history))
                                    .font(.caption).fontWeight(.semibold)
                                    .padding(.horizontal, 12).padding(.vertical, 6)
                                    .background(Color.white.opacity(0.1))
                                    .foregroundColor(.white)
                                    .cornerRadius(8)
                            }
                        }

                        if displayedPlans.isEmpty {
                            EmptyPlansView()
                        } else {
                            ForEach(displayedPlans) { plan in
                                NavigationLink {
                                    WorkoutDetailView(plan: plan)
                                } label: {
                                    WorkoutCard(plan: plan)
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    Divider().background(Color.gray)

                    // AI Tools
                    VStack(alignment: .leading, spacing: 15) {
                        Text(t(.aiTools))
                            .font(.title2).fontWeight(.bold).foregroundColor(.white)

                        Button(action: { showCamera = true }) {
                            ZStack {
                                RoundedRectangle(cornerRadius: 16)
                                    .fill(LinearGradient(
                                        colors: [.blue, .purple],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    ))
                                    .frame(height: 120)

                                HStack {
                                    VStack(alignment: .leading) {
                                        Text(t(.formAnalyzer))
                                            .font(.title3).fontWeight(.bold).foregroundColor(.white)
                                        Text(t(.formAnalyzerSub))
                                            .font(.subheadline).foregroundColor(.white.opacity(0.8))
                                    }
                                    Spacer()
                                    Image(systemName: "camera.viewfinder")
                                        .font(.system(size: 40)).foregroundColor(.white)
                                }
                                .padding(20)
                            }
                        }
                    }
                }
                .padding()
            }
            .background(Color.fitnessDarkBg.ignoresSafeArea())
            .navigationTitle("Тренування")
            .sheet(isPresented: $showCamera) {
                FormAnalyzerView()
            }
        }
        .onAppear {
            viewModel.loadTodaysPlans(from: allPlans, context: modelContext)
        }
        .onChange(of: allPlans) {
            viewModel.loadTodaysPlans(from: allPlans, context: modelContext)
        }
        .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
            viewModel.loadTodaysPlans(from: allPlans, context: modelContext)
        }
    }


}

// MARK: - Components

struct WorkoutCard: View {
    let plan: WorkoutPlan

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 8) {
                Text(plan.workoutType.uppercased())
                    .font(.caption).fontWeight(.bold).foregroundColor(.blue)

                Text(plan.title)
                    .font(.headline).foregroundColor(.white)

                HStack {
                    Label("\(plan.durationMinutes) хв", systemImage: "clock")
                    Spacer()
                    Label(plan.intensity, systemImage: "waveform.path.ecg")
                }
                .font(.caption).foregroundColor(.gray)
            }
            Spacer()
            Image(systemName: plan.isCompleted ? "checkmark.circle.fill" : "chevron.right")
                .foregroundColor(plan.isCompleted ? .fitnessPrimary : .gray)
        }
        .padding()
        .background(Color(UIColor.systemGray6).opacity(0.2))
        .cornerRadius(12)
    }
}

struct EmptyPlansView: View {
    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: "calendar.badge.plus")
                .font(.system(size: 40)).foregroundColor(.gray)
            Text(t(.aiPlansNote))
                .font(.caption).foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(30)
    }
}

#Preview {
    WorkoutsView()
        .modelContainer(for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self], inMemory: true)
}
