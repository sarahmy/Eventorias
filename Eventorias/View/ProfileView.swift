//
//  ProfileView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//


import SwiftUI
import PhotosUI
import UIKit

@MainActor
struct ProfileView: View {

    @ObservedObject var loginViewModel:
        LoginViewModel

    @StateObject private var viewModel:
        ProfileViewModel

    @State private var selectedPhoto:
        PhotosPickerItem?

    @State private var selectedImage:
        UIImage?

    @State private var showCamera =
        false

    @State private var showCameraError =
        false

    @State private var showLogoutConfirmation =
        false

    @State private var showSuccess =
        false

    @State private var showError =
        false

    @State private var displayedErrorMessage =
        ""

    @State private var isEditing =
        false

    // MARK: - Init

    init(
        loginViewModel: LoginViewModel,
        viewModel: ProfileViewModel? = nil
    ) {

        self.loginViewModel =
            loginViewModel

        _viewModel =
            StateObject(
                wrappedValue:
                    viewModel
                    ?? ProfileViewModel()
            )
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack {

                backgroundColor
                    .ignoresSafeArea()

                ScrollView {

                    VStack(
                        spacing: 26
                    ) {

                        avatarSection

                        identitySection

                        notificationSection

                        actionSection

                        logoutButton
                    }
                    .padding(
                        .horizontal,
                        20
                    )
                    .padding(
                        .top,
                        24
                    )
                    .padding(
                        .bottom,
                        40
                    )
                }

                if viewModel.isLoading {

                    loadingOverlay
                }
            }
            .navigationTitle(
                "Profil"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbarBackground(
                backgroundColor,
                for:
                    .navigationBar
            )
            .toolbarBackground(
                .visible,
                for:
                    .navigationBar
            )
            .toolbarColorScheme(
                .dark,
                for:
                    .navigationBar
            )
            .task {

                await viewModel
                    .loadProfile()
            }
            .task(
                id:
                    viewModel.errorMessage
            ) {

                guard
                    let message =
                        viewModel.errorMessage,
                    !message.isEmpty
                else {

                    return
                }

                await Task.yield()

                displayedErrorMessage =
                    message

                showError =
                    true
            }
            .onChange(
                of:
                    selectedPhoto
            ) { _, newItem in

                loadPhoto(
                    from:
                        newItem
                )
            }
            .sheet(
                isPresented:
                    $showCamera
            ) {

                CameraPickerView(
                    image:
                        $selectedImage
                )
            }
            .alert(
                "Caméra indisponible",
                isPresented:
                    $showCameraError
            ) {

                Button(
                    "OK",
                    role:
                        .cancel
                ) {}

            } message: {

                Text(
                    "La caméra n'est pas disponible sur cet appareil. Utilisez la galerie ou testez sur un iPhone."
                )
            }
            .confirmationDialog(
                "Se déconnecter ?",
                isPresented:
                    $showLogoutConfirmation,
                titleVisibility:
                    .visible
            ) {

                Button(
                    "Se déconnecter",
                    role:
                        .destructive
                ) {

                    loginViewModel
                        .signOut()
                }

                Button(
                    "Annuler",
                    role:
                        .cancel
                ) {}

            } message: {

                Text(
                    "Vous devrez vous reconnecter pour accéder à votre compte."
                )
            }
            .alert(
                "Erreur",
                isPresented:
                    $showError
            ) {

                Button(
                    "OK",
                    role:
                        .cancel
                ) {

                    showError =
                        false

                    displayedErrorMessage =
                        ""

                    viewModel.errorMessage =
                        nil
                }

            } message: {

                Text(
                    displayedErrorMessage
                )
            }
            .alert(
                "Profil enregistré",
                isPresented:
                    $showSuccess
            ) {

                Button(
                    "OK",
                    role:
                        .cancel
                ) {}

            } message: {

                Text(
                    viewModel.successMessage
                    ?? "Les modifications ont été enregistrées."
                )
            }
        }
    }

    // MARK: - Background

    private var backgroundColor:
        Color {

        Color(
            red: 0.08,
            green: 0.07,
            blue: 0.09
        )
    }

    // MARK: - Avatar

