//
//  HTAGeneratorView.swift
//  Employ210
//
//  HTA Generator – Two-Phase Session-Based API with Modern Dark UI
//  Includes Edit & Save to AWS S3 functionality 
//

import SwiftUI
import Foundation
import OSLog
import Amplify
import Lottie


// =====================================================================
// MARK: - Logging
// =====================================================================

enum HTALog {
    static let ui = Logger(subsystem: "com.employ210.app", category: "ui")
}

// =====================================================================
// MARK: - Config
// =====================================================================

struct AWSConfig {
    static let lambdaURL = "https://5ppdt2w3u74jpvv3v4mlcjanom0lwfxn.lambda-url.us-east-2.on.aws/"
    static let requestTimeout: TimeInterval = 300  // 5 minutes for complex HTA generation
    static let statusURL = "https://raw.githubusercontent.com/MananShukla007/Employ210/main/status.json"

    // S3 Configuration
    static let s3BucketName = "employ210-hta-storage5ca8e-dev"  // Your S3 bucket name
    static let s3Region = "us-east-1"                           // Your S3 region
}

// =====================================================================
// MARK: - Models
// =====================================================================

struct ClarifyRequest: Codable {
    let phase: String
    let query: String
    let description: String?
    let materials: [String]?
    let transcript: String?
    let sop_text: String?
    let custom_instructions: String?
    let folder: String?

    init(query: String, description: String? = nil, materials: [String]? = nil, transcript: String? = nil, sop_text: String? = nil, custom_instructions: String? = nil, folder: String? = nil) {
        self.phase = "clarify"
        self.query = query
        self.description = description
        self.materials = materials
        self.transcript = transcript
        self.sop_text = sop_text
        self.custom_instructions = custom_instructions
        self.folder = folder
    }

    func encode(to encoder: Encoder) throws {
        var c = encoder.container(keyedBy: CodingKeys.self)
        try c.encode(phase, forKey: .phase)
        try c.encode(query, forKey: .query)
        try c.encodeIfPresent(description, forKey: .description)
        try c.encodeIfPresent(materials, forKey: .materials)
        try c.encodeIfPresent(transcript, forKey: .transcript)
        try c.encodeIfPresent(sop_text, forKey: .sop_text)
        try c.encodeIfPresent(custom_instructions, forKey: .custom_instructions)
        try c.encodeIfPresent(folder, forKey: .folder)
    }
}

struct ClarifyQuestion: Codable, Identifiable {
    let id: String
    let question: String
    let type: String
    let choices: [String]?
    let why_needed: String?
    let default_if_skipped: AnyCodableValue?
}

struct ClarifyResponse: Codable {
    let phase: String?
    let session_id: String?
    let mode: String?
    let clarified_query: String?
    let assumptions: [String]?
    let questions: [ClarifyQuestion]?
    let context_to_append: String?
    let hta: HTAResult?
    let error: String?
    
    var isAutoRun: Bool {
        return phase == "run_result" || hta != nil
    }
}

struct RunRequest: Codable {
    let phase: String
    let session_id: String
    let answers: [String: AnyCodableValue]?
    
    init(session_id: String, answers: [String: AnyCodableValue]? = nil) {
        self.phase = "run"
        self.session_id = session_id
        self.answers = answers
    }
}

struct RunResponse: Codable {
    let phase: String?
    let session_id: String?
    let hta: HTAResult?
    let error: String?
}

struct HTAResult: Codable {
    var duration_sec: Double?
    var high_level_steps: [String]?
    var low_level_steps: [String]?
    var observations: [String]?
    var compliance_checklist: [ComplianceCheckItem]?
}

struct ComplianceCheckItem: Codable, Identifiable {
    var id: String { rule }
    let rule: String
    let satisfied: Bool
    let note: String?
}

// Editable version for the editor
struct EditableHTA: Identifiable {
    let id = UUID()
    var taskDescription: String
    var highLevelSteps: [EditableStep]
    var lowLevelSteps: [EditableStep]
    var observations: [EditableStep]
    var durationSec: Double?
}

struct EditableStep: Identifiable {
    let id = UUID()
    var text: String
    var isDeleted: Bool = false
}

struct AnyCodableValue: Codable {
    let value: Any
    
    init(_ value: Any) {
        self.value = value
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let str = try? container.decode(String.self) {
            value = str
        } else if let int = try? container.decode(Int.self) {
            value = int
        } else if let double = try? container.decode(Double.self) {
            value = double
        } else if let bool = try? container.decode(Bool.self) {
            value = bool
        } else if let arr = try? container.decode([String].self) {
            value = arr
        } else {
            value = ""
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        if let str = value as? String {
            try container.encode(str)
        } else if let int = value as? Int {
            try container.encode(int)
        } else if let double = value as? Double {
            try container.encode(double)
        } else if let bool = value as? Bool {
            try container.encode(bool)
        } else if let arr = value as? [String] {
            try container.encode(arr)
        } else {
            try container.encode(String(describing: value))
        }
    }
}

// =====================================================================
// MARK: - Helpers
// =====================================================================

func nowStamp() -> String {
    ISO8601DateFormatter().string(from: Date())
}

@MainActor
func uiConsole(_ msg: String, to lines: inout [String]) {
    let line = "[\(nowStamp())] \(msg)"
    lines.append(line)
    print(line)
    HTALog.ui.debug("\(msg, privacy: .public)")
}

// =====================================================================
// MARK: - Main View
// =====================================================================

struct HTAGeneratorView: View {
    
    // Optional IDs for saving programs to specific trainee with organized S3 structure
    var trainerId: String?
    var traineeId: String?
    var programStore: TraineeProgramStore?
    
    @EnvironmentObject var authManager: AuthenticationManager
    @Environment(\.dismiss) private var dismiss
    @StateObject private var vm = HTAViewModel()
    @FocusState private var focused: Bool
    
