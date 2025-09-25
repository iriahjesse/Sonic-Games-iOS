import SwiftUI

// This view manages the Sonic Seek Game, including the grid layout, audio pairs, and interactions.
// It provides UI elements for users to interact with the grid, listen to
// audio clues, and attempt to match audio pairs by tapping on cells. It also supports game reset,
// skipping to the next level, and offering hints based on user progress.

struct SonicSeekView: View {
    
    // MARK: - Properties
    // Binding variables for view states and alerts
    @Binding var currentView: ViewState
    @Binding var previousView: ViewState
    @Binding var showMoreTokensAlert: Bool
    @Binding var showWinsAlert: Bool
    @Binding var selectedLevelIndex: Int
    
    // State variable to control the display of GameComplete view
    @State private var gameComplete: Bool = false
    
    // Game configuration properties
    let selectedModeKey: GameDataManager.GameModeKey
    
    // Observes the shared instance of UserPreferencesManager to react to changes in the current audio theme.
    @ObservedObject private var userPreferences = UserPreferencesManager.shared
    private var selectedThemeKey: AudioThemeManager.AudioThemeKey { // Computed property
        userPreferences.currentAudioTheme!
    }
    
    
    // States for game logic
    @State private var audioPairs: [String] = []    // Stores the audio file paths for the level.
    @State private var audioInitialised = false // Indicates whether the audio has been initialised.
    @State private var cellColors: [Color] = []  // Stores the colors for each cell.
    @State private var colorsInitialised = false  // Indicates whether the cell colors have been initialised.
    @State private var selectedCells: [Int] = []  // Stores the indices of the currently selected cells.
    @State private var matchedCells: Set<Int> = [] // Stores the indices of the matched cells.
    @State private var interactionDisabled = false  // Disables user interaction when true.
    @State private var colorUpdateTrigger = false // Triggers a color update for the cells.
    @State private var currentCellLocations: [Int] = []   // Stores the current locations of cells (used in shuffle mode).
    @State private var shuffleTimer: Timer?  // Timer for shuffling cells in shuffle mode.
    @State private var randomShapeIndex: Int = Int.random(in: 0...9) // Random index for shape selection.
    @State private var staticRandomColor: Color = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .gray // Static random color for cells.
    @State private var staticPolygonSides: Int = Int.random(in: 3...8) // Static random number of sides for polygon shape.
    @State private var cellOffsets: [CGSize] = [] // Stores the offsets for cell vibration animation.
    @State private var matchedCellOpacities: [Double] = []// Stores the opacities of matched cells.
    @State private var levelCompleted = false  // Indicates whether the current level is completed.
    
    
    // MARK: - Body
    var body: some View {
        
        ZStack {
            Rectangle()
                .ignoresSafeArea()
                .frame(width: .infinity, height: .infinity)
                .foregroundStyle(Color(GameDataManager.shared.getGameProperties(for: .sonicSeek)?.accentColor.opacity(0.85) ?? .white))
                .blur(radius:200)
            
            VStack {
                UpperPanelView(showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert)
                Spacer()
                
                if let config = GameDataManager.shared.getSonicSeekLayoutConfiguration(for: selectedLevelIndex) {
                    
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(CGFloat(config.cellWidth)), spacing: CGFloat(config.cellSpacing)*1.2), count: config.columns), spacing: CGFloat(Double(config.cellSpacing))) {
                        ForEach(selectedModeKey == .shuffle ? currentCellLocations : Array(0..<config.rows * config.columns), id: \.self) { index in
                            cellView(for: index, config: config)
                        }
                    }
                    .onAppear {
                        setupGame()
                    }
                    .onDisappear {
                        shuffleTimer?.invalidate()
                        shuffleTimer = nil
                        AudioManager.shared.stopAudio() // Stop any currently playing
                        
                    }
                    .onChange(of: colorUpdateTrigger) { _ in
                        initialiseCellColors()
                    }
                } else {
                    Text("Configuration not found.")
                        .foregroundColor(.red)
                }
                
                Spacer();
                
