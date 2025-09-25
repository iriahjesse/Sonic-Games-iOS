
import SwiftUI

// This view manages the Sonic Sync game, where users interact with and swap cells in a grid
// to match a given grid whilst utilising audio and visual feedback.

struct SonicSyncView: View {
    // MARK: - Properties
    // Bindings for view state and alerts
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
    @State private var audioFiles: [String] = []
    @State private var audioInitialised = false
    @State private var cellColors: [Color] = []
    @State private var colorsInitialised = false
    @State private var givenGrid: [String] = []
    @State private var userGrid: [String] = []
    @State private var selectedCell: Int?
    @State private var playingAudioCell: Int?
    @State private var interactionDisabled = false
    @State private var isComplete = false
    @State private var randomShapeIndex: Int = Int.random(in: 0...9)
    @State private var swappingCells: Set<Int> = []
    @State private var invalidSwapCells: Set<Int> = []
    @State private var isPlayingIntro = false
    @State private var staticRandomColor: Color = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .gray
    @State private var staticPolygonSides: Int = Int.random(in: 3...8)
    @State private var cellOffsets: [CGPoint] = []
    @State private var vibratingCells: Set<Int> = []
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Rectangle()
                .ignoresSafeArea()
                .frame(width: .infinity, height: .infinity)
                .foregroundStyle(Color(GameDataManager.shared.getGameProperties(for: .sonicSync)?.accentColor.opacity(0.95) ?? .white))
                .blur(radius:200)
            
            VStack {
                
                UpperPanelView(showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert)
                Spacer()
                
                if let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) {
                    
                    if selectedLevelIndex < 5{
                        Text("MATCH THIS:")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(.bottom, 10)
                    }
                    // Given/Target Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(CGFloat(config.cellWidth)), spacing: CGFloat(Double(config.cellSpacing)*1.2)), count: config.columns), spacing: CGFloat(Double(config.cellSpacing) * 1.2)) {
                        ForEach(0..<givenGrid.count, id: \.self) { index in
                            cellView(for: index, isGivenGrid: true, config: config)
                        }
                    }
                    .scaleEffect(0.68)
                    .frame(width: CGFloat(config.columns * config.cellWidth), height: CGFloat(config.rows * config.cellHeight) * 0.8)
                    
                    CustomShapeManager.shared.getDownArrow()
                        .frame(width: 26, height: 80)
                        
                        .shadow(color: Color.black, radius: 0.5)
                        .padding(.vertical, 10)
                    
