//
//  EventDetailView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 07/10/2026.
//

import SwiftUI

struct EventDetailView: View {

    private let viewModel: EventDetailViewModel

    init(event: EventModel) {
        self.viewModel = EventDetailViewModel(
            event: event
        )
    }

    var body: some View {

        ZStack {

            Color(
                red: 0.08,
                green: 0.07,
                blue: 0.09
            )
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
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .padding(.bottom, 30)
            }
        }
        .navigationTitle(
            viewModel.event.title
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(
            Color(
                red: 0.08,
                green: 0.07,
                blue: 0.09
            ),
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
    }

    // MARK: - Photo

    private var eventPhoto: some View {

        Group {

            if let imageURL =
                viewModel.eventImageURL {

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

                    case .success(let image):

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
            maxWidth: .infinity
        )
        .frame(height: 250)
        .clipped()
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
        .accessibilityLabel(
            "Photo de \(viewModel.event.title)"
        )
    }

    private var photoPlaceholder: some View {

        ZStack {

            Color.white
                .opacity(0.10)

            VStack(spacing: 10) {

                Image(
                    systemName: "photo"
                )
                .font(
                    .system(size: 42)
                )

                Text("Photo indisponible")
                    .font(.caption)
            }
            .foregroundStyle(
                .white.opacity(0.7)
            )
        }
    }

    // MARK: - Informations

    private var eventInformation: some View {

        VStack(
            alignment: .leading,
            spacing: 14
        ) {

            informationRow(
                icon: "calendar",
                text: viewModel.formattedDate
            )

            informationRow(
                icon: "clock",
                text: viewModel.formattedTime
            )

            informationRow(
                icon: "tag.fill",
                text: viewModel.formattedCategory
            )
        }
    }

    private func informationRow(
        icon: String,
        text: String
    ) -> some View {

        HStack(spacing: 12) {

            Image(
                systemName: icon
            )
            .foregroundStyle(.red)
            .frame(width: 22)

            Text(text)
                .foregroundStyle(.white)

            Spacer()
        }
    }

    // MARK: - Description

    private var descriptionSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Description")
                .font(.headline)
                .foregroundStyle(.white)

            if viewModel.event.description.isEmpty {

                Text(
                    "Aucune description disponible."
                )
                .foregroundStyle(
                    .white.opacity(0.6)
                )

            } else {

                Text(
                    viewModel.event.description
                )
                .foregroundStyle(
                    .white.opacity(0.8)
                )
            }
        }
    }

    // MARK: - Adresse

    private var locationSection: some View {

        VStack(
            alignment: .leading,
            spacing: 8
        ) {

            Text("Lieu")
                .font(.headline)
                .foregroundStyle(.white)

            HStack(
                alignment: .top,
                spacing: 10
            ) {

                Image(
                    systemName:
                        "mappin.and.ellipse"
                )
                .foregroundStyle(.red)

                Text(
                    viewModel.event.location
                )
                .foregroundStyle(
                    .white.opacity(0.8)
                )
            }
        }
    }

    // MARK: - Carte Google Maps

    private var mapSection: some View {

        VStack(
            alignment: .leading,
            spacing: 10
        ) {

            Text("Carte")
                .font(.headline)
                .foregroundStyle(.white)

            if let mapURL =
                viewModel.staticMapURL {

                AsyncImage(
                    url: mapURL
                ) { phase in

                    switch phase {

                    case .empty:

                        ZStack {

                            mapPlaceholder

                            ProgressView()
                                .tint(.white)
                        }

                    case .success(let image):

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
                    maxWidth: .infinity
                )
                .frame(height: 190)
                .clipped()
                .clipShape(
                    RoundedRectangle(
                        cornerRadius: 12
                    )
                )
                .accessibilityLabel(
                    "Carte de \(viewModel.event.location)"
                )

            } else {

                mapConfigurationView
            }
        }
    }

    private var mapPlaceholder: some View {

        ZStack {

            Color.white
                .opacity(0.10)

            Image(
                systemName: "map"
            )
            .font(
                .system(size: 40)
            )
            .foregroundStyle(
                .white.opacity(0.6)
            )
        }
    }

    private var mapErrorView: some View {

        VStack(spacing: 10) {

            Image(
                systemName:
                    "exclamationmark.triangle.fill"
            )
            .font(
                .system(size: 30)
            )

            Text(
                "Impossible d'afficher la carte."
            )
            .font(.subheadline)

            Text(
                "Vérifiez la clé Google Maps et l'activation de Maps Static API."
            )
            .font(.caption)
            .multilineTextAlignment(
                .center
            )
        }
        .foregroundStyle(
            .white.opacity(0.75)
        )
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 190)
        .background(
            Color.white.opacity(0.10)
        )
    }

    private var mapConfigurationView: some View {

        VStack(spacing: 10) {

            Image(
                systemName: "map"
            )
            .font(
                .system(size: 34)
            )

            Text(
                "Clé Google Maps non configurée."
            )
            .font(.subheadline)
        }
        .foregroundStyle(
            .white.opacity(0.7)
        )
        .frame(
            maxWidth: .infinity
        )
        .frame(height: 190)
        .background(
            Color.white.opacity(0.10)
        )
        .clipShape(
            RoundedRectangle(
                cornerRadius: 12
            )
        )
    }
}

#Preview {

    NavigationStack {

        EventDetailView(
            event: EventModel(
                id: "preview",
                title: "Art exhibition",
                titleLowercase:
                    "art exhibition",
                description:
                    "Exposition d'art contemporain présentant plusieurs artistes.",
                date: Date(),
                location:
                    "Nantes, France",
                category: "art",
                ownerId: "preview",
                imageURL: nil
            )
        )
    }
}
