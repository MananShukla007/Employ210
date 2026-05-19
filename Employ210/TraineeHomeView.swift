//
//  TraineeHomeView.swift
//  //  Employ210
//
//  Created by Manan Shukla

//
//  Trainee Dashboard - Access training programs
//

import SwiftUI

struct TraineeHomeView: View {
    
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    
    @State private var showSignOutConfirm = false
    @State private var showMyPrograms = false
    @State private var showMyProgress = false
    
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
                            Text("My Training")
                                .font(.system(size: 28, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if !authManager.userEmail.isEmpty {
                                Text(authManager.userEmail)
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                        
                        Spacer()
                        
                        // Hamburger Menu
                        Menu {
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
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
                
                // Quick Actions
                HStack(spacing: 12) {
                    // My Programs
                    Button {
                        showMyPrograms = true
                    } label: {
                        QuickActionCard(
                            title: "My Programs",
                            icon: "doc.text.fill",
                            color: .blue
                        )
                    }
                    
                    // My Progress
                    Button {
                        showMyProgress = true
                    } label: {
                        QuickActionCard(
                            title: "My Progress",
                            icon: "chart.line.uptrend.xyaxis",
                            color: .green
                        )
                    }
                }
                .padding(.horizontal, 24)
                
                Spacer()
                
                // Info Card
                VStack(spacing: 16) {
                    ZStack {
                        Circle()
                            .fill(Color.teal.opacity(0.15))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "person.crop.circle.badge.checkmark")
                            .font(.system(size: 36))
                            .foregroundStyle(.teal)
                    }
                    
                    Text("Welcome, Trainee!")
                        .font(.title3.bold())
                        .foregroundColor(.white)
                    
                    Text("Access your assigned programs and track your progress using the options above.")
                        .font(.subheadline)
                        .foregroundStyle(.white.opacity(0.6))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 40)
                }
                
                Spacer()
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
        .alert("Sign Out", isPresented: $showSignOutConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Sign Out", role: .destructive) {
                authManager.signOut()
            }
        } message: {
            Text("Are you sure you want to sign out?")
        }
        .sheet(isPresented: $showMyPrograms) {
            WorkInProgressView(
                title: "My Programs",
                icon: "doc.text.fill",
                color: .blue
            )
        }
        .sheet(isPresented: $showMyProgress) {
            WorkInProgressView(
                title: "My Progress",
                icon: "chart.line.uptrend.xyaxis",
                color: .green
            )
        }
    }
}

// MARK: - Quick Action Card

struct QuickActionCard: View {
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(color.opacity(0.2))
                    .frame(width: 50, height: 50)
                
                Image(systemName: icon)
                    .font(.system(size: 22))
                    .foregroundColor(color)
            }
            
            Text(title)
                .font(.subheadline.bold())
                .foregroundColor(.white)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 20)
        .background(Color.white.opacity(0.06))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
    }
}

// MARK: - Work In Progress View

struct WorkInProgressView: View {
    @Environment(\.dismiss) private var dismiss
    
    let title: String
    let icon: String
    let color: Color
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 32) {
                    Spacer()
                    
                    // Warning Icon
                    ZStack {
                        Circle()
                            .fill(Color.red.opacity(0.15))
                            .frame(width: 120, height: 120)
                        
                        Circle()
                            .fill(Color.red.opacity(0.1))
                            .frame(width: 160, height: 160)
                        
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.system(size: 60))
                            .foregroundStyle(.red)
                    }
                    
                    // Title is the opening shi is the sw igma
                    VStack(spacing: 12) {
                        Text(title)
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Work In Progress")
                            .font(.title2.bold())
                            .foregroundStyle(.red)
                    }
                    
                    // Description
                    VStack(spacing: 16) {
                        HStack(spacing: 8) {
                            Image(systemName: "wrench.and.screwdriver.fill")
                                .foregroundStyle(.orange)
                            Text("Under Development")
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .font(.headline)
                        
                        Text("This feature is currently being built and will be available in a future update.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.5))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 40)
                    }
                    
                    // Status Card
                    HStack(spacing: 12) {
                        Image(systemName: "clock.fill")
 
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Coming Soon")
                                .font(.headline)
                                .foregroundColor(.white)
                            Text("Check back later for updates")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.5))
                        }
                        
                        Spacer()
                        
                        Image(systemName: "hourglass")
                            .font(.title2)
                            .foregroundStyle(.orange.opacity(0.5))
                    }
                    .padding(20)
                    .background(Color.orange.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color.orange.opacity(0.3), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Close Button
                    Button {
                        dismiss()
                    } label: {
                        Text("Close")
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.1))
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.2), lineWidth: 1)
                            )
                    }
                    .padding(.horizontal, 24)
                    .padding(.bottom, 30)
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Preview

#Preview("Trainee Home") {
    NavigationStack {
        TraineeHomeView()
            .environmentObject(AuthenticationManager())
    }
}

#Preview("Work In Progress") {
    WorkInProgressView(
        title: "My Programs",
        icon: "doc.text.fill",
        color: .blue
    )
}
