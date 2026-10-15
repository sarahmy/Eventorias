//
//  ProfileViewModelTests.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 09/10/2026.
//


import XCTest
@testable import Eventorias

@MainActor
final class ProfileViewModelTests:
    XCTestCase {

    private var auth:
        MockProfileAuth!

    private var repository:
        MockProfileRepository!

    private var storage:
        MockProfileStorage!

    private var viewModel:
        ProfileViewModel!

    override func setUp() {

        super.setUp()

        auth =
            MockProfileAuth()

        repository =
            MockProfileRepository()

        storage =
            MockProfileStorage()

        auth.currentUser =
            AuthenticatedUser(
                uid:
                    "user-1",
                email:
                    "sarah@test.com",
                displayName:
                    "Sarah"
            )

        viewModel =
            ProfileViewModel(
                authService:
                    auth,
                repository:
                    repository,
                avatarStorage:
                    storage
            )
    }

    override func tearDown() {

        viewModel = nil
        storage = nil
        repository = nil
        auth = nil

        super.tearDown()
    }

    // MARK: - État initial

    func testInitialState() {

        XCTAssertEqual(
            viewModel.name,
            ""
        )

        XCTAssertEqual(
            viewModel.email,
            ""
        )

        XCTAssertNil(
            viewModel.avatarURL
        )

        XCTAssertFalse(
            viewModel.notificationsEnabled
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertNil(
            viewModel.successMessage
        )

        XCTAssertNil(
            viewModel.profile
        )
    }

    // MARK: - Chargement sans utilisateur

    func testLoadProfileWithoutUser()
        async {

        auth.currentUser = nil

        await viewModel
            .loadProfile()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Aucun utilisateur connecté."
        )

        XCTAssertFalse(
            repository.loadWasCalled
        )
    }

    // MARK: - Profil existant

    func testLoadExistingProfile()
        async {

        repository.loadedProfile =
            StoredProfileData(
                name:
                    "Sarah Maimoun",
                email:
                    "profil@test.com",
                avatarURL:
                    "https://example.com/avatar.jpg",
                notificationsEnabled:
                    true
            )

        await viewModel
            .loadProfile()

        XCTAssertEqual(
            viewModel.name,
            "Sarah Maimoun"
        )

        XCTAssertEqual(
            viewModel.email,
            "profil@test.com"
        )

        XCTAssertEqual(
            viewModel.avatarURL,
            "https://example.com/avatar.jpg"
        )

        XCTAssertTrue(
            viewModel.notificationsEnabled
        )

        XCTAssertEqual(
            viewModel.profile?.id,
            "user-1"
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    func testLoadExistingProfileUsesAuthFallbacks()
        async {

        repository.loadedProfile =
            StoredProfileData(
                name:
                    nil,
                email:
                    nil,
                avatarURL:
                    nil,
                notificationsEnabled:
                    nil
            )

        await viewModel
            .loadProfile()

        XCTAssertEqual(
            viewModel.name,
            "Sarah"
        )

        XCTAssertEqual(
            viewModel.email,
            "sarah@test.com"
        )

        XCTAssertNil(
            viewModel.avatarURL
        )

        XCTAssertFalse(
            viewModel.notificationsEnabled
        )
    }

    // MARK: - Création profil initial

    func testMissingProfileCreatesInitialProfile()
        async {

        repository.loadedProfile =
            nil

        await viewModel
            .loadProfile()

        XCTAssertTrue(
            repository
                .createInitialWasCalled
        )

        XCTAssertEqual(
            repository.initialUserID,
            "user-1"
        )

        XCTAssertEqual(
            repository.initialName,
            "Sarah"
        )

        XCTAssertEqual(
            repository.initialEmail,
            "sarah@test.com"
        )

        XCTAssertEqual(
            viewModel.name,
            "Sarah"
        )

        XCTAssertEqual(
            viewModel.email,
            "sarah@test.com"
        )
    }

    // MARK: - Erreurs chargement

    func testLoadProfileFailure()
        async {

        repository.loadError =
            MockProfileError.repository

        await viewModel
            .loadProfile()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de charger le profil."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    func testCreateInitialProfileFailure()
        async {

        repository.loadedProfile =
            nil

        repository.createInitialError =
            MockProfileError.repository

        await viewModel
            .loadProfile()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de charger le profil."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    // MARK: - Validation sauvegarde

    func testSaveWithoutUser()
        async {

        auth.currentUser =
            nil

        let result =
            await viewModel
                .saveProfile(
                    imageData:
                        nil
                )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Aucun utilisateur connecté."
        )
    }

    func testSaveRejectsEmptyName()
        async {

        viewModel.name =
            "     "

        let result =
            await viewModel
                .saveProfile(
                    imageData:
                        nil
                )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez renseigner votre nom."
        )

        XCTAssertFalse(
            repository.saveWasCalled
        )
    }

    // MARK: - Sauvegarde sans nouvelle image

    func testSuccessfulSaveWithoutNewAvatar()
        async {

        viewModel.name =
            "  Sarah Maimoun  "

        viewModel.email =
            "old@test.com"

        viewModel.avatarURL =
            "https://example.com/old.jpg"

        viewModel.notificationsEnabled =
            true

        let result =
            await viewModel
                .saveProfile(
                    imageData:
                        nil
                )

        XCTAssertTrue(result)

        XCTAssertFalse(
            storage.wasCalled
        )

        XCTAssertTrue(
            repository.saveWasCalled
        )

        XCTAssertEqual(
            repository
                .savedRecord?
                .name,
            "Sarah Maimoun"
        )

        XCTAssertEqual(
            repository
                .savedRecord?
                .email,
            "sarah@test.com"
        )

        XCTAssertEqual(
            repository
                .savedRecord?
                .avatarURL,
            "https://example.com/old.jpg"
        )

        XCTAssertEqual(
            repository
                .savedRecord?
                .notificationsEnabled,
            true
        )

        XCTAssertEqual(
            viewModel.successMessage,
            "Votre profil a bien été enregistré."
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    // MARK: - Sauvegarde avec avatar

    func testSuccessfulSaveWithNewAvatar()
        async {

        viewModel.name =
            "Sarah"

        storage.url =
            "https://example.com/new.jpg"

        let imageData =
            Data(
                [1, 2, 3]
            )

        let result =
            await viewModel
                .saveProfile(
                    imageData:
                        imageData
                )

        XCTAssertTrue(result)

        XCTAssertTrue(
            storage.wasCalled
        )

        XCTAssertEqual(
            storage.receivedData,
            imageData
        )

        XCTAssertEqual(
            storage.receivedUserID,
            "user-1"
        )

        XCTAssertEqual(
            viewModel.avatarURL,
            "https://example.com/new.jpg"
        )

        XCTAssertEqual(
            viewModel.profile?
                .avatarURL,
            "https://example.com/new.jpg"
        )
    }

    // MARK: - Email fallback

    func testSaveUsesExistingEmailIfAuthEmailIsNil()
        async {

        auth.currentUser =
            AuthenticatedUser(
                uid:
                    "user-1",
                email:
                    nil,
                displayName:
                    "Sarah"
            )

        viewModel.name =
            "Sarah"

        viewModel.email =
            "fallback@test.com"

        let result =
            await viewModel
                .saveProfile(
                    imageData:
                        nil
                )

        XCTAssertTrue(result)

        XCTAssertEqual(
            repository
                .savedRecord?
                .email,
            "fallback@test.com"
        )

        XCTAssertEqual(
            viewModel.email,
            "fallback@test.com"
        )
    }

    // MARK: - Erreur Storage

    func testAvatarUploadFailure()
        async {

        viewModel.name =
            "Sarah"

        storage.error =
            MockProfileError.storage

        let result =
            await viewModel
                .saveProfile(
                    imageData:
                        Data([1])
                )

        XCTAssertFalse(result)

        XCTAssertTrue(
            storage.wasCalled
        )

        XCTAssertFalse(
            repository.saveWasCalled
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible d'enregistrer le profil."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    // MARK: - Erreur repository

    func testSaveRepositoryFailure()
        async {

        viewModel.name =
            "Sarah"

        repository.saveError =
            MockProfileError.repository

        let result =
            await viewModel
                .saveProfile(
                    imageData:
                        nil
                )

        XCTAssertFalse(result)

        XCTAssertTrue(
            repository.saveWasCalled
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible d'enregistrer le profil."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }
}

// ============================================================
// MARK: - Mock Auth
// ============================================================

@MainActor
private final class MockProfileAuth:
    AuthServiceProtocol {

    var currentUser:
        AuthenticatedUser?

    func signIn(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockProfileError.unused
    }

    func createUser(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockProfileError.unused
    }

    func signOut() throws {}
}

// ============================================================
// MARK: - Mock Repository
// ============================================================

@MainActor
private final class MockProfileRepository:
    ProfileRepositoryProtocol {

    var loadedProfile:
        StoredProfileData?

    var loadError:
        Error?

    var createInitialError:
        Error?

    var saveError:
        Error?

    var loadWasCalled =
        false

    var createInitialWasCalled =
        false

    var saveWasCalled =
        false

    var initialUserID:
        String?

    var initialName:
        String?

    var initialEmail:
        String?

    var savedRecord:
        ProfileSaveRecord?

    func loadProfile(
        userId: String
    ) async throws
        -> StoredProfileData? {

        loadWasCalled =
            true

        if let loadError {
            throw loadError
        }

        return loadedProfile
    }

    func createInitialProfile(
        userId: String,
        name: String,
        email: String
    ) async throws {

        createInitialWasCalled =
            true

        initialUserID =
            userId

        initialName =
            name

        initialEmail =
            email

        if let createInitialError {
            throw createInitialError
        }
    }

    func saveProfile(
        userId: String,
        record: ProfileSaveRecord
    ) async throws {

        saveWasCalled =
            true

        savedRecord =
            record

        if let saveError {
            throw saveError
        }
    }
}

// ============================================================
// MARK: - Mock Storage
// ============================================================

@MainActor
private final class MockProfileStorage:
    ProfileAvatarStorageServiceProtocol {

    var url =
        "https://example.com/avatar.jpg"

    var error:
        Error?

    var wasCalled =
        false

    var receivedData:
        Data?

    var receivedUserID:
        String?

    func uploadAvatar(
        data: Data,
        userId: String
    ) async throws -> String {

        wasCalled =
            true

        receivedData =
            data

        receivedUserID =
            userId

        if let error {
            throw error
        }

        return url
    }
}

// ============================================================
// MARK: - Mock Error
// ============================================================

private enum MockProfileError:
    Error {

    case repository
    case storage
    case unused
}
