//
//  LoginViewModelTests.swift
//  EventoriasTests
//
//  Created by Sarah Maimoun on 09/10/2026.
//

import XCTest
@testable import Eventorias

@MainActor
final class LoginViewModelTests:
    XCTestCase {

    private var authService:
        MockAuthService!

    private var viewModel:
        LoginViewModel!

    override func setUp() {

        super.setUp()

        authService =
            MockAuthService()

        viewModel =
            LoginViewModel(
                authService:
                    authService
            )
    }

    override func tearDown() {

        viewModel = nil
        authService = nil

        super.tearDown()
    }

    // MARK: - État initial

    func testInitialStateWhenNoUserExists() {

        XCTAssertEqual(
            viewModel.email,
            ""
        )

        XCTAssertEqual(
            viewModel.password,
            ""
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertFalse(
            viewModel.isAuthenticated
        )

        XCTAssertFalse(
            viewModel.isRegisterMode
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertNil(
            viewModel.successMessage
        )
    }

    func testInitialStateWhenUserExists() {

        authService.currentUser =
            AuthenticatedUser(
                uid: "123",
                email:
                    "user@test.com",
                displayName:
                    "Sarah"
            )

        let authenticatedViewModel =
            LoginViewModel(
                authService:
                    authService
            )

        XCTAssertTrue(
            authenticatedViewModel
                .isAuthenticated
        )
    }

    // MARK: - Validation

    func testAuthenticationRejectsEmptyEmail()
        async {

        viewModel.email = ""
        viewModel.password =
            "password"

        await viewModel
            .authenticate()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir votre adresse e-mail."
        )

        XCTAssertFalse(
            authService
                .signInWasCalled
        )
    }

    func testAuthenticationRejectsWhitespaceEmail()
        async {

        viewModel.email =
            "     "

        viewModel.password =
            "password"

        await viewModel
            .authenticate()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir votre adresse e-mail."
        )
    }

    func testAuthenticationRejectsEmptyPassword()
        async {

        viewModel.email =
            "user@test.com"

        viewModel.password =
            ""

        await viewModel
            .authenticate()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir votre mot de passe."
        )

        XCTAssertFalse(
            authService
                .signInWasCalled
        )
    }

    func testRegistrationRejectsShortPassword()
        async {

        viewModel.isRegisterMode =
            true

        viewModel.email =
            "user@test.com"

        viewModel.password =
            "12345"

        await viewModel
            .authenticate()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Le mot de passe doit contenir au moins 6 caractères."
        )

        XCTAssertFalse(
            authService
                .createUserWasCalled
        )
    }

    // MARK: - Connexion

    func testSuccessfulSignIn()
        async {

        authService.signInUser =
            AuthenticatedUser(
                uid: "123",
                email:
                    "user@test.com",
                displayName: nil
            )

        viewModel.email =
            "user@test.com"

        viewModel.password =
            "password"

        await viewModel
            .authenticate()

        XCTAssertTrue(
            authService
                .signInWasCalled
        )

        XCTAssertTrue(
            viewModel
                .isAuthenticated
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    func testSignInTrimsEmail()
        async {

        authService.signInUser =
            AuthenticatedUser(
                uid: "123",
                email:
                    "user@test.com",
                displayName: nil
            )

        viewModel.email =
            "  user@test.com  "

        viewModel.password =
            "password"

        await viewModel
            .authenticate()

        XCTAssertEqual(
            authService
                .receivedEmail,
            "user@test.com"
        )
    }

    func testSignInPassesPassword()
        async {

        authService.signInUser =
            AuthenticatedUser(
                uid: "123",
                email:
                    "user@test.com",
                displayName: nil
            )

        viewModel.email =
            "user@test.com"

        viewModel.password =
            "Password123"

        await viewModel
            .authenticate()

        XCTAssertEqual(
            authService
                .receivedPassword,
            "Password123"
        )
    }

    // MARK: - Création compte

    func testSuccessfulRegistration()
        async {

        viewModel.isRegisterMode =
            true

        viewModel.email =
            "new@test.com"

        viewModel.password =
            "password"

        authService.createdUser =
            AuthenticatedUser(
                uid: "new-user",
                email:
                    "new@test.com",
                displayName: nil
            )

        await viewModel
            .authenticate()

        XCTAssertTrue(
            authService
                .createUserWasCalled
        )

        XCTAssertTrue(
            viewModel
                .isAuthenticated
        )

        XCTAssertEqual(
            viewModel.successMessage,
            "Votre compte a bien été créé."
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    // MARK: - Erreurs Firebase

    func testInvalidEmailError()
        async {

        await verifySignInError(
            .invalidEmail,
            expectedMessage:
                "L'adresse e-mail est invalide."
        )
    }

    func testInvalidCredentialsError()
        async {

        await verifySignInError(
            .invalidCredentials,
            expectedMessage:
                "E-mail ou mot de passe incorrect."
        )
    }

    func testEmailAlreadyInUseError()
        async {

        await verifySignInError(
            .emailAlreadyInUse,
            expectedMessage:
                "Un compte existe déjà avec cette adresse e-mail."
        )
    }

    func testWeakPasswordError()
        async {

        await verifySignInError(
            .weakPassword,
            expectedMessage:
                "Le mot de passe est trop faible."
        )
    }

    func testUserNotFoundError()
        async {

        await verifySignInError(
            .userNotFound,
            expectedMessage:
                "Aucun compte ne correspond à cette adresse e-mail."
        )
    }

    func testNetworkError()
        async {

        await verifySignInError(
            .network,
            expectedMessage:
                "Impossible de se connecter au réseau."
        )
    }

    func testTooManyRequestsError()
        async {

        await verifySignInError(
            .tooManyRequests,
            expectedMessage:
                "Trop de tentatives. Veuillez réessayer plus tard."
        )
    }

    func testUnknownAuthenticationError()
        async {

        await verifySignInError(
            .unknown,
            expectedMessage:
                "Une erreur est survenue. Veuillez réessayer."
        )
    }

    func testNonAuthenticationError()
        async {

        authService.signInError =
            MockError.generic

        viewModel.email =
            "user@test.com"

        viewModel.password =
            "password"

        await viewModel
            .authenticate()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Une erreur est survenue. Veuillez réessayer."
        )

        XCTAssertFalse(
            viewModel
                .isAuthenticated
        )
    }

    // MARK: - Erreur inscription

    func testRegistrationError()
        async {

        viewModel.isRegisterMode =
            true

        viewModel.email =
            "user@test.com"

        viewModel.password =
            "password"

        authService.createUserError =
            AuthServiceError
                .emailAlreadyInUse

        await viewModel
            .authenticate()

        XCTAssertFalse(
            viewModel
                .isAuthenticated
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Un compte existe déjà avec cette adresse e-mail."
        )
    }

    // MARK: - Déconnexion

    func testSuccessfulSignOut() {

        viewModel.isAuthenticated =
            true

        viewModel.email =
            "user@test.com"

        viewModel.password =
            "password"

        viewModel.signOut()

        XCTAssertTrue(
            authService
                .signOutWasCalled
        )

        XCTAssertFalse(
            viewModel
                .isAuthenticated
        )

        XCTAssertEqual(
            viewModel.email,
            ""
        )

        XCTAssertEqual(
            viewModel.password,
            ""
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    func testSignOutFailure() {

        viewModel.isAuthenticated =
            true

        authService.signOutError =
            AuthServiceError
                .unknown

        viewModel.signOut()

        XCTAssertTrue(
            viewModel
                .isAuthenticated
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de vous déconnecter."
        )
    }

    // MARK: - Rafraîchissement

    func testRefreshAuthenticationStateWithUser() {

        authService.currentUser =
            AuthenticatedUser(
                uid: "123",
                email:
                    "user@test.com",
                displayName: nil
            )

        viewModel
            .refreshAuthenticationState()

        XCTAssertTrue(
            viewModel
                .isAuthenticated
        )
    }

    func testRefreshAuthenticationStateWithoutUser() {

        authService.currentUser =
            nil

        viewModel.isAuthenticated =
            true

        viewModel
            .refreshAuthenticationState()

        XCTAssertFalse(
            viewModel
                .isAuthenticated
        )
    }

    // MARK: - Helper

    private func verifySignInError(
        _ error:
            AuthServiceError,
        expectedMessage:
            String
    ) async {

        authService.signInError =
            error

        viewModel.email =
            "user@test.com"

        viewModel.password =
            "password"

        await viewModel
            .authenticate()

        XCTAssertFalse(
            viewModel
                .isAuthenticated
        )

        XCTAssertFalse(
            viewModel
                .isLoading
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            expectedMessage
        )
    }
}

// MARK: - Mock Auth

@MainActor
private final class MockAuthService:
    AuthServiceProtocol {

    var currentUser:
        AuthenticatedUser?

    var signInUser:
        AuthenticatedUser?

    var createdUser:
        AuthenticatedUser?

    var signInError: Error?
    var createUserError: Error?
    var signOutError: Error?

    var signInWasCalled =
        false

    var createUserWasCalled =
        false

    var signOutWasCalled =
        false

    var receivedEmail:
        String?

    var receivedPassword:
        String?

    func signIn(
        email: String,
        password: String
    ) async throws -> AuthenticatedUser {

        signInWasCalled =
            true

        receivedEmail =
            email

        receivedPassword =
            password

        if let signInError {
            throw signInError
        }

        return signInUser
            ?? AuthenticatedUser(
                uid: "mock-user",
                email: email,
                displayName: nil
            )
    }

    func createUser(
        email: String,
        password: String
    ) async throws -> AuthenticatedUser {

        createUserWasCalled =
            true

        receivedEmail =
            email

        receivedPassword =
            password

        if let createUserError {
            throw createUserError
        }

        return createdUser
            ?? AuthenticatedUser(
                uid: "mock-user",
                email: email,
                displayName: nil
            )
    }

    func signOut() throws {

        signOutWasCalled =
            true

        if let signOutError {
            throw signOutError
        }

        currentUser = nil
    }
}

private enum MockError:
    Error {

    case generic
}
