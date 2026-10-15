//
//  EventEditView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 08/10/2026.
//


import SwiftUI
import PhotosUI
import UIKit

@MainActor
struct EventEditView: View {

    @StateObject private var viewModel:
        EventEditViewModel

    @Environment(\.dismiss)
    private var dismiss

    @State private var selectedPhoto:
        PhotosPickerItem?

    @State private var selectedImage:
        UIImage?

    @State private var showCamera =
        false

    @State private var showCameraError =
        false

    @State private var showSuccess =
        false

    @State private var showErrorAlert =
        false

    @State private var displayedErrorMessage =
        ""

    private let onUpdated:
        (EventModel) -> Void

    init(
        event: EventModel,
        onUpdated:
            @escaping (EventModel) -> Void
    ) {

        _viewModel =
            StateObject(
                wrappedValue:
                    EventEditViewModel(
                        event: event
                    )
            )

        self.onUpdated =
            onUpdated
    }

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

                        fieldTitle(
                            "Titre"
                        )

                        standardTextField(
                            placeholder:
                                "Nom de l'événement",
                            text:
                                $viewModel.title,
                            identifier:
                                "edit.title"
                        )

                        fieldTitle(
                            "Description"
                        )

                        descriptionField

                        dateSection

                        fieldTitle(
                            "Adresse"
                        )

                        standardTextField(
                            placeholder:
                                "Adresse complète",
                            text:
                                $viewModel.location,
                            identifier:
                                "edit.location"
                        )

                        fieldTitle(
                            "Catégorie"
                        )

                        standardTextField(
                            placeholder:
                                "Catégorie",
                            text:
                                $viewModel.category,
                            identifier:
                                "edit.category"
                        )

                        saveButton
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
                "Modifier l'événement"
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
                        "edit.cancel"
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
                "Événement modifié",
                isPresented:
                    $showSuccess
            ) {

                Button("OK") {

                    dismiss()
                }

            } message: {

                Text(
                    "Les modifications ont bien été enregistrées."
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

            eventImage

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
                    "edit.gallery"
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
                .tint(.white)
                .accessibilityLabel(
                    "Caméra"
                )
                .accessibilityIdentifier(
                    "edit.camera"
                )
            }
        }
    }

    @ViewBuilder
    private var eventImage:
        some View {

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

        } else if
            let value =
                viewModel.existingImageURL,
            let url =
                URL(
                    string:
                        value
                ) {

            AsyncImage(
                url: url
            ) { phase in

                switch phase {

                case .empty:

                    imagePlaceholder
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

                    imagePlaceholder

                @unknown default:

                    imagePlaceholder
                }
            }
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

            imagePlaceholder
        }
    }

    private var imagePlaceholder:
        some View {

        ZStack {

            Color.white
                .opacity(0.10)

            VStack(spacing: 8) {

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
                    "Aucune photo"
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

    // MARK: - Date

    private var dateSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            fieldTitle(
                "Date et heure"
            )

            HStack(spacing: 12) {

                pickerContainer {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Label(
                            "Date",
                            systemImage:
                                "calendar"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.65)
                        )

                        DatePicker(
                            "Date",
                            selection:
                                $viewModel.date,
                            displayedComponents:
                                .date
                        )
                        .labelsHidden()
                        .datePickerStyle(
                            .compact
                        )
                        .colorScheme(
                            .dark
                        )
                        .tint(.red)
                        .accessibilityIdentifier(
                            "edit.date"
                        )
                    }
                }

                pickerContainer {

                    VStack(
                        alignment: .leading,
                        spacing: 6
                    ) {

                        Label(
                            "Heure",
                            systemImage:
                                "clock"
                        )
                        .font(.caption)
                        .foregroundStyle(
                            .white.opacity(0.65)
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
                        .colorScheme(
                            .dark
                        )
                        .tint(.red)
                        .accessibilityIdentifier(
                            "edit.time"
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
                    .opacity(0.12)
            )
            .clipShape(
                RoundedRectangle(
                    cornerRadius: 10
                )
            )
    }

    // MARK: - Fields

    private func fieldTitle(
        _ value: String
    ) -> some View {

        Text(value)
            .font(
                .subheadline
            )
            .fontWeight(
                .semibold
            )
            .foregroundStyle(
                .white
            )
    }

    private func standardTextField(
        placeholder: String,
        text: Binding<String>,
        identifier: String
    ) -> some View {

        TextField(
            placeholder,
            text: text
        )
        .padding()
        .foregroundStyle(
            .white
        )
        .background(
            Color.white
                .opacity(0.12)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
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
                .opacity(0.12)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 10
            )
        )
        .accessibilityIdentifier(
            "edit.description"
        )
    }

    // MARK: - Save

    private var saveButton:
        some View {

        Button {

            Task {

                let data =
                    selectedImage?
                        .jpegData(
                            compressionQuality:
                                0.8
                        )

                let updatedEvent =
                    await viewModel
                        .updateEvent(
                            imageData:
                                data
                        )

                guard
                    let updatedEvent
                else {

                    displayedErrorMessage =
                        viewModel.errorMessage
                        ?? "Impossible de modifier l'événement."

                    showErrorAlert =
                        true

                    return
                }

                onUpdated(
                    updatedEvent
                )

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
                    cornerRadius: 8
                )
            )
        }
        .disabled(
            viewModel.isLoading
        )
        .accessibilityIdentifier(
            "edit.save"
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

            VStack(spacing: 12) {

                ProgressView()
                    .tint(.white)

                Text(
                    "Enregistrement..."
                )
                .foregroundStyle(
                    .white
                )
            }
        }
    }
}
