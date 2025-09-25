//
//  AudioManager.swift
//  SonicGames
//
//  Created by Jesse Iriah on 07/11/2024.
//

import Foundation
import AVFAudio

// AudioManager manages audio playback within the application.
// It handles loading, playing, stopping, and adjusting the volume of audio files


class AudioManager {
    
    static let shared = AudioManager()
    
    // MARK: - Initialisation
    private init() {}
    
    // MARK: - Properties
    private var audioPlayer: AVAudioPlayer?
    private var pendingVolume: Float = 1.0
    
    
    // MARK: - Audio Loading Functions
    
    func loadAudio(_ sound: String?) {
        guard let sound = sound else { return }
        
        // Stop any current audio before loading new audio (enforce single playback)
        stopAudio() 
        
        if let audioDataAsset = NSDataAsset(name: sound) {
            do {
                audioPlayer = try AVAudioPlayer(data: audioDataAsset.data)
                
                // 2. APPLY THE STORED VOLUME IMMEDIATELY after creation
                audioPlayer?.volume = pendingVolume
                
                // print("Audio loaded: \(sound).") 
            } catch {
                // print("Error loading audio: \(error.localizedDescription)") 
            }
        } else {
            // print("Audio file not found in assets: \(sound).") 
        }
    }
    
    // MARK: - Audio Volume Control
    
    func setVolume(_ volume: Float) {
        let validVolume = max(0.0, min(1.0, volume))
        
        // 3. ALWAYS STORE THE VOLUME
        pendingVolume = validVolume
        
        // If the audio player is loaded, apply the volume immediately
        if let player = audioPlayer {
            player.volume = validVolume
            // print("Audio volume set to \(validVolume).")
        } else {
            // print("Audio not loaded, volume set to \(validVolume) and will be applied when audio is played.") 
        }
    }
    
    
    // MARK: - Audio Playback Functions
    // Function to play the loaded audio
    func playAudio() {
        if let player = audioPlayer {
            player.play()
            print("Audio is playing.")
        } else {
            print("Audio not loaded.")
        }
    }
    
    // Function to stop the audio
    func stopAudio() {
        if let player = audioPlayer, player.isPlaying {
            player.stop()
            print("Audio stopped.")
        } else {
            print("Audio is not currently playing.")
        }
    }
    
    
}
    
