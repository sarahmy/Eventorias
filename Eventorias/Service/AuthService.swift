//
//  AuthService.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 09/10/2026.
//


import Foundation
import FirebaseAuth

// MARK: - Utilisateur authentifié

struct AuthenticatedUser {

    let uid: String
    let email: String?
    let displayName: String?
}

// MARK: - Erreurs d'authentification

enum AuthServiceError: Error, Equatable {

    case invalidEmail
    case invalidCredentials
    case emailAlreadyInUse
    case weakPassword
    case userNotFound
    case network
    case tooManyRequests
    case unknown
}

// MARK: - Protocole

@MainActor
protocol AuthServiceProtocol {

    var currentUser: AuthenticatedUser? {
        get
    }

    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticatedUser

    func createUser(
        email: String,
        password: String
    ) async throws -> AuthenticatedUser

    func signOut() throws
}

// MARK: - Firebase

@MainActor
final class FirebaseAuthService:
    AuthServiceProtocol {

    var currentUser: AuthenticatedUser? {

        guard
            let user =
                Auth.auth().currentUser
        else {
            return nil
        }

        return makeUser(
            from: user
        )
    }

    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticatedUser {

        do {

            let result =
                try await Auth.auth()
                    .signIn(
                        withEmail: email,
                        password: password
                    )

            return makeUser(
                from: result.user
            )

        } catch {

            throw mapError(error)
        }
    }

    func createUser(
        email: String,
        password: String
    ) async throws -> AuthenticatedUser {

        do {

            let result =
                try await Auth.auth()
                    .createUser(
                        withEmail: email,
                        password: password
                    )

            return makeUser(
                from: result.user
            )

        } catch {

            throw mapError(error)
        }
    }

    func signOut() throws {

        do {

            try Auth.auth()
                .signOut()

        } catch {

            throw AuthServiceError
                .unknown
        }
    }

    // MARK: - Helpers

    private func makeUser(
        from user: User
    ) -> AuthenticatedUser {

        AuthenticatedUser(
            uid: user.uid,
            email: user.email,
            displayName:
                user.displayName
        )
    }

    private func mapError(
        _ error: Error
    ) -> AuthServiceError {

        guard
            let firebaseError =
                AuthErrorCode(
                    _bridgedNSError:
                        error as NSError
                )
        else {
            return .unknown
        }

        switch firebaseError.code {

        case .invalidEmail:
            return .invalidEmail

        case .wrongPassword,
             .invalidCredential:
            return .invalidCredentials

        case .emailAlreadyInUse:
            return .emailAlreadyInUse

        case .weakPassword:
            return .weakPassword

        case .userNotFound:
            return .userNotFound

        case .networkError:
            return .network

        case .tooManyRequests:
            return .tooManyRequests

        default:
            return .unknown
        }
    }
}