    @State private var showShareSheet = false
    @State private var showExportSuccess = false
    @State private var showInstructionsSheet = false
    @State private var showSignOutConfirm = false
    @State private var showEditView = false
    @State private var showSaveSuccess = false
    @State private var showSaveError = false
    @State private var saveErrorMessage = ""
    @State private var exportedFileURL: URL?
    
    // Default initializer for standalone use
    init() {
        self.trainerId = nil
        self.traineeId = nil
        self.programStore = nil
    }
    
    // Initializer with trainee context
    init(trainerId: String, traineeId: String, programStore: TraineeProgramStore) {
        self.trainerId = trainerId
        self.traineeId = traineeId
        self.programStore = programStore
    }
    
    // Legacy initializer (will look up trainerId)
    init(traineeId: String, programStore: TraineeProgramStore) {
        self.trainerId = nil  // Will be looked up
        self.traineeId = traineeId
        self.programStore = programStore
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
            
            // Subtle background circles
            GeometryReader { geo in
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.teal.opacity(0.12), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 200
                        )
                    )
                    .frame(width: 400, height: 400)
                    .offset(x: -100, y: -50)
                    .blur(radius: 60)
                
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.blue.opacity(0.1), Color.clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 150
                        )
                    )
                    .frame(width: 300, height: 300)
                    .offset(x: geo.size.width - 100, y: geo.size.height - 300)
                    .blur(radius: 50)
            }
            
            ScrollView {
                VStack(spacing: 24) {
                    
                    // Header with hamburger menu
                    HStack {
                        Spacer()
                        
                        // Hamburger Menu
                        Menu {
                            if vm.htaResult != nil {
                                Button {
                                    showEditView = true
                                } label: {
                                    Label("Edit & Save", systemImage: "pencil.and.outline")
                                }
                                
                                Button {
                                    shareHTA()
                                } label: {
                                    Label("Share HTA", systemImage: "square.and.arrow.up")
                                }
                                
                                Divider()
                            }
                            
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
                    .padding(.horizontal, 24)
                    .padding(.top, 8)
                    
                    // Title Section
                    VStack(spacing: 8) {
                        Image(systemName: "sparkles")
                            .font(.system(size: 40))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.blue, .teal],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                        
                        Text("HTA Generator")
                            .font(.system(size: 28, weight: .bold, design: .rounded))
                            .foregroundColor(.white)
                        
                        Text("Generate Hierarchical Task Analysis")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.6))
                    }
                    
                    // Input Card
                    VStack(alignment: .leading, spacing: 12) {
                        Text("Task Description")
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(.white.opacity(0.6))
                        
                        ZStack(alignment: .topLeading) {
                            TextEditor(text: $vm.descriptionText)
                                .focused($focused)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .frame(minHeight: 120)
                            
                            if vm.descriptionText.isEmpty {
                                Text("Describe the task in detail…")
                                    .foregroundStyle(.white.opacity(0.4))
                                    .padding(.top, 20)
                                    .padding(.leading, 16)
                                    .allowsHitTesting(false)
                            }
                        }
                        .background(Color.white.opacity(0.08))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.white.opacity(0.1), lineWidth: 1)
                        )
                    }
                    .padding(.horizontal, 24)

                    // Instructions Button
                    Button {
                        showInstructionsSheet = true
                    } label: {
                        HStack(spacing: 10) {
                            Image(systemName: vm.customInstructions.isEmpty ? "doc.text.badge.plus" : "doc.text.fill")
                                .font(.system(size: 15))
                                .foregroundStyle(vm.customInstructions.isEmpty ? .white.opacity(0.5) : .teal)
                            Text(vm.customInstructions.isEmpty ? "Add Instructions / SOP (Optional)" : "Instructions Added")
                                .font(.subheadline)
                                .foregroundColor(vm.customInstructions.isEmpty ? .white.opacity(0.6) : .teal)
                            Spacer()
                            if !vm.customInstructions.isEmpty {
                                Text("\(vm.customInstructions.count) chars")
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 3)
                                    .background(Color.teal.opacity(0.15))
                                    .clipShape(Capsule())
                                    .foregroundStyle(.teal)
                            }
                            Image(systemName: "chevron.right")
                                .font(.caption2)
                                .foregroundStyle(.white.opacity(0.3))
                        }
                        .padding(.horizontal, 16)
                        .padding(.vertical, 13)
                        .background(Color.white.opacity(0.06))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(
                                    vm.customInstructions.isEmpty ? Color.white.opacity(0.1) : Color.teal.opacity(0.35),
                                    lineWidth: 1
                                )
                        )
                    }
                    .padding(.horizontal, 24)

                    // Generate Button
                    Button {
                        focused = false
                        vm.startClarify()
                    } label: {
                        HStack(spacing: 10) {
                            if vm.isRunning {
                                ProgressView()
                                    .tint(.white)
                            } else {
                                Image(systemName: "sparkles")
                                    .font(.system(size: 16))
                            }
                            Text(vm.isRunning ? "Processing…" : "Generate HTA")
                                .font(.headline)
                        }
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(
                                colors: canGenerate ? [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)] : [Color.gray.opacity(0.3), Color.gray.opacity(0.3)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                        .shadow(color: canGenerate ? Color.blue.opacity(0.3) : Color.clear, radius: 10, x: 0, y: 5)
                    }
                    .disabled(!canGenerate)
                    .padding(.horizontal, 24)
                    
                    // Clarifying Questions
                    if !vm.questions.isEmpty && vm.htaResult == nil {
                        ClarifyQuestionsCard(
                            questions: vm.questions,
                            answers: $vm.answers,
                            isLoading: vm.isRunning,
                            onSubmit: { vm.submitAnswers() }
                        )
                        .padding(.horizontal, 24)
                    }
                    
                    // Results
                    if let result = vm.htaResult {
                        HTAResultCard(result: result)
                            .padding(.horizontal, 24)
                        
                        // Edit & Save / Share buttons after results
                        HStack(spacing: 12) {
                            Button {
                                showEditView = true
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "pencil.and.outline")
                                    Text("Edit & Save")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(
                                    LinearGradient(
                                        colors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)],
                                        startPoint: .leading,
                                        endPoint: .trailing
                                    )
                                )
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                            
                            Button {
                                shareHTA()
                            } label: {
                                HStack(spacing: 8) {
                                    Image(systemName: "square.and.arrow.up")
                                    Text("Share")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .frame(height: 50)
                                .background(Color.white.opacity(0.1))
                                .foregroundColor(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(Color.white.opacity(0.2), lineWidth: 1)
                                )
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                    
                    // Error Message
                    if let err = vm.errorMessage {
                        HTAErrorBanner(message: err)
                            .padding(.horizontal, 24)
                    }
                    
                    // Logs
                    HTALogCard(lines: vm.logLines)
                        .padding(.horizontal, 24)
                    
                    Spacer(minLength: 40)
                }
            }
            
            // Lottie Loading Overlay
            if vm.isRunning {
                HTALoadingOverlay()
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbarColorScheme(.dark, for: .navigationBar)
        .onTapGesture { focused = false }
        .sheet(isPresented: $showInstructionsSheet) {
            InstructionsInputView(customInstructions: $vm.customInstructions)
        }
        .sheet(isPresented: $showShareSheet) {
            if let url = exportedFileURL {
                ShareSheet(activityItems: [url])
            }
        }
        .fullScreenCover(isPresented: $showEditView) {
            if let result = vm.htaResult {
                HTAEditorView(
                    htaResult: result,
                    taskDescription: vm.descriptionText,
                    onSave: { editedHTA in
                        // Save to local program store first
                        if let traineeId = traineeId, let store = programStore {
                            Task { @MainActor in
                                store.addProgram(
                                    traineeId: traineeId,
                                    taskDescription: editedHTA.taskDescription,
                                    highLevelSteps: editedHTA.highLevelSteps.filter { !$0.isDeleted }.map { $0.text },
                                    lowLevelSteps: editedHTA.lowLevelSteps.filter { !$0.isDeleted }.map { $0.text },
                                    observations: editedHTA.observations.filter { !$0.isDeleted }.map { $0.text },
                                    durationSec: editedHTA.durationSec
                                )
                            }
                        }
                        
                        // Also save to S3
                        Task {
                            await saveToS3(editedHTA: editedHTA)
                        }
                    }
                )
            }
        }
        .alert("Saved!", isPresented: $showSaveSuccess) {
            Button("OK", role: .cancel) {
                // Navigate back after successful save
                dismiss()
            }
        } message: {
            Text("Your HTA program has been saved successfully.")
        }
        .alert("Save Failed", isPresented: $showSaveError) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(saveErrorMessage)
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
    
    private var canGenerate: Bool {
        !vm.isRunning && !vm.descriptionText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    // MARK: - Save to S3
    
    private func saveToS3(editedHTA: EditableHTA) async {
        do {
            let jsonData = try createHTAJSON(from: editedHTA)
            
            // Create filename with timestamp
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm-ss"
            let timestamp = dateFormatter.string(from: Date())
            
            // Use public/ prefix for guest access level
            let fileName = "public/hta_\(timestamp).json"
            
            print("📤 Uploading HTA to S3: \(fileName)")
            print("📦 Data size: \(jsonData.count) bytes")
            print("🔧 Checking Amplify configuration...")
            
            // Check if Amplify Storage is configured
            do {
                let _ = try await Amplify.Storage.getURL(key: "test")
            } catch {
                print("⚠️ Storage config check (expected to fail for non-existent key): \(error)")
            }
            
            // Upload to S3 using Amplify Storage
            let uploadTask = Amplify.Storage.uploadData(
                key: fileName,
                data: jsonData
            )
            
            _ = try await uploadTask.value
            print("✅ HTA saved to S3: \(fileName)")
            
            await MainActor.run {
                showSaveSuccess = true
            }
        } catch let storageError as StorageError {
            print("❌ StorageError: \(storageError)")
            print("❌ Error Description: \(storageError.errorDescription)")
            print("❌ Recovery Suggestion: \(storageError.recoverySuggestion ?? "None")")
            print("❌ Underlying Error: \(String(describing: storageError.underlyingError))")
            await MainActor.run {
                saveErrorMessage = "\(storageError.errorDescription)\n\(storageError.recoverySuggestion ?? "")"
                showSaveError = true
            }
        } catch {
            print("❌ Failed to save to S3: \(error)")
            print("❌ Error type: \(type(of: error))")
            print("❌ Error details: \(String(describing: error))")
            await MainActor.run {
                saveErrorMessage = error.localizedDescription
                showSaveError = true
            }
        }
    }
    
    private func createHTAJSON(from editedHTA: EditableHTA) throws -> Data {
        let htaDict: [String: Any] = [
            "task_description": editedHTA.taskDescription,
            "duration_sec": editedHTA.durationSec ?? 0,
            "high_level_steps": editedHTA.highLevelSteps.filter { !$0.isDeleted }.map { $0.text },
            "low_level_steps": editedHTA.lowLevelSteps.filter { !$0.isDeleted }.map { $0.text },
            "observations": editedHTA.observations.filter { !$0.isDeleted }.map { $0.text },
            "created_at": ISO8601DateFormatter().string(from: Date()),
            "app_version": "1.0"
        ]
        
        return try JSONSerialization.data(withJSONObject: htaDict, options: [.prettyPrinted, .sortedKeys])
    }
    
    // MARK: - Share Functions
    
    private func generateHTADocument() -> String {
        guard let result = vm.htaResult else { return "" }
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .long
        dateFormatter.timeStyle = .short
        
        var document = """
        ═══════════════════════════════════════════════════════════════
                        HIERARCHICAL TASK ANALYSIS (HTA)
        ═══════════════════════════════════════════════════════════════
        
        Generated: \(dateFormatter.string(from: Date()))
        App: Employ210
        
        ───────────────────────────────────────────────────────────────
        TASK DESCRIPTION
        ───────────────────────────────────────────────────────────────
        
        \(vm.descriptionText)
        
        """
        
        if let duration = result.duration_sec {
            document += "\nProcessing Time: \(String(format: "%.1f", duration)) seconds\n"
        }
        
        if let highLevel = result.high_level_steps, !highLevel.isEmpty {
            document += "\n───────────────────────────────────────────────────────────────\nHIGH-LEVEL STEPS\n───────────────────────────────────────────────────────────────\n\n"
            for (index, step) in highLevel.enumerated() {
                document += "\(index + 1). \(step)\n"
            }
        }
        
        if let lowLevel = result.low_level_steps, !lowLevel.isEmpty {
            document += "\n───────────────────────────────────────────────────────────────\nDETAILED STEPS\n───────────────────────────────────────────────────────────────\n\n"
            for (index, step) in lowLevel.enumerated() {
                document += "   \(index + 1). \(step)\n"
            }
        }
        
        if let observations = result.observations, !observations.isEmpty {
            document += "\n───────────────────────────────────────────────────────────────\nOBSERVATIONS & NOTES\n───────────────────────────────────────────────────────────────\n\n"
            for observation in observations {
                document += "• \(observation)\n"
            }
        }
        
        document += "\n═══════════════════════════════════════════════════════════════\n                          END OF DOCUMENT\n═══════════════════════════════════════════════════════════════\n\nGenerated by Employ210 - Empowering Employment Success"
        
        return document
    }
    
    private func shareHTA() {
        let document = generateHTADocument()
        
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd_HH-mm"
        let timestamp = dateFormatter.string(from: Date())
        let fileName = "HTA_\(timestamp).txt"
        
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
}

// =====================================================================
// MARK: - HTA Editor View
// =====================================================================

struct HTAEditorView: View {
    @Environment(\.dismiss) private var dismiss
    
    let htaResult: HTAResult
    let taskDescription: String
    let onSave: (EditableHTA) -> Void
    
    @State private var editableHTA: EditableHTA
    @State private var isSaving = false
    @State private var showDeleteAllConfirm = false
    @State private var sectionToDelete: String?
    
    init(htaResult: HTAResult, taskDescription: String, onSave: @escaping (EditableHTA) -> Void) {
        self.htaResult = htaResult
        self.taskDescription = taskDescription
        self.onSave = onSave
        
        // Initialize editable HTA
        _editableHTA = State(initialValue: EditableHTA(
            taskDescription: taskDescription,
            highLevelSteps: (htaResult.high_level_steps ?? []).map { EditableStep(text: $0) },
            lowLevelSteps: (htaResult.low_level_steps ?? []).map { EditableStep(text: $0) },
            observations: (htaResult.observations ?? []).map { EditableStep(text: $0) },
            durationSec: htaResult.duration_sec
        ))
    }
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Background
                Color(red: 0.05, green: 0.10, blue: 0.15)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Image(systemName: "pencil.and.outline")
                                .font(.system(size: 36))
                                .foregroundStyle(.blue)
                            
                            Text("Edit HTA")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                            
                            Text("Remove or edit steps before saving")
                                .font(.subheadline)
                                .foregroundStyle(.white.opacity(0.6))
                        }
                        .padding(.top, 16)
                        
                        // Task Description
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Task Description")
                                .font(.headline)
                                .foregroundColor(.white)
                            
                            TextEditor(text: $editableHTA.taskDescription)
                                .foregroundColor(.white)
                                .scrollContentBackground(.hidden)
                                .padding(12)
                                .frame(minHeight: 80)
                                .background(Color.white.opacity(0.08))
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, 24)
                        
                        // High-Level Steps
                        if !editableHTA.highLevelSteps.isEmpty {
                            EditableSectionView(
                                title: "High-Level Steps",
                                icon: "list.bullet.rectangle",
                                color: .teal,
                                steps: $editableHTA.highLevelSteps,
                                onDeleteAll: {
                                    sectionToDelete = "high"
                                    showDeleteAllConfirm = true
                                }
                            )
                        }
                        
                        // Low-Level Steps
                        if !editableHTA.lowLevelSteps.isEmpty {
                            EditableSectionView(
                                title: "Detailed Steps",
                                icon: "checklist",
                                color: .blue,
                                steps: $editableHTA.lowLevelSteps,
                                onDeleteAll: {
                                    sectionToDelete = "low"
                                    showDeleteAllConfirm = true
                                }
                            )
                        }
                        
                        // Observations
                        if !editableHTA.observations.isEmpty {
                            EditableSectionView(
                                title: "Observations",
                                icon: "lightbulb.fill",
                                color: .orange,
                                steps: $editableHTA.observations,
                                onDeleteAll: {
                                    sectionToDelete = "obs"
                                    showDeleteAllConfirm = true
                                }
                            )
                        }
                        
                        // Save Button
                        Button {
                            saveHTA()
                        } label: {
                            HStack(spacing: 10) {
                                if isSaving {
                                    ProgressView()
                                        .tint(.white)
                                } else {
                                    Image(systemName: "icloud.and.arrow.up")
                                }
                                Text(isSaving ? "Saving to Cloud..." : "Save to Cloud")
                                    .font(.headline)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: 54)
                            .background(
                                LinearGradient(
                                    colors: [Color(red: 0.3, green: 0.7, blue: 0.6), Color(red: 0.2, green: 0.5, blue: 0.5)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .foregroundColor(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 14))
                            .shadow(color: Color.teal.opacity(0.4), radius: 10, x: 0, y: 5)
                        }
                        .disabled(isSaving)
                        .padding(.horizontal, 24)
                        .padding(.bottom, 40)
                    }
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
            .alert("Delete All Steps?", isPresented: $showDeleteAllConfirm) {
                Button("Cancel", role: .cancel) {
                    sectionToDelete = nil
                }
                Button("Delete All", role: .destructive) {
                    deleteAllInSection()
                }
            } message: {
                Text("Are you sure you want to delete all steps in this section?")
            }
        }
    }
    
    private func saveHTA() {
        isSaving = true
        onSave(editableHTA)
        
        // Delay dismiss to show saving state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            isSaving = false
            dismiss()
        }
    }
    
    private func deleteAllInSection() {
        switch sectionToDelete {
        case "high":
            for i in editableHTA.highLevelSteps.indices {
                editableHTA.highLevelSteps[i].isDeleted = true
            }
        case "low":
            for i in editableHTA.lowLevelSteps.indices {
                editableHTA.lowLevelSteps[i].isDeleted = true
            }
        case "obs":
            for i in editableHTA.observations.indices {
                editableHTA.observations[i].isDeleted = true
            }
        default:
            break
        }
        sectionToDelete = nil
    }
}

