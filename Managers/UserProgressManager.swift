//
//  UserProgressManager.swift
//  SonicGames
//
//  Created by Jesse Iriah on 07/11/2024.
//
import SwiftUI
import Foundation

// UserProgressManager is responsible for managing  player progress across different games.
// It handles saving and loading game data, awarding tokens, tracking wins, and managing the user's progress in levels.
// This class also manages the reward collection status and resets user data when necessary.

class UserProgressManager: ObservableObject {
    static let shared = UserProgressManager()
    private let defaults = UserDefaults.standard
    
    // MARK: - Initialisation
    private init() {
        loadGameData()
        loadRewardCollectedStatus()
    }
    
    // MARK: - Properties
    @Published private(set) var totalTokens: Int = 0
    @Published private(set) var totalWins: Int = 0
    // Dictionary to store the furthest level completed for each game's mode
    @Published private(set) var gameProgress: [GameDataManager.GameKey: [GameDataManager.GameModeKey: Int]] = [:]
    @Published private(set) var rewardCollected: Bool = false 
    
    // MARK: - Getters
    // View total wins
    func getTotalWins() -> Int {
        return totalWins
    }
    
    // View total cash
    func getTotalCash() -> Int {
        return totalTokens
    }
    
    // View game progress
    func getGameProgress(for gameKey: GameDataManager.GameKey, modeKey: GameDataManager.GameModeKey) -> Int {
        return gameProgress[gameKey]?[modeKey] ?? 0 // Return 0 if no progress found
    }
    
    
    // MARK: - Data Management
    // Save the game data (cash , wins , progress) using UserDefaults
    func saveGameData() {
        // Encode gameProgress to Data
        if let encodedProgress = try? JSONEncoder().encode(gameProgress) {
            defaults.set(encodedProgress, forKey: "gameProgress")
        } else {
            print("Error encoding gameProgress") // Handle encoding errors
        }
        defaults.set(totalTokens, forKey: "totalTokens")
        defaults.set(totalWins, forKey: "totalWins")
        
    }
    // Load the game data from User Defaults
    func loadGameData() {
        totalTokens = defaults.integer(forKey: "totalTokens")
        totalWins = defaults.integer(forKey: "totalWins")
        // Decode gameProgress from Data
        if let progressData = defaults.data(forKey: "gameProgress"),
           let decodedProgress = try? JSONDecoder().decode([GameDataManager.GameKey: [GameDataManager.GameModeKey: Int]].self, from: progressData) {
            gameProgress = decodedProgress
        } else {
            print("Error decoding gameProgress") // Handle decoding errors
            gameProgress = [:] // Initialize with an empty dictionary if decoding fails
        }
    }
    
    
    
    // MARK: - Game Progress Management
    
    // Award the user with a specific cash amount
    func awardCash(amount: Int) {
        totalTokens += amount
        saveGameData()  // Automatically save progress
    }
    
    // Update wins count
    func incrementWins() {
        totalWins += 1
        print("Wins incremented")
        saveGameData()  // Automatically save progress
    }
    
    // Remove a specific cash amount from the user
    func deductCash(amount: Int) {
        if totalTokens >= amount {
            totalTokens -= amount
            saveGameData()  // Automatically save progress
        }
    }
    
    // Update game progress with furthest(max) level
    func updateGameProgress(gameKey: GameDataManager.GameKey, modeKey: GameDataManager.GameModeKey, maxLevelIndex: Int) {
        let maxLevelIndex = max(1, min(maxLevelIndex, GameDataManager.shared.getGameProperties(for: gameKey)?.levelCount ?? 25))
        
        if gameProgress[gameKey] == nil {
            gameProgress[gameKey] = [:]
        }
        gameProgress[gameKey]?[modeKey] = maxLevelIndex // Update or insert level progress for the specific mode
        saveGameData()
    }
    
    // Reset all user progress to default values (reset wins and progress)
    func resetProgress() {
        totalWins = 0
        SessionManager.shared.clearData()
        gameProgress.removeAll()  // Clear game progress
        
        saveGameData()  // Save the reset data
    }
    
    // MARK: - Reward Management
    // Save and load reward collected status
    func markRewardAsCollected() {
        rewardCollected = true
        UserDefaults.standard.set(true, forKey: "rewardCollected")
    }
    
    func loadRewardCollectedStatus() {
        rewardCollected = UserDefaults.standard.bool(forKey: "rewardCollected")
    }
    
    func resetRewardCollectedStatus() {
        rewardCollected = false
        UserDefaults.standard.set(false, forKey: "rewardCollected")
    }
    
    // Check if reward can be collected today
    func canCollectDailyReward() -> Bool {
        return !rewardCollected
    }
    
    // MARK: - User Login
    func onUserLogin() {
        if SessionManager.shared.isFirstLoginOfTheDay() {
            resetRewardCollectedStatus()
        }
        loadGameData()
        loadRewardCollectedStatus()
    }
    
}
