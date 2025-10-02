//
//  UserManager.swift
//  Employ210
//
//  Created by Aiden Panter on 10/2/25.
//

import Foundation
import FirebaseFirestore

struct UserModel: Identifiable, Codable {
    var id: String = UUID().uuidString
    var name: String
    var email: String
}

class UserManager: ObservableObject {
    private let db = Firestore.firestore()
    
    @Published var users: [UserModel] = []
    
    func fetchUsers() {
        db.collection("users").getDocuments { snapshot, error in
            if let error = error {
                print("Error fetching users: \(error)")
                return
            }
            self.users = snapshot?.documents.compactMap { doc -> UserModel? in
                let data = doc.data()
                let name = data["name"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                return UserModel(id: doc.documentID, name: name, email: email)
            } ?? []
        }
    }
    
    func addUser(name: String, email: String, completion: @escaping (Error?) -> Void) {
        let newUser = ["name": name, "email": email]
        db.collection("users").addDocument(data: newUser) { error in
            if error == nil {
                self.fetchUsers()
            }
            completion(error)
        }
    }
    
    func deleteUser(id: String) {
        db.collection("users").document(id).delete { error in
            if let error = error {
                print("Error deleting user: \(error)")
            } else {
                self.fetchUsers()
            }
        }
    }
}