// MARK: - Editable Section View

struct EditableSectionView: View {
    let title: String
    let icon: String
    let color: Color
    @Binding var steps: [EditableStep]
    let onDeleteAll: () -> Void
    
    @State private var isReorderMode = false
    
    var visibleSteps: [EditableStep] {
        steps.filter { !$0.isDeleted }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.headline)
                    .foregroundColor(.white)
                
                Spacer()
                
                // Reorder Toggle Button
                Button {
                    withAnimation {
                        isReorderMode.toggle()
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: isReorderMode ? "checkmark" : "arrow.up.arrow.down")
                            .font(.caption)
                        Text(isReorderMode ? "Done" : "Reorder")
                            .font(.caption)
                    }
                    .foregroundStyle(isReorderMode ? .green : .white.opacity(0.7))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(isReorderMode ? Color.green.opacity(0.15) : Color.white.opacity(0.1))
                    .clipShape(Capsule())
                }
                
                // Delete All Button
                Button {
                    onDeleteAll()
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "trash")
                            .font(.caption)
                        Text("Clear All")
                            .font(.caption)
                    }
                    .foregroundStyle(.red.opacity(0.8))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color.red.opacity(0.15))
                    .clipShape(Capsule())
                }
            }
            
            if visibleSteps.isEmpty {
                Text("All steps removed")
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.4))
                    .padding(.vertical, 20)
                    .frame(maxWidth: .infinity)
            } else if isReorderMode {
                // Reorder Mode - Show drag handles
                ReorderableStepsList(steps: $steps, color: color)
            } else {
                // Normal Edit Mode
                ForEach(steps.indices, id: \.self) { index in
                    if !steps[index].isDeleted {
                        EditableStepRow(
                            step: $steps[index],
                            index: visibleSteps.firstIndex(where: { $0.id == steps[index].id }) ?? 0,
                            color: color
                        )
                    }
                }
            }
        }
        .padding(16)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .padding(.horizontal, 24)
    }
}

