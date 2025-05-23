//
//  UserProfileView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/12/25.
//

import SwiftUI
import SwinjectAutoregistration

struct UserProfileView: View {
    
    @EnvironmentObject private var adProviderFactory: AdProviderFactory
    @State private var adProvider: AdProvider?
    @State private var ad: Ad?
    
    @Inject private var userService: UserService
    
    @State private var user: User?
    
    @State private var showFavoriteColorPicker: Bool = false
    
    private func fetchUser() {
        self.user = userService.currentUser
    }
    
    private func saveUser() {
        guard let user else { return }
        Task {
            do {
                try await userService.save(user: user)
            } catch {
                print("Failed to save user: \(error.localizedDescription)")
            }
        }
    }
    
    var body: some View {
        List {
            NativeAdListRow(ad: $ad, size: .medium)
            ProfileSettingsSection()
            //TODO: Add custom nutrient goals
            UserMealsSection()
            NutrientLibrarySection()
        }
        .listDefaultModifiers()
        .navigationBarTitle("User Profile")
        .onAppear { fetchUser() }
        .onChange(of: user) { saveUser() }
        .adContainer(factory: adProviderFactory, adProvider: $adProvider, ad: $ad)
        .sheet(isPresented: $showFavoriteColorPicker) {
            FavoriteColorPicker(.init(
                get: { user?.preferredColorName ?? .indigo },
                set: { user?.preferredColorName = $0 }
            ))
        }
    }
    
    @ViewBuilder private func ProfileSettingsSection() -> some View {
        Section(header: Text("Profile Settings")) {
            BirthdateField()
            GenderField()
            FavoriteColorField()
        }
    }
    
    @ViewBuilder private func BirthdateField() -> some View {
        HStack {
            Text("Birthdate")
            Spacer()
            Button {
                
            } label: {
                Text(user?.birthdate?.toDate()?.relativeDateString() ?? "Not Set")
                    .bold()
            }
            .overlay{
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
    
    @ViewBuilder private func FavoriteColorField() -> some View {
        HStack {
            Text("Favorite Color")
            Spacer()
            Button {
                showFavoriteColorPicker = true
            } label: {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(user?.preferredColor ?? Color.white)
                    .stroke(.black, style: .init(lineWidth: 1))
                    .frame(width: 100, height: 22)
            }
        }
        .listRowDefaultModifiers()
    }
    
    @ViewBuilder private func FavoriteColorPicker(_ preferredColorName: Binding<ColorName>) -> some View {
        VStack {
            Text("Pick your favorite color")
                .frame(height: 44)
                .bold()
            Spacer()
            HStack {
                ForEach(ColorPalettes.allColors.prefix(4).map { $0.0 }, id: \.self) { colorName in
                    ColorButton(colorName, preferredColorName: preferredColorName)
                }
            }
            HStack {
                ForEach(ColorPalettes.allColors.dropFirst(4).prefix(4).map { $0.0 }, id: \.self) { colorName in
                    ColorButton(colorName, preferredColorName: preferredColorName)
                }
            }
            HStack {
                ForEach(ColorPalettes.allColors.dropFirst(8).prefix(4).map { $0.0 }, id: \.self) { colorName in
                    ColorButton(colorName, preferredColorName: preferredColorName)
                }
            }
            Spacer()
            Button("OK") {
                showFavoriteColorPicker = false
            }
        }
        .presentationDetents([.medium])
    }
    
    @ViewBuilder private func ColorButton(
        _ colorName: ColorName,
        preferredColorName: Binding<ColorName>
    ) -> some View {
        Button {
            withAnimation(.snappy) {
                preferredColorName.wrappedValue = colorName
            }
        } label: {
            Circle()
                .fill(ColorPalettes.colorFrom(name: colorName))
                .stroke(.black, style: .init(lineWidth: 1))
                .frame(width: 56, height: 56)
                .padding(4)
                .background {
                    Circle()
                        .stroke(.black, style: .init(lineWidth: 2))
                        .opacity(preferredColorName.wrappedValue == colorName ? 1 : 0)
                }
        }
    }
    
    @ViewBuilder private func UserMealsSection() -> some View {
        Section {
            NavigationLink {
                UserMealsView()
            } label: {
                VStack {
                    HStack {
                        Text("My Recipes/Meals")
                        Spacer()
                    }
                    HStack {
                        Text("Group several food items together for easy logging")
                        Spacer()
                    }
                    .font(.caption)
                }
            }
            .listRowDefaultModifiers()
        }
    }
    
    @ViewBuilder private func NutrientLibrarySection() -> some View {
        Section {
            NavigationLink {
                NutrientLibraryView()
            } label: {
                VStack {
                    HStack {
                        Text("Browse Nutrients")
                        Spacer()
                    }
                    HStack {
                        Text("Learn about each nutrient and what kinds of foods contain them")
                        Spacer()
                    }
                    .font(.caption)
                }
            }
            .listRowDefaultModifiers()
        }
    }
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self){MockUserService(currentUser: .sample)}
    
    NavigationStack {
        UserProfileView()
    }
    .environmentObject(AdProviderFactory.forDev)
}
