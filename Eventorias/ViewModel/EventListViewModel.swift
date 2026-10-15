//
//  EventListViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import Foundation
import Combine

@MainActor
final class EventListViewModel:
    ObservableObject {

    enum SortOption:
        String,
        CaseIterable {

        case dateAscending =
            "Date : plus proche"

        case dateDescending =
            "Date : plus lointaine"

        case titleAscending =
            "Titre : A → Z"

        case titleDescending =
            "Titre : Z → A"
    }

    @Published var events:
        [EventModel] = []

    @Published var searchText =
        ""

    @Published var isLoading =
        false

    @Published var errorMessage:
        String?

    @Published var selectedSortOption:
        SortOption =
            .dateAscending

    private let repository:
        EventListRepositoryProtocol

    private let searchDelay:
        Duration

    private var searchTask:
        Task<Void, Never>?

    // MARK: - Init

    init(
        repository:
            EventListRepositoryProtocol? = nil,
        searchDelay:
            Duration =
                .milliseconds(300)
    ) {

        self.repository =
            repository
            ?? FirebaseEventListRepository()

        self.searchDelay =
            searchDelay
    }

    // MARK: - Chargement

    func loadEvents() async {

        isLoading = true
        errorMessage = nil

        defer {
            isLoading = false
        }

        let searchTerms =
            makeSearchTerms(
                from:
                    searchText
            )

        do {

            let loadedEvents =
                try await repository
                    .fetchEvents(
                        searchTerms:
                            searchTerms
                    )

            events =
                loadedEvents

            sortEvents()

        } catch {

            print(
                "[Events] Chargement :",
                error.localizedDescription
            )

            events = []

            errorMessage =
                "Impossible de charger les événements."
        }
    }

    // MARK: - Recherche

    func searchTextDidChange() {

        searchTask?.cancel()

        let delay =
            searchDelay

        searchTask =
            Task { [weak self] in

                try? await Task.sleep(
                    for:
                        delay
                )

                guard
                    !Task.isCancelled
                else {
                    return
                }

                await self?
                    .loadEvents()
            }
    }

    // MARK: - Tri

    func selectSortOption(
        _ option:
            SortOption
    ) {

        selectedSortOption =
            option

        sortEvents()
    }

    private func sortEvents() {

        switch selectedSortOption {

        case .dateAscending:

            events.sort {

                $0.date <
                $1.date
            }

        case .dateDescending:

            events.sort {

                $0.date >
                $1.date
            }

        case .titleAscending:

            events.sort {

                $0.title
                    .localizedCaseInsensitiveCompare(
                        $1.title
                    )
                == .orderedAscending
            }

        case .titleDescending:

            events.sort {

                $0.title
                    .localizedCaseInsensitiveCompare(
                        $1.title
                    )
                == .orderedDescending
            }
        }
    }

    // MARK: - Recherche normalisée

    private func makeSearchTerms(
        from text: String
    ) -> [String] {

        let normalizedText =
            text
                .folding(
                    options: [
                        .diacriticInsensitive,
                        .caseInsensitive
                    ],
                    locale:
                        .current
                )
                .lowercased()

        let separators =
            CharacterSet
                .alphanumerics
                .inverted

        let terms =
            normalizedText
                .components(
                    separatedBy:
                        separators
                )
                .filter {
                    !$0.isEmpty
                }

        return Array(
            Set(terms)
        )
    }
}
