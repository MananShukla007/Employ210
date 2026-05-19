//
//  AdminView.swift
//  Employ210
//
//  Created by Manan Shukla 

import SwiftUI

struct AdminView: View {
    var body: some View {
        NavigationStack {
            VStack(spacing: 32) {
                Text("Admin Dashboard")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                NavigationLink {
                    SearchUserView()
                } label: {
                    Text("Search User")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient(colors: [.blue, .cyan], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                NavigationLink {
                    AddUserView()
                } label: {
                    Text("Add User")
                        .font(.headline)
                        .foregroundColor(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 56)
                        .background(LinearGradient(colors: [.green, .mint], startPoint: .leading, endPoint: .trailing))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                }
                
                Spacer()
            }
            .padding(.horizontal, 32)
            .navigationTitle("Admin")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

struct SearchUserView: View {
    @State private var searchText = ""
    
    @State private var users = [
        "alice@example.com",
        "bob@example.com",
        "charlie@example.com",
        "david@example.com"
    ]
    
    var filteredUsers: [String] {
        if searchText.isEmpty {
            return users
        } else {
            return users.filter { $0.lowercased().contains(searchText.lowercased()) }
        }
    }
    
    var body: some View {
        VStack {
            TextField("Search by name or email", text: $searchText)
                .padding(12)
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .padding(.horizontal)
            
            List {
                if filteredUsers.isEmpty {
                    Text("No users found")
                        .foregroundColor(.secondary)
                } else {
                    ForEach(filteredUsers, id: \.self) { user in
                        HStack {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(.blue)
                                .font(.system(size: 28))
                            Text(user)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Search User")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct AddUserView: View {
    @State private var name = ""
    @State private var email = ""
    @State private var errorMessage = ""
    @State private var successMessage = ""
    @State private var isLoading = false
    
    @FocusState private var focusedField: Field?
    
    enum Field {
        case name, email
    }
    
    private var isFormValid: Bool {
        !name.isEmpty && !email.isEmpty && email.contains("@")
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 32) {
                Text("Add New User")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.top, 40)
                
                VStack(spacing: 20) {
                    TextField("Full Name", text: $name)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .autocapitalization(.words)
                        .focused($focusedField, equals: .name)
                    
                    TextField("Email Address", text: $email)
                        .padding()
                        .background(Color(.systemGray6))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .autocapitalization(.none)
                        .keyboardType(.emailAddress)
                        .focused($focusedField, equals: .email)
                    
                    if !errorMessage.isEmpty {
                        ErrorMessageView(message: errorMessage)
                    }
                    if !successMessage.isEmpty {
                        SuccessMessageView(message: successMessage)
                    }
                }
                
                Button {
                    createUser()
                } label: {
                    if isLoading {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                    } else {
                        Text("Create User")
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
        .navigationTitle("Add User")
        .navigationBarTitleDisplayMode(.inline)
        .onTapGesture { focusedField = nil }
    }
    
    private func createUser() {
        focusedField = nil
        errorMessage = ""
        successMessage = ""
        isLoading = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            isLoading = false
            successMessage = "User \(name) created successfully!"
            name = ""
            email = ""
        }
    }
}

// MARK: - Helper Views


#Preview {
    AdminView()
}
