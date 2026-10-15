//
//  SwiftUIView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//



import SwiftUI

@MainActor
struct EventListView: View {

    // MARK: - ViewModel

    @StateObject private var viewModel:
        EventListViewModel

    // MARK: - States

    @State private var showCreationView =
        false

    // MARK: - Init

    init(
        viewModel:
            EventListViewModel? = nil
    ) {

        _viewModel =
            StateObject(
                wrappedValue:
                    viewModel
                    ?? EventListViewModel()
            )
    }

    // MARK: - Body

    var body: some View {

        NavigationStack {

            ZStack(
                alignment:
                    .bottomTrailing
            ) {

                backgroundColor
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

            // IMPORTANT :
            // On ne fait plus :
            //
            // .task { loadEvents() }
            // +
            // .onChange { searchTextDidChange() }
            //
            // Une seule task dépend maintenant du texte recherché.
            //
            // Elle est automatiquement annulée par SwiftUI
            // lorsqu'une nouvelle lettre est tapée.
            //
            // Le premier yield évite également de publier
            // des @Published pendant le cycle de rendu SwiftUI.

            .task(
                id:
                    viewModel.searchText
            ) {

                await Task.yield()

                guard
                    !Task.isCancelled
                else {
                    return
                }

                // Debounce uniquement lorsqu'une recherche
                // est réellement en cours.
                if !viewModel
                    .searchText
                    .trimmingCharacters(
                        in:
                            .whitespacesAndNewlines
                    )
                    .isEmpty {

                    try? await Task.sleep(
                        for:
                            .milliseconds(300)
                    )

                    guard
                        !Task.isCancelled
                    else {
                        return
                    }
                }

                await viewModel
                    .loadEvents()
            }

            .sheet(
                isPresented:
                    $showCreationView,
                onDismiss: {

                    // Le Task est volontairement différé
                    // d'un tour de run loop pour ne pas publier
                    // pendant la fermeture de la sheet.

                    Task {

                        await Task.yield()

                        guard
                            !Task.isCancelled
                        else {
                            return
                        }

                        await viewModel
                            .loadEvents()
                    }
                }
            ) {

                EventCreationView()
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

    // ============================================================
    // MARK: - SEARCH
    // ============================================================

    private var searchBar:
        some View {

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
            .foregroundStyle(
                .white
            )

            // IMPORTANT :
            // il n'y a volontairement PLUS de
            //
            // .onChange(of: viewModel.searchText)
            //
            // La task(id:) placée sur la vue
            // gère maintenant la recherche.

            .accessibilityLabel(
                "Rechercher"
            )
            .accessibilityIdentifier(
                "events.search"
            )
        }
        .padding(
            .horizontal,
            14
        )
        .frame(
            height: 42
        )
        .background(
            Color.white
                .opacity(0.18)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }

    // ============================================================
    // MARK: - SORT
    // ============================================================

    private var sortBar:
        some View {

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
                            viewModel
                                .selectedSortOption
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
                            viewModel
                                .selectedSortOption
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
                            viewModel
                                .selectedSortOption
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
                            viewModel
                                .selectedSortOption
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
                    .font(
                        .caption2
                    )
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
                "Trier"
            )
            .accessibilityIdentifier(
                "events.sort"
            )

            Spacer()

            Text(
                "\(viewModel.events.count) événement(s)"
            )
            .font(.caption)
            .foregroundStyle(
                .white.opacity(0.6)
            )
            .accessibilityIdentifier(
                "events.count"
            )
        }
    }

    // ============================================================
    // MARK: - CONTENT
    // ============================================================

    @ViewBuilder
    private var content:
        some View {

        if viewModel.isLoading {

            Spacer()

            ProgressView()
                .tint(.white)
                .scaleEffect(1.2)
                .accessibilityLabel(
                    "Chargement des événements"
                )

            Spacer()

        } else if
            let errorMessage =
                viewModel.errorMessage {

            errorContent(
                message:
                    errorMessage
            )

        } else if
            viewModel.events.isEmpty {

            emptyContent

        } else {

            eventsContent
        }
    }

    // ============================================================
    // MARK: - ERROR
    // ============================================================

    private func errorContent(
        message: String
    ) -> some View {

        VStack {

            Spacer()

            VStack(spacing: 16) {

                Image(
                    systemName:
                        "exclamationmark.circle.fill"
                )
                .font(
                    .system(
                        size: 45
                    )
                )
                .foregroundStyle(
                    .white.opacity(0.7)
                )

                Text("Erreur")
                    .font(.headline)
                    .foregroundStyle(
                        .white
                    )

                Text(message)
                    .font(.subheadline)
                    .foregroundStyle(
                        .white.opacity(0.7)
                    )
                    .multilineTextAlignment(
                        .center
                    )

                Button(
                    "Réessayer"
                ) {

                    Task {

                        await Task.yield()

                        guard
                            !Task.isCancelled
                        else {
                            return
                        }

                        await viewModel
                            .loadEvents()
                    }
                }
                .foregroundStyle(
                    .white
                )
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
                .accessibilityIdentifier(
                    "events.retry"
                )
            }

            Spacer()
        }
    }

    // ============================================================
    // MARK: - EMPTY
    // ============================================================

    private var emptyContent:
        some View {

        VStack {

            Spacer()

            VStack(spacing: 12) {

                Image(
                    systemName:
                        "calendar"
                )
                .font(
                    .system(
                        size: 44
                    )
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
                .font(
                    .headline
                )
            }

            Spacer()
        }
    }

    // ============================================================
    // MARK: - EVENT LIST
    // ============================================================

    private var eventsContent:
        some View {

        ScrollView {

            LazyVStack(
                spacing: 10
            ) {

                ForEach(
                    viewModel.events
                ) { event in

                    NavigationLink {

                        EventDetailView(
                            event:
                                event
                        )

                    } label: {

                        EventRowView(
                            event:
                                event
                        )
                    }
                    .buttonStyle(
                        .plain
                    )
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

            // refreshable s'exécute déjà hors du
            // cycle de rendu, donc il peut charger directement.

            await viewModel
                .loadEvents()
        }
        .accessibilityIdentifier(
            "events.list"
        )
    }

    // ============================================================
    // MARK: - CREATE BUTTON
    // ============================================================

    private var createButton:
        some View {

        Button {

            showCreationView =
                true

        } label: {

            Image(
                systemName:
                    "plus"
            )
            .font(
                .system(
                    size: 20,
                    weight:
                        .bold
                )
            )
            .foregroundStyle(
                .white
            )
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
        .accessibilityIdentifier(
            "events.create"
        )
    }
}

// MARK: - Preview

#Preview {

    EventListView()
}
