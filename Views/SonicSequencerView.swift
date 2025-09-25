import SwiftUI

// This view manages the Sonic Sequencer game, allowing users to interact with a grid of cells,
// input sequences, and compare them against a computer-generated sequence.
struct SonicSequencerView: View {
    
    // MARK: - Properties
    
    // Bindings for view state and alerts
    @Binding var currentView: ViewState
    @Binding var previousView: ViewState
    @Binding var showMoreTokensAlert: Bool
    @Binding var showWinsAlert: Bool
    @Binding var selectedLevelIndex: Int
    
    // State variable to control the display of level end view
    @State private var gameComplete: Bool = false
    
    // Game configuration properties
    let selectedModeKey: GameDataManager.GameModeKey
    
    // Observes the shared instance of UserPreferencesManager to react to changes in the current audio theme.
    @ObservedObject private var userPreferences = UserPreferencesManager.shared
    private var selectedThemeKey: AudioThemeManager.AudioThemeKey { // Computed property
        userPreferences.currentAudioTheme!
    }
    private var statusText: String { // Status text that reflects who's turn it is
        if !countdownComplete {
            return ""
        }
        return isPlayingComputerSequence ? "COMPUTER'S TURN:" : "YOUR TURN:"
    }
    // States for game logic
    @State private var audioFiles: [String] = [] // Audio files for the level
    @State private var isCorrect = false // Is current tap correct
    @State private var incorrectTapDetected = false // Incorrect tap detected
    @State private var audioInitialised = false // Is audio initialized
    @State private var cellColors: [Color] = [] // Colors for the cells
    @State private var colorsInitialised = false // Are colors initialised
    @State private var currentCell: (row: Int, column: Int)? // Currently highlighted cell
    @State private var interactionDisabled = false // Is interaction disabled
    @State private var colorUpdateTrigger = false // Trigger to update cell colors
    @State private var computerSequence: [(row: Int, col: Int)] = [] // Computer generated sequence
    @State private var userSequence: [(row: Int, col: Int)] = [] // User input sequence
    @State private var isHintActive = false // Is hint active
    @State private var isPlayingComputerSequence = false // Is computer sequence playing
    @State private var randomShapeIndex: Int = Int.random(in: 0...9) // Random shape index
    @State private var staticRandomColor: Color = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .gray // Static random color
    @State private var staticPolygonSides: Int = Int.random(in: 3...8) // Static polygon sides
    @State private var hintCurrentIndex = 0 // Current index for hint
    @State private var isHintPlaying = false // Is hint playing
    @State private var incorrectCellIndex: Int? // Index of incorrect cell
    @State private var isMatch: Bool = false // Are the computer sequence and user sequence a match
    @State private var showCountdown = false // Controls the visibility of the pre-game countdown overlay
    @State private var countdownComplete = false // Tracks whether the countdown has completed and the game sequence can begin
    
