//
//  ContentView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 05/10/2026.
//

import SwiftUI

struct ContentView: View {

    @StateObject private var loginViewModel =
        LoginViewModel()

    var body: some View {

        if loginViewModel.isAuthenticated {

            MainTabView(
                loginViewModel: loginViewModel
            )

        } else {

            LoginView(
                viewModel: loginViewModel
            )
        }
    }
}

#Preview {
    ContentView()
}
