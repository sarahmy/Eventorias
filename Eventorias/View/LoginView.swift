//
//  LoginView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//


import SwiftUI

@MainActor
struct LoginView: View {

    @ObservedObject var viewModel:
        LoginViewModel

    @State private var showForm =
        false

    @State private var isPasswordVisible =
        false

    @State private var showError =
        false

    @State private var alertMessage =
        ""

    var body: some View {

        ZStack {

            Color(
                red: 0.08,
                green: 0.07,
                blue: 0.09
            )
            .ignoresSafeArea()

            if showForm {

                authenticationForm

            } else {

                welcomeScreen
            }

            if viewModel.isLoading {

                loadingView
            }
        }
        .task(
            id:
                viewModel.errorMessage
        ) {

            guard
                let message =
                    viewModel.errorMessage,
                !message.isEmpty
            else {

                return
            }

            await Task.yield()

            alertMessage =
                message

            showError =
                true
        }
        .alert(
            "Erreur",
            isPresented:
                $showError
        ) {

            Button(
                "OK",
                role:
                    .cancel
            ) {

                showError =
                    false

                alertMessage =
                    ""

                viewModel.errorMessage =
                    nil
            }
            .accessibilityIdentifier(
                "login.error.ok"
            )

        } message: {

            Text(
                alertMessage
            )
        }
    }

    // MARK: - Welcome

    private var welcomeScreen:
        some View {

        VStack {

            Spacer()

            Image(
                "EventoriasLogo"
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: 210
            )
            .accessibilityLabel(
                "Eventorias"
            )
            .accessibilityIdentifier(
                "login.logo"
            )

            Spacer()
                .frame(
                    height: 65
                )

            Button {

                showForm =
                    true

            } label: {

                HStack(
                    spacing: 10
                ) {

                    Image(
                        systemName:
                            "envelope.fill"
                    )

                    Text(
                        "Sign in with email"
                    )
                    .fontWeight(
                        .semibold
                    )
                }
                .foregroundStyle(
                    .white
                )
                .frame(
                    maxWidth:
                        .infinity
                )
                .frame(
                    height: 52
                )
                .background(
                    Color.red
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 4
                    )
                )
            }
            .accessibilityElement(
                children:
                    .ignore
            )
            .accessibilityLabel(
                "Se connecter avec une adresse e-mail"
            )
            .accessibilityIdentifier(
                "login.emailEntry"
            )
            .padding(
                .horizontal,
                55
            )

            Spacer()
        }
    }

    // MARK: - Authentication Form

    private var authenticationForm:
        some View {

        VStack(
            spacing: 24
        ) {

            HStack {

                Button {

                    showForm =
                        false

                } label: {

                    Image(
                        systemName:
                            "chevron.left"
                    )
                    .foregroundStyle(
                        .white
                    )
                }
                .accessibilityLabel(
                    "Retour"
                )
                .accessibilityIdentifier(
                    "login.back"
                )

                Spacer()
            }

            Image(
                "EventoriasLogo"
            )
            .resizable()
            .scaledToFit()
            .frame(
                width: 170
            )
            .accessibilityLabel(
                "Eventorias"
            )

            Text(
                viewModel.isRegisterMode
                ? "Créer un compte"
                : "Connexion"
            )
            .font(
                .title2
            )
            .fontWeight(
                .bold
            )
            .foregroundStyle(
                .white
            )
            .accessibilityAddTraits(
                .isHeader
            )
            .accessibilityIdentifier(
                "login.title"
            )

            VStack(
                spacing: 16
            ) {

                emailField

                passwordField
            }

            submitButton

            modeButton

            Spacer()
        }
        .padding(
            .horizontal,
            28
        )
        .padding(
            .top,
            20
        )
    }

    // MARK: - Email

    private var emailField:
        some View {

        TextField(
            "Adresse e-mail",
            text:
                $viewModel.email
        )
        .keyboardType(
            .emailAddress
        )
        .textInputAutocapitalization(
            .never
        )
        .autocorrectionDisabled()
        .textContentType(
            .emailAddress
        )
        .padding()
        .background(
            Color.white
                .opacity(
                    0.15
                )
        )
        .foregroundStyle(
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
        .accessibilityIdentifier(
            "login.email"
        )
    }

    // MARK: - Password

    private var passwordField:
        some View {

        HStack {

            if isPasswordVisible {

                TextField(
                    "Mot de passe",
                    text:
                        $viewModel.password
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()
                .textContentType(
                    viewModel.isRegisterMode
                    ? .newPassword
                    : .password
                )
                .accessibilityIdentifier(
                    "login.password"
                )

            } else {

                SecureField(
                    "Mot de passe",
                    text:
                        $viewModel.password
                )
                .textInputAutocapitalization(
                    .never
                )
                .autocorrectionDisabled()
                .textContentType(
                    viewModel.isRegisterMode
                    ? .newPassword
                    : .password
                )
                .accessibilityIdentifier(
                    "login.password"
                )
            }

            Button {

                isPasswordVisible
                    .toggle()

            } label: {

                Image(
                    systemName:
                        isPasswordVisible
                        ? "eye.slash"
                        : "eye"
                )
                .foregroundStyle(
                    .white.opacity(
                        0.8
                    )
                )
            }
            .accessibilityLabel(
                isPasswordVisible
                ? "Masquer le mot de passe"
                : "Afficher le mot de passe"
            )
            .accessibilityIdentifier(
                "login.passwordVisibility"
            )
        }
        .padding()
        .background(
            Color.white
                .opacity(
                    0.15
                )
        )
        .foregroundStyle(
            .white
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
    }

    // MARK: - Submit

    private var submitButton:
        some View {

        Button {

            Task {

                await viewModel
                    .authenticate()
            }

        } label: {

            Text(
                viewModel.isRegisterMode
                ? "Créer mon compte"
                : "Se connecter"
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                .white
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .frame(
                height: 52
            )
            .background(
                Color.red
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 4
                )
            )
        }
        .disabled(
            viewModel.isLoading
        )
        .accessibilityIdentifier(
            "login.submit"
        )
    }

    // MARK: - Login / Register

    private var modeButton:
        some View {

        Button {

            viewModel
                .isRegisterMode
                .toggle()

            viewModel.password =
                ""

            viewModel.errorMessage =
                nil

            alertMessage =
                ""

            showError =
                false

            isPasswordVisible =
                false

        } label: {

            Text(
                viewModel.isRegisterMode
                ? "J'ai déjà un compte"
                : "Créer un compte"
            )
            .foregroundStyle(
                .white
            )
            .underline()
        }
        .accessibilityIdentifier(
            "login.modeToggle"
        )
    }

    // MARK: - Loading

    private var loadingView:
        some View {

        ZStack {

            Color.black
                .opacity(
                    0.6
                )
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(
                    .circular
                )
                .tint(
                    .white
                )
                .scaleEffect(
                    1.4
                )
                .accessibilityLabel(
                    "Chargement en cours"
                )
                .accessibilityIdentifier(
                    "login.loading"
                )
        }
    }
}

#Preview {

    LoginView(
        viewModel:
            LoginViewModel()
    )
}
