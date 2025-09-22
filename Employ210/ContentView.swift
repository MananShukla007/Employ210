
import SwiftUI
import UIKit
import FirebaseCore
import FirebaseAuth
import FirebaseFirestore

@main
struct Employ210App: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate
    @StateObject private var authManager = AuthenticationManager()
    
    var body: some Scene {
        WindowGroup {
            RootCoordinator()
                .environmentObject(authManager)
        }
    }
}

class AppDelegate: NSObject, UIApplicationDelegate {
    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        return true
    }
}

@MainActor
class AuthenticationManager: ObservableObject {
    @Published var currentUser: User?
    @Published var userRole: UserRole = .member
    @Published var isAuthenticated = false
    
    private let db = Firestore.firestore()
    
    enum UserRole: String, CaseIterable {
        case member
        case trainer
        case admin
        
        var displayName: String {
            rawValue.capitalized
        }
    }
    
    init() {
        checkAuthenticationState()
    }
    
    func checkAuthenticationState() {
        if let user = Auth.auth().currentUser, user.isEmailVerified {
            currentUser = user
            isAuthenticated = true
            fetchUserRole(uid: user.uid)
        }
    }
    
    func signIn(email: String, password: String) async throws {
        let authResult = try await Auth.auth().signIn(withEmail: email, password: password)
        
        guard authResult.user.isEmailVerified else {
            try Auth.auth().signOut()
            throw AuthError.emailNotVerified
        }
        
        currentUser = authResult.user
        isAuthenticated = true
        fetchUserRole(uid: authResult.user.uid)
    }
    
    func signUp(email: String, password: String, role: UserRole) async throws {
        let authResult = try await Auth.auth().createUser(withEmail: email, password: password)
        let user = authResult.user
        
        try await db.collection("users").document(user.uid).setData([
            "email": email,
            "role": role.rawValue,
            "createdAt": FieldValue.serverTimestamp()
        ])
        
        try await user.sendEmailVerification()
    }
    
    func sendPasswordReset(email: String) async throws {
        try await Auth.auth().sendPasswordReset(withEmail: email)
    }
    
    func signOut() throws {
        try Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
        userRole = .member
    }
    
    private func fetchUserRole(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] snapshot, error in
            guard let data = snapshot?.data(),
                  let roleString = data["role"] as? String,
                  let role = UserRole(rawValue: roleString) else { return }
            
            DispatchQueue.main.async {
                self?.userRole = role
            }
        }
    }
}

enum AuthError: LocalizedError {
    case emailNotVerified
    case invalidCredentials
    case networkError
    
    var errorDescription: String? {
        switch self {
        case .emailNotVerified:
            return "Please verify your email address before logging in."
        case .invalidCredentials:
            return "Invalid email or password."
        case .networkError:
            return "Network connection error. Please try again."
        }
    }
}

struct RootCoordinator: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSplash = true
    
    var body: some View {
        ZStack {
            if showSplash {
                SplashView()
                    .transition(.opacity)
            } else {
                if authManager.isAuthenticated {
                    MainTabView()
                        .transition(.opacity)
                } else {
                    NavigationStack {
                        WelcomeView()
                    }
                    .transition(.opacity)
                }
            }
        }
        .task {
            try? await Task.sleep(nanoseconds: 2_000_000_000)
            withAnimation(.easeInOut(duration: 0.5)) {
                showSplash = false
            }
        }
    }
}

struct SplashView: View {
    var body: some View {
        ZStack {
            Color(.systemBackground)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                Image("Employ210")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                Text("Employ 210")
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .foregroundStyle(
                        LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing)
                    )
                
                ProgressView()
                    .scaleEffect(1.2)
                    .tint(.blue)
            }
        }
    }
}

struct WelcomeView: View {
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 24) {
                Image("Employ210")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 160, height: 160)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                VStack(spacing: 8) {
                    Text("Welcome to")
                        .font(.title3)
                        .foregroundColor(.secondary)
                    
                    Text("Employ 210")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                }
            }
            
            Spacer()
            
            VStack(spacing: 16) {
                NavigationLink(destination: LoginView()) {
                    Text("Sign In")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                NavigationLink(destination: SignUpView()) {
                    Text("Create Account")
                        .font(.headline)
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(Color.blue.opacity(0.1))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                NavigationLink(destination: ForgotPasswordView()) {
                    Text("Forgot Password?")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .padding(.top, 8)
                }
            }
            .padding(.horizontal, 32)
            .padding(.bottom, 50)
        }
        .navigationBarBackButtonHidden(true)
    }
}

