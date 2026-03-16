import SwiftUI
import SpriteKit

enum AIDifficulty: String, CaseIterable {
    case easy
    case normal
    case hard

    var displayName: String {
        switch self {
        case .easy: return "Easy"
        case .normal: return "Normal"
        case .hard: return "Hard"
        }
    }

    var description: String {
        switch self {
        case .easy: return "Slower AI, late attacks"
        case .normal: return "Balanced challenge"
        case .hard: return "Fast AI, early aggression"
        }
    }
}

struct ContentView: View {
    @State private var showGame = false
    @State private var selectedCiv: Civilization = .britons
    @State private var selectedDifficulty: AIDifficulty = .normal
    @State private var selectedMapType: MapType = .standard
    @State private var selectedMapSize: MapSize = .medium

    var body: some View {
        if showGame {
            GameContainerView(civilization: selectedCiv, difficulty: selectedDifficulty, mapType: selectedMapType, mapSize: selectedMapSize, onExit: {
                showGame = false
            })
            .ignoresSafeArea()
        } else {
            MainMenuView(selectedCiv: $selectedCiv, selectedDifficulty: $selectedDifficulty, selectedMapType: $selectedMapType, selectedMapSize: $selectedMapSize, onStart: {
                showGame = true
            })
        }
    }
}

struct MainMenuView: View {
    @Binding var selectedCiv: Civilization
    @Binding var selectedDifficulty: AIDifficulty
    @Binding var selectedMapType: MapType
    @Binding var selectedMapSize: MapSize
    let onStart: () -> Void

    var body: some View {
        ZStack {
            // Background
            LinearGradient(
                colors: [Color(red: 0.15, green: 0.1, blue: 0.05),
                         Color(red: 0.3, green: 0.2, blue: 0.1)],
                startPoint: .top, endPoint: .bottom
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 24) {
                    // Title
                    VStack(spacing: 8) {
                        Text("REALM OF")
                            .font(.system(size: 24, weight: .medium))
                            .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))
                            .tracking(8)

                        Text("EMPIRES")
                            .font(.system(size: 56, weight: .bold))
                            .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.35))
                            .shadow(color: .black, radius: 4, x: 2, y: 2)
                            .tracking(4)

                        Rectangle()
                            .fill(Color(red: 0.85, green: 0.7, blue: 0.4))
                            .frame(width: 200, height: 2)
                            .padding(.top, 4)
                    }
                    .padding(.top, 40)

                    // Civilization Selection
                    VStack(spacing: 16) {
                        Text("Choose Your Civilization")
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))

                        HStack(spacing: 20) {
                            ForEach(Civilization.allCases, id: \.self) { civ in
                                CivSelectionCard(civ: civ, isSelected: selectedCiv == civ)
                                    .onTapGesture { selectedCiv = civ }
                            }
                        }
                    }

                    // Difficulty Selection
                    VStack(spacing: 12) {
                        Text("Difficulty")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))

                        HStack(spacing: 16) {
                            ForEach(AIDifficulty.allCases, id: \.self) { diff in
                                DifficultyCard(difficulty: diff, isSelected: selectedDifficulty == diff)
                                    .onTapGesture { selectedDifficulty = diff }
                            }
                        }
                    }

                    // Map Type Selection
                    VStack(spacing: 12) {
                        Text("Map Type")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))

                        ScrollView(.horizontal, showsIndicators: false) {
                            HStack(spacing: 12) {
                                ForEach(MapType.allCases, id: \.self) { mapType in
                                    MapTypeCard(mapType: mapType, isSelected: selectedMapType == mapType)
                                        .onTapGesture { selectedMapType = mapType }
                                }
                            }
                            .padding(.horizontal, 16)
                        }
                    }

                    // Map Size Selection
                    VStack(spacing: 12) {
                        Text("Map Size")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))

                        HStack(spacing: 16) {
                            ForEach(MapSize.allCases, id: \.self) { size in
                                MapSizeCard(mapSize: size, isSelected: selectedMapSize == size)
                                    .onTapGesture { selectedMapSize = size }
                            }
                        }
                    }

                    // Start Button
                    Button(action: onStart) {
                        Text("START GAME")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(.white)
                            .tracking(3)
                            .padding(.horizontal, 60)
                            .padding(.vertical, 18)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(Color(red: 0.6, green: 0.15, blue: 0.1))
                                    .shadow(color: .black.opacity(0.5), radius: 4, x: 0, y: 3)
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(Color(red: 0.85, green: 0.7, blue: 0.4), lineWidth: 2)
                            )
                    }
                    .padding(.bottom, 60)
                }
            }
        }
    }
}

