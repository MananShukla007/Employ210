//
//  TraineeDetailView.swift
//  Employ210
//
//  Trainee Detail - View trainee info, saved programs, and record/analyze
//

import SwiftUI
import AVFoundation
import Amplify
import PhotosUI
import UniformTypeIdentifiers

struct TraineeDetailView: View {
    
    let trainee: Trainee
    let trainerId: String  // Added trainerId for S3 organization
    
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var programStore = TraineeProgramStore()
    
    @State private var navigateToHTA = false
    @State private var showRecordView = false
    @State private var showSignOutConfirm = false
    @State private var selectedProgram: SavedHTAProgram?
    
    var traineePrograms: [SavedHTAProgram] {
        programStore.programs.filter { $0.traineeId == trainee.id }
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
                    // Profile Card
                    VStack(spacing: 16) {
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
                                .frame(width: 100, height: 100)
                            
                            Text(trainee.initials)
                                .font(.system(size: 36, weight: .bold))
                                .foregroundColor(.white)
                        }
                        
                        VStack(spacing: 4) {
                            Text(trainee.fullName)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Added \(trainee.createdAt.formatted(date: .long, time: .omitted))")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 30)
                    .background(Color.white.opacity(0.06))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay(
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.white.opacity(0.08), lineWidth: 1)
                    )
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                    // Action Buttons
                    VStack(spacing: 12) {
                        // New Program Button - Main CTA
                        NavigationLink(destination: HTAGeneratorView(trainerId: trainerId, traineeId: trainee.id, programStore: programStore), isActive: $navigateToHTA) {
                            EmptyView()
                        }
                        
                        Button {
                            navigateToHTA = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "plus.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("New Program")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Create HTA for this trainee")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
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
                        
                        // Record and Analyze Button
                        Button {
                            showRecordView = true
                        } label: {
                            HStack(spacing: 12) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.2))
                                        .frame(width: 50, height: 50)
                                    
                                    Image(systemName: "video.fill")
                                        .font(.system(size: 22))
                                        .foregroundColor(.white)
                                }
                                
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Record & Analyze")
                                        .font(.title3.bold())
                                        .foregroundColor(.white)
                                    
