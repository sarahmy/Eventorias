//
//  EventoriasTests.swift
//  EventoriasTests
//
//  Created by Sarah Maimoun on 05/10/2026.
//


import XCTest
import FirebaseAuth
@testable import Eventorias

final class EventoriasTests: XCTestCase {

    // MARK: - Helpers

    private func makeEvent(
        id: String = UUID().uuidString,
        title: String = "Concert",
        description: String = "Description",
        date: Date = Date(),
        location: String = "Paris, France",
        category: String = "music",
        ownerId: String = "user-1",
        imageURL: String? = nil
    ) -> EventModel {

        EventModel(
            id: id,
            title: title,
            titleLowercase: title.lowercased(),
            description: description,
            date: date,
            location: location,
            category: category,
            ownerId: ownerId,
            imageURL: imageURL
        )
    }

    override func setUp() async throws {

        try await super.setUp()

        try? Auth.auth().signOut()
    }

    // ============================================================
    // MARK: - EventModel
    // ============================================================

    func testEventModelStoresValuesCorrectly() {

        let date = Date(
            timeIntervalSince1970: 1_700_000_000
        )

        let event = makeEvent(
            id: "123",
            title: "Music Festival",
            description: "Festival à Paris",
            date: date,
            location: "Paris, France",
            category: "music",
            ownerId: "owner",
            imageURL: "https://example.com/image.jpg"
        )

        XCTAssertEqual(event.id, "123")
        XCTAssertEqual(event.title, "Music Festival")
        XCTAssertEqual(
            event.titleLowercase,
            "music festival"
        )
        XCTAssertEqual(
            event.description,
            "Festival à Paris"
        )
        XCTAssertEqual(event.date, date)
        XCTAssertEqual(
            event.location,
            "Paris, France"
        )
        XCTAssertEqual(
            event.category,
            "music"
        )
        XCTAssertEqual(
            event.ownerId,
            "owner"
        )
        XCTAssertEqual(
            event.imageURL,
            "https://example.com/image.jpg"
        )
    }

    func testEventModelAcceptsNilImageURL() {

        let event = makeEvent(
            imageURL: nil
        )

        XCTAssertNil(event.imageURL)
    }

    // ============================================================
    // MARK: - EventListViewModel / tri
    // ============================================================

    @MainActor
    func testDefaultSortOptionIsDateAscending() {

        let viewModel =
            EventListViewModel()

        XCTAssertEqual(
            viewModel.selectedSortOption,
            .dateAscending
        )
    }

    @MainActor
    func testInitialEventsAreEmpty() {

        let viewModel =
            EventListViewModel()

        XCTAssertTrue(
            viewModel.events.isEmpty
        )
    }

    @MainActor
    func testInitialSearchTextIsEmpty() {

        let viewModel =
            EventListViewModel()

        XCTAssertEqual(
            viewModel.searchText,
            ""
        )
    }

