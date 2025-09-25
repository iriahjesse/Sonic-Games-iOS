//
//  HapticManager.swift
//  SonicGames
//
//  Created by Jesse Iriah on 14/12/2024.
//

import Foundation
import SwiftUI

// Manages haptic feedback throughout the app, providing various tactile responses
// for different user interactions and game events.

class HapticManager {
    static let shared = HapticManager()
    
    // Triggers a success haptic feedback pattern
    func playSuccess() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.success)
    }
    
    // Triggers an error haptic feedback pattern
    // Used for incorrect/ invalid actions
    func playError() {
        let generator = UINotificationFeedbackGenerator()
        generator.notificationOccurred(.error)
    }
    
    // Triggers a selection haptic feedback
    func playSelection() {
        let generator = UISelectionFeedbackGenerator()
        generator.selectionChanged()
    }
    
    // Triggers an impact haptic feedback with customisable intensity
    func playImpact(style: UIImpactFeedbackGenerator.FeedbackStyle) {
        let generator = UIImpactFeedbackGenerator(style: style)
        generator.impactOccurred()
    }
}

