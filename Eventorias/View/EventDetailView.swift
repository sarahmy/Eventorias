//
//  EventDetailView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 07/10/2026.
//



import SwiftUI

@MainActor
struct EventDetailView: View {

    @StateObject private var viewModel:
        EventDetailViewModel

    @Environment(\.dismiss)
    private var dismiss

    @State private var showEditView =
        false

    @State private var showDeleteConfirmation =
        false

    @State private var showErrorAlert =
        false

    @State private var displayedErrorMessage =
        ""

    private let onEventChanged:
        () -> Void

    init(
        event: EventModel,
        onEventChanged:
            @escaping () -> Void = {}
    ) {

        _viewModel =
            StateObject(
                wrappedValue:
                    EventDetailViewModel(
                        event: event
                    )
            )

        self.onEventChanged =
            onEventChanged
    }

    init(
        viewModel:
            EventDetailViewModel,
        onEventChanged:
            @escaping () -> Void = {}
    ) {

        _viewModel =
            StateObject(
                wrappedValue:
                    viewModel
            )

        self.onEventChanged =
            onEventChanged
    }

    var body: some View {

        ZStack {

            backgroundColor
                .ignoresSafeArea()

            ScrollView {

                VStack(
                    alignment: .leading,
                    spacing: 22
                ) {

                    eventPhoto

                    eventInformation

                    descriptionSection

                    locationSection

                    mapSection
                }
                .padding(
                    .horizontal,
                    16
                )
                .padding(
                    .top,
                    10
                )
                .padding(
                    .bottom,
                    30
                )
            }

            if viewModel.isDeleting {

                Color.black
                    .opacity(0.5)
                    .ignoresSafeArea()

                VStack(spacing: 12) {

                    ProgressView()
                        .tint(.white)

                    Text(
                        "Suppression..."
                    )
                    .foregroundStyle(
                        .white
                    )
                }
                .accessibilityIdentifier(
                    "detail.deleting"
                )
            }
        }
        .navigationTitle(
            viewModel.event.title
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
        .toolbar(
            .hidden,
            for: .tabBar
        )
        .toolbar {

            if viewModel.isOwner {

                ToolbarItem(
                    placement:
                        .topBarTrailing
                ) {

                    Menu {

                        Button {

                            showEditView =
                                true

                        } label: {

                            Label(
                                "Modifier",
                                systemImage:
                                    "pencil"
                            )
                        }

                        Button(
                            role:
                                .destructive
                        ) {

                            showDeleteConfirmation =
                                true

                        } label: {

                            Label(
                                "Supprimer",
                                systemImage:
                                    "trash"
                            )
                        }

                    } label: {

                        Image(
                            systemName:
                                "ellipsis.circle"
                        )
                        .foregroundStyle(
                            .white
                        )
                    }
                    .accessibilityLabel(
                        "Options de l'événement"
                    )
                    .accessibilityIdentifier(
                        "detail.options"
                    )
                }
            }
        }
        .sheet(
            isPresented:
                $showEditView
        ) {

            EventEditView(
                event:
                    viewModel.event
            ) { updatedEvent in

                viewModel
                    .applyUpdatedEvent(
                        updatedEvent
                    )

                onEventChanged()
            }
        }
        .confirmationDialog(
            "Supprimer cet événement ?",
            isPresented:
                $showDeleteConfirmation,
            titleVisibility:
                .visible
        ) {

            Button(
                "Supprimer définitivement",
                role:
                    .destructive
            ) {

                Task {

                    let success =
                        await viewModel
                            .deleteEvent()

                    if success {

                        onEventChanged()

                        dismiss()

                    } else {

                        displayedErrorMessage =
                            viewModel.errorMessage
                            ?? "Impossible de supprimer l'événement."

                        showErrorAlert =
                            true
                    }
                }
            }

            Button(
                "Annuler",
                role:
                    .cancel
            ) {}

        } message: {

            Text(
                "Cette action est définitive et ne peut pas être annulée."
            )
        }
        .alert(
            "Erreur",
            isPresented:
                $showErrorAlert
        ) {

            Button(
                "OK",
                role:
                    .cancel
            ) {

                viewModel.errorMessage =
                    nil
            }

        } message: {

            Text(
                displayedErrorMessage
            )
        }
        .accessibilityIdentifier(
            "detail.screen"
        )
    }

    private var backgroundColor:
        Color {

        Color(
            red: 0.08,
            green: 0.07,
            blue: 0.09
        )
    }

    // MARK: - Photo

    private var eventPhoto:
        some View {

        Group {

            if
                let imageURL =
                    viewModel
                        .eventImageURL {

                AsyncImage(
                    url: imageURL
                ) { phase in

                    switch phase {

                    case .empty:

                        ZStack {

                            photoPlaceholder

                            ProgressView()
                                .tint(.white)
                        }

                    case .success(
                        let image
                    ):

                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:

                        photoPlaceholder

                    @unknown default:

                        photoPlaceholder
                    }
                }

            } else {

                photoPlaceholder
            }
        }
        .frame(
            maxWidth:
                .infinity
        )
        .frame(
            height: 250
        )
        .clipped()
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
        .accessibilityIdentifier(
            "detail.photo"
        )
    }

    private var photoPlaceholder:
        some View {

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
                        size: 42
                    )
                )

