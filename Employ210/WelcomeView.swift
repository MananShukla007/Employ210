//
//  WelcomeView.swift
//  Employ210
//
//  Created by Manan Shukla
//
//  Modern Authentication Views with Social Login Support
//

import SwiftUI
import AuthenticationServices

// MARK: - WELCOME

struct WelcomeView: View {

    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showError = false
    @State private var errorMessage = ""

    var body: some View {
        ZStack {
            // Background gradient
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

            // Subtle background circles
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.teal.opacity(0.15), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -50)
                    .blur(radius: 60)

                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.orange.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 200)
                    .blur(radius: 50)
            }

            VStack(spacing: 0) {
                Spacer()
                    .frame(height: 60)

                VStack(spacing: 20) {
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

                    VStack(spacing: 8) {
                        Text("Welcome to")
                            .font(.title3)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.7))

                        Text("Employ210")
                            .font(.system(size: 36, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.8)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )

                        Text("Empowering Employment Success")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                            .padding(.top, 4)
                    }
                }

                Spacer()

                // Auth Buttons
                VStack(spacing: 14) {
                    // Google Button
                    SocialButton(
                        title: "Continue with Google",
                        icon: "G",
                        iconColors: [.red, .yellow, .green, .blue],
                        backgroundColor: .white,
                        foregroundColor: .black
                    ) {
                        signInWithHostedUI()
                    }

                    // Apple Button
                    SocialButton(
                        title: "Continue with Apple",
                        systemIcon: "apple.logo",
                        backgroundColor: .white.opacity(0.1),
                        foregroundColor: .white,
                        hasBorder: true
                    ) {
                        signInWithHostedUI()
                    }

                    // Divider
                    HStack(spacing: 16) {
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                        Text("or")
                            .font(.footnote)
                            .foregroundStyle(.white.opacity(0.5))
                        Rectangle()
                            .fill(Color.white.opacity(0.2))
                            .frame(height: 1)
                    }
                    .padding(.vertical, 8)

                    // Email Sign In
                    NavigationLink {
                        LoginView()
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: "envelope.fill")
                                .font(.system(size: 16))
                            Text("Sign in with Email")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: Color.blue.opacity(0.3), radius: 10, x: 0, y: 5)
                    }

                    // Create Account
                    NavigationLink {
                        SignUpView()
                    } label: {
                        Text("Create Account")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                    }

                    // Forgot Password
                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 8)
                }
                .padding(.horizontal, 28)

                Spacer()
                    .frame(height: 40)
            }
        }
        .alert("Sign In Error", isPresented: $showError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(errorMessage)
        }
    }

    private func signInWithHostedUI() {
        Task {
            do {
                try await authManager.signInWithHostedUI()
            } catch {
                errorMessage = error.localizedDescription
                showError = true
            }
        }
    }
}

// MARK: - Social Button Component

struct SocialButton: View {
    let title: String
    var icon: String? = nil
    var systemIcon: String? = nil
    var iconColors: [Color]? = nil
    let backgroundColor: Color
    let foregroundColor: Color
    var hasBorder: Bool = false
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: 12) {
                if let icon = icon {
                    if let colors = iconColors {
                        Text(icon)
                            .font(.title2.bold())
                            .foregroundStyle(
                                LinearGradient(
                                    colors: colors,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    } else {
                        Text(icon)
                            .font(.title2.bold())
                            .foregroundColor(foregroundColor)
                    }
                }

                if let systemIcon = systemIcon {
                    Image(systemName: systemIcon)
                        .font(.system(size: 18, weight: .medium))
                }

                Text(title)
                    .font(.headline)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(backgroundColor)
            .foregroundColor(foregroundColor)
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(hasBorder ? Color.white.opacity(0.2) : Color.clear, lineWidth: 1)
            )
            .shadow(color: backgroundColor == .white ? Color.black.opacity(0.1) : Color.clear, radius: 10, x: 0, y: 5)
        }
    }
}