// MARK: - Reorderable Steps List

struct ReorderableStepsList: View {
    @Binding var steps: [EditableStep]
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            ForEach(Array(steps.enumerated().filter { !$0.element.isDeleted }), id: \.element.id) { index, step in
                ReorderableStepRow(
                    step: step,
                    index: index,
                    color: color,
                    onMoveUp: {
                        moveStep(step, direction: -1)
                    },
                    onMoveDown: {
                        moveStep(step, direction: 1)
                    },
                    canMoveUp: canMoveUp(step),
                    canMoveDown: canMoveDown(step)
                )
            }
        }
    }
    
    private func canMoveUp(_ step: EditableStep) -> Bool {
        let visibleSteps = steps.filter { !$0.isDeleted }
        guard let index = visibleSteps.firstIndex(where: { $0.id == step.id }) else { return false }
        return index > 0
    }
    
    private func canMoveDown(_ step: EditableStep) -> Bool {
        let visibleSteps = steps.filter { !$0.isDeleted }
        guard let index = visibleSteps.firstIndex(where: { $0.id == step.id }) else { return false }
        return index < visibleSteps.count - 1
    }
    
    private func moveStep(_ step: EditableStep, direction: Int) {
        // Get visible indices
        let visibleIndices = steps.enumerated().filter { !$0.element.isDeleted }.map { $0.offset }
        
        guard let currentVisibleIndex = steps.filter({ !$0.isDeleted }).firstIndex(where: { $0.id == step.id }),
              let currentActualIndex = steps.firstIndex(where: { $0.id == step.id }) else { return }
        
        let newVisibleIndex = currentVisibleIndex + direction
        
        guard newVisibleIndex >= 0 && newVisibleIndex < visibleIndices.count else { return }
        
        let targetActualIndex = visibleIndices[newVisibleIndex]
        
        withAnimation(.easeInOut(duration: 0.2)) {
            steps.swapAt(currentActualIndex, targetActualIndex)
        }
    }
}