struct DifficultyCard: View {
    let difficulty: AIDifficulty
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(difficulty.displayName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(difficulty.description)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(width: 110)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                      ? Color(red: 0.4, green: 0.25, blue: 0.1)
                      : Color(red: 0.2, green: 0.15, blue: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected
                        ? Color(red: 0.85, green: 0.7, blue: 0.4)
                        : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct CivSelectionCard: View {
    let civ: Civilization
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 8) {
            Text(civ.icon)
                .font(.system(size: 40))

            Text(civ.displayName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(civ.bonus)
                .font(.system(size: 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(width: 120)
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 10)
                .fill(isSelected
                      ? Color(red: 0.4, green: 0.25, blue: 0.1)
                      : Color(red: 0.2, green: 0.15, blue: 0.08))
                .shadow(color: isSelected ? Color(red: 0.85, green: 0.7, blue: 0.4).opacity(0.3) : .clear, radius: 8)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 10)
                .stroke(isSelected
                        ? Color(red: 0.85, green: 0.7, blue: 0.4)
                        : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct MapTypeCard: View {
    let mapType: MapType
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 6) {
            Text(mapType.icon)
                .font(.system(size: 30))

            Text(mapType.displayName)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(.white)

            Text(mapType.description)
                .font(.system(size: 9))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(width: 100)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                      ? Color(red: 0.4, green: 0.25, blue: 0.1)
                      : Color(red: 0.2, green: 0.15, blue: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected
                        ? Color(red: 0.85, green: 0.7, blue: 0.4)
                        : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct MapSizeCard: View {
    let mapSize: MapSize
    let isSelected: Bool

    var body: some View {
        VStack(spacing: 4) {
            Text(mapSize.displayName)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(.white)

            Text(mapSize.description)
                .font(.system(size: 10))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(width: 110)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(isSelected
                      ? Color(red: 0.4, green: 0.25, blue: 0.1)
                      : Color(red: 0.2, green: 0.15, blue: 0.08))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(isSelected
                        ? Color(red: 0.85, green: 0.7, blue: 0.4)
                        : Color.gray.opacity(0.3), lineWidth: isSelected ? 2 : 1)
        )
    }
}

struct GameContainerView: View {
    let civilization: Civilization
    let difficulty: AIDifficulty
    let mapType: MapType
    let mapSize: MapSize
    let onExit: () -> Void
    @State private var scene: GameScene?
    @State private var loadingMessage: String = "Generating terrain..."
    @State private var loadingTimer: Timer?

    private let loadingMessages = [
        "Generating terrain...",
        "Placing resources...",
        "Deploying scouts...",
        "Preparing for battle..."
    ]

    var body: some View {
        ZStack {
            if let scene = scene {
                SpriteView(scene: scene, preferredFramesPerSecond: 60)
                    .ignoresSafeArea()
            } else {
                VStack(spacing: 16) {
                    Text("REALM OF EMPIRES")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.35))

                    Text(loadingMessage)
                        .font(.system(size: 14))
                        .foregroundColor(.gray)
                        .animation(.easeInOut(duration: 0.3), value: loadingMessage)

                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: Color(red: 0.85, green: 0.7, blue: 0.4)))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(Color(red: 0.15, green: 0.1, blue: 0.05))
                .ignoresSafeArea()
                .onAppear {
                    var messageIndex = 0
                    loadingTimer = Timer.scheduledTimer(withTimeInterval: 0.6, repeats: true) { timer in
                        messageIndex += 1
                        if messageIndex < loadingMessages.count {
                            loadingMessage = loadingMessages[messageIndex]
                        } else {
                            timer.invalidate()
                        }
                    }

                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                        let newScene = GameScene(size: UIScreen.main.bounds.size)
                        newScene.scaleMode = .resizeFill
                        newScene.playerCivilization = civilization
                        newScene.aiDifficulty = difficulty
                        newScene.mapType = mapType
                        newScene.mapSize = mapSize
                        newScene.onExit = onExit
                        self.loadingTimer?.invalidate()
                        self.scene = newScene
                    }
                }
            }
        }
    }
}