                Text(
                    "Photo indisponible"
                )
                .font(.caption)
            }
            .foregroundStyle(
                .white.opacity(0.7)
            )
        }
    }

    // MARK: - Informations

    private var eventInformation:
        some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            informationRow(
                icon:
                    "calendar",
                text:
                    viewModel
                        .formattedDate
            )

            informationRow(
                icon:
                    "clock",
                text:
                    viewModel
                        .formattedTime
            )

            informationRow(
                icon:
                    "tag.fill",
                text:
                    viewModel
                        .formattedCategory
            )
        }
        .accessibilityIdentifier(
            "detail.info"
        )
    }

    private func informationRow(
        icon: String,
        text: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName:
                    icon
            )
            .foregroundStyle(
                .red
            )
            .frame(width: 22)

            Text(text)
                .foregroundStyle(
                    .white
                )

            Spacer()
        }
    }

    // MARK: - Description

    private var descriptionSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            sectionTitle(
                "Description"
            )

            Text(
                viewModel.event
                    .description
                    .isEmpty
                ? "Aucune description disponible."
                : viewModel.event
                    .description
            )
            .foregroundStyle(
                .white.opacity(0.8)
            )
        }
        .accessibilityIdentifier(
            "detail.description"
        )
    }

    // MARK: - Lieu

    private var locationSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            sectionTitle(
                "Lieu"
            )

            HStack(
                alignment: .top,
                spacing: 10
            ) {

                Image(
                    systemName:
                        "mappin.and.ellipse"
                )
                .foregroundStyle(
                    .red
                )

                Text(
                    viewModel
                        .event
                        .location
                )
                .foregroundStyle(
                    .white.opacity(0.8)
                )
            }
        }
        .accessibilityIdentifier(
            "detail.location"
        )
    }

    // MARK: - Carte

    private var mapSection:
        some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            sectionTitle(
                "Carte"
            )

            if
                let mapURL =
                    viewModel
                        .staticMapURL {

                AsyncImage(
                    url: mapURL
                ) { phase in

                    switch phase {

                    case .empty:

                        mapPlaceholder
                            .overlay {

                                ProgressView()
                                    .tint(.white)
                            }

                    case .success(
                        let image
                    ):

                        image
                            .resizable()
                            .scaledToFill()

                    case .failure:

                        mapErrorView

                    @unknown default:

                        mapErrorView
                    }
                }
                .frame(
                    maxWidth:
                        .infinity
                )
                .frame(
                    height: 190
                )
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )

            } else {

                mapErrorView
            }
        }
        .accessibilityIdentifier(
            "detail.map"
        )
    }

    private var mapPlaceholder:
        some View {

        ZStack {

            Color.white
                .opacity(0.10)

            Image(
                systemName:
                    "map"
            )
            .font(
                .system(
                    size: 40
                )
            )
            .foregroundStyle(
                .white.opacity(0.6)
            )
        }
    }

    private var mapErrorView:
        some View {

        VStack(spacing: 10) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .font(
                .system(
                    size: 28
                )
            )

            Text(
                "Impossible d'afficher la carte."
            )
        }
        .foregroundStyle(
            .white.opacity(0.7)
        )
        .frame(
            maxWidth:
                .infinity
        )
        .frame(
            height: 190
        )
        .background(
            Color.white
                .opacity(0.10)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }

    private func sectionTitle(
        _ value: String
    ) -> some View {

        Text(value)
            .font(.headline)
            .foregroundStyle(
                .white
            )
    }
}
