//
//  GameDataManager.swift
//  SonicGames
//
//  Created by Jesse Iriah on 11/11/2024.
//

import Foundation
import SwiftUI

// GameDataManager manages and configures game-related data. This includes retrieving, saving, and modifying
//  game layout configurations. The class utilises UserDefaults for persistent
// storage of game parameters such as hint cost, level skip cost, and daily token rewards. It also provides
// layout configurations for different games (e.g., SonicSeek, SonicSequencer, SonicSets) and handles
// loading and managing game attributes like level count, grid configuration, and sequence details for each game mode.

class GameDataManager{
    static let shared = GameDataManager()
    
    // MARK: - Initialisation
    init() {
        // Set default values if not already set
        if UserDefaults.standard.object(forKey: hintCostKey) == nil {
            hintCost = 15
        }
        if UserDefaults.standard.object(forKey: skipLevelCostKey) == nil {
            skipLevelCost = 30
        }
        if UserDefaults.standard.object(forKey: dailyTokenRewardAmountKey) == nil {
            dailyTokenRewardAmount = 25
        }
        loadGameProperties()
        loadSonicSeekLayoutConfigurations()
        loadSonicSequencerLayoutConfigurations()
        loadSonicSyncLayoutConfigurations()
    }
    
    // MARK: - Enums
    
    // Represents the keys for accessing game properties.  Each case corresponds to a specific game.
    enum GameKey: String, CaseIterable, Codable {
        case sonicSeek    // Audio matching game
        case sonicSequencer  // Audio sequence memory game
        case sonicSync    // Audio grid rearrangement game
        // Unimplemented(Inactive) games:
        case sonicStacks  // Audio stacking game
        case sonicSort    // Audio sorting game
        case sonicSurge   // Audio reflex game
        case sonicSearch // Audio search game
        
        // Returns a formatted display name for the game key, e.g., "SONIC SEEK".
        var displayName: String {
            // Use a regular expression to insert a space before each uppercase letter, except for the first letter
            rawValue.replacingOccurrences(of: "([a-z])([A-Z])", with: "$1 $2", options: .regularExpression).uppercased()
        }
    }
    
    // Represents the different game modes available
    enum GameModeKey: String, CaseIterable, Codable {
        case classic, shapes, recolor, resize, rotate, translate, dilate, shuffle, ghost
        var displayName: String {
            rawValue.uppercased() //
        }
    }
    
    // MARK: - Structs
    // Represents the properties of a single game.
    struct GameProperties {
        let title: String          // The title of the game.
        let description: String    // A brief description of the game (85 char max).
        let modes: [GameModeKey]   // The game modes supported by this game.
        let levelCount: Int        // The number of levels in this game.
        let accentColor: Color     // The accent color associated with this game.
        let isActive: Bool         // Indicates whether the game is currently active/implemented.
    }
    
    
    // MARK: - Properties
    
    private var gameProperties: [GameKey: GameProperties] = [:]
    private let DEFAULT_LEVEL_COUNT: Int = 25
    
    // Game congifuration/layout properties
    private(set) var sonicSeekLayoutConfigurations: [Int: (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int)] = [:]
    private(set) var sonicSequencerLayoutConfigurations: [Int: (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int, sequenceLength: Int, sequenceDelay: Double)] = [:]
    private(set) var sonicSyncLayoutConfigurations: [Int: (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int, scrambleSteps: Int)] = [:]
    
    // Keys for UserDefaults data
    private let hintCostKey = "hintCost"
    private let skipLevelCostKey = "skipLevelCost"
    private let dailyTokenRewardAmountKey = "dailyTokenRewardAmount"
    
    
    // MARK: - Computed Properties (UserDefaults-backed properties for game settings)
    
    private(set) var hintCost: Int {
        get { return UserDefaults.standard.integer(forKey: hintCostKey)}
        set { UserDefaults.standard.set(newValue, forKey: hintCostKey)}
    }
    
    private(set) var skipLevelCost: Int {
        get {return UserDefaults.standard.integer(forKey: skipLevelCostKey)}
        set {UserDefaults.standard.set(newValue, forKey: skipLevelCostKey)}
    }
    
    private(set) var dailyTokenRewardAmount: Int {
        get {return UserDefaults.standard.integer(forKey: dailyTokenRewardAmountKey)}
        set {UserDefaults.standard.set(newValue, forKey: dailyTokenRewardAmountKey)}
    }
    
    
    