                                    Text("Record task performance for AI analysis")
                                        .font(.subheadline)
                                        .foregroundColor(.white.opacity(0.7))
                                }
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(.white.opacity(0.6))
                            }
                            .padding(20)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.6, green: 0.3, blue: 0.7), Color(red: 0.4, green: 0.2, blue: 0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                            .shadow(color: Color.purple.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    // Programs Section
                    VStack(alignment: .leading, spacing: 16) {
                        HStack {
                            Text("Training Programs")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                            
                            Spacer()
                            
                            if !traineePrograms.isEmpty {
                                Text("\(traineePrograms.count)")
                                    .font(.subheadline.bold())
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 4)
                                    .background(Color.blue.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                        
                        if traineePrograms.isEmpty {
                            // Empty State
                            VStack(spacing: 16) {
                                ZStack {
                                    Circle()
                                        .fill(Color.white.opacity(0.05))
                                        .frame(width: 80, height: 80)
                                    
                                    Image(systemName: "folder.badge.plus")
                                        .font(.system(size: 32))
                                        .foregroundStyle(.white.opacity(0.3))
                                }
                                
                                Text("No Programs Yet")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                
                                Text("Tap 'New Program' above to create one")
                                    .font(.subheadline)
                                    .foregroundStyle(.white.opacity(0.5))
                            }
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 40)
                            .background(Color.white.opacity(0.04))
                            .clipShape(RoundedRectangle(cornerRadius: 16))
                        } else {
                            ForEach(traineePrograms) { program in
                                SavedProgramCard(program: program) {
                                    selectedProgram = program
                                }
                                .contextMenu {
                                    Button(role: .destructive) {
                                        programStore.deleteProgram(id: program.id)
                                    } label: {
                                        Label("Delete Program", systemImage: "trash")
                                    }
                                }
                            }
                        }
                    }
                    .padding(.horizontal, 24)
                    
                    Spacer(minLength: 50)
                }
            }
        }
        .navigationTitle(trainee.fullName)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Menu {
                    Button {
                        navigateToHTA = true
                    } label: {
                        Label("New Program", systemImage: "plus.circle")
                    }
                    
                    Button {
                        showRecordView = true
                    } label: {
                        Label("Record & Analyze", systemImage: "video.fill")
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
        .fullScreenCover(isPresented: $showRecordView) {
            RecordAndAnalyzeView(trainee: trainee, trainerId: trainerId)
        }
        .sheet(item: $selectedProgram) { program in
            ProgramDetailSheet(program: program)
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

// MARK: - Saved Program Card

struct SavedProgramCard: View {
    let program: SavedHTAProgram
    let onTap: () -> Void
    
    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 14) {
                ZStack {
                    RoundedRectangle(cornerRadius: 12)
                        .fill(
                            LinearGradient(
                                colors: [Color.green.opacity(0.3), Color.teal.opacity(0.3)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 50, height: 50)
                    
                    Image(systemName: "checkmark.seal.fill")
                        .font(.system(size: 22))
                        .foregroundColor(.green)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(program.taskDescription.prefix(40) + (program.taskDescription.count > 40 ? "..." : ""))
                        .font(.headline)
                        .foregroundColor(.white)
                        .lineLimit(1)
                    
                    HStack(spacing: 8) {
                        Text(program.createdAt.formatted(date: .abbreviated, time: .shortened))
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                        
                        Text("•")
                            .foregroundStyle(.white.opacity(0.3))
                        
                        Text("\(program.highLevelSteps.count) steps")
                            .font(.caption)
                            .foregroundStyle(.white.opacity(0.5))
                    }
                }
                
                Spacer()
                
                Text("Saved")
                    .font(.caption.bold())
                    .foregroundColor(.green)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.15))
                    .clipShape(Capsule())
                
                Image(systemName: "chevron.right")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.4))
            }
            .padding(16)
            .background(Color.white.opacity(0.06))
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .stroke(Color.green.opacity(0.2), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Program Detail Sheet

struct ProgramDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let program: SavedHTAProgram
    
    @State private var showShareSheet = false
    @State private var showEvaluationView = false
    @State private var exportedFileURL: URL?
    @State private var stepsExpanded = false
    @State private var selectedEvaluation: EvaluationResult?
    
    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "checkmark.seal.fill")
                                .font(.system(size: 50))
                                .foregroundStyle(.green)
                            
                            Text(program.taskDescription)
                                .font(.title2.bold())
                                .foregroundColor(.white)
                                .multilineTextAlignment(.center)
                            
                            Text(program.createdAt.formatted(date: .long, time: .shortened))
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)
                        
                        // Share Button
                        Button {
                            shareProgram()
                        } label: {
                            HStack(spacing: 10) {
                                Image(systemName: "square.and.arrow.up")
                                Text("Share Program")
                            }
                            .font(.headline)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.3, green: 0.7, blue: 0.6), Color(red: 0.2, green: 0.5, blue: 0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        
                        // Task Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Description")
                                .font(.headline)
                                .foregroundColor(.teal)
                            
                            Text(program.taskDescription)
                                .font(.body)
                                .foregroundColor(.white.opacity(0.9))
                                .padding(16)
                                .background(Color.white.opacity(0.06))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        
                        // Steps (collapsible)
                        if !program.highLevelSteps.isEmpty || !program.lowLevelSteps.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                Button {
                                    withAnimation(.easeInOut(duration: 0.2)) {
                                        stepsExpanded.toggle()
                                    }
                                } label: {
                                    HStack {
                                        Image(systemName: "list.bullet.rectangle")
                                            .foregroundStyle(.teal)
                                        Text("Steps")
                                            .font(.headline)
                                            .foregroundColor(.teal)
                                        Spacer()
                                        Image(systemName: stepsExpanded ? "chevron.up" : "chevron.down")
                                            .font(.system(size: 14, weight: .semibold))
                                            .foregroundColor(.teal)
                                    }
                                }
                                .buttonStyle(.plain)

                                if stepsExpanded {
                                    if !program.highLevelSteps.isEmpty {
                                        VStack(spacing: 8) {
                                            ForEach(Array(program.highLevelSteps.enumerated()), id: \.offset) { index, step in
                                                HStack(alignment: .top, spacing: 12) {
                                                    Text("\(index + 1)")
                                                        .font(.caption.bold())
                                                        .foregroundColor(.teal)
                                                        .frame(width: 24, height: 24)
                                                        .background(Color.teal.opacity(0.2))
                                                        .clipShape(Circle())
                                                    Text(step)
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.9))
                                                    Spacer()
                                                }
                                                .padding(12)
                                                .background(Color.white.opacity(0.04))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                    }

                                    if !program.lowLevelSteps.isEmpty {
                                        VStack(spacing: 8) {
                                            ForEach(Array(program.lowLevelSteps.enumerated()), id: \.offset) { index, step in
                                                HStack(alignment: .top, spacing: 12) {
                                                    Image(systemName: "checkmark.circle.fill")
                                                        .foregroundStyle(.blue)
                                                        .font(.system(size: 16))
                                                    Text(step)
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.85))
                                                    Spacer()
                                                }
                                                .padding(12)
                                                .background(Color.white.opacity(0.04))
                                                .clipShape(RoundedRectangle(cornerRadius: 10))
                                            }
                                        }
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Observations
                        if !program.observations.isEmpty {
                            VStack(alignment: .leading, spacing: 12) {
                                HStack {
                                    Image(systemName: "lightbulb.fill")
                                        .foregroundStyle(.orange)
                                    Text("Observations")
                                        .font(.headline)
                                        .foregroundColor(.orange)
                                }
                                
                                VStack(spacing: 8) {
                                    ForEach(program.observations, id: \.self) { observation in
                                        HStack(alignment: .top, spacing: 12) {
                                            Image(systemName: "arrow.right")
                                                .foregroundStyle(.orange.opacity(0.7))
                                                .font(.system(size: 12))
                                            
                                            Text(observation)
                                                .font(.subheadline)
                                                .foregroundColor(.white.opacity(0.7))
                                            
                                            Spacer()
                                        }
                                        .padding(12)
                                        .background(Color.white.opacity(0.04))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                    }
                                }
                            }
                            .padding(.horizontal, 24)
                        }
                        
                        // Completed Sessions
                        let evaluations = EvaluationStore.shared.evaluationsForProgram(id: program.id)
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                    .foregroundStyle(.green)
                                Text("Completed Sessions")
                                    .font(.headline)
                                    .foregroundColor(.green)
                                Spacer()
                                if !evaluations.isEmpty {
                                    Text("\(evaluations.count)")
                                        .font(.caption.bold())
                                        .foregroundColor(.green)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(Color.green.opacity(0.15))
                                        .clipShape(Capsule())
                                }
                            }

                            if evaluations.isEmpty {
                                Text("No sessions completed yet")
                                    .font(.subheadline)
                                    .foregroundColor(.white.opacity(0.4))
                                    .padding(16)
                                    .frame(maxWidth: .infinity)
                                    .background(Color.white.opacity(0.04))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                            } else {
                                VStack(spacing: 8) {
                                    ForEach(evaluations) { evaluation in
                                        let totalSteps = evaluation.passCount + evaluation.notCompletedCount + evaluation.needsPromptingCount + evaluation.pendingCount
                                        let pct = totalSteps > 0 ? Int((Double(evaluation.passCount) / Double(totalSteps)) * 100) : 0
                                        let mins = evaluation.elapsedTimeSeconds / 60
                                        let secs = evaluation.elapsedTimeSeconds % 60
                                        let dateStr: String = {
                                            let df = DateFormatter()
                                            df.dateFormat = "MMM d, yyyy"
                                            return df.string(from: evaluation.evaluatedAt)
                                        }()
                                        Button {
                                            selectedEvaluation = evaluation
                                        } label: {
                                            HStack(spacing: 12) {
                                                VStack(alignment: .leading, spacing: 4) {
                                                    Text(dateStr)
                                                        .font(.subheadline)
                                                        .foregroundColor(.white.opacity(0.8))
                                                    Text("\(pct)% completed")
                                                        .font(.caption.bold())
                                                        .foregroundColor(.green)
                                                }
                                                Spacer()
                                                Text(String(format: "%02d:%02d", mins, secs))
                                                    .font(.system(.subheadline, design: .monospaced))
                                                    .foregroundColor(.white.opacity(0.6))
                                                Image(systemName: "chevron.right")
                                                    .font(.system(size: 12, weight: .semibold))
                                                    .foregroundColor(.white.opacity(0.3))
                                            }
                                            .padding(12)
                                            .background(Color.white.opacity(0.04))
                                            .clipShape(RoundedRectangle(cornerRadius: 10))
                                        }
                                        .buttonStyle(.plain)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, 24)

                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
                
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        showEvaluationView = true
                    } label: {
                        HStack(spacing: 4) {
                            Text("Next")
                            Image(systemName: "chevron.right")
                                .font(.system(size: 14, weight: .semibold))
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.blue.opacity(0.3))
                        .clipShape(Capsule())
                    }
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
            .sheet(isPresented: $showShareSheet) {
                if let url = exportedFileURL {
                    ProgramShareSheet(activityItems: [url])
                }
            }
            .fullScreenCover(isPresented: $showEvaluationView) {
                TaskEvaluationView(program: program)
            }
            .sheet(item: $selectedEvaluation) { evaluation in
                SessionDetailSheet(evaluation: evaluation, program: program)
            }
        }
    }

    private func shareProgram() {
        let document = generateReadableDocument()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: program.createdAt)
        let fileName = "HTA_Program_\(timestamp).txt"
        
        let tempDirectory = FileManager.default.temporaryDirectory
        let fileURL = tempDirectory.appendingPathComponent(fileName)
        
        do {
            try document.write(to: fileURL, atomically: true, encoding: .utf8)
            exportedFileURL = fileURL
            showShareSheet = true
        } catch {
            print("❌ Failed to create share file: \(error)")
        }
    }
    
    private func generateReadableDocument() -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        var document = """
        ═══════════════════════════════════════════════════════════════
                        HIERARCHICAL TASK ANALYSIS (HTA)
        ═══════════════════════════════════════════════════════════════
        
        Generated: \(dateFormatter.string(from: program.createdAt))
        App: Employ210
        
        ───────────────────────────────────────────────────────────────
        TASK DESCRIPTION
        ───────────────────────────────────────────────────────────────
        
        \(program.taskDescription)
        
        """
        
        if !program.highLevelSteps.isEmpty {
            document += """
            
            ───────────────────────────────────────────────────────────────
            HIGH-LEVEL STEPS
            ───────────────────────────────────────────────────────────────
            
            """
            for (index, step) in program.highLevelSteps.enumerated() {
                document += "\(index + 1). \(step)\n"
            }
        }
        
        if !program.lowLevelSteps.isEmpty {
            document += """
            
            ───────────────────────────────────────────────────────────────
            DETAILED STEPS
            ───────────────────────────────────────────────────────────────
            
            """
            for (index, step) in program.lowLevelSteps.enumerated() {
                document += "   \(index + 1). \(step)\n"
            }
        }
        
        if !program.observations.isEmpty {
            document += """
            
            ───────────────────────────────────────────────────────────────
            OBSERVATIONS & NOTES
            ───────────────────────────────────────────────────────────────
            
            """
            for observation in program.observations {
                document += "• \(observation)\n"
            }
        }
        
        document += """
        
        ═══════════════════════════════════════════════════════════════
                              END OF DOCUMENT
        ═══════════════════════════════════════════════════════════════
        
        Generated by Employ210 - Empowering Employment Success
        """
        
        return document
    }
}