    @MainActor
    func testInitialLoadingStateIsFalse() {

        let viewModel =
            EventListViewModel()

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    @MainActor
    func testInitialErrorMessageIsNil() {

        let viewModel =
            EventListViewModel()

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    @MainActor
    func testDateAscendingSort() {

        let viewModel =
            EventListViewModel()

        let baseDate = Date()

        let event3 = makeEvent(
            id: "3",
            date:
                baseDate.addingTimeInterval(
                    300
                )
        )

        let event1 = makeEvent(
            id: "1",
            date:
                baseDate.addingTimeInterval(
                    100
                )
        )

        let event2 = makeEvent(
            id: "2",
            date:
                baseDate.addingTimeInterval(
                    200
                )
        )

        viewModel.events = [
            event3,
            event1,
            event2
        ]

        viewModel.selectSortOption(
            .dateAscending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            ["1", "2", "3"]
        )
    }

    @MainActor
    func testDateDescendingSort() {

        let viewModel =
            EventListViewModel()

        let baseDate = Date()

        let event1 = makeEvent(
            id: "1",
            date:
                baseDate.addingTimeInterval(
                    100
                )
        )

        let event2 = makeEvent(
            id: "2",
            date:
                baseDate.addingTimeInterval(
                    200
                )
        )

        let event3 = makeEvent(
            id: "3",
            date:
                baseDate.addingTimeInterval(
                    300
                )
        )

        viewModel.events = [
            event1,
            event2,
            event3
        ]

        viewModel.selectSortOption(
            .dateDescending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            ["3", "2", "1"]
        )
    }

    @MainActor
    func testTitleAscendingSort() {

        let viewModel =
            EventListViewModel()

        viewModel.events = [
            makeEvent(
                id: "z",
                title: "Zoo"
            ),
            makeEvent(
                id: "b",
                title: "concert"
            ),
            makeEvent(
                id: "a",
                title: "Art"
            )
        ]

        viewModel.selectSortOption(
            .titleAscending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            ["a", "b", "z"]
        )
    }

    @MainActor
    func testTitleDescendingSort() {

        let viewModel =
            EventListViewModel()

        viewModel.events = [
            makeEvent(
                id: "a",
                title: "Art"
            ),
            makeEvent(
                id: "z",
                title: "Zoo"
            ),
            makeEvent(
                id: "b",
                title: "Concert"
            )
        ]

        viewModel.selectSortOption(
            .titleDescending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            ["z", "b", "a"]
        )
    }

    @MainActor
    func testTitleSortingIsCaseInsensitive() {

        let viewModel =
            EventListViewModel()

        viewModel.events = [
            makeEvent(
                id: "b",
                title: "banana"
            ),
            makeEvent(
                id: "a",
                title: "APPLE"
            )
        ]

        viewModel.selectSortOption(
            .titleAscending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            ["a", "b"]
        )
    }

    @MainActor
    func testSelectingSortOptionUpdatesProperty() {

        let viewModel =
            EventListViewModel()

        viewModel.selectSortOption(
            .titleDescending
        )

        XCTAssertEqual(
            viewModel.selectedSortOption,
            .titleDescending
        )
    }

    @MainActor
    func testEverySortOptionHasExpectedTitle() {

        XCTAssertEqual(
            EventListViewModel.SortOption
                .dateAscending
                .rawValue,
            "Date : plus proche"
        )

        XCTAssertEqual(
            EventListViewModel.SortOption
                .dateDescending
                .rawValue,
            "Date : plus lointaine"
        )

        XCTAssertEqual(
            EventListViewModel.SortOption
                .titleAscending
                .rawValue,
            "Titre : A → Z"
        )

        XCTAssertEqual(
            EventListViewModel.SortOption
                .titleDescending
                .rawValue,
            "Titre : Z → A"
        )
    }

    @MainActor
    func testSortOptionContainsFourValues() {

        XCTAssertEqual(
            EventListViewModel
                .SortOption
                .allCases
                .count,
            4
        )
    }

    // ============================================================
    // MARK: - EventCreationViewModel
    // ============================================================

    @MainActor
    func testCreationInitialValues() {

        let viewModel =
            EventCreationViewModel()

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

    @MainActor
    func testCreationRejectsEmptyTitle() async {

        let viewModel =
            EventCreationViewModel()

        viewModel.title = ""

        viewModel.location =
            "Paris, France"

        viewModel.category =
            "music"

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

    @MainActor
    func testCreationRejectsWhitespaceOnlyTitle() async {

        let viewModel =
            EventCreationViewModel()

        viewModel.title =
            "     "

        viewModel.location =
            "Paris"

        viewModel.category =
            "music"

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

    @MainActor
    func testCreationRejectsEmptyLocation() async {

        let viewModel =
            EventCreationViewModel()

        viewModel.title =
            "Concert"

        viewModel.location =
            ""

        viewModel.category =
            "music"

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

    @MainActor
    func testCreationRejectsWhitespaceOnlyLocation() async {

        let viewModel =
            EventCreationViewModel()

        viewModel.title =
            "Concert"

        viewModel.location =
            "   "

        viewModel.category =
            "music"

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

    @MainActor
    func testCreationRejectsEmptyCategory() async {

        let viewModel =
            EventCreationViewModel()

        viewModel.title =
            "Concert"

        viewModel.location =
            "Paris"

        viewModel.category =
            ""

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

    @MainActor
    func testCreationRejectsWhitespaceOnlyCategory() async {

        let viewModel =
            EventCreationViewModel()

        viewModel.title =
            "Concert"

        viewModel.location =
            "Paris"

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

    @MainActor
    func testCreationRejectsValidFormWhenNoUserIsLoggedIn() async {

        try? Auth.auth().signOut()

        let viewModel =
            EventCreationViewModel()

        viewModel.title =
            "Concert"

        viewModel.description =
            "Concert à Paris"

        viewModel.location =
            "Paris, France"

        viewModel.category =
            "music"

        let result =
            await viewModel.createEvent(
                imageData: nil
            )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Utilisateur non connecté."
        )
    }

    // ============================================================
    // MARK: - EventDetailViewModel
    // ============================================================

    @MainActor
    func testDetailStoresEvent() {

        let event = makeEvent(
            id: "event-42",
            title: "Festival"
        )

        let viewModel =
            EventDetailViewModel(
                event: event
            )

        XCTAssertEqual(
            viewModel.event.id,
            "event-42"
        )

        XCTAssertEqual(
            viewModel.event.title,
            "Festival"
        )
    }

    @MainActor
    func testDetailIsNotOwnerWithoutAuthenticatedUser() {

        try? Auth.auth().signOut()

        let event =
            makeEvent(
                ownerId:
                    "owner-id"
            )

        let viewModel =
            EventDetailViewModel(
                event: event
            )

        XCTAssertFalse(
            viewModel.isOwner
        )
    }

    @MainActor
    func testDeleteFailsWithoutOwnership() async {

        try? Auth.auth().signOut()

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent(
                        ownerId:
                            "another-user"
                    )
            )

        let result =
            await viewModel
                .deleteEvent()

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Vous n'êtes pas autorisé à supprimer cet événement."
        )

        XCTAssertFalse(
            viewModel.isDeleting
        )
    }

    @MainActor
    func testApplyUpdatedEventReplacesEvent() {

        let original =
            makeEvent(
                id: "1",
                title: "Ancien titre"
            )

        let updated =
            makeEvent(
                id: "1",
                title: "Nouveau titre"
            )

        let viewModel =
            EventDetailViewModel(
                event: original
            )

        viewModel.applyUpdatedEvent(
            updated
        )

        XCTAssertEqual(
            viewModel.event.title,
            "Nouveau titre"
        )
    }

    @MainActor
    func testEventImageURLIsNilWhenImageIsNil() {

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent(
                        imageURL: nil
                    )
            )

        XCTAssertNil(
            viewModel.eventImageURL
        )
    }

    @MainActor
    func testEventImageURLIsNilWhenImageIsEmpty() {

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent(
                        imageURL: ""
                    )
            )

        XCTAssertNil(
            viewModel.eventImageURL
        )
    }

    @MainActor
    func testEventImageURLIsNilWhenImageContainsOnlySpaces() {

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent(
                        imageURL: "   "
                    )
            )

        XCTAssertNil(
            viewModel.eventImageURL
        )
    }

    @MainActor
    func testEventImageURLReturnsURL() {

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent(
                        imageURL:
                            "https://example.com/photo.jpg"
                    )
            )

        XCTAssertEqual(
            viewModel.eventImageURL?
                .absoluteString,
            "https://example.com/photo.jpg"
        )
    }

    @MainActor
    func testFormattedDateIsNotEmpty() {

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent()
            )

        XCTAssertFalse(
            viewModel
                .formattedDate
                .isEmpty
        )
    }

    @MainActor
    func testFormattedTimeIsNotEmpty() {

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent()
            )

        XCTAssertFalse(
            viewModel
                .formattedTime
                .isEmpty
        )
    }

