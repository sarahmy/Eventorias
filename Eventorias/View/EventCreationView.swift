//
//  EventCreationView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 08/10/2026.
//



import SwiftUI
import PhotosUI
import UIKit

@MainActor
struct EventCreationView: View {

    @StateObject private var viewModel =
        EventCreationViewModel()

    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedPhoto:
        PhotosPickerItem?

    @State private var selectedImage:
        UIImage?

    @State private var showCamera = false
    @State private var showCameraError = false
    @State private var showSuccess = false

    // L'alerte d'erreur est désormais
    // entièrement pilotée par la vue.
    @State private var showErrorAlert = false
    @State private var displayedErrorMessage = ""

    var body: some View {

        NavigationStack {

            ZStack {

                backgroundColor
                    .ignoresSafeArea()

                ScrollView {

                    VStack(
                        alignment: .leading,
                        spacing: 18
                    ) {

                        imageSection

                        formFieldTitle(
                            "Titre"
                        )

                        textField(
                            placeholder:
                                "Nom de l'événement",
                            text:
                                $viewModel.title,
                            identifier:
                                "creation.title"
                        )

                        formFieldTitle(
                            "Description"
                        )

                        descriptionField

                        dateAndTimeSection

                        formFieldTitle(
                            "Adresse"
                        )

                        textField(
                            placeholder:
                                "Adresse complète",
                            text:
                                $viewModel.location,
                            identifier:
                                "creation.location"
                        )

                        formFieldTitle(
                            "Catégorie"
                        )

                        textField(
                            placeholder:
                                "Ex. musique, art, technologie...",
                            text:
                                $viewModel.category,
                            identifier:
                                "creation.category"
                        )

                        createButton
                            .padding(
                                .top,
                                10
                            )
                    }
                    .padding(20)
                }

                if viewModel.isLoading {

                    loadingOverlay
                }
            }
            .navigationTitle(
                "Création d'un événement"
            )
            .navigationBarTitleDisplayMode(
                .inline
            )
            .toolbarBackground(
                backgroundColor,
                for: .navigationBar
            )
            .toolbarBackground(
                .visible,
                for: .navigationBar
            )
            .toolbarColorScheme(
                .dark,
                for: .navigationBar
            )
            .toolbar {

                ToolbarItem(
                    placement:
                        .topBarLeading
                ) {

                    Button("Annuler") {

                        dismiss()
                    }
                    .foregroundStyle(
                        .white
                    )
                    .accessibilityIdentifier(
                        "creation.cancel"
                    )
                }
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
            .onChange(
                of: selectedPhoto
            ) { _, newItem in

                loadPhoto(
                    from: newItem
                )
            }
            .alert(
                "Caméra indisponible",
                isPresented:
                    $showCameraError
            ) {

                Button(
                    "OK",
                    role: .cancel
                ) {}

            } message: {

                Text(
                    "La caméra n'est pas disponible sur cet appareil. Utilisez la galerie ou testez sur un iPhone."
                )
            }
            .alert(
                "Erreur",
                isPresented:
                    $showErrorAlert
            ) {

                Button(
                    "OK",
                    role: .cancel
                ) {}

            } message: {

                Text(
                    displayedErrorMessage
                )
            }
            .alert(
                "Événement créé",
                isPresented:
                    $showSuccess
            ) {

                Button("OK") {

                    dismiss()
                }

            } message: {

                Text(
                    "L'événement a bien été enregistré."
                )
            }
        }
    }

    private var backgroundColor:
        Color {

        Color(
            red: 0.08,
            green: 0.07,
            blue: 0.09
        )
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

    // MARK: - Image

    private var imageSection:
        some View {

        VStack(spacing: 14) {

            if let selectedImage {

                Image(
                    uiImage:
                        selectedImage
                )
                .resizable()
                .scaledToFill()
                .frame(height: 220)
                .frame(
                    maxWidth:
                        .infinity
                )
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )

            } else {

                ZStack {

                    Color.white
                        .opacity(0.10)

                    VStack(spacing: 10) {

                        Image(
                            systemName:
                                "photo"
                        )
                        .font(
                            .system(
                                size: 40
                            )
                        )

                        Text(
                            "Ajouter une photo"
                        )
                        .font(
                            .subheadline
                        )
                    }
                    .foregroundStyle(
                        .white.opacity(0.7)
                    )
                }
                .frame(height: 220)
                .frame(
                    maxWidth:
                        .infinity
                )
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
            }

            HStack(spacing: 12) {

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
                .tint(.white)
                .accessibilityIdentifier(
                    "creation.gallery"
                )

                Button {

                    if cameraIsAvailable {

                        showCamera = true

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
                .tint(.white)
                .accessibilityLabel(
                    "Caméra"
                )
                .accessibilityIdentifier(
                    "creation.camera"
                )
            }
        }
    }

    // MARK: - Date et heure

    private var dateAndTimeSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            formFieldTitle(
                "Date et heure"
            )

            HStack(spacing: 12) {

                pickerContainer {

                    VStack(
                        alignment: .leading,
                        spacing: 7
                    ) {

                        Label(
                            "Date",
                            systemImage:
                                "calendar"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.7)
                        )

                        DatePicker(
                            "Date",
                            selection:
                                $viewModel.date,
                            in:
                                Date()...,
                            displayedComponents:
                                .date
                        )
                        .labelsHidden()
                        .datePickerStyle(
                            .compact
                        )
                        .tint(.red)
                        .colorScheme(.dark)
                        .accessibilityIdentifier(
                            "creation.date"
                        )
                    }
                }

                pickerContainer {

                    VStack(
                        alignment: .leading,
                        spacing: 7
                    ) {

                        Label(
                            "Heure",
                            systemImage:
                                "clock"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.7)
                        )

                        DatePicker(
                            "Heure",
                            selection:
                                $viewModel.date,
                            displayedComponents:
                                .hourAndMinute
                        )
                        .labelsHidden()
                        .datePickerStyle(
                            .compact
                        )
                        .tint(.red)
                        .colorScheme(.dark)
                        .accessibilityIdentifier(
                            "creation.time"
                        )
                    }
                }
            }
        }
    }

    private func pickerContainer<
        Content: View
    >(
        @ViewBuilder
        content:
            () -> Content
    ) -> some View {

        content()
            .padding(12)
            .frame(
                maxWidth:
                    .infinity
            )
            .background(
                Color.white
                    .opacity(0.15)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 8
                )
            )
    }

    // MARK: - Fields

    private func formFieldTitle(
        _ title: String
    ) -> some View {

        Text(title)
            .font(.subheadline)
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                .white
            )
    }

    private func textField(
        placeholder: String,
        text: Binding<String>,
        identifier: String
    ) -> some View {

        TextField(
            placeholder,
            text: text
        )
        .textInputAutocapitalization(
            .sentences
        )
        .padding()
        .foregroundStyle(
            .white
        )
        .background(
            Color.white
                .opacity(0.15)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
        .accessibilityIdentifier(
            identifier
        )
    }

    private var descriptionField:
        some View {

        TextEditor(
            text:
                $viewModel.description
        )
        .frame(
            minHeight: 110
        )
        .padding(8)
        .scrollContentBackground(
            .hidden
        )
        .foregroundStyle(
            .white
        )
        .background(
            Color.white
                .opacity(0.15)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 8
            )
        )
        .overlay(
            alignment:
                .topLeading
        ) {

            if viewModel
                .description
                .isEmpty {

                Text(
                    "Décrivez votre événement"
                )
                .foregroundStyle(
                    .white.opacity(0.5)
                )
                .padding(
                    .horizontal,
                    13
                )
                .padding(
                    .vertical,
                    17
                )
                .allowsHitTesting(
                    false
                )
            }
        }
        .accessibilityIdentifier(
            "creation.description"
        )
    }

    // MARK: - Submit

    private var createButton:
        some View {

        Button {

            Task {

                let data =
                    selectedImage?
                        .jpegData(
                            compressionQuality:
                                0.8
                        )

                let success =
                    await viewModel
                        .createEvent(
                            imageData:
                                data
                        )

                if success {

                    showSuccess =
                        true

                } else {

                    displayedErrorMessage =
                        viewModel.errorMessage
                        ?? "Impossible de créer l'événement."

                    showErrorAlert =
                        true
                }
            }

        } label: {

            Text("Valider")
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
                        cornerRadius: 6
                    )
                )
        }
        .disabled(
            viewModel.isLoading
        )
        .accessibilityIdentifier(
            "creation.submit"
        )
    }

    // MARK: - Gallery

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
                        data: data
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
                .opacity(0.5)
                .ignoresSafeArea()

            VStack(spacing: 14) {

                ProgressView()
                    .tint(.white)
                    .scaleEffect(1.2)

                Text(
                    "Création en cours..."
                )
                .foregroundStyle(
                    .white
                )
            }
        }
    }
}
