//
//  ProfileView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import SwiftUI

struct ProfileView: View {

    @ObservedObject var loginViewModel: LoginViewModel

    @State private var notificationsEnabled = true
    @State private var showLogoutAlert = false

    var body: some View {

        ZStack {

            Color(
                red: 0.08,
                green: 0.07,
                blue: 0.09
            )
            .ignoresSafeArea()

            VStack(spacing: 22) {

                header

                profileInformation

                notificationSetting

                Spacer()

                logoutButton
            }
            .padding(.horizontal, 20)
            .padding(.top, 20)
            .padding(.bottom, 20)
        }
        .alert(
            "Déconnexion",
            isPresented: $showLogoutAlert
        ) {

            Button(
                "Annuler",
                role: .cancel
            ) {}

            Button(
                "Se déconnecter",
                role: .destructive
            ) {
                loginViewModel.signOut()
            }

        } message: {

            Text(
                "Voulez-vous vraiment vous déconnecter ?"
            )
        }
    }

    private var header: some View {

        HStack {

            Text("User profile")
                .font(.title2)
                .fontWeight(.bold)
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Image(
                systemName: "person.crop.circle.fill"
            )
            .font(.system(size: 42))
            .foregroundStyle(.white.opacity(0.85))
            .accessibilityHidden(true)
        }
    }

    private var profileInformation: some View {

        VStack(spacing: 14) {

            profileField(
                title: "Name",
                value: "Utilisateur"
            )

            profileField(
                title: "E-mail",
                value:
                    loginViewModel.currentUserEmail
                    ?? "Adresse e-mail indisponible"
            )
        }
    }

    private func profileField(
        title: String,
        value: String
    ) -> some View {

        VStack(
            alignment: .leading,
            spacing: 5
        ) {

            Text(title)
                .font(.caption)
                .foregroundStyle(
                    .white.opacity(0.6)
                )

            Text(value)
                .foregroundStyle(.white)
                .frame(
                    maxWidth: .infinity,
                    alignment: .leading
                )
        }
        .padding()
        .background(
            Color.white.opacity(0.15)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 6
            )
        )
    }

    private var notificationSetting: some View {

        HStack {

            Toggle(
                isOn: $notificationsEnabled
            ) {
                Text("Notifications")
                    .foregroundStyle(.white)
            }
            .tint(.red)
        }
        .padding(.horizontal, 4)
        .accessibilityLabel(
            "Notifications"
        )
    }

    private var logoutButton: some View {

        Button {

            showLogoutAlert = true

        } label: {

            HStack(spacing: 10) {

                Image(
                    systemName:
                        "rectangle.portrait.and.arrow.right"
                )

                Text("Se déconnecter")
                    .fontWeight(.semibold)
            }
            .foregroundStyle(.white)
            .frame(
                maxWidth: .infinity
            )
            .frame(height: 52)
            .background(Color.red)
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 6
                )
            )
        }
        .accessibilityLabel(
            "Se déconnecter"
        )
    }
}

#Preview {
    ProfileView(
        loginViewModel: LoginViewModel()
    )
}
