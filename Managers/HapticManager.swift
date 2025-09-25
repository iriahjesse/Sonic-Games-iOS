//
//  HapticManager.swift
//  SonicGames
//
//  Created by Jesse Iriah on 14/12/2024.
//

import Foundation
import UIKit // Use UIKit for UIFeedbackGenerator

// Manages haptic feedback throughout the app, using persistent generators
// for improved performance and responsiveness.

class HapticManager {
    static let shared = HapticManager()
    
    // MARK: - Persistent Generators
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()
    
    // Impact generators for common styles
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    
    // MARK: - Initialisation
    private init() {
        // Prepares all generators right away for low-latency feedback.
        notificationGenerator.prepare()
        selectionGenerator.prepare()
        mediumImpactGenerator.prepare()
        lightImpactGenerator.prepare()
    }
    
    // MARK: - Feedback Functions
    
    // Triggers a success haptic feedback pattern
    func playSuccess() {
        notificationGenerator.notificationOccurred(.success)
        notificationGenerator.prepare() // Prepare again for next use
    }
    
    // Triggers an error haptic feedback pattern
    func playError() {
        notificationGenerator.notificationOccurred(.error)
        notificationGenerator.prepare() // Prepare again for next use
    }
    
    // Triggers a selection haptic feedback
    func playSelection() {
        selectionGenerator.selectionChanged()
        selectionGenerator.prepare() // Prepare again for next use
    }
    
    // Triggers a medium impact haptic feedback (most common impact style)
    func playMediumImpact() {
        mediumImpactGenerator.impactOccurred()
        mediumImpactGenerator.prepare() // Prepare again for next use
    }
    
    // Triggers a light impact haptic feedback
    func playLightImpact() {
        lightImpactGenerator.impactOccurred()
        lightImpactGenerator.prepare() // Prepare again for next use
    }
    
}
