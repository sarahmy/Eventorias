//
//  UITestSupport.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//



#if DEBUG

import SwiftUI
import Foundation

// ============================================================
// MARK: - Configuration UI Tests
// ============================================================

enum UITestConfiguration {

    static var isEnabled:
        Bool {

        ProcessInfo
            .processInfo
            .arguments
            .contains(
                "-uiTesting"
            )
    }

    static var scenario:
        String {

        let arguments =
            ProcessInfo
                .processInfo
                .arguments

        guard
            let index =
                arguments
                    .firstIndex(
                        of:
                            "-uiTestScenario"
                    ),
            arguments
                .indices
                .contains(
                    index + 1
                )
        else {

            return "main"
        }

        return arguments[
            index + 1
        ]
    }
}

// ============================================================
// MARK: - Root
// ============================================================

@MainActor
struct UITestRootView:
    View {

    var body: some View {

        switch
            UITestConfiguration
                .scenario {

        case "login":

            UITestLoginContainer()

        case "main":

            UITestMainContainer()

        case "list-empty":

            UITestEventListContainer(
                mode:
                    .empty
            )

        case "list-error":

            UITestEventListContainer(
                mode:
                    .error
            )

        case "creation":

            EventCreationView()

        case "detail-owner":

            NavigationStack {

                UITestDetailContainer(
                    isOwner:
                        true
                )
            }

        case "detail-guest":

            NavigationStack {

                UITestDetailContainer(
                    isOwner:
                        false
                )
            }

        case "detail-delete-error":

            NavigationStack {

                UITestDetailContainer(
                    isOwner:
                        true,
                    deleteFails:
                        true
                )
            }

        case "edit":

            EventEditView(
                event:
                    UITestFixtures
                        .primaryEvent
            ) { _ in }

        case "profile-error":

            UITestProfileErrorContainer()

        default:

            UITestMainContainer()
        }
    }
}

// ============================================================
// MARK: - Login
// ============================================================

@MainActor
private struct UITestLoginContainer:
    View {

    @StateObject private var viewModel:
        LoginViewModel

    init() {

        let service =
            UITestAuthService(
                currentUser:
                    nil
            )

        _viewModel =
            StateObject(
                wrappedValue:
                    LoginViewModel(
                        authService:
                            service
                    )
            )
    }

    var body: some View {

        LoginView(
            viewModel:
                viewModel
        )
    }
}

// ============================================================
// MARK: - Main
// ============================================================

@MainActor
private struct UITestMainContainer:
    View {

    @StateObject private var loginViewModel:
        LoginViewModel

    @StateObject private var listViewModel:
        EventListViewModel

    @StateObject private var profileViewModel:
        ProfileViewModel

    init() {

        let user =
            UITestFixtures.user

        let auth =
            UITestAuthService(
                currentUser:
                    user
            )

        _loginViewModel =
            StateObject(
                wrappedValue:
                    LoginViewModel(
                        authService:
                            auth
                    )
            )

        _listViewModel =
            StateObject(
                wrappedValue:
                    EventListViewModel(
                        repository:
                            UITestEventListRepository(
                                events:
                                    UITestFixtures
                                        .events
                            ),
                        searchDelay:
                            .milliseconds(1)
                    )
            )

        _profileViewModel =
            StateObject(
                wrappedValue:
                    ProfileViewModel(
                        authService:
                            auth,
                        repository:
                            UITestProfileRepository(),
                        avatarStorage:
                            UITestAvatarStorage()
                    )
            )
    }

    var body: some View {

        MainTabView(
            loginViewModel:
                loginViewModel,
            eventListViewModel:
                listViewModel,
            profileViewModel:
                profileViewModel
        )
    }
}

// ============================================================
// MARK: - Event List
// ============================================================

private enum UITestEventListMode {

    case empty
    case error
}

@MainActor
private struct UITestEventListContainer:
    View {

    @StateObject private var viewModel:
        EventListViewModel

    init(
        mode:
            UITestEventListMode
    ) {

        switch mode {

        case .empty:

            _viewModel =
                StateObject(
                    wrappedValue:
                        EventListViewModel(
                            repository:
                                UITestEventListRepository(
                                    events:
                                        []
                                ),
                            searchDelay:
                                .milliseconds(1)
                        )
                )

        case .error:

            _viewModel =
                StateObject(
                    wrappedValue:
                        EventListViewModel(
                            repository:
                                UITestFailingEventListRepository(),
                            searchDelay:
                                .milliseconds(1)
                        )
                )
        }
    }

    var body: some View {

        EventListView(
            viewModel:
                viewModel
        )
    }
}

// ============================================================
// MARK: - Detail
// ============================================================