    // MARK: - Public Methods
    // Public function to retrieve a game property using its key
    func getGameProperties(for gameKey: GameKey) -> GameProperties? {
        return gameProperties[gameKey]
    }
    
    func getLevelConfiguration(for gameKey: GameKey, levelId: Int) -> Any? {
        switch gameKey {
        case .sonicSeek:
            return sonicSeekLayoutConfigurations[levelId]
        case .sonicSequencer:
            return sonicSequencerLayoutConfigurations[levelId]
        case .sonicSync:
            return sonicSyncLayoutConfigurations[levelId]
        default:
            return nil
        }
    }
    
    func getAllLevelConfigurations(for gameKey: GameKey) -> [Int: Any]? {
        switch gameKey {
        case .sonicSeek:
            return sonicSeekLayoutConfigurations
        case .sonicSequencer:
            return sonicSequencerLayoutConfigurations
        case .sonicSync:
            return sonicSyncLayoutConfigurations
        default:
            return nil
        }
    }
    
    // Getter function for Sonic Seek Level Configurations
    func getSonicSeekLayoutConfiguration(for levelId: Int) -> (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int)? {
        return sonicSeekLayoutConfigurations[levelId]
    }
    
    // Getter function for Sonic Sequencer Layout Configurations
    func getSonicSequencerLayoutConfiguration(for levelId: Int) -> (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int, sequenceLength: Int, sequenceDelay: Double)? {
        return sonicSequencerLayoutConfigurations[levelId]
    }
    
    // Getter function for Sonic Sync Layout Configurations
    func getSonicSyncLayoutConfiguration(for levelId: Int) -> (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int, scrambleSteps: Int)? {
        return sonicSyncLayoutConfigurations[levelId]
    }
    
    
    // MARK: - Private Methods
    
    // Initialises and populates the `gameProperties` dictionary with detailed configurations for each game.
    private func loadGameProperties() {
        // Dynamic level count based on the number of levels in each layout configuration
        gameProperties = [
            .sonicSeek: GameProperties(
                title: GameKey.sonicSeek.displayName,
                description: "LISTEN AND IDENTIFY MATCHING SOUNDS TO CLEAR THE SCREEN.",
                modes: [.classic, .shapes, .recolor, .resize, .rotate ,.translate, .dilate, .shuffle, .ghost],
                levelCount: DEFAULT_LEVEL_COUNT,
                accentColor: ColorManager.shared.getCustomColor(name: .peach) ?? Color.clear,
                isActive: true),
            .sonicSequencer: GameProperties(
                title: GameKey.sonicSequencer.displayName,
                description: "MIRROR THE CORRECT SEQUENCE OF SOUNDS.",
                modes: [.classic, .shapes, .recolor, .rotate],
                levelCount: DEFAULT_LEVEL_COUNT,
                accentColor: ColorManager.shared.getCustomColor(name: .lavender) ?? Color.clear,
                isActive: true),
            .sonicSync: GameProperties(
                title: GameKey.sonicSync.displayName,
                description: "SWAP CELLS TO MATCH THE BOTTOM GRID WITH THE TOP.",
                modes: [.classic, .shapes, .recolor],
                levelCount: DEFAULT_LEVEL_COUNT,
                accentColor: ColorManager.shared.getCustomColor(name: .lightBlue) ?? Color.clear,
                isActive: true),
            
            // Unimplemented/ Inactive games:
            .sonicStacks: GameProperties(
                title: GameKey.sonicStacks.displayName,
                description: " ",
                modes: [.classic],
                levelCount: DEFAULT_LEVEL_COUNT,
                accentColor: ColorManager.shared.getCustomColor(name: .amber) ?? Color.clear,
                isActive: false),
            .sonicSort: GameProperties(
                title: GameKey.sonicSort.displayName,
                description: " ",
                modes: [.classic],
                levelCount: DEFAULT_LEVEL_COUNT,
                accentColor: ColorManager.shared.getCustomColor(name: .green) ?? Color.clear, isActive: false),
            .sonicSurge: GameProperties(
                title: GameKey.sonicSurge.displayName,
                description: " ",
                modes: [.classic],
                levelCount: DEFAULT_LEVEL_COUNT,
                accentColor: ColorManager.shared.getCustomColor(name: .coral) ?? Color.clear, isActive: false),
            .sonicSearch: GameProperties(
                title: GameKey.sonicSearch.displayName,
                description: " ",
                modes: [.classic],
                levelCount: DEFAULT_LEVEL_COUNT,
                accentColor: ColorManager.shared.getCustomColor(name: .darkBlue) ?? Color.clear, isActive: false)
        ]
    }
    