                    if selectedLevelIndex < 5{
                        Text("REARRANGE HERE:")
                            .font(.subheadline)
                            .fontWeight(.bold)
                            .padding(12)
                    }
                    // User Grid
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(CGFloat(config.cellWidth)), spacing: CGFloat(config.cellSpacing)), count: config.columns), spacing: CGFloat(config.cellSpacing)) {
                        ForEach(0..<userGrid.count, id: \.self) { index in
                            cellView(for: index, isGivenGrid: false, config: config)
                        }
                    }
                }
                
                Spacer()
                
                LowerPanelView(currentView: $currentView, previousView: $previousView, resetAction: resetGame, hintAction: giveHint, skipAction: skipToNextLevel)
            }
            .disabled(interactionDisabled || isComplete)
            .onAppear {
                setupGame()
            }
            .onDisappear {
                AudioManager.shared.stopAudio() // Stop any currently playing audio
                isPlayingIntro = false // Stop the intro sequence
                playingAudioCell = nil // Clear the currently playing cell
                
            }
            if gameComplete {
                GameCompleteView(
                    isPresented: $gameComplete,
                    gameKey: .sonicSync,
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
                        if nextLevel < GameDataManager.shared.getGameProperties(for: .sonicSync)?.levelCount ?? 0 {
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
        
        .onTapGesture {
            if isPlayingIntro {
                isPlayingIntro = false
                playingAudioCell = nil
            }
        }
    }
    
    // MARK: - Setup and Initialisation
    
    // Sets up the game by initialising game properties, audio, and cell configurations.
    // Validates game mode, level, and prepares the initial game state.
    private func setupGame() {
        guard let gameProperties = GameDataManager.shared.getGameProperties(for: .sonicSync) else {
            print("Error: Game properties not found for Sonic Sync.")
            currentView = previousView
            return
        }
        
        // Validate the game mode key
        let availableModes = Array(gameProperties.modes)
        guard availableModes.contains(selectedModeKey) else {
            print("Error: Selected mode (\(selectedModeKey)) is not available.")
            currentView = previousView
            return
        }
        
        // Validate the level index
        guard selectedLevelIndex >= 0 && selectedLevelIndex <= gameProperties.levelCount else {
            print("Error: Invalid level selected (\(selectedLevelIndex)).")
            currentView = previousView
            return
        }
        
        // Validate the game configuration
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) else {
            print("Error: Layout configuration not found for level \(selectedLevelIndex).")
            currentView = previousView
            return
        }
        
        // Initialise audio if not done yet
        if !audioInitialised {
            initialiseAudio()
            audioInitialised = true
        }
        
        // Initialise cell colours if not done yet
        if !colorsInitialised {
            initialiseCellColors()
            colorsInitialised = true
        }
        
        // Update random properties
        randomShapeIndex = Int.random(in: 0...9)
        staticRandomColor = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .gray
        staticPolygonSides = Int.random(in: 3...8)
        
        // Set initial offsets for grid cells
        if let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) {
            cellOffsets = Array(repeating: .zero, count: config.rows * config.columns)
        }
        
    }
    
    // Initialises the colours for each cell based on the layout configuration
    private func initialiseCellColors() {
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) else { return }
        var availableColors = ColorManager.shared.getAllCustomColors()
        let totalCells = config.rows * config.columns
        
        cellColors = (0..<totalCells).map { _ in
            availableColors.randomElement()?.value ?? .gray
        }
    }
    
    // Initialises audio files for the game grid based on the selected theme by retrieving themed audio files
    // and creating both the given and user grids with randomised audio.
    private func initialiseAudio() {
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex)else {  print("Error: Invalid Level Index")
            return
        }
        // Fetch the audio theme using the selectedThemeKey
        guard let availableAudioFiles = AudioThemeManager.shared.getThemedAudioFiles(forKey: selectedThemeKey) else {
            print("Error: Could not retrieve audio files for key: \(selectedThemeKey)")
            return
        }
        
        // Shuffle audio files and assign them to the given grid
        let shuffledAudioFiles = availableAudioFiles.shuffled()
        
        // Populate the given and user grids with randomised audio files
        givenGrid = (0..<(config.rows * config.columns)).map { _ in
            shuffledAudioFiles.randomElement() ?? ""
        }
        userGrid = scrambleGrid(givenGrid, steps: config.scrambleSteps)
    }
    
    // Plays all cells in the given grid sequentially with audio feedback.
    private func playAllGivenCells() {
        isPlayingIntro = true
        
        // Play audio for each cell in the given grid
        for (index, _) in givenGrid.enumerated() {
            DispatchQueue.main.asyncAfter(deadline: .now() + Double(index) * 1.3) {
                // Only continue if intro hasn't been stopped
                if isPlayingIntro {
                    playingAudioCell = index
                    playAudio(for: index, grid: givenGrid)
                    
                    // Reset playing audio cell after 0.8 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        if playingAudioCell == index {
                            playingAudioCell = nil
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Game Logic
    
    // Scrambles the given grid by randomly swapping elements for a specified number of steps.
    private func scrambleGrid(_ grid: [String], steps: Int) -> [String] {
        // Retrieve the layout configuration for the current level. If it fails, return the original grid.
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) else {
            return grid
        }
        
        // Create a mutable copy of the original grid to perform swaps on.
        var scrambledGrid = grid
        
        // Perform the scrambling for the specified number of steps.
        for _ in 0..<steps {
            let index = Int.random(in: 0..<scrambledGrid.count)
            let adjacentIndices = getAdjacentIndices(for: index, rows: config.rows, columns: config.columns)
            
            if let swapIndex = adjacentIndices.randomElement() {
                scrambledGrid.swapAt(index, swapIndex)
            }
        }
        // Return the scrambled grid after the specified number of swaps.
        print("Grid Scrambled!") // Debugging
        return scrambledGrid
    }
    
    // Returns a list of indices that are adjacent to the given index in a grid.
    private func getAdjacentIndices(for index: Int, rows: Int, columns: Int) -> [Int] {
        // Initialise an empty array to hold the indices of adjacent cells.
        var adjacent: [Int] = []
        // Calculate the row and column of the given index.
        let row = index / columns
        let col = index % columns
        
        // Check left neighbour
        if col > 0 {
            adjacent.append(index - 1)
        }
        // Check right neighbour
        if col < columns - 1 {
            adjacent.append(index + 1)
        }
        // Check top neighbour
        if row > 0 {
            adjacent.append(index - columns)
        }
        // Check bottom neighbour
        if row < rows - 1 {
            adjacent.append(index + columns)
        }
        
        return adjacent
    }
    
    // Handles the tapping of a cell and manages interactions based on whether it’s a given or user grid.
    private func cellTapped(_ index: Int, isGivenGrid: Bool) {
        // Stop given cells initial sequence if it's playing
        if isPlayingIntro {
            isPlayingIntro = false
            playingAudioCell = nil
            return
        }
        if isGivenGrid {
            playAudio(for: index, grid: givenGrid)
            playingAudioCell = index
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                playingAudioCell = nil
            }
        } else {
            if let selected = selectedCell {
                if selected == index {
                    // Deselect the same cell
                    selectedCell = nil
                } else {
                    // Play audio for the second cell
                    playAudio(for: index, grid: userGrid)
                    
                    if areAdjacent(selected, index) {
                        // Show green shadow for both cells
                        swappingCells = [selected, index]
                        
                        // Disable interaction during animation
                        interactionDisabled = true
                        
                        // After 1 second, swap cells and reset
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            withAnimation {
                                swapCells(selected, index)
                                swappingCells = []
                                selectedCell = nil
                                interactionDisabled = false
                                checkForMatch()
                            }
                        }
                    } else {
                        // Show red shadow for invalid swap
                        invalidSwapCells = [selected, index]
                        vibratingCells = [selected, index]
                        
                        // Add vibration animation
                        withAnimation(.linear(duration: 0.1).repeatCount(3)) {
                            cellOffsets[selected] = CGPoint(x: -5, y: 0)
                            cellOffsets[index] = CGPoint(x: -5, y: 0)
                        }
                        
                        // Reset after animation
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            withAnimation(.linear(duration: 0.1)) {
                                cellOffsets[selected] = .zero
                                cellOffsets[index] = .zero
                            }
                            vibratingCells = []
                            invalidSwapCells = []
                            selectedCell = nil
                        }
                    }
                }
            } else {
                // First cell selection
                selectedCell = index
                playAudio(for: index, grid: userGrid)
            }
        }
    }
    
    // Checks if two indices in the grid are adjacent to each other (in the same row/column)
    private func areAdjacent(_ index1: Int, _ index2: Int) -> Bool {
        // Retrieve the layout configuration for the current level.
        // If the configuration cannot be found, return false since adjacency cannot be determined.
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) else {
            return false
        }
        
        // Get the list of indices adjacent to index1 in the grid, based on the layout configuration.
        let adjacentIndices = getAdjacentIndices(for: index1, rows: config.rows, columns: config.columns)
        // Return true if index2 is found in the list of adjacent indices, otherwise return false.
        return adjacentIndices.contains(index2)
    }
    
    private func swapCells(_ index1: Int, _ index2: Int) {
        let (offset1, offset2) = calculateSwapOffset(from: index1, to: index2)
        
        withAnimation(.easeInOut(duration: 0.5)) {
            cellOffsets[index1] = offset1
            cellOffsets[index2] = offset2
        }
        
        // Wait for the animation to complete before swapping data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            // Swap the data
            userGrid.swapAt(index1, index2)
            cellColors.swapAt(index1, index2)
            
            // Reset offsets immediately without animation
            cellOffsets[index1] = .zero
            cellOffsets[index2] = .zero
            
            checkForMatch()
        }
    }
    
    // Checks if the user's grid matches the given grid and updates completion state accordingly.
    private func checkForMatch() {
        if givenGrid == userGrid {
            isComplete = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                gameComplete = true
            }
        }
    }
    
    // Finds the optimal swap between two items in the user grid that minimizes the number of mismatches
    // with the given grid. The function returns the indices of the two items to swap, or nil if no optimal swap is found.
    private func findOptimalSwap() -> (Int, Int)? {
        // Retrieve the layout configuration for the current level (e.g., grid dimensions).
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) else {
            // If the layout configuration is not available, return nil as no swap can be found.
            return nil
        }
        
        // Iterate over each item in the user grid to compare with the given grid.
        for (index, currentAudio) in userGrid.enumerated() {
            // If the current item in the user grid does not match the given grid, we need to consider swapping.
            if currentAudio != givenGrid[index] {
                // Get the indices of adjacent items to the current index in the grid.
                let adjacentIndices = getAdjacentIndices(for: index, rows: config.rows, columns: config.columns)
                
                // Iterate over the adjacent indices to check if swapping improves the mismatch count.
                for adjIndex in adjacentIndices {
                    // Create a temporary grid and swap the items at the current index and the adjacent index.
                    var tempGrid = userGrid
                    tempGrid.swapAt(index, adjIndex)
                    
                    // Count the number of mismatches in the current user grid compared to the given grid.
                    let currentMismatches = zip(userGrid, givenGrid).filter { $0 != $1 }.count
                    
                    // Count the number of mismatches in the temporary grid after the swap.
                    let newMismatches = zip(tempGrid, givenGrid).filter { $0 != $1 }.count
                    
                    // If the swap results in fewer mismatches, return the indices of the two swapped items.
                    if newMismatches < currentMismatches {
                        return (index, adjIndex)
                    }
                }
            }
        }
        
        // If no optimal swap is found, return nil.
        return nil
    }
    
    
    // Handles providing a hint to the user
    private func giveHint() {
        guard UserProgressManager.shared.totalTokens >= GameDataManager.shared.hintCost else {
            showMoreTokensAlert = true
            return
        }
        
        UserProgressManager.shared.deductCash(amount: GameDataManager.shared.hintCost)
        UserProgressManager.shared.saveGameData()
        
        // Find misplaced cells and their optimal swaps and make a swap.
        if let (index1, index2) = findOptimalSwap() {
            swapCells(index1, index2)
            checkForMatch()
        }
    }
    
    // Skips to the next level if the user has enough tokens and they're not at the maximum level of the current (selected) game mode. If the player doesn't have enough tokens, it shows an alert.
    private func skipToNextLevel() {
        AudioManager.shared.stopAudio() // Stop any currently playing audio
        isPlayingIntro = false // Stop the intro sequence
        guard UserProgressManager.shared.totalTokens >= GameDataManager.shared.hintCost else {
            showMoreTokensAlert = true
            return
        }
        
        let nextLevel = selectedLevelIndex + 1
        guard let gameProperties = GameDataManager.shared.getGameProperties(for: .sonicSync) else {
            print("Error: Could not retrieve game properties for Sonic Swap.")
            return
        }
        
        if nextLevel >= gameProperties.levelCount {
            print("Skip action: All levels complete. Returning to level menu.")
            UserProgressManager.shared.updateGameProgress(
                gameKey: .sonicSync,
                modeKey: selectedModeKey,
                maxLevelIndex: selectedLevelIndex // Store the completed level
            )
            UserProgressManager.shared.saveGameData()
            currentView = .level
        } else {
            print("Skip action: Advancing to next level.")
            UserProgressManager.shared.deductCash(amount: GameDataManager.shared.skipLevelCost)
            UserProgressManager.shared.updateGameProgress(
                gameKey: .sonicSync,
                modeKey: selectedModeKey,
                maxLevelIndex: selectedLevelIndex // Store the completed level
            )
            UserProgressManager.shared.saveGameData()
            selectedLevelIndex = nextLevel
            withAnimation{
                resetGame()
                setupGame()
            }
        }
    }
    
    // Handles resetting the game, disabling interaction during reset
    private func resetGame() {
        AudioManager.shared.stopAudio() // Stop any currently playing audio
        isPlayingIntro = false // Stop the intro sequence
        selectedCell = nil
        playingAudioCell = nil
        isComplete = false
        initialiseAudio()
        initialiseCellColors()
    }
    
    // Plays the audio for the given index in the provided grid of audio file names.
    private func playAudio(for index: Int, grid: [String]) {
        guard index < grid.count else { return }
        AudioManager.shared.loadAudio(grid[index])
        AudioManager.shared.playAudio()
    }
    
    // MARK: - View Helper Methods
    
    // Returns the shadow for a cell (glow effect)
    private func getCellShadow(for index: Int, isGivenGrid: Bool) -> Color {
        if isComplete {
            return isGivenGrid ? .clear : .green // Green for user grid on completion
        } else if swappingCells.contains(index) {
            return isGivenGrid ? .clear : .white // White for both swapping cells
        
        } else if !isGivenGrid, let selected = selectedCell, selected == index {
            return .white // White for selected user grid cell
        }
        return .clear
    }
    
    // Returns the colour for a cell
    private func getCellColor(for index: Int) -> Color {
        guard index < cellColors.count else { return .gray }
        return cellColors[index]
    }
    
    
    
    // Calculates the offset needed to swap two items in the grid, given their indexes.
    // The function returns two CGPoint values: one for each item, representing the movement offsets for the swap.
    private func calculateSwapOffset(from index1: Int, to index2: Int) -> (CGPoint, CGPoint) {
        guard let config = GameDataManager.shared.getSonicSyncLayoutConfiguration(for: selectedLevelIndex) else {
            return (.zero, .zero)
        }
        // Calculate the row and column for the first index based on the configuration.
        let row1 = index1 / config.columns
        let col1 = index1 % config.columns
        let row2 = index2 / config.columns
        let col2 = index2 % config.columns
        
        // Calculate the horizontal (x) offset between the two items, factoring in the width and spacing.
        let xDiff = CGFloat((col2 - col1) * (config.cellWidth + config.cellSpacing))
        // Calculate the vertical (y) offset between the two items, factoring in the height and spacing.
        let yDiff = CGFloat((row2 - row1) * (config.cellHeight + config.cellSpacing))
        // Return a tuple of CGPoints representing the movement(offset) for both items involved in the swap.
        return (CGPoint(x: xDiff, y: yDiff), CGPoint(x: -xDiff, y: -yDiff))
    }
    
    // Creates the view for each cell in the grid, determining its colour, shape, and interactivity based on the selected game mode.
    private func cellView(for index: Int, isGivenGrid: Bool, config: (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int, scrambleSteps: Int)) -> some View {
        let maxWidth = CGFloat(config.cellWidth)
        let maxHeight = CGFloat(config.cellHeight)
        let availableColors = ColorManager.shared.getAllCustomColors()
        let cellColor = selectedModeKey == .recolor ? (availableColors.randomElement()?.value ?? .gray) : staticRandomColor
        
        return Group {
            switch selectedModeKey {
            case .classic:
                RoundedRectangle(cornerRadius: 10)
                    .fill(cellColor)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: isGivenGrid ? 6.2 : 4.4)
                            .padding(-2)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.black, lineWidth: isGivenGrid ? 5.2 : 4)
                    )
                
            case .shapes:
                let shape = shapesView(for: index)
                shape
                    .fill(cellColor)
                
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: isGivenGrid ? 6.2 : 4.4)
                            .padding(-2)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, lineWidth: isGivenGrid ? 5.2 : 4)
                    )
                    .modifier(ShapeModifier())
                
            case .recolor:
                let shape = shapesView(for: index)
                shape
                    .modifier(RecolorModifier(colors: availableColors.map { $0.value }, index: index))
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: isGivenGrid ? 6.2 : 4.4)
                            .padding(-2)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, lineWidth: isGivenGrid ? 5.2 : 4)
                    )
                
            default: EmptyView()
                
            }
        }
        .frame(width: CGFloat(config.cellWidth), height: CGFloat(config.cellHeight))
        .shadow(color: getCellShadow(for: index, isGivenGrid: isGivenGrid), radius: 20)
        .offset(x: !isGivenGrid ? cellOffsets[index].x : 0, y: !isGivenGrid ? cellOffsets[index].y : 0)
        .onTapGesture { cellTapped(index, isGivenGrid: isGivenGrid) }
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
    
    // MARK: - View Modifiers
    protocol CellModifier: ViewModifier {}
    
    
    
    struct NoEffect: CellModifier {
        func body(content: Content) -> some View {
            content
        }
    }
    
    // Modifier to change the colour of cells periodically.
    struct RecolorModifier: CellModifier {
        let colors: [Color]
        let index: Int  // Add this
        @State private var currentColorIndex: Int
        @State private var timer: Timer?
        
        init(colors: [Color], index: Int) {  // Modified initializer
            self.colors = colors
            self.index = index
            self._currentColorIndex = State(initialValue: Int.random(in: 0..<colors.count))  // Random start
        }
        
        func body(content: Content) -> some View {
            content
                .foregroundColor(colors[currentColorIndex])
                .onAppear { timer = Timer.scheduledTimer(withTimeInterval: Double.random(in: 2.0...3.0), repeats: true) { _ in
                    withAnimation {
                        currentColorIndex = (currentColorIndex + 1) % colors.count
                    }
                }
                }
                .onDisappear {
                    timer?.invalidate()
                    timer = nil
                }
            
        }
        
    }
    
    // Modifier to change the shape of a cell periodically.
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
    
    // Modifier to change the size of a cell periodically
    struct ResizeModifier: ViewModifier {
        let index: Int
        @State private var scale: CGFloat = 1.0
        @State private var timer: Timer? // Add a timer property
        func body(content: Content) -> some View {
            content
                .scaleEffect(scale)
                .onAppear {
                    timer = Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                        if Double.random(in: 0...1) < 0.2 { // 20% chance for each cell
                            withAnimation(.easeInOut(duration: 0.8)) {
                                scale = CGFloat.random(in: 0.6...1.4)
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
    
    // Modifier to rotate a cell based on its position in the grid.
    struct RotationModifier: ViewModifier {
        let index: Int
        @State private var angle: Double = 0
        @State private var timer: Timer?
        
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
}

// MARK: - Preview

// Preview Provider for SonicSwap View
struct SonicSync_Previews: PreviewProvider {
    static var previews: some View {
        SonicSyncView(
            currentView: .constant(.game(.sonicSync)),     // Binding to the current view, set to `.sonicSwap`
            previousView: .constant(.level),        // Binding to the previous view, set to `.select` for the preview
            showMoreTokensAlert: .constant(false),     // Binding to the "More Cash" alert, initially false
            showWinsAlert: .constant(false),         // Binding to the "Wins" alert, initially false
            selectedLevelIndex: .constant(25),        // Binding to the selected level index
            selectedModeKey: .recolor              // The selected game mode for the preview
            
        )
    }
}


