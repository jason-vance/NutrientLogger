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

    @ViewBuilder private func GenderField() -> some View {
        HStack {
            Text("Sex")
            Spacer()
            Menu {
                Button(Gender.male.rawValue) {
                    user?.gender = .male
                }
                Button(Gender.female.rawValue) {
                    user?.gender = .female
                }
            } label: {
                Text(user?.gender.rawValue ?? "Not Set")
                    .bold()
            }
        }
        .listRowDefaultModifiers()
    }

    @ViewBuilder private func HeightField() -> some View {
        HStack {
            Text("Height")
            Spacer()
            if preferredHeightUnit == .ftIn {
                Menu {
                    Picker("Feet", selection: Binding(
                        get: { heightFeet },
                        set: { setHeight(feet: $0, inches: heightInches) }
                    )) {
                        ForEach(3...7, id: \.self) { Text("\($0) ft").tag($0) }
                    }
                    Picker("Inches", selection: Binding(
                        get: { heightInches },
                        set: { setHeight(feet: heightFeet, inches: $0) }
                    )) {
                        ForEach(0...11, id: \.self) { Text("\($0) in").tag($0) }
                    }
                } label: {
                    Text(user?.heightCm.map { preferredHeightUnit.formattedHeight(cm: $0) } ?? "Not Set")
                        .bold()
                }
            } else {
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
        }
        .listRowDefaultModifiers()
    }
}

#Preview {
    NavigationStack {
        EditProfileView(user: .constant(.sample))
    }
}
