//
//  CoreFeatureServices.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 09/10/2026.



import Foundation
import FirebaseFirestore
import FirebaseStorage

// MARK: - Liste des événements

@MainActor
protocol EventListRepositoryProtocol {

    func fetchEvents(
        searchTerms: [String]
    ) async throws -> [EventModel]
}

@MainActor
final class FirebaseEventListRepository:
    EventListRepositoryProtocol {

    private let database: Firestore

    init(
        database: Firestore? = nil
    ) {

        self.database =
            database
            ?? Firestore.firestore()
    }

    func fetchEvents(
        searchTerms: [String]
    ) async throws -> [EventModel] {

        let snapshot: QuerySnapshot

        if searchTerms.isEmpty {

            snapshot =
                try await database
                    .collection("events")
                    .getDocuments()

        } else {

            snapshot =
                try await database
                    .collection("events")
                    .whereField(
                        "searchKeywords",
                        arrayContainsAny:
                            Array(
                                searchTerms
                                    .prefix(30)
                            )
                    )
                    .getDocuments()
        }

        var events:
            [EventModel] = []

        for document
        in snapshot.documents {

            let data =
                document.data()

            guard
                let title =
                    data["title"]
                    as? String,
                let timestamp =
                    data["date"]
                    as? Timestamp,
                let location =
                    data["location"]
                    as? String,
                let category =
                    data["category"]
                    as? String,
                let ownerId =
                    data["ownerId"]
                    as? String
            else {

                print(
                    "[Firestore] Document invalide :",
                    document.documentID
                )

                continue
            }

            let description =
                data["description"]
                as? String
                ?? ""

            let titleLowercase =
                data["titleLowercase"]
                as? String
                ?? title.lowercased()

            let imageURL =
                data["imageURL"]
                as? String

            events.append(
                EventModel(
                    id:
                        document.documentID,
                    title:
                        title,
                    titleLowercase:
                        titleLowercase,
                    description:
                        description,
                    date:
                        timestamp
                            .dateValue(),
                    location:
                        location,
                    category:
                        category,
                    ownerId:
                        ownerId,
                    imageURL:
                        imageURL
                )
            )
        }

        return events
    }
}

// MARK: - Profil

struct StoredProfileData {

    let name: String?
    let email: String?
    let avatarURL: String?
    let notificationsEnabled: Bool?
}

struct ProfileSaveRecord {

    let name: String
    let email: String
    let avatarURL: String?
    let notificationsEnabled: Bool
}

@MainActor
protocol ProfileRepositoryProtocol {

    func loadProfile(
        userId: String
    ) async throws
        -> StoredProfileData?

    func createInitialProfile(
        userId: String,
        name: String,
        email: String
    ) async throws

    func saveProfile(
        userId: String,
        record:
            ProfileSaveRecord
    ) async throws
}

@MainActor
final class FirebaseProfileRepository:
    ProfileRepositoryProtocol {

    private let database:
        Firestore

    init(
        database: Firestore? = nil
    ) {

        self.database =
            database
            ?? Firestore.firestore()
    }

    func loadProfile(
        userId: String
    ) async throws
        -> StoredProfileData? {

        let snapshot =
            try await database
                .collection("users")
                .document(userId)
                .getDocument()

        guard
            let data =
                snapshot.data()
        else {

            return nil
        }

        return StoredProfileData(
            name:
                data["name"]
                as? String,
            email:
                data["email"]
                as? String,
            avatarURL:
                data["avatarURL"]
                as? String,
            notificationsEnabled:
                data[
                    "notificationsEnabled"
                ] as? Bool
        )
    }

    func createInitialProfile(
        userId: String,
        name: String,
        email: String
    ) async throws {

        try await database
            .collection("users")
            .document(userId)
            .setData(
                [
                    "name":
                        name,

                    "email":
                        email,

                    "notificationsEnabled":
                        false,

                    "createdAt":
                        FieldValue
                            .serverTimestamp(),

                    "updatedAt":
                        FieldValue
                            .serverTimestamp()
                ]
            )
    }

    func saveProfile(
        userId: String,
        record:
            ProfileSaveRecord
    ) async throws {

        var data:
            [String: Any] = [

                "name":
                    record.name,

                "email":
                    record.email,

                "notificationsEnabled":
                    record
                        .notificationsEnabled,

                "updatedAt":
                    FieldValue
                        .serverTimestamp()
            ]

        if let avatarURL =
            record.avatarURL {

            data["avatarURL"] =
                avatarURL
        }

        try await database
            .collection("users")
            .document(userId)
            .setData(
                data,
                merge: true
            )
    }
}

// MARK: - Avatar du profil

@MainActor
protocol ProfileAvatarStorageServiceProtocol {

    func uploadAvatar(
        data: Data,
        userId: String
    ) async throws -> String
}

@MainActor
final class FirebaseProfileAvatarStorageService:
    ProfileAvatarStorageServiceProtocol {

    private let storage:
        Storage

    init(
        storage: Storage? = nil
    ) {

        self.storage =
            storage
            ?? Storage.storage()
    }

    func uploadAvatar(
        data: Data,
        userId: String
    ) async throws -> String {

        let fileName =
            "\(UUID().uuidString).jpg"

        let reference =
            storage
                .reference()
                .child(
                    "profileImages/\(userId)/\(fileName)"
                )

        let metadata =
            StorageMetadata()

        metadata.contentType =
            "image/jpeg"

        // La valeur StorageMetadata retournée
        // n'est volontairement pas utilisée.
        _ = try await reference
            .putDataAsync(
                data,
                metadata:
                    metadata
            )

        let url =
            try await reference
                .downloadURL()

        return url
            .absoluteString
    }
}

// MARK: - Détail / suppression événement

@MainActor
protocol EventDetailRepositoryProtocol {

    func deleteEvent(
        id: String
    ) async throws
}

@MainActor
final class FirebaseEventDetailRepository:
    EventDetailRepositoryProtocol {

    private let database:
        Firestore

    init(
        database: Firestore? = nil
    ) {

        self.database =
            database
            ?? Firestore.firestore()
    }

    func deleteEvent(
        id: String
    ) async throws {

        try await database
            .collection("events")
            .document(id)
            .delete()
    }
}

// MARK: - Suppression image événement

@MainActor
protocol EventImageDeletionServiceProtocol {

    func deleteImage(
        url: String
    ) async throws
}

@MainActor
final class FirebaseEventImageDeletionService:
    EventImageDeletionServiceProtocol {

    private let storage:
        Storage

    init(
        storage: Storage? = nil
    ) {

        self.storage =
            storage
            ?? Storage.storage()
    }

    func deleteImage(
        url: String
    ) async throws {

        try await storage
            .reference(
                forURL: url
            )
            .delete()
    }
}

// MARK: - Google Maps

protocol GoogleMapsAPIKeyProviderProtocol {

    var googleMapsAPIKey:
        String? {
            get
        }
}

struct BundleGoogleMapsAPIKeyProvider:
    GoogleMapsAPIKeyProviderProtocol {

    var googleMapsAPIKey:
        String? {

        Bundle.main
            .object(
                forInfoDictionaryKey:
                    "GOOGLE_MAPS_API_KEY"
            )
            as? String
    }
}
