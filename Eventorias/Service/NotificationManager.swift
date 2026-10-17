//
//  NotificationManager.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 16/10/2026.
//


import Foundation
import UserNotifications
import FirebaseFirestore

@MainActor
final class NotificationManager {

    static let shared =
        NotificationManager()

    private let center =
        UNUserNotificationCenter.current()

    private let database =
        Firestore.firestore()

    private var listenerRegistration:
        ListenerRegistration?

    private let preferenceKey =
        "eventorias.notifications.enabled"

    private let eventsCacheKey =
        "eventorias.notifications.eventsCache"

    private init() {}

    // MARK: - Stored Event

    private struct StoredEvent:
        Codable,
        Sendable,
        Equatable {

        let id: String
        let title: String
        let description: String
        let date: Date
        let location: String
        let category: String
    }

    // MARK: - Preference

    var notificationsEnabled:
        Bool {

        UserDefaults.standard
            .bool(
                forKey:
                    preferenceKey
            )
    }

    // MARK: - Start

    func startMonitoringIfEnabled()
        async {

        guard notificationsEnabled else {

            print(
                "[Notifications] Désactivées."
            )

            return
        }

        let settings =
            await center
                .notificationSettings()

        switch settings.authorizationStatus {

        case .authorized,
             .provisional,
             .ephemeral:

            print(
                "[Notifications] Autorisation iOS OK."
            )

            await synchronizeNow()

            startMonitoring()

        case .denied:

            print(
                "[Notifications] Autorisation refusée dans iOS."
            )

            UserDefaults.standard
                .set(
                    false,
                    forKey:
                        preferenceKey
                )

            stopMonitoring()

        case .notDetermined:

            print(
                "[Notifications] Autorisation pas encore demandée."
            )

        @unknown default:

            break
        }
    }

    // MARK: - Enable

    @discardableResult
    func enableNotifications()
        async -> Bool {

        do {

            let granted =
                try await center
                    .requestAuthorization(
                        options: [
                            .alert,
                            .badge,
                            .sound
                        ]
                    )

            guard granted else {

                UserDefaults.standard
                    .set(
                        false,
                        forKey:
                            preferenceKey
                    )

                stopMonitoring()

                print(
                    "[Notifications] Permission refusée."
                )

                return false
            }

            UserDefaults.standard
                .set(
                    true,
                    forKey:
                        preferenceKey
                )

            print(
                "[Notifications] Permission accordée."
            )


            await synchronizeNow()

            startMonitoring()

            return true

        } catch {

            print(
                "[Notifications] Erreur autorisation :",
                error.localizedDescription
            )

            UserDefaults.standard
                .set(
                    false,
                    forKey:
                        preferenceKey
                )

            stopMonitoring()

            return false
        }
    }

    // MARK: - Disable

    func disableNotifications()
        async {

        UserDefaults.standard
            .set(
                false,
                forKey:
                    preferenceKey
            )

        stopMonitoring()

        center
            .removeAllPendingNotificationRequests()

        center
            .removeAllDeliveredNotifications()

        UserDefaults.standard
            .removeObject(
                forKey:
                    eventsCacheKey
            )

        print(
            "[Notifications] Notifications désactivées."
        )
    }

    // MARK: - Update Preference

    @discardableResult
    func updateNotifications(
        enabled: Bool
    ) async -> Bool {

        if enabled {

            return await
                enableNotifications()

        } else {

            await
                disableNotifications()

            return true
        }
    }

  
    // MARK: - Immediate Firestore Synchronisation

    private func synchronizeNow()
        async {

        guard notificationsEnabled else {

            return
        }

        do {

            let snapshot =
                try await database
                    .collection(
                        "events"
                    )
                    .getDocuments()

            let events =
                snapshot
                    .documents
                    .compactMap {
                        document in

                        Self.makeStoredEvent(
                            id:
                                document.documentID,
                            data:
                                document.data()
                        )
                    }

            await processEvents(
                events
            )

            print(
                "[Notifications] Synchronisation terminée :",
                events.count,
                "événement(s)."
            )

        } catch {

            print(
                "[Notifications] Synchronisation Firestore impossible :",
                error.localizedDescription
            )
        }
    }

    // MARK: - Firestore Listener