    @MainActor
    func testFormattedCategoryIsCapitalized() {

        let viewModel =
            EventDetailViewModel(
                event:
                    makeEvent(
                        category:
                            "music"
                    )
            )

        XCTAssertEqual(
            viewModel
                .formattedCategory,
            "Music"
        )
    }

    @MainActor
    func testStaticMapURLContainsLocationWhenConfigured() throws {

        let event =
            makeEvent(
                location:
                    "Paris, France"
            )

        let viewModel =
            EventDetailViewModel(
                event: event
            )

        guard let url =
                viewModel.staticMapURL
        else {

            throw XCTSkip(
                "La clé Google Maps n'est pas disponible dans l'environnement de test."
            )
        }

        let absoluteURL =
            url.absoluteString

        XCTAssertTrue(
            absoluteURL.contains(
                "staticmap"
            )
        )

        XCTAssertTrue(
            absoluteURL.contains(
                "Paris"
            )
        )
    }

    // ============================================================
    // MARK: - EventEditViewModel
    // ============================================================

    @MainActor
    func testEditViewModelCopiesOriginalEventValues() {

        let event =
            makeEvent(
                title: "Festival",
                description:
                    "Description initiale",
                location:
                    "Paris",
                category:
                    "music",
                imageURL:
                    "https://example.com/a.jpg"
            )

        let viewModel =
            EventEditViewModel(
                event: event
            )

        XCTAssertEqual(
            viewModel.title,
            "Festival"
        )

        XCTAssertEqual(
            viewModel.description,
            "Description initiale"
        )

        XCTAssertEqual(
            viewModel.location,
            "Paris"
        )

        XCTAssertEqual(
            viewModel.category,
            "music"
        )

        XCTAssertEqual(
            viewModel.existingImageURL,
            "https://example.com/a.jpg"
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    @MainActor
    func testEditFailsWhenNoUserLoggedIn() async {

        try? Auth.auth().signOut()

        let viewModel =
            EventEditViewModel(
                event:
                    makeEvent(
                        ownerId:
                            "owner"
                    )
            )

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
    }

    // ============================================================
    // MARK: - UserProfileModel
    // ============================================================

    func testUserProfileModelStoresValues() {

        let profile =
            UserProfileModel(
                id: "user-1",
                name: "Sarah",
                email:
                    "sarah@example.com",
                avatarURL:
                    "https://example.com/avatar.jpg",
                notificationsEnabled:
                    true
            )

        XCTAssertEqual(
            profile.id,
            "user-1"
        )

        XCTAssertEqual(
            profile.name,
            "Sarah"
        )

        XCTAssertEqual(
            profile.email,
            "sarah@example.com"
        )

        XCTAssertEqual(
            profile.avatarURL,
            "https://example.com/avatar.jpg"
        )

        XCTAssertTrue(
            profile.notificationsEnabled
        )
    }

    func testUserProfileModelCanHaveNoAvatar() {

        let profile =
            UserProfileModel(
                id: "1",
                name: "Sarah",
                email:
                    "sarah@example.com",
                avatarURL: nil,
                notificationsEnabled:
                    false
            )

        XCTAssertNil(
            profile.avatarURL
        )

        XCTAssertFalse(
            profile.notificationsEnabled
        )
    }

    // ============================================================
    // MARK: - ProfileViewModel
    // ============================================================

    @MainActor
    func testProfileInitialState() {

        let viewModel =
            ProfileViewModel()

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

    @MainActor
    func testLoadProfileFailsWithoutAuthenticatedUser() async {

        try? Auth.auth().signOut()

        let viewModel =
            ProfileViewModel()

        await viewModel
            .loadProfile()

        XCTAssertEqual(
            viewModel.errorMessage,
            "Aucun utilisateur connecté."
        )
    }

    @MainActor
    func testSaveProfileFailsWithoutAuthenticatedUser() async {

        try? Auth.auth().signOut()

        let viewModel =
            ProfileViewModel()

        viewModel.name =
            "Sarah"

        let result =
            await viewModel
                .saveProfile(
                    imageData: nil
                )

        XCTAssertFalse(result)

        XCTAssertEqual(
            viewModel.errorMessage,
            "Aucun utilisateur connecté."
        )
    }

    // ============================================================
    // MARK: - LoginViewModel
    // ============================================================

    @MainActor
    func testLoginInitialState() {

        let viewModel =
            LoginViewModel()

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    @MainActor
    func testLoginEmailCanBeModified() {

        let viewModel =
            LoginViewModel()

        viewModel.email =
            "test@example.com"

        XCTAssertEqual(
            viewModel.email,
            "test@example.com"
        )
    }

    @MainActor
    func testLoginPasswordCanBeModified() {

        let viewModel =
            LoginViewModel()

        viewModel.password =
            "Password123"

        XCTAssertEqual(
            viewModel.password,
            "Password123"
        )
    }
}
