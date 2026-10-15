//
//  EventCreationViewModelTests.swift
//  EventoriasTests
//
//  Created by Sarah Maimoun on 09/10/2026.
//

import XCTest
@testable import Eventorias

@MainActor
final class EventCreationViewModelTests:
    XCTestCase {

    private var authService:
        MockCreationAuthService!

    private var repository:
        MockEventCreationRepository!

    private var storageService:
        MockEventImageStorageService!

    private var geocodingService:
        MockGeocodingService!

    private var viewModel:
        EventCreationViewModel!

    override func setUp() {

        super.setUp()

        authService =
            MockCreationAuthService()

        repository =
            MockEventCreationRepository()

        storageService =
            MockEventImageStorageService()

        geocodingService =
            MockGeocodingService()

        authService.currentUser =
            AuthenticatedUser(
                uid: "user-123",
                email:
                    "sarah@test.com",
                displayName:
                    "Sarah"
            )

        repository.eventID =
            "event-123"

        geocodingService.result =
            GeocodedCoordinate(
                latitude: 48.8566,
                longitude: 2.3522
            )

        storageService.uploadedURL =
            "https://example.com/event.jpg"

        viewModel =
            EventCreationViewModel(
                authService:
                    authService,
                repository:
                    repository,
                storageService:
                    storageService,
                geocodingService:
                    geocodingService
            )
    }

    override func tearDown() {

        viewModel = nil
        geocodingService = nil
        storageService = nil
        repository = nil
        authService = nil

        super.tearDown()
    }

    // MARK: - État initial

    func testInitialState() {

        XCTAssertEqual(
            viewModel.title,
            ""
        )

        XCTAssertEqual(
            viewModel.description,
            ""
        )

        XCTAssertEqual(
            viewModel.location,
            ""
        )

        XCTAssertEqual(
            viewModel.category,
            ""
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
    }

    // MARK: - Validation du titre

    func testEmptyTitleIsRejected()
        async {

        prepareValidForm()

        viewModel.title = ""

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir un titre."
        )

        XCTAssertFalse(
            geocodingService
                .wasCalled
        )

        XCTAssertFalse(
            repository
                .createWasCalled
        )
    }

    func testWhitespaceOnlyTitleIsRejected()
        async {

        prepareValidForm()

        viewModel.title =
            "     "

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir un titre."
        )
    }

    // MARK: - Validation adresse

    func testEmptyLocationIsRejected()
        async {

        prepareValidForm()

        viewModel.location = ""

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une adresse."
        )

        XCTAssertFalse(
            geocodingService
                .wasCalled
        )
    }

    func testWhitespaceOnlyLocationIsRejected()
        async {

        prepareValidForm()

        viewModel.location =
            "    "

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une adresse."
        )
    }

    // MARK: - Validation catégorie

    func testEmptyCategoryIsRejected()
        async {

        prepareValidForm()

        viewModel.category = ""

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une catégorie."
        )
    }

    func testWhitespaceOnlyCategoryIsRejected()
        async {

        prepareValidForm()

        viewModel.category =
            "   "

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une catégorie."
        )
    }

    // MARK: - Authentification

    func testCreationFailsWithoutAuthenticatedUser()
        async {

        prepareValidForm()

        authService.currentUser =
            nil

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Utilisateur non connecté."
        )

        XCTAssertFalse(
            geocodingService
                .wasCalled
        )

        XCTAssertFalse(
            repository
                .createWasCalled
        )
    }

    // MARK: - Création sans image

    func testSuccessfulCreationWithoutImage()
        async {

        prepareValidForm()

        let expectedDate =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )

        viewModel.date =
            expectedDate

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertTrue(result)

        XCTAssertTrue(
            geocodingService
                .wasCalled
        )

        XCTAssertEqual(
            geocodingService
                .receivedAddress,
            "Paris, France"
        )

        XCTAssertTrue(
            repository
                .makeIDWasCalled
        )

        XCTAssertTrue(
            repository
                .createWasCalled
        )

        XCTAssertEqual(
            repository
                .receivedEventID,
            "event-123"
        )

        XCTAssertFalse(
            storageService
                .wasCalled
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertEqual(
            viewModel.successMessage,
            "L'événement a bien été créé."
        )
    }

    // MARK: - Valeurs envoyées à Firestore

    func testCreationSavesExpectedRecord()
        async {

        viewModel.title =
            "  Festival Été  "

        viewModel.description =
            "  Festival à Paris  "

        viewModel.location =
            "  Paris, France  "

        viewModel.category =
            "  Musique  "

        let selectedDate =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )

        viewModel.date =
            selectedDate

        _ = await viewModel
            .createEvent(
                imageData: nil
            )

        guard let record =
                repository
                    .receivedRecord
        else {

            XCTFail(
                "Aucun événement n'a été transmis au repository."
            )

            return
        }

        XCTAssertEqual(
            record.title,
            "Festival Été"
        )

        XCTAssertEqual(
            record.titleLowercase,
            "festival ete"
        )

        XCTAssertEqual(
            record.description,
            "Festival à Paris"
        )

        XCTAssertEqual(
            record.date,
            selectedDate
        )

        XCTAssertEqual(
            record.location,
            "Paris, France"
        )

        XCTAssertEqual(
            record.category,
            "Musique"
        )

        XCTAssertEqual(
            record.ownerId,
            "user-123"
        )

        XCTAssertEqual(
            record.latitude,
            48.8566,
            accuracy: 0.0001
        )

        XCTAssertEqual(
            record.longitude,
            2.3522,
            accuracy: 0.0001
        )

        XCTAssertNil(
            record.imageURL
        )
    }

    // MARK: - Keywords

    func testSearchKeywordsAreNormalized()
        async {

        viewModel.title =
            "Festival Été"

        viewModel.description =
            "Musique à Paris"

        viewModel.location =
            "Île-de-France"

        viewModel.category =
            "Concert"

        _ = await viewModel
            .createEvent(
                imageData: nil
            )

        guard let record =
                repository
                    .receivedRecord
        else {

            XCTFail(
                "Aucun record reçu."
            )

            return
        }

        let keywords =
            Set(
                record.searchKeywords
            )

        XCTAssertTrue(
            keywords.contains(
                "festival"
            )
        )

        XCTAssertTrue(
            keywords.contains(
                "ete"
            )
        )

        XCTAssertTrue(
            keywords.contains(
                "musique"
            )
        )

        XCTAssertTrue(
            keywords.contains(
                "paris"
            )
        )

        XCTAssertTrue(
            keywords.contains(
                "ile"
            )
        )

        XCTAssertTrue(
            keywords.contains(
                "de"
            )
        )

        XCTAssertTrue(
            keywords.contains(
                "france"
            )
        )

        XCTAssertTrue(
            keywords.contains(
                "concert"
            )
        )
    }

    func testSearchKeywordsDoNotContainDuplicates()
        async {

        viewModel.title =
            "Paris Paris"

        viewModel.description =
            "Paris"

        viewModel.location =
            "Paris"

        viewModel.category =
            "Paris"

        _ = await viewModel
            .createEvent(
                imageData: nil
            )

        guard let keywords =
                repository
                    .receivedRecord?
                    .searchKeywords
        else {

            XCTFail(
                "Aucun keyword reçu."
            )

            return
        }

        XCTAssertEqual(
            keywords.filter {
                $0 == "paris"
            }.count,
            1
        )
    }

    // MARK: - Création avec image

    func testSuccessfulCreationWithImage()
        async {

        prepareValidForm()

        let imageData =
            Data(
                [1, 2, 3, 4]
            )

        let result =
            await viewModel
                .createEvent(
                    imageData:
                        imageData
                )

        XCTAssertTrue(result)

        XCTAssertTrue(
            storageService
                .wasCalled
        )

        XCTAssertEqual(
            storageService
                .receivedData,
            imageData
        )

        XCTAssertEqual(
            storageService
                .receivedUserID,
            "user-123"
        )

        XCTAssertEqual(
            storageService
                .receivedEventID,
            "event-123"
        )

        XCTAssertEqual(
            repository
                .receivedRecord?
                .imageURL,
            "https://example.com/event.jpg"
        )
    }

    // MARK: - Erreur de géocodage

    func testInvalidAddressError()
        async {

        prepareValidForm()

        geocodingService.error =
            EventCreationError
                .invalidAddress

        let result =
            await viewModel
                .createEvent(
                    imageData: nil
                )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "L'adresse indiquée est introuvable. Vérifiez-la puis réessayez."
        )

        XCTAssertFalse(
            repository
                .createWasCalled
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    func testAddressNotFoundError()
        async {

        prepareValidForm()

        geocodingService.error =
            EventCreationError
                .addressNotFound

        let result =
            await viewModel
                .createEvent(
                    imageData: nil
                )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "L'adresse indiquée est introuvable. Vérifiez-la puis réessayez."
        )
    }

    // MARK: - Erreur Storage

    func testImageUploadFailure()
        async {

        prepareValidForm()

        storageService.error =
            MockCreationError
                .storage

        let result =
            await viewModel
                .createEvent(
                    imageData:
                        Data([1, 2])
                )

        XCTAssertFalse(result)

        XCTAssertTrue(
            storageService
                .wasCalled
        )

        XCTAssertFalse(
            repository
                .createWasCalled
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de créer l'événement."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    // MARK: - Erreur Firestore

    func testRepositoryFailure()
        async {

        prepareValidForm()

        repository.createError =
            MockCreationError
                .firestore

        let result =
            await viewModel
                .createEvent(
                    imageData: nil
                )

        XCTAssertFalse(result)

        XCTAssertTrue(
            repository
                .createWasCalled
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de créer l'événement."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    // MARK: - Réinitialisation

    func testFormIsResetAfterSuccessfulCreation()
        async {

        prepareValidForm()

        viewModel.description =
            "Description"

        let dateBeforeCreation =
            Date(
                timeIntervalSince1970:
                    1_700_000_000
            )

        viewModel.date =
            dateBeforeCreation

        let result =
            await viewModel
                .createEvent(
                    imageData: nil
                )

        XCTAssertTrue(result)

        XCTAssertEqual(
            viewModel.title,
            ""
        )

        XCTAssertEqual(
            viewModel.description,
            ""
        )

        XCTAssertEqual(
            viewModel.location,
            ""
        )

        XCTAssertEqual(
            viewModel.category,
            ""
        )

        XCTAssertNotEqual(
            viewModel.date,
            dateBeforeCreation
        )
    }

    func testFormIsNotResetAfterFailure()
        async {

        prepareValidForm()

        repository.createError =
            MockCreationError
                .firestore

        _ = await viewModel
            .createEvent(
                imageData: nil
            )

        XCTAssertEqual(
            viewModel.title,
            "Concert"
        )

        XCTAssertEqual(
            viewModel.location,
            "Paris, France"
        )

        XCTAssertEqual(
            viewModel.category,
            "music"
        )
    }

    // MARK: - Nettoyage des anciens messages

    func testNewCreationClearsPreviousMessages()
        async {

        prepareValidForm()

        repository.createError =
            MockCreationError
                .firestore

        _ = await viewModel
            .createEvent(
                imageData: nil
            )

        XCTAssertNotNil(
            viewModel.errorMessage
        )

        repository.createError =
            nil

        let result =
            await viewModel
                .createEvent(
                    imageData: nil
                )

        XCTAssertTrue(result)

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertEqual(
            viewModel.successMessage,
            "L'événement a bien été créé."
        )
    }

    // MARK: - Helper

    private func prepareValidForm() {

        viewModel.title =
            "Concert"

        viewModel.description =
            "Concert en soirée"

        viewModel.location =
            "Paris, France"

        viewModel.category =
            "music"
    }
}

// ============================================================
// MARK: - Mock Auth
// ============================================================

@MainActor
private final class MockCreationAuthService:
    AuthServiceProtocol {

    var currentUser:
        AuthenticatedUser?

    func signIn(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockCreationError
            .unused
    }

    func createUser(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockCreationError
            .unused
    }

    func signOut() throws {}
}

// ============================================================
// MARK: - Mock Repository
// ============================================================

@MainActor
private final class MockEventCreationRepository:
    EventCreationRepositoryProtocol {

    var eventID =
        "mock-event"

    var makeIDWasCalled =
        false

    var createWasCalled =
        false

    var receivedEventID:
        String?

    var receivedRecord:
        EventCreationRecord?

    var createError:
        Error?

    func makeEventID()
        -> String {

        makeIDWasCalled =
            true

        return eventID
    }

    func createEvent(
        id: String,
        record: EventCreationRecord
    ) async throws {

        createWasCalled =
            true

        receivedEventID =
            id

        receivedRecord =
            record

        if let createError {
            throw createError
        }
    }
}

// ============================================================
// MARK: - Mock Storage
// ============================================================

@MainActor
private final class MockEventImageStorageService:
    EventImageStorageServiceProtocol {

    var uploadedURL =
        "https://example.com/image.jpg"

    var error:
        Error?

    var wasCalled =
        false

    var receivedData:
        Data?

    var receivedUserID:
        String?

    var receivedEventID:
        String?

    func uploadEventImage(
        data: Data,
        userId: String,
        eventId: String
    ) async throws -> String {

        wasCalled =
            true

        receivedData =
            data

        receivedUserID =
            userId

        receivedEventID =
            eventId

        if let error {
            throw error
        }

        return uploadedURL
    }
}

// ============================================================
// MARK: - Mock Geocoding
// ============================================================

@MainActor
private final class MockGeocodingService:
    GeocodingServiceProtocol {

    var result =
        GeocodedCoordinate(
            latitude: 0,
            longitude: 0
        )

    var error:
        Error?

    var wasCalled =
        false

    var receivedAddress:
        String?

    func coordinate(
        for address: String
    ) async throws
        -> GeocodedCoordinate {

        wasCalled =
            true

        receivedAddress =
            address

        if let error {
            throw error
        }

        return result
    }
}

// ============================================================
// MARK: - Erreurs mock
// ============================================================

private enum MockCreationError:
    Error {

    case storage
    case firestore
    case unused
}
