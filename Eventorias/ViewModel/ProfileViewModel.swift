//
//  ProfileViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 08/10/2026.
//

import Foundation
import Combine

@MainActor
final class ProfileViewModel:
    ObservableObject {

    @Published var name = ""
    @Published var email = ""
    @Published var avatarURL: String?

    @Published var notificationsEnabled =
        false

    @Published var isLoading =
        false

    @Published var errorMessage:
        String?

    @Published var successMessage:
        String?

    @Published private(set)
    var profile:
        UserProfileModel?

    private let authService:
        AuthServiceProtocol

    private let repository:
        ProfileRepositoryProtocol

    private let avatarStorage:
        ProfileAvatarStorageServiceProtocol

    // MARK: - Initialisation

    init(
        authService:
            AuthServiceProtocol? = nil,
        repository:
            ProfileRepositoryProtocol? = nil,
        avatarStorage:
            ProfileAvatarStorageServiceProtocol? = nil
    ) {

        self.authService =
            authService
            ?? FirebaseAuthService()

        self.repository =
            repository
            ?? FirebaseProfileRepository()

        self.avatarStorage =
            avatarStorage
            ?? FirebaseProfileAvatarStorageService()
    }

    // MARK: - Chargement

    func loadProfile() async {

        errorMessage = nil
        successMessage = nil

        guard
            let user =
                authService.currentUser
        else {

            errorMessage =
                "Aucun utilisateur connecté."

            return
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            if let storedProfile =
                try await repository
                    .loadProfile(
                        userId:
                            user.uid
                    ) {

                let loadedName =
                    storedProfile.name
                    ?? user.displayName
                    ?? ""

                let loadedEmail =
                    storedProfile.email
                    ?? user.email
                    ?? ""

                let loadedNotifications =
                    storedProfile
                        .notificationsEnabled
                    ?? false

                let loadedProfile =
                    UserProfileModel(
                        id:
                            user.uid,
                        name:
                            loadedName,
                        email:
                            loadedEmail,
                        avatarURL:
                            storedProfile
                                .avatarURL,
                        notificationsEnabled:
                            loadedNotifications
                    )

                applyProfile(
                    loadedProfile
                )

            } else {

                let initialName =
                    user.displayName
                    ?? ""

                let initialEmail =
                    user.email
                    ?? ""

                try await repository
                    .createInitialProfile(
                        userId:
                            user.uid,
                        name:
                            initialName,
                        email:
                            initialEmail
                    )

                let initialProfile =
                    UserProfileModel(
                        id:
                            user.uid,
                        name:
                            initialName,
                        email:
                            initialEmail,
                        avatarURL:
                            nil,
                        notificationsEnabled:
                            false
                    )

                applyProfile(
                    initialProfile
                )
            }

        } catch {

            print(
                "[Profile] Chargement :",
                error.localizedDescription
            )

            errorMessage =
                "Impossible de charger le profil."
        }
    }

    // MARK: - Enregistrement

    func saveProfile(
        imageData: Data?
    ) async -> Bool {

        errorMessage = nil
        successMessage = nil

        guard
            let user =
                authService.currentUser
        else {

            errorMessage =
                "Aucun utilisateur connecté."

            return false
        }

        let cleanName =
            name.trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )

        guard
            !cleanName.isEmpty
        else {

            errorMessage =
                "Veuillez renseigner votre nom."

            return false
        }

        isLoading = true

        defer {
            isLoading = false
        }

        do {

            var newAvatarURL =
                avatarURL

            if let imageData {

                newAvatarURL =
                    try await avatarStorage
                        .uploadAvatar(
                            data:
                                imageData,
                            userId:
                                user.uid
                        )
            }

            let finalEmail =
                user.email
                ?? email

            let record =
                ProfileSaveRecord(
                    name:
                        cleanName,
                    email:
                        finalEmail,
                    avatarURL:
                        newAvatarURL,
                    notificationsEnabled:
                        notificationsEnabled
                )

            try await repository
                .saveProfile(
                    userId:
                        user.uid,
                    record:
                        record
                )

            let updatedProfile =
                UserProfileModel(
                    id:
                        user.uid,
                    name:
                        cleanName,
                    email:
                        finalEmail,
                    avatarURL:
                        newAvatarURL,
                    notificationsEnabled:
                        notificationsEnabled
                )

            applyProfile(
                updatedProfile
            )

            successMessage =
                "Votre profil a bien été enregistré."

            return true

        } catch {

            print(
                "[Profile] Enregistrement :",
                error.localizedDescription
            )

            errorMessage =
                "Impossible d'enregistrer le profil."

            return false
        }
    }

    // MARK: - Application locale

    private func applyProfile(
        _ value: UserProfileModel
    ) {

        profile =
            value

        name =
            value.name

        email =
            value.email

        avatarURL =
            value.avatarURL

        notificationsEnabled =
            value.notificationsEnabled
    }
}
