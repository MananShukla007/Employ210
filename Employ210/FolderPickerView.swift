//
//  FolderPickerView.swift
//  Employ210
//
//  Shown after login for employ210@gmail.com only.
//  Picks a folder before reaching RoleSelectionView.
//

import SwiftUI

struct FolderPickerView: View {
    @AppStorage("selectedFolder") private var selectedFolder = ""
    @EnvironmentObject var authManager: AuthenticationManager

    @State private var navigate = false
    @State private var showHistory = false

    private let folders = ["Katie", "Sierra", "Colleen", "Kiana"]

    var body: some View {
        NavigationStack {
            ZStack {
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
                    Spacer()

                    VStack(spacing: 20) {
                        ZStack {
                            Image("Employ210")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 100)
                                .blur(radius: 16)
                                .opacity(0.4)
                            Image("Employ210")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 90)
                                .clipShape(RoundedRectangle(cornerRadius: 22))
                                .shadow(color: .black.opacity(0.3), radius: 16, x: 0, y: 8)
                        }

                        VStack(spacing: 8) {
                            Text("Select Folder")
                                .font(.system(size: 30, weight: .bold, design: .rounded))
                                .foregroundColor(.white)
                            Text("Who are you working with today?")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.55))
                        }
                    }

                    Spacer()

                    VStack(spacing: 12) {
                        ForEach(folders, id: \.self) { name in
                            Button {
                                selectedFolder = name
                                navigate = true
                            } label: {
                                HStack(spacing: 16) {
                                    ZStack {
                                        Circle()
                                            .fill(Color.teal.opacity(selectedFolder == name ? 0.3 : 0.12))
                                            .frame(width: 44, height: 44)
                                        Image(systemName: "folder.fill")
                                            .font(.system(size: 18))
                                            .foregroundStyle(selectedFolder == name ? .teal : .white.opacity(0.6))
                                    }
                                    Text(name)
                                        .font(.headline)
                                        .foregroundColor(.white)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.system(size: 14, weight: .semibold))
                                        .foregroundStyle(.white.opacity(0.35))
                                }
                                .padding(.horizontal, 20)
                                .padding(.vertical, 16)
                                .background(Color.white.opacity(selectedFolder == name ? 0.12 : 0.07))
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 14)
                                        .stroke(
                                            selectedFolder == name ? Color.teal.opacity(0.5) : Color.white.opacity(0.1),
                                            lineWidth: 1
                                        )
                                )
                            }
                        }
                    }
                    .padding(.horizontal, 24)

                    Spacer()

                    Button {
                        showHistory = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "clock.arrow.circlepath")
                                .font(.system(size: 13))
                            Text("View All HTAs")
                                .font(.subheadline)
                        }
                        .foregroundStyle(.white.opacity(0.4))
                    }
                    .padding(.bottom, 40)
                }
            }
            .navigationDestination(isPresented: $navigate) {
                RoleSelectionView()
                    .environmentObject(authManager)
            }
            .sheet(isPresented: $showHistory) {
                HTAHistoryView()
            }
        }
    }
}

#Preview {
    FolderPickerView()
        .environmentObject(AuthenticationManager())
}
