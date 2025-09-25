import SwiftUI

// Lower-Panel View for navigation options
struct LowerPanelView: View {
    @Binding var currentView: ViewState
    @Binding var previousView: ViewState
    
    var resetAction: (() -> Void)? = nil  // Closure to reset the game
    var hintAction: (() -> Void)? = nil // Closure to process a hint
    var skipAction: (() -> Void)? = nil // Closure to process skipping a level
    
    @State private var hintButtonPressed: Bool = false
    @State private var helpButtonPressed: Bool = false
    @State private var resetButtonPressed: Bool = false
    @State private var pauseButtonPressed: Bool = false
    @State private var settingsButtonPressed: Bool = false
    @State private var skipButtonPressed: Bool = false
    
    @State private var showThemeView = false
    @State private var showSettingsView = false
    @State private var showHelpView = false
    
    private var isAGameView: Bool { currentView.gameKey != nil }
    private var isHomeView: Bool {currentView == .home}
    
    var body: some View {
        HStack {
            Spacer()
            
            // If the current view is the Home View
            if (isHomeView) {
                HStack{
                    
                    
                    // Settings Button
                    Button(action: {
                        withAnimation {
                            showSettingsView = true
                        }
                    }) {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 37.8))
                            .fontWeight(.light)
                            .padding(8)
                            .foregroundStyle(Color(red: 232/255, green: 69/255, blue: 64/255).opacity(1.0))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.4) // Softer shadow
                            .blur(radius: 0.4)
                            .offset(x: 0, y: 3)
                    }
                }
                
