//
//  SettingsView.swift
//  MySport
//
//  Created by Evgeniya Ivanets on 01.02.2026.
//


import SwiftUI
import SwiftData
import UIKit

struct SettingsView: View {
    @AppStorage("appLanguage") private var appLanguage: String = "uk"
    @Query private var profiles: [UserProfile]
    @Environment(\.modelContext) private var modelContext

    @AppStorage("readHealthData") private var readHealthData = true
    @AppStorage("writeHealthData") private var writeHealthData = true
    @AppStorage("userAge") private var age = "28"

    @State private var editableName: String = ""
    @State private var unitsVM = UnitsViewModel()

    // Display strings — refreshed whenever the unit system or raw values change
    @State private var weightInput: String = ""
    @State private var heightInput: String = ""   // cm (metric)
    @State private var feetInput: String = ""     // ft (imperial)
    @State private var inchesInput: String = ""   // in (imperial)

    var displayName: String {
        if !editableName.isEmpty { return editableName }
        if let user = profiles.first, !user.name.isEmpty { return user.name }
        let cleaned = UIDevice.current.name
            .replacingOccurrences(of: "'s iPhone", with: "")
            .replacingOccurrences(of: "\u{2019}s iPhone", with: "") // curly apostrophe
            .replacingOccurrences(of: "'s iPad", with: "")
            .replacingOccurrences(of: "\u{2019}s iPad", with: "")
            .replacingOccurrences(of: "iPhone", with: "")
            .replacingOccurrences(of: "iPad", with: "")
            .trimmingCharacters(in: .whitespaces)
        if cleaned.count > 1 { return cleaned }
        return "Користувач"
    }

    var initials: String {
        let parts = displayName.split(separator: " ")
        if parts.count >= 2 {
            return String(parts[0].prefix(1)) + String(parts[1].prefix(1))
        }
        return String(displayName.prefix(2)).uppercased()
    }

    func saveUser() {
        if let profile = profiles.first {
            profile.name = editableName
        } else {
            let profile = UserProfile(weight: 70, height: 175, age: 25)
            profile.name = editableName
            modelContext.insert(profile)
        }
    }

