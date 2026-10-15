//
//  EventEditViewModelTests.swift
//  EventoriasTests
//
//  Created by Sarah Maimoun on 09/10/2026.


import XCTest
@testable import Eventorias

@MainActor
final class EventEditViewModelTests:
    XCTestCase {

    private var authService:
        MockEditAuthService!

    private var repository:
        MockEventEditRepository!

    private var storageService:
        MockEditImageStorageService!

    private var geocodingService:
        MockEditGeocodingService!

    private var originalEvent:
        EventModel!

    private var viewModel:
        EventEditViewModel!

    override func setUp() {

        super.setUp()

        authService =
            MockEditAuthService()

        repository =
            MockEventEditRepository()

        storageService =
            MockEditImageStorageService()

        geocodingService =
            MockEditGeocodingService()

        originalEvent =
            EventModel(
                id:
                    "event-123",
                title:
                    "Ancien titre",
                titleLowercase:
                    "ancien titre",
                description:
                    "Ancienne description",
                date:
                    Date(
                        timeIntervalSince1970:
                            1_700_000_000
                    ),
                location:
                    "Paris, France",
                category:
                    "music",
                ownerId:
                    "owner-123",
                imageURL:
                    "https://example.com/old.jpg"
            )

        authService.currentUser =
            AuthenticatedUser(
                uid:
                    "owner-123",
                email:
                    "owner@test.com",
                displayName:
                    "Owner"
            )

        storageService.uploadedURL =
            "https://example.com/new.jpg"

        geocodingService.result =
            GeocodedCoordinate(
                latitude:
                    48.8566,
                longitude:
                    2.3522
            )

        viewModel =
            EventEditViewModel(
                event:
                    originalEvent,
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
        originalEvent = nil

        geocodingService = nil
        storageService = nil
        repository = nil
        authService = nil

        super.tearDown()
    }

    // MARK: - Initialisation

    func testInitialValuesComeFromEvent() {

        XCTAssertEqual(
            viewModel.title,
            "Ancien titre"
        )

        XCTAssertEqual(
            viewModel.description,
            "Ancienne description"
        )

        XCTAssertEqual(
            viewModel.location,
            "Paris, France"
        )

        XCTAssertEqual(
            viewModel.category,
            "music"
        )

        XCTAssertEqual(
            viewModel.date,
            originalEvent.date
        )

        XCTAssertEqual(
            viewModel.existingImageURL,
            "https://example.com/old.jpg"
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    func testInitialImageCanBeNil() {

        let event =
            EventModel(
                id: "1",
                title: "Test",
                titleLowercase:
                    "test",
                description: "",
                date: Date(),
                location:
                    "Paris",
                category:
                    "music",
                ownerId:
                    "owner-123",
                imageURL: nil
            )

        let model =
            EventEditViewModel(
                event: event,
                authService:
                    authService,
                repository:
                    repository,
                storageService:
                    storageService,
                geocodingService:
                    geocodingService
            )

        XCTAssertNil(
            model.existingImageURL
        )
    }

    // MARK: - Authentification

    func testUpdateFailsWithoutAuthenticatedUser()
        async {

        authService.currentUser =
            nil

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Utilisateur non connecté."
        )

        XCTAssertFalse(
            geocodingService.wasCalled
        )

        XCTAssertFalse(
            repository.wasCalled
        )
    }

    func testUpdateFailsForDifferentUser()
        async {

        authService.currentUser =
            AuthenticatedUser(
                uid:
                    "another-user",
                email:
                    "other@test.com",
                displayName: nil
            )

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Vous n'êtes pas autorisé à modifier cet événement."
        )

        XCTAssertFalse(
            repository.wasCalled
        )
    }

    // MARK: - Validation titre

    func testEmptyTitleIsRejected()
        async {

        prepareValidModification()

        viewModel.title = ""

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir un titre."
        )

        XCTAssertFalse(
            geocodingService.wasCalled
        )
    }

    func testWhitespaceOnlyTitleIsRejected()
        async {

        prepareValidModification()

        viewModel.title =
            "       "

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir un titre."
        )
    }

    // MARK: - Validation adresse

    func testEmptyLocationIsRejected()
        async {

        prepareValidModification()

        viewModel.location = ""

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une adresse."
        )

        XCTAssertFalse(
            geocodingService.wasCalled
        )
    }

    func testWhitespaceOnlyLocationIsRejected()
        async {

        prepareValidModification()

        viewModel.location =
            "     "

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une adresse."
        )
    }

    // MARK: - Validation catégorie

    func testEmptyCategoryIsRejected()
        async {

        prepareValidModification()

        viewModel.category = ""

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une catégorie."
        )
    }

    func testWhitespaceOnlyCategoryIsRejected()
        async {

        prepareValidModification()

        viewModel.category =
            "    "

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Veuillez saisir une catégorie."
        )
    }

    // MARK: - Modification sans nouvelle image

    func testSuccessfulUpdateWithoutNewImage()
        async {

        prepareValidModification()

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNotNil(result)

        XCTAssertTrue(
            geocodingService.wasCalled
        )

        XCTAssertTrue(
            repository.wasCalled
        )

        XCTAssertFalse(
            storageService.wasCalled
        )

        XCTAssertEqual(
            repository.receivedEventID,
            "event-123"
        )

        XCTAssertEqual(
            result?.imageURL,
            "https://example.com/old.jpg"
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    func testExistingImageIsKeptWhenNoNewImageIsSelected()
        async {

        prepareValidModification()

        _ = await viewModel
            .updateEvent(
                imageData: nil
            )

        XCTAssertEqual(
            repository
                .receivedRecord?
                .imageURL,
            "https://example.com/old.jpg"
        )
    }

    // MARK: - Modification avec image

    func testSuccessfulUpdateWithNewImage()
        async {

        prepareValidModification()

        let imageData =
            Data(
                [1, 2, 3, 4]
            )

        let result =
            await viewModel
                .updateEvent(
                    imageData:
                        imageData
                )

        XCTAssertNotNil(result)

        XCTAssertTrue(
            storageService.wasCalled
        )

        XCTAssertEqual(
            storageService.receivedData,
            imageData
        )

        XCTAssertEqual(
            storageService.receivedUserID,
            "owner-123"
        )

        XCTAssertEqual(
            storageService.receivedEventID,
            "event-123"
        )

        XCTAssertEqual(
            repository
                .receivedRecord?
                .imageURL,
            "https://example.com/new.jpg"
        )

        XCTAssertEqual(
            result?.imageURL,
            "https://example.com/new.jpg"
        )
    }

    // MARK: - Valeurs sauvegardées

    func testUpdatedRecordContainsExpectedValues()
        async {

        viewModel.title =
            "  Festival Été  "

        viewModel.description =
            "  Nouvelle description  "

        viewModel.location =
            "  Lyon, France  "

        viewModel.category =
            "  Culture  "

        let newDate =
            Date(
                timeIntervalSince1970:
                    1_800_000_000
            )

        viewModel.date =
            newDate

        _ = await viewModel
            .updateEvent(
                imageData: nil
            )

        guard
            let record =
                repository
                    .receivedRecord
        else {

            XCTFail(
                "Le repository n'a reçu aucune donnée."
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
            "Nouvelle description"
        )

        XCTAssertEqual(
            record.date,
            newDate
        )

        XCTAssertEqual(
            record.location,
            "Lyon, France"
        )

        XCTAssertEqual(
            record.category,
            "Culture"
        )

        XCTAssertEqual(
            record.ownerId,
            "owner-123"
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
    }

    // MARK: - Event retourné

    func testReturnedEventContainsUpdatedValues()
        async {

        prepareValidModification()

        let newDate =
            Date(
                timeIntervalSince1970:
                    1_900_000_000
            )

        viewModel.date =
            newDate

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertEqual(
            result?.id,
            "event-123"
        )

        XCTAssertEqual(
            result?.title,
            "Nouveau titre"
        )

        XCTAssertEqual(
            result?.description,
            "Nouvelle description"
        )

        XCTAssertEqual(
            result?.date,
            newDate
        )

        XCTAssertEqual(
            result?.location,
            "Lyon, France"
        )

        XCTAssertEqual(
            result?.category,
            "culture"
        )

        XCTAssertEqual(
            result?.ownerId,
            "owner-123"
        )
    }

    // MARK: - Géocodage

    func testGeocodingReceivesTrimmedLocation()
        async {

        prepareValidModification()

        viewModel.location =
            "   Lyon, France   "

        _ = await viewModel
            .updateEvent(
                imageData: nil
            )

        XCTAssertEqual(
            geocodingService
                .receivedAddress,
            "Lyon, France"
        )
    }

    func testInvalidAddressError()
        async {

        prepareValidModification()

        geocodingService.error =
            EventCreationError
                .invalidAddress

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "L'adresse indiquée est introuvable. Vérifiez-la puis réessayez."
        )

        XCTAssertFalse(
            repository.wasCalled
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    func testAddressNotFoundError()
        async {

        prepareValidModification()

        geocodingService.error =
            EventCreationError
                .addressNotFound

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "L'adresse indiquée est introuvable. Vérifiez-la puis réessayez."
        )
    }

    // MARK: - Storage

    func testImageUploadFailure()
        async {

        prepareValidModification()

        storageService.error =
            MockEditError.storage

        let result =
            await viewModel
                .updateEvent(
                    imageData:
                        Data([1, 2])
                )

        XCTAssertNil(result)

        XCTAssertTrue(
            storageService.wasCalled
        )

        XCTAssertFalse(
            repository.wasCalled
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de modifier l'événement. Vérifiez votre connexion puis réessayez."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    // MARK: - Firestore

    func testRepositoryFailure()
        async {

        prepareValidModification()

        repository.error =
            MockEditError.firestore

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNil(result)

        XCTAssertTrue(
            repository.wasCalled
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de modifier l'événement. Vérifiez votre connexion puis réessayez."
        )

        XCTAssertFalse(
            viewModel.isLoading
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
            .updateEvent(
                imageData: nil
            )

        guard
            let keywords =
                repository
                    .receivedRecord?
                    .searchKeywords
        else {

            XCTFail(
                "Aucun mot-clé reçu."
            )

            return
        }

        let set =
            Set(keywords)

        XCTAssertTrue(
            set.contains(
                "festival"
            )
        )

        XCTAssertTrue(
            set.contains(
                "ete"
            )
        )

        XCTAssertTrue(
            set.contains(
                "musique"
            )
        )

        XCTAssertTrue(
            set.contains(
                "paris"
            )
        )

        XCTAssertTrue(
            set.contains(
                "ile"
            )
        )

        XCTAssertTrue(
            set.contains(
                "france"
            )
        )

        XCTAssertTrue(
            set.contains(
                "concert"
            )
        )
    }

    func testSearchKeywordsContainNoDuplicates()
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
            .updateEvent(
                imageData: nil
            )

        guard
            let keywords =
                repository
                    .receivedRecord?
                    .searchKeywords
        else {

            XCTFail(
                "Aucun mot-clé reçu."
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

    // MARK: - Erreur précédente

    func testSuccessfulUpdateClearsPreviousError()
        async {

        prepareValidModification()

        repository.error =
            MockEditError.firestore

        _ = await viewModel
            .updateEvent(
                imageData: nil
            )

        XCTAssertNotNil(
            viewModel.errorMessage
        )

        repository.error = nil

        let result =
            await viewModel
                .updateEvent(
                    imageData: nil
                )

        XCTAssertNotNil(result)

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    // MARK: - Helper

    private func prepareValidModification() {

        viewModel.title =
            "Nouveau titre"

        viewModel.description =
            "Nouvelle description"

        viewModel.location =
            "Lyon, France"

        viewModel.category =
            "culture"
    }
}

// ============================================================
// MARK: - Mock Auth
// ============================================================

@MainActor
private final class MockEditAuthService:
    AuthServiceProtocol {

    var currentUser:
        AuthenticatedUser?

    func signIn(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockEditError.unused
    }

    func createUser(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockEditError.unused
    }

    func signOut() throws {}
}

// ============================================================
// MARK: - Mock Repository
// ============================================================

@MainActor
private final class MockEventEditRepository:
    EventEditRepositoryProtocol {

    var wasCalled = false

    var receivedEventID:
        String?

    var receivedRecord:
        EventUpdateRecord?

    var error: Error?

    func updateEvent(
        id: String,
        record: EventUpdateRecord
    ) async throws {

        wasCalled = true

        receivedEventID = id
        receivedRecord = record

        if let error {
            throw error
        }
    }
}

// ============================================================
// MARK: - Mock Storage
// ============================================================

@MainActor
private final class MockEditImageStorageService:
    EventImageStorageServiceProtocol {

    var uploadedURL =
        "https://example.com/new.jpg"

    var error: Error?

    var wasCalled = false

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

        wasCalled = true

        receivedData = data
        receivedUserID = userId
        receivedEventID = eventId

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
private final class MockEditGeocodingService:
    GeocodingServiceProtocol {

    var result =
        GeocodedCoordinate(
            latitude: 48.8566,
            longitude: 2.3522
        )

    var error: Error?

    var wasCalled = false

    var receivedAddress:
        String?

    func coordinate(
        for address: String
    ) async throws
        -> GeocodedCoordinate {

        wasCalled = true
        receivedAddress = address

        if let error {
            throw error
        }

        return result
    }
}

// ============================================================
// MARK: - Erreurs
// ============================================================

private enum MockEditError:
    Error {

    case firestore
    case storage
    case unused
}
