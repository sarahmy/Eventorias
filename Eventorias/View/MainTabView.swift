//
//  MainTabView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import SwiftUI

struct MainTabView: View {

    @ObservedObject var loginViewModel: LoginViewModel

    var body: some View {

        TabView {

            EventListView()
                .tabItem {
                    Label(
                        "Events",
                        systemImage: "calendar"
                    )
                }

            ProfileView(
                loginViewModel: loginViewModel
            )
            .tabItem {
                Label(
                    "Profile",
                    systemImage: "person"
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
            for: .tabBar
        )
        .toolbarBackground(
            .visible,
            for: .tabBar
        )
    }
}

#Preview {
    MainTabView(
        loginViewModel: LoginViewModel()
    )
}
