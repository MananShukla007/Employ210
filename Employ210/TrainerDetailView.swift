//
//  TrainerDetailView.swift
//  Employ210
//
//  Trainer Detail - Shows trainer info and their trainees
//

import SwiftUI

struct TrainerDetailView: View {
    
    let trainer: Trainer
    @ObservedObject var store: TraineeStore
    
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showAddTraineeSheet = false
    @State private var showSignOutConfirm = false
    @State private var showDeleteConfirm = false
    @State private var traineeToDelete: Trainee?
    @State private var searchText = ""
    
    // Get the latest trainer data from store
    var currentTrainer: Trainer {
        store.getTrainer(by: trainer.id) ?? trainer
    }
    
    var filteredTrainees: [Trainee] {
        if searchText.isEmpty {
            return currentTrainer.trainees
        }
        return currentTrainer.trainees.filter { $0.fullName.localizedCaseInsensitiveContains(searchText) }
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
            
            ScrollView {
                VStack(spacing: 24) {
                    // Trainer Profile Card
                    VStack(spacing: 16) {
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
                                .frame(width: 90, height: 90)
                            
                            Text(currentTrainer.initials)
                                .font(.system(size: 32, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(currentTrainer.fullName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            HStack(spacing: 6) {
                                Image(systemName: "person.2.fill")
                                    .font(.caption)
                                Text("\(currentTrainer.trainees.count) trainee\(currentTrainer.trainees.count == 1 ? "" : "s")")
                                    .font(.subheadline)
                            }
                            .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 24)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Add Trainee Button
                    Button {
                        showAddTraineeSheet = true
                    } label: {
                        HStack(spacing: 12) {
                            ZStack {
                                Circle()
                                    .fill(Color.white.opacity(0.2))
                                    .frame(width: 50, height: 50)
                                
                                Image(systemName: "person.badge.plus")
                                    .font(.system(size: 22))
                                    .foregroundColor(.white)
                            }
                            
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Add Trainee")
                                    .font(.title3.bold())
                                    .foregroundColor(.white)
                                
                                Text("Add a new trainee to this trainer")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.7))
                            }
                            
                            Spacer()
                            
                            Image(systemName: "plus.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(.white.opacity(0.6))
                        }
                        .padding(20)
                        .background(
                            LinearGradient(
                                colors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .shadow(color: Color.blue.opacity(0.4), radius: 10, x: 0, y: 5)
                    }
                    .padding(.horizontal, 24)
                    
                    // Trainees Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Trainees")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if !currentTrainer.trainees.isEmpty {
                                Text("\(currentTrainer.trainees.count)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.teal)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.teal.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        // Search bar (if trainees exist)
                        if !currentTrainer.trainees.isEmpty {
                            HStack(spacing: 12) {
                                Image(systemName: "magnifyingglass")
                                    .foregroundStyle(.white.opacity(0.5))
                                
                                TextField("Search trainees...", text: $searchText)
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
                        
                        if currentTrainer.trainees.isEmpty {
                            // Empty State
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "person.crop.circle.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                
                                Text("No Trainees Yet")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Tap 'Add Trainee' above to add one")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            // Trainee List
                            LazyVStack(spacing: 12) {
                                ForEach(filteredTrainees) { trainee in
                                    TraineeNavigationRow(
                                        trainee: trainee,
                                        trainerId: trainer.id,
                                        onDelete: {
                                            traineeToDelete = trainee
                                            showDeleteConfirm = true
                                        }
                                    )
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationTitle(currentTrainer.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                // Hamburger Menu
                Menu {
                    Button {
                        showAddTraineeSheet = true
                    } label: {
                        Label("Add Trainee", systemImage: "person.badge.plus")
                    }
                    
                    Divider()
                    
                    Button(role: .destructive) {
                        showSignOutConfirm = true
                    } label: {
                        Label("Sign Out", systemImage: "rectangle.portrait.and.arrow.right")
                    }
                } label: {
                    Image(systemName: "line.3.horizontal")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 36, height: 36)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
            }
        }
        .toolbarColorScheme(.dark, for: .navigationBar)
        .sheet(isPresented: $showAddTraineeSheet) {
            AddTraineeToTrainerSheet(trainerId: trainer.id, store: store)
        }
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .alert("Delete Trainee", isPresented: $showDeleteConfirm) {
            Button("Cancel", role: .cancel) {
                traineeToDelete = nil
            }
            Button("Delete", role: .destructive) {
                if let trainee = traineeToDelete {
                    store.removeTrainee(from: trainer.id, traineeId: trainee.id)
                    traineeToDelete = nil
                }
            }
        } message: {
            if let trainee = traineeToDelete {
                Text("Are you sure you want to delete \(trainee.fullName)?")
            } else {
                Text("Are you sure you want to delete this trainee?")
            }
        }
    }
}

// MARK: - Trainee Row Card

struct TraineeRowCard: View {
    let trainee: Trainee
    let onDelete: () -> Void
    
    var body: some View {
        HStack(spacing: 14) {
            // Avatar
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            colors: [Color.blue.opacity(0.4), Color.teal.opacity(0.4)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 50, height: 50)
                
                Text(trainee.initials)
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            // Info
            VStack(alignment: .leading, spacing: 4) {
                Text(trainee.fullName)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Text("Added \(trainee.createdAt.formatted(date: .abbreviated, time: .omitted))")
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            Spacer()
            
            // Delete menu
            Menu {
                Button(role: .destructive) {
                    onDelete()
                } label: {
                    Label("Delete Trainee", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(.white.opacity(0.5))
                    .frame(width: 28, height: 28)
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

// MARK: - Add Trainee to Trainer Sheet

struct AddTraineeToTrainerSheet: View {
    let trainerId: String
    @ObservedObject var store: TraineeStore
    
    @Environment(\.dismiss) var dismiss
    
    @State private var firstName = ""
    @State private var lastName = ""
    
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
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 20)
                    
                    Text("Add New Trainee")
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
                        store.addTrainee(
                            to: trainerId,
                            firstName: firstName.trimmingCharacters(in: .whitespaces),
                            lastName: lastName.trimmingCharacters(in: .whitespaces)
                        )
                        dismiss()
                    } label: {
                        Text("Add Trainee")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: isFormValid ?
                                        [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)] :
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
        TrainerDetailView(
            trainer: Trainer(
                id: "1",
                firstName: "John",
                lastName: "Smith",
                createdAt: Date(),
                trainees: [
                    Trainee(id: "t1", firstName: "Alice", lastName: "Johnson", createdAt: Date()),
                    Trainee(id: "t2", firstName: "Bob", lastName: "Williams", createdAt: Date())
                ]
            ),
            store: TraineeStore()
        )
        .environmentObject(AuthenticationManager())
    }
}

#Preview("Add Trainee Sheet") {
    AddTraineeToTrainerSheet(trainerId: "trainer-1", store: TraineeStore())
}

// MARK: - Trainee Navigation Row (Helper to simplify compiler)

struct TraineeNavigationRow: View {
    let trainee: Trainee
    let trainerId: String
    let onDelete: () -> Void
    
    var body: some View {
        NavigationLink {
            TraineeDetailView(trainee: trainee, trainerId: trainerId)
        } label: {
            TraineeRowCard(trainee: trainee, onDelete: onDelete)
        }
        .buttonStyle(.plain)
    }
}
