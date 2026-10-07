//
//  EventDetailViewModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 07/10/2026.
//

import Foundation

struct EventDetailViewModel {

    let event: EventModel

    // MARK: - Photo de l'événement

    var eventImageURL: URL? {

        guard
            let imageURL = event.imageURL,
            !imageURL
                .trimmingCharacters(in: .whitespacesAndNewlines)
                .isEmpty
        else {
            return nil
        }

        return URL(string: imageURL)
    }

    // MARK: - Clé Google Maps

    private var googleMapsAPIKey: String? {

        guard
            let apiKey = Bundle.main.object(
                forInfoDictionaryKey: "GOOGLE_MAPS_API_KEY"
            ) as? String
        else {
            print("[Google Maps] Clé API introuvable.")
            return nil
        }

        let cleanKey = apiKey
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !cleanKey.isEmpty,
            !cleanKey.contains("$(")
        else {
            print("[Google Maps] Clé API non configurée.")
            return nil
        }

        return cleanKey
    }

    // MARK: - Carte Google Maps statique

    var staticMapURL: URL? {

        guard let apiKey = googleMapsAPIKey else {
            return nil
        }

        var components = URLComponents(
            string: "https://maps.googleapis.com/maps/api/staticmap"
        )

        components?.queryItems = [

            URLQueryItem(
                name: "center",
                value: event.location
            ),

            URLQueryItem(
                name: "zoom",
                value: "14"
            ),

            URLQueryItem(
                name: "size",
                value: "640x320"
            ),

            URLQueryItem(
                name: "scale",
                value: "2"
            ),

            URLQueryItem(
                name: "maptype",
                value: "roadmap"
            ),

            URLQueryItem(
                name: "markers",
                value: "color:red|\(event.location)"
            ),

            URLQueryItem(
                name: "key",
                value: apiKey
            )
        ]

        return components?.url
    }

    // MARK: - Formatage

    var formattedDate: String {

        event.date.formatted(
            date: .long,
            time: .omitted
        )
    }

    var formattedTime: String {

        event.date.formatted(
            date: .omitted,
            time: .shortened
        )
    }

    var formattedCategory: String {
        event.category.capitalized
    }
}