    /*
     `loadSonicSeekLayoutConfigurations` is a private function that initialises the `sonicSeekLayoutConfigurations` dictionary.
     This dictionary contains layout configurations for 25 different levels.
     Each level is defined by:
     - `rows`: The number of rows in the grid.
     - `columns`: The number of columns in the grid.
     - `cellWidth`: The width of each individual cell in the grid.
     - `cellHeight`: The height of each individual cell in the grid.
     - `cellSpacing`: The spacing between each cell in the grid.
     
     The function populates this dictionary with the layout details for all 25 levels, ensuring that each level has its own unique configuration.
     */
    private func loadSonicSeekLayoutConfigurations() {
        sonicSeekLayoutConfigurations = [
            1: (rows: 2, columns: 2, cellWidth: 98, cellHeight: 108, cellSpacing: 22),  // Level 1
            2: (rows: 2, columns: 3, cellWidth: 84, cellHeight: 94, cellSpacing: 16),   // Level 2
            3: (rows: 2, columns: 4, cellWidth: 70, cellHeight: 80, cellSpacing: 9),    // Level 3
            4: (rows: 3, columns: 2, cellWidth: 84, cellHeight: 94, cellSpacing: 14),   // Level 4
            5: (rows: 3, columns: 4, cellWidth: 68, cellHeight: 78, cellSpacing: 9),   // Level 5
            6: (rows: 3, columns: 2, cellWidth: 91, cellHeight: 101, cellSpacing: 14),   // Level 6
            7: (rows: 3, columns: 4, cellWidth: 68, cellHeight: 78, cellSpacing: 9),   // Level 7
            8: (rows: 3, columns: 6, cellWidth: 48, cellHeight: 58, cellSpacing: 8),    // Level 8
            9: (rows: 4, columns: 2, cellWidth: 70, cellHeight: 80, cellSpacing: 9),   // Level 9
            10: (rows: 4, columns: 3, cellWidth: 70, cellHeight: 80, cellSpacing: 9),  // Level 10
            11: (rows: 4, columns: 4, cellWidth: 65, cellHeight: 75, cellSpacing: 9),  // Level 11
            12: (rows: 4, columns: 6, cellWidth: 48, cellHeight: 58, cellSpacing: 8),  // Level 12
            13: (rows: 5, columns: 2, cellWidth: 50, cellHeight: 60, cellSpacing: 9),  // Level 13
            14: (rows: 5, columns: 4, cellWidth: 55, cellHeight: 65, cellSpacing: 12),  // Level 14
            15: (rows: 5, columns: 6, cellWidth: 48, cellHeight: 58, cellSpacing: 8),  // Level 15
            16: (rows: 6, columns: 4, cellWidth: 48, cellHeight: 58, cellSpacing: 8),   // Level 16
            17: (rows: 6, columns: 5, cellWidth: 48, cellHeight: 58, cellSpacing: 8),  // Level 17
            18: (rows: 6, columns: 6, cellWidth: 44, cellHeight: 54, cellSpacing: 8),   // Level 18
            19: (rows: 7, columns: 4, cellWidth: 46, cellHeight: 56, cellSpacing: 8),   // Level 19
            20: (rows: 7, columns: 6, cellWidth: 46, cellHeight: 56, cellSpacing: 8),   // Level 20
            21: (rows: 8, columns: 4, cellWidth: 40, cellHeight: 50, cellSpacing: 8),   // Level 21
            22: (rows: 8, columns: 6, cellWidth: 40, cellHeight: 50, cellSpacing: 8),   // Level 22
            23: (rows: 8, columns: 6, cellWidth: 40, cellHeight: 50, cellSpacing: 8),   // Level 23
            24: (rows: 9, columns: 4, cellWidth: 38, cellHeight: 48, cellSpacing: 8),   // Level 24
            25: (rows: 9, columns: 6, cellWidth: 38, cellHeight: 48, cellSpacing: 8)    // Level 25
        ]
    }
    
