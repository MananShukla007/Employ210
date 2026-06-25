//
//  RootCoordinator.swift
//  Employ210
//
//  Coordinates navigation based on authentication state and maintenance mode.
//

import SwiftUI

struct RootCoordinator: View {

    @EnvironmentObject var authManager: AuthenticationManager
    @EnvironmentObject var appStatus: AppStatusService

    var body: some View {
        Group {
            if appStatus.isInMaintenance {
                MaintenanceView(message: appStatus.maintenanceMessage)
            } else if authManager.isLoading {
                // Show splash while checking session
                SplashView()
            } else if authManager.isAuthenticated {
                // User is signed in - show role selection
                RoleSelectionView()
                    .environmentObject(authManager)
                    .transition(.opacity)
            } else {
                // Not signed in - show welcome/auth flow
                NavigationStack {
                    WelcomeView()
                }
                .transition(.opacity)
            }
        }
        .animation(.easeInOut(duration: 0.3), value: authManager.isAuthenticated)
        .animation(.easeInOut(duration: 0.2), value: authManager.isLoading)
        .animation(.easeInOut(duration: 0.3), value: appStatus.isInMaintenance)
        .onAppear {
            // Initial status check after splash animation completes
            appStatus.check()
        }
    }
}

// MARK: - Splash View

struct SplashView: View {
    var body: some View {
        ZStack {
            // Background gradient - matching app theme
            LinearGradient(
                colors: [
                    Color(red: 0.05, green: 0.10, blue: 0.15),
                    Color(red: 0.08, green: 0.15, blue: 0.20),
                    Color(red: 0.05, green: 0.10, blue: 0.15)
                ],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack(spacing: 24) {
                // Logo with glow
                ZStack {
                    Image("Employ210")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 130)
                        .blur(radius: 20)
                        .opacity(0.5)
                    
                    Image("Employ210")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 24))
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                }

                ProgressView()
                    .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    .scaleEffect(1.3)

                Text("Loading...")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.6))
            }
        }
    }
}

// MARK: - Preview

#Preview {
    RootCoordinator()
        .environmentObject(AuthenticationManager())
        .environmentObject(AppStatusService())
}

#Preview("Maintenance") {
    RootCoordinator()
        .environmentObject(AuthenticationManager())
        .environmentObject({
            let s = AppStatusService()
            // To preview maintenance: set AWSConfig.statusURL to return maintenanceMode=true,
            // or temporarily hard-code by calling check() against a mock.
            return s
        }())
}

#Preview("Loading Splash") {
    SplashView()
}