    // MARK: - Body
    var body: some View {
        ZStack {
            Rectangle()
                .ignoresSafeArea()
                .frame(width: .infinity, height: .infinity)
                .foregroundStyle(Color(GameDataManager.shared.getGameProperties(for: .sonicSequencer)?.accentColor.opacity(0.95) ?? .white))
                .blur(radius:200)
            
            VStack {
                
                UpperPanelView(showMoreTokensAlert: $showMoreTokensAlert, showWinsAlert: $showWinsAlert)
                
                Spacer()
                
                Text(statusText)
                    .font(.custom("AcierBATText-Solid", size: 22))
                    .foregroundStyle(.black)
                    .padding(.bottom, 30)
                
                
                if let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) {
                    LazyVGrid(columns: Array(repeating: GridItem(.fixed(CGFloat(config.cellWidth)), spacing: CGFloat(config.cellSpacing)), count: config.columns), spacing: CGFloat(config.cellSpacing)) {
                        ForEach(Array(0..<config.rows * config.columns), id: \.self) { index in
                            cellView(for: index, config: (config.rows, config.columns, config.cellWidth, config.cellHeight, config.cellSpacing))
                        }
                    }
                    
                    .onChange(of: colorUpdateTrigger) { _ in
                        initialiseCellColors()
                    }
                    
                } else {
                    Text("Configuration not found.")
                        .foregroundColor(.red)
                }
                
                Spacer()
                
                LowerPanelView(currentView: $currentView, previousView: $previousView, resetAction: resetGame, hintAction: giveHint, skipAction: skipToNextLevel)
            }
            .frame(width: .infinity)
            .disabled(interactionDisabled && !isHintActive)
            
            if gameComplete {
                GameCompleteView(
                    isPresented: $gameComplete,
                    gameKey: .sonicSequencer,
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
                        if nextLevel < GameDataManager.shared.getGameProperties(for: .sonicSequencer)?.levelCount ?? 0 {
                            selectedLevelIndex = nextLevel
                            gameComplete = false
                            
                            setupGame()
                        } else {
                            currentView = .level
                        }
                    }
                )
            }
            if showCountdown {
                CountdownOverlay(isVisible: $showCountdown, levelIndex: selectedLevelIndex)
            }
        }
        .onTapGesture {
            if isHintActive {
                isHintActive = false
                isHintPlaying = false // Stop hint playback
                hintCurrentIndex = -1 // Reset index
            }
        }
        
        .onAppear {
            setupGame()
            // Only generate and output sequence once on initial appear
        }
        .onChange(of: showCountdown) { isVisible in
            if !isVisible {
                interactionDisabled = false
                countdownComplete = true
                isPlayingComputerSequence = true
                
                // Clear existing sequences
                computerSequence = []
                userSequence = []
                
                // Generate new sequence with delay
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    generateComputerSequence()
                    
                    // Play sequence after generation
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        outputComputerSequence()
                    }
                }
            }
        }
        .onDisappear {
            AudioManager.shared.stopAudio() // Stop any currently playing audio
            isPlayingComputerSequence = false // Stop the computer sequence if it is currently playing
        }
        
    }
    
    // MARK: - Setup and Initialisation Methods
    // Sets up the game properties, validates the selected level and mode,
    // and initialises audio and colour settings if not already done.
    private func setupGame() {
        guard let gameProperties = GameDataManager.shared.getGameProperties(for: .sonicSequencer) else {
            print("Error: Game properties not found for Sonic Sequencer.")
            currentView = previousView
            return
        }
        
        // Validate the selected game mode
        let availableModes = Array(gameProperties.modes)
        guard availableModes.contains(selectedModeKey) else {
            print("Error: Selected mode (\(selectedModeKey)) is not available.")
            currentView = previousView
            return
        }
        
        // Validate the selected level index
        guard selectedLevelIndex >= 0 && selectedLevelIndex <= gameProperties.levelCount else {
            print("Error: Invalid level selected (\(selectedLevelIndex)).")
            currentView = previousView
            return
        }
        
        // Validate and get the layout configuration for the selected level
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else {
            print("Error: Layout configuration not found for level \(selectedLevelIndex).")
            currentView = previousView
            return
        }
        
        interactionDisabled = true  // Ensure interaction is disabled at start
        // Reset game state
        computerSequence = []
        userSequence = []
        audioInitialised = false
        colorsInitialised = false
        isPlayingComputerSequence = false
        randomShapeIndex = Int.random(in: 0...9)
        staticRandomColor = ColorManager.shared.getAllCustomColors().randomElement()?.value ?? .gray
        staticPolygonSides = Int.random(in: 3...8)
        
        // Initialise the audio and colours if not already done
        if !audioInitialised {
            initialiseCellAudio()
            audioInitialised = true
        }
        if !colorsInitialised {
            initialiseCellColors()
            colorsInitialised = true
        }
        showCountdown = true        // Show countdown
    }
    
    // Initialises the audio for each cell by selecting a shuffled set of audio files
    // based on the layout configuration of the selected level.
    private func initialiseCellAudio() {
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else { return }
        
        guard let availableAudioFiles = AudioThemeManager.shared.getThemedAudioFiles(forKey: selectedThemeKey) else {
            print("Error: No audio files found for theme key \(selectedThemeKey).")
            return
        }
        
        // Shuffle the audio files and select the required number based on grid size
        let shuffledAudioFiles = availableAudioFiles.shuffled()
        audioFiles = Array(shuffledAudioFiles.prefix(config.rows * config.columns))
    }
    
    // Initialises the colours for each cell based on the available colours for the theme
    private func initialiseCellColors() {
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else { return }
        let availableColors = ColorManager.shared.getAllCustomColors()
        let totalCells = config.rows * config.columns
        
        cellColors = (0..<totalCells).map { _ in
            availableColors.randomElement()?.value ?? .gray
        }
    }
    
    // MARK: - Game Logic Methods
    // Generates a random sequence for the computer to follow, consisting of
    // randomly selected cells (row, column) from the grid.
    private func generateComputerSequence() {
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else { return }
        
        computerSequence = []
        for _ in 0..<config.sequenceLength {
            let randomRow = Int.random(in: 0..<config.rows)
            let randomCol = Int.random(in: 0..<config.columns)
            computerSequence.append((row: randomRow, col: randomCol))
        }
        
        print("Computer sequence generated")
    }
    
    // Outputs the computer's sequence by highlighting the cells and playing their audio
    // with a delay between each, allowing the user to visually track the sequence.
    private func outputComputerSequence() {
        
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else { return }
        interactionDisabled = true
        userSequence = []
        isPlayingComputerSequence = true
        // Iterate over each element in the computer's sequence and display it with a delay
        for (index, position) in                    computerSequence.enumerated() {
            let delay = Double(index) * config.sequenceDelay
            DispatchQueue.main.asyncAfter(deadline: .now() + delay) {
                if isPlayingComputerSequence {
                    let cellIndex = position.row * config.columns + position.col
           playCellAudio(cellIndex)
      currentCell = (row: position.row, column: position.col)
    
    // Remove the highlight and re-enable interaction after the sequence finishes
      DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
      if index == computerSequence.count - 1 {
        currentCell = nil
           interactionDisabled = false
           isPlayingComputerSequence = false
                            }
          }
                }
            }
        }
    }


    // Handles the tapping of a cell, adding it to the user's sequence and checking for a match
    private func cellTapped(index: Int) {
        guard !interactionDisabled else { return }
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else { return }
        
        let row = index / config.columns
        let col = index % config.columns
        
        if userSequence.count < computerSequence.count {
            if (row, col) == computerSequence[userSequence.count] {
                // Correct input
                userSequence.append((row: row, col: col))
                playCellAudio(index)
                currentCell = (row: row, column: col)
                isCorrect = true
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    currentCell = nil
                    isCorrect = false
                }
                
                if userSequence.count == computerSequence.count {
                    checkForMatch()
                }
            } else {
                // Incorrect input
                isCorrect = false
                incorrectCellIndex = index
                incorrectTapDetected = true // Trigger level restart
                handleIncorrectInput()
            }
        }
    }
    
    // Handles an incorrect user input
    private func handleIncorrectInput() {
        interactionDisabled = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            incorrectCellIndex = nil
            interactionDisabled = false
            incorrectTapDetected = false // Reset the trigger
            resetGame() // Restart the level
        }
    }
    
    // Compares the user's sequence against the computer's sequence to check for a match.
    private func checkForMatch() {
        print("checkForMatch called") // Debug statement
        guard !interactionDisabled else { return }
        interactionDisabled = true
        
        // Check if each element in the user's sequence matches the corresponding element in the computer's sequence
        isMatch = zip(userSequence, computerSequence).allSatisfy { user, computer in
            user.row == computer.row && user.col == computer.col
        }
        print("isMatch: \(isMatch)") // Debug statement
        if isMatch {
            print("Check for match: Match succesfful and game complete") // Debug
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.75) {
                gameComplete = true
                interactionDisabled = false
            }
        } else {
            print("Check for match: Match unsuccesful. Starting level again")  // Debug
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.5) {
                
                resetGame()
            }
        }
    }
    
    // Provides a hint to the player by highlighting and playing the next cell the user needs to tap
    private func giveHint() {
        
        AudioManager.shared.stopAudio()
        isPlayingComputerSequence = false
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else { return }
        guard UserProgressManager.shared.totalTokens >= GameDataManager.shared.hintCost else {
            showMoreTokensAlert = true
            return
        }
        
        UserProgressManager.shared.deductCash(amount: GameDataManager.shared.hintCost)
        UserProgressManager.shared.saveGameData()
        
        isHintActive = true
        isHintPlaying = true
        
        if userSequence.count < computerSequence.count {
            let nextCell = computerSequence[userSequence.count]
            let hintIndex = nextCell.row * config.columns + nextCell.col // Calculate index
            incorrectCellIndex = hintIndex // Use incorrectCellIndex for highlighting the hint
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { // Remove highlight after a delay
                incorrectCellIndex = nil
                isHintActive = false
                isHintPlaying = false
            }
            
        }
    }
    
    // Skips to the next level if the user has enough tokens and they're not at the maximum level of the current (selected) game mode. If the player doesn't have enough tokens, it shows an alert.
    private func skipToNextLevel() {
        AudioManager.shared.stopAudio()
        isPlayingComputerSequence = false
        guard UserProgressManager.shared.totalTokens >= GameDataManager.shared.hintCost else {
            showMoreTokensAlert = true
            return
        }
        
        let nextLevel = selectedLevelIndex + 1
        guard let gameProperties = GameDataManager.shared.getGameProperties(for: .sonicSequencer) else {
            print("Error: Could not retrieve game properties for Sonic Sequencer.")
            return
        }
        
        if nextLevel >= gameProperties.levelCount {
            print("Skip action: All levels complete. Returning to select menu.")
            UserProgressManager.shared.updateGameProgress(
                gameKey: .sonicSequencer,
                modeKey: selectedModeKey,
                maxLevelIndex: selectedLevelIndex // Store the completed level
            )
            UserProgressManager.shared.saveGameData()
            currentView = .level
        } else {
            print("Skip action: Advancing to next level.")
            UserProgressManager.shared.deductCash(amount: GameDataManager.shared.skipLevelCost)
            UserProgressManager.shared.updateGameProgress(
                gameKey: .sonicSequencer,
                modeKey: selectedModeKey,
                maxLevelIndex: selectedLevelIndex // Store the completed level
            )
            UserProgressManager.shared.saveGameData()
            selectedLevelIndex = nextLevel
            
            setupGame()
        }
    }
    
    // Resets the game to its initial state, clearing sequences and disabling interaction.
    private func resetGame() {
        isMatch = false
        incorrectCellIndex = nil
        incorrectTapDetected = false
        gameComplete = false
        interactionDisabled = false
        isCorrect = false // Reset isCorrect
        userSequence = [] // Clear user sequence
        computerSequence = [] // Clear computer sequence
        
        // Stop any playing audio
        AudioManager.shared.stopAudio()
        
        // Reinitialize game components
        initialiseCellColors()
        
        initialiseCellColors()
        initialiseCellAudio()
        // Start fresh sequence
        
        showCountdown = true
        
    }
    
    // Plays the audio for the specified cell index based on the current layout configuration.
    private func playCellAudio(_ index: Int) {
        guard index < audioFiles.count else { return }
        AudioManager.shared.loadAudio(audioFiles[index])
        AudioManager.shared.playAudio()
    }
    
    // MARK: - View Helper Methods
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
    
    // Returns the colour for a cell
    private func getCellColor(for index: Int) -> Color {
        guard index < cellColors.count else { return .gray }
        return cellColors[index]
    }
    
    // Returns the shadow colour for a cell (glow effect)
    private func getCellShadow(for index: Int) -> Color {
        guard let config = GameDataManager.shared.getSonicSequencerLayoutConfiguration(for: selectedLevelIndex) else { return .clear }
        
        if incorrectTapDetected && incorrectCellIndex == index {
            return .red // Incorrect tap
        } else if isCorrect && index == (userSequence.last?.row ?? 0) * config.columns + (userSequence.last?.col ?? 0) {
            return .green // Correct tap
        } else if isHintPlaying && index == hintCurrentIndex {
            return .white // Hint
        } else if isPlayingComputerSequence, let current = currentCell, index == current.row * config.columns + current.column {
            return .white // Currently playing cell (computer sequence)
        }
        return .clear
    }
    
    
    
    
    // Creates the view for each cell in the grid, determining its colour, shape, and interactivity based on the selected game mode.
    private func cellView(for index: Int, config: (rows: Int, columns: Int, cellWidth: Int, cellHeight: Int, cellSpacing: Int)) -> some View {
        let minDimension = min(CGFloat(config.cellWidth), CGFloat(config.cellHeight)) * 0.8
        let maxWidth = CGFloat(config.cellWidth)
        let maxHeight = CGFloat(config.cellHeight)
        let availableColors = ColorManager.shared.getAllCustomColors()
        let cellColor = selectedModeKey == .recolor ? (availableColors.randomElement()?.value ?? .gray) : staticRandomColor
        
        return Group {
            switch selectedModeKey {
            case .classic:
                RoundedRectangle(cornerRadius: 10)
                    .fill(cellColor)
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2)
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
                            .padding(-2)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, lineWidth: 4)
                    )
                    .modifier(ShapeModifier())
            case .recolor:
                let shape = shapesView(for: index)
                shape
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, lineWidth: 4)
                    )
                    .modifier(ShapeModifier())
                    .modifier(RecolorModifier(colors: cellColors))
                
            case .rotate:
                let shape = shapesView(for: index)
                shape
                    .frame(width: maxWidth, height: maxHeight)
                    .overlay(
                        shape
                            .stroke(Color.white, lineWidth: 6)
                            .padding(-2)
                    )
                    .overlay(
                        shape
                            .stroke(Color.black, style: StrokeStyle(lineWidth: 4, dash: [100, 2]))
                    )
                    .modifier(ShapeModifier())
                    .modifier(RecolorModifier(colors: cellColors))
                    .modifier(RotationModifier(index: index))
            default:
                EmptyView()
            }
        }
        .frame(width: CGFloat(config.cellWidth), height: CGFloat(config.cellHeight))
        .shadow(color: getCellShadow(for: index), radius: 15)
        .onTapGesture { cellTapped(index: index) }
    }
}