// MARK: - LOGIN (Email/Password)

struct LoginView: View {

    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var loading = false

    @FocusState private var focusedField: Field?

    enum Field {
        case email, password
    }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.10, blue: 0.15)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 16) {
                        Image("Employ210")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text("Welcome Back")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text("Sign in to continue")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 40)

                    VStack(spacing: 18) {
                        ModernTextField(
                            title: "Email",
                            text: $email,
                            icon: "envelope",
                            keyboardType: .emailAddress
                        )
                        .focused($focusedField, equals: .email)
                        .textContentType(.emailAddress)
                        .autocapitalization(.none)

                        ModernSecureField(title: "Password", text: $password, icon: "lock")
                            .focused($focusedField, equals: .password)
                            .textContentType(.password)
                    }
                    .padding(.horizontal, 24)

                    if !errorMessage.isEmpty {
                        ErrorBanner(message: errorMessage)
                            .padding(.horizontal, 24)
                    }

                    Button(action: login) {
                        HStack {
                            if loading {
                                ProgressView().tint(.white)
                            } else {
                                Text("Sign In").font(.headline)
                            }
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: isFormValid ? [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isFormValid || loading)
                    .padding(.horizontal, 24)

                    NavigationLink {
                        ForgotPasswordView()
                    } label: {
                        Text("Forgot Password?")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture { focusedField = nil }
    }

    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }

    private func login() {
        focusedField = nil
        errorMessage = ""
        loading = true

        Task {
            do {
                try await authManager.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }
}

// MARK: - Modern Text Field

struct ModernTextField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 20)
                }

                TextField(title, text: $text)
                    .keyboardType(keyboardType)
                    .foregroundColor(.white)
                    .tint(.white)
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Modern Secure Field

