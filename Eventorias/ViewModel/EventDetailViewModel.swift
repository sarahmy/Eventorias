//
//  EventDetailViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 07/10/2026.
//


import Foundation
import Combine

@MainActor
final class EventDetailViewModel:
    ObservableObject {

    @Published private(set)
    var event:
        EventModel

    @Published var isDeleting =
        false

    @Published var errorMessage:
        String?

    private let authService:
        AuthServiceProtocol

    private let repository:
        EventDetailRepositoryProtocol

    private let imageDeletionService:
        EventImageDeletionServiceProtocol

    private let apiKeyProvider:
        GoogleMapsAPIKeyProviderProtocol

    // MARK: - Init

    init(
        event: EventModel,
        authService:
            AuthServiceProtocol? = nil,
        repository:
            EventDetailRepositoryProtocol? = nil,
        imageDeletionService:
            EventImageDeletionServiceProtocol? = nil,
        apiKeyProvider:
            GoogleMapsAPIKeyProviderProtocol? = nil
    ) {

        self.event =
            event

        self.authService =
            authService
            ?? FirebaseAuthService()

        self.repository =
            repository
            ?? FirebaseEventDetailRepository()

        self.imageDeletionService =
            imageDeletionService
            ?? FirebaseEventImageDeletionService()

        self.apiKeyProvider =
            apiKeyProvider
            ?? BundleGoogleMapsAPIKeyProvider()
    }

    // MARK: - Propriétaire

    var isOwner: Bool {

        guard
            let currentUserID =
                authService
                    .currentUser?
                    .uid
        else {
            return false
        }

        return
            currentUserID ==
            event.ownerId
    }

    // MARK: - Mise à jour locale

    func applyUpdatedEvent(
        _ updatedEvent:
            EventModel
    ) {

        event =
            updatedEvent
    }

    // MARK: - Suppression

    func deleteEvent()
        async -> Bool {

        errorMessage = nil

        guard isOwner else {

            errorMessage =
                "Vous n'êtes pas autorisé à supprimer cet événement."

            return false
        }

        isDeleting = true

        defer {
            isDeleting = false
        }

        do {

            try await repository
                .deleteEvent(
                    id:
                        event.id
                )

            await deleteImageIfNeeded()

            return true

        } catch {

            print(
                "[Event deletion]",
                error.localizedDescription
            )

            errorMessage =
                "Impossible de supprimer l'événement."

            return false
        }
    }

    // MARK: - Nettoyage image

    private func deleteImageIfNeeded()
        async {

        guard
            let imageURL =
                event.imageURL,
            isFirebaseStorageURL(
                imageURL
            )
        else {
            return
        }

        do {

            try await imageDeletionService
                .deleteImage(
                    url:
                        imageURL
                )

        } catch {

            // L'événement est déjà supprimé
            // de Firestore.
            // Une erreur Storage ne doit donc
            // pas annuler la suppression.

            print(
                "[Storage cleanup]",
                error.localizedDescription
            )
        }
    }

    private func isFirebaseStorageURL(
        _ value: String
    ) -> Bool {

        value.hasPrefix(
            "gs://"
        )
        ||
        value.contains(
            "firebasestorage.googleapis.com"
        )
        ||
        value.contains(
            "storage.googleapis.com"
        )
    }

    // MARK: - Image événement

    var eventImageURL:
        URL? {

        guard
            let value =
                event.imageURL
        else {
            return nil
        }

        let cleanValue =
            value.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard
            !cleanValue.isEmpty
        else {
            return nil
        }

        return URL(
            string:
                cleanValue
        )
    }

    // MARK: - Google Maps

    private var googleMapsAPIKey:
        String? {

        guard
            let rawKey =
                apiKeyProvider
                    .googleMapsAPIKey
        else {
            return nil
        }

        let cleanKey =
            rawKey.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard
            !cleanKey.isEmpty,
            !cleanKey.contains("$(")
        else {
            return nil
        }

        return cleanKey
    }

    var staticMapURL:
        URL? {

        guard
            let apiKey =
                googleMapsAPIKey
        else {
            return nil
        }

        var components =
            URLComponents(
                string:
                    "https://maps.googleapis.com/maps/api/staticmap"
            )

        components?.queryItems = [

            URLQueryItem(
                name:
                    "center",
                value:
                    event.location
            ),

            URLQueryItem(
                name:
                    "zoom",
                value:
                    "14"
            ),

            URLQueryItem(
                name:
                    "size",
                value:
                    "640x320"
            ),

            URLQueryItem(
                name:
                    "scale",
                value:
                    "2"
            ),

            URLQueryItem(
                name:
                    "maptype",
                value:
                    "roadmap"
            ),

            URLQueryItem(
                name:
                    "markers",
                value:
                    "color:red|\(event.location)"
            ),

            URLQueryItem(
                name:
                    "key",
                value:
                    apiKey
            )
        ]

        return components?.url
    }

    // MARK: - Formatage

    var formattedDate:
        String {

        event.date.formatted(
            date:
                .long,
            time:
                .omitted
        )
    }

    var formattedTime:
        String {

        event.date.formatted(
            date:
                .omitted,
            time:
                .shortened
        )
    }

    var formattedCategory:
        String {

        event.category
            .capitalized
    }
}
