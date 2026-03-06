import SpriteKit

class HUDOverlay {
    weak var gameScene: GameScene?
    let hudNode: SKNode
    let viewSize: CGSize

    // Responsive layout flag
    let isCompact: Bool
    let uiScale: CGFloat

    // Resource bar
    private var foodLabel: SKLabelNode!
    private var woodLabel: SKLabelNode!
    private var goldLabel: SKLabelNode!
    private var stoneLabel: SKLabelNode!
    private var popLabel: SKLabelNode!
    private var ageLabel: SKLabelNode!

    // Minimap
    private var minimapNode: SKShapeNode!
    private var minimapSize: CGFloat
    private var minimapDots: SKNode!
    private var minimapViewRect: SKShapeNode!

    // Action panel
    private var actionPanel: SKNode!
    private var actionButtons: [SKNode] = []
    private var actionPanelWidth: CGFloat
    private var actionPanelHeight: CGFloat

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
    private var helpButton: SKNode!

    // Help overlay
    private var helpOverlayNode: SKNode!
    private var isHelpShowing = false

    init(viewSize: CGSize) {
        self.viewSize = viewSize
        self.isCompact = viewSize.height < 500
        self.uiScale = isCompact ? 0.7 : 1.0

        self.minimapSize = isCompact ? 90 : 150
        self.actionPanelWidth = isCompact ? 180 : 280
        self.actionPanelHeight = isCompact ? 100 : 160

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
        setupDeselectButton()
        setupHelpOverlay()
    }

    // MARK: - Setup

