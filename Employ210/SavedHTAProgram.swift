//
//  SavedHTAProgram.swift
//  Employ210
//
//  Created by Manan Shukla on 4/6/26.
//  TraineeProgramStore.swift
//  Employ210
//
//  Store for managing saved HTA programs with UserDefaults persistence
//

import Foundation


struct SavedHTAProgram: Identifiable, Codable, Equatable {
    var id: String
    var traineeId: String
    var taskDescription: String
    var highLevelSteps: [String]
    var lowLevelSteps: [String]
    var observations: [String]
    var durationSec: Double?
    var createdAt: Date
    var s3Key: String?
}


@MainActor
final class TraineeProgramStore: ObservableObject {
    
    @Published private(set) var programs: [SavedHTAProgram] = []
    
    private let storageKey = "employ210_saved_programs"
    
    init() {
        loadFromStorage()
    }
        
    private func loadFromStorage() {
        if let data = UserDefaults.standard.data(forKey: storageKey) {
            do {
                let decoder = JSONDecoder()
                programs = try decoder.decode([SavedHTAProgram].self, from: data)
                print("✅ Loaded \(programs.count) saved programs from storage")
            } catch {
                print("❌ Failed to load programs: \(error)")
                programs = []
            }
        }
    }
        
    private func saveToStorage() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(programs)
            UserDefaults.standard.set(data, forKey: storageKey)
            print("✅ Saved \(programs.count) programs to storage")
        } catch {
            print("❌ Failed to save programs: \(error)")
        }
    }
    
    // MARK: - Add Program
    
    func addProgram(
        traineeId: String,
        taskDescription: String,
        highLevelSteps: [String],
        lowLevelSteps: [String],
        observations: [String],
        durationSec: Double? = nil,
        s3Key: String? = nil
    ) {
        let newProgram = SavedHTAProgram(
            id: UUID().uuidString,
            traineeId: traineeId,
            taskDescription: taskDescription,
            highLevelSteps: highLevelSteps,
            lowLevelSteps: lowLevelSteps,
            observations: observations,
            durationSec: durationSec,
            createdAt: Date(),
            s3Key: s3Key
        )
        
        programs.insert(newProgram, at: 0)  // Insert at beginning (newest first)
        saveToStorage()
    }
    
    // MARK: - Delete Program
    
    func deleteProgram(id: String) {
        programs.removeAll { $0.id == id }
        saveToStorage()
    }
    
    // MARK: - Get Programs for Trainee
    
    func programsForTrainee(id: String) -> [SavedHTAProgram] {
        return programs.filter { $0.traineeId == id }
    }
    
    // MARK: - Update Program S3 Key
    
    func updateS3Key(programId: String, s3Key: String) {
        if let index = programs.firstIndex(where: { $0.id == programId }) {
            programs[index].s3Key = s3Key
            saveToStorage()
        }
    }
    
    // MARK: - Reset
    
    func reset() {
        programs.removeAll()
        saveToStorage()
    }
}