// MARK: - Reorderable Step Row

struct ReorderableStepRow: View {
    let step: EditableStep
    let index: Int
    let color: Color
    let onMoveUp: () -> Void
    let onMoveDown: () -> Void
    let canMoveUp: Bool
    let canMoveDown: Bool
    
    var body: some View {
        HStack(spacing: 12) {
            // Drag handle indicator
            Image(systemName: "line.3.horizontal")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(.white.opacity(0.4))
            
            // Number badge
            Text("\(index + 1)")
                .font(.caption.bold())
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            // Step text
            Text(step.text)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
                .lineLimit(2)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Move buttons
            HStack(spacing: 4) {
                Button {
                    onMoveUp()
                } label: {
                    Image(systemName: "chevron.up")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(canMoveUp ? color : .white.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .background(canMoveUp ? color.opacity(0.2) : Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .disabled(!canMoveUp)
                
                Button {
                    onMoveDown()
                } label: {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundStyle(canMoveDown ? color : .white.opacity(0.2))
                        .frame(width: 32, height: 32)
                        .background(canMoveDown ? color.opacity(0.2) : Color.white.opacity(0.05))
                        .clipShape(Circle())
                }
                .disabled(!canMoveDown)
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Editable Step Row

struct EditableStepRow: View {
    @Binding var step: EditableStep
    let index: Int
    let color: Color
    
    @State private var isEditing = false
    
    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            // Number badge
            Text("\(index + 1)")
                .font(.caption.bold())
                .foregroundColor(color)
                .frame(width: 24, height: 24)
                .background(color.opacity(0.2))
                .clipShape(Circle())
            
            // Text content
            if isEditing {
                TextField("Step text", text: $step.text, axis: .vertical)
                    .foregroundColor(.white)
                    .padding(8)
                    .background(Color.white.opacity(0.1))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
            } else {
                Text(step.text)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))
                    .frame(maxWidth: .infinity, alignment: .leading)
            }
            
            // Action buttons
            HStack(spacing: 8) {
                // Edit button
                Button {
                    isEditing.toggle()
                } label: {
                    Image(systemName: isEditing ? "checkmark" : "pencil")
                        .font(.caption)
                        .foregroundStyle(isEditing ? .green : .white.opacity(0.5))
                        .frame(width: 28, height: 28)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Circle())
                }
                
                // Delete button
                Button {
                    withAnimation {
                        step.isDeleted = true
                    }
                } label: {
                    Image(systemName: "xmark")
                        .font(.caption)
                        .foregroundStyle(.red.opacity(0.8))
                        .frame(width: 28, height: 28)
                        .background(Color.red.opacity(0.15))
                        .clipShape(Circle())
                }
            }
        }
        .padding(12)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// =====================================================================
// MARK: - Share Sheet (UIKit Bridge)
// =====================================================================

struct ShareSheet: UIViewControllerRepresentable {
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

// =====================================================================
// MARK: - Clarifying Questions Card
// =====================================================================

struct ClarifyQuestionsCard: View {
    let questions: [ClarifyQuestion]
    @Binding var answers: [String: String]
    let isLoading: Bool
    let onSubmit: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            HStack {
                Image(systemName: "questionmark.circle.fill")
                    .foregroundStyle(.blue)
                Text("Please answer these questions")
                    .font(.headline)
                    .foregroundColor(.white)
            }
            
            ForEach(questions) { q in
                QuestionRow(question: q, answers: $answers)
            }
            
            Button(action: onSubmit) {
                HStack {
                    if isLoading {
                        ProgressView().tint(.white)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Submit & Generate")
                            .font(.headline)
                    }
                }
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(
                    LinearGradient(
                        colors: [Color(red: 0.2, green: 0.5, blue: 0.8), Color(red: 0.1, green: 0.4, blue: 0.7)],
                        startPoint: .leading,
                        endPoint: .trailing
                    )
                )
                .foregroundColor(.white)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(isLoading)
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.blue.opacity(0.3), lineWidth: 1)
        )
    }
}

// MARK: - Question Row

struct QuestionRow: View {
    let question: ClarifyQuestion
    @Binding var answers: [String: String]
    
    private var currentAnswer: String {
        answers[question.id] ?? ""
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(question.question)
                .font(.subheadline.weight(.medium))
                .foregroundColor(.white)
            
            if let why = question.why_needed, !why.isEmpty {
                Text(why)
                    .font(.caption)
                    .foregroundStyle(.white.opacity(0.5))
            }
            
            if question.type == "single_choice", let choices = question.choices, !choices.isEmpty {
                Menu {
                    ForEach(choices, id: \.self) { choice in
                        Button(choice) {
                            answers[question.id] = choice
                        }
                    }
                } label: {
                    HStack {
                        Text(currentAnswer.isEmpty ? "Select an option" : currentAnswer)
                            .foregroundColor(currentAnswer.isEmpty ? .white.opacity(0.4) : .white)
                        Spacer()
                        Image(systemName: "chevron.down")
                            .foregroundStyle(.white.opacity(0.5))
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            } else {
                TextField("Your answer", text: Binding(
                    get: { answers[question.id] ?? "" },
                    set: { answers[question.id] = $0 }
                ))
                .foregroundColor(.white)
                .padding(.horizontal, 16)
                .padding(.vertical, 14)
                .background(Color.white.opacity(0.08))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .padding()
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// =====================================================================
// MARK: - Results Card
// =====================================================================

struct HTAResultCard: View {
    let result: HTAResult
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            HStack {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .font(.title2)
                Text("HTA Generated")
                    .font(.headline)
                    .foregroundColor(.white)
                Spacer()
                if let d = result.duration_sec {
                    Text("\(String(format: "%.1f", d))s")
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(Color.white.opacity(0.1))
                        .clipShape(Capsule())
                        .foregroundStyle(.white.opacity(0.7))
                }
            }
            
            if let high = result.high_level_steps, !high.isEmpty {
                HTAStepSection(title: "High-Level Steps", icon: "list.bullet.rectangle", color: .teal) {
                    ForEach(Array(high.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Text("\(index + 1)")
                                .font(.caption.bold())
                                .foregroundColor(.teal)
                                .frame(width: 20, height: 20)
                                .background(Color.teal.opacity(0.2))
                                .clipShape(Circle())
                            Text(step)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.9))
                        }
                    }
                }
            }
            
            if let low = result.low_level_steps, !low.isEmpty {
                HTAStepSection(title: "Detailed Steps", icon: "checklist", color: .blue) {
                    ForEach(Array(low.enumerated()), id: \.offset) { index, step in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundStyle(.blue)
                                .font(.system(size: 14))
                            Text(step)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.85))
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            
            if let obs = result.observations, !obs.isEmpty {
                HTAStepSection(title: "Observations", icon: "lightbulb.fill", color: .orange) {
                    ForEach(obs, id: \.self) { observation in
                        HStack(alignment: .top, spacing: 12) {
                            Image(systemName: "arrow.right")
                                .foregroundStyle(.orange.opacity(0.7))
                                .font(.system(size: 12))
                            Text(observation)
                                .font(.subheadline)
                                .foregroundColor(.white.opacity(0.7))
                        }
                    }
                }
            }

            if let checklist = result.compliance_checklist, !checklist.isEmpty {
                ComplianceChecklistView(items: checklist)
            }
        }
        .padding(20)
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.green.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HTAStepSection<Content: View>: View {
    let title: String
    let icon: String
    let color: Color
    @ViewBuilder let content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .foregroundStyle(color)
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(color)
            }
            
            VStack(alignment: .leading, spacing: 8) {
                content
            }
            .padding(.leading, 4)
        }
        .padding()
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// =====================================================================
// MARK: - Compliance Checklist
// =====================================================================

struct ComplianceChecklistView: View {
    let items: [ComplianceCheckItem]

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 8) {
                Image(systemName: "checklist")
                    .foregroundStyle(.purple)
                Text("Compliance Checklist")
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.purple)
            }

            VStack(alignment: .leading, spacing: 8) {
                ForEach(items) { item in
                    ComplianceCheckRow(item: item)
                }
            }
        }
        .padding()
        .background(Color.purple.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct ComplianceCheckRow: View {
    let item: ComplianceCheckItem

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: item.satisfied ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                .foregroundStyle(item.satisfied ? .green : .orange)
                .font(.system(size: 16))
                .padding(.top, 1)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.rule)
                    .font(.subheadline)
                    .foregroundColor(.white.opacity(0.9))

                if let note = item.note, !note.isEmpty {
                    Text(note)
                        .font(.caption)
                        .foregroundStyle(.white.opacity(0.55))
                }
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(item.satisfied ? Color.green.opacity(0.06) : Color.orange.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// =====================================================================
// MARK: - Error Banner & Log Card
// =====================================================================

struct HTAErrorBanner: View {
    let message: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: "exclamationmark.triangle.fill")
                .foregroundStyle(.red)
            Text(message)
                .font(.subheadline)
                .foregroundColor(.white.opacity(0.9))
            Spacer()
        }
        .padding()
        .background(Color.red.opacity(0.15))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.red.opacity(0.3), lineWidth: 1)
        )
    }
}

struct HTALogCard: View {
    let lines: [String]
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    isExpanded.toggle()
                }
            } label: {
                HStack {
                    Image(systemName: "terminal")
                        .foregroundStyle(.white.opacity(0.5))
                    Text("Logs")
                        .font(.subheadline.weight(.medium))
                        .foregroundColor(.white.opacity(0.7))
                    Spacer()
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .foregroundStyle(.white.opacity(0.5))
                        .font(.caption)
                }
                .padding()
            }
            
            if isExpanded {
                Divider().background(Color.white.opacity(0.1))
                
                ScrollView {
                    VStack(alignment: .leading, spacing: 4) {
                        if lines.isEmpty {
                            Text("No logs yet")
                                .font(.caption)
                                .foregroundStyle(.white.opacity(0.4))
                        } else {
                            ForEach(lines, id: \.self) { line in
                                Text(line)
                                    .font(.system(size: 11, design: .monospaced))
                                    .foregroundStyle(.white.opacity(0.6))
                            }
                        }
                    }
                    .padding()
                }
                .frame(maxHeight: 200)
            }
        }
        .background(Color.white.opacity(0.05))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(Color.white.opacity(0.1), lineWidth: 1)
        )
    }
}

