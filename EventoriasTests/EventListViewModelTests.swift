//
//  EventListViewModelTests.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 09/10/2026.
//


import XCTest
@testable import Eventorias

@MainActor
final class EventListViewModelTests:
    XCTestCase {

    private var repository:
        MockEventListRepository!

    private var viewModel:
        EventListViewModel!

    override func setUp() {

        super.setUp()

        repository =
            MockEventListRepository()

        viewModel =
            EventListViewModel(
                repository:
                    repository,
                searchDelay:
                    .milliseconds(1)
            )
    }

    override func tearDown() {

        viewModel = nil
        repository = nil

        super.tearDown()
    }

    // MARK: - Initial state

    func testInitialState() {

        XCTAssertTrue(
            viewModel.events.isEmpty
        )

        XCTAssertEqual(
            viewModel.searchText,
            ""
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )

        XCTAssertEqual(
            viewModel.selectedSortOption,
            .dateAscending
        )
    }

    // MARK: - Chargement

    func testLoadEventsWithoutSearch()
        async {

        repository.events = [

            makeEvent(
                id: "later",
                title: "Later",
                dateOffset: 200
            ),

            makeEvent(
                id: "first",
                title: "First",
                dateOffset: 100
            )
        ]

        await viewModel
            .loadEvents()

        XCTAssertTrue(
            repository
                .receivedSearchTerms
                .isEmpty
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            [
                "first",
                "later"
            ]
        )

        XCTAssertFalse(
            viewModel.isLoading
        )

        XCTAssertNil(
            viewModel.errorMessage
        )
    }

    // MARK: - Recherche

    func testSearchTermsAreNormalized()
        async {

        viewModel.searchText =
            "Été Paris PARIS"

        await viewModel
            .loadEvents()

        XCTAssertEqual(
            Set(
                repository
                    .receivedSearchTerms
            ),
            Set([
                "ete",
                "paris"
            ])
        )
    }

    func testSearchTermsHandlePunctuation()
        async {

        viewModel.searchText =
            "Concert, Paris ! été"

        await viewModel
            .loadEvents()

        XCTAssertEqual(
            Set(
                repository
                    .receivedSearchTerms
            ),
            Set([
                "concert",
                "paris",
                "ete"
            ])
        )
    }

    func testEmptySearchProducesNoTerms()
        async {

        viewModel.searchText =
            "   , !   "

        await viewModel
            .loadEvents()

        XCTAssertTrue(
            repository
                .receivedSearchTerms
                .isEmpty
        )
    }

    // MARK: - Erreur chargement

    func testLoadFailure()
        async {

        viewModel.events = [
            makeEvent(
                id: "old"
            )
        ]

        repository.error =
            MockEventListError.failure

        await viewModel
            .loadEvents()

        XCTAssertTrue(
            viewModel.events.isEmpty
        )

        XCTAssertEqual(
            viewModel.errorMessage,
            "Impossible de charger les événements."
        )

        XCTAssertFalse(
            viewModel.isLoading
        )
    }

    // MARK: - Tri date croissante

    func testDateAscendingSort() {

        viewModel.events = [

            makeEvent(
                id: "three",
                dateOffset: 300
            ),

            makeEvent(
                id: "one",
                dateOffset: 100
            ),

            makeEvent(
                id: "two",
                dateOffset: 200
            )
        ]

        viewModel.selectSortOption(
            .dateAscending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            [
                "one",
                "two",
                "three"
            ]
        )
    }

    // MARK: - Tri date décroissante

    func testDateDescendingSort() {

        viewModel.events = [

            makeEvent(
                id: "one",
                dateOffset: 100
            ),

            makeEvent(
                id: "three",
                dateOffset: 300
            ),

            makeEvent(
                id: "two",
                dateOffset: 200
            )
        ]

        viewModel.selectSortOption(
            .dateDescending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            [
                "three",
                "two",
                "one"
            ]
        )
    }

    // MARK: - Tri titre A-Z

    func testTitleAscendingSort() {

        viewModel.events = [

            makeEvent(
                id: "z",
                title: "Zoo"
            ),

            makeEvent(
                id: "a",
                title: "art"
            ),

            makeEvent(
                id: "c",
                title: "Concert"
            )
        ]

        viewModel.selectSortOption(
            .titleAscending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            [
                "a",
                "c",
                "z"
            ]
        )
    }

    // MARK: - Tri titre Z-A

    func testTitleDescendingSort() {

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
                id: "c",
                title: "Concert"
            )
        ]

        viewModel.selectSortOption(
            .titleDescending
        )

        XCTAssertEqual(
            viewModel.events.map(\.id),
            [
                "z",
                "c",
                "a"
            ]
        )
    }

    // MARK: - Recherche différée

    func testSearchTextDidChangeReloadsEvents()
        async {

        viewModel.searchText =
            "Paris"

        viewModel
            .searchTextDidChange()

        try? await Task.sleep(
            for:
                .milliseconds(50)
        )

        XCTAssertGreaterThanOrEqual(
            repository.fetchCount,
            1
        )

        XCTAssertEqual(
            repository
                .receivedSearchTerms,
            ["paris"]
        )
    }

    // MARK: - Annulation debounce

    func testNewSearchCancelsPreviousSearch()
        async {

        let delayedViewModel =
            EventListViewModel(
                repository:
                    repository,
                searchDelay:
                    .milliseconds(100)
            )

        delayedViewModel.searchText =
            "Premier"

        delayedViewModel
            .searchTextDidChange()

        delayedViewModel.searchText =
            "Second"

        delayedViewModel
            .searchTextDidChange()

        try? await Task.sleep(
            for:
                .milliseconds(180)
        )

        XCTAssertEqual(
            repository.fetchCount,
            1
        )

        XCTAssertEqual(
            repository
                .receivedSearchTerms,
            ["second"]
        )
    }

    // MARK: - Raw values

    func testSortOptions() {

        XCTAssertEqual(
            EventListViewModel
                .SortOption
                .allCases
                .count,
            4
        )

        XCTAssertEqual(
            EventListViewModel
                .SortOption
                .dateAscending
                .rawValue,
            "Date : plus proche"
        )

        XCTAssertEqual(
            EventListViewModel
                .SortOption
                .dateDescending
                .rawValue,
            "Date : plus lointaine"
        )

        XCTAssertEqual(
            EventListViewModel
                .SortOption
                .titleAscending
                .rawValue,
            "Titre : A → Z"
        )

        XCTAssertEqual(
            EventListViewModel
                .SortOption
                .titleDescending
                .rawValue,
            "Titre : Z → A"
        )
    }

    // MARK: - Helpers

    private func makeEvent(
        id: String,
        title: String = "Event",
        dateOffset:
            TimeInterval = 0
    ) -> EventModel {

        EventModel(
            id:
                id,
            title:
                title,
            titleLowercase:
                title.lowercased(),
            description:
                "",
            date:
                Date(
                    timeIntervalSince1970:
                        1_800_000_000
                        + dateOffset
                ),
            location:
                "Paris",
            category:
                "music",
            ownerId:
                "user-1",
            imageURL:
                nil
        )
    }
}

// ============================================================
// MARK: - Mock repository
// ============================================================

@MainActor
private final class MockEventListRepository:
    EventListRepositoryProtocol {

    var events:
        [EventModel] = []

    var error:
        Error?

    var receivedSearchTerms:
        [String] = []

    var fetchCount =
        0

    func fetchEvents(
        searchTerms: [String]
    ) async throws
        -> [EventModel] {

        fetchCount += 1

        receivedSearchTerms =
            searchTerms

        if let error {
            throw error
        }

        return events
    }
}

// ============================================================
// MARK: - Mock error
// ============================================================

private enum MockEventListError:
    Error {

    case failure
}