    private func startMonitoring() {

        guard
            notificationsEnabled,
            listenerRegistration == nil
        else {

            return
        }

        print(
            "[Notifications] Listener Firestore démarré."
        )

        listenerRegistration =
            database
                .collection(
                    "events"
                )
                .addSnapshotListener {
                    snapshot,
                    error in

                    if let error {

                        print(
                            "[Notifications] Listener Firestore :",
                            error.localizedDescription
                        )

                        return
                    }

                    guard let snapshot else {

                        return
                    }

                    let events =
                        snapshot
                            .documents
                            .compactMap {
                                document in

                                Self.makeStoredEvent(
                                    id:
                                        document.documentID,
                                    data:
                                        document.data()
                                )
                            }

                    Task {
                        @MainActor in

                        await NotificationManager
                            .shared
                            .processEvents(
                                events
                            )
                    }
                }
    }

    private func stopMonitoring() {

        listenerRegistration?
            .remove()

        listenerRegistration =
            nil
    }

    // MARK: - Conversion

    nonisolated
    private static func makeStoredEvent(
        id: String,
        data: [String: Any]
    ) -> StoredEvent? {

        guard
            let title =
                data["title"]
                    as? String,
            let timestamp =
                data["date"]
                    as? Timestamp,
            let location =
                data["location"]
                    as? String,
            let category =
                data["category"]
                    as? String
        else {

            return nil
        }

        return StoredEvent(
            id:
                id,
            title:
                title,
            description:
                data["description"]
                    as? String
                ?? "",
            date:
                timestamp
                    .dateValue(),
            location:
                location,
            category:
                category
        )
    }

    // MARK: - Process Events

    private func processEvents(
        _ events:
            [StoredEvent]
    ) async {

        guard notificationsEnabled else {

            return
        }

        let current =
            Dictionary(
                uniqueKeysWithValues:
                    events.map {
                        (
                            $0.id,
                            $0
                        )
                    }
            )

        let previous =
            loadStoredEvents()

        // Première synchronisation 
   
        if previous.isEmpty {

            for event in current.values {

                await scheduleReminder(
                    for:
                        event
                )
            }

            saveStoredEvents(
                current
            )

            return
        }

        // Modifications + rappels

        for (
            eventId,
            currentEvent
        ) in current {

            if let previousEvent =
                previous[eventId] {

                let changes =
                    importantChanges(
                        previous:
                            previousEvent,
                        current:
                            currentEvent
                    )

                if !changes.isEmpty {

                    await sendUpdateNotification(
                        event:
                            currentEvent,
                        changes:
                            changes
                    )
                }
            }

            await scheduleReminder(
                for:
                    currentEvent
            )
        }

        // Suppressions

        let deletedIds =
            Set(
                previous.keys
            )
            .subtracting(
                current.keys
            )

        for eventId in deletedIds {

            guard
                let deletedEvent =
                    previous[eventId]
            else {

                continue
            }

            cancelReminder(
                eventId:
                    eventId
            )

            await sendCancellationNotification(
                event:
                    deletedEvent
            )
        }

        saveStoredEvents(
            current
        )
    }

    // MARK: - Important Changes

    private func importantChanges(
        previous: StoredEvent,
        current: StoredEvent
    ) -> [String] {

        var changes:
            [String] = []

        if normalized(
            previous.title
        ) != normalized(
            current.title
        ) {

            changes.append(
                "le titre"
            )
        }

        if abs(
            previous.date
                .timeIntervalSince(
                    current.date
                )
        ) > 1 {

            changes.append(
                "la date ou l'heure"
            )
        }

        if normalized(
            previous.location
        ) != normalized(
            current.location
        ) {

            changes.append(
                "le lieu"
            )
        }

        if normalized(
            previous.description
        ) != normalized(
            current.description
        ) {

            changes.append(
                "la description"
            )
        }

        if normalized(
            previous.category
        ) != normalized(
            current.category
        ) {

            changes.append(
                "la catégorie"
            )
        }

        return changes
    }

    private func normalized(
        _ value: String
    ) -> String {

        value
            .trimmingCharacters(
                in:
                    .whitespacesAndNewlines
            )
            .lowercased()
    }

    // MARK: - Reminder