// =====================================================================
// MARK: - ViewModel
// =====================================================================

@MainActor
final class HTAViewModel: ObservableObject {
    
    @Published var descriptionText = ""
    @Published var customInstructions = ""
    @Published var isRunning = false
    @Published var htaResult: HTAResult?
    @Published var errorMessage: String?
    @Published var logLines: [String] = []
    
    @Published var sessionId: String?
    @Published var questions: [ClarifyQuestion] = []
    @Published var answers: [String: String] = [:]
    
    func startClarify() {
        Task { await doClarify() }
    }
    
    private func doClarify() async {
        isRunning = true
        logLines.removeAll()
        errorMessage = nil
        htaResult = nil
        sessionId = nil
        questions = []
        answers = [:]
        
        uiConsole("Starting clarify phase...", to: &logLines)
        
        let query = descriptionText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !query.isEmpty else {
            errorMessage = "Please enter a task."
            isRunning = false
            return
        }
        
        do {
            let user = try await Amplify.Auth.getCurrentUser()
            uiConsole("Authenticated user: \(user.userId)", to: &logLines)
        } catch {
            errorMessage = "You must be signed in."
            isRunning = false
            return
        }
        
        do {
            let trimmedInstructions = customInstructions.trimmingCharacters(in: .whitespacesAndNewlines)
            let savedFolder = UserDefaults.standard.string(forKey: "selectedFolder")
            let request = ClarifyRequest(
                query: query,
                custom_instructions: trimmedInstructions.isEmpty ? nil : trimmedInstructions,
                folder: savedFolder?.isEmpty == false ? savedFolder : nil
            )
            let response = try await callClarifyAPI(request: request)
            
            if let err = response.error {
                errorMessage = err
                isRunning = false
                return
            }
            
            sessionId = response.session_id
            uiConsole("Session ID: \(response.session_id ?? "none")", to: &logLines)
            
            if response.isAutoRun, let hta = response.hta {
                uiConsole("HTA auto-generated", to: &logLines)
                htaResult = hta
                isRunning = false
                return
            }
            
            if let qs = response.questions, !qs.isEmpty {
                uiConsole("Received \(qs.count) clarifying question(s)", to: &logLines)
                questions = qs
                for q in qs {
                    if let def = q.default_if_skipped {
                        answers[q.id] = String(describing: def.value)
                    }
                }
                isRunning = false
                return
            }
            
            uiConsole("Proceeding to run phase...", to: &logLines)
            await doRun()
            
        } catch {
            errorMessage = error.localizedDescription
            uiConsole("Error: \(error.localizedDescription)", to: &logLines)
        }
        
        isRunning = false
    }
    
