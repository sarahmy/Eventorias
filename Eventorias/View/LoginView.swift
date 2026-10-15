//
//  LoginView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//


import SwiftUI

struct LoginView: View {

    @ObservedObject var viewModel:
        LoginViewModel

    @State private var showForm =
        false

    @State private var isPasswordVisible =
        false

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
        .alert(
            "Erreur",
            isPresented:
                errorBinding
        ) {

            Button("OK") {

                viewModel.errorMessage =
                    nil
            }

        } message: {

            Text(
                viewModel.errorMessage
                ?? ""
            )
        }
    }

    // MARK: - Welcome

    private var welcomeScreen:
        some View {

        VStack {

            Spacer()

            Image("EventoriasLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 210)
                .accessibilityLabel(
                    "Eventorias"
                )

            Spacer()
                .frame(height: 65)

            Button {

                showForm = true

            } label: {

                HStack(spacing: 10) {

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
                .foregroundStyle(.white)
                .frame(
                    maxWidth:
                        .infinity
                )
                .frame(height: 52)
                .background(
                    Color.red
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 4
                    )
                )
            }
            .padding(
                .horizontal,
                55
            )
            .accessibilityLabel(
                "Se connecter avec une adresse e-mail"
            )
            .accessibilityIdentifier(
                "login.emailEntry"
            )

            Spacer()
        }
    }

    // MARK: - Formulaire

    private var authenticationForm:
        some View {

        VStack(spacing: 24) {

            HStack {

                Button {

                    showForm = false

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

            Image("EventoriasLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 170)
                .accessibilityLabel(
                    "Eventorias"
                )

            Text(
                viewModel.isRegisterMode
                ? "Créer un compte"
                : "Connexion"
            )
            .font(.title2)
            .fontWeight(.bold)
            .foregroundStyle(.white)
            .accessibilityAddTraits(
                .isHeader
            )
            .accessibilityIdentifier(
                "login.title"
            )

            VStack(spacing: 16) {

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
                        .opacity(0.15)
                )
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )
                .accessibilityIdentifier(
                    "login.email"
                )

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
                            .white
                                .opacity(0.8)
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
                        .opacity(0.15)
                )
                .foregroundStyle(.white)
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 8
                    )
                )
            }

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
                .foregroundStyle(.white)
                .frame(
                    maxWidth:
                        .infinity
                )
                .frame(height: 52)
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

            Button {

                viewModel
                    .isRegisterMode
                    .toggle()

                viewModel.password =
                    ""

                viewModel.errorMessage =
                    nil

                isPasswordVisible =
                    false

            } label: {

                Text(
                    viewModel.isRegisterMode
                    ? "J'ai déjà un compte"
                    : "Créer un compte"
                )
                .foregroundStyle(.white)
                .underline()
            }
            .accessibilityIdentifier(
                "login.modeToggle"
            )

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

    // MARK: - Loading

    private var loadingView:
        some View {

        ZStack {

            Color.black
                .opacity(0.6)
                .ignoresSafeArea()

            ProgressView()
                .progressViewStyle(
                    .circular
                )
                .tint(.white)
                .scaleEffect(1.4)
                .accessibilityLabel(
                    "Chargement en cours"
                )
        }
    }

    // MARK: - Error

    private var errorBinding:
        Binding<Bool> {

        Binding(
            get: {

                viewModel
                    .errorMessage
                    != nil
            },
            set: { value in

                if !value {

                    viewModel
                        .errorMessage =
                        nil
                }
            }
        )
    }
}

#Preview {

    LoginView(
        viewModel:
            LoginViewModel()
    )
}
