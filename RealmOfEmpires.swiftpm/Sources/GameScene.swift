import SpriteKit
import UIKit

class GameScene: SKScene {

    // MARK: - Properties

    var playerCivilization: Civilization = .britons
    var aiDifficulty: AIDifficulty = .normal
    var onExit: (() -> Void)?

    // Game speed
    var gameSpeed: CGFloat = 1.0

    // Stats tracking
    var totalUnitsTrainedHuman: Int = 0
    var totalUnitsLostHuman: Int = 0
    var totalResourcesGathered: Resources = Resources()
    var gameStartTime: TimeInterval = 0

    // Game systems
    var gameMap: GameMap!
    var pathfinder: Pathfinder!
    var spriteFactory: SpriteFactory!
    var resourceSystem = ResourceSystem()
    var buildingSystem = BuildingSystem()
    var unitSystem = UnitSystem()
    var combatSystem = CombatSystem()
    var fogOfWar: FogOfWar!
    var techTree = TechTree()
    var hud: HUDOverlay!

    // Players
    var players: [Player] = []
    var humanPlayer: Player!
    var aiOpponents: [AIOpponent] = []

    // Camera
    var gameWorld: SKNode!
    var cameraPosition = CGPoint.zero
    var hudCamera: SKCameraNode!
    var zoomScale: CGFloat = 1.0
    let minZoom: CGFloat = 0.5
    let maxZoom: CGFloat = 2.0

    // Game state
    var gameState: GameState = .playing
    var gameTime: TimeInterval = 0
    var lastUpdateTime: TimeInterval = 0
    var actionMode: ActionMode = .normal
    var lastBuildingAttackTimes: [String: TimeInterval] = [:]

    // Selection
    var selectedBuilding: Building?
    var selectionStart: CGPoint?
    var selectionRect: SKShapeNode?
    var isBoxSelecting = false
    var touchStartedOnEmptyGround = false
    var touchHandledByHUD = false

    // Touch tracking
    var lastTouchPosition: CGPoint?
    var isPanning = false
    var panVelocity = CGPoint.zero
    var lastTouchMoveTime: TimeInterval = 0
    var touchStartTime: TimeInterval = 0
    var lastTapTime: TimeInterval = 0
    var lastTappedUnitType: UnitType?

    // Building placement
    var placementGhost: SKNode?
    var placementType: BuildingType?

    // Tile rendering timer
    var tileRenderTimer: CGFloat = 0
    var minimapTimer: CGFloat = 0

    // Idle villager cycling
    var lastIdleVillagerIndex: Int = 0

    // Tutorial
    var tutorialStep: Int = -1  // -1 means no tutorial
    var tutorialOverlay: SKNode?

    // MARK: - Scene Lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .black

        setupGameWorld()
        setupPlayers()
        setupCamera()
        setupHUD()
        setupGestures(view: view)

        // Link systems
        resourceSystem.gameScene = self
        buildingSystem.gameScene = self
        unitSystem.gameScene = self
        combatSystem.gameScene = self

        // Initial render
        renderTiles()

        // Start zoomed in on TC
        zoomScale = 1.5
        updateCamera()