@MainActor
private struct UITestDetailContainer:
    View {

    @StateObject private var viewModel:
        EventDetailViewModel

    init(
        isOwner: Bool,
        deleteFails: Bool = false
    ) {

        let auth =
            UITestAuthService(
                currentUser:
                    isOwner
                    ? UITestFixtures
                        .user
                    : AuthenticatedUser(
                        uid:
                            "guest-user",
                        email:
                            "guest@test.com",
                        displayName:
                            "Guest"
                    )
            )

        let detailViewModel =
            EventDetailViewModel(
                event:
                    UITestFixtures
                        .primaryEvent,
                authService:
                    auth,
                repository:
                    UITestDetailRepository(
                        shouldFail:
                            deleteFails
                    ),
                imageDeletionService:
                    UITestImageDeletionService(),
                apiKeyProvider:
                    UITestAPIKeyProvider(
                        key: nil
                    )
            )

        _viewModel =
            StateObject(
                wrappedValue:
                    detailViewModel
            )
    }

    var body: some View {

        EventDetailView(
            viewModel:
                viewModel
        )
    }
}

// ============================================================
// MARK: - Profile Error
// ============================================================

@MainActor
private struct UITestProfileErrorContainer:
    View {

    @StateObject private var loginViewModel:
        LoginViewModel

    @StateObject private var profileViewModel:
        ProfileViewModel

    init() {

        let auth =
            UITestAuthService(
                currentUser:
                    UITestFixtures.user
            )

        _loginViewModel =
            StateObject(
                wrappedValue:
                    LoginViewModel(
                        authService:
                            auth
                    )
            )

        _profileViewModel =
            StateObject(
                wrappedValue:
                    ProfileViewModel(
                        authService:
                            auth,
                        repository:
                            UITestFailingProfileRepository(),
                        avatarStorage:
                            UITestAvatarStorage()
                    )
            )
    }

    var body: some View {

        ProfileView(
            loginViewModel:
                loginViewModel,
            viewModel:
                profileViewModel
        )
    }
}

// ============================================================
// MARK: - Fixtures
// ============================================================

enum UITestFixtures {

    static let user =
        AuthenticatedUser(
            uid:
                "ui-owner",
            email:
                "sarah@test.com",
            displayName:
                "Sarah"
        )

    static var primaryEvent:
        EventModel {

        EventModel(
            id:
                "ui-music",
            title:
                "Music Festival",
            titleLowercase:
                "music festival",
            description:
                "Festival de musique à Paris.",
            date:
                Date()
                    .addingTimeInterval(
                        86_400
                    ),
            location:
                "Paris, France",
            category:
                "music",
            ownerId:
                user.uid,
            imageURL:
                nil
        )
    }

    static var events:
        [EventModel] {

        let base =
            Date()
                .addingTimeInterval(
                    86_400
                )

        return [

            makeEvent(
                id:
                    "ui-music",
                title:
                    "Music Festival",
                category:
                    "music",
                location:
                    "Paris, France",
                date:
                    base
            ),

            makeEvent(
                id:
                    "ui-art",
                title:
                    "Art Exhibition",
                category:
                    "art",
                location:
                    "Nantes, France",
                date:
                    base
                        .addingTimeInterval(
                            86_400
                        )
            ),

            makeEvent(
                id:
                    "ui-tech",
                title:
                    "Tech Conference",
                category:
                    "tech",
                location:
                    "La Défense, Paris",
                date:
                    base
                        .addingTimeInterval(
                            172_800
                        )
            ),

            makeEvent(
                id:
                    "ui-food",
                title:
                    "Food Market",
                category:
                    "food",
                location:
                    "Lyon, France",
                date:
                    base
                        .addingTimeInterval(
                            259_200
                        )
            ),

            makeEvent(
                id:
                    "ui-film",
                title:
                    "Cinema Night",
                category:
                    "cinema",
                location:
                    "Bordeaux, France",
                date:
                    base
                        .addingTimeInterval(
                            345_600
                        )
            ),

            makeEvent(
                id:
                    "ui-sport",
                title:
                    "City Run",
                category:
                    "sport",
                location:
                    "Nice, France",
                date:
                    base
                        .addingTimeInterval(
                            432_000
                        )
            ),

            makeEvent(
                id:
                    "ui-other",
                title:
                    "Community Meetup",
                category:
                    "other",
                location:
                    "Lille, France",
                date:
                    base
                        .addingTimeInterval(
                            518_400
                        )
            )
        ]
    }

    private static func makeEvent(
        id: String,
        title: String,
        category: String,
        location: String,
        date: Date
    ) -> EventModel {

        EventModel(
            id:
                id,
            title:
                title,
            titleLowercase:
                title.lowercased(),
            description:
                "Description de \(title).",
            date:
                date,
            location:
                location,
            category:
                category,
            ownerId:
                user.uid,
            imageURL:
                nil
        )
    }
}