// MARK: - Session Detail Sheet

struct SessionDetailSheet: View {
    @Environment(\.dismiss) private var dismiss
    let evaluation: EvaluationResult
    let program: SavedHTAProgram

    var allSteps: [(id: String, text: String, type: StepType)] {
        var steps: [(id: String, text: String, type: StepType)] = []
        for (index, step) in program.highLevelSteps.enumerated() {
            steps.append((id: "high_\(index)", text: step, type: .highLevel))
        }
        for (index, step) in program.lowLevelSteps.enumerated() {
            steps.append((id: "low_\(index)", text: step, type: .detailed))
        }
        return steps
    }

    var totalSteps: Int {
        evaluation.passCount + evaluation.notCompletedCount + evaluation.needsPromptingCount + evaluation.pendingCount
    }

    var completionPct: Int {
        totalSteps > 0 ? Int((Double(evaluation.passCount) / Double(totalSteps)) * 100) : 0
    }

    var body: some View {
        NavigationStack {
            ZStack {
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()

                ScrollView {
                    VStack(alignment: .leading, spacing: 24) {

                        // Header
                        VStack(spacing: 16) {
                            let mins = evaluation.elapsedTimeSeconds / 60
                            let secs = evaluation.elapsedTimeSeconds % 60
                            let dateStr: String = {
                                let df = DateFormatter()
                                df.dateFormat = "MMM d, yyyy"
                                return df.string(from: evaluation.evaluatedAt)
                            }()

                            Text(dateStr)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.6))

                            Text("\(completionPct)%")
                                .font(.system(size: 52, weight: .bold, design: .rounded))
                                .foregroundColor(.green)

                            Text("completed")
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.5))

                            Text(String(format: "%02d:%02d", mins, secs))
                                .font(.system(.title3, design: .monospaced))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.top, 20)

                        // Stats row
                        HStack(spacing: 12) {
                            StatBadge(count: evaluation.passCount, label: "Pass", color: .green)
                            StatBadge(count: evaluation.needsPromptingCount, label: "Prompt", color: .orange)
                            StatBadge(count: evaluation.notCompletedCount, label: "Incomplete", color: .red)
                            StatBadge(count: evaluation.pendingCount, label: "Pending", color: .gray)
                        }
                        .padding(.horizontal, 24)

                        // Step-by-step results
                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Image(systemName: "list.bullet.rectangle")
                                    .foregroundStyle(.teal)
                                Text("Step Results")
                                    .font(.headline)
                                    .foregroundColor(.teal)
                            }
                            .padding(.horizontal, 24)