    /*
     `loadSonicSequencerLayoutConfigurations` is a private function that initialises the `sonicSequencerLayoutConfigurations` dictionary.
     This dictionary contains layout configurations for 25 different levels.
     Each level is defined by:
     - `rows`: The number of rows in the grid.
     - `columns`: The number of columns in the grid.
     - `cellWidth`: The width of each individual cell in the grid.
     - `cellHeight`: The height of each individual cell in the grid.
     - `cellSpacing`: The spacing between each cell in the grid.
     - 'sequenceLenth': // The number of steps in the sequence to memorise
     - 'sequenceDelay': Time (in seconds) to show each step in the sequence.
     The function populates this dictionary with the layout details for all 25 levels, ensuring that each level has its own unique configuration.
     */
    private func loadSonicSequencerLayoutConfigurations() {
        sonicSequencerLayoutConfigurations = [
            1: (rows: 2, columns: 1, cellWidth: 90, cellHeight: 90, cellSpacing: 26, sequenceLength: 1, sequenceDelay: 2.0),
            2: (rows: 2, columns: 2, cellWidth: 84, cellHeight: 84, cellSpacing: 20, sequenceLength: 2, sequenceDelay: 1.9),
            3: (rows: 3, columns: 3, cellWidth: 78, cellHeight: 78, cellSpacing: 14, sequenceLength: 3, sequenceDelay: 1.8),
            4: (rows: 2, columns: 2, cellWidth: 80, cellHeight: 80, cellSpacing: 16, sequenceLength: 4, sequenceDelay: 1.7),
            5: (rows: 2, columns: 3, cellWidth: 68, cellHeight: 68, cellSpacing: 14, sequenceLength: 5, sequenceDelay: 1.6),
            6: (rows: 2, columns: 4, cellWidth: 58, cellHeight: 58, cellSpacing: 10, sequenceLength: 6, sequenceDelay: 1.5),
            7: (rows: 2, columns: 5, cellWidth: 54, cellHeight: 54, cellSpacing: 9, sequenceLength: 7, sequenceDelay: 1.4),
            8: (rows: 2, columns: 6, cellWidth: 46, cellHeight: 46, cellSpacing: 9, sequenceLength: 8, sequenceDelay: 1.3),
            9: (rows: 3, columns: 4, cellWidth: 58, cellHeight: 58, cellSpacing: 10, sequenceLength: 9, sequenceDelay: 1.25),
            10: (rows: 3, columns: 5, cellWidth: 54, cellHeight: 54, cellSpacing: 9, sequenceLength: 10, sequenceDelay: 1.2),
            11: (rows: 3, columns: 6, cellWidth: 50, cellHeight: 50, cellSpacing: 9, sequenceLength: 11, sequenceDelay: 1.15),
            12: (rows: 4, columns: 3, cellWidth: 58, cellHeight: 58, cellSpacing: 10, sequenceLength: 12, sequenceDelay: 1.1),
            13: (rows: 4, columns: 4, cellWidth: 58, cellHeight: 58, cellSpacing: 10, sequenceLength: 13, sequenceDelay: 1.05),
            14: (rows: 4, columns: 5, cellWidth: 52, cellHeight: 52, cellSpacing: 9, sequenceLength: 14, sequenceDelay: 1.0),
            15: (rows: 4, columns: 6, cellWidth: 50, cellHeight: 50, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.95),
            16: (rows: 5, columns: 4, cellWidth: 54, cellHeight: 54, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.93),
            17: (rows: 5, columns: 5, cellWidth: 52, cellHeight: 52, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.9),
            18: (rows: 5, columns: 6, cellWidth: 50, cellHeight: 50, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.88),
            19: (rows: 6, columns: 4, cellWidth: 50, cellHeight: 50, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.85),
            20: (rows: 6, columns: 5, cellWidth: 50, cellHeight: 50, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.83),
            21: (rows: 7, columns: 5, cellWidth: 46, cellHeight: 46, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.8),
            22: (rows: 7, columns: 6, cellWidth: 46, cellHeight: 46, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.78),
            23: (rows: 8, columns: 5, cellWidth: 42, cellHeight: 42, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.75),
            24: (rows: 8, columns: 6, cellWidth: 42, cellHeight: 42, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.73),
            25: (rows: 9, columns: 6, cellWidth: 42, cellHeight: 42, cellSpacing: 9, sequenceLength: 15, sequenceDelay: 0.7)
            
        ]
    }
    
