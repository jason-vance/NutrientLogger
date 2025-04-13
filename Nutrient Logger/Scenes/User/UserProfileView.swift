//
//  UserProfileView.swift
//  Nutrient Logger
//
//  Created by Jason Vance on 4/12/25.
//

import SwiftUI
import SwinjectAutoregistration

struct UserProfileView: View {
    
    private let userService = swinjectContainer~>UserService.self
    
    @State private var user: User?
    
    private func fetchUser() {
        self.user = userService.currentUser
    }
    
    var body: some View {
        List {
            ProfileSettingsSection()
        }
        .listDefaultModifiers()
        .navigationBarTitle("User Profile")
        .onAppear { fetchUser() }
    }
    
    @ViewBuilder private func ProfileSettingsSection() -> some View {
        Section(header: Text("Profile Settings")) {
            BirthdateField()
            GenderField()
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
            Text("Gender")
            Spacer()
            SwiftUI.Menu {
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
    
}

#Preview {
    let _ = swinjectContainer.autoregister(UserService.self){MockUserService(currentUser: .sample)}
    
    NavigationStack {
        UserProfileView()
    }
}
