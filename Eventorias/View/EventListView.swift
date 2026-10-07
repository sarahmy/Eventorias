//
//  SwiftUIView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import SwiftUI

struct EventListView: View {

    @StateObject private var viewModel =
        EventListViewModel()

    @State private var showCreationAlert =
        false

    var body: some View {

        NavigationStack {

            ZStack(
                alignment: .bottomTrailing
            ) {

                Color(
                    red: 0.08,
                    green: 0.07,
                    blue: 0.09
                )
                .ignoresSafeArea()

                VStack(spacing: 12) {

                    searchBar

                    sortBar

                    content
                }
                .padding(
                    .horizontal,
                    14
                )
                .padding(
                    .top,
                    10
                )

                createButton
            }
            .task {

                await viewModel
                    .loadEvents()
            }
            .alert(
                "Création d'événement",
                isPresented:
                    $showCreationAlert
            ) {

                Button(
                    "OK",
                    role: .cancel
                ) {}

            } message: {

                Text(
                    "La création d'événement sera implémentée dans une prochaine étape."
                )
            }
        }
    }

    // MARK: - Recherche

    private var searchBar: some View {

        HStack(spacing: 10) {

            Image(
                systemName:
                    "magnifyingglass"
            )
            .foregroundStyle(
                .white.opacity(0.7)
            )

            TextField(
                "Search",
                text:
                    $viewModel.searchText
            )
            .textInputAutocapitalization(
                .never
            )
            .autocorrectionDisabled()
            .foregroundStyle(.white)
            .onChange(
                of:
                    viewModel.searchText
            ) { _, _ in

                viewModel
                    .searchTextDidChange()
            }
        }
        .padding(
            .horizontal,
            14
        )
        .frame(height: 42)
        .background(
            Color.white.opacity(0.18)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
        .accessibilityLabel(
            "Rechercher un événement"
        )
    }

    // MARK: - Tri

    private var sortBar: some View {

        HStack {

            Menu {

                Button {

                    viewModel
                        .selectSortOption(
                            .dateAscending
                        )

                } label: {

                    Label(
                        "Date : plus proche",
                        systemImage:
                            viewModel.selectedSortOption
                                == .dateAscending
                            ? "checkmark"
                            : "calendar"
                    )
                }

                Button {

                    viewModel
                        .selectSortOption(
                            .dateDescending
                        )

                } label: {

                    Label(
                        "Date : plus lointaine",
                        systemImage:
                            viewModel.selectedSortOption
                                == .dateDescending
                            ? "checkmark"
                            : "calendar"
                    )
                }

                Divider()

                Button {

                    viewModel
                        .selectSortOption(
                            .titleAscending
                        )

                } label: {

                    Label(
                        "Titre : A → Z",
                        systemImage:
                            viewModel.selectedSortOption
                                == .titleAscending
                            ? "checkmark"
                            : "textformat"
                    )
                }

                Button {

                    viewModel
                        .selectSortOption(
                            .titleDescending
                        )

                } label: {

                    Label(
                        "Titre : Z → A",
                        systemImage:
                            viewModel.selectedSortOption
                                == .titleDescending
                            ? "checkmark"
                            : "textformat"
                    )
                }

            } label: {

                HStack(spacing: 6) {

                    Image(
                        systemName:
                            "arrow.up.arrow.down"
                    )

                    Text("Trier")
                        .font(.caption)
                        .fontWeight(
                            .medium
                        )

                    Image(
                        systemName:
                            "chevron.down"
                    )
                    .font(.caption2)
                }
                .foregroundStyle(
                    .white
                )
                .padding(
                    .horizontal,
                    12
                )
                .padding(
                    .vertical,
                    7
                )
                .background(
                    Color.white
                        .opacity(0.18)
                )
                .clipShape(
                    Capsule()
                )
            }
            .accessibilityLabel(
                "Trier les événements"
            )

            Spacer()

            Text(
                "\(viewModel.events.count) événement(s)"
            )
            .font(.caption)
            .foregroundStyle(
                .white.opacity(0.6)
            )
        }
    }

    // MARK: - Contenu

    @ViewBuilder
    private var content: some View {

        if viewModel.isLoading {

            Spacer()

            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
                .accessibilityLabel(
                    "Chargement des événements"
                )

            Spacer()

        } else if let errorMessage =
                    viewModel.errorMessage {

            Spacer()

            VStack(spacing: 16) {

                Image(
                    systemName:
                        "exclamationmark.circle.fill"
                )
                .font(
                    .system(size: 45)
                )
                .foregroundStyle(
                    .white.opacity(0.7)
                )

                Text("Erreur")
                    .font(.headline)
                    .foregroundStyle(
                        .white
                    )

                Text(errorMessage)
                    .font(.subheadline)
                    .foregroundStyle(
                        .white.opacity(0.7)
                    )
                    .multilineTextAlignment(
                        .center
                    )

                Button("Réessayer") {

                    Task {

                        await viewModel
                            .loadEvents()
                    }
                }
                .foregroundStyle(.white)
                .padding(
                    .horizontal,
                    24
                )
                .padding(
                    .vertical,
                    10
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

            Spacer()

        } else if
            viewModel.events.isEmpty {

            Spacer()

            VStack(spacing: 12) {

                Image(
                    systemName:
                        "calendar"
                )
                .font(
                    .system(size: 44)
                )
                .foregroundStyle(
                    .white.opacity(0.6)
                )

                Text(
                    viewModel.searchText
                        .isEmpty
                    ? "Aucun événement"
                    : "Aucun résultat"
                )
                .foregroundStyle(
                    .white
                )
                .font(.headline)
            }

            Spacer()

        } else {

            ScrollView {

                LazyVStack(
                    spacing: 10
                ) {

                    ForEach(
                        viewModel.events
                    ) { event in

                        NavigationLink {

                            EventDetailView(
                                event: event
                            )

                        } label: {

                            EventRowView(
                                event: event
                            )
                        }
                        .buttonStyle(.plain)
                        .accessibilityHint(
                            "Ouvre le détail de l'événement"
                        )
                    }
                }
                .padding(
                    .bottom,
                    90
                )
            }
            .refreshable {

                await viewModel
                    .loadEvents()
            }
        }
    }

    // MARK: - Création

    private var createButton: some View {

        Button {

            showCreationAlert = true

        } label: {

            Image(
                systemName: "plus"
            )
            .font(
                .system(
                    size: 20,
                    weight: .bold
                )
            )
            .foregroundStyle(.white)
            .frame(
                width: 52,
                height: 52
            )
            .background(
                Color.red
            )
            .clipShape(
                Circle()
            )
            .shadow(
                radius: 5
            )
        }
        .padding(
            .trailing,
            20
        )
        .padding(
            .bottom,
            15
        )
        .accessibilityLabel(
            "Créer un événement"
        )
    }
}

#Preview {
    EventListView()
}
