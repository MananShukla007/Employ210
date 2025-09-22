import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import Combine
import UIKit
import FirebaseCore
import FirebaseFirestore

enum UserType: String {
    case member = "member"
    case trainer = "trainer"
    case admin = "admin"
    case none
}

class AuthManager: ObservableObject {
    @Published var isAuthenticated: Bool = false
    @Published var userType: UserType = .none
    @Published var currentUserID: String? = nil

    private var authHandle: AuthStateDidChangeListenerHandle?
    private let db = Firestore.firestore()

    init() {
        authHandle = Auth.auth().addStateDidChangeListener { [weak self] auth, user in
            guard let self = self else { return }
            
            if let user = user, user.isEmailVerified {
                self.currentUserID = user.uid
                self.isAuthenticated = true
                self.fetchUserType(uid: user.uid)
            } else {
                self.currentUserID = nil
                self.isAuthenticated = false
                self.userType = .none
            }
        }
    }

    deinit {
        if let handle = authHandle {
            Auth.auth().removeStateDidChangeListener(handle)
        }
    }
    func signUp(email: String, password: String, role: UserType, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found after signup."])))
                return
            }

            self.db.collection("users").document(user.uid).setData([
                "role": role.rawValue,
                "email": email
            ], merge: true) { error in
                if let error = error {
                    print("Error saving role: \(error.localizedDescription)")
                } else {
                    print("User role saved: \(role.rawValue)")
                }
            }

            user.sendEmailVerification { error in
                if let error = error {
                    completion(.failure(error))
                } else {
                    completion(.success(()))
                }
            }
        }
    }
    func login(email: String, password: String, completion: @escaping (Result<Void, Error>) -> Void) {
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }

            if let error = error {
                completion(.failure(error))
                return
            }

            guard let user = result?.user else {
                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "User not found after login."])))
                return
            }

            if user.isEmailVerified {
                self.currentUserID = user.uid
                self.isAuthenticated = true
                self.fetchUserType(uid: user.uid)
                completion(.success(()))
            } else {
                do {
                    try Auth.auth().signOut()
                } catch { print("SignOut error: \(error.localizedDescription)") }
                completion(.failure(NSError(domain: "AuthManager", code: -1, userInfo: [NSLocalizedDescriptionKey: "Please verify your email before logging in."])))
            }
        }
    }
    func fetchUserType(uid: String) {
        db.collection("users").document(uid).getDocument { [weak self] document, error in
            guard let self = self else { return }
            if let document = document, document.exists,
               let roleString = document.data()?["role"] as? String,
               let role = UserType(rawValue: roleString) {
                DispatchQueue.main.async { self.userType = role }
            } else {
                DispatchQueue.main.async { self.userType = .member }
                if let error = error { print("Error fetching role: \(error.localizedDescription)") }
            }
        }
    }
    func signOut() {
        do {
            try Auth.auth().signOut()
            DispatchQueue.main.async {
                self.isAuthenticated = false
                self.userType = .none
                self.currentUserID = nil
            }
        } catch {
            print("SignOut error: \(error.localizedDescription)")
        }
    }
}


