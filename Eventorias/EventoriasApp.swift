//
//  EventoriasApp.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 05/10/2026.
//


import SwiftUI
import UIKit
import FirebaseCore
import UserNotifications

final class AppDelegate:
    NSObject,
    UIApplicationDelegate,
    UNUserNotificationCenterDelegate {

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions
            launchOptions:
            [
                UIApplication.LaunchOptionsKey:
                    Any
            ]? = nil
    ) -> Bool {

        FirebaseApp.configure()

        UNUserNotificationCenter
            .current()
            .delegate =
                self

#if DEBUG

        // Pendant les tests UI :
        // - aucun listener Firestore réel
        // - aucune demande de permission notification
        // - aucune notification de test
        if UITestConfiguration.isEnabled {

            return true
        }

#endif

        Task { @MainActor in

            await NotificationManager
                .shared
                .startMonitoringIfEnabled()
        }

        return true
    }

    // MARK: - Notification reçue app ouverte

    func userNotificationCenter(
        _ center:
            UNUserNotificationCenter,
        willPresent notification:
            UNNotification
    ) async
        -> UNNotificationPresentationOptions {

        [
            .banner,
            .sound,
            .badge
        ]
    }
}

@main
struct EventoriasApp:
    App {

    @UIApplicationDelegateAdaptor(
        AppDelegate.self
    )
    private var delegate

    var body:
        some Scene {

        WindowGroup {

#if DEBUG

            if UITestConfiguration
                .isEnabled {

                UITestRootView()

            } else {

                ContentView()
            }

#else

            ContentView()

#endif
        }
    }
}
