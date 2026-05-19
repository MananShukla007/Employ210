//  Employ210
//
//  Created by Manan Shukla

import Foundation
import Amplify
import UIKit

@MainActor
final class AuthenticationManager: ObservableObject {

    // MARK: - Published State
    @Published var isAuthenticated: Bool = false
    @Published var isLoading: Bool = false
    @Published var userEmail: String = ""
    @Published var userRole: UserRole? = nil

    enum UserRole: String, CaseIterable { 
        case member
        case trainer
        case admin

        var displayName: String {
            rawValue.capitalized
        }
    }

    // MARK: - Init
    init() {
        Task { await refreshSession() }
    }

    // MARK: - Session Management

    func refreshSession() async {
        do {
            let session = try await Amplify.Auth.fetchAuthSession()

            guard session.isSignedIn else {
                reset()
                return
            }

            isAuthenticated = true
            await loadUserAttributes()

        } catch {
            reset()
        }
    }

    private func reset() {
        isAuthenticated = false
        userEmail = ""
        userRole = nil
    }

    // MARK: - EMAIL SIGN IN

    func signIn(email: String, password: String) async throws {
        isLoading = true
        defer { isLoading = false }

        let result = try await Amplify.Auth.signIn(
            username: email,
            password: password
        )

        guard result.isSignedIn else {
            throw NSError(
                domain: "Auth",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: "Sign in incomplete"]
            )
        }

        await refreshSession()
    }

    // MARK: - HOSTED UI (Google + Apple)

    func signInWithHostedUI() async throws {
        isLoading = true
        defer { isLoading = false }

        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let window = windowScene.windows.first(where: { $0.isKeyWindow }) else {
            throw NSError(
                domain: "Auth",
                code: 99,
                userInfo: [NSLocalizedDescriptionKey: "No presentation anchor found."]
            )
        }

        let result = try await Amplify.Auth.signInWithWebUI(
            presentationAnchor: window
        )

        if result.isSignedIn {
            await refreshSession()
        }
    }

    // MARK: - SIGN UP

    func signUp(email: String, password: String) async throws {
        let options = AuthSignUpRequest.Options(
            userAttributes: [
                AuthUserAttribute(.email, value: email)
            ]
        )
        
        do {
            let result = try await Amplify.Auth.signUp(
                username: email,
                password: password,
                options: options
            )
            print("✅ SignUp result: \(result)")
        } catch let error as AuthError {
            print("❌ AuthError: \(error)")
            print("❌ Error description: \(error.errorDescription)")
            print("❌ Recovery suggestion: \(error.recoverySuggestion ?? "none")")
            print("❌ Underlying error: \(error.underlyingError ?? "none" as Any)")
            throw error
        } catch {
            print("❌ Other error: \(error)")
            throw error
        }
    }

    func confirmSignUp(email: String, code: String) async throws {
        let result = try await Amplify.Auth.confirmSignUp(
            for: email,
            confirmationCode: code
        )

        guard result.isSignUpComplete else {
            throw NSError(
                domain: "Auth",
                code: 2,
                userInfo: [NSLocalizedDescriptionKey: "Verification incomplete"]
            )
        }
    }

    func resendConfirmationCode(email: String) async throws {
        _ = try await Amplify.Auth.resendSignUpCode(for: email)
    }

    // MARK: - PASSWORD RESET

    func startPasswordReset(email: String) async throws {
        _ = try await Amplify.Auth.resetPassword(for: email)
    }

    func confirmPasswordReset(
        email: String,
        newPassword: String,
        code: String
    ) async throws {
        try await Amplify.Auth.confirmResetPassword(
            for: email,
            with: newPassword,
            confirmationCode: code
        )
    }

    // MARK: - ROLE MANAGEMENT

    func updateUserRole(_ role: UserRole) async throws {
        let session = try await Amplify.Auth.fetchAuthSession()
        guard session.isSignedIn else { return }

        try await Amplify.Auth.update(
            userAttributes: [
                AuthUserAttribute(.custom("role"), value: role.rawValue)
            ]
        )

        userRole = role
    }

    // MARK: - Load Attributes

    private func loadUserAttributes() async {
        do {
            let attributes = try await Amplify.Auth.fetchUserAttributes()

            for attr in attributes {
                switch attr.key {
                case .email:
                    userEmail = attr.value
                case .custom("role"):
                    userRole = UserRole(rawValue: attr.value)
                default:
                    break
                }
            }

        } catch {
            // silent fail
        }
    }

    // MARK: - Sign Out

    func signOut() {
        Task {
            try? await Amplify.Auth.signOut()
            reset()
        }
    }
}
