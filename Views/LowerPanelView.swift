import SwiftUI

// Lower-Panel View for navigation options
struct LowerPanelView: View {
    
    @ObservedObject private var gameData = GameDataManager.shared
    
    @Binding var currentView: ViewState
    @Binding var previousView: ViewState
    
    var resetAction: (() -> Void)? = nil
    var hintAction: (() -> Void)? = nil
    var skipAction: (() -> Void)? = nil
    
    @State private var showThemeView = false
    @State private var showSettingsView = false
    @State private var showHelpView = false // Kept for future use if needed
    
    private var isAGameView: Bool { currentView.gameKey != nil }
    private var isHomeView: Bool { currentView == .home }
    
    // Defined a custom color for consistency
    private static let primaryRed = Color(red: 232/255, green: 69/255, blue: 64/255)
    private static let secondaryRed = Color(red: 238/255, green: 69/255, blue: 64/255)

    var body: some View {
        HStack {
            Spacer()
            
            if isHomeView {
                HomeViewButtons
            } else if !isAGameView {
                NonGameViewButtons
            } else {
                GameViewButtons 
            }
            
            Spacer()
        }
        
        .overlay(ModalViews)
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .background(Color.white.opacity(0.8))
        .shadow(color: Color.white.opacity(2), radius: 10, y: 20)
        .shadow(color: Color.white.opacity(2), radius: 10, y: -20)
    }
    
    // MARK: - View Sections
    
    @ViewBuilder
    private var HomeViewButtons: some View {
        // Settings Button
        SettingsButton(showSettingsView: $showSettingsView, size: 37.8, color: LowerPanelView.primaryRed)
        
        // This spacer replaces the large padding to separate the two buttons precisely
        Spacer()
            .frame(width: 180) // This fixed width mimics your padding(.leading, 180)
        
        // Audio Theme Button
        ThemeButton(showThemeView: $showThemeView)
    }
    
    @ViewBuilder
    private var NonGameViewButtons: some View {
        // Back button
        Button {
            withAnimation {
                // Simplified navigation logic
                currentView = (currentView == .mode) ? .home : .mode
            }
        } label: {
            Image(systemName: "arrowshape.backward.fill")
                .buttonStyle(size: 28, color: LowerPanelView.secondaryRed)
                .offset(x: -7, y: 3)
        }
        
        Spacer() // Separates the back button from the main block
            .frame(width: 80) // Mimics previous fixed spacing
        
        // Home Button
        Button {
            withAnimation {
                previousView = currentView
                currentView = .home
            }
        } label: {
            Image(systemName: "house.fill")
                .buttonStyle(size: 30, color: LowerPanelView.primaryRed)
                .background(currentView == .home ? Color.red.opacity(0.2): Color.clear)
                .clipShape(Circle())
                .offset(x:0, y: 3)
        }
        
        Spacer()
            .frame(width: 30) // Spacer between Home and Settings
        
        // Settings Button
        SettingsButton(showSettingsView: $showSettingsView, size: 36, color: LowerPanelView.primaryRed)
        
        Spacer()
            .frame(width: 30) // Spacer between Settings and Theme
        
        // Audio Theme Button
        ThemeButton(showThemeView: $showThemeView)
    }

    @ViewBuilder
    private var GameViewButtons: some View {
        // Return to levels button
        Button {
            withAnimation {
                previousView = currentView
                currentView = .level
            }
        } label: {
            Image(systemName: "arrowshape.backward.fill")
                .buttonStyle(size: 31, color: LowerPanelView.secondaryRed)
                // Removed redundant padding(.trailing, 70) and replaced it with a fixed spacer below
                .offset(x: -7, y: 3)
        }
        
        // Spacer that mimics the padding(.trailing, 70) from the original code
        Spacer()
            .frame(width: 70) 
        
        // Repeat Level Button
        Button {
            withAnimation { resetAction?() }
        } label: {
            ResetButtonContent()
        }
        
        
        Spacer()
            .frame(width: 40)
        
        // Hint Button
        PricedActionButton(
            action: { hintAction?() },
            systemName: "lightbulb.max",
            cost: gameData.hintCost,
            // Preserving the original complex offsets for exact layout
            iconOffset: .init(x: 0, y: 3),
            textOffset: .init(x: 10, y: -28.6)
        )
        
        
        Spacer()
            .frame(width: 40)
        
        // Skip Button
        PricedActionButton(
            action: { skipAction?() },
            systemName: "forward",
            cost: gameData.skipLevelCost,
            // Preserving the original complex offsets for exact layout
            iconOffset: .init(x: 0, y: 3),
            textOffset: .init(x: 10, y: -20)
        )
    }
    
    // MARK: - Modals
    @ViewBuilder
    private var ModalViews: some View {
        // Settings Modal
        .fullScreenCover(isPresented: $showSettingsView) {
            SettingsView(isPresented: $showSettingsView, currentView: $currentView, previousView: $previousView)
                .modalStyle()
        }
        
        // Theme Modal
        .fullScreenCover(isPresented: $showThemeView) {
            ThemeView(isPresented: $showThemeView)
                .modalStyle(transitionEdge: .leading)
        }
    }
}

// MARK: - View Modifiers and Subviews

// Common icon styling for nav buttons
fileprivate extension Image {
    func buttonStyle(size: CGFloat, color: Color) -> some View {
        self
            .font(.system(size: size))
            .fontWeight(.bold)
            .foregroundStyle(color)
            .clipShape(Circle())
            // Combined the two shadows into one, simplifying the ZStack requirement
            .shadow(color: .black.opacity(0.6), radius: 0.6, x: 0, y: 0) 
            .blur(radius: 0.4)
    }
}

