//
//  TrainerHomeView.swift
//  Employ210
//
//  Created by Manan Shukla
//
//  Trainer Dashboard - List of trainers, tap to see their trainees
//

import SwiftUI

struct TrainerHomeView: View {
    
    @EnvironmentObject var authManager: AuthenticationManager
    @StateObject private var store = TraineeStore()
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddTrainerSheet = false
    @State private var searchText = ""
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var trainerToDelete: Trainer?
    
    var filteredTrainers: [Trainer] {
        if searchText.isEmpty {
            return store.trainers
        }
        return store.trainers.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
    }
    
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
            
            VStack(spacing: 0) {
                // Header
                VStack(spacing: 16) {
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text("Trainer Dashboard")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            Text("\(store.trainers.count) trainer\(store.trainers.count == 1 ? "" : "s")")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        
                        Spacer()
                        
                        // Hamburger Menu
                        Menu {
                            Button {
                                showAddTrainerSheet = true
                            } label: {
                                Label("Add Trainer", systemImage: "person.badge.plus")
                            }
                            
                            Divider()
                            
                            Button {
                                dismiss()
                            } label: {
                                Label("Main Menu", systemImage: "house.fill")
                            }
                            
                            Divider()
                            
                            Button(role: .destructive) {
                                showSignOutConfirm = true
                            } label: {
                                Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                            }
                        } label: {
                            Image(systemName: "line.3.horizontal")
                                .font(.system(size: 18, weight: .medium))
                                .foregroundColor(.white)
                                .frame(width: 44, height: 44)
                                .background(Color.white.opacity(0.1))
                                .clipShape(Circle())
                        }
                    }
                    
                    // Search Bar (only show if there are trainers)
                    if !store.trainers.isEmpty {
                        HStack(spacing: 12) {
                            Image(systemName: "magnifyingglass")
                                .foregroundStyle(.white.opacity(0.5))
                            
                            TextField("Search trainers...", text: $searchText)
                                .foregroundColor(.white)
                                .tint(.white)
                            
                            if !searchText.isEmpty {
                                Button {
                                    searchText = ""
                                } label: {
                                    Image(systemName: "xmark.circle.fill")
                                        .foregroundStyle(.white.opacity(0.5))
                                }
                            }
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 12)
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 20)
                
                // Content
                if store.trainers.isEmpty {
                    Spacer()
                    
                    // Empty State
                    VStack(spacing: 20) {
                        ZStack {
                            Circle()
                                .fill(Color.teal.opacity(0.1))
                                .frame(width: 120, height: 120)
                            
                            Image(systemName: "person.2.badge.plus")
                                .font(.system(size: 50))
                                .foregroundStyle(.teal.opacity(0.6))
                        }
                        
                        VStack(spacing: 8) {
                            Text("No Trainers Yet")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Add your first trainer to get started")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        
                        Button {
                            showAddTrainerSheet = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "plus.circle.fill")
                                Text("Add Trainer")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 28)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.3, green: 0.7, blue: 0.6), Color(red: 0.2, green: 0.5, blue: 0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.teal.opacity(0.3), radius: 10, x: 0, y: 5)
                        }
                    }
                    
                    Spacer()
                } else {
                    // Trainer List
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Select a Trainer")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.7))
                            .padding(.horizontal, 24)
                        
                        ScrollView {
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTrainers) { trainer in
                                    NavigationLink(destination: TrainerDetailView(trainer: trainer, store: store)) {
                                        TrainerRowCard(
                                            trainer: trainer,
                                            onDelete: {
                                                trainerToDelete = trainer
                                                showDeleteConfirm = true
                                            }
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                            .padding(.horizontal, 24)
                            .padding(.bottom, 100)
                        }
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button {
                    dismiss()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Back")
                    }
                    .foregroundColor(.white)
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddTrainerSheet) {
            AddTrainerSheet { firstName, lastName in
                store.addTrainer(firstName: firstName, lastName: lastName)
            }
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Trainer", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {
                trainerToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let trainer = trainerToDelete {
                    store.removeTrainer(trainer)
                    trainerToDelete = nil
                }
            }
        } message: {
            if let trainer = trainerToDelete {
                Text("Are you sure you want to delete \(trainer.fullName) and all their trainees?")
            } else {
                Text("Are you sure you want to delete this trainer?")
            }
        }
    }
}

// MARK: - Trainer Row Card

struct TrainerRowCard: View {
    let trainer: Trainer
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.teal.opacity(0.5), Color.green.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 54, height: 54)
                
                Text(trainer.initials)
                    .font(.headline.bold())
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(trainer.fullName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                HStack(spacing: 4) {
                    Image(systemName: "person.2.fill")
                        .font(.caption2)
                    Text("\(trainer.trainees.count) trainee\(trainer.trainees.count == 1 ? "" : "s")")
                        .font(.caption)
                }
                .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Delete button (3-dot menu)
            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Trainer", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 32, height: 32)
                    .background(Color.white.opacity(0.05))
                    .clipShape(Circle())
            }
            
            // Chevron
            Image(systemName: "chevron.right")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white.opacity(0.4))
        }
        .padding(16)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Add Trainer Sheet

struct AddTrainerSheet: View {
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    @State private var isLoading = false
    
    let onAdd: (String, String) -> Void
    
    var isFormValid: Bool {
        !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
        !lastName.trimmingCharacters(in: .whitespaces).isEmpty
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Icon
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.teal)
                    }
                    .padding(.top, 20)
                    
                    Text("Add New Trainer")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    // Form
                    VStack(spacing: 16) {
                        ModernTextField(
                            title: "First Name",
                            text: $firstName,
                            icon: "person"
                        )
                        
                        ModernTextField(
                            title: "Last Name",
                            text: $lastName,
                            icon: "person"
                        )
                    }
                    .padding(.horizontal, 24)
                    
                    // Add Button
                    Button {
                        onAdd(
                            firstName.trimmingCharacters(in: .whitespaces),
                            lastName.trimmingCharacters(in: .whitespaces)
                        )
                        dismiss()
                    } label: {
                        Text("Add Trainer")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: isFormValid ?
                                        [Color(red: 0.3, green: 0.7, blue: 0.6), Color(red: 0.2, green: 0.5, blue: 0.5)] :
                                        [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                    }
                    .disabled(!isFormValid)
                    .padding(.horizontal, 24)
                    
                    Spacer()
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.white.opacity(0.7))
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TrainerHomeView()
            .environmentObject(AuthenticationManager())
    }
}
