//
//  HomeView.swift
//  SonicGames
//
//  Created by Jesse Iriah on 28/10/2024.
//


import SwiftUI

// Home Screen View
struct HomeView: View {
    
    // MARK: - Properties
    @Binding var currentView: ViewState
    @Binding var previousView: ViewState
    @Binding var selectedGameKey: GameDataManager.GameKey!
    @Binding var showMoreTokensAlert: Bool
    @Binding var showWinsAlert: Bool
    
    @ObservedObject private var progressManager = UserProgressManager.shared
    private let gameManager = GameDataManager.shared
    @State private var expandedGameKey: GameDataManager.GameKey?
    

    private let availableGameKeys = GameDataManager.GameKey.allCases
    
    var body: some View {
        ZStack {
            Image("UIBackground") // Background Image
                .resizable()
                .aspectRatio(contentMode: .fill)
                .scaleEffect(1.8)
                .edgesIgnoringSafeArea(.all)
                .opacity(0.5)
            
            
            Rectangle() // Foreground Overlay
                .foregroundStyle(Color(.white).opacity(0.8))
                .frame(height: 550)
                .blur(radius: 30)
            
            VStack{
                
                // Upper panel for displaying wins and tokens
                UpperPanelView(showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert)
                
                
                Spacer()
                // Game selection title
                Text("SELECT GAME:")
                    .font(.custom("AcierBATText-Solid", size: 17)).foregroundStyle(.black)
                    .padding(.bottom, 24)
                    .padding(.top, 20)
                
                
                // Scrollable list of games
                ScrollView {
                    VStack(spacing: 20) {
                        // Using the explicit array for safety
                        ForEach(availableGameKeys, id: \.self) { gameKey in 
                            GameAccordion(
                                gameKey: gameKey,
                                isExpanded: .constant(expandedGameKey == gameKey), // Bind expansion state
                                currentView: $currentView,
                                previousView: $previousView,
                                selectedGameKey: $selectedGameKey
                            )
                            .onTapGesture {
                                withAnimation {
                                   
                                    if gameManager.getGameProperties(for: gameKey)?.isActive ?? false { 
                                        expandedGameKey = (expandedGameKey == gameKey) ? nil : gameKey // Toggle expansion
                                    }
                                }
                            }
                        }
                    }
                } // End of Scroll View
                .frame(height: 520)
                .scrollIndicators(.hidden) // Hides scroll indicators
                .background(Color.clear)
                
                Spacer()
                
                // Lower panel for navigation buttons
                LowerPanelView(currentView: $currentView, previousView: $previousView)
                
            }
            
            
            
            
        }
        
        
        
        
    } // End of body
    
}
// Game Accordion setup for active games 
struct GameAccordion: View {
    let gameKey: GameDataManager.GameKey
    @Binding var isExpanded: Bool
    @Binding var currentView: ViewState
    @Binding var previousView: ViewState
    @Binding var selectedGameKey: GameDataManager.GameKey!
    
    private let gameManager = GameDataManager.shared
    
    var body: some View {
      
        RoundedRectangle(cornerRadius: 20)
            .fill(Color(gameManager.getGameProperties(for: gameKey)?.accentColor.opacity(gameManager.getGameProperties(for: gameKey)?.isActive ?? true ? 1 : 0.75) ?? .white))
            .frame(maxWidth: 300)
            .frame(height: isExpanded ? 180 : 90) // Height based on expansion
            .overlay(
                RoundedRectangle(cornerRadius: 20) // RoundedRectangle for black stroke
                    .fill(Color(.clear))
                    .stroke(Color.black.opacity(gameManager.getGameProperties(for: gameKey)?.isActive ?? true ? 0.7 : 0.4), lineWidth: 8.4)
                    .padding(0))
            .overlay(
                VStack {
                    Text(gameKey.displayName)
                        .font(.custom("AcierBATText-Solid", size: 24))
                        .foregroundStyle(.white)
                        .shadow(color: (gameManager.getGameProperties(for: gameKey)?.accentColor ?? .clear).opacity(0.15), radius: 2, x: 2, y: -1)
                        .padding(.top, isExpanded && (gameManager.getGameProperties(for: gameKey)?.isActive ?? false) ? 27 : 4.2) // Conditional padding
                    
                    
                    if isExpanded && (gameManager.getGameProperties(for: gameKey)?.isActive ?? false) { // Show description and play button when expanded and active
                        Divider()
                            .frame(width:220, height:2.5)
                            .background(Color.black.opacity(0.8))
                            
                            .offset(y:-8)
                        ZStack{
                            Rectangle() // Foreground Overlay
                                .foregroundStyle(Color(.green).opacity(0.09))
                                
                                .blur(radius: 20)
                            HStack {
                                
                                Text(gameManager.getGameProperties(for: gameKey)!.description)
                                    .font(.system(size: 15))
                                    
                                    .fontWeight(.bold)
                                    .foregroundStyle(Color(.white))
                                    .padding(.trailing, 8)
                                    .shadow(color: .white, radius: 0.1)
                                    
                                    Button(action: {
                                        selectedGameKey = gameKey
                                        withAnimation {
                                            previousView = currentView
                                            currentView = .mode
                                        }
                                    }) {
                                        ZStack{
                                            Circle()
                                                
                                                .fill(.white)
                                                .frame(width: 25, height: 25)
                                            Image("customPlayIcon")
                                                .scaleEffect(1.2)
                                                .fontWeight(.heavy)
                                                .shadow(color: Color.white.opacity(0.6), radius: 0.3, x: 0, y: 0
                                                )
                                                .shadow(color: Color.white.opacity(0.8), radius: 0.3, x: 0, y: 0
                                                )
                                        }
                                        
                                    }
                                }
                                .offset(y:-4)
                                .padding(.bottom)
                                .padding(.horizontal, 26)
                                
                        }
                    } else if !gameManager.getGameProperties(for: gameKey)!.isActive {
                        Text("COMING SOON")
                            .font(.caption)
                            .scaleEffect(1.1)
                            .fontWeight(.bold)
                            .foregroundColor(.black.opacity(0.2))
                            .shadow(color: .orange.opacity(0.5), radius: 0.2, x: 1, y: -2)
                    }
                }
            )
        
            .cornerRadius(20)
            .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 3)
            .disabled(!(gameManager.getGameProperties(for: gameKey)?.isActive ?? true))
    }
}

// Preview provider for HomeView
struct HomeView_Previews: PreviewProvider {
    // Sample variables
    @State static var currentView: ViewState = .home
    @State static var previousView: ViewState = .launch
    @State static var selectedGameKey: GameDataManager.GameKey! = .sonicSort
    
    @State static var showMoreTokensAlert: Bool = false 
    @State static var showWinsAlert: Bool = false
    
    
    static var previews: some View {
        HomeView(
            currentView: $currentView,
            previousView: $previousView,
            selectedGameKey: $selectedGameKey,
            showMoreTokensAlert: $showMoreTokensAlert, 
            showWinsAlert: $showWinsAlert)
    }
}