                            VStack(spacing: 10) {
                                ForEach(Array(allSteps.enumerated()), id: \.element.id) { index, step in
                                    EvaluationStepCard(
                                        index: index + 1,
                                        text: step.text,
                                        type: step.type,
                                        state: evaluation.stepResults[step.id] ?? 0,
                                        onTap: {}
                                    )
                                }
                            }
                            .padding(.horizontal, 24)
                        }

                        Spacer(minLength: 50)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
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
                ToolbarItem(placement: .principal) {
                    Text("Session Details")
                        .font(.headline)
                        .foregroundColor(.white)
                }
            }
            .toolbarColorScheme(.dark, for: .navigationBar)
        }
    }
}

// MARK: - Task Evaluation View

struct TaskEvaluationView: View {
    @Environment(\.dismiss) private var dismiss
    let program: SavedHTAProgram
    
    // Timer state - counts UP like a stopwatch
    @State private var elapsedTime: Int = 0  // Seconds elapsed
    @State private var timerIsRunning = false
    @State private var timer: Timer?
    
    // Evaluation states: 0 = grey (not evaluated), 1 = green (pass), 2 = orange (needs prompting), 3 = red (not completed)
    @State private var stepStates: [String: Int] = [:]
    @State private var showSaveConfirm = false
    @State private var showResetConfirm = false
    
    // Combine all steps for evaluation
    var allSteps: [(id: String, text: String, type: StepType)] {
        var steps: [(id: String, text: String, type: StepType)] = []
        
        for (index, step) in program.highLevelSteps.enumerated() {
            steps.append((id: "high_\(index)", text: step, type: .highLevel))
        }
        
        for (index, step) in program.lowLevelSteps.enumerated() {
            steps.append((id: "low_\(index)", text: step, type: .detailed))
        }
        
        return steps
    }
    
    var passCount: Int {
        stepStates.values.filter { $0 == 1 }.count
    }
    
    var needsPromptingCount: Int {
        stepStates.values.filter { $0 == 2 }.count
    }
    
    var notCompletedCount: Int {
        stepStates.values.filter { $0 == 3 }.count
    }
    
    var notEvaluatedCount: Int {
        allSteps.count - passCount - needsPromptingCount - notCompletedCount
    }
    
