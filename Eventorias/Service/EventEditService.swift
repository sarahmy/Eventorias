//
//  EventEditService.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 09/10/2026.
//

import Foundation
import FirebaseFirestore

// MARK: - Données de modification

struct EventUpdateRecord {

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

// MARK: - Repository

@MainActor
protocol EventEditRepositoryProtocol {

    func updateEvent(
        id: String,
        record: EventUpdateRecord
    ) async throws
}

// MARK: - Firebase

@MainActor
final class FirebaseEventEditRepository:
    EventEditRepositoryProtocol {

    private let database: Firestore

    init(
        database: Firestore? = nil
    ) {

        self.database =
            database
            ?? Firestore.firestore()
    }

    func updateEvent(
        id: String,
        record: EventUpdateRecord
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

            "updatedAt":
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
            .updateData(data)
    }
}
