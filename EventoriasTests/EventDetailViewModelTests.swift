//
//  EventDetailViewModelTests.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 09/10/2026.
//


import XCTest
@testable import Eventorias

@MainActor
final class EventDetailViewModelTests:
    XCTestCase {

    private var auth:
        MockDetailAuth!

    private var repository:
        MockDetailRepository!

    private var storage:
        MockDetailStorage!

    private var apiKeyProvider:
        MockAPIKeyProvider!

    private var event:
        EventModel!

    private var viewModel:
        EventDetailViewModel!

    override func setUp() {

        super.setUp()

        auth =
            MockDetailAuth()

        repository =
            MockDetailRepository()

        storage =
            MockDetailStorage()

        apiKeyProvider =
            MockAPIKeyProvider()

        auth.currentUser =
            AuthenticatedUser(
                uid:
                    "owner-123",
                email:
                    "owner@test.com",
                displayName:
                    nil
            )

        apiKeyProvider.key =
            "test-api-key"

        event =
            makeEvent()

        viewModel =
            makeViewModel(
                event:
                    event
            )
    }

    override func tearDown() {

        viewModel = nil
        event = nil
        apiKeyProvider = nil
        storage = nil
        repository = nil
        auth = nil

        super.tearDown()
    }

    // MARK: - État initial

    func testInitialEvent() {

        XCTAssertEqual(
            viewModel.event.id,
            "event-1"
        )

        XCTAssertEqual(
            viewModel.event.title,
            "Concert"
        )

        XCTAssertFalse(
            viewModel.isDeleting
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    // MARK: - Owner

    func testIsOwnerWhenUserMatches() {

        XCTAssertTrue(
            viewModel.isOwner
        )
    }

    func testIsNotOwnerWhenUserDiffers() {

        auth.currentUser =
            AuthenticatedUser(
                uid:
                    "another-user",
                email:
                    nil,
                displayName:
                    nil
            )

        XCTAssertFalse(
            viewModel.isOwner
        )
    }

    func testIsNotOwnerWithoutUser() {

        auth.currentUser =
            nil

        XCTAssertFalse(
            viewModel.isOwner
        )
    }

    // MARK: - Mise à jour locale

    func testApplyUpdatedEvent() {

        let updatedEvent =
            makeEvent(
                title:
                    "Nouveau titre"
            )

        viewModel
            .applyUpdatedEvent(
                updatedEvent
            )

        XCTAssertEqual(
            viewModel.event.title,
            "Nouveau titre"
        )
    }

    // MARK: - Suppression refusée

    func testUnauthorizedDelete()
        async {

        auth.currentUser =
            nil

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Vous n'êtes pas autorisé à supprimer cet événement."
        )

        XCTAssertFalse(
            repository.wasCalled
        )

        XCTAssertFalse(
            storage.wasCalled
        )
    }

    // MARK: - Suppression sans image

    func testDeleteWithoutImage()
        async {

        event =
            makeEvent(
                imageURL:
                    nil
            )

        viewModel =
            makeViewModel(
                event:
                    event
            )

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertTrue(result)

        XCTAssertTrue(
            repository.wasCalled
        )

        XCTAssertEqual(
            repository.receivedID,
            "event-1"
        )

        XCTAssertFalse(
            storage.wasCalled
        )

        XCTAssertFalse(
            viewModel.isDeleting
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    // MARK: - gs://

    func testDeleteWithGSStorageURL()
        async {

        event =
            makeEvent(
                imageURL:
                    "gs://bucket/image.jpg"
            )

        viewModel =
            makeViewModel(
                event:
                    event
            )

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertTrue(result)

        XCTAssertTrue(
            storage.wasCalled
        )

        XCTAssertEqual(
            storage.receivedURL,
            "gs://bucket/image.jpg"
        )
    }

    // MARK: - Firebase Storage HTTPS

    func testDeleteWithFirebaseStorageURL()
        async {

        event =
            makeEvent(
                imageURL:
                    "https://firebasestorage.googleapis.com/test.jpg"
            )

        viewModel =
            makeViewModel(
                event:
                    event
            )

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertTrue(result)

        XCTAssertTrue(
            storage.wasCalled
        )

        XCTAssertEqual(
            storage.receivedURL,
            "https://firebasestorage.googleapis.com/test.jpg"
        )
    }

    // MARK: - storage.googleapis.com

    func testDeleteWithGoogleStorageURL()
        async {

        event =
            makeEvent(
                imageURL:
                    "https://storage.googleapis.com/test.jpg"
            )

        viewModel =
            makeViewModel(
                event:
                    event
            )

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertTrue(result)

        XCTAssertTrue(
            storage.wasCalled
        )

        XCTAssertEqual(
            storage.receivedURL,
            "https://storage.googleapis.com/test.jpg"
        )
    }

    // MARK: - Image externe

    func testNonFirebaseImageIsNotDeletedFromStorage()
        async {

        event =
            makeEvent(
                imageURL:
                    "https://example.com/image.jpg"
            )

        viewModel =
            makeViewModel(
                event:
                    event
            )

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertTrue(result)

        XCTAssertTrue(
            repository.wasCalled
        )

        XCTAssertFalse(
            storage.wasCalled
        )
    }

    // MARK: - Erreur Storage

    func testStorageCleanupFailureDoesNotFailDeletion()
        async {

        event =
            makeEvent(
                imageURL:
                    "gs://bucket/test.jpg"
            )

        storage.error =
            MockDetailError.storage

        viewModel =
            makeViewModel(
                event:
                    event
            )

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertTrue(result)

        XCTAssertTrue(
            repository.wasCalled
        )

        XCTAssertTrue(
            storage.wasCalled
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertFalse(
            viewModel.isDeleting
        )
    }

    // MARK: - Erreur Firestore

    func testRepositoryDeleteFailure()
        async {

        repository.error =
            MockDetailError.repository

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertFalse(result)

        XCTAssertTrue(
            repository.wasCalled
        )

        XCTAssertFalse(
            storage.wasCalled
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de supprimer l'événement."
        )

        XCTAssertFalse(
            viewModel.isDeleting
        )
    }

    // MARK: - Image URL

    func testImageURLIsNilWithoutImage() {

        viewModel =
            makeViewModel(
                event:
                    makeEvent(
                        imageURL:
                            nil
                    )
            )

        XCTAssertNil(
            viewModel.eventImageURL
        )
    }

    func testImageURLIsNilForBlankString() {

        viewModel =
            makeViewModel(
                event:
                    makeEvent(
                        imageURL:
                            "     "
                    )
            )

        XCTAssertNil(
            viewModel.eventImageURL
        )
    }

    func testValidImageURL() {

        viewModel =
            makeViewModel(
                event:
                    makeEvent(
                        imageURL:
                            "https://example.com/image.jpg"
                    )
            )

        XCTAssertEqual(
            viewModel
                .eventImageURL?
                .absoluteString,
            "https://example.com/image.jpg"
        )
    }

    // MARK: - Maps key

    func testStaticMapURLIsNilWithoutKey() {

        apiKeyProvider.key =
            nil

        viewModel =
            makeViewModel(
                event:
                    event
            )

        XCTAssertNil(
            viewModel.staticMapURL
        )
    }

    func testStaticMapURLIsNilWithBlankKey() {

        apiKeyProvider.key =
            "      "

        viewModel =
            makeViewModel(
                event:
                    event
            )

        XCTAssertNil(
            viewModel.staticMapURL
        )
    }

    func testStaticMapURLIsNilWithUnresolvedVariable() {

        apiKeyProvider.key =
            "$(GOOGLE_MAPS_API_KEY)"

        viewModel =
            makeViewModel(
                event:
                    event
            )

        XCTAssertNil(
            viewModel.staticMapURL
        )
    }

    // MARK: - Maps URL valide

    func testStaticMapURLContainsExpectedParameters()
        throws {

        apiKeyProvider.key =
            "abc123"

        viewModel =
            makeViewModel(
                event:
                    event
            )

        let url =
            try XCTUnwrap(
                viewModel.staticMapURL
            )

        XCTAssertEqual(
            url.host,
            "maps.googleapis.com"
        )

        XCTAssertEqual(
            url.path,
            "/maps/api/staticmap"
        )

        let components =
            try XCTUnwrap(
                URLComponents(
                    url:
                        url,
                    resolvingAgainstBaseURL:
                        false
                )
            )

        let queryItems =
            components.queryItems
            ?? []

        let values =
            Dictionary(
                uniqueKeysWithValues:
                    queryItems.map {

                        (
                            $0.name,
                            $0.value ?? ""
                        )
                    }
            )

        XCTAssertEqual(
            values["center"],
            "Paris, France"
        )

        XCTAssertEqual(
            values["zoom"],
            "14"
        )

        XCTAssertEqual(
            values["size"],
            "640x320"
        )

        XCTAssertEqual(
            values["scale"],
            "2"
        )

        XCTAssertEqual(
            values["maptype"],
            "roadmap"
        )

        XCTAssertEqual(
            values["markers"],
            "color:red|Paris, France"
        )

        XCTAssertEqual(
            values["key"],
            "abc123"
        )
    }

    // MARK: - Formatage

    func testFormattedDate() {

        XCTAssertFalse(
            viewModel
                .formattedDate
                .isEmpty
        )
    }

    func testFormattedTime() {

        XCTAssertFalse(
            viewModel
                .formattedTime
                .isEmpty
        )
    }

    func testFormattedCategory() {

        XCTAssertEqual(
            viewModel
                .formattedCategory,
            "Music"
        )
    }

    // MARK: - Helpers

    private func makeViewModel(
        event: EventModel
    ) -> EventDetailViewModel {

        EventDetailViewModel(
            event:
                event,
            authService:
                auth,
            repository:
                repository,
            imageDeletionService:
                storage,
            apiKeyProvider:
                apiKeyProvider
        )
    }

    private func makeEvent(
        title: String =
            "Concert",
        imageURL: String? =
            nil
    ) -> EventModel {

        EventModel(
            id:
                "event-1",
            title:
                title,
            titleLowercase:
                title.lowercased(),
            description:
                "Description",
            date:
                Date(
                    timeIntervalSince1970:
                        1_800_000_000
                ),
            location:
                "Paris, France",
            category:
                "music",
            ownerId:
                "owner-123",
            imageURL:
                imageURL
        )
    }
}

// ============================================================
// MARK: - Mock Auth
// ============================================================

@MainActor
private final class MockDetailAuth:
    AuthServiceProtocol {

    var currentUser:
        AuthenticatedUser?

    func signIn(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockDetailError.unused
    }

    func createUser(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        throw MockDetailError.unused
    }

    func signOut() throws {}
}

// ============================================================
// MARK: - Mock Repository
// ============================================================

@MainActor
private final class MockDetailRepository:
    EventDetailRepositoryProtocol {

    var wasCalled =
        false

    var receivedID:
        String?

    var error:
        Error?

    func deleteEvent(
        id: String
    ) async throws {

        wasCalled =
            true

        receivedID =
            id

        if let error {
            throw error
        }
    }
}

// ============================================================
// MARK: - Mock Storage
// ============================================================

@MainActor
private final class MockDetailStorage:
    EventImageDeletionServiceProtocol {

    var wasCalled =
        false

    var receivedURL:
        String?

    var error:
        Error?

    func deleteImage(
        url: String
    ) async throws {

        wasCalled =
            true

        receivedURL =
            url

        if let error {
            throw error
        }
    }
}

// ============================================================
// MARK: - Mock Maps key
// ============================================================

private final class MockAPIKeyProvider:
    GoogleMapsAPIKeyProviderProtocol {

    var key:
        String?

    var googleMapsAPIKey:
        String? {

        key
    }
}

// ============================================================
// MARK: - Mock errors
// ============================================================

private enum MockDetailError:
    Error {

    case repository
    case storage
    case unused
}
