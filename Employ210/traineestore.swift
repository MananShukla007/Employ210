//
//  TraineeStore.swift
//  Employ210
//
//  Created by Manan Shukla
//
//  Data models and store for Trainers and Trainees with persistence
//

import Foundation

// MARK: - TRAINEE MODEL

struct Trainee: Identifiable, Codable, Equatable {
    var id: String
    var firstName: String
    var lastName: String
    var createdAt: Date
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
}

// MARK: - TRAINER MODEL

struct Trainer: Identifiable, Codable, Equatable {
    var id: String
    var firstName: String
    var lastName: String
    var createdAt: Date
    var trainees: [Trainee]
    
    var fullName: String {
        "\(firstName) \(lastName)"
    }
    
    var initials: String {
        let first = firstName.prefix(1).uppercased()
        let last = lastName.prefix(1).uppercased()
        return "\(first)\(last)"
    }
}

// MARK: - STORE WITH PERSISTENCE

@MainActor
final class TraineeStore: ObservableObject {
    
    // Published lists for UI
    @Published private(set) var trainers: [Trainer] = []
    @Published private(set) var trainees: [Trainee] = []  // Legacy - standalone trainees
    
    // UserDefaults keys
    private let trainersKey = "employ210_trainers"
    private let traineesKey = "employ210_trainees"
    
    // MARK: - Init
    init() {
        loadFromStorage()
    }
    
    // MARK: - Load from UserDefaults
    private func loadFromStorage() {
        // Load trainers
        if let data = UserDefaults.standard.data(forKey: trainersKey) {
            do {
                let decoder = JSONDecoder()
                trainers = try decoder.decode([Trainer].self, from: data)
                print("✅ Loaded \(trainers.count) trainers from storage")
            } catch {
                print("❌ Failed to load trainers: \(error)")
                trainers = []
            }
        }
        
        // Load legacy trainees (standalone)
        if let data = UserDefaults.standard.data(forKey: traineesKey) {
            do {
                let decoder = JSONDecoder()
                trainees = try decoder.decode([Trainee].self, from: data)
                print("✅ Loaded \(trainees.count) trainees from storage")
            } catch {
                print("❌ Failed to load trainees: \(error)")
                trainees = []
            }
        }
    }
    
    // MARK: - Save to UserDefaults
    private func saveTrainersToStorage() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trainers)
            UserDefaults.standard.set(data, forKey: trainersKey)
            print("✅ Saved \(trainers.count) trainers to storage")
        } catch {
            print("❌ Failed to save trainers: \(error)")
        }
    }
    
    private func saveTraineesToStorage() {
        do {
            let encoder = JSONEncoder()
            let data = try encoder.encode(trainees)
            UserDefaults.standard.set(data, forKey: traineesKey)
            print("✅ Saved \(trainees.count) trainees to storage")
        } catch {
            print("❌ Failed to save trainees: \(error)")
        }
    }
    
    // MARK: - Trainer Operations
    
    func addTrainer(firstName: String, lastName: String) {
        let newTrainer = Trainer(
            id: UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            createdAt: Date(),
            trainees: []
        )
        trainers.append(newTrainer)
        saveTrainersToStorage()
    }
    
    func removeTrainer(_ trainer: Trainer) {
        trainers.removeAll { $0.id == trainer.id }
        saveTrainersToStorage()
    }
    
    func removeTrainer(id: String) {
        trainers.removeAll { $0.id == id }
        saveTrainersToStorage()
    }
    
    // MARK: - Trainee Operations (within a Trainer)
    
    func addTrainee(to trainerId: String, firstName: String, lastName: String) {
        guard let index = trainers.firstIndex(where: { $0.id == trainerId }) else { return }
        
        let newTrainee = Trainee(
            id: UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            createdAt: Date()
        )
        
        trainers[index].trainees.append(newTrainee)
        saveTrainersToStorage()
    }
    
    func removeTrainee(from trainerId: String, traineeId: String) {
        guard let index = trainers.firstIndex(where: { $0.id == trainerId }) else { return }
        trainers[index].trainees.removeAll { $0.id == traineeId }
        saveTrainersToStorage()
    }
    
    func getTrainer(by id: String) -> Trainer? {
        return trainers.first { $0.id == id }
    }
    
    // MARK: - Legacy Trainee Operations (standalone)
    
    func add(firstName: String, lastName: String) async throws {
        let newTrainee = Trainee(
            id: UUID().uuidString,
            firstName: firstName,
            lastName: lastName,
            createdAt: Date()
        )
        trainees.append(newTrainee)
        saveTraineesToStorage()
    }
    
    func remove(_ trainee: Trainee) {
        trainees.removeAll { $0.id == trainee.id }
        saveTraineesToStorage()
    }
    
    func remove(id: String) {
        trainees.removeAll { $0.id == id }
        saveTraineesToStorage()
    }
    
    // MARK: - Reset
    
    func reset() {
        trainers.removeAll()
        trainees.removeAll()
        saveTrainersToStorage()
        saveTraineesToStorage()
    }
}
