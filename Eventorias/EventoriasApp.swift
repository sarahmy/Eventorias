//
//  EventoriasApp.swift
//  Eventorias
//
//  Created by Sarah Maimoun on 05/10/2026.
//


import SwiftUI
import FirebaseCore

final class AppDelegate:
    NSObject,
    UIApplicationDelegate {

    func application(
        _ application:
            UIApplication,
        didFinishLaunchingWithOptions
            launchOptions:
            [
                UIApplication
                    .LaunchOptionsKey: Any
            ]? = nil
    ) -> Bool {

        FirebaseApp.configure()

        return true
    }
}

@main
struct EventoriasApp: App {

    @UIApplicationDelegateAdaptor(
        AppDelegate.self
    )
    var delegate

    var body: some Scene {

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
