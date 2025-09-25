
// // MainView.swift // SonicGames //
// // Created by Jesse Iriah on 06/11/2024. //

import SwiftUI
import AVFAudio


// Enum to define various views/screens in the app, each corresponding to a distinct screen or game mode.
enum ViewState: Equatable {
    
    case launch, load, home, mode, level,
         game(GameDataManager.GameKey)
    
    var gameKey: GameDataManager.GameKey? { // Computed property to extract GameKey
        if case let .game(key) = self {
            return key
        }
        return nil
    }
}

// Main view struct/entry point and container for all views within the app.
struct MainView: View {
    // MARK: - Properties
    // State variables to manage the current and previous view
    @State private var currentView: ViewState = .launch
    @State private var previousView: ViewState = .launch
    
    // State variables for game selection and configuration
    @State private var selectedGameKey: GameDataManager.GameKey!
    @State private var selectedModeKey: GameDataManager.GameModeKey!
    @State private var selectedThemeKey: AudioThemeManager.AudioThemeKey!
    @State private var selectedLevelIndex: Int = 1
    
    // State variables for game rewards and alerts
    @State private var isBonusEligible: Bool = false
    @State private var showRewardsView: Bool = false
    @State private var rewardDismissTimer: Timer?
    @State private var showMoreTokensAlert: Bool = false
    @State private var showWinsAlert: Bool = false
    
    // State object to manage user progress
    @StateObject private var userProgress = UserProgressManager.shared
    
    
    
    
    // MARK: - Initialisation
    init(){
        SessionManager.shared.userLogin()
    }
    
    
    // MARK: - Body
    var body: some View {
        
        ZStack {
            switch currentView {
            case .launch:
                
                LaunchView()
                    .onAppear {
                        print("App launching!")
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            withAnimation {
                                previousView = currentView
                                currentView = .load
                            }
                        }
                    }
            case .load:
                
                LoadView()
                    .onAppear {
                        print("App loading")
                        // Transition to the home view after a 2-second delay
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                previousView = currentView
                                currentView = .home
                            }
                        }
                    }
                
                
            case .home:
                
                HomeView(
                    currentView:$currentView,
                    previousView:$previousView,
                    selectedGameKey: $selectedGameKey,
                    showMoreTokensAlert: $showMoreTokensAlert,
                    showWinsAlert: $showWinsAlert)
                .onAppear(){
                    if SessionManager.shared.isFirstLoginOfTheDay() && UserProgressManager.shared.canCollectDailyReward() {
                        showRewardsView = true
                        UserProgressManager.shared.markRewardAsCollected()
                    }
                }
            case .mode:
                ModeView(currentView: $currentView, previousView: $previousView, selectedModeKey: $selectedModeKey, showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert, selectedGameKey: selectedGameKey)
            case .level:
                LevelView(currentView: $currentView, previousView: $previousView, selectedLevelIndex: $selectedLevelIndex, showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert, selectedGameKey: selectedGameKey, selectedModeKey: selectedModeKey)
            case .game(let gameKey):
                getGameView(for: gameKey)
                
                
                
                
            }
            // Conditionally show RewardsView
            if showRewardsView {
                TokenRewardView()
                    .onAppear{
                        // Start a timer to dismiss the RewardsView after 2.5 seconds
                        rewardDismissTimer = Timer.scheduledTimer(withTimeInterval: 2.5, repeats: false) { _ in
                            withAnimation {
                                showRewardsView = false
                            }
                        }
                    }
                    .onDisappear {
                        rewardDismissTimer?.invalidate()
                    }
            }
            
            // Show AlertView if the reset green 'plus' button next to tokens is selected
            if showMoreTokensAlert {
                AlertView(
                    isPresented: $showMoreTokensAlert, title: "Daily Tokens Await!",
                    message: "Check back tomorrow to collect your next reward. Don’t miss out on your daily bonus!",
                    backgroundColor: Color(red: 0/255, green: 80/255, blue: 0/255).opacity(0.6)
                )
                .transition(.opacity)
                .zIndex(1) // Ensure it's on top
                .onAppear {
                    // Automatically dismiss after 4.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        withAnimation {
                            showMoreTokensAlert = false
                        }
                    }
                }
            }
            
            // Show AlertView if wins are selected
            if showWinsAlert {
                AlertView(
                    isPresented: $showWinsAlert, title: "Your Winning Streak",
                    message: "Every game you win is recorded here. Your next win is just a game away—keep going!",
                    backgroundColor: Color(red: 90/255, green: 90/255, blue: 0/255).opacity(0.7)
                )
                .transition(.opacity)
                .zIndex(1) // Ensure it's on top
                .onAppear {
                    // Automatically dismiss after 4.5 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 4.5) {
                        withAnimation {
                            showWinsAlert = false
                        }
                    }
                }
            }
            
        }
    }
    
    
    // MARK: - View Helper Methods
    @ViewBuilder
    // Helper function: returns an implemented game view
    private func getGameView(for gameKey: GameDataManager.GameKey) -> some View {
        switch gameKey {
        case .sonicSeek:
            SonicSeekView(currentView:$currentView,
                           previousView:$previousView, showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert,
                           selectedLevelIndex: $selectedLevelIndex,  selectedModeKey: selectedModeKey)
            
        case .sonicSequencer:
            SonicSequencerView(currentView:$currentView,
                               previousView:$previousView,showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert, selectedLevelIndex: $selectedLevelIndex,  selectedModeKey: selectedModeKey)
        case .sonicSync:
            SonicSyncView(currentView:$currentView,
                          previousView:$previousView,showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert, selectedLevelIndex: $selectedLevelIndex,  selectedModeKey: selectedModeKey)
        default: EmptyView()
        }
    }
}

// Preview provider for the Main View
struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
