//
//  EventEditViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 08/10/2026.
//

import Foundation
import Combine

@MainActor
final class EventEditViewModel:
    ObservableObject {

    @Published var title: String
    @Published var description: String
    @Published var date: Date
    @Published var location: String
    @Published var category: String

    @Published var isLoading = false
    @Published var errorMessage: String?

    let existingImageURL: String?

    private let originalEvent:
        EventModel

    private let authService:
        AuthServiceProtocol

    private let repository:
        EventEditRepositoryProtocol

    private let storageService:
        EventImageStorageServiceProtocol

    private let geocodingService:
        GeocodingServiceProtocol

    // MARK: - Initialisation

    init(
        event: EventModel,
        authService:
            AuthServiceProtocol? = nil,
        repository:
            EventEditRepositoryProtocol? = nil,
        storageService:
            EventImageStorageServiceProtocol? = nil,
        geocodingService:
            GeocodingServiceProtocol? = nil
    ) {

        originalEvent = event

        title = event.title
        description = event.description
        date = event.date
        location = event.location
        category = event.category
        existingImageURL =
            event.imageURL

        self.authService =
            authService
            ?? FirebaseAuthService()

        self.repository =
            repository
            ?? FirebaseEventEditRepository()

        self.storageService =
            storageService
            ?? FirebaseEventImageStorageService()

        self.geocodingService =
            geocodingService
            ?? AppleGeocodingService()
    }

    // MARK: - Mise à jour

    func updateEvent(
        imageData: Data?
    ) async -> EventModel? {

        errorMessage = nil

        guard
            let user =
                authService.currentUser
        else {

            errorMessage =
                "Utilisateur non connecté."

            return nil
        }

        guard
            user.uid ==
                originalEvent.ownerId
        else {

            errorMessage =
                "Vous n'êtes pas autorisé à modifier cet événement."

            return nil
        }

        let cleanTitle =
            title.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        let cleanDescription =
            description
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let cleanLocation =
            location
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        let cleanCategory =
            category
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        guard
            !cleanTitle.isEmpty
        else {

            errorMessage =
                "Veuillez saisir un titre."

            return nil
        }

        guard
            !cleanLocation.isEmpty
        else {

            errorMessage =
                "Veuillez saisir une adresse."

            return nil
        }

        guard
            !cleanCategory.isEmpty
        else {

            errorMessage =
                "Veuillez saisir une catégorie."

            return nil
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            let coordinate =
                try await geocodingService
                    .coordinate(
                        for:
                            cleanLocation
                    )

            var newImageURL =
                existingImageURL

            if let imageData {

                newImageURL =
                    try await storageService
                        .uploadEventImage(
                            data:
                                imageData,
                            userId:
                                user.uid,
                            eventId:
                                originalEvent.id
                        )
            }

            let titleLowercase =
                normalize(
                    cleanTitle
                )

            let searchKeywords =
                makeSearchKeywords(
                    title:
                        cleanTitle,
                    description:
                        cleanDescription,
                    location:
                        cleanLocation,
                    category:
                        cleanCategory
                )

            let record =
                EventUpdateRecord(

                    title:
                        cleanTitle,

                    titleLowercase:
                        titleLowercase,

                    description:
                        cleanDescription,

                    date:
                        date,

                    location:
                        cleanLocation,

                    category:
                        cleanCategory,

                    ownerId:
                        user.uid,

                    latitude:
                        coordinate.latitude,

                    longitude:
                        coordinate.longitude,

                    searchKeywords:
                        searchKeywords,

                    imageURL:
                        newImageURL
                )

            try await repository
                .updateEvent(
                    id:
                        originalEvent.id,
                    record:
                        record
                )

            return EventModel(
                id:
                    originalEvent.id,
                title:
                    cleanTitle,
                titleLowercase:
                    titleLowercase,
                description:
                    cleanDescription,
                date:
                    date,
                location:
                    cleanLocation,
                category:
                    cleanCategory,
                ownerId:
                    user.uid,
                imageURL:
                    newImageURL
            )

        } catch {

            print(
                "[Event update]",
                error.localizedDescription
            )

            errorMessage =
                readableErrorMessage(
                    from: error
                )

            return nil
        }
    }

    // MARK: - Recherche

    private func makeSearchKeywords(
        title: String,
        description: String,
        location: String,
        category: String
    ) -> [String] {

        let source = [
            title,
            description,
            location,
            category
        ]
        .joined(
            separator: " "
        )

        let normalized =
            normalize(source)

        let separators =
            CharacterSet
                .alphanumerics
                .inverted

        let words =
            normalized
                .components(
                    separatedBy:
                        separators
                )
                .filter {
                    !$0.isEmpty
                }

        return Array(
            Set(words)
        )
    }

    private func normalize(
        _ value: String
    ) -> String {

        value
            .folding(
                options: [
                    .diacriticInsensitive,
                    .caseInsensitive
                ],
                locale: .current
            )
            .lowercased()
    }

    // MARK: - Erreurs

    private func readableErrorMessage(
        from error: Error
    ) -> String {

        /*
         AppleGeocodingService est le même service
         que celui utilisé lors de la création.
         Il peut donc renvoyer EventCreationError.
         */

        if let geocodingError =
            error as? EventCreationError {

            switch geocodingError {

            case .invalidAddress,
                 .addressNotFound:

                return
                    "L'adresse indiquée est introuvable. Vérifiez-la puis réessayez."
            }
        }

        return
            "Impossible de modifier l'événement. Vérifiez votre connexion puis réessayez."
    }
}