    func submitAnswers() {
        Task { await doRun() }
    }
    
    private func doRun() async {
        guard let sid = sessionId else {
            errorMessage = "No session ID. Please start over."
            return
        }
        
        isRunning = true
        uiConsole("Running HTA generation...", to: &logLines)
        
        do {
            var codableAnswers: [String: AnyCodableValue] = [:]
            for (key, value) in answers {
                codableAnswers[key] = AnyCodableValue(value)
            }
            
            let request = RunRequest(session_id: sid, answers: codableAnswers.isEmpty ? nil : codableAnswers)
            let response = try await callRunAPI(request: request)
            
            if let err = response.error {
                errorMessage = err
                isRunning = false
                return
            }
            
            if let hta = response.hta {
                uiConsole("HTA generated successfully!", to: &logLines)
                htaResult = hta
                questions = []
            } else {
                errorMessage = "No HTA result returned."
            }
            
        } catch {
            errorMessage = error.localizedDescription
            uiConsole("Error: \(error.localizedDescription)", to: &logLines)
        }
        
        isRunning = false
    }
    
    private func callClarifyAPI(request: ClarifyRequest) async throws -> ClarifyResponse {
        guard let url = URL(string: AWSConfig.lambdaURL) else {
            throw URLError(.badURL)
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AWSConfig.requestTimeout
        config.timeoutIntervalForResource = AWSConfig.requestTimeout
        let session = URLSession(configuration: config)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(request)
        
        uiConsole("Calling clarify API...", to: &logLines)
        
        let (data, response) = try await session.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        uiConsole("Status: \(httpResponse.statusCode)", to: &logLines)
        
        if httpResponse.statusCode != 200 {
            if let rawString = String(data: data, encoding: .utf8) {
                throw NSError(domain: "HTA", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Server error: \(rawString.prefix(200))"])
            }
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(ClarifyResponse.self, from: data)
    }
    
    private func callRunAPI(request: RunRequest) async throws -> RunResponse {
        guard let url = URL(string: AWSConfig.lambdaURL) else {
            throw URLError(.badURL)
        }
        
        let config = URLSessionConfiguration.default
        config.timeoutIntervalForRequest = AWSConfig.requestTimeout
        config.timeoutIntervalForResource = AWSConfig.requestTimeout
        let session = URLSession(configuration: config)
        
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")
        req.httpBody = try JSONEncoder().encode(request)
        
        uiConsole("Calling run API...", to: &logLines)
        
        let (data, response) = try await session.data(for: req)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        uiConsole("Status: \(httpResponse.statusCode)", to: &logLines)
        
        if httpResponse.statusCode != 200 {
            throw URLError(.badServerResponse)
        }
        
        return try JSONDecoder().decode(RunResponse.self, from: data)
    }
}

// =====================================================================
// MARK: - HTA Loading Overlay (Lottie Animation)
// =====================================================================

struct HTALoadingOverlay: View {
    @State private var loadingText = "Analyzing your task..."
    @State private var dotCount = 0
    
    let loadingMessages = [
        "Analyzing your task...",
        "Breaking down the steps...",
        "Identifying sub-tasks...",
        "Generating hierarchy...",
        "Almost there..."
    ]
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    let dotTimer = Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        ZStack {
            // Blurred background
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 30) {
                // Lottie Animation
                LottieView(animation: .named("HTALoadingAnimation"))
                    .playbackMode(.playing(.toProgress(1, loopMode: .loop)))
                    .frame(width: 280, height: 280)
                
                // Loading text with animated dots
                VStack(spacing: 12) {
                    Text(loadingText)
                        .font(.title3.bold())
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    // Animated dots
                    HStack(spacing: 8) {
                        ForEach(0..<3) { index in
                            Circle()
                                .fill(Color.teal)
                                .frame(width: 10, height: 10)
                                .opacity(dotCount > index ? 1.0 : 0.3)
                                .animation(.easeInOut(duration: 0.3), value: dotCount)
                        }
                    }
                    
                    Text("This may take up to a minute")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.5))
                }
            }
            .padding(40)
        }
        .onReceive(timer) { _ in
            withAnimation {
                if let currentIndex = loadingMessages.firstIndex(of: loadingText) {
                    let nextIndex = (currentIndex + 1) % loadingMessages.count
                    loadingText = loadingMessages[nextIndex]
                }
            }
        }
        .onReceive(dotTimer) { _ in
            dotCount = (dotCount + 1) % 4
        }
    }
}

// =====================================================================
// MARK: - Preview
// =====================================================================

#Preview {
    NavigationStack {
        HTAGeneratorView()
            .environmentObject(AuthenticationManager())
    }
}

#Preview("HTA Editor") {
    HTAEditorView(
        htaResult: HTAResult(
            duration_sec: 12.5,
            high_level_steps: ["Gather materials", "Prepare workspace", "Complete task", "Clean up"],
            low_level_steps: ["Get scissors from drawer", "Lay materials on table"],
            observations: ["Check safety precautions first"]
        ),
        taskDescription: "Making a sandwich",
        onSave: { _ in }
    )
}