    private func refreshDisplayValues() {
        if unitsVM.useMetric {
            weightInput = String(format: "%.1f", unitsVM.weightKg)
            heightInput = String(Int(unitsVM.heightCm.rounded()))
        } else {
            weightInput = String(format: "%.1f", unitsVM.weightLbs)
            feetInput   = String(unitsVM.heightFeet)
            inchesInput = String(unitsVM.heightInches)
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                // Загальний фон
                Color.fitnessDarkBg.edgesIgnoringSafeArea(.all)
                
                ScrollView {
                    VStack(spacing: 0) {
                        
                        // 1. Верхній Header (Кастомний)
                        CustomHeader(onSave: saveUser)
                            .padding(.bottom, 20)
                        
                        // 2. Профіль користувача
                        ProfileHeaderSection(
                            initials: initials,
                            editableName: $editableName,
                            onSave: saveUser
                        )
                        .padding(.bottom, 30)
                        
                        // 3. Секція Health & Data
                        SectionTitle(text: t(.healthData))
                        VStack(spacing: 1) {
                            HealthToggleRow(
                                icon: "heart.fill",
                                title: t(.readHealthData),
                                subtitle: t(.readHealthSub),
                                isOn: $readHealthData
                            )
                            HealthToggleRow(
                                icon: "square.and.arrow.up.fill",
                                title: t(.writeHealthData),
                                subtitle: t(.writeHealthSub),
                                isOn: $writeHealthData
                            )
                        }
                        .padding(.bottom, 30)

                        // 4. Фізичні параметри
                        SectionTitle(text: t(.physicalParams))
                        if unitsVM.useMetric {
                            HStack(spacing: 15) {
                                ParameterInput(label: t(.weight), value: $weightInput, unit: "KG")
                                    .onChange(of: weightInput) {
                                        if let v = Double(weightInput) { unitsVM.weightKg = v }
                                    }
                                ParameterInput(label: t(.height), value: $heightInput, unit: "CM")
                                    .onChange(of: heightInput) {
                                        if let v = Double(heightInput) { unitsVM.heightCm = v }
                                    }
                                ParameterInput(label: t(.age), value: $age, unit: "YRS")
                            }
                            .padding(.horizontal)
                        } else {
                            HStack(spacing: 15) {
                                ParameterInput(label: t(.weight), value: $weightInput, unit: "LBS")
                                    .onChange(of: weightInput) {
                                        if let v = Double(weightInput) { unitsVM.setFromImperialWeight(v) }
                                    }
                                ParameterInput(label: t(.feet), value: $feetInput, unit: "FT")
                                    .onChange(of: feetInput) {
                                        let ft = Int(feetInput) ?? unitsVM.heightFeet
                                        let ins = Int(inchesInput) ?? unitsVM.heightInches
                                        unitsVM.setFromImperialHeight(feet: ft, inches: ins)
                                    }
                                ParameterInput(label: t(.inches), value: $inchesInput, unit: "IN")
                                    .onChange(of: inchesInput) {
                                        let ft = Int(feetInput) ?? unitsVM.heightFeet
                                        let ins = Int(inchesInput) ?? unitsVM.heightInches
                                        unitsVM.setFromImperialHeight(feet: ft, inches: ins)
                                    }
                            }
                            .padding(.horizontal)
                            HStack(spacing: 15) {
                                ParameterInput(label: t(.age), value: $age, unit: "YRS")
                                Spacer()
                                Spacer()
                            }
                            .padding(.horizontal)
                        }
                        Color.clear.frame(height: 30)

                        // 5. Preferences
                        SectionTitle(text: t(.preferences))
                        VStack(spacing: 1) {
                            // Units picker
                            HStack {
                                HStack(spacing: 12) {
                                    Image(systemName: "ruler.fill")
                                        .foregroundColor(.gray)
                                    Text(t(.units))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Picker(t(.units), selection: $unitsVM.useMetric) {
                                    Text(t(.metric)).tag(true)
                                    Text(t(.imperial)).tag(false)
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 150)
                                .onChange(of: unitsVM.useMetric) {
                                    withAnimation(.spring(response: 0.3)) {
                                        refreshDisplayValues()
                                    }
                                }
                            }
                            .padding()

                            // Language picker
                            HStack {
                                HStack(spacing: 12) {
                                    Image(systemName: "globe")
                                        .foregroundColor(.gray)
                                    Text(t(.language))
                                        .fontWeight(.medium)
                                        .foregroundColor(.white)
                                }
                                Spacer()
                                Picker(t(.language), selection: Binding(
                                    get: { AppLanguage(rawValue: appLanguage) ?? .ukrainian },
                                    set: { appLanguage = $0.rawValue }
                                )) {
                                    ForEach(AppLanguage.allCases, id: \.self) { lang in
                                        Text(lang.displayName).tag(lang)
                                    }
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .frame(width: 200)
                            }
                            .padding()

                            SettingsLinkRow(icon: "bell.fill", title: t(.aiAlerts))
                            SettingsLinkRow(icon: "lock.shield.fill", title: t(.privacySecurity))
                        }
                        .padding(.bottom, 30)
                        
                        // 6. Footer (Privacy Disclaimer)
                        PrivacyFooter()
                            .padding(.bottom, 50)
                    }
                }
            }
            .navigationBarHidden(true)
            .onAppear {
                editableName = profiles.first?.name.isEmpty == false
                    ? profiles.first!.name
                    : displayName
                refreshDisplayValues()
            }
            .onTapGesture { hideKeyboard() }
        }
    }
}

// MARK: - Subviews & Components

struct CustomHeader: View {
    let onSave: () -> Void

    var body: some View {
        HStack {
            Color.clear.frame(width: 28, height: 28) // balance spacer

            Spacer()

            Text(t(.settingsTitle))
                .font(.headline)
                .fontWeight(.bold)
                .foregroundColor(.white)

            Spacer()

            Button(action: onSave) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 28))
                    .foregroundColor(.fitnessPrimary)
            }
        }
        .padding()
        .background(Color.fitnessDarkBg.opacity(0.95))
    }
}

struct ProfileHeaderSection: View {
    let initials: String
    @Binding var editableName: String
    let onSave: () -> Void

