//
//  EventModel.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 06/10/2026.
//

import Foundation

struct EventModel: Identifiable {
    let id: String
    let title: String
    let titleLowercase: String
    let description: String
    let date: Date
    let location: String
    let category: String
    let ownerId: String
    let imageURL: String?
}
