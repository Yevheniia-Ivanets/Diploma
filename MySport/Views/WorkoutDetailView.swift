import SwiftUI
import SwiftData

// MARK: - WorkoutDetailView

struct WorkoutDetailView: View {
    let plan: WorkoutPlan

    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var completedExercises: Set<UUID> = []
    // Stable @State so UUIDs don't change on every render
    @State private var exercises: [Exercise]

    init(plan: WorkoutPlan) {
        self.plan = plan
        _exercises = State(initialValue: WorkoutLibrary.exercises(
            for: plan.workoutType, intensity: plan.intensity
        ))
    }

    private var allCompleted: Bool {
        !exercises.isEmpty && completedExercises.count == exercises.count
    }

    private var isRestDay: Bool { exercises.isEmpty }

    private var intensityColor: Color {
        if plan.intensity.lowercased().contains("висок") { return .fitnessAccent }
        if plan.intensity.lowercased().contains("серед") { return .yellow }
        return .fitnessPrimary
    }

    var body: some View {
        ZStack(alignment: .bottom) {
            Color.fitnessDarkBg.ignoresSafeArea()

            ScrollView {
                VStack(spacing: 20) {
                    headerCard

                    if isRestDay {
                        restDayCard
                    } else {
                        progressSection

                        if allCompleted {
                            completionBanner
                                .transition(.scale.combined(with: .opacity))
                        }

                        VStack(spacing: 10) {
                            ForEach(exercises) { exercise in
                                ExerciseRowView(
                                    exercise: exercise,
                                    isCompleted: Binding(
                                        get: { completedExercises.contains(exercise.id) },
                                        set: { done in
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.65)) {
                                                if done { completedExercises.insert(exercise.id) }
                                                else    { completedExercises.remove(exercise.id) }
                                            }
                                        }
                                    )
                                )
                            }
                        }
                    }

                    Color.clear.frame(height: 96)
                }
                .padding()
                .animation(.easeInOut(duration: 0.25), value: allCompleted)
            }

            // Sticky bottom button
            bottomButton
        }
        .navigationTitle(plan.title)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbarBackground(Color.fitnessDarkBg, for: .navigationBar)
        .toolbarBackground(.visible, for: .navigationBar)
    }

    // MARK: - Subviews

    private var headerCard: some View {
        HStack {
            Label("\(plan.durationMinutes) \(t(.minutes))", systemImage: "clock")
                .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)

            Spacer()

            Label("\(exercises.count) \(t(.exercisesLabel))", systemImage: "list.bullet")
                .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)

            Spacer()

            Text(plan.intensity)
                .font(.caption).fontWeight(.bold)
                .padding(.horizontal, 12).padding(.vertical, 6)
                .background(intensityColor.opacity(0.2))
                .foregroundColor(intensityColor)
                .cornerRadius(8)
        }
        .padding()
        .background(Color.fitnessSurface.opacity(0.6))
        .cornerRadius(20)
        .overlay(RoundedRectangle(cornerRadius: 20).stroke(Color.white.opacity(0.1), lineWidth: 1))
    }

    private var progressSection: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("\(t(.completedOf)) \(completedExercises.count) / \(exercises.count) \(t(.exercisesLabel))")
                    .font(.subheadline).fontWeight(.semibold).foregroundColor(.white)
                Spacer()
                Text("\(Int(Double(completedExercises.count) / Double(max(exercises.count, 1)) * 100))%")
                    .font(.caption).fontWeight(.bold).foregroundColor(Color.fitnessPrimary)
            }
            ProgressView(value: Double(completedExercises.count), total: Double(max(exercises.count, 1)))
                .tint(.fitnessPrimary)
                .scaleEffect(x: 1, y: 1.8, anchor: .center)
                .animation(.easeInOut, value: completedExercises.count)
        }
        .padding()
        .background(Color.fitnessSurface.opacity(0.4))
        .cornerRadius(16)
    }

    private var completionBanner: some View {
        HStack(spacing: 14) {
            Text("🏆")
                .font(.title)
            VStack(alignment: .leading, spacing: 2) {
                Text(t(.workoutComplete))
                    .font(.headline).fontWeight(.bold).foregroundColor(.white)
                Text(t(.pressToSave))
                    .font(.caption).foregroundColor(.gray)
            }
            Spacer()
        }
        .padding()
        .background(Color.fitnessPrimary.opacity(0.15))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.fitnessPrimary.opacity(0.4), lineWidth: 1))
    }

    private var restDayCard: some View {
        VStack(spacing: 20) {
            Text("🌙")
                .font(.system(size: 64))
            Text(t(.restDay))
                .font(.title2).fontWeight(.bold).foregroundColor(.white)
            Text(t(.restDaySub))
                .font(.subheadline).foregroundColor(.gray)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(40)
        .background(Color.fitnessSurface.opacity(0.4))
        .cornerRadius(20)
    }

    private var bottomButton: some View {
        let enabled = allCompleted || isRestDay
        return VStack(spacing: 0) {
            Button(action: finishWorkout) {
                Text(t(.finishWorkout))
                    .fontWeight(.bold)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(enabled ? Color.fitnessPrimary : Color.white.opacity(0.12))
                    .foregroundColor(enabled ? Color.fitnessDarkBg : Color.white.opacity(0.4))
                    .cornerRadius(16)
            }
            .disabled(!enabled)
            .animation(.easeInOut(duration: 0.2), value: enabled)
        }
        .padding(.horizontal, 20)
        .padding(.bottom, 34)
        .background(
            LinearGradient(
                colors: [Color.fitnessDarkBg.opacity(0), Color.fitnessDarkBg, Color.fitnessDarkBg],
                startPoint: .top,
                endPoint: .bottom
            )
            .ignoresSafeArea()
        )
    }

    // MARK: - Actions

    private func finishWorkout() {
        plan.isCompleted = true
        dismiss()
    }
}

