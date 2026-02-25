import SpriteKit
import UIKit

class GameScene: SKScene {

    // MARK: - Properties

    var playerCivilization: Civilization = .britons
    var onExit: (() -> Void)?

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
    var lastBuildingAttackTimes: [Int: TimeInterval] = [:]

    // Selection
    var selectedBuilding: Building?
    var selectionStart: CGPoint?
    var selectionRect: SKShapeNode?
    var isBoxSelecting = false

    // Touch tracking
    var lastTouchPosition: CGPoint?
    var isPanning = false
    var panVelocity = CGPoint.zero
    var touchStartTime: TimeInterval = 0

    // Building placement
    var placementGhost: SKNode?
    var placementType: BuildingType?

    // Tile rendering timer
    var tileRenderTimer: CGFloat = 0
    var minimapTimer: CGFloat = 0
    var fogTimer: CGFloat = 0
    var spriteUpdateTimer: CGFloat = 0
    var isReady = false

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
        isReady = true
    }

    private func setupGameWorld() {
        gameWorld = SKNode()
        gameWorld.name = "gameWorld"
        addChild(gameWorld)

        gameMap = GameMap(width: 50, height: 50, tileSize: 32)
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

        let ai = AIOpponent(player: aiPlayer)
        ai.gameScene = self
        aiOpponents.append(ai)

        // Place starting positions
        let p1Start = GridPosition(x: 10, y: 10)
        let p2Start = GridPosition(x: gameMap.width - 12, y: gameMap.height - 12)

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
            if let node = tc.node {
                gameWorld.addChild(node)
            }
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
            unit.gridPosition = pos
            unit.position = gameMap.gridToWorld(pos)

            let node = spriteFactory.createUnitNode(unit: unit)
            node.position = unit.position
            unit.node = node

            player.addUnit(unit)
            gameWorld.addChild(node)
        }

        // Scout
        let scoutPos = GridPosition(x: center.x + 3, y: center.y)
        let scout = Unit(type: .scout, ownerID: player.id, position: scoutPos)
        scout.gridPosition = scoutPos
        scout.position = gameMap.gridToWorld(scoutPos)

        let scoutNode = spriteFactory.createUnitNode(unit: scout)
        scoutNode.position = scout.position
        scout.node = scoutNode

        player.addUnit(scout)
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
        guard isReady, gameState == .playing else { return }

        let deltaTime: CGFloat
        if lastUpdateTime == 0 {
            deltaTime = 1.0 / 60.0
        } else {
            deltaTime = CGFloat(min(currentTime - lastUpdateTime, 0.05))
        }
        lastUpdateTime = currentTime
        gameTime = currentTime

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

        // Fog of war (throttled to ~4x per second instead of 60x)
        fogTimer += deltaTime
        if fogTimer >= 0.25 {
            fogTimer = 0
            fogOfWar.update(player: humanPlayer)
        }

        // Update sprite visuals (throttled to ~5x per second)
        spriteUpdateTimer += deltaTime
        if spriteUpdateTimer >= 0.2 {
            spriteUpdateTimer = 0
            updateSpriteVisuals()
        }

        // Tile rendering (throttled)
        tileRenderTimer += deltaTime
        if tileRenderTimer >= 0.75 {
            tileRenderTimer = 0
            renderTiles()
            fogOfWar.updateVisuals(cameraPosition: cameraPosition, viewSize: size)
        }

        // Minimap (throttled)
        minimapTimer += deltaTime
        if minimapTimer >= 2.0 {
            minimapTimer = 0
            hud.updateMinimap(players: players, map: gameMap,
                              cameraPos: cameraPosition, viewSize: size)
        }

        // HUD
        hud.update(player: humanPlayer)
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
            }
            for building in player.buildings {
                spriteFactory.updateBuildingNode(building)
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
            panVelocity.x *= 0.92
            panVelocity.y *= 0.92
            updateCamera()
        }
    }

    private func checkGameEnd() {
        // Check if all AI players are eliminated (victory takes priority)
        let aiEliminated = players.filter { !$0.isHuman }.allSatisfy {
            $0.buildings.isEmpty && $0.units.isEmpty
        }
        if aiEliminated && players.count > 1 {
            gameState = .victory
            hud.showGameOver(victory: true)
            return
        }

        // Check if human player lost all buildings and units
        if humanPlayer.buildings.isEmpty && humanPlayer.units.isEmpty {
            gameState = .defeat
            hud.showGameOver(victory: false)
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

        // Check HUD first
        if let action = hud.handleTouch(at: hudPoint) {
            handleHUDAction(action)
            return
        }

        if hud.isPointInHUD(hudPoint) { return }

        // Game world interaction
        lastTouchPosition = locationInScene
        isPanning = false

        if touches.count == 1 {
            selectionStart = locationInScene
        }
    }

    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let location = touch.location(in: self)

        guard let lastPos = lastTouchPosition else { return }

        let dx = location.x - lastPos.x
        let dy = location.y - lastPos.y
        let dist = sqrt(dx * dx + dy * dy)

        if dist > 5 {
            isPanning = true

            // Pan camera
            cameraPosition.x -= dx
            cameraPosition.y -= dy
            panVelocity = CGPoint(x: -dx / CGFloat(1.0 / 60.0),
                                   y: -dy / CGFloat(1.0 / 60.0))
            updateCamera()
            renderTiles()
        }

        lastTouchPosition = location

        // Box selection
        if !isPanning, let start = selectionStart {
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
        }
    }

    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let locationInScene = touch.location(in: self)
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
            return
        }

        selectionRect?.removeFromParent()
        selectionRect = nil
        isBoxSelecting = false
        selectionStart = nil

        guard !isPanning else {
            isPanning = false
            lastTouchPosition = nil
            return
        }

        isPanning = false
        lastTouchPosition = nil

        // Handle game over tap
        if gameState == .victory || gameState == .defeat {
            onExit?()
            return
        }

        // Building placement mode
        if case .placingBuilding(let type) = actionMode {
            handleBuildingPlacement(type: type, at: gridPos)
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
    }

    // MARK: - HUD Actions

    private func handleHUDAction(_ action: HUDAction) {
        switch action {
        case .pause:
            gameState = gameState == .paused ? .playing : .paused
            hud.showStatus(gameState == .paused ? "PAUSED" : "")

        case .exit:
            onExit?()

        case .ageUp:
            attemptAgeAdvance()

        case .openBuildMenu:
            hud.showBuildMenu(player: humanPlayer)

        case .closeBuildMenu:
            hud.hideBuildMenu()
            actionMode = .normal
            placementGhost?.removeFromParent()
            placementGhost = nil

        case .selectBuilding(let type):
            hud.hideBuildMenu()
            actionMode = .placingBuilding(type)
            placementType = type
            hud.showStatus("Tap to place \(type.displayName)")

        case .trainUnit(let type):
            if let building = selectedBuilding {
                if buildingSystem.trainUnit(type: type, at: building, player: humanPlayer) {
                    hud.showStatus("Training \(type.displayName)")
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
            hud.showStatus("Tap to set rally point")
            actionMode = .normal // Will handle next tap as rally

        case .minimapTap(let point):
            let worldPoint = hud.minimapToWorld(point: point, map: gameMap)
            cameraPosition = worldPoint
            updateCamera()
            renderTiles()
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
            if let node = building.node {
                gameWorld.addChild(node)
            }
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
}