struct LoginView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var password = ""
    @State private var errorMessage = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image("Employ210")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    Text("Welcome Back")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Sign in to continue")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    CustomTextField(title: "Email",
                                    text: $email,
                                    placeholder: "name@example.com",
                                    keyboardType: .emailAddress,
                                    focusedField: _focusedField,
                                    field: .email)
                    
                    CustomSecureField(title: "Password",
                                      text: $password,
                                      focusedField: _focusedField,
                                      field: .password)
                    
                    if !errorMessage.isEmpty {
                        ErrorMessageView(message: errorMessage)
                    }
                }
                
                Button {
                    signIn()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Sign In")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(!isFormValid || isLoading)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { focusedField = nil }
    }
    
    private func signIn() {
        focusedField = nil
        errorMessage = ""
        isLoading = true
        
        Task {
            do { try await authManager.signIn(email: email, password: password) }
            catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }
}

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) var dismiss
    
    @State private var email = ""
    @State private var confirmEmail = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole: AuthenticationManager.UserRole = .member
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false
    @FocusState private var focusedField: Field?
    
    enum Field { case email, confirmEmail, password, confirmPassword }
    
    private var isFormValid: Bool {
        !email.isEmpty && !confirmEmail.isEmpty &&
        !password.isEmpty && !confirmPassword.isEmpty &&
        email == confirmEmail && password == confirmPassword &&
        email.contains("@") && password.count >= 6
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image("Employ210")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 120, height: 120)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    
                    Text("Create Account")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Sign up to get started")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.top, 40)
                
                VStack(spacing: 20) {
                    CustomTextField(title: "Email",
                                    text: $email,
                                    placeholder: "name@example.com",
                                    keyboardType: .emailAddress,
                                    focusedField: _focusedField,
                                    field: .email)
                    
                    CustomTextField(title: "Confirm Email",
                                    text: $confirmEmail,
                                    placeholder: "name@example.com",
                                    keyboardType: .emailAddress,
                                    focusedField: _focusedField,
                                    field: .confirmEmail)
                    
                    CustomSecureField(title: "Password",
                                      text: $password,
                                      focusedField: _focusedField,
                                      field: .password)
                    
                    CustomSecureField(title: "Confirm Password",
                                      text: $confirmPassword,
                                      focusedField: _focusedField,
                                      field: .confirmPassword)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Account Type")
                            .font(.subheadline)
                            .fontWeight(.semibold)
                        
                        Picker("Role", selection: $selectedRole) {
                            ForEach(AuthenticationManager.UserRole.allCases, id: \.self) { role in
                                Text(role.displayName).tag(role)
                            }
                        }
                        .pickerStyle(.segmented)
                    }
                    
                    if !errorMessage.isEmpty { ErrorMessageView(message: errorMessage) }
                    if !successMessage.isEmpty { SuccessMessageView(message: successMessage) }
                }
                
                Button {
                    signUp()
                } label: {
                    if isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                    else { Text("Create Account").font(.headline) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(isFormValid ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(!isFormValid || isLoading)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { focusedField = nil }
    }
    
    private func signUp() {
        focusedField = nil
        errorMessage = ""
        successMessage = ""
        isLoading = true
        
        Task {
            do {
                try await authManager.signUp(email: email, password: password, role: selectedRole)
                successMessage = "Account created! Please check your email to verify your account."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
            } catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }
}

struct ForgotPasswordView: View {
    @Environment(\.dismiss) var dismiss
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false
    @FocusState private var isEmailFocused: Bool
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                VStack(spacing: 16) {
                    Image(systemName: "lock.circle.fill")
                        .font(.system(size: 80))
                        .foregroundStyle(LinearGradient(colors: [.blue, .cyan], startPoint: .topLeading, endPoint: .bottomTrailing))
                    
                    Text("Reset Password")
                        .font(.system(size: 28, weight: .bold))
                    
                    Text("Enter your email address and we'll send you a link to reset your password")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 60)
                
                VStack(spacing: 20) {
                    CustomTextField<Bool>(
                        title: "Email",
                        text: $email,
                        placeholder: "name@example.com",
                        keyboardType: .emailAddress,
                        field: true
                    )
                    
                    if !errorMessage.isEmpty { ErrorMessageView(message: errorMessage) }
                    if !successMessage.isEmpty { SuccessMessageView(message: successMessage) }
                }
                
                Button {
                    sendPasswordReset()
                } label: {
                    if isLoading { ProgressView().progressViewStyle(CircularProgressViewStyle(tint: .white)) }
                    else { Text("Send Reset Link").font(.headline) }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(!email.isEmpty && email.contains("@") ? Color.blue : Color.gray)
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .disabled(email.isEmpty || !email.contains("@") || isLoading)
                
                Spacer()
            }
            .padding(.horizontal, 32)
        }
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { isEmailFocused = false }
    }
    
    private func sendPasswordReset() {
        isEmailFocused = false
        errorMessage = ""
        successMessage = ""
        isLoading = true
        
        Task {
            do {
                try await Auth.auth().sendPasswordReset(withEmail: email)
                successMessage = "Password reset link sent! Check your email."
                DispatchQueue.main.asyncAfter(deadline: .now() + 2) { dismiss() }
            } catch { errorMessage = error.localizedDescription }
            isLoading = false
        }
    }
}