    var timerString: String {
        let minutes = elapsedTime / 60
        let seconds = elapsedTime % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()
                
                VStack(spacing: 0) {
                    // Timer Section
                    VStack(spacing: 12) {
                        // Timer Display
                        Text(timerString)
                            .font(.system(size: 52, weight: .bold, design: .monospaced))
                            .foregroundColor(timerIsRunning ? .green : .white)
                        
                        // Timer Controls
                        HStack(spacing: 24) {
                            // Reset Timer
                            Button {
                                resetTimer()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "arrow.counterclockwise")
                                        .font(.system(size: 22, weight: .semibold))
                                    Text("Reset")
                                        .font(.caption2)
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            // Start/Pause Button
                            Button {
                                toggleTimer()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: timerIsRunning ? "pause.fill" : "play.fill")
                                        .font(.system(size: 28, weight: .semibold))
                                    Text(timerIsRunning ? "Pause" : "Start")
                                        .font(.caption2)
                                }
                                .foregroundColor(.white)
                                .frame(width: 80, height: 70)
                                .background(
                                    LinearGradient(
                                        colors: timerIsRunning
                                            ? [Color.orange, Color.red.opacity(0.8)]
                                            : [Color.green, Color.teal],
                                        startPoint: .topLeading,
                                        endPoint: .bottomTrailing
                                    )
                                )
                                .clipShape(RoundedRectangle(cornerRadius: 14))
                                .shadow(color: timerIsRunning ? Color.orange.opacity(0.4) : Color.green.opacity(0.4), radius: 8, x: 0, y: 4)
                            }
                            
                            // End Timer
                            Button {
                                stopTimer()
                            } label: {
                                VStack(spacing: 4) {
                                    Image(systemName: "stop.fill")
                                        .font(.system(size: 22, weight: .semibold))
                                    Text("End")
                                        .font(.caption2)
                                }
                                .foregroundColor(.white.opacity(0.7))
                                .frame(width: 60, height: 60)
                                .background(Color.white.opacity(0.1))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                    }
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
                    .background(Color.white.opacity(0.05))
                    
                    // Stats Bar - 4 states
                    HStack(spacing: 12) {
                        StatBadge(count: passCount, label: "Pass", color: .green)
                        StatBadge(count: needsPromptingCount, label: "Prompt", color: .orange)
                        StatBadge(count: notCompletedCount, label: "Incomplete", color: .red)
                        StatBadge(count: notEvaluatedCount, label: "Pending", color: .gray)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    
                    // Instructions - 4 states
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 12) {
                            InstructionBadge(color: .gray, text: "Not Evaluated")
                            InstructionBadge(color: .green, text: "Pass")
                            InstructionBadge(color: .orange, text: "Needs Prompting")
                            InstructionBadge(color: .red, text: "Not Completed")
                        }
                        .padding(.horizontal, 24)
                    }
                    .padding(.vertical, 8)
                    
                    Divider()
                        .background(Color.white.opacity(0.1))
                    
                    // Steps List
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(Array(allSteps.enumerated()), id: \.element.id) { index, step in
                                EvaluationStepCard(
                                    index: index + 1,
                                    text: step.text,
                                    type: step.type,
                                    state: stepStates[step.id] ?? 0,
                                    onTap: {
                                        cycleState(for: step.id)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                        .padding(.vertical, 16)
                        .padding(.bottom, 100)
                    }
                }
                
                // Bottom Action Bar
                VStack {
                    Spacer()
                    
                    HStack(spacing: 16) {
                        // Reset Button
                        Button {
                            showResetConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "arrow.counterclockwise")
                                Text("Reset")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(Color.white.opacity(0.15))
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                        
                        // Save Evaluation Button
                        Button {
                            stopTimer()
                            showSaveConfirm = true
                        } label: {
                            HStack(spacing: 8) {
                                Image(systemName: "checkmark.circle.fill")
                                Text("Save Evaluation")
                            }
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.2, green: 0.6, blue: 0.4), Color(red: 0.1, green: 0.4, blue: 0.3)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                        }
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 16)
                    .background(
                        Color(red: 0.05, green: 0.10, blue: 0.15)
                            .shadow(color: .black.opacity(0.3), radius: 10, x: 0, y: -5)
                    )
                }
            }
            .navigationTitle("Task Evaluation")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        stopTimer()
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
            .alert("Reset Evaluation?", isPresented: $showResetConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Reset All", role: .destructive) {
                    resetAllStates()
                    resetTimer()
                }
            } message: {
                Text("This will reset all steps and the timer.")
            }
            .alert("Save Evaluation?", isPresented: $showSaveConfirm) {
                Button("Cancel", role: .cancel) {}
                Button("Save") {
                    saveEvaluation()
                    dismiss()
                }
            } message: {
                let minutes = elapsedTime / 60
                let seconds = elapsedTime % 60
                Text("Time: \(String(format: "%02d:%02d", minutes, seconds))\nPass: \(passCount) | Prompt: \(needsPromptingCount) | Incomplete: \(notCompletedCount)")
            }
            .onDisappear {
                timer?.invalidate()
            }
        }
    }
    
    // MARK: - Timer Functions
    
    private func toggleTimer() {
        if timerIsRunning {
            pauseTimer()
        } else {
            startTimer()
        }
    }
    
    private func startTimer() {
        timerIsRunning = true
        timer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { _ in
            elapsedTime += 1
        }
    }
    
    private func pauseTimer() {
        timerIsRunning = false
        timer?.invalidate()
        timer = nil
    }
    
    private func stopTimer() {
        pauseTimer()
    }
    
    private func resetTimer() {
        pauseTimer()
        elapsedTime = 0
    }
    
    // MARK: - Evaluation Functions
    
    private func cycleState(for stepId: String) {
        let currentState = stepStates[stepId] ?? 0
        // Cycle: 0 (grey) -> 1 (green/pass) -> 2 (orange/needs prompting) -> 3 (red/not completed) -> 0
        let nextState = (currentState + 1) % 4
        
        withAnimation(.easeInOut(duration: 0.2)) {
            stepStates[stepId] = nextState
        }
        
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .light)
        generator.impactOccurred()
    }
    
    private func resetAllStates() {
        withAnimation(.easeInOut(duration: 0.3)) {
            stepStates.removeAll()
        }
    }
    
    private func saveEvaluation() {
        // Create evaluation result
        let evaluation = EvaluationResult(
            programId: program.id,
            taskDescription: program.taskDescription,
            evaluatedAt: Date(),
            elapsedTimeSeconds: elapsedTime,
            passCount: passCount,
            needsPromptingCount: needsPromptingCount,
            notCompletedCount: notCompletedCount,
            pendingCount: notEvaluatedCount,
            stepResults: stepStates
        )
        
        // Save to UserDefaults
        EvaluationStore.shared.saveEvaluation(evaluation)
        print("✅ Evaluation saved: Pass=\(passCount), Prompt=\(needsPromptingCount), Incomplete=\(notCompletedCount), Time=\(elapsedTime)s")
    }
}

// MARK: - Evaluation Result Model

struct EvaluationResult: Codable, Identifiable {
    var id: String = UUID().uuidString
    let programId: String
    let taskDescription: String
    let evaluatedAt: Date
    let elapsedTimeSeconds: Int
    let passCount: Int
    let needsPromptingCount: Int
    let notCompletedCount: Int
    let pendingCount: Int
    let stepResults: [String: Int]
}

// MARK: - Evaluation Store

class EvaluationStore {
    static let shared = EvaluationStore()
    private let storageKey = "employ210_evaluations"
    
    private init() {}
    
    func saveEvaluation(_ evaluation: EvaluationResult) {
        var evaluations = loadEvaluations()
        evaluations.insert(evaluation, at: 0)
        
        // Keep only last 50 evaluations
        if evaluations.count > 50 {
            evaluations = Array(evaluations.prefix(50))
        }
        
        do {
            let data = try JSONEncoder().encode(evaluations)
            UserDefaults.standard.set(data, forKey: storageKey)
        } catch {
            print("❌ Failed to save evaluation: \(error)")
        }
    }
    
    func loadEvaluations() -> [EvaluationResult] {
        guard let data = UserDefaults.standard.data(forKey: storageKey) else {
            return []
        }
        
        do {
            return try JSONDecoder().decode([EvaluationResult].self, from: data)
        } catch {
            print("❌ Failed to load evaluations: \(error)")
            return []
        }
    }
    
    func evaluationsForProgram(id: String) -> [EvaluationResult] {
        return loadEvaluations().filter { $0.programId == id }
    }
}

// MARK: - Step Type

enum StepType {
    case highLevel
    case detailed
    