// MARK: - View Modifiers

// Displays a countdown overlay with tutorial messages for early levels
struct CountdownOverlay: View {
    @Binding var isVisible: Bool
    let levelIndex: Int
    @State private var counter = 3
    
    var body: some View {
        ZStack {
            Color(.white.opacity(0.8))
                .ignoresSafeArea()
            ZStack{
                Rectangle()
                    .fill(.white)
                    .frame(maxWidth: .infinity, maxHeight:180)
                    .blur(radius: 5)
                    .opacity(0.9)
                
                VStack(spacing: 20) {
                    if levelIndex < 5 {
                        Text("GET READY!")
                            .font(.custom("AcierBATText-Solid", size: 28)).foregroundStyle(.black)
                            .foregroundColor(.black)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    ZStack{
                        Text("\(counter)")
                            .font(.custom("AcierBATText-Solid", size: 40)).foregroundStyle(.black)
                            .foregroundColor(.white)
                        
                        Text("\(counter)")
                            .font(.custom("AcierBATText-Solid", size: 45)).foregroundStyle(.black)
                            .foregroundColor(.black)
                        
                    }
                }
            }
        }
        .onAppear {
            startCountdown()
        }
    }
    
    private func startCountdown() {
        Timer.scheduledTimer(withTimeInterval: 1.2, repeats: true) { timer in
            if counter > 1 {
                counter -= 1
            } else {
                timer.invalidate()
                isVisible = false
            }
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

// Modifier to change the colour of a cell periodically
struct RecolorModifier: ViewModifier {
    let colors: [Color]
    @State private var currentColorIndex = 0
    @State private var timer: Timer?
    
    func body(content: Content) -> some View {
        content
            .foregroundColor(colors.isEmpty ? .gray : colors[currentColorIndex % colors.count])
            .onAppear {
                guard !colors.isEmpty else { return }
                timer = Timer.scheduledTimer(withTimeInterval: 2.0, repeats: true) { _ in
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

// Modifier to rotate a cell
struct RotationModifier: ViewModifier {
    let index: Int
    @State private var angle: Double = 0
    @State private var timer: Timer? // Add timer property
    
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


// MARK: - Preview Provider
// Preview provider for SonicSequencer View
struct SonicSequencer_Previews: PreviewProvider {
    
    static var previews: some View {
        
        SonicSequencerView(
            currentView: .constant(.game(.sonicSequencer)),     // Binding to the current view, set to `.sonicSequencer`
            previousView: .constant(.level),            // Binding to the previous view, set to `.select` for the preview
            showMoreTokensAlert: .constant(false),         // Binding to the "More Cash" alert, initially false
            showWinsAlert: .constant(false),             // Binding to the "Wins" alert, initially false
            selectedLevelIndex: .constant(25),            // Binding to the selected level index
            selectedModeKey: .rotate
             
        ).onAppear{
            UserProgressManager.shared.awardCash(amount: 30)
        }
    }
}