    private func setupResourceBar() {
        let barHeight: CGFloat = isCompact ? 30 : 38
        let bar = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: barHeight), cornerRadius: 0)
        bar.fillColor = SKColor(red: 0.08, green: 0.06, blue: 0.03, alpha: 0.92)
        bar.strokeColor = .clear
        bar.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - barHeight / 2)
        hudNode.addChild(bar)

        // Gold trim line at bottom of bar
        let trimLine = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: 1.5))
        trimLine.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 0.7)
        trimLine.strokeColor = .clear
        trimLine.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - barHeight)
        hudNode.addChild(trimLine)

        let startX: CGFloat = isCompact ? 16 : 25
        let spacing: CGFloat = isCompact ? 78 : 130
        let emojiSize: CGFloat = isCompact ? 12 : 16
        let fontSize: CGFloat = isCompact ? 11 : 15
        let y = viewSize.height - barHeight / 2

        // Food
        let foodIcon = createResourceEmojiIcon(emoji: "\u{1F34E}", x: startX, y: y, size: emojiSize)
        hudNode.addChild(foodIcon)
        foodLabel = createLabel(x: startX + emojiSize + 4, y: y, fontSize: fontSize)
        hudNode.addChild(foodLabel)

        // Wood
        let woodIcon = createResourceEmojiIcon(emoji: "\u{1FAB5}", x: startX + spacing, y: y, size: emojiSize)
        hudNode.addChild(woodIcon)
        woodLabel = createLabel(x: startX + spacing + emojiSize + 4, y: y, fontSize: fontSize)
        hudNode.addChild(woodLabel)

        // Gold
        let goldIcon = createResourceEmojiIcon(emoji: "\u{1FA99}", x: startX + spacing * 2, y: y, size: emojiSize)
        hudNode.addChild(goldIcon)
        goldLabel = createLabel(x: startX + spacing * 2 + emojiSize + 4, y: y, fontSize: fontSize)
        hudNode.addChild(goldLabel)

        // Stone
        let stoneIcon = createResourceEmojiIcon(emoji: "\u{1FAA8}", x: startX + spacing * 3, y: y, size: emojiSize)
        hudNode.addChild(stoneIcon)
        stoneLabel = createLabel(x: startX + spacing * 3 + emojiSize + 4, y: y, fontSize: fontSize)
        hudNode.addChild(stoneLabel)

        // Population
        let popIcon = createResourceEmojiIcon(emoji: "\u{1F465}", x: startX + spacing * 4, y: y, size: emojiSize)
        hudNode.addChild(popIcon)
        popLabel = createLabel(x: startX + spacing * 4 + emojiSize + 4, y: y, fontSize: fontSize)
        hudNode.addChild(popLabel)

        // Age display with crown
        ageLabel = SKLabelNode(text: "\u{1F451} Dark Age")
        ageLabel.fontSize = isCompact ? 11 : 14
        ageLabel.fontName = "Helvetica-Bold"
        ageLabel.fontColor = SKColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1.0)
        ageLabel.position = CGPoint(x: viewSize.width - (isCompact ? 80 : 120), y: y - 5)
        ageLabel.horizontalAlignmentMode = .center
        hudNode.addChild(ageLabel)
    }

    private func createResourceEmojiIcon(emoji: String, x: CGFloat, y: CGFloat, size: CGFloat) -> SKNode {
        let label = SKLabelNode(text: emoji)
        label.fontSize = size
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.position = CGPoint(x: x, y: y)
        return label
    }

    private func createLabel(x: CGFloat, y: CGFloat, fontSize: CGFloat = 14) -> SKLabelNode {
        let label = SKLabelNode(text: "0")
        label.fontSize = fontSize
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.horizontalAlignmentMode = .left
        label.verticalAlignmentMode = .center
        label.position = CGPoint(x: x, y: y)
        return label
    }

    private func setupMinimap() {
        let padding: CGFloat = isCompact ? 6 : 10
        minimapNode = SKShapeNode(rectOf: CGSize(width: minimapSize, height: minimapSize), cornerRadius: 4)
        minimapNode.fillColor = SKColor(red: 0.08, green: 0.12, blue: 0.05, alpha: 0.9)
        minimapNode.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
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
        let padding: CGFloat = isCompact ? 6 : 10

        actionPanel = SKNode()
        actionPanel.position = CGPoint(x: viewSize.width - actionPanelWidth / 2 - padding,
                                        y: padding + actionPanelHeight / 2)

        let bg = SKShapeNode(rectOf: CGSize(width: actionPanelWidth, height: actionPanelHeight), cornerRadius: 6)
        bg.fillColor = SKColor(red: 0.08, green: 0.06, blue: 0.03, alpha: 0.92)
        bg.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 0.8)
        bg.lineWidth = 2
        bg.name = "actionPanelBg"
        actionPanel.addChild(bg)

        hudNode.addChild(actionPanel)
    }

    private func setupInfoPanel() {
        let infoPanelWidth: CGFloat = isCompact ? 150 : 220
        let infoPanelHeight: CGFloat = isCompact ? 100 : 160
        let padding: CGFloat = isCompact ? 6 : 10
        let minimapRightEdge: CGFloat = padding + minimapSize + padding

        infoPanel = SKNode()
        infoPanel.position = CGPoint(x: minimapRightEdge + infoPanelWidth / 2,
                                      y: padding + infoPanelHeight / 2)

        let bg = SKShapeNode(rectOf: CGSize(width: infoPanelWidth, height: infoPanelHeight), cornerRadius: 6)
        bg.fillColor = SKColor(red: 0.08, green: 0.06, blue: 0.03, alpha: 0.92)
        bg.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 0.8)
        bg.lineWidth = 2
        infoPanel.addChild(bg)

        let iconRadius: CGFloat = isCompact ? 14 : 20
        infoIcon = SKShapeNode(circleOfRadius: iconRadius)
        infoIcon.fillColor = .gray
        infoIcon.strokeColor = .white
        infoIcon.position = CGPoint(x: -infoPanelWidth / 2 + iconRadius + 10, y: isCompact ? 12 : 20)
        infoPanel.addChild(infoIcon)

        infoNameLabel = SKLabelNode(text: "")
        infoNameLabel.fontSize = isCompact ? 11 : 14
        infoNameLabel.fontName = "Helvetica-Bold"
        infoNameLabel.fontColor = .white
        infoNameLabel.position = CGPoint(x: isCompact ? 0 : 10, y: isCompact ? 22 : 30)
        infoNameLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(infoNameLabel)

        infoHPLabel = SKLabelNode(text: "")
        infoHPLabel.fontSize = isCompact ? 9 : 12
        infoHPLabel.fontName = "Helvetica"
        infoHPLabel.fontColor = .lightGray
        infoHPLabel.position = CGPoint(x: isCompact ? 0 : 10, y: isCompact ? 6 : 10)
        infoHPLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(infoHPLabel)

        queueLabel = SKLabelNode(text: "")
        queueLabel.fontSize = isCompact ? 9 : 11
        queueLabel.fontName = "Helvetica"
        queueLabel.fontColor = .cyan
        queueLabel.position = CGPoint(x: -infoPanelWidth / 2 + 10, y: isCompact ? -12 : -20)
        queueLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(queueLabel)

        selectionCountLabel = SKLabelNode(text: "")
        selectionCountLabel.fontSize = isCompact ? 9 : 12
        selectionCountLabel.fontName = "Helvetica"
        selectionCountLabel.fontColor = .yellow
        selectionCountLabel.position = CGPoint(x: -infoPanelWidth / 2 + 10, y: isCompact ? -26 : -40)
        selectionCountLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(selectionCountLabel)

        infoPanel.isHidden = true
        hudNode.addChild(infoPanel)
    }

    private func setupBuildMenu() {
        buildMenuNode = SKNode()
        buildMenuNode.isHidden = true
        buildMenuNode.zPosition = 110

        let menuW: CGFloat = isCompact ? 300 : 400
        let menuH: CGFloat = isCompact ? 200 : 250
        let bg = SKShapeNode(rectOf: CGSize(width: menuW, height: menuH))
        bg.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
        bg.lineWidth = 2
        bg.name = "buildMenuBg"
        buildMenuNode.addChild(bg)

        let title = SKLabelNode(text: "Build Menu")
        title.fontSize = isCompact ? 13 : 16
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        title.position = CGPoint(x: 0, y: isCompact ? 75 : 100)
        buildMenuNode.addChild(title)

        buildMenuNode.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        hudNode.addChild(buildMenuNode)
    }

    private func setupStatusLabel() {
        // Status background pill
        let statusBg = SKShapeNode(rectOf: CGSize(width: isCompact ? 250 : 350, height: isCompact ? 22 : 28), cornerRadius: isCompact ? 11 : 14)
        statusBg.fillColor = SKColor.black.withAlphaComponent(0.65)
        statusBg.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 0.5)
        statusBg.lineWidth = 1
        statusBg.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - (isCompact ? 46 : 62))
        statusBg.zPosition = 119
        statusBg.alpha = 0
        statusBg.name = "statusBg"
        hudNode.addChild(statusBg)

        statusLabel = SKLabelNode(text: "")
        statusLabel.fontSize = isCompact ? 13 : 16
        statusLabel.fontName = "Helvetica-Bold"
        statusLabel.fontColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 1.0)
        statusLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - (isCompact ? 50 : 67))
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.zPosition = 120
        hudNode.addChild(statusLabel)
    }

    private func setupGameButtons() {
        let barHeight: CGFloat = isCompact ? 28 : 36
        let btnY = viewSize.height - barHeight

        // Pause button
        pauseButton = createHUDButton(text: "||", x: viewSize.width - 45, y: btnY, name: "pauseBtn")
        hudNode.addChild(pauseButton)

        // Exit button
        exitButton = createHUDButton(text: "X", x: viewSize.width - 15, y: btnY, name: "exitBtn")
        hudNode.addChild(exitButton)

        // Age up button
        ageUpButton = createHUDButton(text: "AGE UP", x: viewSize.width - (isCompact ? 150 : 200), y: btnY, name: "ageUpBtn", width: isCompact ? 50 : 60)
        hudNode.addChild(ageUpButton)
    }

    private func setupDeselectButton() {
        // Floating deselect button - shown when units/buildings are selected
        let btnSize: CGFloat = isCompact ? 36 : 44
        deselectButton = SKNode()
        deselectButton.name = "deselectBtn"
        deselectButton.position = CGPoint(x: viewSize.width - btnSize / 2 - (isCompact ? 8 : 12),
                                           y: viewSize.height / 2)
        deselectButton.isHidden = true
        deselectButton.zPosition = 105

        let bg = SKShapeNode(circleOfRadius: btnSize / 2)
        bg.fillColor = SKColor(red: 0.6, green: 0.15, blue: 0.1, alpha: 0.85)
        bg.strokeColor = SKColor(red: 0.9, green: 0.7, blue: 0.4, alpha: 0.9)
        bg.lineWidth = 2
        bg.name = "deselectBtn"
        deselectButton.addChild(bg)

        let xLabel = SKLabelNode(text: "\u{2716}")
        xLabel.fontSize = isCompact ? 16 : 20
        xLabel.fontName = "Helvetica-Bold"
        xLabel.fontColor = .white
        xLabel.verticalAlignmentMode = .center
        xLabel.name = "deselectBtn"
        deselectButton.addChild(xLabel)

        let hint = SKLabelNode(text: "Deselect")
        hint.fontSize = isCompact ? 7 : 9
        hint.fontName = "Helvetica"
        hint.fontColor = .lightGray
        hint.verticalAlignmentMode = .top
        hint.position = CGPoint(x: 0, y: -btnSize / 2 - 2)
        hint.name = "deselectBtn"
        deselectButton.addChild(hint)

        hudNode.addChild(deselectButton)
    }

    private func setupHelpOverlay() {
        // Help/? button in top bar
        let barHeight: CGFloat = isCompact ? 28 : 36
        let btnY = viewSize.height - barHeight
        helpButton = createHUDButton(text: "?", x: viewSize.width - 75, y: btnY, name: "helpBtn")
        hudNode.addChild(helpButton)

        // Help overlay (initially hidden)
        helpOverlayNode = SKNode()
        helpOverlayNode.isHidden = true
        helpOverlayNode.zPosition = 200

        let overlayBg = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: viewSize.height))
        overlayBg.fillColor = SKColor.black.withAlphaComponent(0.8)
        overlayBg.strokeColor = .clear
        overlayBg.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        overlayBg.name = "closeHelp"
        helpOverlayNode.addChild(overlayBg)

        let panelW: CGFloat = isCompact ? viewSize.width * 0.85 : min(500, viewSize.width * 0.7)
        let panelH: CGFloat = isCompact ? viewSize.height * 0.85 : min(420, viewSize.height * 0.7)
        let panel = SKShapeNode(rectOf: CGSize(width: panelW, height: panelH), cornerRadius: 12)
        panel.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.07, alpha: 0.97)
        panel.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.25, alpha: 1.0)
        panel.lineWidth = 2
        panel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        panel.name = "closeHelp"
        helpOverlayNode.addChild(panel)

        let titleFontSize: CGFloat = isCompact ? 16 : 22
        let bodyFontSize: CGFloat = isCompact ? 9 : 12
        let sectionFontSize: CGFloat = isCompact ? 11 : 14
        let lineSpacing: CGFloat = isCompact ? 14 : 18
        let sectionSpacing: CGFloat = isCompact ? 20 : 26
        let centerX = viewSize.width / 2
        var yPos = viewSize.height / 2 + panelH / 2 - (isCompact ? 25 : 35)

        // Title
        let title = SKLabelNode(text: "How to Play - Realm of Empires")
        title.fontSize = titleFontSize
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.9, green: 0.75, blue: 0.35, alpha: 1.0)
        title.position = CGPoint(x: centerX, y: yPos)
        title.horizontalAlignmentMode = .center
        helpOverlayNode.addChild(title)
        yPos -= sectionSpacing

        let helpLines: [(String, String, Bool)] = [
            ("CONTROLS", "", true),
            ("\u{1F446} Tap unit/building", "Select it", false),
            ("\u{1F446} Tap empty ground", "Deselect all (or use \u{2716} button)", false),
            ("\u{1F446} Tap ground with units selected", "Move units there", false),
            ("\u{270B} Drag", "Pan camera", false),
            ("\u{1F91C} Pinch", "Zoom in/out", false),
            ("\u{25A1} Drag from empty space", "Box-select multiple units", false),
            ("", "", false),
            ("GAMEPLAY", "", true),
            ("\u{1F477} Villagers", "Gather resources (tap resource tile), build structures", false),
            ("\u{2694}\u{FE0F} Military units", "Tap enemy to attack, auto-attack nearby foes", false),
            ("\u{1F3D7}\u{FE0F} Building", "Select villager \u{2192} Build btn \u{2192} pick building \u{2192} tap to place", false),
            ("\u{1F393} Age Up", "Spend resources to unlock new buildings & units", false),
            ("\u{1F3C1} Win condition", "Destroy all enemy buildings and units", false),
            ("", "", false),
            ("RESOURCES", "", true),
            ("\u{1F34E} Food", "From berries, farms  \u{1F333} Wood: From forests", false),
            ("\u{1FA99} Gold", "From gold deposits  \u{1FAA8} Stone: From stone quarries", false),
        ]

        for (left, right, isSection) in helpLines {
            if left.isEmpty {
                yPos -= lineSpacing * 0.3
                continue
            }
            if isSection {
                let sectionLabel = SKLabelNode(text: left)
                sectionLabel.fontSize = sectionFontSize
                sectionLabel.fontName = "Helvetica-Bold"
                sectionLabel.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
                sectionLabel.position = CGPoint(x: centerX - panelW * 0.4, y: yPos)
                sectionLabel.horizontalAlignmentMode = .left
                helpOverlayNode.addChild(sectionLabel)
                // Underline
                let line = SKShapeNode(rectOf: CGSize(width: panelW * 0.8, height: 1))
                line.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 0.5)
                line.strokeColor = .clear
                line.position = CGPoint(x: centerX, y: yPos - 4)
                helpOverlayNode.addChild(line)
            } else {
                let leftLabel = SKLabelNode(text: left)
                leftLabel.fontSize = bodyFontSize
                leftLabel.fontName = "Helvetica-Bold"
                leftLabel.fontColor = .white
                leftLabel.position = CGPoint(x: centerX - panelW * 0.4, y: yPos)
                leftLabel.horizontalAlignmentMode = .left
                helpOverlayNode.addChild(leftLabel)

                let rightLabel = SKLabelNode(text: right)
                rightLabel.fontSize = bodyFontSize
                rightLabel.fontName = "Helvetica"
                rightLabel.fontColor = SKColor(red: 0.75, green: 0.75, blue: 0.7, alpha: 1.0)
                rightLabel.position = CGPoint(x: centerX + panelW * 0.05, y: yPos)
                rightLabel.horizontalAlignmentMode = .left
                helpOverlayNode.addChild(rightLabel)
            }
            yPos -= lineSpacing
        }

        // Close hint
        let closeHint = SKLabelNode(text: "Tap anywhere to close")
        closeHint.fontSize = isCompact ? 10 : 13
        closeHint.fontName = "Helvetica"
        closeHint.fontColor = SKColor.gray
        closeHint.position = CGPoint(x: centerX, y: viewSize.height / 2 - panelH / 2 + (isCompact ? 10 : 16))
        closeHint.horizontalAlignmentMode = .center
        closeHint.name = "closeHelp"
        helpOverlayNode.addChild(closeHint)

        hudNode.addChild(helpOverlayNode)
    }

    func showHelp() {
        isHelpShowing = true
        helpOverlayNode.isHidden = false
    }

    func hideHelp() {
        isHelpShowing = false
        helpOverlayNode.isHidden = true
    }

    var isHelpVisible: Bool { isHelpShowing }

    func updateDeselectButton(hasSelection: Bool) {
        deselectButton.isHidden = !hasSelection
    }

    private func createHUDButton(text: String, x: CGFloat, y: CGFloat, name: String, width: CGFloat = 26) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: x, y: y)
        container.name = name

        let h: CGFloat = isCompact ? 18 : 22
        let bg = SKShapeNode(rectOf: CGSize(width: width, height: h), cornerRadius: 3)
        bg.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.9)
        bg.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        bg.lineWidth = 1
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontSize = isCompact ? 9 : 11
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        return container
    }

    // MARK: - Update

    func update(player: Player) {
        // Update resources
        foodLabel.text = "\(player.resources.food)"
        woodLabel.text = "\(player.resources.wood)"
        goldLabel.text = "\(player.resources.gold)"
        stoneLabel.text = "\(player.resources.stone)"
        popLabel.text = "\(player.population)/\(player.populationCap)"
        ageLabel.text = "\u{1F451} \(player.currentAge.displayName)"

        if player.isAdvancingAge {
            ageLabel.fontColor = .cyan
            ageLabel.text = "\u{231B} Advancing..."
        } else {
            ageLabel.fontColor = SKColor(red: 0.9, green: 0.75, blue: 0.4, alpha: 1.0)
        }

        // Update selection info
        updateSelectionInfo(player: player)
    }

    func updateMinimap(players: [Player], map: GameMap, cameraPos: CGPoint, viewSize: CGSize) {
        minimapDots.removeAllChildren()

        let scaleX = (minimapSize - 10) / CGFloat(map.width)
        let scaleY = (minimapSize - 10) / CGFloat(map.height)

        // Draw terrain features (very sparse to reduce node count)
        let step = max(2, map.width / 15)
        for y in stride(from: 0, to: map.height, by: step) {
            for x in stride(from: 0, to: map.width, by: step) {
                let tile = map.tiles[y][x]
                if tile.terrain == .water || tile.terrain == .deepWater || tile.terrain == .forest {
                    let dot = SKShapeNode(rectOf: CGSize(width: max(2, scaleX * CGFloat(step)),
                                                          height: max(2, scaleY * CGFloat(step))))
                    dot.fillColor = tile.terrain.color.withAlphaComponent(0.6)
                    dot.strokeColor = .clear
                    dot.position = CGPoint(
                        x: CGFloat(x) * scaleX - minimapSize / 2 + 5,
                        y: CGFloat(y) * scaleY - minimapSize / 2 + 5
                    )
                    minimapDots.addChild(dot)
                }
            }
        }

        // Draw buildings and units
        for player in players {
            let color = SpriteFactory.playerColors[player.id % SpriteFactory.playerColors.count]
            for building in player.buildings {
                let dot = SKShapeNode(rectOf: CGSize(width: 3, height: 3))
                dot.fillColor = color
                dot.strokeColor = .clear
                dot.position = CGPoint(
                    x: CGFloat(building.gridPosition.x) * scaleX - minimapSize / 2 + 5,
                    y: CGFloat(building.gridPosition.y) * scaleY - minimapSize / 2 + 5
                )
                minimapDots.addChild(dot)
            }

            for unit in player.units {
                let dot = SKShapeNode(circleOfRadius: 1.0)
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

        let buttonSize: CGFloat = isCompact ? 36 : 50
        let padding: CGFloat = isCompact ? 5 : 8
        let cols = isCompact ? 3 : 4
        let startX = -actionPanelWidth / 2 + buttonSize / 2 + padding
        let startY: CGFloat = isCompact ? 22 : 40

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
            subLabel.fontSize = isCompact ? 6 : 8
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

        let menuW: CGFloat = isCompact ? 310 : 420
        let menuH: CGFloat = isCompact ? 210 : 280
        let bg = SKShapeNode(rectOf: CGSize(width: menuW, height: menuH), cornerRadius: 8)
        bg.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
        bg.lineWidth = 2
        bg.name = "buildMenuBg"
        buildMenuNode.addChild(bg)

        let title = SKLabelNode(text: "Build Menu")
        title.fontSize = isCompact ? 14 : 18
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        title.position = CGPoint(x: 0, y: isCompact ? 82 : 110)
        buildMenuNode.addChild(title)

        let buildingTypes: [BuildingType] = [
            .house, .farm, .lumberCamp, .miningCamp,
            .barracks, .archeryRange, .stable, .blacksmith,
            .market, .tower, .wall, .castle
        ]

        let buttonSize: CGFloat = isCompact ? 44 : 60
        let bPadding: CGFloat = isCompact ? 6 : 10
        let cols = 4
        let startX = -CGFloat(cols) * (buttonSize + bPadding) / 2 + buttonSize / 2
        let startY: CGFloat = isCompact ? 42 : 60

        for (i, buildingType) in buildingTypes.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = startX + CGFloat(col) * (buttonSize + bPadding)
            let y = startY - CGFloat(row) * (buttonSize + bPadding)

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
        let closeBtnX = menuW / 2 - 20
        let closeBtnY: CGFloat = isCompact ? 82 : 110
        let closeBtn = SKNode()
        closeBtn.position = CGPoint(x: closeBtnX, y: closeBtnY)
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
        iconLabel.position = CGPoint(x: 0, y: isCompact ? 5 : 8)
        iconLabel.name = "build_\(type)"
        container.addChild(iconLabel)

        let nameLabel = SKLabelNode(text: type.displayName)
        nameLabel.fontSize = isCompact ? 6 : 8
        nameLabel.fontName = "Helvetica"
        nameLabel.fontColor = .lightGray
        nameLabel.verticalAlignmentMode = .center
        nameLabel.position = CGPoint(x: 0, y: isCompact ? -8 : -12)
        nameLabel.name = "build_\(type)"
        container.addChild(nameLabel)

        let costLabel = SKLabelNode(text: formatCost(type.cost))
        costLabel.fontSize = isCompact ? 5 : 7
        costLabel.fontName = "Helvetica"
        costLabel.fontColor = .gray
        costLabel.verticalAlignmentMode = .center
        costLabel.position = CGPoint(x: 0, y: isCompact ? -16 : -22)
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

        // Animate status background
        if let bg = hudNode.childNode(withName: "statusBg") {
            bg.removeAllActions()
            bg.alpha = message.isEmpty ? 0 : 1.0
            if !message.isEmpty {
                bg.run(SKAction.sequence([
                    SKAction.wait(forDuration: TimeInterval(duration)),
                    SKAction.fadeOut(withDuration: 0.5)
                ]))
            }
        }
    }

    func showGameOver(victory: Bool) {
        let overlay = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: viewSize.height))
        overlay.fillColor = SKColor.black.withAlphaComponent(0.7)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        overlay.zPosition = 200
        hudNode.addChild(overlay)

        let text = victory ? "VICTORY!" : "DEFEAT"
        let color: SKColor = victory ? .yellow : .red

        let label = SKLabelNode(text: text)
        label.fontSize = isCompact ? 40 : 60
        label.fontName = "Helvetica-Bold"
        label.fontColor = color
        label.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 30)
        label.zPosition = 201
        hudNode.addChild(label)

        let exitLabel = SKLabelNode(text: "Tap to return to menu")
        exitLabel.fontSize = isCompact ? 16 : 20
        exitLabel.fontName = "Helvetica"
        exitLabel.fontColor = .white
        exitLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 - 30)
        exitLabel.zPosition = 201
        exitLabel.name = "gameOverExit"
        hudNode.addChild(exitLabel)
    }

    // MARK: - Touch Handling

    func handleTouch(at point: CGPoint) -> HUDAction? {
        // Handle help overlay first
        if isHelpShowing {
            hideHelp()
            return .closeHelp
        }

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
        let mmPadding: CGFloat = isCompact ? 6 : 10
        let minimapFrame = CGRect(
            x: mmPadding, y: mmPadding,
            width: minimapSize, height: minimapSize
        )
        if minimapFrame.contains(point) {
            return .minimapTap(point)
        }

        return nil
    }

    func isPointInHUD(_ point: CGPoint) -> Bool {
        let barHeight: CGFloat = isCompact ? 28 : 40
        let padding: CGFloat = isCompact ? 6 : 10
        // Top resource bar
        if point.y > viewSize.height - barHeight { return true }
        // Bottom minimap
        if point.x < minimapSize + padding * 2 && point.y < minimapSize + padding * 2 { return true }
        // Action panel
        if point.x > viewSize.width - actionPanelWidth - padding * 2 && point.y < actionPanelHeight + padding * 2 { return true }
        // Info panel
        let infoPanelWidth: CGFloat = isCompact ? 150 : 220
        let minimapRightEdge = padding + minimapSize
        if point.x > minimapRightEdge && point.x < minimapRightEdge + infoPanelWidth + padding * 2 && point.y < actionPanelHeight + padding * 2 { return true }
        // Build menu
        if isBuildMenuOpen { return true }
        // Help overlay
        if isHelpShowing { return true }
        // Deselect button (right side, middle)
        if !deselectButton.isHidden {
            let btnSize: CGFloat = isCompact ? 36 : 44
            let btnX = viewSize.width - btnSize / 2 - (isCompact ? 8 : 12)
            let btnY = viewSize.height / 2
            let dist = sqrt(pow(point.x - btnX, 2) + pow(point.y - btnY, 2))
            if dist < btnSize / 2 + 5 { return true }
        }
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
        let padding: CGFloat = isCompact ? 6 : 10
        let relX = (point.x - padding) / minimapSize
        let relY = (point.y - padding) / minimapSize
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
    case openBuildMenu
    case closeBuildMenu
    case selectBuilding(BuildingType)
    case trainUnit(UnitType)
    case setRallyPoint
    case minimapTap(CGPoint)
    case deselect
    case showHelp
    case closeHelp
}
