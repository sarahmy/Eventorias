//
//  EventListViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import Foundation
import Combine
import FirebaseFirestore

@MainActor
final class EventListViewModel: ObservableObject {

    enum SortOption: String, CaseIterable {
        case dateAscending = "Date : plus proche"
        case dateDescending = "Date : plus lointaine"
        case titleAscending = "Titre : A → Z"
        case titleDescending = "Titre : Z → A"
    }

    @Published var events: [EventModel] = []
    @Published var searchText = ""
    @Published var isLoading = false
    @Published var errorMessage: String?

    @Published var selectedSortOption: SortOption = .dateAscending

    private let database = Firestore.firestore()
    private var searchTask: Task<Void, Never>?

    func loadEvents() async {

        isLoading = true
        errorMessage = nil

        let searchTerms = makeSearchTerms(
            from: searchText
        )

        do {

            let snapshot: QuerySnapshot

            if searchTerms.isEmpty {

                snapshot = try await database
                    .collection("events")
                    .getDocuments()

            } else {

                snapshot = try await database
                    .collection("events")
                    .whereField(
                        "searchKeywords",
                        arrayContainsAny: Array(
                            searchTerms.prefix(30)
                        )
                    )
                    .getDocuments()
            }

            var loadedEvents: [EventModel] = []

            for document in snapshot.documents {

                let data = document.data()

                guard
                    let title = data["title"] as? String,
                    let timestamp = data["date"] as? Timestamp,
                    let location = data["location"] as? String,
                    let category = data["category"] as? String,
                    let ownerId = data["ownerId"] as? String
                else {
                    print(
                        "[Firestore] Document invalide :",
                        document.documentID
                    )

                    continue
                }

                let description =
                    data["description"] as? String ?? ""

                let titleLowercase =
                    data["titleLowercase"] as? String
                    ?? title.lowercased()

                let imageURL =
                    data["imageURL"] as? String

                let event = EventModel(
                    id: document.documentID,
                    title: title,
                    titleLowercase: titleLowercase,
                    description: description,
                    date: timestamp.dateValue(),
                    location: location,
                    category: category,
                    ownerId: ownerId,
                    imageURL: imageURL
                )

                loadedEvents.append(event)
            }

            events = loadedEvents

            sortEvents()

        } catch {

            print(
                "[Firestore] Erreur :",
                error.localizedDescription
            )

            errorMessage =
                "Impossible de charger les événements."

            events = []
        }

        isLoading = false
    }

    func searchTextDidChange() {

        searchTask?.cancel()

        searchTask = Task {

            try? await Task.sleep(
                for: .milliseconds(300)
            )

            guard !Task.isCancelled else {
                return
            }

            await loadEvents()
        }
    }

    func selectSortOption(
        _ option: SortOption
    ) {

        selectedSortOption = option

        sortEvents()
    }

    private func sortEvents() {

        switch selectedSortOption {

        case .dateAscending:

            events.sort {
                $0.date < $1.date
            }

        case .dateDescending:

            events.sort {
                $0.date > $1.date
            }

        case .titleAscending:

            events.sort {
                $0.title.localizedCaseInsensitiveCompare(
                    $1.title
                ) == .orderedAscending
            }

        case .titleDescending:

            events.sort {
                $0.title.localizedCaseInsensitiveCompare(
                    $1.title
                ) == .orderedDescending
            }
        }
    }

    private func makeSearchTerms(
        from text: String
    ) -> [String] {

        let normalizedText = text
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .lowercased()

        let separators =
            CharacterSet.alphanumerics.inverted

        let terms = normalizedText
            .components(
                separatedBy: separators
            )
            .filter {
                !$0.isEmpty
            }

        return Array(
            Set(terms)
        )
    }

    deinit {
        searchTask?.cancel()
    }
}