// ============================================================
// MARK: - Fake Auth
// ============================================================

@MainActor
final class UITestAuthService:
    AuthServiceProtocol {

    var currentUser:
        AuthenticatedUser?

    init(
        currentUser:
            AuthenticatedUser?
    ) {

        self.currentUser =
            currentUser
    }

    func signIn(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        guard
            !email.isEmpty,
            !password.isEmpty
        else {

            throw UITestSupportError
                .expected
        }

        let user =
            AuthenticatedUser(
                uid:
                    "ui-owner",
                email:
                    email,
                displayName:
                    "Sarah"
            )

        currentUser =
            user

        return user
    }

    func createUser(
        email: String,
        password: String
    ) async throws
        -> AuthenticatedUser {

        try await signIn(
            email:
                email,
            password:
                password
        )
    }

    func signOut() throws {

        currentUser =
            nil
    }
}

// ============================================================
// MARK: - Fake Event List
// ============================================================

@MainActor
final class UITestEventListRepository:
    EventListRepositoryProtocol {

    private let events:
        [EventModel]

    init(
        events:
            [EventModel]
    ) {

        self.events =
            events
    }

    func fetchEvents(
        searchTerms:
            [String]
    ) async throws
        -> [EventModel] {

        guard
            !searchTerms.isEmpty
        else {

            return events
        }

        return events.filter {
            event in

            let haystack =
                [
                    event.title,
                    event.description,
                    event.location,
                    event.category
                ]
                .joined(
                    separator:
                        " "
                )
                .folding(
                    options: [
                        .diacriticInsensitive,
                        .caseInsensitive
                    ],
                    locale:
                        .current
                )
                .lowercased()

            return searchTerms
                .contains {

                    haystack
                        .contains($0)
                }
        }
    }
}

@MainActor
final class UITestFailingEventListRepository:
    EventListRepositoryProtocol {

    func fetchEvents(
        searchTerms:
            [String]
    ) async throws
        -> [EventModel] {

        throw UITestSupportError
            .expected
    }
}

// ============================================================
// MARK: - Fake Profile
// ============================================================

@MainActor
final class UITestProfileRepository:
    ProfileRepositoryProtocol {

    private var stored =
        StoredProfileData(
            name:
                "Sarah Maimoun",
            email:
                "sarah@test.com",
            avatarURL:
                nil,
            notificationsEnabled:
                false
        )

    func loadProfile(
        userId: String
    ) async throws
        -> StoredProfileData? {

        stored
    }

    func createInitialProfile(
        userId: String,
        name: String,
        email: String
    ) async throws {

        stored =
            StoredProfileData(
                name:
                    name,
                email:
                    email,
                avatarURL:
                    nil,
                notificationsEnabled:
                    false
            )
    }

    func saveProfile(
        userId: String,
        record:
            ProfileSaveRecord
    ) async throws {

        stored =
            StoredProfileData(
                name:
                    record.name,
                email:
                    record.email,
                avatarURL:
                    record.avatarURL,
                notificationsEnabled:
                    record
                        .notificationsEnabled
            )
    }
}

@MainActor
final class UITestFailingProfileRepository:
    ProfileRepositoryProtocol {

    func loadProfile(
        userId: String
    ) async throws
        -> StoredProfileData? {

        throw UITestSupportError
            .expected
    }

    func createInitialProfile(
        userId: String,
        name: String,
        email: String
    ) async throws {

        throw UITestSupportError
            .expected
    }

    func saveProfile(
        userId: String,
        record:
            ProfileSaveRecord
    ) async throws {

        throw UITestSupportError
            .expected
    }
}

@MainActor
final class UITestAvatarStorage:
    ProfileAvatarStorageServiceProtocol {

    func uploadAvatar(
        data: Data,
        userId: String
    ) async throws
        -> String {

        "https://example.com/ui-avatar.jpg"
    }
}

// ============================================================
// MARK: - Fake Detail
// ============================================================

@MainActor
final class UITestDetailRepository:
    EventDetailRepositoryProtocol {

    private let shouldFail:
        Bool

    init(
        shouldFail: Bool = false
    ) {

        self.shouldFail =
            shouldFail
    }

    func deleteEvent(
        id: String
    ) async throws {

        if shouldFail {

            throw UITestSupportError
                .expected
        }
    }
}

@MainActor
final class UITestImageDeletionService:
    EventImageDeletionServiceProtocol {

    func deleteImage(
        url: String
    ) async throws {}
}

struct UITestAPIKeyProvider:
    GoogleMapsAPIKeyProviderProtocol {

    let key:
        String?

    var googleMapsAPIKey:
        String? {

        key
    }
}

enum UITestSupportError:
    Error {

    case expected
}

#endif