// Extracted Modifiers for common buttons

private struct SettingsButton: View {
    @Binding var showSettingsView: Bool
    let size: CGFloat
    let color: Color
    
    var body: some View {
        Button {
            withAnimation { showSettingsView = true }
        } label: {
            Image(systemName: "gearshape.2.fill")
                .font(.system(size: size))
                .fontWeight(.light)
                .padding(size > 37 ? 8 : 2)
                .foregroundStyle(color)
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.2), radius: 0.5, x: 0, y: 0.4)
                .blur(radius: 0.4)
                .offset(x: 0, y: 3)
        }
    }
}

private struct ThemeButton: View {
    @Binding var showThemeView: Bool
    
    var body: some View {
        Button {
            withAnimation { showThemeView = true }
        } label: {
            Image(systemName: "music.note")
                .font(.system(size: 40))
                .padding(8)
                .fontWeight(.bold)
                .foregroundStyle(Color(red: 20/255, green: 20/255, blue: 20/255))
                .clipShape(Circle())
                .shadow(color: Color.black.opacity(0.25), radius: 1, x: 0, y: 1)
                .blur(radius: 0.3)
                .offset(x:0, y: 3)
        }
    }
}

// Content for the Reset Button
private struct ResetButtonContent: View {
    var body: some View {
        ZStack{
            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 23))
                .rotationEffect(.degrees(0))
                .fontWeight(.bold)
                .padding(5)
                .foregroundStyle(LowerPanelView.primaryRed)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                .blur(radius: 0.4)
                .offset(x: 0, y: 3)
            
            Image(systemName: "arrow.trianglehead.counterclockwise.rotate.90")
                .font(.system(size: 25))
                .rotationEffect(.degrees(0))
                .fontWeight(.bold)
                .padding(5)
                .foregroundStyle(LowerPanelView.primaryRed)
                .shadow(color: .black.opacity(0.15), radius: 1, x: 0, y: 1)
                .blur(radius: 0.4)
                .offset(x: 0, y: 3)
        }
    }
}

// Unified button for Hint and Skip - preserves original layout offsets
private struct PricedActionButton: View {
    let action: () -> Void
    let systemName: String
    let cost: Int
    let iconOffset: CGSize
    let textOffset: CGSize
    
    private let iconRed = Color(red: 231/255, green: 69/255, blue: 64/255)
    private let costGreen = Color(red: 23/255, green: 166/255, blue: 43/255)
    
    var body: some View {
        ZStack {
            Button(action: action) {
                ZStack {
                    Image(systemName: systemName) // Smaller base image
                        .font(.system(size: 23.4))
                        .fontWeight(.heavy)
                        .padding(.vertical, 5)
                        .foregroundStyle(iconRed)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                        .blur(radius: 0.4)
                        .offset(iconOffset)
                    
                    Image(systemName: systemName) // Larger top image
                        .font(.system(size: 25.4))
                        .fontWeight(.heavy)
                        .padding(.vertical, 5)
                        .foregroundStyle(iconRed)
                        .shadow(color: .black.opacity(0.15), radius: 2, x: 0, y: 2)
                        .blur(radius: 0.4)
                        .offset(iconOffset)
                }
            }
            
            // Cost Display Stack (precisely positioned)
            HStack(spacing: 0) {
                Text(String(cost))
                    .font(.footnote)
                    .scaleEffect(1.1)
                    .fontWeight(.bold)
                    .foregroundStyle(costGreen)
                    .multilineTextAlignment(.center)
                    .shadow(color: .black.opacity(0.3), radius: 1, x: 0, y: 1)
                
                Image("customCashIcon") // Token icon
                    .scaleEffect(0.6)
                    .foregroundStyle(.green)
                    .shadow(color: .black.opacity(0.18), radius: 1, x: 0, y: 1)
                    .offset(x:-14, y:-0.3)
            }
            .offset(textOffset) // Apply the specific offset (e.g., x:10, y:-28.6)
        }
    }
}

// Modifier for repetitive modal presentation style
fileprivate extension View {
    func modalStyle(transitionEdge: Edge = .bottom) -> some View {
        self
            .presentationDetents([.large])
            .transition(.move(edge: transitionEdge))
            .animation(.spring(response: 0.5, dampingFraction: 0.7, blendDuration: 0.3), value: self.isPresented(self.isPresented.wrappedValue))
            .presentationDragIndicator(.hidden)
            .interactiveDismissDisabled(true)
            .presentationBackgroundInteraction(.disabled)
            .presentationCompactAdaptation(.none)
    }
    
    // Helper to extract a binding value for animation usage
    private func isPresented(_ value: Bool) -> Bool { value }
}


// Preview provider for LowerPanelView
struct LowerPanelView_Previews: PreviewProvider {
    @State static var homeView: ViewState = .home
    @State static var levelView: ViewState = .level
    @State static var gameView: ViewState = .game(key: "A")
    
    static var previews: some View {
        VStack(spacing: 20) {
            Text("Home View").font(.caption)
            LowerPanelView(currentView: $homeView, previousView: .constant(.launch))
            
            Text("Level Select View").font(.caption)
            LowerPanelView(currentView: $levelView, previousView: .constant(.home))
            
            Text("Game View").font(.caption)
            LowerPanelView(currentView: $gameView, previousView: .constant(.level), resetAction: {}, hintAction: {}, skipAction: {})
        }
        .previewLayout(.sizeThatFits)
        .padding()
    }
}
