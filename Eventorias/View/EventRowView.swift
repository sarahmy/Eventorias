//
//  EventRowView.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import SwiftUI

struct EventRowView: View {

    let event: EventModel

    var body: some View {

        HStack(spacing: 12) {

            categoryIcon

            VStack(
                alignment: .leading,
                spacing: 4
            ) {

                Text(event.title)
                    .font(.headline)
                    .foregroundStyle(.white)
                    .lineLimit(1)

                Text(
                    event.date.formatted(
                        date: .abbreviated,
                        time: .omitted
                    )
                )
                .font(.caption)
                .foregroundStyle(.white.opacity(0.65))

                Text(event.location)
                    .font(.caption2)
                    .foregroundStyle(.white.opacity(0.55))
                    .lineLimit(1)
            }

            Spacer()

            eventImage
        }
        .padding(10)
        .frame(maxWidth: .infinity)
        .frame(height: 82)
        .background(
            Color.white.opacity(0.14)
        )
        .clipShape(
            RoundedRectangle(cornerRadius: 10)
        )
        .accessibilityElement(children: .combine)
        .accessibilityLabel(
            "\(event.title), \(event.location)"
        )
    }

    private var categoryIcon: some View {

        ZStack {

            Circle()
                .fill(Color.white.opacity(0.15))
                .frame(width: 38, height: 38)

            Image(systemName: iconName)
                .foregroundStyle(.white)
        }
    }

    @ViewBuilder
    private var eventImage: some View {

        if
            let imageURL = event.imageURL,
            let url = URL(string: imageURL) {

            AsyncImage(url: url) { phase in

                switch phase {

                case .success(let image):

                    image
                        .resizable()
                        .scaledToFill()

                case .failure:

                    imagePlaceholder

                case .empty:

                    ProgressView()
                        .tint(.white)

                @unknown default:

                    imagePlaceholder
                }
            }
            .frame(width: 92, height: 62)
            .clipShape(
                RoundedRectangle(cornerRadius: 8)
            )

        } else {

            imagePlaceholder
        }
    }

    private var imagePlaceholder: some View {

        ZStack {

            Color.white.opacity(0.08)

            Image(systemName: iconName)
                .font(.title2)
                .foregroundStyle(.white.opacity(0.6))
        }
        .frame(width: 92, height: 62)
        .clipShape(
            RoundedRectangle(cornerRadius: 8)
        )
    }

    private var iconName: String {

        switch event.category.lowercased() {

        case "music", "musique":
            return "music.note"

        case "art":
            return "paintpalette.fill"

        case "technology", "tech":
            return "laptopcomputer"

        case "food", "cuisine":
            return "fork.knife"

        case "cinema", "film":
            return "film.fill"

        case "sport":
            return "figure.run"

        default:
            return "calendar"
        }
    }
}

#Preview {

    EventRowView(
        event: EventModel(
            id: "1",
            title: "Music festival",
            titleLowercase: "music festival",
            description: "Festival de musique",
            date: Date(),
            location: "Paris",
            category: "music",
            ownerId: "preview",
            imageURL: nil
        )
    )
    .padding()
    .background(Color.black)
}
