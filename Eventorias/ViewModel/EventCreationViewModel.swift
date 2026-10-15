//
//  EventCreationViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 08/10/2026.
//

import Foundation
import Combine

@MainActor
final class EventCreationViewModel:
    ObservableObject {

    @Published var title = ""
    @Published var description = ""
    @Published var date = Date()
    @Published var location = ""
    @Published var category = ""

    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var successMessage: String?

    private let authService:
        AuthServiceProtocol

    private let repository:
        EventCreationRepositoryProtocol

    private let storageService:
        EventImageStorageServiceProtocol

    private let geocodingService:
        GeocodingServiceProtocol

    // MARK: - Initialisation

    init(
        authService:
            AuthServiceProtocol? = nil,
        repository:
            EventCreationRepositoryProtocol? = nil,
        storageService:
            EventImageStorageServiceProtocol? = nil,
        geocodingService:
            GeocodingServiceProtocol? = nil
    ) {

        self.authService =
            authService
            ?? FirebaseAuthService()

        self.repository =
            repository
            ?? FirebaseEventCreationRepository()

        self.storageService =
            storageService
            ?? FirebaseEventImageStorageService()

        self.geocodingService =
            geocodingService
            ?? AppleGeocodingService()
    }

    // MARK: - Création

    func createEvent(
        imageData: Data?
    ) async -> Bool {

        errorMessage = nil
        successMessage = nil

        let cleanTitle =
            title.trimmingCharacters(
                in: .whitespacesAndNewlines
            )

        let cleanDescription =
            description
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let cleanLocation =
            location
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        let cleanCategory =
            category
                .trimmingCharacters(
                    in: .whitespacesAndNewlines
                )

        guard
            !cleanTitle.isEmpty
        else {

            errorMessage =
                "Veuillez saisir un titre."

            return false
        }

        guard
            !cleanLocation.isEmpty
        else {

            errorMessage =
                "Veuillez saisir une adresse."

            return false
        }

        guard
            !cleanCategory.isEmpty
        else {

            errorMessage =
                "Veuillez saisir une catégorie."

            return false
        }

        guard
            let user =
                authService.currentUser
        else {

            errorMessage =
                "Utilisateur non connecté."

            return false
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            let coordinate =
                try await geocodingService
                    .coordinate(
                        for: cleanLocation
                    )

            let eventId =
                repository
                    .makeEventID()

            var imageURL: String?

            if let imageData {

                imageURL =
                    try await storageService
                        .uploadEventImage(
                            data: imageData,
                            userId: user.uid,
                            eventId: eventId
                        )
            }

            let record =
                EventCreationRecord(

                    title:
                        cleanTitle,

                    titleLowercase:
                        normalize(
                            cleanTitle
                        ),

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
                        makeSearchKeywords(
                            title:
                                cleanTitle,
                            description:
                                cleanDescription,
                            location:
                                cleanLocation,
                            category:
                                cleanCategory
                        ),

                    imageURL:
                        imageURL
                )

            try await repository
                .createEvent(
                    id: eventId,
                    record: record
                )

            successMessage =
                "L'événement a bien été créé."

            resetForm()

            return true

        } catch {

            print(
                "[Event creation]",
                error.localizedDescription
            )

            errorMessage =
                message(
                    for: error
                )

            return false
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
        .joined(separator: " ")

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

    // MARK: - Réinitialisation

    private func resetForm() {

        title = ""
        description = ""
        date = Date()
        location = ""
        category = ""
    }

    // MARK: - Erreurs

    private func message(
        for error: Error
    ) -> String {

        guard
            let creationError =
                error as? EventCreationError
        else {

            return
                "Impossible de créer l'événement."
        }

        switch creationError {

        case .invalidAddress,
             .addressNotFound:

            return
                "L'adresse indiquée est introuvable. Vérifiez-la puis réessayez."
        }
    }
}

enum EventCreationError:
    Error {

    case invalidAddress
    case addressNotFound
}
