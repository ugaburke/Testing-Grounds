import SpriteKit

class HUDOverlay {
    weak var gameScene: GameScene?
    let hudNode: SKNode
    let viewSize: CGSize

    // Resource bar
    private var foodLabel: SKLabelNode!
    private var woodLabel: SKLabelNode!
    private var goldLabel: SKLabelNode!
    private var stoneLabel: SKLabelNode!
    private var popLabel: SKLabelNode!
    private var ageLabel: SKLabelNode!

    // Minimap
    private var minimapNode: SKShapeNode!
    private var minimapSize: CGFloat = 150
    private var minimapDots: SKNode!
    private var minimapViewRect: SKShapeNode!

    // Action panel
    private var actionPanel: SKNode!
    private var actionButtons: [SKNode] = []

    // Info panel
    private var infoPanel: SKNode!
    private var infoNameLabel: SKLabelNode!
    private var infoHPLabel: SKLabelNode!
    private var infoIcon: SKShapeNode!
    private var queueLabel: SKLabelNode!

    // Build menu
    private var buildMenuNode: SKNode!
    private var isBuildMenuOpen = false

    // Selection info
    private var selectionCountLabel: SKLabelNode!

    // Game status
    private var statusLabel: SKLabelNode!

    // Buttons
    private var pauseButton: SKNode!
    private var exitButton: SKNode!
    private var ageUpButton: SKNode!
    private var deselectButton: SKNode!

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        self.hudNode = SKNode()
        self.hudNode.zPosition = 100
        self.hudNode.name = "hud"

