import SwiftUI
import SpriteKit

struct ContentView: View {
    @State private var showGame = false
    @State private var selectedCiv: Civilization = .britons

    var body: some View {
        if showGame {
            GameContainerView(civilization: selectedCiv, onExit: {
                showGame = false
            })
            .ignoresSafeArea()
        } else {
            MainMenuView(selectedCiv: $selectedCiv, onStart: {
                showGame = true
            })
        }
    }
}

struct MainMenuView: View {
    @Binding var selectedCiv: Civilization
    let onStart: () -> Void

    var body: some View {
        GeometryReader { geo in
            let isCompact = geo.size.height < 500

            ZStack {
                // Background
                LinearGradient(
                    colors: [Color(red: 0.15, green: 0.1, blue: 0.05),
                             Color(red: 0.3, green: 0.2, blue: 0.1)],
                    startPoint: .top, endPoint: .bottom
                )
                .ignoresSafeArea()

                if isCompact {
                    // iPhone landscape: horizontal layout
                    HStack(spacing: 0) {
                        // Left side: title + start button
                        VStack(spacing: 12) {
                            Spacer()
                            VStack(spacing: 4) {
                                Text("REALM OF")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))
                                    .tracking(6)

                                Text("EMPIRES")
                                    .font(.system(size: 32, weight: .bold))
                                    .foregroundColor(Color(red: 0.9, green: 0.75, blue: 0.35))
                                    .shadow(color: .black, radius: 4, x: 2, y: 2)
                                    .tracking(3)

                                Rectangle()
                                    .fill(Color(red: 0.85, green: 0.7, blue: 0.4))
                                    .frame(width: 120, height: 2)
                                    .padding(.top, 2)
                            }

                            Spacer()

                            Button(action: onStart) {
                                Text("START GAME")
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(.white)
                                    .tracking(2)
                                    .padding(.horizontal, 30)
                                    .padding(.vertical, 12)
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
                            Spacer()
                        }
                        .frame(width: geo.size.width * 0.35)

                        // Right side: civ selection in 2x2 grid
                        VStack(spacing: 8) {
                            Text("Choose Your Civilization")
                                .font(.system(size: 14, weight: .semibold))
                                .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))
                                .padding(.top, 8)

                            let gridCivs = Civilization.allCases
                            VStack(spacing: 8) {
                                HStack(spacing: 8) {
                                    ForEach(gridCivs.prefix(2), id: \.self) { civ in
                                        CivSelectionCard(civ: civ, isSelected: selectedCiv == civ, compact: true)
                                            .onTapGesture { selectedCiv = civ }
                                    }
                                }
                                HStack(spacing: 8) {
                                    ForEach(gridCivs.suffix(2), id: \.self) { civ in
                                        CivSelectionCard(civ: civ, isSelected: selectedCiv == civ, compact: true)
                                            .onTapGesture { selectedCiv = civ }
                                    }
                                }
                            }
                            .padding(.bottom, 8)
                        }
                        .frame(width: geo.size.width * 0.65)
                    }
                } else {
                    // iPad: original vertical layout
                    VStack(spacing: 30) {
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

                        Spacer()

                        VStack(spacing: 16) {
                            Text("Choose Your Civilization")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundColor(Color(red: 0.85, green: 0.7, blue: 0.4))

                            HStack(spacing: 20) {
                                ForEach(Civilization.allCases, id: \.self) { civ in
                                    CivSelectionCard(civ: civ, isSelected: selectedCiv == civ, compact: false)
                                        .onTapGesture { selectedCiv = civ }
                                }
                            }
                        }

                        Spacer()

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
        .ignoresSafeArea()
    }
}

struct CivSelectionCard: View {
    let civ: Civilization
    let isSelected: Bool
    var compact: Bool = false

    var body: some View {
        VStack(spacing: compact ? 4 : 8) {
            Text(civ.icon)
                .font(.system(size: compact ? 24 : 40))

            Text(civ.displayName)
                .font(.system(size: compact ? 12 : 16, weight: .bold))
                .foregroundColor(.white)

            Text(civ.bonus)
                .font(.system(size: compact ? 8 : 11))
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .frame(width: compact ? 90 : 120)
        }
        .padding(compact ? 8 : 16)
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

struct GameContainerView: View {
    let civilization: Civilization
    let onExit: () -> Void
    @State private var scene: GameScene?

    var body: some View {
        GeometryReader { geometry in
            ZStack {
                if let scene = scene {
                    SpriteView(scene: scene)
                        .ignoresSafeArea()
                } else {
                    Color.black
                        .ignoresSafeArea()
                        .onAppear {
                            let sceneSize = geometry.size
                            let newScene = GameScene(size: sceneSize)
                            newScene.scaleMode = .resizeFill
                            newScene.playerCivilization = civilization
                            newScene.onExit = onExit
                            self.scene = newScene
                        }
                }
            }
        }
        .ignoresSafeArea()
    }
}
