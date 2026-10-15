//
//  MainTabView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//


import SwiftUI

@MainActor
struct MainTabView: View {

    @ObservedObject var loginViewModel:
        LoginViewModel

    private let eventListViewModel:
        EventListViewModel?

    private let profileViewModel:
        ProfileViewModel?

    // MARK: - Init

    init(
        loginViewModel: LoginViewModel,
        eventListViewModel: EventListViewModel? = nil,
        profileViewModel: ProfileViewModel? = nil
    ) {

        self.loginViewModel =
            loginViewModel

        self.eventListViewModel =
            eventListViewModel

        self.profileViewModel =
            profileViewModel
    }

    // MARK: - Body

    var body: some View {

        TabView {

            EventListView(
                viewModel:
                    eventListViewModel
            )
            .tabItem {

                Label(
                    "Événements",
                    systemImage:
                        "calendar"
                )
            }

            ProfileView(
                loginViewModel:
                    loginViewModel,
                viewModel:
                    profileViewModel
            )
            .tabItem {

                Label(
                    "Profil",
                    systemImage:
                        "person"
                )
            }
        }
        .tint(.red)
        .toolbarBackground(
            Color(
                red: 0.08,
                green: 0.07,
                blue: 0.09
            ),
            for:
                .tabBar
        )
        .toolbarBackground(
            .visible,
            for:
                .tabBar
        )
    }
}

// MARK: - Preview

#Preview {

    MainTabView(
        loginViewModel:
            LoginViewModel()
    )
}
