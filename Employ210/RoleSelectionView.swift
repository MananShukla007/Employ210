//
//  RoleSelectionView.swift
//  //  Employ210
//
//  Created by Manan Shukla

//
//  Main Home Screen - Shown after successful login
//

import SwiftUI

struct RoleSelectionView: View {
    
    @EnvironmentObject var authManager: AuthenticationManager
    @State private var showSignOutConfirm = false
    
    var body: some View {
        NavigationStack {
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
                
                // Subtle background circles
                GeometryReader { geo in
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.blue.opacity(0.12), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 200
                            )
                        )
                        .frame(width: 400, height: 400)
                        .offset(x: -100, y: 100)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(
                            RadialGradient(
                                colors: [Color.teal.opacity(0.1), Color.clear],
                                center: .center,
                                startRadius: 0,
                                endRadius: 150
                            )
                        )
                        .frame(width: 300, height: 300)
                        .offset(x: geo.size.width - 100, y: geo.size.height - 400)
                        .blur(radius: 50)
                }
                
                VStack(spacing: 0) {
                    // Header with hamburger menu
                    HStack {
                        Spacer()
                        
                        Menu {
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
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    Spacer()
                    
                    // Logo and Welcome
                    VStack(spacing: 24) {
                        // App Logo with glow effect
                        ZStack {
                            // Outer glow
                            Circle()
                                .fill(
                                    RadialGradient(
                                        colors: [Color.teal.opacity(0.3), Color.clear],
                                        center: .center,
                                        startRadius: 40,
                                        endRadius: 100
                                    )
                                )
                                .frame(width: 180, height: 180)
                            
                            Image("Employ210")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 120)
                                .clipShape(RoundedRectangle(cornerRadius: 28))
                                .shadow(color: .black.opacity(0.4), radius: 20, x: 0, y: 10)
                        }
                        
                        VStack(spacing: 12) {
                            Text("Welcome Back!")
                                .font(.system(size: 32, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            
                            if !authManager.userEmail.isEmpty {
                                HStack(spacing: 8) {
                                    Image(systemName: "person.circle.fill")
                                        .font(.system(size: 16))
                                        .foregroundStyle(.teal)
                                    Text(authManager.userEmail)
                                        .font(.subheadline)
                                        .foregroundStyle(.white.opacity(0.7))
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(Color.white.opacity(0.08))
                                .clipShape(Capsule())
                            }
                        }
                    }
                    
                    Spacer()
                    
                    // Role Selection Section
                    VStack(spacing: 12) {
                        Text("Select Your Role")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.6))
                            .padding(.bottom, 8)
                        
                        // Trainee Button
                        NavigationLink(destination: TraineeHomeView()) {
                            RoleCard(
                                title: "Trainee",
                                subtitle: "Access your training programs",
                                icon: "person.fill",
                                gradientColors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)]
                            )
                        }
                        
                        // Trainer Button
                        NavigationLink(destination: TrainerHomeView()) {
                            RoleCard(
                                title: "Trainer",
                                subtitle: "Manage trainees and programs",
                                icon: "person.2.fill",
                                gradientColors: [Color(red: 0.3, green: 0.7, blue: 0.6), Color(red: 0.2, green: 0.5, blue: 0.5)]
                            )
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    // Footer
                    VStack(spacing: 8) {
                        Text("Empowering Employment Success")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.4))
                        
                        Text("v1.0")
                            .font(.caption2)
                            .foregroundStyle(.white.opacity(0.25))
                    }
                    .padding(.bottom, 30)
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
        }
    }
}

// MARK: - Role Card Component

struct RoleCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let gradientColors: [Color]
    
    var body: some View {
        HStack(spacing: 16) {
            // Icon Circle
            ZStack {
                Circle()
                    .fill(Color.white.opacity(0.2))
                    .frame(width: 56, height: 56)
                
                Image(systemName: icon)
                    .font(.system(size: 24))
                    .foregroundColor(.white)
            }
            
            // Text
            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.title2.bold())
                    .foregroundColor(.white)
                
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.7))
            }
            
            Spacer()
            
            // Arrow
            Image(systemName: "chevron.right")
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white.opacity(0.6))
        }
        .padding(20)
        .background(
            LinearGradient(
                colors: gradientColors,
                startPoint: .leading,
                endPoint: .trailing
            )
        )
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: gradientColors[0].opacity(0.4), radius: 10, x: 0, y: 5)
    }
}

// MARK: - Preview

#Preview {
    RoleSelectionView()
        .environmentObject(AuthenticationManager())
}