        setupResourceBar()
        setupMinimap()
        setupActionPanel()
        setupInfoPanel()
        setupBuildMenu()
        setupStatusLabel()
        setupGameButtons()
    }

    // MARK: - Setup

    private func setupResourceBar() {
        let barHeight: CGFloat = 36
        let bar = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: barHeight))
        bar.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.9)
        bar.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
        bar.lineWidth = 1
        bar.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - barHeight / 2)
        hudNode.addChild(bar)

        let startX: CGFloat = 30
        let spacing: CGFloat = 140

        // Food
        let foodIcon = createResourceIcon(color: .red, symbol: "F", x: startX, y: viewSize.height - barHeight / 2)
        hudNode.addChild(foodIcon)
        foodLabel = createLabel(x: startX + 22, y: viewSize.height - barHeight / 2)
        hudNode.addChild(foodLabel)

        // Wood
        let woodIcon = createResourceIcon(color: .brown, symbol: "W", x: startX + spacing, y: viewSize.height - barHeight / 2)
        hudNode.addChild(woodIcon)
        woodLabel = createLabel(x: startX + spacing + 22, y: viewSize.height - barHeight / 2)
        hudNode.addChild(woodLabel)

        // Gold
        let goldIcon = createResourceIcon(color: .yellow, symbol: "G", x: startX + spacing * 2, y: viewSize.height - barHeight / 2)
        hudNode.addChild(goldIcon)
        goldLabel = createLabel(x: startX + spacing * 2 + 22, y: viewSize.height - barHeight / 2)
        hudNode.addChild(goldLabel)

        // Stone
        let stoneIcon = createResourceIcon(color: .gray, symbol: "S", x: startX + spacing * 3, y: viewSize.height - barHeight / 2)
        hudNode.addChild(stoneIcon)
        stoneLabel = createLabel(x: startX + spacing * 3 + 22, y: viewSize.height - barHeight / 2)
        hudNode.addChild(stoneLabel)

        // Population
        let popIcon = createResourceIcon(color: .cyan, symbol: "P", x: startX + spacing * 4, y: viewSize.height - barHeight / 2)
        hudNode.addChild(popIcon)
        popLabel = createLabel(x: startX + spacing * 4 + 22, y: viewSize.height - barHeight / 2)
        hudNode.addChild(popLabel)

        // Age
        ageLabel = SKLabelNode(text: "Dark Age")
        ageLabel.fontSize = 14
        ageLabel.fontName = "Helvetica-Bold"
        ageLabel.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        ageLabel.position = CGPoint(x: viewSize.width - 120, y: viewSize.height - barHeight / 2 - 5)
        ageLabel.horizontalAlignmentMode = .center
        hudNode.addChild(ageLabel)
    }

    private func createResourceIcon(color: SKColor, symbol: String, x: CGFloat, y: CGFloat) -> SKNode {
        let bg = SKShapeNode(circleOfRadius: 10)
        bg.fillColor = color.withAlphaComponent(0.7)
        bg.strokeColor = color
        bg.lineWidth = 1
        bg.position = CGPoint(x: x, y: y)

        let label = SKLabelNode(text: symbol)
        label.fontSize = 11
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        bg.addChild(label)

        return bg
    }

    private func createLabel(x: CGFloat, y: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(text: "0")
        label.fontSize = 14
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: x, y: y)
        return label
    }

    private func setupMinimap() {
        let padding: CGFloat = 10
        minimapNode = SKShapeNode(rectOf: CGSize(width: minimapSize, height: minimapSize))
        minimapNode.fillColor = SKColor(red: 0.05, green: 0.05, blue: 0.05, alpha: 0.85)
        minimapNode.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
        minimapNode.lineWidth = 2
        minimapNode.position = CGPoint(x: padding + minimapSize / 2, y: padding + minimapSize / 2)
        hudNode.addChild(minimapNode)

        minimapDots = SKNode()
        minimapNode.addChild(minimapDots)

        minimapViewRect = SKShapeNode(rectOf: CGSize(width: 20, height: 15))
        minimapViewRect.fillColor = .clear
        minimapViewRect.strokeColor = .white
        minimapViewRect.lineWidth = 1
        minimapNode.addChild(minimapViewRect)
    }

    private func setupActionPanel() {
        let panelWidth: CGFloat = 280
        let panelHeight: CGFloat = 160
        let padding: CGFloat = 10

        actionPanel = SKNode()
        actionPanel.position = CGPoint(x: viewSize.width - panelWidth / 2 - padding,
                                        y: padding + panelHeight / 2)

        let bg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight))
        bg.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.9)
        bg.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
        bg.lineWidth = 2
        bg.name = "actionPanelBg"
        actionPanel.addChild(bg)

        hudNode.addChild(actionPanel)
    }

    private func setupInfoPanel() {
        let panelWidth: CGFloat = 220
        let panelHeight: CGFloat = 160
        let minimapRightEdge: CGFloat = 10 + minimapSize + 10

        infoPanel = SKNode()
        infoPanel.position = CGPoint(x: minimapRightEdge + panelWidth / 2,
                                      y: 10 + panelHeight / 2)

        let bg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight))
        bg.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.9)
        bg.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
        bg.lineWidth = 2
        infoPanel.addChild(bg)

        infoIcon = SKShapeNode(circleOfRadius: 20)
        infoIcon.fillColor = .gray
        infoIcon.strokeColor = .white
        infoIcon.position = CGPoint(x: -panelWidth / 2 + 35, y: 20)
        infoPanel.addChild(infoIcon)

        infoNameLabel = SKLabelNode(text: "")
        infoNameLabel.fontSize = 14
        infoNameLabel.fontName = "Helvetica-Bold"
        infoNameLabel.fontColor = .white
        infoNameLabel.position = CGPoint(x: 10, y: 30)
        infoNameLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(infoNameLabel)

        infoHPLabel = SKLabelNode(text: "")
        infoHPLabel.fontSize = 12
        infoHPLabel.fontName = "Helvetica"
        infoHPLabel.fontColor = .lightGray
        infoHPLabel.position = CGPoint(x: 10, y: 10)
        infoHPLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(infoHPLabel)

        queueLabel = SKLabelNode(text: "")
        queueLabel.fontSize = 11
        queueLabel.fontName = "Helvetica"
        queueLabel.fontColor = .cyan
        queueLabel.position = CGPoint(x: -panelWidth / 2 + 10, y: -20)
        queueLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(queueLabel)

        selectionCountLabel = SKLabelNode(text: "")
        selectionCountLabel.fontSize = 12
        selectionCountLabel.fontName = "Helvetica"
        selectionCountLabel.fontColor = .yellow
        selectionCountLabel.position = CGPoint(x: -panelWidth / 2 + 10, y: -40)
        selectionCountLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(selectionCountLabel)

        infoPanel.isHidden = true
        hudNode.addChild(infoPanel)
    }

    private func setupBuildMenu() {
        buildMenuNode = SKNode()
        buildMenuNode.isHidden = true
        buildMenuNode.zPosition = 110

        let bg = SKShapeNode(rectOf: CGSize(width: 400, height: 250))
        bg.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
        bg.lineWidth = 2
        bg.name = "buildMenuBg"
        buildMenuNode.addChild(bg)

        let title = SKLabelNode(text: "Build Menu")
        title.fontSize = 16
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        title.position = CGPoint(x: 0, y: 100)
        buildMenuNode.addChild(title)

        buildMenuNode.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        hudNode.addChild(buildMenuNode)
    }

    private func setupStatusLabel() {
        statusLabel = SKLabelNode(text: "")
        statusLabel.fontSize = 18
        statusLabel.fontName = "Helvetica-Bold"
        statusLabel.fontColor = .yellow
        statusLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - 60)
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.zPosition = 120
        hudNode.addChild(statusLabel)
    }

    private func setupGameButtons() {
        // Pause button
        pauseButton = createHUDButton(text: "||", x: viewSize.width - 55, y: viewSize.height - 36, name: "pauseBtn")
        hudNode.addChild(pauseButton)

        // Exit button
        exitButton = createHUDButton(text: "X", x: viewSize.width - 15, y: viewSize.height - 36, name: "exitBtn")
        hudNode.addChild(exitButton)

        // Age up button
        ageUpButton = createHUDButton(text: "AGE UP", x: viewSize.width - 200, y: viewSize.height - 36, name: "ageUpBtn", width: 64)
        hudNode.addChild(ageUpButton)

        // Help button
        let helpBtn = createHUDButton(text: "?", x: viewSize.width - 95, y: viewSize.height - 36, name: "helpBtn")
        hudNode.addChild(helpBtn)

        // Deselect/Cancel button
        deselectButton = createHUDButton(text: "ESC", x: viewSize.width - 135, y: viewSize.height - 36, name: "deselectBtn", width: 36)
        hudNode.addChild(deselectButton)
    }

    private func createHUDButton(text: String, x: CGFloat, y: CGFloat, name: String, width: CGFloat = 34) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: x, y: y)
        container.name = name

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 26), cornerRadius: 4)
        bg.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.9)
        bg.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        bg.lineWidth = 1
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontSize = 12
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        return container
    }

    // MARK: - Update

    func update(player: Player) {
        // Update resources with low-resource warnings
        let warningThreshold = 50
        foodLabel.text = "\(player.resources.food)"
        foodLabel.fontColor = player.resources.food < warningThreshold ? .red : .white
        woodLabel.text = "\(player.resources.wood)"
        woodLabel.fontColor = player.resources.wood < warningThreshold ? .red : .white
        goldLabel.text = "\(player.resources.gold)"
        goldLabel.fontColor = player.resources.gold < warningThreshold ? .red : .white
        stoneLabel.text = "\(player.resources.stone)"
        stoneLabel.fontColor = player.resources.stone < warningThreshold ? .red : .white

        popLabel.text = "\(player.population)/\(player.populationCap)"
        popLabel.fontColor = player.population >= player.populationCap ? .red : .white

        ageLabel.text = player.currentAge.displayName

        if player.isAdvancingAge {
            ageLabel.fontColor = .cyan
            let progressPct = Int(player.ageAdvanceProgress * 100)
            ageLabel.text = "Advancing... \(progressPct)%"
            updateAgeProgressBar(progress: player.ageAdvanceProgress)
        } else {
            ageLabel.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
            removeAgeProgressBar()
        }

        // Update selection info
        updateSelectionInfo(player: player)
    }

    private func updateAgeProgressBar(progress: CGFloat) {
        let barWidth: CGFloat = 80
        if hudNode.childNode(withName: "ageProgressBg") == nil {
            let bg = SKShapeNode(rectOf: CGSize(width: barWidth, height: 4))
            bg.fillColor = .darkGray
            bg.strokeColor = .clear
            bg.position = CGPoint(x: viewSize.width - 120, y: viewSize.height - 50)
            bg.name = "ageProgressBg"
            bg.zPosition = 101
            hudNode.addChild(bg)
        }
        if let existing = hudNode.childNode(withName: "ageProgressFill") as? SKShapeNode {
            let fillWidth = barWidth * progress
            existing.path = CGPath(rect: CGRect(x: -barWidth / 2, y: -2, width: fillWidth, height: 4), transform: nil)
        } else {
            let fill = SKShapeNode(rectOf: CGSize(width: 1, height: 4))
            fill.fillColor = .cyan
            fill.strokeColor = .clear
            fill.position = CGPoint(x: viewSize.width - 120, y: viewSize.height - 50)
            fill.name = "ageProgressFill"
            fill.zPosition = 102
            hudNode.addChild(fill)
        }
    }

    private func removeAgeProgressBar() {
        hudNode.childNode(withName: "ageProgressBg")?.removeFromParent()
        hudNode.childNode(withName: "ageProgressFill")?.removeFromParent()
    }

    func updateMinimap(players: [Player], map: GameMap, cameraPos: CGPoint, viewSize: CGSize) {
        minimapDots.removeAllChildren()

        let scaleX = (minimapSize - 10) / CGFloat(map.width)
        let scaleY = (minimapSize - 10) / CGFloat(map.height)

        // Draw terrain features (sparse)
        let step = max(1, map.width / 30)
        for y in stride(from: 0, to: map.height, by: step) {
            for x in stride(from: 0, to: map.width, by: step) {
                let tile = map.tiles[y][x]
                let dotSize = CGSize(width: max(2, scaleX * CGFloat(step)),
                                     height: max(2, scaleY * CGFloat(step)))
                let dotPos = CGPoint(
                    x: CGFloat(x) * scaleX - minimapSize / 2 + 5,
                    y: CGFloat(y) * scaleY - minimapSize / 2 + 5
                )

                if !tile.isExplored {
                    // Unexplored: dark
                    let fog = SKShapeNode(rectOf: dotSize)
                    fog.fillColor = SKColor.black.withAlphaComponent(0.7)
                    fog.strokeColor = .clear
                    fog.position = dotPos
                    minimapDots.addChild(fog)
                } else {
                    // Show terrain with better colors
                    let terrainColor: SKColor
                    switch tile.terrain {
                    case .water, .deepWater: terrainColor = SKColor(red: 0.15, green: 0.3, blue: 0.65, alpha: 0.8)
                    case .forest: terrainColor = SKColor(red: 0.1, green: 0.35, blue: 0.1, alpha: 0.8)
                    case .gold: terrainColor = SKColor(red: 0.85, green: 0.75, blue: 0.15, alpha: 0.9)
                    case .stone: terrainColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.8)
                    case .sand: terrainColor = SKColor(red: 0.7, green: 0.65, blue: 0.45, alpha: 0.5)
                    case .grass: terrainColor = SKColor(red: 0.3, green: 0.5, blue: 0.2, alpha: 0.4)
                    default: terrainColor = tile.terrain.color.withAlphaComponent(0.5)
                    }

                    let dot = SKShapeNode(rectOf: dotSize)
                    dot.fillColor = tile.isVisible ? terrainColor : terrainColor.withAlphaComponent(terrainColor.cgColor.alpha * 0.5)
                    dot.strokeColor = .clear
                    dot.position = dotPos
                    minimapDots.addChild(dot)
                }
            }
        }

        // Draw buildings
        for player in players {
            let color = SpriteFactory.playerColors[player.id % SpriteFactory.playerColors.count]
            for building in player.buildings {
                let dot = SKShapeNode(rectOf: CGSize(width: 4, height: 4))
                dot.fillColor = color
                dot.strokeColor = .clear
                dot.position = CGPoint(
                    x: CGFloat(building.gridPosition.x) * scaleX - minimapSize / 2 + 5,
                    y: CGFloat(building.gridPosition.y) * scaleY - minimapSize / 2 + 5
                )
                minimapDots.addChild(dot)
            }

            // Draw units
            for unit in player.units {
                let dot = SKShapeNode(circleOfRadius: 1.5)
                dot.fillColor = color
                dot.strokeColor = .clear
                dot.position = CGPoint(
                    x: CGFloat(unit.gridPosition.x) * scaleX - minimapSize / 2 + 5,
                    y: CGFloat(unit.gridPosition.y) * scaleY - minimapSize / 2 + 5
                )
                minimapDots.addChild(dot)
            }
        }

        // Update camera view rect
        let camTileX = cameraPos.x / map.tileSize
        let camTileY = cameraPos.y / map.tileSize
        let viewTilesX = viewSize.width / map.tileSize
        let viewTilesY = viewSize.height / map.tileSize

        minimapViewRect.position = CGPoint(
            x: camTileX * scaleX - minimapSize / 2 + 5,
            y: camTileY * scaleY - minimapSize / 2 + 5
        )
        let rectPath = CGPath(rect: CGRect(
            x: -viewTilesX * scaleX / 2,
            y: -viewTilesY * scaleY / 2,
            width: viewTilesX * scaleX,
            height: viewTilesY * scaleY
        ), transform: nil)
        minimapViewRect.path = rectPath
    }

    private func updateSelectionInfo(player: Player) {
        let selected = player.units.filter { $0.isSelected }

        if selected.isEmpty {
            infoPanel.isHidden = true
            updateActionButtons(for: nil, building: nil, player: player)
            return
        }

        infoPanel.isHidden = false

        if selected.count == 1 {
            let unit = selected[0]
            infoNameLabel.text = unit.type.displayName
            infoHPLabel.text = "HP: \(unit.hp)/\(unit.maxHP)"
            infoIcon.fillColor = unit.type.color
            selectionCountLabel.text = ""

            if unit.type == .villager {
                if case .gathering(let rt, _) = unit.state {
                    queueLabel.text = "Gathering \(rt)"
                } else if case .building(_) = unit.state {
                    queueLabel.text = "Building..."
                } else if unit.carriedAmount > 0 {
                    queueLabel.text = "Carrying: \(unit.carriedAmount)"
                } else {
                    queueLabel.text = ""
                }
            } else {
                queueLabel.text = ""
            }

            // Show build button for villagers
            if unit.type == .villager {
                updateActionButtons(for: unit, building: nil, player: player)
            } else {
                updateActionButtons(for: nil, building: nil, player: player)
            }
        } else {
            let first = selected[0]
            infoNameLabel.text = first.type.displayName
            infoHPLabel.text = ""
            infoIcon.fillColor = first.type.color
            selectionCountLabel.text = "\(selected.count) units selected"
            queueLabel.text = ""

            if selected.allSatisfy({ $0.type == .villager }) {
                updateActionButtons(for: first, building: nil, player: player)
            } else {
                updateActionButtons(for: nil, building: nil, player: player)
            }
        }
    }

    func showBuildingInfo(building: Building, player: Player) {
        infoPanel.isHidden = false
        infoNameLabel.text = building.type.displayName
        infoHPLabel.text = "HP: \(building.hp)/\(building.maxHP)"
        infoIcon.fillColor = building.type.color
        selectionCountLabel.text = ""

        if !building.trainingQueue.isEmpty {
            let queueText = building.trainingQueue.map { $0.icon }.joined(separator: " ")
            let progress = Int(building.trainingProgress * 100)
            queueLabel.text = "Training: \(queueText) (\(progress)%)"
        } else if !building.isConstructed {
            let progress = Int(building.constructionProgress * 100)
            queueLabel.text = "Building: \(progress)%"
        } else {
            queueLabel.text = ""
        }

        updateActionButtons(for: nil, building: building, player: player)
    }

    private func updateActionButtons(for unit: Unit?, building: Building?, player: Player) {
        // Clear existing buttons
        for btn in actionButtons {
            btn.removeFromParent()
        }
        actionButtons.removeAll()

        let panelWidth: CGFloat = 280
        let buttonSize: CGFloat = 54
        let padding: CGFloat = 8
        let cols = 4
        let startX = -panelWidth / 2 + buttonSize / 2 + padding
        let startY: CGFloat = 40

        if let unit = unit, unit.type == .villager {
            // Build button
            let buildBtn = createActionButton(
                text: "Build", icon: "B",
                color: SKColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1.0),
                name: "btn_build",
                x: startX, y: startY, size: buttonSize)
            actionPanel.addChild(buildBtn)
            actionButtons.append(buildBtn)
        }

        if let building = building, building.isConstructed {
            // Show trainable units
            for (i, unitType) in building.type.trainableUnits.enumerated() {
                guard player.currentAge.rawValue >= unitType.requiredAge.rawValue else { continue }

                let col = i % cols
                let row = i / cols
                let x = startX + CGFloat(col) * (buttonSize + padding)
                let y = startY - CGFloat(row) * (buttonSize + padding)

                let costText = formatCost(unitType.cost)
                let btn = createActionButton(
                    text: unitType.displayName, icon: unitType.icon,
                    color: unitType.color,
                    name: "train_\(unitType)",
                    x: x, y: y, size: buttonSize,
                    subtitle: costText,
                    enabled: player.canAfford(unitType.cost))
                actionPanel.addChild(btn)
                actionButtons.append(btn)
            }

            // Rally point button for production buildings
            if !building.type.trainableUnits.isEmpty {
                let rallyBtn = createActionButton(
                    text: "Rally", icon: "R",
                    color: SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0),
                    name: "btn_rally",
                    x: startX + CGFloat(min(building.type.trainableUnits.count, cols)) * (buttonSize + padding),
                    y: startY, size: buttonSize)
                actionPanel.addChild(rallyBtn)
                actionButtons.append(rallyBtn)
            }
        }
    }

    private func createActionButton(text: String, icon: String, color: SKColor,
                                     name: String, x: CGFloat, y: CGFloat, size: CGFloat,
                                     subtitle: String = "", enabled: Bool = true) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: x, y: y)
        container.name = name
        container.alpha = enabled ? 1.0 : 0.4

        let bg = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 4)
        bg.fillColor = color.withAlphaComponent(0.7)
        bg.strokeColor = enabled ? .white : .gray
        bg.lineWidth = 1
        bg.name = name
        container.addChild(bg)

        let iconLabel = SKLabelNode(text: icon)
        iconLabel.fontSize = size * 0.35
        iconLabel.fontName = "Helvetica-Bold"
        iconLabel.fontColor = .white
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 0, y: subtitle.isEmpty ? 0 : 6)
        iconLabel.name = name
        container.addChild(iconLabel)

        if !subtitle.isEmpty {
            let subLabel = SKLabelNode(text: subtitle)
            subLabel.fontSize = 10
            subLabel.fontName = "Helvetica"
            subLabel.fontColor = .lightGray
            subLabel.verticalAlignmentMode = .center
            subLabel.position = CGPoint(x: 0, y: -size * 0.3)
            subLabel.name = name
            container.addChild(subLabel)
        }

        return container
    }

    // MARK: - Build Menu

    func showBuildMenu(player: Player) {
        isBuildMenuOpen = true
        buildMenuNode.isHidden = false
        buildMenuNode.removeAllChildren()

        let bg = SKShapeNode(rectOf: CGSize(width: 420, height: 280), cornerRadius: 8)
        bg.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
        bg.lineWidth = 2
        bg.name = "buildMenuBg"
        buildMenuNode.addChild(bg)

        let title = SKLabelNode(text: "Build Menu")
        title.fontSize = 18
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        title.position = CGPoint(x: 0, y: 110)
        buildMenuNode.addChild(title)

        let buildingTypes: [BuildingType] = [
            .house, .farm, .lumberCamp, .miningCamp,
            .barracks, .archeryRange, .stable, .blacksmith,
            .market, .tower, .wall, .castle
        ]

        let buttonSize: CGFloat = 66
        let padding: CGFloat = 10
        let cols = 4
        let startX = -CGFloat(cols) * (buttonSize + padding) / 2 + buttonSize / 2
        let startY: CGFloat = 60

        for (i, buildingType) in buildingTypes.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = startX + CGFloat(col) * (buttonSize + padding)
            let y = startY - CGFloat(row) * (buttonSize + padding)

            let available = player.currentAge.rawValue >= buildingType.requiredAge.rawValue
            let affordable = player.canAfford(buildingType.cost)
            let enabled = available && affordable

            let btn = createBuildButton(
                type: buildingType,
                x: x, y: y, size: buttonSize,
                enabled: enabled)
            buildMenuNode.addChild(btn)
        }

        // Close button
        let closeBtn = SKNode()
        closeBtn.position = CGPoint(x: 190, y: 110)
        closeBtn.name = "closeBuildMenu"

        let closeBg = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 3)
        closeBg.fillColor = SKColor(red: 0.6, green: 0.15, blue: 0.1, alpha: 0.9)
        closeBg.strokeColor = .white
        closeBg.lineWidth = 1
        closeBg.name = "closeBuildMenu"
        closeBtn.addChild(closeBg)

        let closeLabel = SKLabelNode(text: "X")
        closeLabel.fontSize = 14
        closeLabel.fontName = "Helvetica-Bold"
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.name = "closeBuildMenu"
        closeBtn.addChild(closeLabel)

        buildMenuNode.addChild(closeBtn)
    }

    private func createBuildButton(type: BuildingType, x: CGFloat, y: CGFloat,
                                    size: CGFloat, enabled: Bool) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: x, y: y)
        container.name = "build_\(type)"
        container.alpha = enabled ? 1.0 : 0.35

        let bg = SKShapeNode(rectOf: CGSize(width: size, height: size), cornerRadius: 4)
        bg.fillColor = type.color.withAlphaComponent(0.6)
        bg.strokeColor = enabled ? SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0) : .gray
        bg.lineWidth = enabled ? 1.5 : 1
        bg.name = "build_\(type)"
        container.addChild(bg)

        let iconLabel = SKLabelNode(text: type.icon)
        iconLabel.fontSize = size * 0.3
        iconLabel.fontName = "Helvetica-Bold"
        iconLabel.fontColor = .white
        iconLabel.verticalAlignmentMode = .center
        iconLabel.position = CGPoint(x: 0, y: 8)
        iconLabel.name = "build_\(type)"
        container.addChild(iconLabel)

        let nameLabel = SKLabelNode(text: type.displayName)
        nameLabel.fontSize = 10
        nameLabel.fontName = "Helvetica"
        nameLabel.fontColor = .lightGray
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: -14)
        nameLabel.name = "build_\(type)"
        container.addChild(nameLabel)

        let costLabel = SKLabelNode(text: formatCost(type.cost))
        costLabel.fontSize = 9
        costLabel.fontName = "Helvetica"
        costLabel.fontColor = .gray
        costLabel.verticalAlignmentMode = .center
        costLabel.position = CGPoint(x: 0, y: -22)
        costLabel.name = "build_\(type)"
        container.addChild(costLabel)

        return container
    }

    func hideBuildMenu() {
        isBuildMenuOpen = false
        buildMenuNode.isHidden = true
    }

    var isBuildMenuShowing: Bool { isBuildMenuOpen }

    // MARK: - Status Messages

    func showStatus(_ message: String, duration: CGFloat = 3.0) {
        statusLabel.text = message
        statusLabel.removeAllActions()
        statusLabel.alpha = 1.0
        statusLabel.run(SKAction.sequence([
            SKAction.wait(forDuration: TimeInterval(duration)),
            SKAction.fadeOut(withDuration: 0.5)
        ]))
    }

    func showGameOver(victory: Bool, player: Player? = nil) {
        let overlay = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: viewSize.height))
        overlay.fillColor = SKColor.black.withAlphaComponent(0.8)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        overlay.zPosition = 200
        hudNode.addChild(overlay)

        let text = victory ? "VICTORY!" : "DEFEAT"
        let color: SKColor = victory ? .yellow : .red

        let label = SKLabelNode(text: text)
        label.fontSize = 60
        label.fontName = "Helvetica-Bold"
        label.fontColor = color
        label.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 60)
        label.zPosition = 201
        // Entrance animation
        label.setScale(0.1)
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))
        hudNode.addChild(label)

        // Stats
        if let player = player {
            let stats = [
                "Age: \(player.currentAge.displayName)",
                "Units: \(player.units.count)  Buildings: \(player.buildings.count)",
                "Resources: F:\(player.resources.food) W:\(player.resources.wood) G:\(player.resources.gold) S:\(player.resources.stone)"
            ]
            for (i, stat) in stats.enumerated() {
                let statLabel = SKLabelNode(text: stat)
                statLabel.fontSize = 14
                statLabel.fontName = "Helvetica"
                statLabel.fontColor = .lightGray
                statLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 15 - CGFloat(i) * 20)
                statLabel.zPosition = 201
                hudNode.addChild(statLabel)
            }
        }

        let exitLabel = SKLabelNode(text: "Tap to return to menu")
        exitLabel.fontSize = 20
        exitLabel.fontName = "Helvetica"
        exitLabel.fontColor = .white
        exitLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 - 30)
        exitLabel.zPosition = 201
        exitLabel.name = "gameOverExit"
        hudNode.addChild(exitLabel)
    }

    // MARK: - Touch Handling

    func handleTouch(at point: CGPoint) -> HUDAction? {
        let nodes = hudNode.nodes(at: point)

        for node in nodes {
            guard let name = node.name else { continue }

            if name == "pauseBtn" { return .pause }
            if name == "exitBtn" { return .exit }
            if name == "ageUpBtn" { return .ageUp }
            if name == "helpBtn" { return .showHelp }
            if name == "deselectBtn" { return .deselect }
            if name == "btn_build" { return .openBuildMenu }
            if name == "btn_rally" { return .setRallyPoint }
            if name == "closeBuildMenu" { return .closeBuildMenu }
            if name == "gameOverExit" { return .exit }

            if name.hasPrefix("build_") {
                let typeStr = String(name.dropFirst(6))
                if let buildingType = parseBuildingType(typeStr) {
                    return .selectBuilding(buildingType)
                }
            }

            if name.hasPrefix("train_") {
                let typeStr = String(name.dropFirst(6))
                if let unitType = parseUnitType(typeStr) {
                    return .trainUnit(unitType)
                }
            }
        }

        // Check minimap tap
        let minimapFrame = CGRect(
            x: 10, y: 10,
            width: minimapSize, height: minimapSize
        )
        if minimapFrame.contains(point) {
            return .minimapTap(point)
        }

        return nil
    }

    func isPointInHUD(_ point: CGPoint) -> Bool {
        // Top resource bar
        if point.y > viewSize.height - 40 { return true }
        // Bottom minimap
        if point.x < minimapSize + 20 && point.y < minimapSize + 20 { return true }
        // Action panel
        if point.x > viewSize.width - 300 && point.y < 180 { return true }
        // Info panel
        if point.x > minimapSize + 20 && point.x < minimapSize + 250 && point.y < 180 { return true }
        // Build menu
        if isBuildMenuOpen { return true }
        return false
    }

    // MARK: - Helpers

    private func formatCost(_ cost: Resources) -> String {
        var parts: [String] = []
        if cost.food > 0 { parts.append("F:\(cost.food)") }
        if cost.wood > 0 { parts.append("W:\(cost.wood)") }
        if cost.gold > 0 { parts.append("G:\(cost.gold)") }
        if cost.stone > 0 { parts.append("S:\(cost.stone)") }
        return parts.joined(separator: " ")
    }

    private func parseBuildingType(_ str: String) -> BuildingType? {
        BuildingType.allCases.first { "\($0)" == str }
    }

    private func parseUnitType(_ str: String) -> UnitType? {
        UnitType.allCases.first { "\($0)" == str }
    }

    func minimapToWorld(point: CGPoint, map: GameMap) -> CGPoint {
        let relX = (point.x - 10) / minimapSize
        let relY = (point.y - 10) / minimapSize
        return CGPoint(
            x: relX * CGFloat(map.width) * map.tileSize,
            y: relY * CGFloat(map.height) * map.tileSize
        )
    }
}

// MARK: - HUD Action

enum HUDAction {
    case pause
    case exit
    case ageUp
    case showHelp
    case deselect
    case openBuildMenu
    case closeBuildMenu
    case selectBuilding(BuildingType)
    case trainUnit(UnitType)
    case setRallyPoint
    case minimapTap(CGPoint)
}
