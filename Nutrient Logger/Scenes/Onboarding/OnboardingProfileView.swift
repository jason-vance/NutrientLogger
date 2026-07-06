//
//  OnboardingProfileView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 7/6/26.
//

import SwiftUI

struct OnboardingProfileView: View {

    let onComplete: (User, Double?) -> Void

    @AppStorage("preferredWeightUnit") private var preferredWeightUnitRaw: String = BodyWeightUnit.lbs.rawValue
    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue

    @State private var gender: Gender = .male
    @State private var birthYear: Int = 1990
    @State private var heightFeet: Int = 5
    @State private var heightInches: Int = 7
    @State private var heightCm: Double = 170
    @State private var weightText: String = ""

    private var preferredWeightUnit: BodyWeightUnit {
        BodyWeightUnit(rawValue: preferredWeightUnitRaw) ?? .lbs
    }

    private var preferredHeightUnit: HeightUnit {
        HeightUnit(rawValue: preferredHeightUnitRaw) ?? .ftIn
    }

    private var weightKg: Double? {
        guard let value = Double(weightText), value > 0 else { return nil }
        return preferredWeightUnit.toKg(value)
    }

    private var builtUser: User {
        let birthdate = SimpleDate(year: birthYear, month: 1, day: 1)
        let height: Double = preferredHeightUnit == .ftIn
            ? HeightUnit.ftIn.heightToCm(feet: heightFeet, inches: heightInches)
            : heightCm
        return User(gender: gender, birthdate: birthdate, heightCm: height)
    }

    private let minYear: Int = Calendar.current.component(.year, from: Date.now) - 100
    private let maxYear: Int = Calendar.current.component(.year, from: Date.now) - 10

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 32) {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tell us about you")
                            .font(.largeTitle.bold())
                            .foregroundStyle(.white)
                        Text("Used to calculate your personal nutrient targets")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 16)

                    FieldSection(label: "Sex") {
                        HStack(spacing: 12) {
                            SexButton(label: "Male", isSelected: gender == .male) { gender = .male }
                            SexButton(label: "Female", isSelected: gender == .female) { gender = .female }
                        }
                    }

                    FieldSection(label: "Birth Year") {
                        Picker("Birth Year", selection: $birthYear) {
                            ForEach(minYear...maxYear, id: \.self) { year in
                                Text(String(year)).tag(year)
                            }
                        }
                        .pickerStyle(.wheel)
                        .frame(height: 120)
                        .clipped()
                        .colorScheme(.dark)
                    }

                    FieldSection(label: "Height") {
                        if preferredHeightUnit == .ftIn {
                            HStack(spacing: 0) {
                                Picker("Feet", selection: $heightFeet) {
                                    ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity, maxHeight: 120)
                                .clipped()
                                .colorScheme(.dark)
                                Picker("Inches", selection: $heightInches) {
                                    ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                                }
                                .pickerStyle(.wheel)
                                .frame(maxWidth: .infinity, maxHeight: 120)
                                .clipped()
                                .colorScheme(.dark)
                            }
                        } else {
                            HStack {
                                TextField("170", text: Binding(
                                    get: { heightCm == 0 ? "" : "\(Int(heightCm))" },
                                    set: { heightCm = Double($0) ?? heightCm }
                                ))
                                .keyboardType(.numberPad)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                Text("cm")
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }

                    FieldSection(label: "Weight (\(preferredWeightUnit.label)) — Optional") {
                        HStack {
                            TextField("e.g. 165", text: $weightText)
                                .keyboardType(.decimalPad)
                                .font(.title2.bold())
                                .foregroundStyle(.white)
                                .tint(.white)
                            if !weightText.isEmpty {
                                Text(preferredWeightUnit.label)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }

            Button(action: { onComplete(builtUser, weightKg) }) {
                Text("Get Started")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.accentColor)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 48)
        }
    }

    @ViewBuilder private func FieldSection<Content: View>(
        label: String,
        @ViewBuilder content: () -> Content
    ) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(label.uppercased())
                .font(.caption.bold())
                .foregroundStyle(.white.opacity(0.5))
                .tracking(1)
            content()
        }
    }

    @ViewBuilder private func SexButton(
        label: String,
        isSelected: Bool,
        action: @escaping () -> Void
    ) -> some View {
        Button(action: action) {
            Text(label)
                .font(.headline)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 14)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(isSelected ? Color.accentColor : Color.white.opacity(0.08))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(isSelected ? Color.accentColor : Color.clear, lineWidth: 1.5)
                        )
                )
                .foregroundStyle(.white)
        }
        .buttonStyle(.plain)
        .animation(.easeInOut(duration: 0.15), value: isSelected)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        OnboardingProfileView(onComplete: { _, _ in })
    }
}