    var label: String {
        switch self {
        case .highLevel: return "HIGH-LEVEL"
        case .detailed: return "DETAILED"
        }
    }
    
    var color: Color {
        switch self {
        case .highLevel: return .teal
        case .detailed: return .blue
        }
    }
}

// MARK: - Evaluation Step Card

struct EvaluationStepCard: View {
    let index: Int
    let text: String
    let type: StepType
    let state: Int  // 0 = grey (not evaluated), 1 = green (pass), 2 = orange (needs prompting), 3 = red (not completed)
    let onTap: () -> Void
    
    var stateColor: Color {
        switch state {
        case 1: return .green
        case 2: return .orange
        case 3: return .red
        default: return Color.white.opacity(0.15)
        }
    }
    
    var stateIcon: String {
        switch state {
        case 1: return "checkmark.circle.fill"
        case 2: return "exclamationmark.circle.fill"
        case 3: return "xmark.circle.fill"
        default: return "circle"
        }
    }
    
    var stateLabel: String {
        switch state {
        case 1: return "PASS"
        case 2: return "PROMPT"
        case 3: return "INCOMPLETE"
        default: return ""
        }
    }
    
    var body: some View {
        Button(action: onTap) {
            HStack(alignment: .top, spacing: 14) {
                // State indicator
                ZStack {
                    Circle()
                        .fill(stateColor.opacity(state == 0 ? 0.3 : 0.25))
                        .frame(width: 44, height: 44)
                    
                    Image(systemName: stateIcon)
                        .font(.system(size: 24))
                        .foregroundColor(state == 0 ? .white.opacity(0.4) : stateColor)
                }
                
                VStack(alignment: .leading, spacing: 6) {
                    // Type badge and state label
                    HStack(spacing: 8) {
                        Text(type.label)
                            .font(.caption2.bold())
                            .foregroundColor(type.color)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(type.color.opacity(0.2))
                            .clipShape(Capsule())
                        
                        if state != 0 {
                            Text(stateLabel)
                                .font(.caption2.bold())
                                .foregroundColor(stateColor)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(stateColor.opacity(0.2))
                                .clipShape(Capsule())
                        }
                    }
                    
                    // Step text
                    Text(text)
                        .font(.subheadline)
                        .foregroundColor(.white.opacity(0.9))
                        .multilineTextAlignment(.leading)
                        .fixedSize(horizontal: false, vertical: true)
                }
                
                Spacer(minLength: 0)
                
                // Step number
                Text("#\(index)")
                    .font(.caption.bold())
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(stateColor.opacity(state == 0 ? 0.08 : 0.15))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .stroke(stateColor.opacity(state == 0 ? 0.1 : 0.3), lineWidth: 1)
                    )
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Stat Badge

struct StatBadge: View {
    let count: Int
    let label: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text("\(count)")
                .font(.title2.bold())
                .foregroundColor(color)
            
            Text(label)
                .font(.caption)
                .foregroundColor(.white.opacity(0.6))
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Instruction Badge

struct InstructionBadge: View {
    let color: Color
    let text: String
    
    var body: some View {
        HStack(spacing: 6) {
            Circle()
                .fill(color)
                .frame(width: 10, height: 10)
            
            Text(text)
                .font(.caption)
                .foregroundColor(.white.opacity(0.7))
        }
    }
}

// MARK: - Program Share Sheet

struct ProgramShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: nil
        )
        return controller
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

// MARK: - Record and Analyze View

struct RecordAndAnalyzeView: View {
    @Environment(\.dismiss) private var dismiss
    let trainee: Trainee
    let trainerId: String
    
    @State private var isRecording = false
    @State private var recordedVideoURL: URL?
    @State private var showSaveConfirm = false
    @State private var cameraPermissionDenied = false
    @State private var isSavingRecording = false
    @State private var uploadProgress: Double = 0
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    
    // Video picker states
    @State private var showVideoPicker = false
    @State private var selectedVideoURL: URL?
    
    var body: some View {
        ZStack {
            // Camera Preview
            CameraPreviewView(isRecording: $isRecording, recordedVideoURL: $recordedVideoURL)
                .ignoresSafeArea()
            
            // Overlay UI
            VStack {
                // Top Bar
                HStack {
                    // Back Button
                    Button {
                        dismiss()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                            Text("Back")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Recording Indicator
                    if isRecording {
                        HStack(spacing: 8) {
                            Circle()
                                .fill(Color.red)
                                .frame(width: 12, height: 12)
                                .overlay(
                                    Circle()
                                        .fill(Color.red.opacity(0.5))
                                        .scaleEffect(1.5)
                                        .opacity(isRecording ? 1 : 0)
                                        .animation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true), value: isRecording)
                                )
                            
                            Text("Recording")
                                .font(.subheadline.bold())
                                .foregroundColor(.white)
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(Color.red.opacity(0.8))
                        .clipShape(Capsule())
                    }
                    
                    Spacer()
                    
                    // Upload Video Button
                    Button {
                        showVideoPicker = true
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 14, weight: .semibold))
                            Text("Upload")
                        }
                        .foregroundColor(.white)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .clipShape(Capsule())
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 60)
                
                Spacer()
                
                // Trainee Info Card
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color.blue.opacity(0.3))
                            .frame(width: 40, height: 40)
                        
                        Text(trainee.initials)
                            .font(.caption.bold())
                            .foregroundColor(.white)
                    }
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Recording for")
                            .font(.caption)
                            .foregroundColor(.white.opacity(0.7))
                        Text(trainee.fullName)
                            .font(.subheadline.bold())
                            .foregroundColor(.white)
                    }
                    
                    Spacer()
                }
                .padding(16)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 16))
                .padding(.horizontal, 20)
                .padding(.bottom, 20)
                
                // Bottom Controls
                HStack(spacing: 40) {
                    // Placeholder
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 60, height: 60)
                    
                    // Record Button
                    Button {
                        withAnimation(.spring(response: 0.3)) {
                            isRecording.toggle()
                        }
                    } label: {
                        ZStack {
                            // Outer ring
                            Circle()
                                .stroke(Color.white, lineWidth: 4)
                                .frame(width: 80, height: 80)
                            
                            // Inner shape - circle when not recording, square when recording
                            if isRecording {
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color.red)
                                    .frame(width: 32, height: 32)
                            } else {
                                Circle()
                                    .fill(Color.red)
                                    .frame(width: 64, height: 64)
                            }
                        }
                    }
                    
                    // Save Button (only when not recording and video exists)
                    if !isRecording && recordedVideoURL != nil {
                        Button {
                            showSaveConfirm = true
                        } label: {
                            ZStack {
                                Circle()
                                    .fill(
                                        LinearGradient(
                                            colors: [Color.green, Color.teal],
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        )
                                    )
                                    .frame(width: 60, height: 60)
                                    .shadow(color: Color.green.opacity(0.5), radius: 10, x: 0, y: 5)
                                
                                Image(systemName: "checkmark")
                                    .font(.system(size: 24, weight: .bold))
                                    .foregroundColor(.white)
                            }
                        }
                    } else {
                        Circle()
                            .fill(Color.clear)
                            .frame(width: 60, height: 60)
                    }
                }
                .padding(.bottom, 50)
            }
            
            // Saving overlay with progress
            if isSavingRecording {
                Color.black.opacity(0.85)
                    .ignoresSafeArea()
                
                VStack(spacing: 24) {
                    // Upload icon
                    ZStack {
                        Circle()
                            .stroke(Color.white.opacity(0.2), lineWidth: 4)
                            .frame(width: 80, height: 80)
                        
                        Circle()
                            .trim(from: 0, to: uploadProgress)
                            .stroke(Color.green, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                            .frame(width: 80, height: 80)
                            .rotationEffect(.degrees(-90))
                            .animation(.linear(duration: 0.3), value: uploadProgress)
                        
                        Image(systemName: "arrow.up.circle.fill")
                            .font(.system(size: 36))
                            .foregroundColor(.white)
                    }
                    
                    Text("Uploading to AWS...")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text("\(Int(uploadProgress * 100))%")
                        .font(.system(size: 28, weight: .bold, design: .monospaced))
                        .foregroundColor(.green)
                    
                    Text("Please don't close the app")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.6))
                }
            }
        }
        .alert("Save Recording?", isPresented: $showSaveConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Save & Analyze") {
                saveRecording()
            }
        } message: {
            Text("This recording will be uploaded to AWS S3 for storage and analysis.")
        }
        .alert("Upload Complete!", isPresented: $showSaveSuccess) {
            Button("Done") {
                dismiss()
            }
        } message: {
            Text("Your video has been saved to AWS S3 successfully.")
        }
        .alert("Upload Failed", isPresented: $showSaveError) {
            Button("Try Again") {
                saveRecording()
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text(saveErrorMessage)
        }
        .sheet(isPresented: $showVideoPicker) {
            VideoPickerView(selectedVideoURL: $selectedVideoURL)
        }
        .onChange(of: selectedVideoURL) { oldValue, newValue in
            if let url = newValue {
                recordedVideoURL = url
                showSaveConfirm = true
            }
        }
        .onAppear {
            checkCameraPermission()
        }
        .alert("Camera Access Required", isPresented: $cameraPermissionDenied) {
            Button("Settings") {
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url)
                }
            }
            Button("Cancel", role: .cancel) {
                dismiss()
            }
        } message: {
            Text("Please enable camera access in Settings to use the Record & Analyze feature.")
        }
    }
    
    private func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            break
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                if !granted {
                    DispatchQueue.main.async {
                        cameraPermissionDenied = true
                    }
                }
            }
        case .denied, .restricted:
            cameraPermissionDenied = true
        @unknown default:
            break
        }
    }
    
    private func saveRecording() {
        guard let videoURL = recordedVideoURL else {
            dismiss()
            return
        }
        
        isSavingRecording = true
        uploadProgress = 0
        
        Task {
            do {
                // Read video data
                let videoData = try Data(contentsOf: videoURL)
                
                // Create S3 key with public/ prefix for guest access
                let dateFormatter = DateFormatter()
                dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
                let timestamp = dateFormatter.string(from: Date())
                let s3Key = "public/recordings/\(trainerId)/\(trainee.id)/recording_\(timestamp).mov"
                
                print("📤 Uploading recording to S3: \(s3Key)")
                print("📦 Video size: \(videoData.count / 1024 / 1024) MB")
                
                // Upload to S3 using Amplify Storage (no options = uses default from config)
                let uploadTask = Amplify.Storage.uploadData(
                    key: s3Key,
                    data: videoData
                )
                
                // Track progress
                Task {
                    for await progress in await uploadTask.progress {
                        await MainActor.run {
                            uploadProgress = progress.fractionCompleted
                        }
                    }
                }
                
                // Wait for upload to complete
                let result = try await uploadTask.value
                print("✅ Recording uploaded to S3: \(result)")
                
                // Also save metadata locally
                saveRecordingMetadata(s3Key: s3Key, timestamp: timestamp)
                
                await MainActor.run {
                    isSavingRecording = false
                    uploadProgress = 1.0
                    showSaveSuccess = true
                }
                
            } catch {
                print("❌ Failed to upload recording: \(error)")
                await MainActor.run {
                    isSavingRecording = false
                    saveErrorMessage = error.localizedDescription
                    showSaveError = true
                }
            }
        }
    }
    
    private func saveRecordingMetadata(s3Key: String, timestamp: String) {
        // Save recording info to UserDefaults for later reference
        var recordings = UserDefaults.standard.array(forKey: "employ210_recordings") as? [[String: String]] ?? []
        
        let recordingInfo: [String: String] = [
            "id": UUID().uuidString,
            "trainee_id": trainee.id,
            "trainer_id": trainerId,
            "s3_key": s3Key,
            "timestamp": timestamp,
            "created_at": ISO8601DateFormatter().string(from: Date())
        ]
        
        recordings.insert(recordingInfo, at: 0)
        
        // Keep only last 100 recordings
        if recordings.count > 100 {
            recordings = Array(recordings.prefix(100))
        }
        
        UserDefaults.standard.set(recordings, forKey: "employ210_recordings")
        print("✅ Recording metadata saved locally")
    }
}