    /*
     `loadSonicSyncLayoutConfigurations` is a private function that initialises the `sonicSyncLayoutConfigurations` dictionary.
     This dictionary contains layout configurations for 25 different levels.
     Each level consists of a grid with a specific number of rows and columns.
     Additionally, dividers can be placed between rows and/or columns to section off parts of the grid.
     The configuration for each level includes the following:
     - `rows`: The number of rows in the grid.
     - `columns`: The number of columns in the grid.
     - `cellWidth`: The width of each cell in the grid.
     - `cellHeight`: The height of each cell in the grid.
     - `cellSpacing`: The spacing between each cell in the grid.
     - `scrambleSteps`: The number of adjacent cell swaps used to scramble the grid at each level.
     */
    private func loadSonicSyncLayoutConfigurations() {
        sonicSyncLayoutConfigurations = [
            1: (rows: 1, columns: 3, cellWidth: 60, cellHeight: 66, cellSpacing: 35, scrambleSteps: 3),
            2: (rows: 3, columns: 1, cellWidth: 45, cellHeight: 50, cellSpacing: 25, scrambleSteps: 4),
            3: (rows: 2, columns: 2, cellWidth: 74, cellHeight: 74, cellSpacing: 16, scrambleSteps: 5),
            4: (rows: 1, columns: 4, cellWidth: 60, cellHeight: 60, cellSpacing: 16, scrambleSteps: 6),
            5: (rows: 5, columns: 1, cellWidth: 46, cellHeight: 46, cellSpacing: 12, scrambleSteps: 7),
            6: (rows: 2, columns: 3, cellWidth: 74, cellHeight: 74, cellSpacing: 18, scrambleSteps: 8),
            7: (rows: 1, columns: 5, cellWidth: 46, cellHeight: 46, cellSpacing: 12, scrambleSteps: 8),
            8: (rows: 3, columns: 3, cellWidth: 64, cellHeight: 64, cellSpacing: 14, scrambleSteps: 9),
            9: (rows: 2, columns: 4, cellWidth: 60, cellHeight: 60, cellSpacing: 16, scrambleSteps: 9),
            10: (rows: 3, columns: 4, cellWidth: 60, cellHeight: 60, cellSpacing: 15, scrambleSteps: 10),
            11: (rows: 3, columns: 5, cellWidth: 46, cellHeight: 46, cellSpacing: 12, scrambleSteps: 11),
            12: (rows: 6, columns: 1, cellWidth: 38, cellHeight: 38, cellSpacing: 10, scrambleSteps: 12),
            13: (rows: 4, columns: 4, cellWidth: 56, cellHeight: 56, cellSpacing: 13, scrambleSteps: 13),
            14: (rows: 4, columns: 5, cellWidth: 46, cellHeight: 46, cellSpacing: 13, scrambleSteps: 14),
            15: (rows: 1, columns: 6, cellWidth: 40, cellHeight: 40, cellSpacing: 12, scrambleSteps: 14),
            16: (rows: 4, columns: 6, cellWidth: 42, cellHeight: 42, cellSpacing: 10, scrambleSteps: 15),
            17: (rows: 5, columns: 5, cellWidth: 44, cellHeight: 44, cellSpacing: 10, scrambleSteps: 15),
            18: (rows: 5, columns: 6, cellWidth: 38, cellHeight: 38, cellSpacing: 9, scrambleSteps: 16),
            19: (rows: 1, columns: 7, cellWidth: 36, cellHeight: 36, cellSpacing: 11, scrambleSteps: 16),
            20: (rows: 6, columns: 6, cellWidth: 38, cellHeight: 38, cellSpacing: 10, scrambleSteps: 17),
            21: (rows: 7, columns: 5, cellWidth: 36, cellHeight: 36, cellSpacing: 8, scrambleSteps: 17),
            22: (rows: 6, columns: 7, cellWidth: 36, cellHeight: 36, cellSpacing: 8, scrambleSteps: 18),
            23: (rows: 7, columns: 6, cellWidth: 36, cellHeight: 36, cellSpacing: 8, scrambleSteps: 18),
            24: (rows: 8, columns: 6, cellWidth: 32, cellHeight: 32, cellSpacing: 8, scrambleSteps: 19),
            25: (rows: 7, columns: 9, cellWidth: 32, cellHeight: 32, cellSpacing: 8, scrambleSteps: 20)
        ]
    }
    
}
