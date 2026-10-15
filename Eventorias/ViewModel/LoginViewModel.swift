//
//  LoginViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import Foundation
import Combine

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email = ""
    @Published var password = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var isAuthenticated: Bool

    @Published var isRegisterMode = false

    private let authService: AuthServiceProtocol

    // MARK: - Initialisation

    init(
        authService: AuthServiceProtocol? = nil
    ) {

        let service =
            authService
            ?? FirebaseAuthService()

        self.authService = service

        self.isAuthenticated =
            service.currentUser != nil
    }

    // MARK: - Authentification

    func authenticate() async {

        errorMessage = nil
        successMessage = nil

        let cleanEmail =
            email.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        guard !cleanEmail.isEmpty else {

            errorMessage =
                "Veuillez saisir votre adresse e-mail."

            return
        }

        guard !password.isEmpty else {

            errorMessage =
                "Veuillez saisir votre mot de passe."

            return
        }

        if isRegisterMode,
           password.count < 6 {

            errorMessage =
                "Le mot de passe doit contenir au moins 6 caractères."

            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            if isRegisterMode {

                _ = try await authService
                    .createUser(
                        email: cleanEmail,
                        password: password
                    )

                successMessage =
                    "Votre compte a bien été créé."

            } else {

                _ = try await authService
                    .signIn(
                        email: cleanEmail,
                        password: password
                    )
            }

            isAuthenticated = true

        } catch {

            isAuthenticated = false

            errorMessage =
                message(
                    for: error
                )
        }
    }

    // MARK: - Déconnexion

    func signOut() {

        errorMessage = nil
        successMessage = nil

        do {

            try authService.signOut()

            isAuthenticated = false

            email = ""
            password = ""

        } catch {

            errorMessage =
                "Impossible de vous déconnecter."
        }
    }

    // MARK: - État d'authentification

    func refreshAuthenticationState() {

        isAuthenticated =
            authService.currentUser != nil
    }

    // MARK: - Messages d'erreur

    private func message(
        for error: Error
    ) -> String {

        guard
            let authError =
                error as? AuthServiceError
        else {

            return
                "Une erreur est survenue. Veuillez réessayer."
        }

        switch authError {

        case .invalidEmail:

            return
                "L'adresse e-mail est invalide."

        case .invalidCredentials:

            return
                "E-mail ou mot de passe incorrect."

        case .emailAlreadyInUse:

            return
                "Un compte existe déjà avec cette adresse e-mail."

        case .weakPassword:

            return
                "Le mot de passe est trop faible."

        case .userNotFound:

            return
                "Aucun compte ne correspond à cette adresse e-mail."

        case .network:

            return
                "Impossible de se connecter au réseau."

        case .tooManyRequests:

            return
                "Trop de tentatives. Veuillez réessayer plus tard."

        case .unknown:

            return
                "Une erreur est survenue. Veuillez réessayer."
        }
    }
}
