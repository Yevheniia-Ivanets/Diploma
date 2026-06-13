import SwiftUI
import SwiftData

struct OnboardingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(HealthKitManager.self) private var healthKit

    @Binding var isOnboardingComplete: Bool

    @State private var currentPage = 0
    @State private var weight = ""
    @State private var height = ""
    @State private var age = ""

    var body: some View {
        ZStack {
            Color.fitnessDarkBg.ignoresSafeArea()

            TabView(selection: $currentPage) {
                WelcomePage().tag(0)
                ParametersPage(weight: $weight, height: $height, age: $age).tag(1)
                HealthKitPermissionPage().tag(2)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))

            VStack {
                Spacer()
                Button(action: handleNextTap) {
                    Text(currentPage < 2 ? t(.next) : t(.startTraining))
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(Color.fitnessPrimary)
                        .foregroundColor(Color.fitnessDarkBg)
                        .cornerRadius(16)
                }
                .padding(.horizontal, 30)
                .padding(.bottom, 50)
            }
        }
    }

    private func handleNextTap() {
        if currentPage < 2 {
            withAnimation { currentPage += 1 }
        } else {
            saveProfile()
            isOnboardingComplete = true
        }
    }

    private func saveProfile() {
        let profile = UserProfile(
            weight: Double(weight) ?? 70,
            height: Double(height) ?? 175,
            age: Int(age) ?? 25
        )
        modelContext.insert(profile)
    }
}

// MARK: - Pages

struct WelcomePage: View {
    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "figure.run.circle.fill")
                .resizable()
                .frame(width: 120, height: 120)
                .foregroundColor(.fitnessPrimary)

            VStack(spacing: 12) {
                Text("MySport")
                    .font(.system(size: 48, weight: .black, design: .rounded))
                    .foregroundColor(.white)
                Text(t(.onboardingSubtitle))
                    .font(.title3)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }
            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct ParametersPage: View {
    @Binding var weight: String
    @Binding var height: String
    @Binding var age: String

    var body: some View {
        VStack(alignment: .leading, spacing: 30) {
            Spacer()
            VStack(alignment: .leading, spacing: 8) {
                Text(t(.yourParams))
                    .font(.largeTitle).fontWeight(.black).foregroundColor(.white)
                Text(t(.forAccurate))
                    .foregroundColor(.gray)
            }

            VStack(spacing: 20) {
                OnboardingInputField(label: t(.weight), placeholder: t(.weightPlaceholder), value: $weight, unit: t(.weightUnit))
                OnboardingInputField(label: t(.height), placeholder: t(.heightPlaceholder), value: $height, unit: t(.heightUnit))
                OnboardingInputField(label: t(.age),    placeholder: t(.agePlaceholder),    value: $age,    unit: t(.ageUnit))
            }
            Spacer()
            Spacer()
        }
        .padding(.horizontal, 30)
        .onTapGesture { hideKeyboard() }
    }
}

struct HealthKitPermissionPage: View {
    @Environment(HealthKitManager.self) private var healthKit
    @State private var didRequest = false

    var body: some View {
        VStack(spacing: 30) {
            Spacer()
            Image(systemName: "heart.fill")
                .resizable()
                .frame(width: 80, height: 80)
                .foregroundColor(.red)

            VStack(spacing: 12) {
                Text(t(.healthAccess))
                    .font(.largeTitle).fontWeight(.black).foregroundColor(.white)
                Text(t(.healthDesc))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.gray)
            }

            if didRequest || !healthKit.isAvailable {
                Label(
                    healthKit.isAvailable ? t(.accessGranted) : t(.simulatorNote),
                    systemImage: "checkmark.circle.fill"
                )
                .foregroundColor(.fitnessPrimary)
                .font(.headline)
            } else {
                Button {
                    Task {
                        await healthKit.requestAuthorization()
                        didRequest = true
                    }
                } label: {
                    Label(t(.connectHealth), systemImage: "heart.fill")
                        .fontWeight(.bold)
                        .padding()
                        .background(Color.red.opacity(0.15))
                        .foregroundColor(.red)
                        .cornerRadius(12)
                        .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.red.opacity(0.4), lineWidth: 1))
                }
            }
            Spacer()
            Spacer()
        }
        .padding()
    }
}

struct OnboardingInputField: View {
    let label: String
    let placeholder: String
    @Binding var value: String
    let unit: String

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(label.uppercased())
                .font(.caption).fontWeight(.bold)
                .foregroundColor(.gray).tracking(1.2)

            HStack {
                TextField(placeholder, text: $value)
                    .keyboardType(.numberPad)
                    .font(.title2).fontWeight(.bold)
                    .foregroundColor(.white)
                Text(unit)
                    .font(.caption).fontWeight(.bold)
                    .foregroundColor(.fitnessPrimary)
            }
            .padding()
            .background(Color.fitnessSurface)
            .cornerRadius(12)
        }
    }
}

#Preview {
    OnboardingView(isOnboardingComplete: .constant(false))
        .environment(HealthKitManager())
        .modelContainer(for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self], inMemory: true)
}