    var body: some View {
        VStack(spacing: 15) {
            ZStack(alignment: .bottomTrailing) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(
                            colors: [Color.fitnessPrimary.opacity(0.7), Color.fitnessPrimary],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ))
                        .frame(width: 100, height: 100)
                        .overlay(Circle().stroke(Color.fitnessPrimary.opacity(0.3), lineWidth: 4))
                    Text(initials)
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .foregroundColor(Color.fitnessDarkBg)
                }

                Image(systemName: "pencil")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundColor(.fitnessDarkBg)
                    .padding(8)
                    .background(Color.fitnessPrimary)
                    .clipShape(Circle())
                    .overlay(Circle().stroke(Color.fitnessDarkBg, lineWidth: 3))
            }

            TextField(t(.yourName), text: $editableName)
                .font(.title2)
                .fontWeight(.semibold)
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 16).padding(.vertical, 10)
                .background(Color.fitnessSurface)
                .cornerRadius(12)
                .padding(.horizontal, 40)
                .onSubmit { onSave() }
        }
    }
}

struct SectionTitle: View {
    let text: String
    var body: some View {
        HStack {
            Text(text.uppercased())
                .font(.caption)
                .fontWeight(.bold)
                .tracking(1.5) // letter spacing
                .foregroundColor(.gray.opacity(0.8))
            Spacer()
        }
        .padding(.horizontal)
        .padding(.top, 10)
    }
}

struct HealthToggleRow: View {
    let icon: String
    let title: String
    let subtitle: String
    @Binding var isOn: Bool
    
    var body: some View {
        HStack(spacing: 15) {
            // Іконка
            ZStack {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.fitnessPrimary.opacity(0.1))
                    .frame(width: 48, height: 48)
                Image(systemName: icon)
                    .foregroundColor(.fitnessPrimary)
                    .font(.system(size: 20))
            }
            
            // Текст
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.gray)
                    .lineLimit(1)
            }
            
            Spacer()
            
            // Toggle
            Toggle("", isOn: $isOn)
                .toggleStyle(SwitchToggleStyle(tint: .fitnessPrimary))
                .labelsHidden()
        }
        .padding()
    }
}

struct ParameterInput: View {
    let label: String
    @Binding var value: String
    let unit: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundColor(.gray)
            
            ZStack(alignment: .trailing) {
                TextField("", text: $value)
                    .keyboardType(.numberPad)
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.fitnessSurface)
                    .cornerRadius(12)
                
                Text(unit)
                    .font(.caption)
                    .fontWeight(.bold)
                    .foregroundColor(.fitnessPrimary)
                    .padding(.trailing, 10)
            }
        }
    }
}

struct SettingsLinkRow: View {
    let icon: String
    let title: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .foregroundColor(.gray)
            Text(title)
                .fontWeight(.medium)
                .foregroundColor(.white)
            Spacer()
            Image(systemName: "chevron.right")
                .foregroundColor(.gray.opacity(0.5))
        }
        .padding()
    }
}

struct PrivacyFooter: View {
    var body: some View {
        VStack(spacing: 20) {
            // Інфо-бокс
            HStack(alignment: .top, spacing: 10) {
                Image(systemName: "info.circle")
                    .foregroundColor(.fitnessPrimary)
                Text(t(.privacyNote))
                    .font(.caption)
                    .foregroundColor(.gray)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .background(Color.fitnessPrimary.opacity(0.05))
            .cornerRadius(12)
            .overlay(RoundedRectangle(cornerRadius: 12).stroke(Color.fitnessPrimary.opacity(0.1), lineWidth: 1))
            
            // Кнопка виходу
            Button(action: {
                print("Sign Out")
            }) {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                    Text(t(.signOut).uppercased())
                }
                .fontWeight(.bold)
                .foregroundColor(.red.opacity(0.8))
            }
            
            Text("Version 2.4.1 (Build 890)")
                .font(.caption2)
                .foregroundColor(.gray.opacity(0.3))
        }
        .padding(.horizontal)
    }
}

// Допоміжна функція для ховання клавіатури
extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}

#Preview {
    SettingsView()
        .modelContainer(for: [UserProfile.self, HealthMetric.self, WorkoutPlan.self], inMemory: true)
}