    private func scheduleReminder(
        for event:
            StoredEvent
    ) async {

        guard notificationsEnabled else {

            return
        }

        let now =
            Date()

        guard event.date > now else {

            cancelReminder(
                eventId:
                    event.id
            )

            return
        }

        let reminderDate =
            event.date
                .addingTimeInterval(
                    -86_400
                )

        let delay:
            TimeInterval

        let body:
            String

        let cleanLocation =
            event.location
                .trimmingCharacters(
                    in:
                        .whitespacesAndNewlines
                )

        if reminderDate > now {

            delay =
                reminderDate
                    .timeIntervalSince(
                        now
                    )

            if cleanLocation.isEmpty {

                body =
                    "\(event.title) commence dans 24 heures."

            } else {

                body =
                    "\(event.title) commence dans 24 heures à \(cleanLocation)."
            }

        } else {

            // L'événement est déjà à moins
            // de 24 heures.
            delay =
                5

            if cleanLocation.isEmpty {

                body =
                    "\(event.title) commence dans moins de 24 heures."

            } else {

                body =
                    "\(event.title) commence dans moins de 24 heures à \(cleanLocation)."
            }
        }

        let identifier =
            reminderIdentifier(
                eventId:
                    event.id
            )

        // Remplace toujours l'ancien rappel.
        center
            .removePendingNotificationRequests(
                withIdentifiers: [
                    identifier
                ]
            )

        let content =
            UNMutableNotificationContent()

        content.title =
            "Événement à venir 🎉"

        content.body =
            body

        content.sound =
            .default

        content.userInfo = [
            "type":
                "event_reminder",
            "eventId":
                event.id
        ]

        let trigger =
            UNTimeIntervalNotificationTrigger(
                timeInterval:
                    max(
                        delay,
                        1
                    ),
                repeats:
                    false
            )

        let request =
            UNNotificationRequest(
                identifier:
                    identifier,
                content:
                    content,
                trigger:
                    trigger
            )

        do {

            try await center
                .add(
                    request
                )

            print(
                "[Notifications] Rappel programmé :",
                event.title,
                "dans",
                Int(delay),
                "seconde(s)."
            )

        } catch {

            print(
                "[Notifications] Erreur programmation :",
                error.localizedDescription
            )
        }
    }

    private func cancelReminder(
        eventId: String
    ) {

        center
            .removePendingNotificationRequests(
                withIdentifiers: [
                    reminderIdentifier(
                        eventId:
                            eventId
                    )
                ]
            )
    }

    private func reminderIdentifier(
        eventId: String
    ) -> String {

        "event-reminder-\(eventId)"
    }

    // MARK: - Update Notification

    private func sendUpdateNotification(
        event: StoredEvent,
        changes: [String]
    ) async {

        let content =
            UNMutableNotificationContent()

        content.title =
            "Mise à jour : \(event.title)"

        if changes.count == 1 {

            content.body =
                "Une information importante a changé : \(changes[0])."

        } else {

            content.body =
                "Des informations importantes ont changé : \(changes.joined(separator: ", "))."
        }

        content.sound =
            .default

        content.userInfo = [
            "type":
                "event_update",
            "eventId":
                event.id
        ]

        let request =
            UNNotificationRequest(
                identifier:
                    "event-update-\(event.id)-\(UUID().uuidString)",
                content:
                    content,
                trigger:
                    nil
            )

        do {

            try await center
                .add(
                    request
                )

            print(
                "[Notifications] Mise à jour détectée :",
                event.title
            )

        } catch {

            print(
                "[Notifications] Notification mise à jour impossible :",
                error.localizedDescription
            )
        }
    }

    // MARK: - Cancellation Notification

    private func sendCancellationNotification(
        event:
            StoredEvent
    ) async {

        let content =
            UNMutableNotificationContent()

        content.title =
            "Événement annulé"

        content.body =
            "\(event.title) a été annulé ou supprimé."

        content.sound =
            .default

        content.userInfo = [
            "type":
                "event_cancelled",
            "eventId":
                event.id
        ]

        let request =
            UNNotificationRequest(
                identifier:
                    "event-cancelled-\(event.id)-\(UUID().uuidString)",
                content:
                    content,
                trigger:
                    nil
            )

        do {

            try await center
                .add(
                    request
                )

            print(
                "[Notifications] Événement supprimé :",
                event.title
            )

        } catch {

            print(
                "[Notifications] Notification annulation impossible :",
                error.localizedDescription
            )
        }
    }

    // MARK: - Cache

    private func loadStoredEvents()
        -> [String: StoredEvent] {

        guard
            let data =
                UserDefaults.standard
                    .data(
                        forKey:
                            eventsCacheKey
                    )
        else {

            return [:]
        }

        do {

            return try JSONDecoder()
                .decode(
                    [String: StoredEvent]
                        .self,
                    from:
                        data
                )

        } catch {

            print(
                "[Notifications] Cache invalide :",
                error.localizedDescription
            )

            return [:]
        }
    }

    private func saveStoredEvents(
        _ events:
            [String: StoredEvent]
    ) {

        do {

            let data =
                try JSONEncoder()
                    .encode(
                        events
                    )

            UserDefaults.standard
                .set(
                    data,
                    forKey:
                        eventsCacheKey
                )

        } catch {

            print(
                "[Notifications] Cache impossible à enregistrer :",
                error.localizedDescription
            )
        }
    }
}
