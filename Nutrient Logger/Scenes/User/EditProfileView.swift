//
//  EditProfileView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 6/30/26.
//

import SwiftUI

struct EditProfileView: View {

    @Binding var user: User?

    @AppStorage("preferredHeightUnit") private var preferredHeightUnitRaw: String = HeightUnit.ftIn.rawValue

    private var preferredHeightUnit: HeightUnit {
        HeightUnit(rawValue: preferredHeightUnitRaw) ?? .ftIn
    }

    private var heightFeet: Int {
        guard let cm = user?.heightCm else { return 5 }
        return Int((cm * 0.393701).rounded()) / 12
    }

    private var heightInches: Int {
        guard let cm = user?.heightCm else { return 7 }
        return Int((cm * 0.393701).rounded()) % 12
    }

    private func setHeight(feet: Int, inches: Int) {
        user?.heightCm = HeightUnit.ftIn.heightToCm(feet: feet, inches: inches)
    }

    var body: some View {
        List {
            Section(header: Text("Profile")) {
                BirthdateField()
                GenderField()
                HeightField()
            }
        }
        .listDefaultModifiers()
        .navigationTitle("Edit Profile")
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder private func BirthdateField() -> some View {
        HStack {
            Text("Birthdate")
            Spacer()
            Button {

            } label: {
                Text(user?.birthdate?.toDate()?.relativeDisplayString() ?? "Not Set")
                    .bold()
            }
            .overlay {
                DatePicker(
                    "",
                    selection: .init(
                        get: { user?.birthdate?.toDate() ?? .now },
                        set: { user?.birthdate = SimpleDate(date: $0)! }
                    ),
                    displayedComponents: [.date]
                )
                .blendMode(.destinationOver) //MARK: use this extension to keep the clickable functionality
            }
        }
        .listRowDefaultModifiers()
    }

    /// Both choices on screen, so it's one tap instead of a menu.
    @ViewBuilder private func GenderField() -> some View {
        let options: [Gender] = [.male, .female]
        VStack(alignment: .leading, spacing: 8) {
            Text("Sex")
            LogPillRow(
                items: options,
                labels: options.map { $0.rawValue.capitalized },
                isSelected: { user?.gender == $0 },
                onSelect: { user?.gender = $0 }
            )
        }
        .padding(.vertical, 4)
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func HeightField() -> some View {
        if preferredHeightUnit == .ftIn {
            // Feet and inches as pills instead of two pickers hidden inside a menu.
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text("Height")
                    Spacer()
                    Text(user?.heightCm.map { preferredHeightUnit.formattedHeight(cm: $0) } ?? "Not Set")
                        .bold()
                        .foregroundStyle(Color.accentColor)
                }
                LogFieldLabel("Feet")
                LogPillRow(
                    items: Array(4...7),
                    labels: (4...7).map { "\($0) ft" },
                    isSelected: { user?.heightCm != nil && $0 == heightFeet },
                    onSelect: { setHeight(feet: $0, inches: heightInches) }
                )
                LogFieldLabel("Inches")
                LogPillRow(
                    items: Array(0...11),
                    labels: (0...11).map { "\($0)" },
                    isSelected: { user?.heightCm != nil && $0 == heightInches },
                    onSelect: { setHeight(feet: heightFeet, inches: $0) }
                )
            }
            .padding(.vertical, 4)
            .listRowDefaultModifiers()
        } else {
            HeightInCentimetersField()
        }
    }

    @ViewBuilder private func HeightInCentimetersField() -> some View {
        HStack {
            Text("Height")
            Spacer()
                TextField(
                    "Not Set",
                    text: Binding(
                        get: {
                            if let cm = user?.heightCm {
                                return cm.formatted(maxDigits: 0)
                            }
                            return ""
                        },
                        set: { newValue in
                            if newValue.isEmpty {
                                user?.heightCm = nil
                            } else if let d = Double(newValue) {
                                user?.heightCm = d
                            }
                        }
                    )
                )
                .keyboardType(.numberPad)
                .multilineTextAlignment(.trailing)
                .bold()
                .foregroundStyle(Color.accentColor)
                .frame(maxWidth: 100)
            Text("cm")
                .fontWeight(.light)
                .foregroundStyle(.secondary)
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    NavigationStack {
        EditProfileView(user: .constant(.sample))
    }
}