// MARK: - Camera Preview View

struct CameraPreviewView: UIViewRepresentable {
    @Binding var isRecording: Bool
    @Binding var recordedVideoURL: URL?
    
    func makeUIView(context: Context) -> UIView {
        let view = CameraUIView()
        view.backgroundColor = .black
        return view
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        guard let cameraView = uiView as? CameraUIView else { return }
        
        if isRecording && !cameraView.isCurrentlyRecording {
            cameraView.startRecording()
        } else if !isRecording && cameraView.isCurrentlyRecording {
            cameraView.stopRecording { url in
                DispatchQueue.main.async {
                    self.recordedVideoURL = url
                }
            }
        }
    }
}

// MARK: - Camera UI View

class CameraUIView: UIView {
    private var captureSession: AVCaptureSession?
    private var videoPreviewLayer: AVCaptureVideoPreviewLayer?
    private var movieOutput: AVCaptureMovieFileOutput?
    private var recordingDelegate: RecordingDelegate?
    
    var isCurrentlyRecording = false
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCamera()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupCamera()
    }
    
    override func layoutSubviews() {
        super.layoutSubviews()
        videoPreviewLayer?.frame = bounds
    }
    
    private func setupCamera() {
        captureSession = AVCaptureSession()
        captureSession?.sessionPreset = .high
        
        guard let backCamera = AVCaptureDevice.default(for: .video),
              let captureSession = captureSession else {
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            }
            
            // Add audio input
            if let audioDevice = AVCaptureDevice.default(for: .audio) {
                let audioInput = try AVCaptureDeviceInput(device: audioDevice)
                if captureSession.canAddInput(audioInput) {
                    captureSession.addInput(audioInput)
                }
            }
            
            // Add movie output
            movieOutput = AVCaptureMovieFileOutput()
            if let movieOutput = movieOutput, captureSession.canAddOutput(movieOutput) {
                captureSession.addOutput(movieOutput)
            }
            
            // Setup preview layer
            videoPreviewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
            videoPreviewLayer?.videoGravity = .resizeAspectFill
            videoPreviewLayer?.frame = bounds
            
            if let videoPreviewLayer = videoPreviewLayer {
                layer.addSublayer(videoPreviewLayer)
            }
            
            DispatchQueue.global(qos: .userInitiated).async {
                captureSession.startRunning()
            }
            
        } catch {
            print("Error setting up camera: \(error)")
        }
    }
    
    func startRecording() {
        guard let movieOutput = movieOutput, !movieOutput.isRecording else { return }
        
        let tempDir = FileManager.default.temporaryDirectory
        let fileName = "recording_\(Date().timeIntervalSince1970).mov"
        let fileURL = tempDir.appendingPathComponent(fileName)
        
        recordingDelegate = RecordingDelegate()
        movieOutput.startRecording(to: fileURL, recordingDelegate: recordingDelegate!)
        isCurrentlyRecording = true
    }
    
    func stopRecording(completion: @escaping (URL?) -> Void) {
        guard let movieOutput = movieOutput, movieOutput.isRecording else {
            completion(nil)
            return
        }
        
        recordingDelegate?.onFinish = completion
        movieOutput.stopRecording()
        isCurrentlyRecording = false
    }
}

