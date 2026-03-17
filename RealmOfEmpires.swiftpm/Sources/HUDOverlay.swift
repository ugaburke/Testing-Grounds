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

    // Income rate labels
    private var foodIncomeLabel: SKLabelNode!
    private var woodIncomeLabel: SKLabelNode!
    private var goldIncomeLabel: SKLabelNode!
    private var stoneIncomeLabel: SKLabelNode!
    private var previousResources: Resources = Resources()
    private var incomeUpdateTimer: CGFloat = 0

    // Villager allocation label
    private var villagerAllocLabel: SKLabelNode!

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
    private var infoStatsLabel: SKLabelNode!
    private var infoIcon: SKShapeNode!
    private var queueLabel: SKLabelNode!

    // Build menu
    private var buildMenuNode: SKNode!
    private var isBuildMenuOpen = false

    // Tech menu
    private var techMenuNode: SKNode!
    private var isTechMenuOpen = false

    // Selection info
    private var selectionCountLabel: SKLabelNode!

    // Idle villager button
    private var idleVillagerBtn: SKNode!
    private var idleVillagerCountLabel: SKLabelNode!

    // Idle military button
    private var idleMilitaryBtn: SKNode!
    private var idleMilitaryCountLabel: SKLabelNode!

    // Game status
    private var statusLabel: SKLabelNode!
    private var statusBg: SKShapeNode!

    // Event log
    private var eventLogEntries: [SKLabelNode] = []
    private var eventLogBg: SKShapeNode!

    // Mode indicator
    private var modeIndicatorLabel: SKLabelNode!
    private var modeIndicatorBg: SKShapeNode!

    // Buttons
    private var pauseButton: SKNode!
    private var exitButton: SKNode!
    private var ageUpButton: SKNode!
    private var deselectButton: SKNode!
    private var speedButton: SKNode!

    // Exit confirmation
    private var exitConfirmNode: SKNode?
    private var isShowingExitConfirm = false

    // Safe area offset to avoid iOS status bar
    private let safeAreaTop: CGFloat = 50

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
        setupTechMenu()
        setupStatusLabel()
        setupGameButtons()
        setupIdleVillagerButton()
        setupModeIndicator()
        setupVillagerAlloc()
        setupEventLog()
    }

    // MARK: - Setup

    private func setupResourceBar() {
        let barHeight: CGFloat = 36
        let barY = viewSize.height - barHeight / 2 - safeAreaTop
        let bar = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: barHeight))
        bar.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.9)
        bar.strokeColor = SKColor(red: 0.4, green: 0.3, blue: 0.15, alpha: 1.0)
        bar.lineWidth = 1
        bar.position = CGPoint(x: viewSize.width / 2, y: barY)
        hudNode.addChild(bar)

        let startX: CGFloat = 30
        let spacing: CGFloat = 120

        // Food
        let foodIcon = createResourceIcon(color: .red, symbol: "F", x: startX, y: barY)
        hudNode.addChild(foodIcon)
        foodLabel = createLabel(x: startX + 22, y: barY)
        hudNode.addChild(foodLabel)
        foodIncomeLabel = createIncomeLabel(x: startX + 70, y: barY)
        hudNode.addChild(foodIncomeLabel)

        // Wood
        let woodIcon = createResourceIcon(color: .brown, symbol: "W", x: startX + spacing, y: barY)
        hudNode.addChild(woodIcon)
        woodLabel = createLabel(x: startX + spacing + 22, y: barY)
        hudNode.addChild(woodLabel)
        woodIncomeLabel = createIncomeLabel(x: startX + spacing + 70, y: barY)
        hudNode.addChild(woodIncomeLabel)

        // Gold
        let goldIcon = createResourceIcon(color: .yellow, symbol: "G", x: startX + spacing * 2, y: barY)
        hudNode.addChild(goldIcon)
        goldLabel = createLabel(x: startX + spacing * 2 + 22, y: barY)
        hudNode.addChild(goldLabel)
        goldIncomeLabel = createIncomeLabel(x: startX + spacing * 2 + 70, y: barY)
        hudNode.addChild(goldIncomeLabel)

        // Stone
        let stoneIcon = createResourceIcon(color: .gray, symbol: "S", x: startX + spacing * 3, y: barY)
        hudNode.addChild(stoneIcon)
        stoneLabel = createLabel(x: startX + spacing * 3 + 22, y: barY)
        hudNode.addChild(stoneLabel)
        stoneIncomeLabel = createIncomeLabel(x: startX + spacing * 3 + 70, y: barY)
        hudNode.addChild(stoneIncomeLabel)

        // Population
        let popIcon = createResourceIcon(color: .cyan, symbol: "P", x: startX + spacing * 4, y: barY)
        hudNode.addChild(popIcon)
        popLabel = createLabel(x: startX + spacing * 4 + 22, y: barY)
        hudNode.addChild(popLabel)

        // Age
        ageLabel = SKLabelNode(text: "Dark Age")
        ageLabel.fontSize = 14
        ageLabel.fontName = "Helvetica-Bold"
        ageLabel.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        ageLabel.position = CGPoint(x: viewSize.width - 150, y: barY - 5)
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

    private func createIncomeLabel(x: CGFloat, y: CGFloat) -> SKLabelNode {
        let label = SKLabelNode(text: "")
        label.fontSize = 10
        label.fontName = "Helvetica"
        label.fontColor = SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 0.8)
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
        infoHPLabel.fontSize = 13
        infoHPLabel.fontName = "Helvetica-Bold"
        infoHPLabel.fontColor = .white
        infoHPLabel.position = CGPoint(x: 10, y: 12)
        infoHPLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(infoHPLabel)

        infoStatsLabel = SKLabelNode(text: "")
        infoStatsLabel.fontSize = 12
        infoStatsLabel.fontName = "Helvetica-Bold"
        infoStatsLabel.fontColor = SKColor(red: 1.0, green: 0.7, blue: 0.3, alpha: 1.0)
        infoStatsLabel.position = CGPoint(x: 10, y: -6)
        infoStatsLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(infoStatsLabel)

        queueLabel = SKLabelNode(text: "")
        queueLabel.fontSize = 11
        queueLabel.fontName = "Helvetica"
        queueLabel.fontColor = .cyan
        queueLabel.position = CGPoint(x: -panelWidth / 2 + 10, y: -20)
        queueLabel.horizontalAlignmentMode = .left
        infoPanel.addChild(queueLabel)

        selectionCountLabel = SKLabelNode(text: "")
        selectionCountLabel.fontSize = 11
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
        // Background for status messages
        statusBg = SKShapeNode(rectOf: CGSize(width: 300, height: 28), cornerRadius: 6)
        statusBg.fillColor = SKColor.black.withAlphaComponent(0.6)
        statusBg.strokeColor = .clear
        statusBg.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - 62 - safeAreaTop)
        statusBg.zPosition = 119
        statusBg.alpha = 0
        hudNode.addChild(statusBg)

        statusLabel = SKLabelNode(text: "")
        statusLabel.fontSize = 18
        statusLabel.fontName = "Helvetica-Bold"
        statusLabel.fontColor = .yellow
        statusLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - 62 - safeAreaTop)
        statusLabel.horizontalAlignmentMode = .center
        statusLabel.verticalAlignmentMode = .center
        statusLabel.zPosition = 120
        hudNode.addChild(statusLabel)
    }

    private func setupGameButtons() {
        let btnY = viewSize.height - 36 - safeAreaTop

        // Row 1: Game control buttons (right to left, properly spaced)
        // Exit button
        exitButton = createHUDButton(text: "Quit", x: viewSize.width - 30, y: btnY, name: "exitBtn", width: 44)
        hudNode.addChild(exitButton)

        // Pause button
        pauseButton = createHUDButton(text: "Pause", x: viewSize.width - 84, y: btnY, name: "pauseBtn", width: 52)
        hudNode.addChild(pauseButton)

        // Help button
        let helpBtn = createHUDButton(text: "?", x: viewSize.width - 138, y: btnY, name: "helpBtn", width: 44)
        hudNode.addChild(helpBtn)

        // Speed button
        speedButton = createHUDButton(text: "1x", x: viewSize.width - 190, y: btnY, name: "speedBtn", width: 44)
        hudNode.addChild(speedButton)

        // Row 2: Context buttons (right to left, below row 1)
        let btnY2 = viewSize.height - 76 - safeAreaTop

        // Age up button
        ageUpButton = createHUDButton(text: "AGE UP", x: viewSize.width - 48, y: btnY2, name: "ageUpBtn", width: 80)
        hudNode.addChild(ageUpButton)

        // Deselect button
        deselectButton = createHUDButton(text: "Deselect", x: viewSize.width - 127, y: btnY2, name: "deselectBtn", width: 62)
        hudNode.addChild(deselectButton)
    }

    private func setupIdleVillagerButton() {
        let btnY2 = viewSize.height - 76 - safeAreaTop

        // Civ bonuses button (row 2, after deselect)
        let civBtn = SKNode()
        civBtn.position = CGPoint(x: viewSize.width - 178, y: btnY2)
        civBtn.name = "btn_showCivBonuses"

        let civBg = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 4)
        civBg.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.1, alpha: 0.9)
        civBg.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.25, alpha: 1.0)
        civBg.lineWidth = 1
        civBg.name = "btn_showCivBonuses"
        civBtn.addChild(civBg)

        let civIcon = SKLabelNode(text: "\u{2606}")
        civIcon.fontSize = 14
        civIcon.fontName = "Helvetica"
        civIcon.fontColor = SKColor(red: 0.9, green: 0.75, blue: 0.35, alpha: 1)
        civIcon.verticalAlignmentMode = .center
        civIcon.name = "btn_showCivBonuses"
        civBtn.addChild(civIcon)

        hudNode.addChild(civBtn)

        // Scoreboard button (row 2, after civ bonuses)
        let scoreBtn = SKNode()
        scoreBtn.position = CGPoint(x: viewSize.width - 210, y: btnY2)
        scoreBtn.name = "btn_showScoreboard"

        let scoreBg = SKShapeNode(rectOf: CGSize(width: 24, height: 24), cornerRadius: 4)
        scoreBg.fillColor = SKColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 0.9)
        scoreBg.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.6, alpha: 1.0)
        scoreBg.lineWidth = 1
        scoreBg.name = "btn_showScoreboard"
        scoreBtn.addChild(scoreBg)

        let scoreIcon = SKLabelNode(text: "\u{2630}")
        scoreIcon.fontSize = 14
        scoreIcon.fontName = "Helvetica"
        scoreIcon.fontColor = .white
        scoreIcon.verticalAlignmentMode = .center
        scoreIcon.name = "btn_showScoreboard"
        scoreBtn.addChild(scoreIcon)

        hudNode.addChild(scoreBtn)

        // Idle military button (row 2, after scoreboard)
        idleMilitaryBtn = SKNode()
        idleMilitaryBtn.position = CGPoint(x: viewSize.width - 262, y: btnY2)
        idleMilitaryBtn.name = "btn_selectIdleMilitary"
        idleMilitaryBtn.isHidden = true

        let milBg = SKShapeNode(rectOf: CGSize(width: 60, height: 34), cornerRadius: 5)
        milBg.fillColor = SKColor(red: 0.5, green: 0.15, blue: 0.1, alpha: 0.9)
        milBg.strokeColor = SKColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
        milBg.lineWidth = 1.5
        milBg.name = "btn_selectIdleMilitary"
        idleMilitaryBtn.addChild(milBg)

        idleMilitaryCountLabel = SKLabelNode(text: "Mil: 0")
        idleMilitaryCountLabel.fontSize = 12
        idleMilitaryCountLabel.fontName = "Helvetica-Bold"
        idleMilitaryCountLabel.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.5, alpha: 1.0)
        idleMilitaryCountLabel.verticalAlignmentMode = .center
        idleMilitaryCountLabel.name = "btn_selectIdleMilitary"
        idleMilitaryBtn.addChild(idleMilitaryCountLabel)

        hudNode.addChild(idleMilitaryBtn)

        // Idle villager button (row 2, after idle military)
        idleVillagerBtn = SKNode()
        idleVillagerBtn.position = CGPoint(x: viewSize.width - 330, y: btnY2)
        idleVillagerBtn.name = "idleVillagerBtn"
        idleVillagerBtn.isHidden = true

        let bg = SKShapeNode(rectOf: CGSize(width: 60, height: 34), cornerRadius: 5)
        bg.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.1, alpha: 0.9)
        bg.strokeColor = SKColor(red: 0.8, green: 0.7, blue: 0.3, alpha: 1.0)
        bg.lineWidth = 1.5
        bg.name = "idleVillagerBtn"
        idleVillagerBtn.addChild(bg)

        idleVillagerCountLabel = SKLabelNode(text: "Idle: 0")
        idleVillagerCountLabel.fontSize = 12
        idleVillagerCountLabel.fontName = "Helvetica-Bold"
        idleVillagerCountLabel.fontColor = .yellow
        idleVillagerCountLabel.verticalAlignmentMode = .center
        idleVillagerCountLabel.name = "idleVillagerBtn"
        idleVillagerBtn.addChild(idleVillagerCountLabel)

        hudNode.addChild(idleVillagerBtn)
    }

    func updateIdleVillagerCount(player: Player) {
        let idleCount = player.units.filter { unit in
            guard unit.type == .villager else { return false }
            if case .idle = unit.state { return true }
            return false
        }.count
        if idleCount > 0 {
            idleVillagerBtn.isHidden = false
            idleVillagerCountLabel.text = "Idle: \(idleCount)"
            // Pulse effect when idle villagers exist
            if idleVillagerBtn.action(forKey: "pulse") == nil {
                let pulse = SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.6, duration: 0.5),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.5)
                ]))
                idleVillagerBtn.run(pulse, withKey: "pulse")
            }
        } else {
            idleVillagerBtn.isHidden = true
            idleVillagerBtn.removeAction(forKey: "pulse")
            idleVillagerBtn.alpha = 1.0
        }
    }

    func updateIdleMilitaryCount(player: Player) {
        let militaryTypes: Set<UnitType> = [.militia, .manAtArms, .spearman, .knight, .crossbowman,
                                             .skirmisher, .scout, .lightCavalry, .batteringRam, .mangonel,
                                             .archer, .monk, .trebuchet, .warGalley, .fireShip,
                                             .petard, .camelRider, .handCannoneer, .samurai, .warElephant, .mangudai,
                                             .uniqueUnit, .longbowman, .throwingAxeman, .cataphract, .chuKoNu, .berserk]
        let idleMilCount = player.units.filter { unit in
            guard militaryTypes.contains(unit.type) else { return false }
            if case .idle = unit.state { return true }
            return false
        }.count

        if idleMilCount > 0 {
            idleMilitaryBtn.isHidden = false
            idleMilitaryCountLabel.text = "Mil: \(idleMilCount)"
        } else {
            idleMilitaryBtn.isHidden = true
        }
    }

    private func setupModeIndicator() {
        modeIndicatorBg = SKShapeNode(rectOf: CGSize(width: 200, height: 28), cornerRadius: 6)
        modeIndicatorBg.fillColor = SKColor.black.withAlphaComponent(0.7)
        modeIndicatorBg.strokeColor = .clear
        modeIndicatorBg.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - 90 - safeAreaTop)
        modeIndicatorBg.zPosition = 119
        modeIndicatorBg.isHidden = true
        hudNode.addChild(modeIndicatorBg)

        modeIndicatorLabel = SKLabelNode(text: "")
        modeIndicatorLabel.fontSize = 16
        modeIndicatorLabel.fontName = "Helvetica-Bold"
        modeIndicatorLabel.fontColor = .orange
        modeIndicatorLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - 90 - safeAreaTop)
        modeIndicatorLabel.horizontalAlignmentMode = .center
        modeIndicatorLabel.verticalAlignmentMode = .center
        modeIndicatorLabel.zPosition = 120
        modeIndicatorLabel.isHidden = true
        hudNode.addChild(modeIndicatorLabel)
    }

    private func setupVillagerAlloc() {
        villagerAllocLabel = SKLabelNode(text: "")
        villagerAllocLabel.fontSize = 11
        villagerAllocLabel.fontName = "Helvetica"
        villagerAllocLabel.fontColor = SKColor(red: 0.8, green: 0.8, blue: 0.6, alpha: 0.9)
        villagerAllocLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height - 50 - safeAreaTop)
        villagerAllocLabel.horizontalAlignmentMode = .center
        villagerAllocLabel.verticalAlignmentMode = .center
        villagerAllocLabel.zPosition = 101
        hudNode.addChild(villagerAllocLabel)
    }

    private func setupEventLog() {
        eventLogBg = SKShapeNode(rectOf: CGSize(width: 250, height: 80), cornerRadius: 4)
        eventLogBg.fillColor = SKColor.black.withAlphaComponent(0.4)
        eventLogBg.strokeColor = .clear
        eventLogBg.position = CGPoint(x: viewSize.width - 135, y: viewSize.height - 130 - safeAreaTop)
        eventLogBg.zPosition = 99
        eventLogBg.alpha = 0
        hudNode.addChild(eventLogBg)
    }

    private func createHUDButton(text: String, x: CGFloat, y: CGFloat, name: String, width: CGFloat = 44) -> SKNode {
        let container = SKNode()
        container.position = CGPoint(x: x, y: y)
        container.name = name

        let bg = SKShapeNode(rectOf: CGSize(width: width, height: 34), cornerRadius: 5)
        bg.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 0.9)
        bg.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        bg.lineWidth = 1
        bg.name = name
        container.addChild(bg)

        let label = SKLabelNode(text: text)
        label.fontSize = 14
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.name = name
        container.addChild(label)

        return container
    }

    // MARK: - Mode Indicator

    func updateModeIndicator(mode: ActionMode) {
        switch mode {
        case .placingBuilding(let type):
            modeIndicatorLabel.text = "PLACING: \(type.displayName)"
            modeIndicatorLabel.fontColor = .orange
            modeIndicatorLabel.isHidden = false
            modeIndicatorBg.isHidden = false
        case .settingRallyPoint:
            modeIndicatorLabel.text = "SET RALLY POINT"
            modeIndicatorLabel.fontColor = SKColor(red: 0.3, green: 0.7, blue: 1.0, alpha: 1.0)
            modeIndicatorLabel.isHidden = false
            modeIndicatorBg.isHidden = false
        case .attackMove:
            modeIndicatorLabel.text = "ATTACK MOVE"
            modeIndicatorLabel.fontColor = .red
            modeIndicatorLabel.isHidden = false
            modeIndicatorBg.isHidden = false
        case .settingPatrol:
            modeIndicatorLabel.text = "SET PATROL POINT"
            modeIndicatorLabel.fontColor = SKColor(red: 0.3, green: 0.6, blue: 1.0, alpha: 1.0)
            modeIndicatorLabel.isHidden = false
            modeIndicatorBg.isHidden = false
        case .guardMode:
            modeIndicatorLabel.text = "GUARD MODE"
            modeIndicatorLabel.fontColor = SKColor(red: 0.3, green: 0.6, blue: 0.8, alpha: 1.0)
            modeIndicatorLabel.isHidden = false
            modeIndicatorBg.isHidden = false
        case .normal:
            modeIndicatorLabel.isHidden = true
            modeIndicatorBg.isHidden = true
        }
    }

    func addEventLog(_ message: String) {
        let label = SKLabelNode(text: message)
        label.fontSize = 11
        label.fontName = "Helvetica"
        label.fontColor = SKColor(red: 0.9, green: 0.8, blue: 0.6, alpha: 0.9)
        label.horizontalAlignmentMode = .right
        label.position = CGPoint(x: viewSize.width - 20, y: viewSize.height - 110 - safeAreaTop)
        label.zPosition = 100
        hudNode.addChild(label)

        // Shift existing entries up
        for entry in eventLogEntries {
            entry.position.y += 16
        }
        eventLogEntries.append(label)

        // Remove old entries
        while eventLogEntries.count > 4 {
            eventLogEntries[0].removeFromParent()
            eventLogEntries.removeFirst()
        }

        eventLogBg.alpha = 0.5

        // Fade out after delay
        label.run(SKAction.sequence([
            SKAction.wait(forDuration: 8.0),
            SKAction.fadeOut(withDuration: 1.0),
            SKAction.removeFromParent()
        ]))
    }

    func updateIdleMilitaryAlert(player: Player) {
        let idleMilitary = player.units.filter { unit in
            guard unit.type != .villager && unit.type != .monk else { return false }
            if case .idle = unit.state { return true }
            return false
        }

        if idleMilitary.count >= 3 {
            if hudNode.childNode(withName: "idleMilitaryAlert") == nil {
                let alert = SKLabelNode(text: "! \(idleMilitary.count) idle military")
                alert.fontSize = 12
                alert.fontName = "Helvetica-Bold"
                alert.fontColor = SKColor(red: 1.0, green: 0.6, blue: 0.2, alpha: 1.0)
                alert.position = CGPoint(x: viewSize.width - 420, y: viewSize.height - 36 - safeAreaTop)
                alert.horizontalAlignmentMode = .center
                alert.zPosition = 101
                alert.name = "idleMilitaryAlert"

                let pulse = SKAction.repeatForever(SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.5, duration: 0.5),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.5)
                ]))
                alert.run(pulse)
                hudNode.addChild(alert)
            } else if let alert = hudNode.childNode(withName: "idleMilitaryAlert") as? SKLabelNode {
                alert.text = "! \(idleMilitary.count) idle military"
            }
        } else {
            hudNode.childNode(withName: "idleMilitaryAlert")?.removeFromParent()
        }
    }

    // MARK: - Speed Button

    func updateSpeedButton(speed: CGFloat) {
        if let container = speedButton {
            for child in container.children {
                if let label = child as? SKLabelNode {
                    if speed == 1.0 { label.text = "1x" }
                    else if speed == 1.5 { label.text = "1.5x" }
                    else { label.text = "2x" }
                }
            }
        }
    }

    // MARK: - Update

    func update(player: Player) {
        // Update resources with enhanced low-resource warnings
        foodLabel.text = "\(player.resources.food)"
        woodLabel.text = "\(player.resources.wood)"
        goldLabel.text = "\(player.resources.gold)"
        stoneLabel.text = "\(player.resources.stone)"

        applyResourceWarning(label: foodLabel, value: player.resources.food)
        applyResourceWarning(label: woodLabel, value: player.resources.wood)
        applyResourceWarning(label: goldLabel, value: player.resources.gold)
        applyResourceWarning(label: stoneLabel, value: player.resources.stone)

        popLabel.text = "Pop: \(player.population)/\(player.populationCap)"
        let popRatio = player.populationCap > 0 ? CGFloat(player.population) / CGFloat(player.populationCap) : 0
        if player.population >= player.populationCap {
            popLabel.fontColor = .red
            // Pulse when at cap
            if popLabel.action(forKey: "popPulse") == nil {
                let pulse = SKAction.repeatForever(SKAction.sequence([
                    SKAction.run { [weak self] in self?.popLabel.fontColor = .red },
                    SKAction.wait(forDuration: 0.4),
                    SKAction.run { [weak self] in self?.popLabel.fontColor = SKColor(red: 0.6, green: 0, blue: 0, alpha: 1) },
                    SKAction.wait(forDuration: 0.4)
                ]))
                popLabel.run(pulse, withKey: "popPulse")
            }
        } else if popRatio >= 0.9 {
            popLabel.removeAction(forKey: "popPulse")
            popLabel.fontColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0) // Orange warning
        } else {
            popLabel.removeAction(forKey: "popPulse")
            popLabel.fontColor = .white
        }

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

        // Update villager allocation
        updateVillagerAllocation(player: player)

        // Update selection info
        updateSelectionInfo(player: player)
    }

    func updateIncomeRates(player: Player, deltaTime: CGFloat) {
        incomeUpdateTimer += deltaTime
        if incomeUpdateTimer >= 5.0 {
            let foodRate = (player.resources.food - previousResources.food)
            let woodRate = (player.resources.wood - previousResources.wood)
            let goldRate = (player.resources.gold - previousResources.gold)
            let stoneRate = (player.resources.stone - previousResources.stone)

            foodIncomeLabel.text = foodRate >= 0 ? "+\(foodRate / 5)/s" : "\(foodRate / 5)/s"
            woodIncomeLabel.text = woodRate >= 0 ? "+\(woodRate / 5)/s" : "\(woodRate / 5)/s"
            goldIncomeLabel.text = goldRate >= 0 ? "+\(goldRate / 5)/s" : "\(goldRate / 5)/s"
            stoneIncomeLabel.text = stoneRate >= 0 ? "+\(stoneRate / 5)/s" : "\(stoneRate / 5)/s"

            foodIncomeLabel.fontColor = foodRate >= 0 ? SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 0.8) : .red
            woodIncomeLabel.fontColor = woodRate >= 0 ? SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 0.8) : .red
            goldIncomeLabel.fontColor = goldRate >= 0 ? SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 0.8) : .red
            stoneIncomeLabel.fontColor = stoneRate >= 0 ? SKColor(red: 0.4, green: 0.8, blue: 0.4, alpha: 0.8) : .red

            previousResources = Resources(food: player.resources.food, wood: player.resources.wood,
                                           gold: player.resources.gold, stone: player.resources.stone)
            incomeUpdateTimer = 0
        }
    }

    private func updateVillagerAllocation(player: Player) {
        var foodW = 0, woodW = 0, goldW = 0, stoneW = 0, idleW = 0, buildW = 0
        for unit in player.units where unit.type == .villager {
            switch unit.state {
            case .gathering(let rt, _):
                switch rt {
                case .food: foodW += 1
                case .wood: woodW += 1
                case .gold: goldW += 1
                case .stone: stoneW += 1
                }
            case .building: buildW += 1
            case .idle: idleW += 1
            default: break
            }
        }
        let total = foodW + woodW + goldW + stoneW + idleW + buildW
        if total > 0 {
            var parts: [String] = []
            if foodW > 0 { parts.append("Food:\(foodW)") }
            if woodW > 0 { parts.append("Wood:\(woodW)") }
            if goldW > 0 { parts.append("Gold:\(goldW)") }
            if stoneW > 0 { parts.append("Stone:\(stoneW)") }
            if buildW > 0 { parts.append("Build:\(buildW)") }
            if idleW > 0 { parts.append("Idle:\(idleW)") }
            villagerAllocLabel.text = "Villagers: " + parts.joined(separator: "  ")
        } else {
            villagerAllocLabel.text = ""
        }
    }

    private func updateAgeProgressBar(progress: CGFloat) {
        let barWidth: CGFloat = 80
        if hudNode.childNode(withName: "ageProgressBg") == nil {
            let bg = SKShapeNode(rectOf: CGSize(width: barWidth, height: 4))
            bg.fillColor = .darkGray
            bg.strokeColor = .clear
            bg.position = CGPoint(x: viewSize.width - 150, y: viewSize.height - 50 - safeAreaTop)
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
            fill.position = CGPoint(x: viewSize.width - 150, y: viewSize.height - 50 - safeAreaTop)
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
                    let fog = SKShapeNode(rectOf: dotSize)
                    fog.fillColor = SKColor.black.withAlphaComponent(0.7)
                    fog.strokeColor = .clear
                    fog.position = dotPos
                    minimapDots.addChild(fog)
                } else {
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
            infoStatsLabel.text = ""
            updateActionButtons(for: nil, building: nil, player: player)
            return
        }

        infoPanel.isHidden = false

        if selected.count == 1 {
            let unit = selected[0]
            infoNameLabel.text = unit.type.displayName
            infoHPLabel.text = "HP: \(unit.hp)/\(unit.maxHP)"
            let vetText = unit.killCount > 0 ? "  Kills: \(unit.killCount)" : ""
            infoStatsLabel.text = "ATK: \(unit.effectiveAttack)  DEF: \(unit.effectiveDefense)\(vetText)"
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

            if unit.type == .villager {
                updateActionButtons(for: unit, building: nil, player: player)
            } else {
                updateActionButtons(for: nil, building: nil, player: player)
            }
        } else {
            let first = selected[0]
            infoNameLabel.text = "\(selected.count) Units"
            let grouped = Dictionary(grouping: selected, by: { $0.type })
            let composition = grouped.map { "\($0.value.count) \($0.key.displayName)\($0.value.count > 1 ? "s" : "")" }
                .joined(separator: ", ")
            let totalHP = selected.reduce(0) { $0 + $1.hp }
            let totalMaxHP = selected.reduce(0) { $0 + $1.maxHP }
            infoHPLabel.text = "HP: \(totalHP)/\(totalMaxHP)"
            infoStatsLabel.text = ""
            infoIcon.fillColor = first.type.color
            selectionCountLabel.text = composition
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
        infoStatsLabel.text = ""
        infoIcon.fillColor = building.type.color
        selectionCountLabel.text = ""

        // Remove old queue icons
        infoPanel.children.filter { $0.name == "queueIcon" }.forEach { $0.removeFromParent() }

        if !building.trainingQueue.isEmpty {
            let queueText = building.trainingQueue.map { $0.icon }.joined(separator: " ")
            let progress = Int(building.trainingProgress * 100)
            queueLabel.text = "Queue [\(building.trainingQueue.count)/5]: \(queueText) (\(progress)%)"

            // Visual queue slots
            let panelWidth: CGFloat = 220
            let slotSize: CGFloat = 18
            let slotPadding: CGFloat = 3
            let slotsStartX = -panelWidth / 2 + 10
            let slotsY: CGFloat = -38

            for (i, unitType) in building.trainingQueue.enumerated() {
                let slot = SKShapeNode(rectOf: CGSize(width: slotSize, height: slotSize), cornerRadius: 2)
                slot.fillColor = unitType.color.withAlphaComponent(i == 0 ? 0.9 : 0.5)
                slot.strokeColor = i == 0 ? .white : .gray
                slot.lineWidth = i == 0 ? 1.5 : 0.5
                slot.position = CGPoint(x: slotsStartX + CGFloat(i) * (slotSize + slotPadding) + slotSize / 2, y: slotsY)
                slot.name = "queueIcon"
                infoPanel.addChild(slot)

                let iconLabel = SKLabelNode(text: unitType.icon)
                iconLabel.fontSize = 10
                iconLabel.fontName = "Helvetica-Bold"
                iconLabel.fontColor = .white
                iconLabel.verticalAlignmentMode = .center
                iconLabel.name = "queueIcon"
                slot.addChild(iconLabel)

                // Progress bar on first item
                if i == 0 {
                    let progressWidth = slotSize * building.trainingProgress
                    let progressBar = SKShapeNode(rectOf: CGSize(width: progressWidth, height: 2))
                    progressBar.fillColor = .green
                    progressBar.strokeColor = .clear
                    progressBar.position = CGPoint(x: (progressWidth - slotSize) / 2, y: -slotSize / 2 - 2)
                    progressBar.name = "queueIcon"
                    slot.addChild(progressBar)
                }
            }
        } else if let tech = building.currentResearch {
            let progress = Int(building.researchProgress * 100)
            queueLabel.text = "Researching: \(tech.displayName) (\(progress)%)"
        } else if !building.isConstructed {
            let progress = Int(building.constructionProgress * 100)
            queueLabel.text = "Building: \(progress)%"
        } else {
            queueLabel.text = ""
        }

        // Show garrison info
        if building.garrisonCapacity > 0 && !building.garrisonedUnits.isEmpty {
            let garrisonText = "Garrisoned: \(building.garrisonedUnits.count)/\(building.garrisonCapacity)"
            selectionCountLabel.text = garrisonText
        }

        updateActionButtons(for: nil, building: building, player: player)
    }

    private func updateActionButtons(for unit: Unit?, building: Building?, player: Player) {
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
            let buildBtn = createActionButton(
                text: "Build", icon: "B",
                color: SKColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1.0),
                name: "btn_build",
                x: startX, y: startY, size: buttonSize)
            actionPanel.addChild(buildBtn)
            actionButtons.append(buildBtn)
        }

        if let building = building, building.isConstructed {
            for (i, rawUnitType) in building.type.trainableUnits.enumerated() {
                // Resolve uniqueUnit to civ-specific type for display
                let unitType = (rawUnitType == .uniqueUnit) ? player.civilization.uniqueUnitType : rawUnitType
                guard player.currentAge.rawValue >= unitType.requiredAge.rawValue else { continue }

                let col = i % cols
                let row = i / cols
                let x = startX + CGFloat(col) * (buttonSize + padding)
                let y = startY - CGFloat(row) * (buttonSize + padding)

                let costText = formatCost(unitType.cost)
                let btn = createActionButton(
                    text: unitType.displayName, icon: unitType.icon,
                    color: unitType.color,
                    name: "train_\(rawUnitType)",
                    x: x, y: y, size: buttonSize,
                    subtitle: costText,
                    enabled: player.canAfford(unitType.cost))
                actionPanel.addChild(btn)
                actionButtons.append(btn)
            }

            if !building.type.trainableUnits.isEmpty {
                let nextCol = min(building.type.trainableUnits.count, cols)
                let rallyBtn = createActionButton(
                    text: "Rally", icon: "R",
                    color: SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0),
                    name: "btn_rally",
                    x: startX + CGFloat(nextCol) * (buttonSize + padding),
                    y: startY, size: buttonSize)
                actionPanel.addChild(rallyBtn)
                actionButtons.append(rallyBtn)

                // Cancel training button (shown when queue is not empty)
                if !building.trainingQueue.isEmpty {
                    let cancelBtn = createActionButton(
                        text: "Cancel", icon: "X",
                        color: SKColor(red: 0.6, green: 0.15, blue: 0.15, alpha: 1.0),
                        name: "btn_cancelTrain",
                        x: startX + CGFloat(nextCol + 1) * (buttonSize + padding),
                        y: startY, size: buttonSize)
                    actionPanel.addChild(cancelBtn)
                    actionButtons.append(cancelBtn)
                }
            }

            // Tech button for buildings that have researchable techs
            let techBuildings: [BuildingType] = [.blacksmith, .lumberCamp, .miningCamp, .townCenter, .stable, .monastery, .castle, .university, .barracks, .market]
            if techBuildings.contains(building.type) {
                let techBtn = createActionButton(
                    text: "Tech", icon: "T",
                    color: SKColor(red: 0.4, green: 0.3, blue: 0.5, alpha: 1.0),
                    name: "btn_tech",
                    x: startX + CGFloat(cols - 1) * (buttonSize + padding),
                    y: startY - (buttonSize + padding), size: buttonSize)
                actionPanel.addChild(techBtn)
                actionButtons.append(techBtn)

                // Cancel research button (shown when researching)
                if building.currentResearch != nil {
                    let cancelResBtn = createActionButton(
                        text: "CxRes", icon: "XR",
                        color: SKColor(red: 0.6, green: 0.15, blue: 0.15, alpha: 1.0),
                        name: "btn_cancelResearch",
                        x: startX + CGFloat(cols - 2) * (buttonSize + padding),
                        y: startY - (buttonSize + padding), size: buttonSize)
                    actionPanel.addChild(cancelResBtn)
                    actionButtons.append(cancelResBtn)
                }
            }

            // Garrison button for buildings with capacity
            if building.garrisonCapacity > 0 {
                let garrisonCount = building.garrisonedUnits.count
                let garrisonBtn = createActionButton(
                    text: "Garrison", icon: "\(garrisonCount)/\(building.garrisonCapacity)",
                    color: SKColor(red: 0.3, green: 0.35, blue: 0.5, alpha: 1.0),
                    name: "btn_garrison",
                    x: startX, y: startY - 2 * (buttonSize + padding), size: buttonSize)
                actionPanel.addChild(garrisonBtn)
                actionButtons.append(garrisonBtn)

                if garrisonCount > 0 {
                    let ungarrisonBtn = createActionButton(
                        text: "Ungarr", icon: "UG",
                        color: SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0),
                        name: "btn_ungarrison",
                        x: startX + (buttonSize + padding), y: startY - 2 * (buttonSize + padding), size: buttonSize)
                    actionPanel.addChild(ungarrisonBtn)
                    actionButtons.append(ungarrisonBtn)
                }
            }

            // Auto-reseed toggle for farms
            if building.type == .farm {
                let reseedText = building.autoReseed ? "Auto:ON" : "Auto:OFF"
                let reseedBtn = createActionButton(
                    text: "Reseed", icon: reseedText,
                    color: building.autoReseed ? SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0) : SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0),
                    name: "btn_autoReseed",
                    x: startX, y: startY - (buttonSize + padding), size: buttonSize)
                actionPanel.addChild(reseedBtn)
                actionButtons.append(reseedBtn)
            }
        }

        // Military unit action buttons (attack-move, patrol)
        if unit == nil && building == nil {
            let selected = player.units.filter { $0.isSelected && $0.type != .villager }
            if !selected.isEmpty {
                let atkBtn = createActionButton(
                    text: "A-Move", icon: "AM",
                    color: SKColor(red: 0.6, green: 0.2, blue: 0.2, alpha: 1.0),
                    name: "btn_attackMove",
                    x: startX, y: startY, size: buttonSize)
                actionPanel.addChild(atkBtn)
                actionButtons.append(atkBtn)

                let patrolBtn = createActionButton(
                    text: "Patrol", icon: "PT",
                    color: SKColor(red: 0.2, green: 0.4, blue: 0.6, alpha: 1.0),
                    name: "btn_patrol",
                    x: startX + (buttonSize + padding), y: startY, size: buttonSize)
                actionPanel.addChild(patrolBtn)
                actionButtons.append(patrolBtn)

                let stanceBtn = createActionButton(
                    text: "Stance", icon: "ST",
                    color: SKColor(red: 0.5, green: 0.5, blue: 0.2, alpha: 1.0),
                    name: "btn_stance",
                    x: startX + 2 * (buttonSize + padding), y: startY, size: buttonSize)
                actionPanel.addChild(stanceBtn)
                actionButtons.append(stanceBtn)

                let guardBtn = createActionButton(
                    text: "Guard", icon: "GD",
                    color: SKColor(red: 0.3, green: 0.4, blue: 0.5, alpha: 1.0),
                    name: "btn_guard",
                    x: startX + 3 * (buttonSize + padding), y: startY, size: buttonSize)
                actionPanel.addChild(guardBtn)
                actionButtons.append(guardBtn)

                // Auto-scout button for scout/light cavalry
                let hasScout = selected.contains { $0.type == .scout || $0.type == .lightCavalry }
                if hasScout {
                    let scoutBtn = createActionButton(
                        text: "Auto", icon: "AS",
                        color: SKColor(red: 0.4, green: 0.5, blue: 0.3, alpha: 1.0),
                        name: "btn_autoScout",
                        x: startX + 4 * (buttonSize + padding), y: startY, size: buttonSize)
                    actionPanel.addChild(scoutBtn)
                    actionButtons.append(scoutBtn)
                }

                // Collect relic button for monks
                let hasMonk = selected.contains { $0.type == .monk }
                if hasMonk {
                    let relicBtn = createActionButton(
                        text: "Relic", icon: "RL",
                        color: SKColor(red: 0.7, green: 0.6, blue: 0.2, alpha: 1.0),
                        name: "btn_collectRelic",
                        x: startX + (hasScout ? 5 : 4) * (buttonSize + padding), y: startY, size: buttonSize)
                    actionPanel.addChild(relicBtn)
                    actionButtons.append(relicBtn)
                }
            }
        }

        // Repair button when a damaged building is selected
        if let b = building, b.hp < b.maxHP {
            let repairBtn = createActionButton(
                text: "Repair", icon: "RP",
                color: SKColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0),
                name: "btn_repair",
                x: startX + CGFloat(actionButtons.count) * (buttonSize + padding), y: startY, size: buttonSize)
            actionPanel.addChild(repairBtn)
            actionButtons.append(repairBtn)
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

    // MARK: - Exit Confirmation

    func showExitConfirmation() {
        isShowingExitConfirm = true

        let overlay = SKNode()
        overlay.name = "exitConfirm"
        overlay.zPosition = 150

        let bg = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: viewSize.height))
        bg.fillColor = SKColor.black.withAlphaComponent(0.6)
        bg.strokeColor = .clear
        bg.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        bg.name = "exitConfirm"
        overlay.addChild(bg)

        let panel = SKShapeNode(rectOf: CGSize(width: 300, height: 140), cornerRadius: 10)
        panel.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 0.95)
        panel.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        panel.lineWidth = 2
        panel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        overlay.addChild(panel)

        let title = SKLabelNode(text: "Quit Game?")
        title.fontSize = 20
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        title.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 35)
        title.zPosition = 1
        overlay.addChild(title)

        let subtitle = SKLabelNode(text: "Your progress will be lost.")
        subtitle.fontSize = 14
        subtitle.fontName = "Helvetica"
        subtitle.fontColor = .lightGray
        subtitle.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 10)
        subtitle.zPosition = 1
        overlay.addChild(subtitle)

        // Yes button
        let yesBtn = SKNode()
        yesBtn.position = CGPoint(x: viewSize.width / 2 - 60, y: viewSize.height / 2 - 30)
        yesBtn.name = "exitConfirmYes"
        let yesBg = SKShapeNode(rectOf: CGSize(width: 80, height: 36), cornerRadius: 5)
        yesBg.fillColor = SKColor(red: 0.6, green: 0.15, blue: 0.1, alpha: 0.9)
        yesBg.strokeColor = .white
        yesBg.lineWidth = 1
        yesBg.name = "exitConfirmYes"
        yesBtn.addChild(yesBg)
        let yesLabel = SKLabelNode(text: "Quit")
        yesLabel.fontSize = 16
        yesLabel.fontName = "Helvetica-Bold"
        yesLabel.fontColor = .white
        yesLabel.verticalAlignmentMode = .center
        yesLabel.name = "exitConfirmYes"
        yesBtn.addChild(yesLabel)
        yesBtn.zPosition = 1
        overlay.addChild(yesBtn)

        // No button
        let noBtn = SKNode()
        noBtn.position = CGPoint(x: viewSize.width / 2 + 60, y: viewSize.height / 2 - 30)
        noBtn.name = "exitConfirmNo"
        let noBg = SKShapeNode(rectOf: CGSize(width: 80, height: 36), cornerRadius: 5)
        noBg.fillColor = SKColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 0.9)
        noBg.strokeColor = .white
        noBg.lineWidth = 1
        noBg.name = "exitConfirmNo"
        noBtn.addChild(noBg)
        let noLabel = SKLabelNode(text: "Stay")
        noLabel.fontSize = 16
        noLabel.fontName = "Helvetica-Bold"
        noLabel.fontColor = .white
        noLabel.verticalAlignmentMode = .center
        noLabel.name = "exitConfirmNo"
        noBtn.addChild(noLabel)
        noBtn.zPosition = 1
        overlay.addChild(noBtn)

        exitConfirmNode = overlay
        hudNode.addChild(overlay)
    }

    func hideExitConfirmation() {
        isShowingExitConfirm = false
        exitConfirmNode?.removeFromParent()
        exitConfirmNode = nil
    }

    var isExitConfirmShowing: Bool { isShowingExitConfirm }

    // MARK: - Build Menu

    func showBuildMenu(player: Player) {
        isBuildMenuOpen = true
        buildMenuNode.isHidden = false
        buildMenuNode.removeAllChildren()

        // Entrance animation
        buildMenuNode.setScale(0.7)
        buildMenuNode.alpha = 0
        buildMenuNode.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.fadeIn(withDuration: 0.15)
        ]))

        let bg = SKShapeNode(rectOf: CGSize(width: 420, height: 380), cornerRadius: 8)
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
            .townCenter, .house, .farm, .lumberCamp, .miningCamp,
            .barracks, .archeryRange, .stable, .blacksmith,
            .market, .tower, .wall, .gate, .castle, .siegeWorkshop,
            .monastery, .dock
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

        let closeBg = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 4)
        closeBg.fillColor = SKColor(red: 0.6, green: 0.15, blue: 0.1, alpha: 0.9)
        closeBg.strokeColor = .white
        closeBg.lineWidth = 1
        closeBg.name = "closeBuildMenu"
        closeBtn.addChild(closeBg)

        let closeLabel = SKLabelNode(text: "X")
        closeLabel.fontSize = 16
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
        costLabel.fontColor = enabled ? .gray : SKColor(red: 0.8, green: 0.3, blue: 0.2, alpha: 1.0)
        costLabel.verticalAlignmentMode = .center
        costLabel.position = CGPoint(x: 0, y: -22)
        costLabel.name = "build_\(type)"
        container.addChild(costLabel)

        return container
    }

    func hideBuildMenu() {
        isBuildMenuOpen = false
        buildMenuNode.run(SKAction.group([
            SKAction.scale(to: 0.7, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.1)
        ])) { [weak self] in
            self?.buildMenuNode.isHidden = true
            self?.buildMenuNode.setScale(1.0)
        }
    }

    var isBuildMenuShowing: Bool { isBuildMenuOpen }

    // MARK: - Tech Menu

    private func setupTechMenu() {
        techMenuNode = SKNode()
        techMenuNode.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        techMenuNode.zPosition = 120
        techMenuNode.isHidden = true
        hudNode.addChild(techMenuNode)
    }

    func showTechMenu(player: Player) {
        isTechMenuOpen = true
        techMenuNode.isHidden = false
        techMenuNode.removeAllChildren()

        // Entrance animation
        techMenuNode.setScale(0.7)
        techMenuNode.alpha = 0
        techMenuNode.run(SKAction.group([
            SKAction.scale(to: 1.0, duration: 0.15),
            SKAction.fadeIn(withDuration: 0.15)
        ]))

        let bg = SKShapeNode(rectOf: CGSize(width: 420, height: 440), cornerRadius: 8)
        bg.fillColor = SKColor(red: 0.1, green: 0.08, blue: 0.05, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
        bg.lineWidth = 2
        bg.name = "techMenuBg"
        techMenuNode.addChild(bg)

        let title = SKLabelNode(text: "Research Technologies")
        title.fontSize = 18
        title.fontName = "Helvetica-Bold"
        title.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1.0)
        title.position = CGPoint(x: 0, y: 140)
        techMenuNode.addChild(title)

        let allTechs = TechType.allCases
        let buttonSize: CGFloat = 66
        let padding: CGFloat = 8
        let cols = 5
        let startX = -CGFloat(cols) * (buttonSize + padding) / 2 + buttonSize / 2
        let startY: CGFloat = 90

        for (i, tech) in allTechs.enumerated() {
            let col = i % cols
            let row = i / cols
            let x = startX + CGFloat(col) * (buttonSize + padding)
            let y = startY - CGFloat(row) * (buttonSize + padding)

            let researched = player.researchedTechs.contains(tech)
            let hasAge = player.currentAge.rawValue >= tech.requiredAge.rawValue
            let affordable = player.canAfford(tech.cost)
            let hasBuilding = player.buildings.contains { $0.type == tech.researchedAt && $0.isConstructed }
            let alreadyResearching = player.buildings.contains { $0.currentResearch == tech }
            let hasPrereqs = tech.prerequisites.allSatisfy { player.researchedTechs.contains($0) }
            let enabled = !researched && hasAge && affordable && hasBuilding && !alreadyResearching && hasPrereqs

            let container = SKNode()
            container.position = CGPoint(x: x, y: y)
            container.name = "tech_\(tech)"
            container.alpha = researched ? 0.3 : (enabled ? 1.0 : 0.5)

            let btnBg = SKShapeNode(rectOf: CGSize(width: buttonSize, height: buttonSize), cornerRadius: 4)
            btnBg.fillColor = researched
                ? SKColor(red: 0.2, green: 0.4, blue: 0.2, alpha: 0.6)
                : SKColor(red: 0.3, green: 0.25, blue: 0.15, alpha: 0.7)
            btnBg.strokeColor = researched
                ? .green
                : (enabled ? SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0) : .gray)
            btnBg.lineWidth = researched ? 2 : 1
            btnBg.name = "tech_\(tech)"
            container.addChild(btnBg)

            let iconLabel = SKLabelNode(text: tech.icon)
            iconLabel.fontSize = 16
            iconLabel.verticalAlignmentMode = .center
            iconLabel.position = CGPoint(x: 0, y: 14)
            iconLabel.name = "tech_\(tech)"
            container.addChild(iconLabel)

            let nameLabel = SKLabelNode(text: tech.displayName)
            nameLabel.fontSize = 8
            nameLabel.fontName = "Helvetica"
            nameLabel.fontColor = .lightGray
            nameLabel.verticalAlignmentMode = .center
            nameLabel.position = CGPoint(x: 0, y: -2)
            nameLabel.name = "tech_\(tech)"
            container.addChild(nameLabel)

            let effectText: String
            let effectColor: SKColor
            if researched {
                effectText = "Done"
                effectColor = .green
            } else if !hasPrereqs {
                let prereqNames = tech.prerequisites.filter { !player.researchedTechs.contains($0) }.map { $0.displayName }
                effectText = "Needs: \(prereqNames.joined(separator: ", "))"
                effectColor = .orange
            } else {
                effectText = tech.effectDescription
                effectColor = .gray
            }
            let effectLabel = SKLabelNode(text: effectText)
            effectLabel.fontSize = 7
            effectLabel.fontName = "Helvetica"
            effectLabel.fontColor = effectColor
            effectLabel.verticalAlignmentMode = .center
            effectLabel.position = CGPoint(x: 0, y: -14)
            effectLabel.name = "tech_\(tech)"
            container.addChild(effectLabel)

            let costLabel = SKLabelNode(text: researched ? "" : formatCost(tech.cost))
            costLabel.fontSize = 7
            costLabel.fontName = "Helvetica"
            costLabel.fontColor = affordable ? .lightGray : .red
            costLabel.verticalAlignmentMode = .center
            costLabel.position = CGPoint(x: 0, y: -24)
            costLabel.name = "tech_\(tech)"
            container.addChild(costLabel)

            techMenuNode.addChild(container)
        }

        // Close button
        let closeBtn = SKNode()
        closeBtn.position = CGPoint(x: 190, y: 140)
        closeBtn.name = "closeTechMenu"
        let closeBg = SKShapeNode(rectOf: CGSize(width: 28, height: 28), cornerRadius: 4)
        closeBg.fillColor = SKColor(red: 0.6, green: 0.15, blue: 0.1, alpha: 0.9)
        closeBg.strokeColor = .white
        closeBg.lineWidth = 1
        closeBg.name = "closeTechMenu"
        closeBtn.addChild(closeBg)
        let closeLabel = SKLabelNode(text: "X")
        closeLabel.fontSize = 16
        closeLabel.fontName = "Helvetica-Bold"
        closeLabel.fontColor = .white
        closeLabel.verticalAlignmentMode = .center
        closeLabel.name = "closeTechMenu"
        closeBtn.addChild(closeLabel)
        techMenuNode.addChild(closeBtn)
    }

    func hideTechMenu() {
        isTechMenuOpen = false
        techMenuNode.run(SKAction.group([
            SKAction.scale(to: 0.7, duration: 0.1),
            SKAction.fadeOut(withDuration: 0.1)
        ])) { [weak self] in
            self?.techMenuNode.isHidden = true
            self?.techMenuNode.setScale(1.0)
        }
    }

    var isTechMenuShowing: Bool { isTechMenuOpen }

    // MARK: - Status Messages

    func showStatus(_ message: String, duration: CGFloat = 5.0, color: SKColor? = nil) {
        statusLabel.text = message
        statusLabel.removeAllActions()
        statusLabel.alpha = 0
        statusBg.removeAllActions()
        statusBg.alpha = 0

        // Color code based on message content or explicit color
        if let color = color {
            statusLabel.fontColor = color
        } else if message.contains("!") || message.contains("attack") || message.lowercased().contains("enemy") {
            statusLabel.fontColor = SKColor(red: 1.0, green: 0.4, blue: 0.3, alpha: 1.0)
        } else if message.contains("complete") || message.contains("finished") || message.contains("researched") {
            statusLabel.fontColor = SKColor(red: 0.4, green: 1.0, blue: 0.4, alpha: 1.0)
        } else if message.contains("cannot") || message.contains("need") || message.contains("insufficient") {
            statusLabel.fontColor = SKColor(red: 1.0, green: 0.85, blue: 0.3, alpha: 1.0)
        } else {
            statusLabel.fontColor = .white
        }

        if !message.isEmpty {
            // Slide in from top
            let slideIn = SKAction.group([
                SKAction.fadeIn(withDuration: 0.2),
                SKAction.moveBy(x: 0, y: -5, duration: 0.2)
            ])
            let bgFade = SKAction.fadeAlpha(to: 0.7, duration: 0.2)
            let fadeSeq = SKAction.sequence([
                slideIn,
                SKAction.wait(forDuration: TimeInterval(duration)),
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.moveBy(x: 0, y: 5, duration: 0.5)
                ])
            ])
            statusLabel.run(fadeSeq)
            statusBg.run(SKAction.sequence([
                bgFade,
                SKAction.wait(forDuration: TimeInterval(duration)),
                SKAction.fadeOut(withDuration: 0.5)
            ]))
        }
    }

    func showScoreboard(players: [Player], gameTime: CGFloat = 0) {
        // Remove existing scoreboard if any
        hudNode.childNode(withName: "scoreboardOverlay")?.removeFromParent()

        let overlay = SKShapeNode(rectOf: CGSize(width: 400, height: 300))
        overlay.fillColor = SKColor.black.withAlphaComponent(0.85)
        overlay.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
        overlay.lineWidth = 2
        overlay.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        overlay.zPosition = 180
        overlay.name = "scoreboardOverlay"
        hudNode.addChild(overlay)

        let title = SKLabelNode(text: "SCOREBOARD")
        title.fontSize = 20
        title.fontName = "Helvetica-Bold"
        title.fontColor = .yellow
        title.position = CGPoint(x: 0, y: 120)
        overlay.addChild(title)

        let minutes = Int(gameTime) / 60
        let seconds = Int(gameTime) % 60
        let timeLabel = SKLabelNode(text: String(format: "Game Time: %d:%02d", minutes, seconds))
        timeLabel.fontSize = 12
        timeLabel.fontName = "Helvetica"
        timeLabel.fontColor = SKColor(white: 0.6, alpha: 1.0)
        timeLabel.position = CGPoint(x: 0, y: 104)
        overlay.addChild(timeLabel)

        // Header row
        let header = SKLabelNode(text: "Player    Units  Kills  Lost   Food  Wood  Gold  Stone")
        header.fontSize = 11
        header.fontName = "Courier"
        header.fontColor = SKColor(white: 0.7, alpha: 1.0)
        header.position = CGPoint(x: 0, y: 90)
        overlay.addChild(header)

        for (index, player) in players.enumerated() {
            let color = SpriteFactory.playerColors[player.id % SpriteFactory.playerColors.count]
            let unitCount = player.units.count
            let kills = player.totalKills
            let lost = player.totalUnitsLost
            let res = player.resources

            let row = SKLabelNode(text: String(format: "P%d        %3d    %3d    %3d   %4d  %4d  %4d  %4d",
                                               player.id + 1, unitCount, kills, lost,
                                               res.food, res.wood, res.gold, res.stone))
            row.fontSize = 12
            row.fontName = "Courier"
            row.fontColor = color
            row.position = CGPoint(x: 0, y: 60 - CGFloat(index) * 30)
            overlay.addChild(row)

            // Age indicator
            let ageLabel = SKLabelNode(text: player.currentAge.displayName)
            ageLabel.fontSize = 9
            ageLabel.fontName = "Helvetica"
            ageLabel.fontColor = color.withAlphaComponent(0.7)
            ageLabel.position = CGPoint(x: 0, y: 48 - CGFloat(index) * 30)
            overlay.addChild(ageLabel)
        }

        let hint = SKLabelNode(text: "Tap to close")
        hint.fontSize = 10
        hint.fontName = "Helvetica"
        hint.fontColor = SKColor(white: 0.5, alpha: 1.0)
        hint.position = CGPoint(x: 0, y: -130)
        overlay.addChild(hint)

        // Auto-dismiss after 8 seconds or on tap
        overlay.run(SKAction.sequence([
            SKAction.wait(forDuration: 8.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
    }

    func showCivBonuses(player: Player) {
        // Toggle off if already showing
        if let existing = hudNode.childNode(withName: "civBonusesPanel") {
            existing.removeFromParent()
            return
        }

        let panelWidth: CGFloat = 260
        let panelHeight: CGFloat = 180
        let panel = SKNode()
        panel.name = "civBonusesPanel"
        panel.zPosition = 150
        panel.position = CGPoint(x: viewSize.width - 200, y: viewSize.height - 120 - safeAreaTop)

        let bg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 8)
        bg.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.05, alpha: 0.95)
        bg.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.25, alpha: 1)
        bg.lineWidth = 1.5
        bg.name = "closeCivBonuses"
        panel.addChild(bg)

        // Civ name and icon
        let civTitle = SKLabelNode(text: "\(player.civilization.icon) \(player.civilization.displayName)")
        civTitle.fontSize = 16
        civTitle.fontName = "Helvetica-Bold"
        civTitle.fontColor = SKColor(red: 0.9, green: 0.75, blue: 0.35, alpha: 1)
        civTitle.position = CGPoint(x: 0, y: panelHeight / 2 - 30)
        panel.addChild(civTitle)

        // Separator
        let sep = SKShapeNode(rectOf: CGSize(width: panelWidth - 30, height: 1))
        sep.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 0.6)
        sep.strokeColor = .clear
        sep.position = CGPoint(x: 0, y: panelHeight / 2 - 42)
        panel.addChild(sep)

        // Bonuses header
        let bonusHeader = SKLabelNode(text: "Active Bonuses")
        bonusHeader.fontSize = 12
        bonusHeader.fontName = "Helvetica-Bold"
        bonusHeader.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1)
        bonusHeader.position = CGPoint(x: 0, y: panelHeight / 2 - 58)
        panel.addChild(bonusHeader)

        // Parse and display bonus lines
        let bonusText = player.civilization.bonus
        let bonusLines = bonusText.components(separatedBy: "\n")
        for (i, line) in bonusLines.enumerated() {
            let bonusLabel = SKLabelNode(text: line)
            bonusLabel.fontSize = 12
            bonusLabel.fontName = "Helvetica"
            bonusLabel.fontColor = SKColor(red: 0.5, green: 0.9, blue: 0.5, alpha: 1)
            bonusLabel.position = CGPoint(x: 0, y: panelHeight / 2 - 76 - CGFloat(i) * 20)
            panel.addChild(bonusLabel)
        }

        // Current age
        let ageInfo = SKLabelNode(text: "Current Age: \(player.currentAge.displayName)")
        ageInfo.fontSize = 11
        ageInfo.fontName = "Helvetica"
        ageInfo.fontColor = .lightGray
        ageInfo.position = CGPoint(x: 0, y: -panelHeight / 2 + 38)
        panel.addChild(ageInfo)

        // Close hint
        let closeHint = SKLabelNode(text: "Tap to close")
        closeHint.fontSize = 10
        closeHint.fontName = "Helvetica"
        closeHint.fontColor = SKColor(white: 0.5, alpha: 1)
        closeHint.position = CGPoint(x: 0, y: -panelHeight / 2 + 18)
        closeHint.name = "closeCivBonuses"
        panel.addChild(closeHint)

        // Auto-dismiss after 10 seconds
        panel.run(SKAction.sequence([
            SKAction.wait(forDuration: 10.0),
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))

        hudNode.addChild(panel)
    }

    func showGameOver(victory: Bool, player: Player? = nil) {
        let overlay = SKShapeNode(rectOf: CGSize(width: viewSize.width, height: viewSize.height))
        overlay.fillColor = SKColor.black.withAlphaComponent(0.85)
        overlay.strokeColor = .clear
        overlay.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2)
        overlay.zPosition = 200
        hudNode.addChild(overlay)

        let text = victory ? "VICTORY!" : "DEFEAT"
        let color: SKColor = victory ? SKColor(red: 1, green: 0.85, blue: 0.3, alpha: 1) : .red

        let label = SKLabelNode(text: text)
        label.fontSize = 60
        label.fontName = "Helvetica-Bold"
        label.fontColor = color
        label.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 140)
        label.zPosition = 201
        label.setScale(0.1)
        label.run(SKAction.sequence([
            SKAction.scale(to: 1.2, duration: 0.3),
            SKAction.scale(to: 1.0, duration: 0.15)
        ]))
        hudNode.addChild(label)

        // Decorative line under title
        let titleLine = SKShapeNode(rectOf: CGSize(width: 250, height: 2))
        titleLine.fillColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1)
        titleLine.strokeColor = .clear
        titleLine.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 110)
        titleLine.zPosition = 201
        hudNode.addChild(titleLine)

        // Stats panel background
        let panelWidth: CGFloat = 380
        let panelHeight: CGFloat = 250
        let panelBg = SKShapeNode(rectOf: CGSize(width: panelWidth, height: panelHeight), cornerRadius: 8)
        panelBg.fillColor = SKColor(red: 0.12, green: 0.1, blue: 0.06, alpha: 0.9)
        panelBg.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1)
        panelBg.lineWidth = 1.5
        panelBg.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 - 15)
        panelBg.zPosition = 201
        hudNode.addChild(panelBg)

        // Stats header
        let statsHeader = SKLabelNode(text: "GAME STATISTICS")
        statsHeader.fontSize = 14
        statsHeader.fontName = "Helvetica-Bold"
        statsHeader.fontColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1)
        statsHeader.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 + 95)
        statsHeader.zPosition = 202
        hudNode.addChild(statsHeader)

        if let player = player {
            let scene = gameScene
            let gameDuration = scene != nil ? Int(scene!.gameTime - scene!.gameStartTime) : 0
            let minutes = gameDuration / 60
            let seconds = gameDuration % 60
            let timeStr = String(format: "%02d:%02d", minutes, seconds)

            let gathered = player.totalResourcesGathered

            let leftLabels: [(String, String)] = [
                ("Game Duration", timeStr),
                ("Age Reached", player.currentAge.displayName),
                ("Units Trained", "\(scene?.totalUnitsTrainedHuman ?? 0)"),
                ("Units Lost", "\(scene?.totalUnitsLostHuman ?? 0)"),
                ("Enemies Killed", "\(player.totalKills)"),
                ("Techs Researched", "\(player.researchedTechs.count)")
            ]

            let rightLabels: [(String, String)] = [
                ("Buildings", "\(player.buildings.count)"),
                ("Food Gathered", "\(Int(gathered.food))"),
                ("Wood Gathered", "\(Int(gathered.wood))"),
                ("Gold Gathered", "\(Int(gathered.gold))"),
                ("Stone Gathered", "\(Int(gathered.stone))"),
                ("Relics Collected", "\(player.relicsCollected)")
            ]

            let colLeftX = viewSize.width / 2 - panelWidth / 2 + 20
            let colRightX = viewSize.width / 2 + 10
            let startY = viewSize.height / 2 + 70

            for (i, entry) in leftLabels.enumerated() {
                let nameLabel = SKLabelNode(text: entry.0)
                nameLabel.fontSize = 12
                nameLabel.fontName = "Helvetica"
                nameLabel.fontColor = .lightGray
                nameLabel.horizontalAlignmentMode = .left
                nameLabel.position = CGPoint(x: colLeftX, y: startY - CGFloat(i) * 22)
                nameLabel.zPosition = 202
                hudNode.addChild(nameLabel)

                let valLabel = SKLabelNode(text: entry.1)
                valLabel.fontSize = 12
                valLabel.fontName = "Helvetica-Bold"
                valLabel.fontColor = .white
                valLabel.horizontalAlignmentMode = .right
                valLabel.position = CGPoint(x: colLeftX + 160, y: startY - CGFloat(i) * 22)
                valLabel.zPosition = 202
                hudNode.addChild(valLabel)
            }

            for (i, entry) in rightLabels.enumerated() {
                let nameLabel = SKLabelNode(text: entry.0)
                nameLabel.fontSize = 12
                nameLabel.fontName = "Helvetica"
                nameLabel.fontColor = .lightGray
                nameLabel.horizontalAlignmentMode = .left
                nameLabel.position = CGPoint(x: colRightX, y: startY - CGFloat(i) * 22)
                nameLabel.zPosition = 202
                hudNode.addChild(nameLabel)

                let valLabel = SKLabelNode(text: entry.1)
                valLabel.fontSize = 12
                valLabel.fontName = "Helvetica-Bold"
                valLabel.fontColor = .white
                valLabel.horizontalAlignmentMode = .right
                valLabel.position = CGPoint(x: colRightX + 160, y: startY - CGFloat(i) * 22)
                valLabel.zPosition = 202
                hudNode.addChild(valLabel)
            }
        }

        // Exit button
        let exitBtnBg = SKShapeNode(rectOf: CGSize(width: 220, height: 40), cornerRadius: 6)
        exitBtnBg.fillColor = SKColor(red: 0.5, green: 0.15, blue: 0.1, alpha: 1)
        exitBtnBg.strokeColor = SKColor(red: 0.85, green: 0.7, blue: 0.4, alpha: 1)
        exitBtnBg.lineWidth = 1.5
        exitBtnBg.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 - 165)
        exitBtnBg.zPosition = 201
        exitBtnBg.name = "gameOverExit"
        hudNode.addChild(exitBtnBg)

        let exitLabel = SKLabelNode(text: "RETURN TO MENU")
        exitLabel.fontSize = 16
        exitLabel.fontName = "Helvetica-Bold"
        exitLabel.fontColor = .white
        exitLabel.verticalAlignmentMode = .center
        exitLabel.position = CGPoint(x: viewSize.width / 2, y: viewSize.height / 2 - 165)
        exitLabel.zPosition = 202
        exitLabel.name = "gameOverExit"
        hudNode.addChild(exitLabel)
    }

    // MARK: - Touch Handling

    private func animateButtonPress(_ node: SKNode) {
        // Find the topmost named parent (the button container)
        var target = node
        if let parent = node.parent, parent.name != nil && parent.name != "hudNode" {
            target = parent
        }
        target.run(SKAction.sequence([
            SKAction.scale(to: 0.85, duration: 0.05),
            SKAction.scale(to: 1.0, duration: 0.08)
        ]))
    }

    func handleTouch(at point: CGPoint) -> HUDAction? {
        let nodes = hudNode.nodes(at: point)

        for node in nodes {
            guard let name = node.name else { continue }

            // Animate button press for any named node
            if name.hasPrefix("btn_") || name.hasPrefix("build_") || name.hasPrefix("train_") ||
               name.hasPrefix("tech_") || name == "pauseBtn" || name == "ageUpBtn" ||
               name == "helpBtn" || name == "speedBtn" {
                animateButtonPress(node)
            }

            // Exit confirmation
            if name == "exitConfirmYes" { return .confirmExit }
            if name == "exitConfirmNo" || (name == "exitConfirm" && isShowingExitConfirm) { return .cancelExit }

            if name == "pauseBtn" { return .pause }
            if name == "exitBtn" { return .exit }
            if name == "ageUpBtn" { return .ageUp }
            if name == "helpBtn" { return .showHelp }
            if name == "deselectBtn" { return .deselect }
            if name == "speedBtn" { return .toggleSpeed }
            if name == "btn_build" { return .openBuildMenu }
            if name == "btn_rally" { return .setRallyPoint }
            if name == "closeBuildMenu" { return .closeBuildMenu }
            if name == "gameOverExit" { return .confirmExit }
            if name == "btn_tech" { return .openTechMenu }
            if name == "closeTechMenu" { return .closeTechMenu }
            if name == "btn_attackMove" { return .attackMoveMode }
            if name == "btn_patrol" { return .patrolMode }
            if name == "btn_stance" { return .cycleStance }
            if name == "btn_cancelTrain" { return .cancelTraining }
            if name == "btn_cancelResearch" { return .cancelResearch }
            if name == "btn_guard" { return .guardMode }
            if name == "btn_garrison" { return .garrison }
            if name == "btn_ungarrison" { return .ungarrison }
            if name == "btn_autoReseed" { return .toggleAutoReseed }
            if name == "btn_autoScout" { return .autoScout }
            if name == "btn_collectRelic" { return .collectRelic }
            if name == "btn_repair" { return .repairBuilding }
            if name == "btn_selectIdleMilitary" { return .selectIdleMilitary }
            if name == "btn_showScoreboard" { return .showScoreboard }
            if name == "btn_showCivBonuses" { return .showCivBonuses }
            if name == "closeCivBonuses" {
                hudNode.childNode(withName: "civBonusesPanel")?.removeFromParent()
                return nil
            }
            if name == "idleVillagerBtn" { return .selectIdleVillager }

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

            if name.hasPrefix("tech_") {
                let typeStr = String(name.dropFirst(5))
                if let techType = parseTechType(typeStr) {
                    return .researchTech(techType)
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
        if isShowingExitConfirm { return true }
        if point.y > viewSize.height - 80 - safeAreaTop && point.x > viewSize.width - 370 { return true }
        if point.y > viewSize.height - 40 - safeAreaTop { return true }
        if point.x < minimapSize + 20 && point.y < minimapSize + 20 { return true }
        if point.x > viewSize.width - 300 && point.y < 180 { return true }
        if point.x > minimapSize + 20 && point.x < minimapSize + 250 && point.y < 180 { return true }
        if isBuildMenuOpen { return true }
        if isTechMenuOpen { return true }
        return false
    }

    // MARK: - Helpers

    private func applyResourceWarning(label: SKLabelNode, value: Int) {
        let warningThreshold = 50
        let criticalThreshold = 20
        if value < criticalThreshold {
            // Critical: fast pulse between red and dark red
            if label.action(forKey: "resFlash") == nil {
                let flash = SKAction.repeatForever(SKAction.sequence([
                    SKAction.run { label.fontColor = .red },
                    SKAction.wait(forDuration: 0.3),
                    SKAction.run { label.fontColor = SKColor(red: 0.5, green: 0, blue: 0, alpha: 1) },
                    SKAction.wait(forDuration: 0.3)
                ]))
                label.run(flash, withKey: "resFlash")
            }
        } else if value < warningThreshold {
            label.removeAction(forKey: "resFlash")
            label.fontColor = SKColor(red: 1.0, green: 0.5, blue: 0.2, alpha: 1.0) // orange warning
        } else {
            label.removeAction(forKey: "resFlash")
            label.fontColor = .white
        }
    }

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

    private func parseTechType(_ str: String) -> TechType? {
        TechType.allCases.first { "\($0)" == str }
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
    case confirmExit
    case cancelExit
    case ageUp
    case showHelp
    case deselect
    case openBuildMenu
    case closeBuildMenu
    case selectBuilding(BuildingType)
    case trainUnit(UnitType)
    case setRallyPoint
    case minimapTap(CGPoint)
    case toggleSpeed
    case openTechMenu
    case closeTechMenu
    case researchTech(TechType)
    case attackMoveMode
    case patrolMode
    case selectIdleVillager
    case cancelTraining
    case cancelResearch
    case cycleStance
    case guardMode
    case garrison
    case ungarrison
    case toggleAutoReseed
    case repairBuilding
    case autoScout
    case selectIdleMilitary
    case showScoreboard
    case collectRelic
    case showCivBonuses
}