struct ModernSecureField: View {
    let title: String
    @Binding var text: String
    var icon: String? = nil
    @State private var isVisible = false

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.caption)
                .fontWeight(.medium)
                .foregroundStyle(.white.opacity(0.6))

            HStack(spacing: 12) {
                if let icon = icon {
                    Image(systemName: icon)
                        .foregroundStyle(.white.opacity(0.5))
                        .frame(width: 20)
                }

                Group {
                    if isVisible {
                        TextField(title, text: $text)
                    } else {
                        SecureField(title, text: $text)
                    }
                }
                .foregroundColor(.white)
                .tint(.white)

                Button {
                    isVisible.toggle()
                } label: {
                    Image(systemName: isVisible ? "eye.slash.fill" : "eye.fill")
                        .foregroundStyle(.white.opacity(0.5))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white.opacity(0.08))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

// MARK: - Error Banner

struct ErrorBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Success Banner

struct SuccessBanner: View {
    let message: String

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(.green)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding()
        .background(Color.green.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - SIGN UP

struct SignUpView: View {

    @EnvironmentObject var authManager: AuthenticationManager

    @State private var email = ""
    @State private var confirmEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var code = ""
    @State private var stage = 1

    @State private var loading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    @FocusState private var focusedField: Field?

    enum Field { case email, confirmEmail, password, confirmPassword, code }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.10, blue: 0.15).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 16) {
                        Image("Employ210")
                            .resizable()
                            .scaledToFit()
                            .frame(width: 80)
                            .clipShape(RoundedRectangle(cornerRadius: 16))

                        Text(stage == 1 ? "Create Account" : "Verify Email")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text(stage == 1 ? "Join Employ210 today" : "Enter the code sent to your email")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    .padding(.top, 40)

                    if stage == 1 { stageOneForm } else { stageTwoForm }

                    if !errorMessage.isEmpty {
                        ErrorBanner(message: errorMessage).padding(.horizontal, 24)
                    }

                    if !successMessage.isEmpty {
                        SuccessBanner(message: successMessage).padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture { focusedField = nil }
    }

    private var stageOneForm: some View {
        VStack(spacing: 18) {
            ModernTextField(title: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
                .focused($focusedField, equals: .email)
                .autocapitalization(.none)

            ModernTextField(title: "Confirm Email", text: $confirmEmail, icon: "envelope.badge", keyboardType: .emailAddress)
                .focused($focusedField, equals: .confirmEmail)
                .autocapitalization(.none)

            ModernSecureField(title: "Password", text: $password, icon: "lock")
                .focused($focusedField, equals: .password)

            ModernSecureField(title: "Confirm Password", text: $confirmPassword, icon: "lock.fill")
                .focused($focusedField, equals: .confirmPassword)

            PasswordRequirementsCard(password: password)

            Button(action: signUp) {
                HStack {
                    if loading { ProgressView().tint(.white) }
                    else { Text("Create Account").font(.headline) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: isFormValid ? [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isFormValid || loading)
        }
        .padding(.horizontal, 24)
    }

    private var stageTwoForm: some View {
        VStack(spacing: 18) {
            Text(email).font(.headline).foregroundColor(.white)

            ModernTextField(title: "Verification Code", text: $code, icon: "number", keyboardType: .numberPad)
                .focused($focusedField, equals: .code)

            Button(action: confirmCode) {
                HStack {
                    if loading { ProgressView().tint(.white) }
                    else { Text("Verify Email").font(.headline) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: code.count >= 6 ? [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(code.count < 6 || loading)

            Button("Resend Code") { resendCode() }
                .font(.subheadline)
                .foregroundStyle(.white.opacity(0.6))
        }
        .padding(.horizontal, 24)
    }

    private var isFormValid: Bool {
        !email.isEmpty && email == confirmEmail && email.contains("@") &&
        password == confirmPassword && password.count >= 8 && passwordMeetsRequirements
    }

    private var passwordMeetsRequirements: Bool {
        password.range(of: "[A-Z]", options: .regularExpression) != nil &&
        password.range(of: "[a-z]", options: .regularExpression) != nil &&
        password.range(of: "[0-9]", options: .regularExpression) != nil &&
        password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil
    }

    private func signUp() {
        focusedField = nil
        loading = true
        errorMessage = ""
        successMessage = ""

        Task {
            do {
                try await authManager.signUp(email: email, password: password)
                successMessage = "Verification code sent!"
                stage = 2
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    private func confirmCode() {
        focusedField = nil
        loading = true
        errorMessage = ""

        Task {
            do {
                try await authManager.confirmSignUp(email: email, code: code)
                try await authManager.signIn(email: email, password: password)
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    private func resendCode() {
        Task {
            do {
                try await authManager.resendConfirmationCode(email: email)
                successMessage = "New code sent!"
            } catch {
                errorMessage = error.localizedDescription
            }
        }
    }
}

// MARK: - Password Requirements Card

struct PasswordRequirementsCard: View {
    let password: String

    private var hasMinLength: Bool { password.count >= 8 }
    private var hasUppercase: Bool { password.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var hasLowercase: Bool { password.range(of: "[a-z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { password.range(of: "[0-9]", options: .regularExpression) != nil }
    private var hasSpecial: Bool { password.range(of: "[^A-Za-z0-9]", options: .regularExpression) != nil }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            RequirementItem(text: "At least 8 characters", isMet: hasMinLength)
            RequirementItem(text: "Uppercase letter", isMet: hasUppercase)
            RequirementItem(text: "Lowercase letter", isMet: hasLowercase)
            RequirementItem(text: "Number", isMet: hasNumber)
            RequirementItem(text: "Special character", isMet: hasSpecial)
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct RequirementItem: View {
    let text: String
    let isMet: Bool

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: isMet ? "checkmark.circle.fill" : "circle")
                .foregroundStyle(isMet ? .green : .white.opacity(0.4))
                .font(.system(size: 14))
            Text(text)
                .font(.caption)
                .foregroundStyle(isMet ? .white : .white.opacity(0.5))
        }
    }
}

// MARK: - FORGOT PASSWORD

struct ForgotPasswordView: View {

    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss

    @State private var email = ""
    @State private var code = ""
    @State private var newPassword = ""
    @State private var confirmPassword = ""
    @State private var stage = 1

    @State private var loading = false
    @State private var errorMessage = ""
    @State private var successMessage = ""

    @FocusState private var focusedField: Field?

    enum Field { case email, code, newPassword, confirmPassword }

    var body: some View {
        ZStack {
            Color(red: 0.05, green: 0.10, blue: 0.15).ignoresSafeArea()

            ScrollView {
                VStack(spacing: 28) {
                    VStack(spacing: 16) {
                        ZStack {
                            Circle()
                                .fill(Color.blue.opacity(0.2))
                                .frame(width: 80, height: 80)
                            Image(systemName: "key.fill")
                                .font(.system(size: 32))
                                .foregroundStyle(.blue)
                        }

                        Text(stage == 1 ? "Reset Password" : "Create New Password")
                            .font(.title.bold())
                            .foregroundColor(.white)

                        Text(stage == 1 ? "Enter your email to receive a reset code" : "Enter the code and your new password")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 40)

                    if stage == 1 { stageOneForm } else { stageTwoForm }

                    if !errorMessage.isEmpty {
                        ErrorBanner(message: errorMessage).padding(.horizontal, 24)
                    }

                    if !successMessage.isEmpty {
                        SuccessBanner(message: successMessage).padding(.horizontal, 24)
                    }

                    Spacer(minLength: 40)
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture { focusedField = nil }
    }

    private var stageOneForm: some View {
        VStack(spacing: 18) {
            ModernTextField(title: "Email", text: $email, icon: "envelope", keyboardType: .emailAddress)
                .focused($focusedField, equals: .email)
                .autocapitalization(.none)

            Button(action: startReset) {
                HStack {
                    if loading { ProgressView().tint(.white) }
                    else { Text("Send Reset Code").font(.headline) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: !email.isEmpty ? [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(email.isEmpty || loading)
        }
        .padding(.horizontal, 24)
    }

    private var stageTwoForm: some View {
        VStack(spacing: 18) {
            ModernTextField(title: "Verification Code", text: $code, icon: "number", keyboardType: .numberPad)
                .focused($focusedField, equals: .code)

            ModernSecureField(title: "New Password", text: $newPassword, icon: "lock")
                .focused($focusedField, equals: .newPassword)

            ModernSecureField(title: "Confirm Password", text: $confirmPassword, icon: "lock.fill")
                .focused($focusedField, equals: .confirmPassword)

            PasswordRequirementsCard(password: newPassword)

            Button(action: confirmReset) {
                HStack {
                    if loading { ProgressView().tint(.white) }
                    else { Text("Reset Password").font(.headline) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(
                        colors: isResetFormValid ? [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
            .disabled(!isResetFormValid || loading)
        }
        .padding(.horizontal, 24)
    }

    private var isResetFormValid: Bool {
        !code.isEmpty && newPassword == confirmPassword && newPassword.count >= 8
    }

    private func startReset() {
        focusedField = nil
        loading = true
        errorMessage = ""

        Task {
            do {
                try await authManager.startPasswordReset(email: email)
                stage = 2
                successMessage = "Code sent to your email"
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }

    private func confirmReset() {
        focusedField = nil
        loading = true
        errorMessage = ""

        Task {
            do {
                try await authManager.confirmPasswordReset(email: email, newPassword: newPassword, code: code)
                successMessage = "Password reset successful!"
                try await Task.sleep(nanoseconds: 1_500_000_000)
                dismiss()
            } catch {
                errorMessage = error.localizedDescription
            }
            loading = false
        }
    }
}

#Preview {
    NavigationStack {
        WelcomeView()
    }
    .environmentObject(AuthenticationManager())
}
