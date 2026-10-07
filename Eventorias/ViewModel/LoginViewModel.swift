//
//  LoginViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//
 

import Foundation
import Combine
import FirebaseAuth

@MainActor
final class LoginViewModel: ObservableObject {

    @Published var email = ""
    @Published var password = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    @Published var isAuthenticated = false
    @Published var isRegisterMode = false

    @Published var currentUserEmail: String?

    init() {
        let currentUser = Auth.auth().currentUser

        isAuthenticated = currentUser != nil
        currentUserEmail = currentUser?.email
    }

    func authenticate() async {
        errorMessage = nil
        successMessage = nil

        let cleanEmail = email
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard !cleanEmail.isEmpty else {
            errorMessage = "Veuillez saisir votre adresse e-mail."
            return
        }

        guard !password.isEmpty else {
            errorMessage = "Veuillez saisir votre mot de passe."
            return
        }

        guard password.count >= 6 else {
            errorMessage = "Le mot de passe doit contenir au moins 6 caractères."
            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {
            if isRegisterMode {
                let result = try await Auth.auth().createUser(
                    withEmail: cleanEmail,
                    password: password
                )

                currentUserEmail = result.user.email
                successMessage = "Compte créé avec succès."

            } else {
                let result = try await Auth.auth().signIn(
                    withEmail: cleanEmail,
                    password: password
                )

                currentUserEmail = result.user.email
                successMessage = "Connexion réussie."
            }

            isAuthenticated = true

        } catch {
            errorMessage = firebaseErrorMessage(from: error)
        }
    }

    func signOut() {
        do {
            try Auth.auth().signOut()

            email = ""
            password = ""

            currentUserEmail = nil
            successMessage = nil
            errorMessage = nil

            isAuthenticated = false

        } catch {
            errorMessage = "Impossible de vous déconnecter."
        }
    }

    private func firebaseErrorMessage(from error: Error) -> String {

        let nsError = error as NSError

        guard let code = AuthErrorCode(rawValue: nsError.code) else {
            return "Une erreur est survenue. Veuillez réessayer."
        }

        switch code {

        case .invalidEmail:
            return "L'adresse e-mail n'est pas valide."

        case .wrongPassword, .invalidCredential:
            return "E-mail ou mot de passe incorrect."

        case .emailAlreadyInUse:
            return "Cette adresse e-mail est déjà utilisée."

        case .weakPassword:
            return "Le mot de passe n'est pas assez sécurisé."

        case .userNotFound:
            return "Aucun compte ne correspond à cette adresse e-mail."

        case .networkError:
            return "Erreur réseau. Vérifiez votre connexion Internet."

        case .tooManyRequests:
            return "Trop de tentatives. Réessayez plus tard."

        default:
            return "Une erreur est survenue. Veuillez réessayer."
        }
    }
}