// MARK: - Video Picker View

import PhotosUI

struct VideoPickerView: UIViewControllerRepresentable {
    @Binding var selectedVideoURL: URL?
    @Environment(\.dismiss) private var dismiss
    
    func makeUIViewController(context: Context) -> PHPickerViewController {
        var config = PHPickerConfiguration()
        config.filter = .videos
        config.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: config)
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: PHPickerViewController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, PHPickerViewControllerDelegate {
        let parent: VideoPickerView
        
        init(_ parent: VideoPickerView) {
            self.parent = parent
        }
        
        func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
            parent.dismiss()
            
            guard let result = results.first else { return }
            
            if result.itemProvider.hasItemConformingToTypeIdentifier(UTType.movie.identifier) {
                result.itemProvider.loadFileRepresentation(forTypeIdentifier: UTType.movie.identifier) { url, error in
                    if let error = error {
                        print("❌ Error loading video: \(error)")
                        return
                    }
                    
                    guard let url = url else { return }
                    
                    // Copy to temp directory since the original will be deleted
                    let tempDir = FileManager.default.temporaryDirectory
                    let fileName = "upload_\(Date().timeIntervalSince1970).mov"
                    let destURL = tempDir.appendingPathComponent(fileName)
                    
                    do {
                        if FileManager.default.fileExists(atPath: destURL.path) {
                            try FileManager.default.removeItem(at: destURL)
                        }
                        try FileManager.default.copyItem(at: url, to: destURL)
                        
                        DispatchQueue.main.async {
                            self.parent.selectedVideoURL = destURL
                            print("📹 Video selected: \(destURL.lastPathComponent)")
                        }
                    } catch {
                        print("❌ Error copying video: \(error)")
                    }
                }
            }
        }
    }
}

// MARK: - Recording Delegate

class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    var onFinish: ((URL?) -> Void)?
    
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error)")
            onFinish?(nil)
        } else {
            onFinish?(outputFileURL)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        TraineeDetailView(
            trainee: Trainee(
                id: "1",
                firstName: "John",
                lastName: "Doe",
                createdAt: Date()
            ),
            trainerId: "trainer-123"
        )
        .environmentObject(AuthenticationManager())
    }
}