                LowerPanelView(currentView: $currentView, previousView: $previousView, resetAction: resetGame, hintAction: giveHint, skipAction: skipToNextLevel)
                    .padding(.top, 3)
            }
            
            
            .disabled(interactionDisabled)
            if gameComplete {
                GameCompleteView(
                    isPresented: $gameComplete,
                    gameKey: .sonicSeek,
                    modeKey: selectedModeKey,
                    completedLevel: selectedLevelIndex,
                    onLevelsButtonTapped: { currentView = .level },
                    onRepeatButtonTapped: {
                        gameComplete = false
                        resetGame()
                    },
                    onNextButtonTapped: {
                        let completedLevel = selectedLevelIndex // Store completed level
                        let nextLevel = completedLevel + 1
                        if nextLevel < GameDataManager.shared.getGameProperties(for: .sonicSeek)?.levelCount ?? 0 {
                            selectedLevelIndex = nextLevel
                            gameComplete = false
                            resetGame()
                            setupGame()
                        } else {
                            currentView = .level
                        }
                    }
                )
            }
        }
    }
    
    
    // MARK: - Setup and Initialisation
    
    // Sets up the game by retrieving necessary configurations, initialising audio, colours, and handling mode-specific behaviour.
    private func setupGame() {
        guard let gameProperties = GameDataManager.shared.getGameProperties(for: .sonicSeek) else {
            print("Error: Game properties not found for Sonic Seek.")
            currentView = previousView
            return
        }
        
        
        let availableModes = Array(gameProperties.modes)
        guard availableModes.contains(selectedModeKey) else {
            print("Error: Selected mode (\(selectedModeKey)) is not available.")
            currentView = previousView
            return
        }
        
        guard selectedLevelIndex >= 0 && selectedLevelIndex <= gameProperties.levelCount else {
            print("Error: Invalid level selected (\(selectedLevelIndex)).")
            currentView = previousView
            return
        }
        guard let config = GameDataManager.shared.getSonicSeekLayoutConfiguration(for: selectedLevelIndex) else {
            print("Error: Layout configuration not found for level \(selectedLevelIndex).")
            currentView = previousView
            return
        }
        // Initialise audio and cell colours if they have not been initialised yet
        if !audioInitialised {
            initialiseAudioPairs()
            audioInitialised = true
        }
        if !colorsInitialised {
            initialiseCellColors()
            colorsInitialised = true
        }
        
        // Update random properties
        randomShapeIndex = Int.random(in: 0...9)
        staticRandomColor = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .gray
        staticPolygonSides = Int.random(in: 3...8)
        
        // Set up the grid state
        if let config = GameDataManager.shared.getSonicSeekLayoutConfiguration(for: selectedLevelIndex) {
            let totalCells = config.rows * config.columns
            matchedCellOpacities = Array(repeating: 1.0, count: totalCells)
            cellOffsets = Array(repeating: .zero, count: totalCells)
            currentCellLocations = Array(0..<totalCells)
            cellColors = Array(repeating: .gray, count: totalCells)
        }
        
        // Set shuffle mode based on user's selected game mode
        if selectedModeKey == .shuffle {
            activateShuffling(isOn: true)
        } else {
            activateShuffling(isOn: false) // Or remove this if activateShuffling(isOn: false) does nothing
        }
    }
    
    // Fetches and shuffles the audio pairs based on the selected theme and level configuration.
    private func initialiseAudioPairs() {
        guard let config = GameDataManager.shared.getSonicSeekLayoutConfiguration(for: selectedLevelIndex) else {
            print("Error: Invalid Level Index")
            return
        }
        
        // Fetch the audio theme using the selectedThemeKey
        guard let availableAudioFiles = AudioThemeManager.shared.getThemedAudioFiles(forKey: selectedThemeKey) else {
            print("Error: Could not retrieve audio files for key: \(selectedThemeKey)")
            return
        }
        
        let totalCells = config.rows * config.columns
        let pairsNeeded = totalCells / 2
        var shuffledAudioFiles = availableAudioFiles.shuffled()
        audioPairs = []
        
        // Create pairs of audio
        for _ in 0..<pairsNeeded {
            if let audioFile = shuffledAudioFiles.popLast()  {
                audioPairs.append(contentsOf: [audioFile, audioFile])
            }
        }
        
        // If the total cells count is odd, append one more audio file
        if totalCells % 2 != 0 {
            audioPairs.append(shuffledAudioFiles.popLast() ?? "defaultAudio")
        }
        
        // Shuffle the audio pairs
        audioPairs.shuffle()
    }
    
    // Initialises the cell colours randomly based on the selected level's layout.
    private func initialiseCellColors() {
        guard let config = GameDataManager.shared.getSonicSeekLayoutConfiguration(for: selectedLevelIndex) else { return }
        var availableColors = ColorManager.shared.getAllCustomColors()
        let totalCells = config.rows * config.columns
        cellColors = (0..<totalCells).map { _ in
            let randomColorKey = availableColors.keys.randomElement() ?? .peach
            return availableColors[randomColorKey] ?? .white
        }
        
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) else { return }
    }
    
    // Provides a collection of available custom colours for the cells.
    private var availableColors: [ColorManager.CustomColorNames: Color] {
        return ColorManager.shared.getAllCustomColors()
    }
    
    // MARK: - Game Logic
    
    // Returns the colour for the cell at a specific index.
    private func getCellColor(for index: Int) -> Color {
        guard index < cellColors.count else { return .gray }
        return cellColors[index]
    }
    
    // Returns the shadow effect for a given cell based on its selection status.
    private func getCellShadow(for index: Int) -> Color {
        if selectedCells.contains(index) {
            return Color(.white)
        }
        return .clear
    }
    
    // Handles the event when a cell is tapped by the player, adding it to the selected cells and checking for a match.
    private func cellTapped(index: Int) {
        guard !matchedCells.contains(index) && !interactionDisabled else { return }
        
        if let cellIndex = selectedCells.firstIndex(of: index) {
            selectedCells.remove(at: cellIndex)
        } else {
            selectedCells.append(index)
            playCellAudio(index)
        }
        
        if selectedCells.count == 2 {
            checkForMatch()
        }
    }
    
    // Plays the audio for the cell at the specified index
    private func playCellAudio(_ index: Int) {
        if index < audioPairs.count {
            AudioManager.shared.loadAudio(audioPairs[index])
            AudioManager.shared.playAudio()
        }
    }
    
    // Checks if the two selected cells match based on their audio files and updates the game state accordingly.
    // If the cells match, they are added to the matched cells set, their opacity is faded, and the game checks if all pairs are matched.
    // If they do not match, a vibration animation is triggered, and the selected cells are reset.
    //
    // - Note: The method also disables user interaction during the checking process to prevent further cell selections until the match is processed.
    private func checkForMatch() {
        guard selectedCells.count == 2,
              let firstCellIndex = selectedCells.first,
              let secondCellIndex = selectedCells.last,
              firstCellIndex < audioPairs.count,
              secondCellIndex < audioPairs.count else { return }
        
        interactionDisabled = true
        let isMatch = audioPairs[firstCellIndex] == audioPairs[secondCellIndex]
        
        if isMatch {
            matchedCells.insert(firstCellIndex)
            matchedCells.insert(secondCellIndex)
            // Wait 0.5 seconds, then fade out
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                withAnimation(.easeOut(duration: 0.5)) {
                    matchedCellOpacities[firstCellIndex] = 0
                    matchedCellOpacities[secondCellIndex] = 0
                }
                selectedCells.removeAll()
                interactionDisabled = false
            }
            
            // Check if all pairs are matched
            print("Debug - Handling last match")
            if matchedCells.count == audioPairs.count {
                gameComplete = true
            }
        } else {
            // Add vibration animation for non-matching cells
            withAnimation(.linear(duration: 0.1).repeatCount(3)) {
                selectedCells.forEach { index in
                    cellOffsets[index] = CGSize(width: -5, height: 0)
                }
            }
            
            // Reset the cells position after vibration
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                withAnimation(.linear(duration: 0.1)) {
                    selectedCells.forEach { index in
                        cellOffsets[index] = .zero
                    }
                }
                selectedCells.removeAll()
                interactionDisabled = false
            }
        }
    }
    
    // Handles resetting the game, disabling interaction during reset
    private func resetGame() {
        interactionDisabled = true
        matchedCells.removeAll()
        selectedCells.removeAll()
        if let config = GameDataManager.shared.getSonicSeekLayoutConfiguration(for: selectedLevelIndex) {
            let totalCells = config.rows * config.columns
            matchedCellOpacities = Array(repeating: 1.0, count: totalCells)
        }
        initialiseAudioPairs()
        initialiseCellColors()
        if selectedModeKey == .shuffle {
            currentCellLocations = Array(0..<currentCellLocations.count) // Reset shuffled locations
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) { // Short delay
            interactionDisabled = false
        }
    }
    
    // Skips to the next level if the user has enough tokens and they're not at the maximum level of the current (selected) game mode. If the player doesn't have enough tokens, it shows an alert.
    private func skipToNextLevel() {
        guard UserProgressManager.shared.totalTokens >= GameDataManager.shared.hintCost else {
            showMoreTokensAlert = true
            return
        }
        let nextLevel = selectedLevelIndex + 1
        guard let gameProperties = GameDataManager.shared.getGameProperties(for: .sonicSeek) else {
            print("Error: Could not retrieve game properties for Sonic Seek.")
            return
        }
        
        if nextLevel > gameProperties.levelCount { // Check if nextLevel exceeds the maximum level
            print("Skip action: All levels complete. Returning to select menu.")
            UserProgressManager.shared.updateGameProgress(
                gameKey: .sonicSeek,
                modeKey: selectedModeKey,
                maxLevelIndex: nextLevel
            )
            currentView = .level // Go back to selection view
            return
        } else {
            print("Skip action: Advancing to next level.")
            UserProgressManager.shared.deductCash(amount: GameDataManager.shared.skipLevelCost)
            UserProgressManager.shared.updateGameProgress(
                gameKey: .sonicSeek,
                modeKey: selectedModeKey,
                maxLevelIndex: nextLevel
            )
            selectedLevelIndex = nextLevel
            withAnimation{
                resetGame()
                setupGame()
            }
        }
    }
    
    // Deducts tokens for a hint, revealing a matched pair, and checking if the level is complete.
    private func giveHint() {
        guard UserProgressManager.shared.totalTokens >= GameDataManager.shared.hintCost else {
            showMoreTokensAlert = true
            return
        }
        
        UserProgressManager.shared.deductCash(amount: GameDataManager.shared.hintCost)
        UserProgressManager.shared.saveGameData()
        
        interactionDisabled = true
        
        // Make a match
        if let firstUnmatchedCell = (0..<audioPairs.count).first(where: { !matchedCells.contains($0) }) {
            let matchingCell = audioPairs.firstIndex(of: audioPairs[firstUnmatchedCell])! // Find the matching cell
            
            // Simulate taps to trigger sounds and shadows
            cellTapped(index: firstUnmatchedCell)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { // Slight delay for the first tap to register
                cellTapped(index: matchingCell)
            }
        }
        
        // Check if this hint completed the level
        if matchedCells.count == audioPairs.count {
            gameComplete = true
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            interactionDisabled = false
        }
    }
    
    // MARK: - View Helper Methods
    
    // Creates the view for each cell in the grid, determining its colour, shape, and interactivity based on the selected game mode.
    private func cellView(for index: Int, config: (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int)) -> some View {
        let minDimension = min(CGFloat(config.cellWidth), CGFloat(config.cellHeight)) * 0.8
        let maxWidth = CGFloat(config.cellWidth)
        let maxHeight = CGFloat(config.cellHeight)
        let randomScale = Double.random(in: 0.5...1.0)
        let availableColors = ColorManager.shared.getAllCustomColors()
        let cellColor = selectedModeKey == .recolor ? (availableColors.randomElement()?.value ?? .gray) : staticRandomColor
        return Group {
            switch selectedModeKey {
            case .classic:
                RoundedRectangle(cornerRadius: 10)
                    .fill(cellColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: 4)
                    )
                
            case .shapes:
                let shape = shapesView(for: index)
                shape
                    .fill(cellColor)
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, lineWidth: 4)
                    )
                    .modifier(ShapeModifier())
                
            case .resize:
                let shape = shapesView(for: index)
                shape
                    .fill(cellColor)
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, lineWidth: 4)
                    )
                    .modifier(ResizeModifier(index: index))
                
            case .recolor:
                let shape = shapesView(for: index)
                shape
                    .modifier(RecolorModifier( index: index))
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, lineWidth: 4)
                    )
                    .modifier(ShapeModifier())
                    .modifier(ResizeModifier(index: index))
                    
            case .rotate:
                let shape = shapesView(for: index)
                shape
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 4, dash: [100, 2]))
                    )
                    .modifier(ShapeModifier())
                    .modifier(ResizeModifier(index: index))
                    .modifier(RecolorModifier(index: index))
                    .modifier(RotationModifier(index: index))
            case .translate:
                let shape = shapesView(for: index)
                shape
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 4, dash: [100, 2]))
                    )
                    .modifier(ShapeModifier())
                    .modifier(ResizeModifier(index: index))
                    .modifier(RecolorModifier(index: index))
                    .modifier(RotationModifier(index: index))
                    .modifier(TranslationModifier(index: index))
            case.dilate:
                let shape = shapesView(for: index)
                shape
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 4, dash: [100, 2]))
                    )
                    .modifier(ShapeModifier())
                    .modifier(ResizeModifier(index: index))
                    .modifier(RecolorModifier(index: index))
                    .modifier(RotationModifier(index: index))
                    .modifier(TranslationModifier(index: index))
                    .modifier(DilationModifier(index: index))
                
            case.shuffle:
                let shape = shapesView(for: index)
                shape
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 4, dash: [100, 2]))
                    )
                    .modifier(ShapeModifier())
                    .modifier(ResizeModifier(index: index))
                    .modifier(RecolorModifier(index: index))
                    .modifier(RotationModifier(index: index))
                    .modifier(TranslationModifier(index: index))
                    .modifier(DilationModifier(index: index))
            case.ghost:
                let shape = shapesView(for: index)
                shape
                    .frame(width: maxWidth * randomScale, height: maxHeight * randomScale)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2.4)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 4, dash: [100, 2]))
                        
                    )
                    .modifier(ShapeModifier())
                    .modifier(ResizeModifier(index: index))
                    .modifier(RecolorModifier(index: index))
                    .modifier(RotationModifier(index: index))
                    .modifier(TranslationModifier(index: index))
                    .modifier(DilationModifier(index: index))
                    .modifier(GhostModifier(index: index))
            default: EmptyView()
            }
        }
        .frame(width: CGFloat(config.cellWidth), height: CGFloat(config.cellHeight))
        .shadow(color: getCellShadow(for: index), radius: getCellShadow(for: index) == .clear ? 0 : 20)
        .offset(index < cellOffsets.count ? cellOffsets[index] : .zero)
        .opacity(matchedCellOpacities.indices.contains(index) ? matchedCellOpacities[index] : 1.0)
        .onTapGesture { cellTapped(index: index) }
    }
    
    // Returns a randomly selected shape from a predefined list of shapes.
    private func shapesView(for index: Int) -> some Shape {
        let shapes: [AnyShape] = [
            AnyShape(RoundedRectangle(cornerRadius: 10)),
            AnyShape(Circle()),
            AnyShape(Capsule()),
            AnyShape(Ellipse()),
            AnyShape(CustomShapeManager.shared.getTriangle()),
            AnyShape(CustomShapeManager.shared.getStar(points: 5, cornerRadius: 10)),
            AnyShape(CustomShapeManager.shared.getKite(cornerRadius: 10)),
            AnyShape(CustomShapeManager.shared.getHeart()),
            AnyShape(CustomShapeManager.shared.getPolygon(sides: staticPolygonSides)),
            AnyShape(CustomShapeManager.shared.getCross())
        ]
        return shapes[randomShapeIndex]
    }
    
    private func activateShuffling(isOn: Bool) {
        if isOn {
            shuffleTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: true) { _ in
                withAnimation(.easeInOut(duration: 0.5)) {
                    // Pick two random indices
                    let index1 = Int.random(in: 0..<currentCellLocations.count)
                    let index2 = Int.random(in: 0..<currentCellLocations.count)
                    // Swap just those two cells
                    currentCellLocations.swapAt(index1, index2)
                }
            }
        } else {
            shuffleTimer?.invalidate()
            shuffleTimer = nil
            withAnimation(.easeInOut(duration: 0.5)) {
                currentCellLocations = Array(0..<currentCellLocations.count)
            }
        }
    }
    // MARK: - View Modifiers
    // Modifier to make cells disappear/appear randomly
    struct GhostModifier: ViewModifier {
        let index: Int
        @State private var isVisible = true
        @State private var timer: Timer?
        
        func body(content: Content) -> some View {
            content
                .opacity(isVisible ? 1 : 0)
                .onAppear {
                    timer = Timer.scheduledTimer(withTimeInterval: 3.5, repeats: true) { _ in
                        if Double.random(in: 0...1) < 0.15 {
                            withAnimation(.easeInOut(duration: 0.5)) {
                                isVisible = false
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    isVisible = true
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
    }
    
    
    
    // Modifier to dilate a cell
    struct DilationModifier: ViewModifier {
        let index: Int
        @State private var scale: CGFloat = 1.0
        @State private var timer: Timer?
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(scale)
                .onAppear {
                    timer = Timer.scheduledTimer(withTimeInterval: 2.75, repeats: true) { _ in
                        if Bool.random() {
                            withAnimation(.easeInOut(duration: 1.0)) {
                                scale = CGFloat.random(in: 0.5...1.2)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.5)) {
                                    scale = 1.0
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
    }
    
    
    // Modifier to translate a cell
    struct TranslationModifier: ViewModifier {
        let index: Int
        @State private var offset: CGSize = .zero
        @State private var opacity: Double = 1.0
        @State private var timer: Timer? // Timer declared here
        
        private let shuffleInterval = 2.0
        private let animationDuration = 0.5
        
        func body(content: Content) -> some View {
            content
                .offset(offset)
                .opacity(opacity)
                .onAppear {
                    timer = Timer.scheduledTimer(withTimeInterval: shuffleInterval, repeats: true) { _ in // Use timer
                        withAnimation(.easeInOut(duration: animationDuration)) {
                            opacity = 0
                            offset = CGSize(
                                width: CGFloat.random(in: -50...50),
                                height: CGFloat.random(in: -50...50)
                            )
                        }
                        
                        DispatchQueue.main.asyncAfter(deadline: .now() + animationDuration/2) {
                            withAnimation(.easeInOut(duration: animationDuration)) {
                                opacity = 1
                                offset = .zero
                            }
                        }
                    }
                }
                .onDisappear {
                    timer?.invalidate() // Invalidate on disappear
                    timer = nil
                }
        }
    }
    
    // Modifier to rotate a cell
    struct RotationModifier: ViewModifier {
        let index: Int
        @State private var angle: Double = 0
        @State private var timer: Timer? // Timer is now local
        
        private let initialAngle: Double
        private let rotationSpeed: Double
        private let rotationDirection: Double
        
        init(index: Int) {
            self.index = index
            self.initialAngle = Double.random(in: 0...360)
            self.rotationSpeed = Double.random(in: 1.5...4.0)
            self.rotationDirection = Bool.random() ? 1 : -1
        }
        
        func body(content: Content) -> some View {
            content
                .rotationEffect(.degrees(angle))
                .onAppear {
                    angle = initialAngle
                    timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
                        withAnimation(.linear(duration: 0.05)) {
                            angle += rotationSpeed * rotationDirection
                        }
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
    }
    
    
    
    struct ResizeModifier: ViewModifier {
        let index: Int
        @State private var scale: CGFloat = 1.0
        @State private var timer: Timer?
        
        func body(content: Content) -> some View {
            content
                .scaleEffect(scale)
                .onAppear {
                    timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                        if Double.random(in: 0...1) < 0.5 {
                            withAnimation(.easeInOut(duration: 0.8)) {
                                scale = CGFloat.random(in: 0.2...1.2)
                            }
                            
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                                withAnimation(.easeInOut(duration: 0.8)) {
                                    scale = 1.0
                                }
                            }
                        }
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
    }
    
    
    
    // Modifier to change the colour of a cell periodically
    struct RecolorModifier: ViewModifier {
        let index: Int
        @State private var currentColor: Color = .white
        @State private var timer: Timer?
        
        func body(content: Content) -> some View {
            content
                .foregroundStyle(currentColor)
                .onAppear {
                    // Set initial random color
                    currentColor = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .white
                    
                    timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 1.5...3.5), repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            // Get new random color on each interval
                            currentColor = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .white
                        }
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
    }

    
    
    
    // Modifier to change the shape of a cell periodically
    struct ShapeModifier: ViewModifier {
        @State private var shapeIndex: Int = Int.random(in: 0..<10)
        @State private var timer: Timer?
        
        func body(content: Content) -> some View {
            content
                .onAppear {
                    timer = Timer.scheduledTimer(withTimeInterval: 2.2, repeats: true) { _ in
                        withAnimation(.easeInOut(duration: 0.5)) {
                            shapeIndex = Int.random(in: 0..<10)
                        }
                    }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
        }
    }
    
    
    
}

// MARK: - Preview
 
// Preview Provider for SonicSeek View
struct SonicSeek_Previews: PreviewProvider {
    static var previews: some View {
        SonicSeekView(
            currentView: .constant(.game(.sonicSeek)),     // Binding to the current view, set to `.sonicSeek`
            previousView: .constant(.level),            // Binding to the previous view, set to `.select` for the preview
            showMoreTokensAlert: .constant(false),         // Binding to the "More Cash" alert, initially false
            showWinsAlert: .constant(false),             // Binding to the "Wins" alert, initially false
            selectedLevelIndex: .constant(25),            // Binding to the selected level index
            selectedModeKey: .shuffle                   // The selected game mode for the preview
            
        )
    }
}