        // Show tutorial for first-time players
        if !UserDefaults.standard.bool(forKey: "tutorialCompleted") {
            showTutorial(step: 0)
        }
    }

    // MARK: - Tutorial

    private func showTutorial(step: Int) {
        tutorialStep = step
        tutorialOverlay?.removeFromParent()

        let tips = [
            "Select villagers and send them to gather resources (berries, trees, gold, stone).",
            "Build a Barracks to train military units.",
            "Advance through Ages to unlock stronger units and technologies.",
            "Destroy the enemy Town Center to win!"
        ]

        guard step < tips.count else {
            // Tutorial complete
            tutorialStep = -1
            UserDefaults.standard.set(true, forKey: "tutorialCompleted")
            return
        }

        let overlay = SKNode()
        overlay.zPosition = 200
        overlay.name = "tutorialOverlay"

        // Background panel
        let bg = SKShapeNode(rectOf: CGSize(width: size.width * 0.7, height: 80), cornerRadius: 10)
        bg.fillColor = SKColor.black.withAlphaComponent(0.8)
        bg.strokeColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        bg.lineWidth = 2
        bg.position = CGPoint(x: 0, y: size.height * 0.3)
        overlay.addChild(bg)

        // Tip text
        let label = SKLabelNode(text: tips[step])
        label.fontSize = 14
        label.fontName = "Helvetica"
        label.fontColor = .white
        label.preferredMaxLayoutWidth = size.width * 0.6
        label.numberOfLines = 0
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: 0, y: size.height * 0.3 + 8)
        overlay.addChild(label)

        // Step indicator
        let stepLabel = SKLabelNode(text: "Tip \(step + 1)/\(tips.count)  —  Tap to continue")
        stepLabel.fontSize = 11
        stepLabel.fontName = "Helvetica"
        stepLabel.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        stepLabel.verticalAlignmentMode = .center
        stepLabel.horizontalAlignmentMode = .center
        stepLabel.position = CGPoint(x: 0, y: size.height * 0.3 - 22)
        overlay.addChild(stepLabel)

        // Skip button
        let skipBg = SKShapeNode(rectOf: CGSize(width: 90, height: 28), cornerRadius: 6)
        skipBg.fillColor = SKColor(red: 0.4, green: 0.15, blue: 0.1, alpha: 0.9)
        skipBg.strokeColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 0.6)
        skipBg.lineWidth = 1
        skipBg.position = CGPoint(x: size.width * 0.3, y: size.height * 0.3 - 22)
        skipBg.name = "skipTutorial"
        overlay.addChild(skipBg)

        let skipLabel = SKLabelNode(text: "Skip")
        skipLabel.fontSize = 12
        skipLabel.fontName = "Helvetica-Bold"
        skipLabel.fontColor = .white
        skipLabel.verticalAlignmentMode = .center
        skipLabel.horizontalAlignmentMode = .center
        skipLabel.position = CGPoint(x: size.width * 0.3, y: size.height * 0.3 - 22)
        skipLabel.name = "skipTutorialLabel"
        overlay.addChild(skipLabel)

        tutorialOverlay = overlay
        hudCamera.addChild(overlay)
    }

    private func setupGameWorld() {
        gameWorld = SKNode()
        gameWorld.name = "gameWorld"
        addChild(gameWorld)

        gameMap = GameMap(width: 80, height: 80, tileSize: 32)
        gameWorld.addChild(gameMap.mapNode)

        pathfinder = Pathfinder(map: gameMap)
        spriteFactory = SpriteFactory(tileSize: gameMap.tileSize)
        fogOfWar = FogOfWar(map: gameMap)
    }

    private func setupPlayers() {
        // Human player
        humanPlayer = Player(id: 0, civilization: playerCivilization, isHuman: true)
        players.append(humanPlayer)

        // AI opponent
        let aiCivs = Civilization.allCases.filter { $0 != playerCivilization }
        let aiCiv = aiCivs.randomElement() ?? .franks
        let aiPlayer = Player(id: 1, civilization: aiCiv, isHuman: false)
        players.append(aiPlayer)

        let ai = AIOpponent(player: aiPlayer, difficulty: aiDifficulty)
        ai.gameScene = self
        aiOpponents.append(ai)

        // Place starting positions
        let p1Start = GridPosition(x: 12, y: 12)
        let p2Start = GridPosition(x: gameMap.width - 15, y: gameMap.height - 15)

        gameMap.clearStartingArea(center: p1Start, radius: 8)
        gameMap.clearStartingArea(center: p2Start, radius: 8)

        spawnStartingUnits(player: humanPlayer, at: p1Start)
        spawnStartingUnits(player: aiPlayer, at: p2Start)

        // Center camera on player start
        cameraPosition = gameMap.gridToWorld(p1Start)
    }

    private func spawnStartingUnits(player: Player, at center: GridPosition) {
        // Town Center
        let tcPos = GridPosition(x: center.x - 1, y: center.y - 1)
        if let tc = buildingSystem.placeBuilding(type: .townCenter, at: tcPos,
                                                   player: player, map: gameMap,
                                                   spriteFactory: spriteFactory) {
            tc.isConstructed = true
            tc.hp = tc.maxHP
            tc.constructionProgress = 1.0
            gameWorld.addChild(tc.node!)
            spriteFactory.updateBuildingNode(tc)
        }

        // Starting villagers
        let villagerPositions = [
            GridPosition(x: center.x - 2, y: center.y + 3),
            GridPosition(x: center.x, y: center.y + 3),
            GridPosition(x: center.x + 2, y: center.y + 3),
        ]

        for pos in villagerPositions {
            let unit = Unit(type: .villager, ownerID: player.id, position: pos)
            unit.ownerPlayer = player
            unit.gridPosition = pos
            unit.position = gameMap.gridToWorld(pos)

            let node = spriteFactory.createUnitNode(unit: unit)
            node.position = unit.position
            unit.node = node

            player.units.append(unit)
            gameWorld.addChild(node)
        }

        // Scout
        let scoutPos = GridPosition(x: center.x + 3, y: center.y)
        let scout = Unit(type: .scout, ownerID: player.id, position: scoutPos)
        scout.ownerPlayer = player
        scout.gridPosition = scoutPos
        scout.position = gameMap.gridToWorld(scoutPos)

        let scoutNode = spriteFactory.createUnitNode(unit: scout)
        scoutNode.position = scout.position
        scout.node = scoutNode

        player.units.append(scout)
        gameWorld.addChild(scoutNode)
    }

    private func setupCamera() {
        hudCamera = SKCameraNode()
        camera = hudCamera
        addChild(hudCamera)
    }

    private func setupHUD() {
        hud = HUDOverlay(viewSize: size)
        hud.gameScene = self
        hudCamera.addChild(hud.hudNode)

        // Offset HUD so it's positioned relative to screen
        hud.hudNode.position = CGPoint(x: -size.width / 2, y: -size.height / 2)
    }

    private func setupGestures(view: SKView) {
        let pinch = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        view.addGestureRecognizer(pinch)
    }

    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        if gesture.state == .changed {
            let newZoom = zoomScale / gesture.scale
            zoomScale = max(minZoom, min(maxZoom, newZoom))
            gesture.scale = 1.0
            updateCamera()
        }
    }

    // MARK: - Update Loop

    override func update(_ currentTime: TimeInterval) {
        guard gameState == .playing else { return }

        let rawDelta: CGFloat
        if lastUpdateTime == 0 {
            rawDelta = 1.0 / 60.0
            gameStartTime = currentTime
        } else {
            rawDelta = CGFloat(min(currentTime - lastUpdateTime, 0.05))
        }
        lastUpdateTime = currentTime
        gameTime = currentTime
        let deltaTime = rawDelta * gameSpeed

        // Update systems for all players
        for player in players {
            resourceSystem.update(deltaTime: deltaTime, player: player,
                                  map: gameMap, pathfinder: pathfinder)
            buildingSystem.update(deltaTime: deltaTime, player: player,
                                  map: gameMap, spriteFactory: spriteFactory)
            unitSystem.update(deltaTime: deltaTime, player: player,
                              map: gameMap, pathfinder: pathfinder)
        }

        // Combat
        combatSystem.update(deltaTime: deltaTime, players: players,
                            map: gameMap, pathfinder: pathfinder)

        // AI
        for ai in aiOpponents {
            ai.update(deltaTime: deltaTime)
        }

        // Age advancement
        for player in players where player.isAdvancingAge {
            player.ageAdvanceProgress += deltaTime / 30.0
            if player.ageAdvanceProgress >= 1.0 {
                player.isAdvancingAge = false
                player.ageAdvanceProgress = 0
                if let nextAge = Age(rawValue: player.currentAge.rawValue + 1) {
                    player.currentAge = nextAge
                    if player.isHuman {
                        hud.showStatus("Advanced to \(nextAge.displayName)!")
                    }
                }
            }
        }

        // Fog of war
        fogOfWar.update(player: humanPlayer)

        // Update sprite visuals
        updateSpriteVisuals()

        // Animate flags and idle fidget
        animateFlagsAndIdle(time: CGFloat(gameTime))

        // Terrain animations (every frame for visible tiles only)
        gameMap.animateWaterTiles(time: CGFloat(gameTime), cameraPosition: cameraPosition, viewSize: size)

        // Tile rendering (throttled)
        tileRenderTimer += deltaTime
        if tileRenderTimer >= 0.25 {
            tileRenderTimer = 0
            renderTiles()
            gameMap.addTerrainBlending(cameraPosition: cameraPosition, viewSize: size)
            fogOfWar.updateVisuals(cameraPosition: cameraPosition, viewSize: size)
        }

        // Minimap (throttled)
        minimapTimer += deltaTime
        if minimapTimer >= 0.5 {
            minimapTimer = 0
            hud.updateMinimap(players: players, map: gameMap,
                              cameraPos: cameraPosition, viewSize: size)
        }

        // HUD
        hud.update(player: humanPlayer)
        hud.updateIncomeRates(player: humanPlayer, deltaTime: deltaTime)
        hud.updateIdleVillagerCount(player: humanPlayer)
        if let building = selectedBuilding {
            hud.showBuildingInfo(building: building, player: humanPlayer)
        }

        // Apply panning momentum
        applyPanMomentum(deltaTime: deltaTime)

        // Check win/loss
        checkGameEnd()

        // Hide enemy units in fog
        updateUnitVisibility()
    }

    private func updateSpriteVisuals() {
        for player in players {
            for unit in player.units {
                spriteFactory.updateUnitNode(unit)
                spriteFactory.updateUnitFacing(unit, deltaTime: 1.0 / 60.0)
            }
            for building in player.buildings {
                spriteFactory.updateBuildingNode(building)
            }
        }
    }

    private func animateFlagsAndIdle(time: CGFloat) {
        // Flag waving on buildings
        for player in players {
            for building in player.buildings {
                if let flag = building.node?.childNode(withName: "flag") {
                    let phase = CGFloat(building.id * 17)
                    flag.position.x = (flag.position.x == 0 ? CGFloat(building.type.size.width) * gameMap.tileSize * 0.35 + 3.5 : flag.position.x)
                    let wave = sin(time * 2.5 + phase) * 1.5
                    flag.zRotation = wave * 0.1
                }
            }

            // Idle unit fidget
            for unit in player.units {
                if case .idle = unit.state {
                    if let bodyNode = unit.bodyNode {
                        let phase = CGFloat(unit.id * 31)
                        let fidgetX = sin(time * 1.2 + phase) * 0.5
                        let fidgetY = cos(time * 0.9 + phase * 1.3) * 0.3
                        bodyNode.position = CGPoint(x: fidgetX, y: fidgetY)
                    }
                }
            }
        }
    }

    private func updateUnitVisibility() {
        for player in players where !player.isHuman {
            for unit in player.units {
                let tile = gameMap.tile(at: unit.gridPosition)
                unit.node?.isHidden = !(tile?.isVisible ?? false)
            }
            for building in player.buildings {
                let tile = gameMap.tile(at: building.gridPosition)
                building.node?.isHidden = !(tile?.isExplored ?? false)
            }
        }
    }

    private func renderTiles() {
        gameMap.renderVisibleTiles(cameraPosition: cameraPosition, viewSize: size)
        gameMap.removeFarTiles(cameraPosition: cameraPosition, viewSize: size)
        fogOfWar.removeFarFogNodes(cameraPosition: cameraPosition, viewSize: size)
    }

    private func updateCamera() {
        let mapWidth = CGFloat(gameMap.width) * gameMap.tileSize
        let mapHeight = CGFloat(gameMap.height) * gameMap.tileSize
        cameraPosition.x = max(0, min(mapWidth, cameraPosition.x))
        cameraPosition.y = max(0, min(mapHeight, cameraPosition.y))

        hudCamera.position = cameraPosition
        hudCamera.setScale(zoomScale)
    }

    private func applyPanMomentum(deltaTime: CGFloat) {
        guard !isPanning else { return }

        if abs(panVelocity.x) > 1 || abs(panVelocity.y) > 1 {
            cameraPosition.x += panVelocity.x * deltaTime
            cameraPosition.y += panVelocity.y * deltaTime
            // Frame-rate independent decay (~0.92 per frame at 60fps)
            let decayRate: CGFloat = 60.0 * -log(0.92)
            let decay = exp(-decayRate * deltaTime)
            panVelocity.x *= decay
            panVelocity.y *= decay
            updateCamera()
        } else {
            panVelocity = .zero
        }
    }

    private func checkGameEnd() {
        // Check if human player lost all buildings
        if humanPlayer.buildings.isEmpty && humanPlayer.units.isEmpty {
            gameState = .defeat
            hud.showGameOver(victory: false, player: humanPlayer)
        }

        // Check if all AI players are eliminated
        let aiEliminated = players.filter { !$0.isHuman }.allSatisfy {
            $0.buildings.isEmpty && $0.units.isEmpty
        }
        if aiEliminated && players.count > 1 {
            gameState = .victory
            hud.showGameOver(victory: true, player: humanPlayer)
        }
    }

    // MARK: - Touch Handling

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let locationInScene = touch.location(in: self)
        let locationInHUD = touch.location(in: hudCamera)
        let hudPoint = CGPoint(x: locationInHUD.x + size.width / 2,
                               y: locationInHUD.y + size.height / 2)

        touchStartTime = gameTime
        touchHandledByHUD = false

        // Dismiss help overlay if showing
        if let helpOverlay = hudCamera.childNode(withName: "helpOverlay") {
            helpOverlay.removeFromParent()
            gameState = .playing
            touchHandledByHUD = true
            return
        }

        // Check HUD first
        if let action = hud.handleTouch(at: hudPoint) {
            handleHUDAction(action)
            touchHandledByHUD = true
            return
        }

        if hud.isPointInHUD(hudPoint) {
            touchHandledByHUD = true
            return
        }

        // Game world interaction
        lastTouchPosition = locationInScene
        isPanning = false
        lastTouchMoveTime = CACurrentMediaTime()

        if touches.count == 1 {
            selectionStart = locationInScene
        }

        // Determine if touch started on empty ground (for box select vs pan)
        let startTapRadius: CGFloat = gameMap.tileSize
        var touchedUnit = false
        for unit in humanPlayer.units {
            let dist = sqrt(pow(unit.position.x - locationInScene.x, 2) + pow(unit.position.y - locationInScene.y, 2))
            if dist < startTapRadius {
                touchedUnit = true
                break
            }
        }
        touchStartedOnEmptyGround = !touchedUnit
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        guard let lastPos = lastTouchPosition else { return }

        let dx = location.x - lastPos.x
        let dy = location.y - lastPos.y
        let dist = sqrt(dx * dx + dy * dy)

        // Update placement ghost (before pan/box-select decision)
        if case .placingBuilding(_) = actionMode {
            updatePlacementGhost(at: location)
            lastTouchPosition = location
            return
        }

        if dist > 5 {
            let currentSelected = unitSystem.selectedUnits(for: humanPlayer)

            // Box select if: touch started on empty ground AND no units selected
            if touchStartedOnEmptyGround && currentSelected.isEmpty, let start = selectionStart {
                // Box selection mode
                if selectionRect == nil {
                    selectionRect = SKShapeNode()
                    selectionRect?.strokeColor = SKColor.green.withAlphaComponent(0.7)
                    selectionRect?.fillColor = SKColor.green.withAlphaComponent(0.1)
                    selectionRect?.lineWidth = 1
                    selectionRect?.zPosition = 90
                    addChild(selectionRect!)
                }
                isBoxSelecting = true

                let rect = CGRect(x: min(start.x, location.x),
                                  y: min(start.y, location.y),
                                  width: abs(location.x - start.x),
                                  height: abs(location.y - start.y))
                selectionRect?.path = CGPath(rect: rect, transform: nil)
            } else {
                // Pan camera
                isPanning = true
                cameraPosition.x -= dx
                cameraPosition.y -= dy

                // Smooth velocity tracking
                let now = CACurrentMediaTime()
                let moveDelta = CGFloat(max(now - lastTouchMoveTime, 1.0 / 120.0))
                lastTouchMoveTime = now
                let instantVelocity = CGPoint(x: -dx / moveDelta, y: -dy / moveDelta)
                let smoothing: CGFloat = 0.3
                panVelocity = CGPoint(
                    x: panVelocity.x * (1 - smoothing) + instantVelocity.x * smoothing,
                    y: panVelocity.y * (1 - smoothing) + instantVelocity.y * smoothing
                )
                // Cap velocity
                let maxVel: CGFloat = 2000
                panVelocity.x = max(-maxVel, min(maxVel, panVelocity.x))
                panVelocity.y = max(-maxVel, min(maxVel, panVelocity.y))

                updateCamera()
                // Don't call renderTiles() here - the 0.25s timer in update() handles it
            }
        }

        lastTouchPosition = location
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let locationInScene = touch.location(in: self)

        // Handle tutorial taps
        if tutorialStep >= 0, let overlay = tutorialOverlay {
            let locInOverlay = touch.location(in: overlay)
            let skipNodes = overlay.nodes(at: locInOverlay).filter { $0.name == "skipTutorial" || $0.name == "skipTutorialLabel" }
            if !skipNodes.isEmpty {
                // Skip tutorial entirely
                tutorialStep = -1
                tutorialOverlay?.removeFromParent()
                tutorialOverlay = nil
                UserDefaults.standard.set(true, forKey: "tutorialCompleted")
            } else {
                // Advance to next step
                showTutorial(step: tutorialStep + 1)
            }
            return
        }

        // If touch was handled by HUD in touchesBegan, don't process game world
        if touchHandledByHUD {
            touchHandledByHUD = false
            selectionRect?.removeFromParent()
            selectionRect = nil
            isBoxSelecting = false
            selectionStart = nil
            lastTouchPosition = nil
            isPanning = false
            return
        }

        let worldPos = locationInScene
        let gridPos = gameMap.worldToGrid(worldPos)

        // Box selection
        if isBoxSelecting, let start = selectionStart {
            let rect = CGRect(x: min(start.x, locationInScene.x),
                              y: min(start.y, locationInScene.y),
                              width: abs(locationInScene.x - start.x),
                              height: abs(locationInScene.y - start.y))
            let _ = unitSystem.selectUnitsInRect(rect, player: humanPlayer)
            selectedBuilding = nil

            selectionRect?.removeFromParent()
            selectionRect = nil
            isBoxSelecting = false
            selectionStart = nil
            lastTouchPosition = nil
            touchStartedOnEmptyGround = false
            return
        }

        selectionRect?.removeFromParent()
        selectionRect = nil
        isBoxSelecting = false
        selectionStart = nil

        guard !isPanning else {
            isPanning = false
            lastTouchPosition = nil
            touchStartedOnEmptyGround = false
            renderTiles()
            return
        }

        isPanning = false
        lastTouchPosition = nil
        touchStartedOnEmptyGround = false

        // Handle game over tap
        if gameState == .victory || gameState == .defeat {
            onExit?()
            return
        }

        // Rally point mode
        if case .settingRallyPoint(let building) = actionMode {
            building.rallyPoint = gridPos
            hud.showStatus("Rally point set")
            actionMode = .normal
            hud.updateModeIndicator(mode: .normal)
            // Show rally point indicator
            let indicator = spriteFactory.createMoveIndicator(at: gameMap.gridToWorld(gridPos))
            gameWorld.addChild(indicator)
            return
        }

        // Building placement mode
        if case .placingBuilding(let type) = actionMode {
            handleBuildingPlacement(type: type, at: gridPos)
            return
        }

        // Attack-move mode
        if case .attackMove = actionMode {
            let selectedUnits = unitSystem.selectedUnits(for: humanPlayer)
            for unit in selectedUnits where unit.type != .villager {
                unit.state = .attackMoving(to: gridPos)
            }
            actionMode = .normal
            hud.updateModeIndicator(mode: .normal)
            hud.showStatus("Attack-moving to position")
            let indicator = spriteFactory.createMoveIndicator(at: gameMap.gridToWorld(gridPos))
            gameWorld.addChild(indicator)
            return
        }

        // Patrol mode
        if case .settingPatrol = actionMode {
            let selectedUnits = unitSystem.selectedUnits(for: humanPlayer)
            for unit in selectedUnits where unit.type != .villager {
                unit.state = .patrolling(from: unit.gridPosition, to: gridPos)
            }
            actionMode = .normal
            hud.updateModeIndicator(mode: .normal)
            hud.showStatus("Patrolling")
            let indicator = spriteFactory.createMoveIndicator(at: gameMap.gridToWorld(gridPos))
            gameWorld.addChild(indicator)
            return
        }

        // Check what was tapped
        let selectedUnits = unitSystem.selectedUnits(for: humanPlayer)

        if !selectedUnits.isEmpty {
            // Check if tapping on resource (send villagers to gather)
            if let tile = gameMap.tile(at: gridPos),
               tile.terrain.resourceType != nil,
               tile.resourceRemaining > 0,
               selectedUnits.allSatisfy({ $0.type == .villager }) {
                for unit in selectedUnits {
                    resourceSystem.sendVillagerToGather(unit: unit, tilePos: gridPos,
                                                        map: gameMap, pathfinder: pathfinder)
                }
                return
            }

            // Check if tapping on enemy unit (attack)
            for enemy in players where !enemy.isHuman {
                for enemyUnit in enemy.units {
                    if enemyUnit.gridPosition == gridPos || enemyUnit.gridPosition.distance(to: gridPos) < 1.5 {
                        for unit in selectedUnits {
                            unitSystem.attackTarget(unit: unit, targetID: enemyUnit.id, pathfinder: pathfinder)
                        }
                        return
                    }
                }

                // Check enemy buildings
                for enemyBuilding in enemy.buildings {
                    let size = enemyBuilding.type.size
                    let bx = enemyBuilding.gridPosition.x
                    let by = enemyBuilding.gridPosition.y
                    if gridPos.x >= bx && gridPos.x < bx + size.width &&
                       gridPos.y >= by && gridPos.y < by + size.height {
                        for unit in selectedUnits {
                            unitSystem.attackBuilding(unit: unit, targetBuildingID: enemyBuilding.id, pathfinder: pathfinder)
                        }
                        return
                    }
                }
            }

            // Check if tapping on own unfinished building (send villagers to build)
            for building in humanPlayer.buildings where !building.isConstructed {
                let size = building.type.size
                let bx = building.gridPosition.x
                let by = building.gridPosition.y
                if gridPos.x >= bx && gridPos.x < bx + size.width &&
                   gridPos.y >= by && gridPos.y < by + size.height {
                    if selectedUnits.allSatisfy({ $0.type == .villager }) {
                        for unit in selectedUnits {
                            resourceSystem.sendVillagerToBuild(unit: unit, building: building, pathfinder: pathfinder)
                        }
                        return
                    }
                }
            }

            // Check if tapping on a friendly unit — select it instead of moving
            let friendlyTapRadius: CGFloat = gameMap.tileSize
            var tappedFriendlyUnit: Unit?
            var bestFriendlyDist: CGFloat = .infinity
            for unit in humanPlayer.units {
                let dist = sqrt(pow(unit.position.x - worldPos.x, 2) + pow(unit.position.y - worldPos.y, 2))
                if dist < friendlyTapRadius && dist < bestFriendlyDist {
                    bestFriendlyDist = dist
                    tappedFriendlyUnit = unit
                }
            }
            if let friendlyUnit = tappedFriendlyUnit {
                let now = gameTime
                if now - lastTapTime < 0.4 && lastTappedUnitType == friendlyUnit.type {
                    for u in humanPlayer.units where u.type == friendlyUnit.type {
                        u.isSelected = true
                    }
                    selectedBuilding = nil
                    lastTapTime = 0
                    lastTappedUnitType = nil
                } else {
                    lastTapTime = now
                    lastTappedUnitType = friendlyUnit.type
                    unitSystem.selectUnit(friendlyUnit, player: humanPlayer)
                    selectedBuilding = nil
                }
                return
            }

            // Move selected units
            unitSystem.moveUnits(selectedUnits, to: gridPos, pathfinder: pathfinder)
            return
        }

        // Try to select a unit at this position
        let tapRadius: CGFloat = gameMap.tileSize
        var tappedUnit: Unit?
        var bestDist: CGFloat = .infinity

        for unit in humanPlayer.units {
            let dist = sqrt(pow(unit.position.x - worldPos.x, 2) + pow(unit.position.y - worldPos.y, 2))
            if dist < tapRadius && dist < bestDist {
                bestDist = dist
                tappedUnit = unit
            }
        }

        if let unit = tappedUnit {
            // Double-tap detection: select all visible of same type
            let now = gameTime
            if now - lastTapTime < 0.4 && lastTappedUnitType == unit.type {
                // Double tap — select all visible units of this type
                for u in humanPlayer.units {
                    if u.type == unit.type {
                        u.isSelected = true
                    }
                }
                selectedBuilding = nil
                lastTapTime = 0
                lastTappedUnitType = nil
                return
            }

            lastTapTime = now
            lastTappedUnitType = unit.type
            unitSystem.selectUnit(unit, player: humanPlayer)
            selectedBuilding = nil
            return
        }

        // Try to select a building
        for building in humanPlayer.buildings {
            let size = building.type.size
            let bx = building.gridPosition.x
            let by = building.gridPosition.y
            if gridPos.x >= bx && gridPos.x < bx + size.width &&
               gridPos.y >= by && gridPos.y < by + size.height {
                selectedBuilding = building
                unitSystem.deselectAll(player: humanPlayer)
                hud.showBuildingInfo(building: building, player: humanPlayer)
                return
            }
        }

        // Tapped empty space - deselect
        unitSystem.deselectAll(player: humanPlayer)
        selectedBuilding = nil
    }

    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        selectionRect?.removeFromParent()
        selectionRect = nil
        isBoxSelecting = false
        selectionStart = nil
        lastTouchPosition = nil
        isPanning = false
        touchStartedOnEmptyGround = false
    }

    // MARK: - HUD Actions

    private func handleHUDAction(_ action: HUDAction) {
        switch action {
        case .pause:
            gameState = gameState == .paused ? .playing : .paused
            hud.showStatus(gameState == .paused ? "PAUSED" : "")

        case .exit:
            hud.showExitConfirmation()

        case .confirmExit:
            hud.hideExitConfirmation()
            onExit?()

        case .cancelExit:
            hud.hideExitConfirmation()

        case .toggleSpeed:
            if gameSpeed == 1.0 { gameSpeed = 1.5 }
            else if gameSpeed == 1.5 { gameSpeed = 2.0 }
            else { gameSpeed = 1.0 }
            hud.updateSpeedButton(speed: gameSpeed)
            hud.showStatus("Speed: \(gameSpeed == 1.0 ? "1x" : gameSpeed == 1.5 ? "1.5x" : "2x")")

        case .showHelp:
            showHelpOverlay()

        case .deselect:
            if case .placingBuilding(_) = actionMode {
                actionMode = .normal
                placementGhost?.removeFromParent()
                placementGhost = nil
                hud.showStatus("")
                hud.updateModeIndicator(mode: .normal)
            } else if case .settingRallyPoint(_) = actionMode {
                actionMode = .normal
                hud.showStatus("")
                hud.updateModeIndicator(mode: .normal)
            } else if case .attackMove = actionMode {
                actionMode = .normal
                hud.showStatus("")
                hud.updateModeIndicator(mode: .normal)
            } else if case .settingPatrol = actionMode {
                actionMode = .normal
                hud.showStatus("")
                hud.updateModeIndicator(mode: .normal)
            } else {
                unitSystem.deselectAll(player: humanPlayer)
                selectedBuilding = nil
            }

        case .ageUp:
            attemptAgeAdvance()

        case .openBuildMenu:
            hud.showBuildMenu(player: humanPlayer)

        case .closeBuildMenu:
            hud.hideBuildMenu()
            actionMode = .normal
            placementGhost?.removeFromParent()
            placementGhost = nil
            hud.updateModeIndicator(mode: .normal)

        case .selectBuilding(let type):
            hud.hideBuildMenu()
            actionMode = .placingBuilding(type)
            placementType = type
            hud.showStatus("Tap to place \(type.displayName)")
            hud.updateModeIndicator(mode: actionMode)
            createPlacementGhost(type: type)

        case .trainUnit(let type):
            if let building = selectedBuilding {
                if buildingSystem.trainUnit(type: type, at: building, player: humanPlayer) {
                    hud.showStatus("Training \(type.displayName)")
                    totalUnitsTrainedHuman += 1
                } else {
                    if !humanPlayer.canAfford(type.cost) {
                        hud.showStatus("Not enough resources!")
                    } else if humanPlayer.population >= humanPlayer.populationCap {
                        hud.showStatus("Need more houses!")
                    } else {
                        hud.showStatus("Cannot train this unit")
                    }
                }
            }

        case .setRallyPoint:
            if let building = selectedBuilding {
                hud.showStatus("Tap to set rally point")
                actionMode = .settingRallyPoint(building)
                hud.updateModeIndicator(mode: actionMode)
            }

        case .minimapTap(let point):
            let worldPoint = hud.minimapToWorld(point: point, map: gameMap)
            cameraPosition = worldPoint
            updateCamera()
            renderTiles()

        case .openTechMenu:
            hud.showTechMenu(player: humanPlayer)

        case .closeTechMenu:
            hud.hideTechMenu()

        case .researchTech(let tech):
            guard !humanPlayer.researchedTechs.contains(tech) else {
                hud.showStatus("Already researched!")
                return
            }
            // Find a building that can research this tech
            let researchBuilding = humanPlayer.buildings.first {
                $0.type == tech.researchedAt && $0.isConstructed && $0.currentResearch == nil
            }
            guard let building = researchBuilding else {
                hud.showStatus("No available \(tech.researchedAt.displayName)!")
                return
            }
            guard humanPlayer.canAfford(tech.cost) else {
                hud.showStatus("Not enough resources!")
                return
            }
            humanPlayer.spend(tech.cost)
            building.currentResearch = tech
            building.researchProgress = 0
            hud.showStatus("Researching \(tech.displayName)...")
            hud.hideTechMenu()

        case .attackMoveMode:
            actionMode = .attackMove
            hud.updateModeIndicator(mode: .attackMove)
            hud.showStatus("Click destination to attack-move")

        case .patrolMode:
            actionMode = .settingPatrol
            hud.updateModeIndicator(mode: .settingPatrol)
            hud.showStatus("Click destination to patrol")

        case .selectIdleVillager:
            let idleVillagers = humanPlayer.units.filter { unit in
                guard unit.type == .villager else { return false }
                if case .idle = unit.state { return true }
                return false
            }
            guard !idleVillagers.isEmpty else {
                hud.showStatus("No idle villagers")
                return
            }
            lastIdleVillagerIndex = lastIdleVillagerIndex % idleVillagers.count
            let villager = idleVillagers[lastIdleVillagerIndex]
            unitSystem.deselectAll(player: humanPlayer)
            villager.isSelected = true
            selectedBuilding = nil
            cameraPosition = villager.position
            updateCamera()
            renderTiles()
            lastIdleVillagerIndex = (lastIdleVillagerIndex + 1) % idleVillagers.count
        }
    }

    private func handleBuildingPlacement(type: BuildingType, at gridPos: GridPosition) {
        guard humanPlayer.canAfford(type.cost) else {
            hud.showStatus("Not enough resources!")
            return
        }
        guard humanPlayer.currentAge.rawValue >= type.requiredAge.rawValue else {
            hud.showStatus("Requires \(type.requiredAge.displayName)")
            return
        }

        if let building = buildingSystem.placeBuilding(type: type, at: gridPos,
                                                         player: humanPlayer, map: gameMap,
                                                         spriteFactory: spriteFactory) {
            gameWorld.addChild(building.node!)
            hud.showStatus("Building \(type.displayName)")

            // Auto-assign nearby idle villagers to build
            let idleVillagers = humanPlayer.units.filter {
                $0.type == .villager && isUnitIdle($0)
            }.sorted {
                $0.gridPosition.distance(to: gridPos) < $1.gridPosition.distance(to: gridPos)
            }

            if let villager = idleVillagers.first {
                resourceSystem.sendVillagerToBuild(unit: villager, building: building, pathfinder: pathfinder)
            }
        } else {
            hud.showStatus("Cannot build here!")
        }

        actionMode = .normal
        placementGhost?.removeFromParent()
        placementGhost = nil
        hud.updateModeIndicator(mode: .normal)
    }

    private func createPlacementGhost(type: BuildingType) {
        placementGhost?.removeFromParent()
        let w = CGFloat(type.size.width) * gameMap.tileSize
        let h = CGFloat(type.size.height) * gameMap.tileSize
        let ghost = SKNode()
        ghost.zPosition = 80

        let body = SKShapeNode(rectOf: CGSize(width: w - 2, height: h - 2))
        body.fillColor = type.color.withAlphaComponent(0.4)
        body.strokeColor = SKColor.green.withAlphaComponent(0.8)
        body.lineWidth = 2
        body.name = "ghostBody"
        ghost.addChild(body)

        let label = SKLabelNode(text: type.icon)
        label.fontSize = min(w, h) * 0.35
        label.fontName = "Helvetica-Bold"
        label.fontColor = SKColor.white.withAlphaComponent(0.6)
        label.verticalAlignmentMode = .center
        ghost.addChild(label)

        // Grid cell indicators
        for dy in 0..<type.size.height {
            for dx in 0..<type.size.width {
                let cell = SKShapeNode(rectOf: CGSize(width: gameMap.tileSize - 1, height: gameMap.tileSize - 1))
                cell.fillColor = SKColor.green.withAlphaComponent(0.15)
                cell.strokeColor = SKColor.green.withAlphaComponent(0.3)
                cell.lineWidth = 0.5
                cell.position = CGPoint(
                    x: CGFloat(dx) * gameMap.tileSize - w / 2 + gameMap.tileSize / 2,
                    y: CGFloat(dy) * gameMap.tileSize - h / 2 + gameMap.tileSize / 2
                )
                cell.name = "ghostCell_\(dx)_\(dy)"
                ghost.addChild(cell)
            }
        }

        ghost.position = cameraPosition
        gameWorld.addChild(ghost)
        placementGhost = ghost
    }

    private func updatePlacementGhost(at worldPos: CGPoint) {
        guard let ghost = placementGhost, let type = placementType else { return }
        let gridPos = gameMap.worldToGrid(worldPos)
        let snappedPos = gameMap.gridToWorld(gridPos)
        let offsetX = CGFloat(type.size.width - 1) * gameMap.tileSize / 2
        let offsetY = CGFloat(type.size.height - 1) * gameMap.tileSize / 2
        ghost.position = CGPoint(x: snappedPos.x + offsetX, y: snappedPos.y + offsetY)

        // Update cell colors based on validity
        let canPlace = gameMap.canPlaceBuilding(type: type, at: gridPos)
        if let body = ghost.childNode(withName: "ghostBody") as? SKShapeNode {
            body.strokeColor = canPlace ? SKColor.green.withAlphaComponent(0.8) : SKColor.red.withAlphaComponent(0.8)
        }
        for dy in 0..<type.size.height {
            for dx in 0..<type.size.width {
                if let cell = ghost.childNode(withName: "ghostCell_\(dx)_\(dy)") as? SKShapeNode {
                    let tilePos = GridPosition(x: gridPos.x + dx, y: gridPos.y + dy)
                    let valid = gameMap.isBuildable(tilePos)
                    cell.fillColor = valid ? SKColor.green.withAlphaComponent(0.15) : SKColor.red.withAlphaComponent(0.25)
                    cell.strokeColor = valid ? SKColor.green.withAlphaComponent(0.3) : SKColor.red.withAlphaComponent(0.5)
                }
            }
        }
    }

    private func attemptAgeAdvance() {
        guard !humanPlayer.isAdvancingAge else {
            hud.showStatus("Already advancing!")
            return
        }
        guard humanPlayer.currentAge != .imperialAge else {
            hud.showStatus("Already at Imperial Age!")
            return
        }

        let nextAge = Age(rawValue: humanPlayer.currentAge.rawValue + 1)!
        guard humanPlayer.canAfford(nextAge.advanceCost) else {
            hud.showStatus("Not enough resources to advance!")
            return
        }

        humanPlayer.spend(nextAge.advanceCost)
        humanPlayer.isAdvancingAge = true
        humanPlayer.ageAdvanceProgress = 0
        hud.showStatus("Advancing to \(nextAge.displayName)...")
    }

    private func isUnitIdle(_ unit: Unit) -> Bool {
        if case .idle = unit.state { return true }
        return false
    }

    // MARK: - Help Overlay

    private func showHelpOverlay() {
        guard hudCamera.childNode(withName: "helpOverlay") == nil else {
            hudCamera.childNode(withName: "helpOverlay")?.removeFromParent()
            gameState = .playing
            return
        }

        gameState = .paused

        let overlay = SKNode()
        overlay.name = "helpOverlay"
        overlay.zPosition = 300

        let bg = SKShapeNode(rectOf: size)
        bg.fillColor = SKColor.black.withAlphaComponent(0.85)
        bg.strokeColor = .clear
        overlay.addChild(bg)

        let title = SKLabelNode(text: "How to Play")
        title.fontSize = 24
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        title.position = CGPoint(x: 0, y: size.height * 0.35)
        overlay.addChild(title)

        let tips = [
            "Drag to pan the camera, pinch to zoom",
            "Tap a unit to select, drag to box-select",
            "Tap ground to move selected units",
            "Select villagers > Build to construct buildings",
            "Tap resources with villagers to gather",
            "Tap unfinished buildings with villagers to help build",
            "Select military buildings to train units",
            "Double-tap a unit to select all of same type",
            "ESC button cancels placement / deselects",
            "Tap enemy units or buildings to attack",
        ]

        for (i, tip) in tips.enumerated() {
            let label = SKLabelNode(text: tip)
            label.fontSize = 13
            label.fontName = "Helvetica"
            label.fontColor = .white
            label.position = CGPoint(x: 0, y: size.height * 0.25 - CGFloat(i) * 22)
            overlay.addChild(label)
        }

        let closeLabel = SKLabelNode(text: "Tap anywhere to close")
        closeLabel.fontSize = 14
        closeLabel.fontName = "Helvetica-Bold"
        closeLabel.fontColor = .yellow
        closeLabel.position = CGPoint(x: 0, y: -size.height * 0.35)
        closeLabel.name = "helpOverlay"
        overlay.addChild(closeLabel)

        hudCamera.addChild(overlay)
    }
}
