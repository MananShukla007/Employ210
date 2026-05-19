//
//  NewProgramView.swift
//  //  Employ210
//
//  Created by Manan Shukla

//
//  Create new training program for a trainee
//

import SwiftUI

struct NewProgramView: View {
    
    @Environment(\.dismiss) var dismiss
    
    let traineeName: String
    
    @State private var programName = ""
    @State private var programDescription = ""
    @State private var selectedDueDate = Date().addingTimeInterval(7 * 24 * 60 * 60)
    @State private var showDatePicker = false
    @State private var isLoading = false
    @State private var navigateToHTA = false
    
    var isFormValid: Bool {
        !programName.trimmingCharacters(in: .whitespaces).isEmpty
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
                    // Header Icon
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.2))
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "doc.badge.plus")
                            .font(.system(size: 32))
                            .foregroundStyle(.blue)
                    }
                    .padding(.top, 20)
                    
                    VStack(spacing: 8) {
                        Text("New Program")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        Text("For \(traineeName)")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    // Form
                    VStack(spacing: 20) {
                        // Program Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Program Name")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            HStack(spacing: 12) {
                                Image(systemName: "folder")
                                    .foregroundStyle(.white.opacity(0.5))
                                    .frame(width: 20)
                                
                                TextField("Enter program name", text: $programName)
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
                        
                        // Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Description (Optional)")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            TextEditor(text: $programDescription)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .frame(minHeight: 100)
                                .padding(12)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.1), lineWidth: 1)
                                )
                        }
                        
                        // Due Date
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Due Date")
                                .font(.caption)
                                .fontWeight(.medium)
                                .foregroundStyle(.white.opacity(0.6))
                            
                            Button {
                                showDatePicker.toggle()
                            } label: {
                                HStack(spacing: 12) {
                                    Image(systemName: "calendar")
                                        .foregroundStyle(.white.opacity(0.5))
                                        .frame(width: 20)
                                    
                                    Text(selectedDueDate.formatted(date: .long, time: .omitted))
                                        .foregroundColor(.white)
                                    
                                    Spacer()
                                    
                                    Image(systemName: "chevron.down")
                                        .foregroundStyle(.white.opacity(0.5))
                                        .rotationEffect(.degrees(showDatePicker ? 180 : 0))
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
                            
                            if showDatePicker {
                                DatePicker(
                                    "",
                                    selection: $selectedDueDate,
                                    in: Date()...,
                                    displayedComponents: .date
                                )
                                .datePickerStyle(.graphical)
                                .colorScheme(.dark)
                                .padding()
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // Create with HTA
                        Button {
                            navigateToHTA = true
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "wand.and.stars")
                                Text("Create with HTA Generator")
                                    .font(.headline)
                            }
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
                            .shadow(color: Color.blue.opacity(isFormValid ? 0.3 : 0), radius: 10, x: 0, y: 5)
                        }
                        .disabled(!isFormValid)
                        
                        // Create Basic
                        Button {
                            createProgram()
                        } label: {
                            HStack {
                                if isLoading {
                                    ProgressView().tint(.white)
                                } else {
                                    Text("Create Basic Program")
                                        .font(.headline)
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.08))
                            .foregroundColor(.white.opacity(isFormValid ? 0.9 : 0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .overlay(
                                RoundedRectangle(cornerRadius: 14)
                                    .stroke(Color.white.opacity(0.15), lineWidth: 1)
                            )
                        }
                        .disabled(!isFormValid || isLoading)
                    }
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationTitle("New Program")
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button("Cancel") {
                    dismiss()
                }
                .foregroundColor(.white.opacity(0.7))
            }
        }
        .navigationDestination(isPresented: $navigateToHTA) {
            HTAGeneratorView()
        }
    }
    
    private func createProgram() {
        isLoading = true
        
        // Simulate API call
        Task {
            try? await Task.sleep(nanoseconds: 1_000_000_000)
            dismiss()
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        NewProgramView(traineeName: "John Doe")
    }
}
