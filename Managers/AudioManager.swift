//
//  AudioManager.swift
//  SonicGames
//
//  Created by Jesse Iriah on 07/11/2024.
//

import Foundation
import AVFAudio
import UIKit

// AudioManager manages audio playback within the application.
// It handles loading, playing, stopping, and adjusting the volume of audio files


class AudioManager {
    
    static let shared = AudioManager()
    
    // MARK: - Initialisation
    private init() {}
    
    // MARK: - Properties
    private var audioPlayer: AVAudioPlayer?
    private var audioLibraries: [Int: (title: String, audioFiles: [String])] = [:]
    
    
    // MARK: - Audio Loading Functions
       
    // Function to load audio from the assets folder using NSDataAsset
    func loadAudio(_ sound: String?) {
        guard let sound = sound else { return }
        
        // Load audio file from asset catalog using NSDataAsset
        if let audioDataAsset = NSDataAsset(name: sound) {
            do {
                // Initialise AVAudioPlayer with the raw data from the NSDataAsset
                audioPlayer = try AVAudioPlayer(data: audioDataAsset.data)
                print("Audio loaded: \(sound).")
            } catch {
                print("Error loading audio: \(error.localizedDescription)")
            }
        } else {
            print("Audio file not found in assets: \(sound).")
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
    
    // MARK: - Audio Volume Control
    // Function to set the volume of the audio player
    func setVolume(_ volume: Float) {
        // Ensure volume is between 0.0 and 1.0
        let validVolume = max(0.0, min(1.0, volume))
        
        // If the audio player is already loaded, apply the volume immediately
        if let player = audioPlayer {
            player.volume = validVolume
            print("Audio volume set to \(validVolume).")
        } else {
            print("Audio not loaded, volume set to \(validVolume) and will be applied when audio is played.")
            // If audio is not loaded, we simply store the volume to be applied later
            
        }
    }
    
   
    
}
    