struct HomeView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    Text("Dashboard")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                }
                .padding()
            }
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct ProfileView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showingSignOutAlert = false
    
    var body: some View {
        NavigationStack {
            List {
                Section {
                    HStack {
                        Image(systemName: "person.circle.fill")
                            .font(.system(size: 50))
                            .foregroundColor(.blue)
                        
                        VStack(alignment: .leading, spacing: 4) {
                            Text(authManager.currentUser?.email ?? "User")
                                .font(.headline)
                            
                            Text(authManager.userRole.displayName)
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                        }
                    }
                    .padding(.vertical, 8)
                }
                
                Section("Settings") {
                    NavigationLink {
                        Text("Account Settings")
                    } label: {
                        Label("Account", systemImage: "person.circle")
                    }
                    
                    NavigationLink {
                        Text("Notifications")
                    } label: {
                        Label("Notifications", systemImage: "bell")
                    }
                    
                    NavigationLink {
                        Text("Privacy")
                    } label: {
                        Label("Privacy", systemImage: "lock.shield")
                    }
                }
                
                Section {
                    Button(role: .destructive) {
                        showingSignOutAlert = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                }
            }
            .navigationTitle("Profile")
            .alert("Sign Out", isPresented: $showingSignOutAlert) {
                Button("Cancel", role: .cancel) { }
                Button("Sign Out", role: .destructive) {
                    try? authManager.signOut()
                }
            } message: {
                Text("Are you sure you want to sign out?")
            }
        }
    }
}

struct MainTabView: View {
    @EnvironmentObject var authManager: AuthenticationManager
    
    var body: some View {
        TabView {
            HomeView()
                .tabItem {
                    Label("Home", systemImage: "house.fill")
                }
            
            if authManager.userRole == .trainer {
                TrainingView()
                    .tabItem {
                        Label("Training", systemImage: "figure.strengthtraining.traditional")
                    }
            }
            
            if authManager.userRole == .admin {
                AdminView() // Only here
                    .tabItem {
                        Label("Admin", systemImage: "gear.circle.fill")
                    }
            }
            
            ProfileView()
                .tabItem {
                    Label("Profile", systemImage: "person.circle.fill")
                }
        }
    }
}

struct CustomTextField<FocusedField: Hashable>: View {
    let title: String
    @Binding var text: String
    let placeholder: String
    var keyboardType: UIKeyboardType = .default
    @FocusState var focusedField: FocusedField?
    var field: FocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            if let fieldValue = field {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .autocapitalization(.none)
                    .keyboardType(keyboardType)
                    .focused($focusedField, equals: fieldValue)
            } else {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .autocapitalization(.none)
                    .keyboardType(keyboardType)
            }
        }
    }
}

struct CustomSecureField<FocusedField: Hashable>: View {
    let title: String
    @Binding var text: String
    @FocusState var focusedField: FocusedField?
    var field: FocusedField?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)

            if let fieldValue = field {
                SecureField("Enter password", text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .focused($focusedField, equals: fieldValue)
            } else {
                SecureField("Enter password", text: $text)
                    .textFieldStyle(.plain)
                    .padding()
                    .background(Color(.systemGray6))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
    }
}

struct ErrorMessageView: View {
    let message: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.circle.fill")
            Text(message).font(.subheadline)
            Spacer()
        }
        .foregroundColor(.red)
        .padding()
        .background(Color.red.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct SuccessMessageView: View {
    let message: String
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "checkmark.circle.fill")
            Text(message).font(.subheadline)
            Spacer()
        }
        .foregroundColor(.green)
        .padding()
        .background(Color.green.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

extension View {
    func hideKeyboard() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
    }
}