                // Audio Theme Button
                Button(action: {
                    withAnimation {
                        showThemeView = true 
                    }
                }) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .padding(8)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 20/255).opacity(1.0))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1) // Softer shadow
                        .blur(radius: 0.3)
                        .offset(x:0, y: 3)
                }
                .padding(.leading, 180)
            }
            
            
            
            // If not currently in a game and not in Home View
            if (!isAGameView && !isHomeView) {
                HStack{
                    // Back button
                    Button(action: {
                        withAnimation {
                            if currentView == .mode{
                                
                                currentView = .home
                            }
                            if currentView == .level{
                                
                                currentView = .mode
                            }
                        }
                    }) {
                        Image(systemName: "arrowshape.backward.fill")
                            .font(.system(size: 28))
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 238/255, green: 69/255, blue: 64/255).opacity(1.0))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.6), radius: 0.6, x: 0, y: -1
                            )
                            .shadow(color: Color.black.opacity(0.6), radius: 0.6, x: 0, y: 1
                            )
                            .blur(radius: 0.4)
                            .offset(x: -7, y: 3)
                            
                        
                    }
                    
                    
                    // Home Button
                    Button(action: {
                        withAnimation {
                            previousView = currentView
                            currentView = .home // Navigate to home
                        }
                    }) {
                        Image(systemName: "house.fill")
                            .font(.system(size: 30))
                            .padding(2)
                            .fontWeight(.semibold)
                            .foregroundStyle(Color(red: 231/255, green: 69/255, blue: 64/255).opacity(1.0))
                            .background(currentView == .home ? Color.red.opacity(0.2): Color.clear) // Change background when on home
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1) // Softer shadow
                            .blur(radius: 0.3)
                            .offset(x:0, y: 3)
                    }
                    
                    // Settings Button
                    Button(action: {
                        withAnimation {
                            showSettingsView = true
                        }
                    }) {
                        Image(systemName: "gearshape.2.fill")
                            .font(.system(size: 36))
                            .fontWeight(.light)
                            .padding(2)
                            .foregroundStyle(Color(red: 232/255, green: 69/255, blue: 64/255).opacity(1.0))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.15), radius: 0.5, x: 0, y: 0.4) // Softer shadow
                            .blur(radius: 0.4)
                            .offset(x: 0, y: 3)
                    }
                }
                
                
                // Audio Theme Button
                Button(action: {
                    withAnimation {
                        showThemeView = true
                    }
                }) {
                    Image(systemName: "music.note")
                        .font(.system(size: 40))
                        .padding(8)
                        .fontWeight(.bold)
                        .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 20/255).opacity(1.0))
                        .clipShape(Circle())
                        .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1) // Softer shadow
                        .blur(radius: 0.3)
                        .offset(x:0, y: 3)
                }
                .padding(.leading, 80)
            }
            
            
            
            // If currently in a game
            if (isAGameView) {
                HStack{
                    // Return to levels button
                    Button(action: {
                        withAnimation {
                            previousView = currentView
                            currentView = .level
                        }
                    }) {
                        
                        Image(systemName: "arrowshape.backward.fill")
                            .font(.system(size: 31))
                            .fontWeight(.bold)
                            .foregroundStyle(Color(red: 238/255, green: 69/255, blue: 64/255).opacity(1.0))
                            .clipShape(Circle())
                            .shadow(color: Color.black.opacity(0.6), radius: 0.6, x: 0, y: -1
                            )
                            .shadow(color: Color.black.opacity(0.6), radius: 0.6, x: 0, y: 1
                            )
                            .blur(radius: 0.4)
                            .offset(x: -7, y: 3)
                            .padding(8)
                        
                    }
                    .padding(.trailing, 70)
                    
                    
                    // Repeat Level Button
                    Button(action: {
                        withAnimation {
                            resetAction?()
                        }
                    }) {
                        ZStack{
                            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                                .font(.system(size: 23))
                                .rotationEffect(.degrees(0))
                                .fontWeight(.bold)
                                .padding(5)
                                .foregroundStyle(Color(red: 231/255, green: 69/255, blue: 64/255).opacity(1.0))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                                .blur(radius: 0.4)
                                .offset(x: 0, y: 3)
                            
                            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                                .font(.system(size: 25))
                                .rotationEffect(.degrees(0))
                                .fontWeight(.bold)
                                .padding(5)
                                .foregroundStyle(Color(red: 231/255, green: 69/255, blue: 64/255).opacity(1.0))
                                .clipShape(Circle())
                                .shadow(color: Color.black.opacity(0.15), radius: 1, x: 0, y: 1)
                                .blur(radius: 0.4)
                                .offset(x: 0, y: 3)
                        }
                    }
                    
                    ZStack{
                        // Hint Button
                        Button(action: {
                            withAnimation {
                                hintAction?()
                            }
                            
                        }) {
                            ZStack{
                                Image(systemName: "lightbulb.max")
                                    .font(.system(size: 23.4))
                                    .fontWeight(.heavy)
                                    .symbolRenderingMode(.monochrome)
                                    .padding(.vertical, 5)
                                    .foregroundStyle(Color(red: 231/255, green: 69/255, blue: 64/255).opacity(1.0))
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                    .blur(radius: 0.4)
                                    .offset(x: 0, y: 3)
                                Image(systemName: "lightbulb.max")
                                    .font(.system(size: 25.4))
                                    .fontWeight(.heavy)
                                    .symbolRenderingMode(.monochrome)
                                    .padding(.vertical, 5)
                                    .foregroundStyle(Color(red: 231/255, green: 69/255, blue: 64/255).opacity(1.0))
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                    .blur(radius: 0.4)
                                .offset(x: 0, y: 3)}
                        }
                        HStack{
                            Text(String(GameDataManager.shared.hintCost))
                                .font(.footnote)
                                .scaleEffect(1.1)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 23/255, green: 166/255, blue: 43/255))
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            Image("customCashIcon") // Banknote icon
                                .bold()
                                .scaleEffect(0.6)
                                .foregroundStyle(.green)
                                .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                                .offset(x:-14, y:-0.3)
                        }
                        .offset(x:10, y:-28.6)
                    }
                    
                    ZStack{
                        // Skip Button
                        Button(action: {
                            withAnimation {
                                skipButtonPressed = true
                                skipAction?()
                            }
                            // Reset the button state after a short delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                                skipButtonPressed = false // Reset button state after the skip action
                            }
                        }) {
                            ZStack{
                                Image(systemName: "forward")
                                    .font(.system(size: 24))
                                    .fontWeight(.heavy)
                                    .padding(5)
                                    .foregroundStyle(Color(red: 231/255, green: 69/255, blue: 64/255).opacity(1.0))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                    .blur(radius: 0.4)
                                    .offset(x: 0, y: 3)
                                
                                Image(systemName: "forward")
                                    .font(.system(size: 23.6))
                                    .fontWeight(.heavy)
                                    .padding(5)
                                    .foregroundStyle(Color(red: 231/255, green: 69/255, blue: 64/255).opacity(1.0))
                                    .clipShape(Circle())
                                    .shadow(color: Color.black.opacity(0.15), radius: 2, x: 0, y: 2)
                                    .blur(radius: 0.4)
                                    .offset(x: 0, y: 3)
                            }
                        }
                        HStack{
                            Text(String(GameDataManager.shared.skipLevelCost))
                                .font(.footnote)
                                .scaleEffect(1.1)
                                .fontWeight(.bold)
                                .foregroundStyle(Color(red: 23/255, green: 166/255, blue: 43/255))
                                .multilineTextAlignment(.center)
                                .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                            Image("customCashIcon") // Banknote icon
                                .bold()
                                .scaleEffect(0.6)
                                .font(.system(size: 12))
                                .foregroundStyle(.green)
                            
                                .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                                .offset(x:-14, y:-0.3)
                        }
                        .offset(x:10, y:-20)
                    }
                    
                    
                    
                }
            }
            Spacer()
        }
        .fullScreenCover(isPresented: $showSettingsView) {
            SettingsView(isPresented: $showSettingsView, currentView: $currentView, previousView: $previousView)
                .presentationDetents([.large])
                .transition(.move(edge: .bottom))
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: showSettingsView)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.disabled)
                .presentationCompactAdaptation(.none)
            
        }
        .fullScreenCover(isPresented: $showThemeView) {
            ThemeView(isPresented: $showThemeView)
                .presentationDetents([.large])
                .transition(.move(edge: .leading))
                .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: showThemeView)
                .presentationDragIndicator(.hidden)
                .interactiveDismissDisabled(true)
                .presentationBackgroundInteraction(.disabled)
                .presentationCompactAdaptation(.none)
            
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .shadow(color: Color.white.opacity(2), radius: 10, y: 20)
        .shadow(color: Color.white.opacity(2), radius: 10, y: -20)
        
    }
}

// Preview provider for LowerPanelView
struct LowerPanelView_Previews: PreviewProvider {
    @State static var currentView: ViewState = .home
    @State static var previousView: ViewState = .launch
    @State static var isAGameView: Bool = false
    
    static var previews: some View {
        LowerPanelView(currentView: $currentView, previousView: $previousView)
            .previewLayout(.sizeThatFits)
            .padding()
    }
}