// MARK: - ExerciseRowView

struct ExerciseRowView: View {
    let exercise: Exercise
    @Binding var isCompleted: Bool

    private static let palette: [Color] = [.blue, .purple, .orange, .green, .red, .cyan]

    private var iconColor: Color {
        Self.palette[abs(exercise.name.hashValue) % Self.palette.count]
    }

    var body: some View {
        HStack(spacing: 14) {
            // Icon circle — becomes green checkmark when done
            ZStack {
                Circle()
                    .fill(isCompleted ? Color.green : iconColor.opacity(0.18))
                    .frame(width: 44, height: 44)
                Image(systemName: isCompleted ? "checkmark" : exercise.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(isCompleted ? .white : iconColor)
            }

            // Name + sets/reps/rest
            VStack(alignment: .leading, spacing: 4) {
                Text(exercise.name)
                    .font(.subheadline).fontWeight(.bold)
                    .foregroundColor(isCompleted ? .secondary : .white)
                    .strikethrough(isCompleted, color: .secondary)
                Text("\(exercise.sets) \(t(.setsLabel)) × \(exercise.reps) · \(t(.restLabel)) \(exercise.rest)")
                    .font(.caption).foregroundColor(.secondary)
            }

            Spacer()

            // Checkmark toggle
            Button {
                withAnimation(.spring(response: 0.3)) {
                    isCompleted.toggle()
                }
            } label: {
                Image(systemName: isCompleted ? "checkmark.circle.fill" : "circle")
                    .font(.title2)
                    .foregroundColor(isCompleted ? .green : .secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16).padding(.vertical, 12)
        .background(Color(red: 26/255, green: 46/255, blue: 40/255).opacity(isCompleted ? 0.2 : 0.55))
        .cornerRadius(16)
        .overlay(RoundedRectangle(cornerRadius: 16).fill(Color.green.opacity(isCompleted ? 0.1 : 0)))
        .animation(.spring(response: 0.3), value: isCompleted)
        .onTapGesture {
            withAnimation(.spring(response: 0.3)) {
                isCompleted.toggle()
            }
        }
    }
}

#Preview {
    NavigationView {
        WorkoutDetailView(plan: WorkoutPlan(
            title: "Силове тренування",
            workoutType: "Силове",
            intensity: "Середня",
            durationMinutes: 50
        ))
        .modelContainer(for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self], inMemory: true)
    }
}
