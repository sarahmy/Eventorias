//
//  EventCreationServices.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 09/10/2026.
//


import Foundation
import FirebaseFirestore
import FirebaseStorage
import MapKit

// MARK: - Données à enregistrer

struct EventCreationRecord {

    let title: String
    let titleLowercase: String
    let description: String
    let date: Date
    let location: String
    let category: String
    let ownerId: String
    let latitude: Double
    let longitude: Double
    let searchKeywords: [String]
    let imageURL: String?
}

// MARK: - Firestore

@MainActor
protocol EventCreationRepositoryProtocol {

    func makeEventID() -> String

    func createEvent(
        id: String,
        record: EventCreationRecord
    ) async throws
}

@MainActor
final class FirebaseEventCreationRepository:
    EventCreationRepositoryProtocol {

    private let database: Firestore

    init(
        database: Firestore? = nil
    ) {

        self.database =
            database
            ?? Firestore.firestore()
    }

    func makeEventID() -> String {

        database
            .collection("events")
            .document()
            .documentID
    }

    func createEvent(
        id: String,
        record: EventCreationRecord
    ) async throws {

        var data: [String: Any] = [

            "title":
                record.title,

            "titleLowercase":
                record.titleLowercase,

            "description":
                record.description,

            "date":
                Timestamp(
                    date: record.date
                ),

            "location":
                record.location,

            "category":
                record.category,

            "ownerId":
                record.ownerId,

            "latitude":
                record.latitude,

            "longitude":
                record.longitude,

            "searchKeywords":
                record.searchKeywords,

            "createdAt":
                FieldValue.serverTimestamp()
        ]

        if let imageURL =
            record.imageURL {

            data["imageURL"] =
                imageURL
        }

        try await database
            .collection("events")
            .document(id)
            .setData(data)
    }
}

// MARK: - Firebase Storage

@MainActor
protocol EventImageStorageServiceProtocol {

    func uploadEventImage(
        data: Data,
        userId: String,
        eventId: String
    ) async throws -> String
}

@MainActor
final class FirebaseEventImageStorageService:
    EventImageStorageServiceProtocol {

    private let storage: Storage

    init(
        storage: Storage? = nil
    ) {

        self.storage =
            storage
            ?? Storage.storage()
    }

    func uploadEventImage(
        data: Data,
        userId: String,
        eventId: String
    ) async throws -> String {

        let reference =
            storage
                .reference()
                .child(
                    "eventImages/\(userId)/\(eventId).jpg"
                )

        let metadata =
            StorageMetadata()

        metadata.contentType =
            "image/jpeg"

        // La méthode renvoie des métadonnées.
        // On indique explicitement que nous
        // n'avons pas besoin de cette valeur.
        _ = try await reference
            .putDataAsync(
                data,
                metadata: metadata
            )

        let url =
            try await reference
                .downloadURL()

        return url.absoluteString
    }
}

// MARK: - Géocodage

struct GeocodedCoordinate:
    Equatable {

    let latitude: Double
    let longitude: Double
}

@MainActor
protocol GeocodingServiceProtocol {

    func coordinate(
        for address: String
    ) async throws
        -> GeocodedCoordinate
}

@MainActor
final class AppleGeocodingService:
    GeocodingServiceProtocol {

    func coordinate(
        for address: String
    ) async throws
        -> GeocodedCoordinate {

        guard
            let request =
                MKGeocodingRequest(
                    addressString:
                        address
                )
        else {

            throw EventCreationError
                .invalidAddress
        }

        let items =
            try await request.mapItems

        guard
            let coordinate =
                items.first?
                    .location
                    .coordinate
        else {

            throw EventCreationError
                .addressNotFound
        }

        return GeocodedCoordinate(
            latitude:
                coordinate.latitude,
            longitude:
                coordinate.longitude
        )
    }
}