    private var avatarSection:
        some View {

        VStack(
            spacing: 14
        ) {

            avatar

            if isEditing {

                HStack(
                    spacing: 12
                ) {

                    PhotosPicker(
                        selection:
                            $selectedPhoto,
                        matching:
                            .images
                    ) {

                        Label(
                            "Galerie",
                            systemImage:
                                "photo.on.rectangle"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .buttonStyle(
                        .bordered
                    )
                    .tint(
                        .white
                    )
                    .accessibilityIdentifier(
                        "profile.gallery"
                    )

                    Button {

                        if cameraIsAvailable {

                            showCamera =
                                true

                        } else {

                            showCameraError =
                                true
                        }

                    } label: {

                        Label(
                            "Caméra",
                            systemImage:
                                "camera"
                        )
                        .frame(
                            maxWidth:
                                .infinity
                        )
                    }
                    .buttonStyle(
                        .bordered
                    )
                    .tint(
                        .white
                    )
                    .accessibilityLabel(
                        "Caméra"
                    )
                    .accessibilityIdentifier(
                        "profile.camera"
                    )
                }
            }
        }
    }

    // MARK: - Avatar Image

    @ViewBuilder
    private var avatar:
        some View {

        if let selectedImage {

            Image(
                uiImage:
                    selectedImage
            )
            .resizable()
            .scaledToFill()
            .frame(
                width: 120,
                height: 120
            )
            .clipShape(
                Circle()
            )
            .overlay {

                Circle()
                    .stroke(
                        Color.red,
                        lineWidth: 3
                    )
            }

        } else if
            let avatarURL =
                viewModel.avatarURL,
            let url =
                URL(
                    string:
                        avatarURL
                ) {

            AsyncImage(
                url:
                    url
            ) { phase in

                switch phase {

                case .empty:

                    avatarPlaceholder
                        .overlay {

                            ProgressView()
                                .tint(
                                    .white
                                )
                        }

                case .success(
                    let image
                ):

                    image
                        .resizable()
                        .scaledToFill()

                case .failure:

                    avatarPlaceholder

                @unknown default:

                    avatarPlaceholder
                }
            }
            .frame(
                width: 120,
                height: 120
            )
            .clipShape(
                Circle()
            )
            .overlay {

                Circle()
                    .stroke(
                        Color.red,
                        lineWidth: 3
                    )
            }

        } else {

            avatarPlaceholder
        }
    }

    private var avatarPlaceholder:
        some View {

        ZStack {

            Circle()
                .fill(
                    Color.white
                        .opacity(
                            0.12
                        )
                )

            Image(
                systemName:
                    "person.fill"
            )
            .font(
                .system(
                    size: 48
                )
            )
            .foregroundStyle(
                .white.opacity(
                    0.7
                )
            )
        }
        .frame(
            width: 120,
            height: 120
        )
        .overlay {

            Circle()
                .stroke(
                    Color.red,
                    lineWidth: 3
                )
        }
    }

    // MARK: - Camera

    private var cameraIsAvailable:
        Bool {

#if DEBUG

        if UITestConfiguration
            .isEnabled {

            return false
        }

#endif

        return UIImagePickerController
            .isSourceTypeAvailable(
                .camera
            )
    }

    // MARK: - Identity

    private var identitySection:
        some View {

        VStack(
            alignment:
                .leading,
            spacing: 16
        ) {

            sectionTitle(
                "Informations personnelles"
            )

            VStack(
                alignment:
                    .leading,
                spacing: 7
            ) {

                Text(
                    "Nom"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .white.opacity(
                        0.6
                    )
                )

                if isEditing {

                    TextField(
                        "Votre nom",
                        text:
                            $viewModel.name
                    )
                    .textInputAutocapitalization(
                        .words
                    )
                    .padding()
                    .foregroundStyle(
                        .white
                    )
                    .background(
                        Color.white
                            .opacity(
                                0.12
                            )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                10
                        )
                    )
                    .accessibilityIdentifier(
                        "profile.name"
                    )

                } else {

                    HStack {

                        Image(
                            systemName:
                                "person"
                        )
                        .foregroundStyle(
                            .white.opacity(
                                0.6
                            )
                        )

                        Text(
                            viewModel.name.isEmpty
                            ? "Nom non renseigné"
                            : viewModel.name
                        )
                        .foregroundStyle(
                            .white
                        )

                        Spacer()
                    }
                    .padding()
                    .background(
                        Color.white
                            .opacity(
                                0.08
                            )
                    )
                    .clipShape(
                        RoundedRectangle(
                            cornerRadius:
                                10
                        )
                    )
                }
            }

            VStack(
                alignment:
                    .leading,
                spacing: 7
            ) {

                Text(
                    "E-mail"
                )
                .font(
                    .caption
                )
                .foregroundStyle(
                    .white.opacity(
                        0.6
                    )
                )

                HStack {

                    Image(
                        systemName:
                            "envelope"
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.6
                        )
                    )

                    Text(
                        viewModel.email.isEmpty
                        ? "Adresse e-mail"
                        : viewModel.email
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.8
                        )
                    )

                    Spacer()

                    Image(
                        systemName:
                            "lock.fill"
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.4
                        )
                    )
                }
                .padding()
                .background(
                    Color.white
                        .opacity(
                            0.08
                        )
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius:
                            10
                    )
                )
            }
        }
    }

    // MARK: - Notifications

    private var notificationSection:
        some View {

        VStack(
            alignment:
                .leading,
            spacing: 14
        ) {

            sectionTitle(
                "Préférences"
            )

            HStack(
                spacing: 14
            ) {

                Image(
                    systemName:
                        "bell.fill"
                )
                .foregroundStyle(
                    .red
                )
                .frame(
                    width: 24
                )

                VStack(
                    alignment:
                        .leading,
                    spacing: 3
                ) {

                    Text(
                        "Notifications"
                    )
                    .foregroundStyle(
                        .white
                    )

                    Text(
                        "Rappels des événements à venir et mises à jour importantes."
                    )
                    .font(
                        .caption
                    )
                    .foregroundStyle(
                        .white.opacity(
                            0.55
                        )
                    )
                }

                Spacer()

                Toggle(
                    "",
                    isOn:
                        $viewModel
                            .notificationsEnabled
                )
                .labelsHidden()
                .tint(
                    .red
                )
                .disabled(
                    !isEditing
                )
                .accessibilityIdentifier(
                    "profile.notifications"
                )
            }
            .padding(
                16
            )
            .background(
                Color.white
                    .opacity(
                        0.10
                    )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        12
                )
            )
        }
    }

    // MARK: - Actions

    @ViewBuilder
    private var actionSection:
        some View {

        if isEditing {

            VStack(
                spacing: 12
            ) {

                saveButton

                cancelEditButton
            }

        } else {

            editButton
        }
    }

    // MARK: Edit

    private var editButton:
        some View {

        Button {

            isEditing =
                true

        } label: {

            Label(
                "Modifier le profil",
                systemImage:
                    "pencil"
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                .white
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .frame(
                height: 52
            )
            .background(
                Color.red
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        8
                )
            )
        }
        .accessibilityIdentifier(
            "profile.edit"
        )
    }

    // MARK: Save

    private var saveButton:
        some View {

        Button {

            Task {

                let imageData =
                    selectedImage?
                        .jpegData(
                            compressionQuality:
                                0.8
                        )

                let success =
                    await viewModel
                        .saveProfile(
                            imageData:
                                imageData
                        )

                guard success else {

                    return
                }

                let notificationsAccepted =
                    await applyNotificationPreference()

                if
                    viewModel
                        .notificationsEnabled,
                    !notificationsAccepted {

                    viewModel
                        .notificationsEnabled =
                        false

                    _ =
                        await viewModel
                            .saveProfile(
                                imageData:
                                    nil
                            )
                }

                selectedImage =
                    nil

                selectedPhoto =
                    nil

                isEditing =
                    false

                showSuccess =
                    true
            }

        } label: {

            Text(
                "Enregistrer les modifications"
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                .white
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .frame(
                height: 52
            )
            .background(
                Color.red
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        8
                )
            )
        }
        .disabled(
            viewModel.isLoading
        )
        .accessibilityIdentifier(
            "profile.save"
        )
    }

    // MARK: Cancel Edit

    private var cancelEditButton:
        some View {

        Button {

            selectedImage =
                nil

            selectedPhoto =
                nil

            isEditing =
                false

            Task {

                await viewModel
                    .loadProfile()
            }

        } label: {

            Text(
                "Annuler les modifications"
            )
            .fontWeight(
                .medium
            )
            .foregroundStyle(
                .white
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .frame(
                height: 48
            )
            .background(
                Color.white
                    .opacity(
                        0.10
                    )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        8
                )
            )
        }
        .accessibilityIdentifier(
            "profile.cancelEdit"
        )
    }

    // MARK: Logout

    private var logoutButton:
        some View {

        Button {

            showLogoutConfirmation =
                true

        } label: {

            Label(
                "Se déconnecter",
                systemImage:
                    "rectangle.portrait.and.arrow.right"
            )
            .fontWeight(
                .medium
            )
            .foregroundStyle(
                .red
            )
            .frame(
                maxWidth:
                    .infinity
            )
            .frame(
                height: 50
            )
            .background(
                Color.red
                    .opacity(
                        0.12
                    )
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius:
                        8
                )
            )
        }
        .accessibilityIdentifier(
            "profile.logout"
        )
    }

    // MARK: - Notification Preference

    private func applyNotificationPreference()
        async -> Bool {

#if DEBUG

        // Aucun popup système pendant XCTest.
        if UITestConfiguration
            .isEnabled {

            return true
        }

#endif

        return await
            NotificationManager
                .shared
                .updateNotifications(
                    enabled:
                        viewModel
                            .notificationsEnabled
                )
    }

    // MARK: - Photo

    private func loadPhoto(
        from item:
            PhotosPickerItem?
    ) {

        guard let item else {

            return
        }

        Task {

            guard
                let data =
                    try? await item
                        .loadTransferable(
                            type:
                                Data.self
                        ),
                let image =
                    UIImage(
                        data:
                            data
                    )
            else {

                return
            }

            selectedImage =
                image
        }
    }

    // MARK: - Loading

    private var loadingOverlay:
        some View {

        ZStack {

            Color.black
                .opacity(
                    0.45
                )
                .ignoresSafeArea()

            VStack(
                spacing: 12
            ) {

                ProgressView()
                    .tint(
                        .white
                    )
                    .scaleEffect(
                        1.2
                    )

                Text(
                    "Chargement..."
                )
                .foregroundStyle(
                    .white
                )
            }
        }
    }

    // MARK: - Helpers

    private func sectionTitle(
        _ title: String
    ) -> some View {

        Text(
            title
        )
        .font(
            .headline
        )
        .foregroundStyle(
            .white
        )
    }
}

#Preview {

    ProfileView(
        loginViewModel:
            LoginViewModel()
    )
}
