//
//  Employ210App.swift
//  Employ210
//
//  Created by Manan Shukla
//

import SwiftUI
import Amplify
import AWSCognitoAuthPlugin
import AWSS3StoragePlugin

@main
struct Employ210App: App {

    @StateObject private var authManager = AuthenticationManager()
    @StateObject private var appStatus = AppStatusService()
    @Environment(\.scenePhase) private var scenePhase

    private static var amplifyConfigured = false

    init() {
        Self.configureAmplify()
    }

    private static func configureAmplify() {
        guard !amplifyConfigured else { return }

        do {
            try Amplify.add(plugin: AWSCognitoAuthPlugin())
            try Amplify.add(plugin: AWSS3StoragePlugin())
            try Amplify.configure()
            amplifyConfigured = true
            print("✅ Amplify configured successfully")
        } catch let error as AmplifyError {
            if error.errorDescription.lowercased().contains("already configured") {
                amplifyConfigured = true
                print("ℹ️ Amplify was already configured")
            } else {
                print("❌ Failed to configure Amplify: \(error)")
            }
        } catch {
            print("❌ Failed to configure Amplify: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            SplashScreenView()
                .environmentObject(authManager)
                .environmentObject(appStatus)
        }
        .onChange(of: scenePhase) { newPhase in
            // Re-check maintenance flag every time the app comes to foreground
            if newPhase == .active {
                appStatus.check()
            }
        }
    }
}
