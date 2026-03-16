import Foundation
import SpriteKit

class AIOpponent {
    weak var gameScene: GameScene?
    let player: Player
    let difficulty: AIDifficulty
    var decisionTimer: CGFloat = 0
    var strategy: AIStrategy = .economy
    var rushTimer: CGFloat = 0
    var hasAttacked = false
    var defenseTimer: CGFloat = 0
    let defenseInterval: CGFloat = 2.0
    var techTree = TechTree()
    var dynamicDifficultyAdjust: CGFloat = 1.0  // Scales AI gather/build rate
    var wonderAwareness: Bool = false
    var navalTimer: CGFloat = 0

    // Scouting: track whether we found the enemy base
    var scoutedEnemyBase: GridPosition?
    var scoutSentImmediately: Bool = false
    var scoutTargetIndex: Int = 0

    // Adaptive strategy: detect enemy playstyle
    enum EnemyPlaystyle {
        case unknown
        case turtle   // Many towers/walls, few military
        case rush     // Early aggression with many units
        case boom     // Heavy economy focus
    }
    var enemyPlaystyle: EnemyPlaystyle = .unknown

    // Counter-unit composition tracking to prevent flip-flopping
    var lastEnemyComposition: (cavalry: Int, ranged: Int, infantry: Int, siege: Int, monks: Int) = (0, 0, 0, 0, 0)
    var compositionSampleCount: Int = 0

    // Army rally system
    var rallyPoint: GridPosition?
    var rallyTimer: CGFloat = 0
    let rallyTimeout: CGFloat = 15.0  // Don't wait longer than 15 seconds
    var isRallying: Bool = false

    // Monk management
    var monkTargetCount: Int = 0

    var decisionInterval: CGFloat {
        switch difficulty {
        case .easy: return 5.0
        case .normal: return 3.0
        case .hard: return 1.5
        }
    }

    var attackTimerThreshold: CGFloat {
        switch difficulty {
        case .easy: return 240
        case .normal: return 120
        case .hard: return 60
        }
    }

    var militaryThreshold: Int {
        switch difficulty {
        case .easy: return 15
        case .normal: return 12
        case .hard: return 8
        }
    }

    enum AIStrategy {
        case economy
        case military
        case attack
    }

    init(player: Player, difficulty: AIDifficulty = .normal) {
        self.player = player
        self.difficulty = difficulty
    }

    func update(deltaTime: CGFloat) {
        decisionTimer += deltaTime
        rushTimer += deltaTime

        // Hard AI gets small gather bonus (scaled by dynamic difficulty)
        if difficulty == .hard {
            player.resources.food += Int(deltaTime * 0.15 * dynamicDifficultyAdjust)
            player.resources.wood += Int(deltaTime * 0.1 * dynamicDifficultyAdjust)
        }

        // Dynamic difficulty: adjust based on score differential
        if let human = gameScene?.players.first(where: { $0.isHuman }) {
            let humanScore = human.units.count + human.buildings.count * 2
            let aiScore = player.units.count + player.buildings.count * 2
            if aiScore > humanScore * 2 {
                dynamicDifficultyAdjust = 0.8  // AI is way ahead, slow down
            } else if humanScore > aiScore * 2 {
                dynamicDifficultyAdjust = 1.2  // AI is behind, catch up slightly
            } else {
                dynamicDifficultyAdjust = 1.0
            }
        }

        // Dark Age immediate scouting - send scout right away
        if !scoutSentImmediately && player.currentAge == .darkAge {
            sendInitialScout()
        }

        // Update rally timer if rallying
        if isRallying {
            rallyTimer += deltaTime
        }

        guard decisionTimer >= decisionInterval else { return }
        decisionTimer = 0

        // Check for enemy buildings near our scout (scouting intelligence)
        updateScoutIntelligence()

        updateStrategy()

        switch strategy {
        case .economy:
            handleEconomy()
        case .military:
            handleMilitary()
        case .attack:
            handleAttack()
        }

        // Always try to maintain economy
        manageVillagers()
        advanceAgeIfPossible()
        researchTechs()

        // Defense check
        defenseTimer += decisionInterval
        if defenseTimer >= defenseInterval {
            defenseTimer = 0
            handleDefense()
        }

        // Monk micro-management
        handleMonkBehavior()

        // Naval strategy
        navalTimer += decisionInterval
        if navalTimer >= 10.0 {
            navalTimer = 0
            handleNavalStrategy()
        }

        // Wonder awareness: if enemy is building/has wonder, rush them
        checkWonderThreat()

        // Build outposts for vision
        buildOutpostsForVision()
    }

    // MARK: - Scouting Intelligence

    /// In Dark Age, immediately send the starting scout to explore
    private func sendInitialScout() {
        guard let scene = gameScene else { return }

        if let scout = player.units.first(where: { $0.type == .scout }) {
            scoutSentImmediately = true

            // Send scout toward likely enemy positions (opposite corners first)
            guard let tc = player.buildings.first(where: { $0.type == .townCenter }) else { return }
            let mapW = scene.gameMap.width
            let mapH = scene.gameMap.height

            // Head to the corner furthest from our TC (most likely enemy location)
            let corners = [
                GridPosition(x: mapW / 4, y: mapH / 4),
                GridPosition(x: mapW * 3 / 4, y: mapH / 4),
                GridPosition(x: mapW / 4, y: mapH * 3 / 4),
                GridPosition(x: mapW * 3 / 4, y: mapH * 3 / 4),
            ]
            let furthestCorner = corners.max(by: {
                $0.distance(to: tc.gridPosition) < $1.distance(to: tc.gridPosition)
            }) ?? corners[0]

            scene.unitSystem.moveUnit(scout, to: furthestCorner, pathfinder: scene.pathfinder)
        }
    }

    /// Check if any scout has discovered enemy buildings
    private func updateScoutIntelligence() {
        guard let scene = gameScene else { return }
        guard scoutedEnemyBase == nil else { return }

        let scouts = player.units.filter { $0.type == .scout }
        for scout in scouts {
            for enemy in scene.players where enemy.id != player.id {
                for building in enemy.buildings {
                    let dist = scout.gridPosition.distance(to: building.gridPosition)
                    if dist < 12 {
                        scoutedEnemyBase = building.gridPosition
                        return
                    }
                }
            }
        }
    }

    // MARK: - Defense (Enhanced Retreat + Monk Healing)

    private func handleDefense() {
        guard let scene = gameScene else { return }

        var threatPositions: [GridPosition] = []

        for unit in player.units where unit.hp < unit.maxHP {
            threatPositions.append(unit.gridPosition)
        }
        for building in player.buildings where building.hp < building.maxHP && building.isConstructed {
            threatPositions.append(building.gridPosition)
        }

        guard !threatPositions.isEmpty else { return }

        // Enhanced retreat behavior: pull back wounded units
        let monks = player.units.filter { $0.type == .monk }
        let hasMonks = !monks.isEmpty

        for unit in player.units where unit.type != .villager && unit.type != .monk {
            let hpPercent = CGFloat(unit.hp) / CGFloat(unit.maxHP)

            // Retreat attacking units at 25% HP
            if hpPercent < 0.25 {
                if let tc = player.buildings.first(where: { $0.type == .townCenter }) {
                    let distToTC = unit.gridPosition.distance(to: tc.gridPosition)
                    if distToTC > 5 {
                        if case .attacking(_) = unit.state {
                            scene.unitSystem.moveUnit(unit, to: tc.gridPosition, pathfinder: scene.pathfinder)
                        }
                    }
                }
            }
            // Also retreat non-attacking units at 30% HP
            else if hpPercent < 0.30 {
                if let tc = player.buildings.first(where: { $0.type == .townCenter }) {
                    let distToTC = unit.gridPosition.distance(to: tc.gridPosition)
                    if distToTC > 5 {
                        let shouldRetreat: Bool
                        switch unit.state {
                        case .idle, .moving(_):
                            shouldRetreat = true
                        default:
                            shouldRetreat = false
                        }
                        if shouldRetreat {
                            scene.unitSystem.moveUnit(unit, to: tc.gridPosition, pathfinder: scene.pathfinder)
                        }
                    }
                }
            }

            // Monk healing: send monks to heal damaged units near TC
            if hasMonks && hpPercent < 0.60 && unit.hp > 0 {
                if let tc = player.buildings.first(where: { $0.type == .townCenter }) {
                    let distToTC = unit.gridPosition.distance(to: tc.gridPosition)
                    if distToTC < 10 {
                        // Find an idle monk to heal this unit
                        if let monk = monks.first(where: { isIdle($0) }) {
                            monk.state = .healing(targetUnitID: unit.id)
                            monk.path = scene.pathfinder.findPath(from: monk.gridPosition, to: unit.gridPosition)
                        }
                    }
                }
            }
        }

        let idleMilitary = player.units.filter { $0.type != .villager && $0.type != .monk && isIdle($0) }
        guard !idleMilitary.isEmpty else { return }

        let threatPos = threatPositions[0]

        for unit in idleMilitary {
            let dist = unit.gridPosition.distance(to: threatPos)
            if dist < 25 {
                for enemy in scene.players where enemy.id != player.id {
                    for enemyUnit in enemy.units {
                        let eDist = enemyUnit.gridPosition.distance(to: threatPos)
                        if eDist < 10 {
                            scene.unitSystem.attackTarget(unit: unit, targetID: enemyUnit.id, pathfinder: scene.pathfinder)
                            break
                        }
                    }
                }
            }
        }
    }

    // MARK: - Strategy (Enhanced with Adaptive Detection)

    private func updateStrategy() {
        let villagerCount = player.units.filter { $0.type == .villager }.count
        let militaryCount = player.units.filter { $0.type != .villager && $0.type != .monk }.count
        let hasBarracks = player.buildings.contains { $0.type == .barracks && $0.isConstructed }

        // Detect enemy playstyle
        detectEnemyPlaystyle()

        // Adapt strategy based on detected enemy playstyle
        if enemyPlaystyle == .rush && rushTimer < 120 {
            // Prioritize defense: build towers and defensive units
            if militaryCount < 4 {
                strategy = .military
                return
            }
        }

        if villagerCount < 8 || !hasBarracks {
            strategy = .economy
        } else if militaryCount < 6 {
            strategy = .military
        } else if rushTimer > attackTimerThreshold || militaryCount >= militaryThreshold {
            // If rallying, stay in attack mode but don't send yet
            strategy = .attack
        } else {
            strategy = .military
        }
    }

    /// Detect whether enemy is turtling, rushing, or booming
    private func detectEnemyPlaystyle() {
        guard let scene = gameScene else { return }

        for enemy in scene.players where enemy.id != player.id {
            let enemyMilitary = enemy.units.filter { $0.type != .villager && $0.type != .monk }.count
            let enemyTowers = enemy.buildings.filter { $0.type == .tower && $0.isConstructed }.count
            let enemyWalls = enemy.buildings.filter { $0.type == .wall && $0.isConstructed }.count
            let enemyVillagers = enemy.units.filter { $0.type == .villager }.count

            let defensiveStructures = enemyTowers + enemyWalls / 3

            // Turtle detection: many towers/walls but few military
            if defensiveStructures >= 4 && enemyMilitary < 5 {
                enemyPlaystyle = .turtle
                return
            }

            // Rush detection: early aggression (before 120s) with significant military
            if rushTimer < 120 && enemyMilitary >= 5 {
                enemyPlaystyle = .rush
                return
            }

            // Boom detection: lots of villagers, few military
            if enemyVillagers > 15 && enemyMilitary < 4 {
                enemyPlaystyle = .boom
                return
            }
        }

        // Keep existing detection if nothing clear
        if enemyPlaystyle == .unknown {
            enemyPlaystyle = .unknown
        }
    }

    // MARK: - Economy (Enhanced Scouting)

    private func handleEconomy() {
        guard let scene = gameScene else { return }

        let villagerCount = player.units.filter { $0.type == .villager }.count
        let hasBarracks = player.buildings.contains { $0.type == .barracks && $0.isConstructed }

        // Train villagers
        // Chinese AI: higher villager cap and more aggressive early villager production
        let baseMaxVillagers = difficulty == .hard ? 20 : (difficulty == .normal ? 15 : 12)
        let maxVillagers = player.civilization == .chinese ? baseMaxVillagers + 3 : baseMaxVillagers
        let maxQueue = player.civilization == .chinese ? 3 : 2
        if villagerCount < maxVillagers {
            if let tc = player.buildings.first(where: { $0.type == .townCenter && $0.isConstructed }) {
                if tc.trainingQueue.count < maxQueue {
                    _ = scene.buildingSystem.trainUnit(type: .villager, at: tc, player: player)
                }
            }
        }

        // Send scout to explore (enhanced: prioritize unexplored areas, track enemy)
        let scouts = player.units.filter { $0.type == .scout && isIdle($0) }
        if let scout = scouts.first {
            let mapW = scene.gameMap.width
            let mapH = scene.gameMap.height
            let scoutTargets = [
                GridPosition(x: mapW / 4, y: mapH / 4),
                GridPosition(x: mapW * 3 / 4, y: mapH / 4),
                GridPosition(x: mapW / 4, y: mapH * 3 / 4),
                GridPosition(x: mapW * 3 / 4, y: mapH * 3 / 4),
                GridPosition(x: mapW / 2, y: mapH / 2),
                GridPosition(x: mapW / 6, y: mapH / 2),
                GridPosition(x: mapW * 5 / 6, y: mapH / 2),
            ]

            // Cycle through targets sequentially rather than randomly for better coverage
            let target = scoutTargets[scoutTargetIndex % scoutTargets.count]
            scoutTargetIndex += 1
            scene.unitSystem.moveUnit(scout, to: target, pathfinder: scene.pathfinder)
        }

        // Build houses if needed
        if player.population >= player.populationCap - 2 {
            let houseCount = player.buildings.filter { $0.type == .house }.count
            if houseCount < 10 {
                buildNearTC(.house)
            }
        }

        // Build barracks
        if !hasBarracks && player.resources.wood >= 175 {
            buildNearTC(.barracks)
        }

        // Build lumber camp near forest
        let hasLumberCamp = player.buildings.contains { $0.type == .lumberCamp }
        if !hasLumberCamp && player.resources.wood >= 100 {
            if let forestTile = findNearestResourceTile(.wood) {
                buildNear(forestTile, type: .lumberCamp)
            }
        }

        // Build mining camp near gold
        let hasMiningCamp = player.buildings.contains { $0.type == .miningCamp }
        if !hasMiningCamp && player.resources.wood >= 100 {
            if let goldTile = findNearestResourceTile(.gold) {
                buildNear(goldTile, type: .miningCamp)
            }
        }

        // Build farms when food is low
        if player.resources.food < 150 && player.resources.wood >= 60 {
            let farmCount = player.buildings.filter { $0.type == .farm }.count
            if farmCount < villagerCount / 2 {
                buildNearTC(.farm)
            }
        }

        // Feudal age buildings
        if player.currentAge.rawValue >= Age.feudalAge.rawValue {
            if !player.buildings.contains(where: { $0.type == .archeryRange }) && player.resources.wood >= 175 {
                buildNearTC(.archeryRange)
            }
            if !player.buildings.contains(where: { $0.type == .blacksmith }) && player.resources.wood >= 150 {
                buildNearTC(.blacksmith)
            }

            // Vikings: prioritize dock in Feudal Age for naval bonuses
            if player.civilization == .vikings {
                if !player.buildings.contains(where: { $0.type == .dock }) && player.resources.wood >= 150 {
                    buildNearTC(.dock)
                }
            }

            // Counter rush: build towers if enemy is rushing
            if enemyPlaystyle == .rush {
                let towerCount = player.buildings.filter { $0.type == .tower }.count
                if towerCount < 2 && player.resources.stone >= 125 && player.resources.wood >= 50 {
                    buildNearTC(.tower)
                }
            }
        }

        // Castle age buildings
        if player.currentAge.rawValue >= Age.castleAge.rawValue {
            if !player.buildings.contains(where: { $0.type == .stable }) && player.resources.wood >= 175 {
                buildNearTC(.stable)
            }
            if !player.buildings.contains(where: { $0.type == .siegeWorkshop }) && player.resources.wood >= 200 {
                buildNearTC(.siegeWorkshop)
            }
            if !player.buildings.contains(where: { $0.type == .university }) && player.resources.wood >= 200 {
                buildNearTC(.university)
            }
            // Build monastery in Castle Age for monks
            if !player.buildings.contains(where: { $0.type == .monastery }) && player.resources.wood >= 175 && player.resources.gold >= 100 {
                buildNearTC(.monastery)
            }
        }

        // Build walls around base
        if player.currentAge.rawValue >= Age.feudalAge.rawValue && difficulty != .easy {
            let wallCount = player.buildings.filter { $0.type == .wall }.count
            if wallCount < 8 && player.resources.stone >= 40 {
                buildWallSegmentNearBase()
            }
        }
    }

    // MARK: - Enemy Composition Analysis (Enhanced)

    private func analyzeEnemyComposition() -> (cavalry: Int, ranged: Int, infantry: Int, siege: Int, monks: Int) {
        guard let scene = gameScene else { return (0, 0, 0, 0, 0) }
        var cav = 0, ranged = 0, inf = 0, siege = 0, monks = 0
        for enemy in scene.players where enemy.id != player.id {
            for unit in enemy.units where unit.type != .villager {
                if unit.type.isCavalry { cav += 1 }
                if unit.type.isRanged { ranged += 1 }
                if unit.type.isInfantry { inf += 1 }
                if unit.type.isSiege { siege += 1 }
                if unit.type == .monk { monks += 1 }
            }
        }

        // Smooth composition tracking to prevent flip-flopping
        // Blend new observation with historical data
        if compositionSampleCount > 0 {
            let weight: CGFloat = 0.7  // Weight toward new observation
            let oldWeight: CGFloat = 1.0 - weight
            cav = Int(CGFloat(cav) * weight + CGFloat(lastEnemyComposition.cavalry) * oldWeight)
            ranged = Int(CGFloat(ranged) * weight + CGFloat(lastEnemyComposition.ranged) * oldWeight)
            inf = Int(CGFloat(inf) * weight + CGFloat(lastEnemyComposition.infantry) * oldWeight)
            siege = Int(CGFloat(siege) * weight + CGFloat(lastEnemyComposition.siege) * oldWeight)
            monks = Int(CGFloat(monks) * weight + CGFloat(lastEnemyComposition.monks) * oldWeight)
        }

        lastEnemyComposition = (cav, ranged, inf, siege, monks)
        compositionSampleCount += 1

        return (cav, ranged, inf, siege, monks)
    }

    // MARK: - Military (Enhanced with Counter-Units, Monks, Siege Counters)

    private func handleMilitary() {
        guard let scene = gameScene else { return }

        let enemy = analyzeEnemyComposition()
        let totalEnemy = enemy.cavalry + enemy.ranged + enemy.infantry + enemy.siege + enemy.monks

        for building in player.buildings where building.isConstructed {
            guard building.trainingQueue.count < 2 else { continue }

            switch building.type {
            case .barracks:
                // Counter-build: spearmen if enemy is 40%+ cavalry
                if totalEnemy > 0 && enemy.cavalry * 100 / max(totalEnemy, 1) > 40 {
                    _ = scene.buildingSystem.trainUnit(type: .spearman, at: building, player: player)
                } else if player.currentAge.rawValue >= Age.feudalAge.rawValue {
                    _ = scene.buildingSystem.trainUnit(type: .manAtArms, at: building, player: player)
                } else {
                    _ = scene.buildingSystem.trainUnit(type: .militia, at: building, player: player)
                }

            case .archeryRange:
                // If enemy has monks, prioritize ranged units to keep distance
                if totalEnemy > 0 && enemy.monks >= 2 {
                    if player.currentAge.rawValue >= Age.castleAge.rawValue {
                        _ = scene.buildingSystem.trainUnit(type: .crossbowman, at: building, player: player)
                    } else {
                        _ = scene.buildingSystem.trainUnit(type: .archer, at: building, player: player)
                    }
                }
                // Counter-build: skirmishers if enemy is 40%+ ranged
                else if totalEnemy > 0 && enemy.ranged * 100 / max(totalEnemy, 1) > 40 {
                    _ = scene.buildingSystem.trainUnit(type: .skirmisher, at: building, player: player)
                } else if player.currentAge.rawValue >= Age.castleAge.rawValue {
                    _ = scene.buildingSystem.trainUnit(type: .crossbowman, at: building, player: player)
                } else {
                    _ = scene.buildingSystem.trainUnit(type: .archer, at: building, player: player)
                }

            case .stable:
                // If enemy has lots of siege, train cavalry to rush siege
                if totalEnemy > 0 && enemy.siege >= 2 {
                    if player.currentAge.rawValue >= Age.castleAge.rawValue && player.resources.gold >= 75 {
                        _ = scene.buildingSystem.trainUnit(type: .knight, at: building, player: player)
                    } else {
                        _ = scene.buildingSystem.trainUnit(type: .lightCavalry, at: building, player: player)
                    }
                }
                // Knights crush infantry-heavy compositions
                else if totalEnemy > 0 && enemy.infantry * 100 / max(totalEnemy, 1) > 50 {
                    if player.currentAge.rawValue >= Age.castleAge.rawValue && player.resources.gold >= 75 {
                        _ = scene.buildingSystem.trainUnit(type: .knight, at: building, player: player)
                    } else {
                        _ = scene.buildingSystem.trainUnit(type: .scout, at: building, player: player)
                    }
                } else {
                    if player.currentAge.rawValue >= Age.castleAge.rawValue && player.resources.gold >= 75 {
                        _ = scene.buildingSystem.trainUnit(type: .knight, at: building, player: player)
                    } else {
                        _ = scene.buildingSystem.trainUnit(type: .scout, at: building, player: player)
                    }
                }

            case .siegeWorkshop:
                // Counter turtle play: prioritize siege when enemy is turtling
                if enemyPlaystyle == .turtle {
                    if player.resources.wood >= 200 && player.resources.gold >= 200 {
                        _ = scene.buildingSystem.trainUnit(type: .trebuchet, at: building, player: player)
                    } else if player.resources.wood >= 160 && player.resources.gold >= 75 {
                        _ = scene.buildingSystem.trainUnit(type: .batteringRam, at: building, player: player)
                    }
                } else {
                    if player.resources.wood >= 200 && player.resources.gold >= 200 {
                        _ = scene.buildingSystem.trainUnit(type: .trebuchet, at: building, player: player)
                    } else if player.resources.wood >= 160 && player.resources.gold >= 75 {
                        _ = scene.buildingSystem.trainUnit(type: .batteringRam, at: building, player: player)
                    }
                }

            case .monastery:
                // Train 2-3 monks in Castle Age
                let monkCount = player.units.filter { $0.type == .monk }.count
                let desiredMonks = difficulty == .hard ? 3 : 2
                if monkCount < desiredMonks && player.resources.gold >= 100 {
                    _ = scene.buildingSystem.trainUnit(type: .monk, at: building, player: player)
                }

            case .castle:
                // Train civilization unique units from the castle
                let uniqueCount = player.units.filter { $0.type == player.civilization.uniqueUnitType }.count
                let desiredUnique = difficulty == .hard ? 5 : 3
                if uniqueCount < desiredUnique {
                    _ = scene.buildingSystem.trainUnit(type: .uniqueUnit, at: building, player: player)
                }

            case .dock:
                // Vikings prioritize war galleys for naval dominance
                if player.civilization == .vikings {
                    let warGalleys = player.units.filter { $0.type == .warGalley }.count
                    if warGalleys < 3 && player.resources.wood >= 135 && player.resources.gold >= 60 {
                        _ = scene.buildingSystem.trainUnit(type: .warGalley, at: building, player: player)
                    }
                }

            default:
                break
            }
        }

        // If enemy is rushing, train defensive units quickly
        if enemyPlaystyle == .rush {
            for building in player.buildings where building.isConstructed && building.type == .barracks {
                if building.trainingQueue.count < 2 {
                    _ = scene.buildingSystem.trainUnit(type: .spearman, at: building, player: player)
                }
            }
        }
    }

    // MARK: - Monk Behavior

    private func handleMonkBehavior() {
        guard let scene = gameScene else { return }

        let monks = player.units.filter { $0.type == .monk }
        guard !monks.isEmpty else { return }

        for monk in monks {
            guard isIdle(monk) else { continue }

            // Priority 1: Heal wounded friendly units near TC
            let woundedFriendlies = player.units.filter {
                $0.type != .monk && $0.type != .villager &&
                $0.hp < $0.maxHP && $0.hp > 0
            }.sorted(by: { $0.hp < $1.hp })  // Heal most damaged first

            if let wounded = woundedFriendlies.first {
                let dist = monk.gridPosition.distance(to: wounded.gridPosition)
                if dist < 15 {
                    monk.state = .healing(targetUnitID: wounded.id)
                    monk.path = scene.pathfinder.findPath(from: monk.gridPosition, to: wounded.gridPosition)
                    continue
                }
            }

            // Priority 2: During attack, attempt conversion on expensive enemy units
            if strategy == .attack {
                var bestTarget: Unit?
                var bestDist: CGFloat = .infinity

                for enemy in scene.players where enemy.id != player.id {
                    for enemyUnit in enemy.units {
                        // Target expensive units: knights, cataphracts, war elephants
                        let isHighValue = enemyUnit.type == .knight ||
                                          enemyUnit.type == .cataphract ||
                                          enemyUnit.type == .warElephant ||
                                          enemyUnit.type == .mangudai ||
                                          enemyUnit.type == .trebuchet
                        if isHighValue {
                            let dist = monk.gridPosition.distance(to: enemyUnit.gridPosition)
                            if dist < bestDist && dist < 20 {
                                bestDist = dist
                                bestTarget = enemyUnit
                            }
                        }
                    }
                }

                if let target = bestTarget {
                    monk.state = .converting(targetUnitID: target.id)
                    monk.path = scene.pathfinder.findPath(from: monk.gridPosition, to: target.gridPosition)
                    continue
                }
            }
        }
    }

    // MARK: - Army Rally System

    /// Gather military units at a rally point before attacking
    private func rallyArmy(target: GridPosition) -> Bool {
        guard let scene = gameScene else { return false }
        guard let tc = player.buildings.first(where: { $0.type == .townCenter }) else { return false }

        let militaryUnits = player.units.filter { $0.type != .villager && $0.type != .monk }
        guard !militaryUnits.isEmpty else { return false }

        // Calculate rally point: midpoint between TC and target
        if rallyPoint == nil {
            rallyPoint = GridPosition(
                x: (tc.gridPosition.x + target.x) / 2,
                y: (tc.gridPosition.y + target.y) / 2
            )
            isRallying = true
            rallyTimer = 0
        }

        guard let rally = rallyPoint else { return false }

        // Send idle units to rally point
        for unit in militaryUnits {
            if isIdle(unit) {
                let distToRally = unit.gridPosition.distance(to: rally)
                if distToRally > 5 {
                    scene.unitSystem.moveUnit(unit, to: rally, pathfinder: scene.pathfinder)
                }
            }
        }

        // Check if 70% of army has arrived (within 5 tiles of rally)
        let arrivedCount = militaryUnits.filter { $0.gridPosition.distance(to: rally) <= 5 }.count
        let arrivalRatio = CGFloat(arrivedCount) / CGFloat(max(militaryUnits.count, 1))

        // Attack once 70% assembled or timer expires
        if arrivalRatio >= 0.7 || rallyTimer >= rallyTimeout {
            isRallying = false
            rallyPoint = nil
            rallyTimer = 0
            return true  // Ready to attack
        }

        return false  // Still rallying
    }

    // MARK: - Attack (Enhanced with Rally)

    private func handleAttack() {
        guard let scene = gameScene else { return }
        guard let humanPlayer = scene.players.first(where: { $0.isHuman }) else { return }

        let militaryUnits = player.units.filter { $0.type != .villager && $0.type != .monk }
        guard !militaryUnits.isEmpty else {
            strategy = .military
            return
        }

        // Determine attack target
        let attackTarget: GridPosition
        if let knownBase = scoutedEnemyBase {
            // Use scouted enemy base location
            attackTarget = knownBase
        } else if let enemyTC = humanPlayer.buildings.first(where: { $0.type == .townCenter }) {
            attackTarget = enemyTC.gridPosition
        } else if let enemyBuilding = humanPlayer.buildings.first {
            attackTarget = enemyBuilding.gridPosition
        } else if let enemyUnit = humanPlayer.units.first {
            attackTarget = enemyUnit.gridPosition
        } else {
            return
        }

        // Rally army before attacking (skip for first few scouts)
        if militaryUnits.count >= 5 && !isRallying && rallyPoint == nil {
            // Start rally
            _ = rallyArmy(target: attackTarget)
            return
        }

        if isRallying {
            let ready = rallyArmy(target: attackTarget)
            if !ready {
                return  // Still gathering
            }
        }

        // Split fast units for harassment if we have enough
        let fastUnits = militaryUnits.filter { $0.type == .scout || $0.type == .lightCavalry }
        let mainArmy = militaryUnits.filter { $0.type != .scout && $0.type != .lightCavalry && $0.type != .monk }

        // Harass: send scouts to raid villagers (even with just 1 scout)
        if fastUnits.count >= 1 {
            let enemyVillagers = humanPlayer.units.filter { $0.type == .villager }
            // Target villager furthest from their TC (most vulnerable)
            let enemyTC = humanPlayer.buildings.first(where: { $0.type == .townCenter })
            let targetVillager = enemyVillagers
                .max(by: { a, b in
                    let aDist = enemyTC.map { a.gridPosition.distance(to: $0.gridPosition) } ?? 0
                    let bDist = enemyTC.map { b.gridPosition.distance(to: $0.gridPosition) } ?? 0
                    return aDist < bDist
                })
            if let target = targetVillager {
                for unit in fastUnits.prefix(3) {
                    if isIdle(unit) {
                        scene.unitSystem.attackTarget(unit: unit, targetID: target.id, pathfinder: scene.pathfinder)
                    }
                }
            }
        }

        // Main army: target weakest buildings first (economy buildings), then TC
        let target: GridPosition
        let econBuildings = humanPlayer.buildings.filter {
            $0.type == .lumberCamp || $0.type == .miningCamp || $0.type == .farm || $0.type == .dock || $0.type == .market
        }
        if let weakTarget = econBuildings.min(by: { $0.hp < $1.hp }) {
            target = weakTarget.gridPosition
        } else if let enemyTC = humanPlayer.buildings.first(where: { $0.type == .townCenter }) {
            target = enemyTC.gridPosition
        } else if let enemyBuilding = humanPlayer.buildings.first {
            target = enemyBuilding.gridPosition
        } else if let enemyUnit = humanPlayer.units.first {
            target = enemyUnit.gridPosition
        } else {
            return
        }

        // Send monks to follow army and heal during attack
        let monks = player.units.filter { $0.type == .monk && isIdle($0) }
        for monk in monks {
            // Move monks toward army center
            if let frontUnit = mainArmy.first {
                let monkDist = monk.gridPosition.distance(to: frontUnit.gridPosition)
                if monkDist > 8 {
                    scene.unitSystem.moveUnit(monk, to: frontUnit.gridPosition, pathfinder: scene.pathfinder)
                }
            }
        }

        // Coordinated attack: split army into groups for multi-prong attack (hard AI)
        if difficulty == .hard && mainArmy.count >= 8 {
            let halfCount = mainArmy.count / 2
            let group1 = Array(mainArmy.prefix(halfCount))
            let group2 = Array(mainArmy.suffix(from: halfCount))

            // Group 1: attack main target
            for unit in group1 {
                if isIdle(unit) {
                    if let enemy = findNearestEnemyUnit(unit: unit, humanPlayer: humanPlayer) {
                        scene.unitSystem.attackTarget(unit: unit, targetID: enemy.id, pathfinder: scene.pathfinder)
                    } else {
                        scene.unitSystem.moveUnit(unit, to: target, pathfinder: scene.pathfinder)
                    }
                }
            }

            // Group 2: flank from different angle (offset target)
            let flankTarget = GridPosition(x: target.x + 8, y: target.y + 5)
            for unit in group2 {
                if isIdle(unit) {
                    if let enemy = findNearestEnemyUnit(unit: unit, humanPlayer: humanPlayer) {
                        scene.unitSystem.attackTarget(unit: unit, targetID: enemy.id, pathfinder: scene.pathfinder)
                    } else {
                        scene.unitSystem.moveUnit(unit, to: flankTarget, pathfinder: scene.pathfinder)
                    }
                }
            }
        } else {
            // Send main army (standard approach)
            for unit in mainArmy {
                if isIdle(unit) {
                    if let enemy = findNearestEnemyUnit(unit: unit, humanPlayer: humanPlayer) {
                        scene.unitSystem.attackTarget(unit: unit, targetID: enemy.id, pathfinder: scene.pathfinder)
                    } else {
                        scene.unitSystem.moveUnit(unit, to: target, pathfinder: scene.pathfinder)
                    }
                }
            }
        }

        hasAttacked = true
    }

    private func researchTechs() {
        guard let scene = gameScene else { return }

        // Only research on normal/hard, and only if we have a blacksmith or relevant building
        if difficulty == .easy && player.currentAge == .darkAge { return }

        // Prioritized tech list by age
        var desiredTechs: [TechType] = []

        // Filter out free techs (Vikings get wheelbarrow/handCart for free)
        let freeTechs = player.civilization.freeEcoUpgrades

        if player.currentAge.rawValue >= Age.feudalAge.rawValue {
            desiredTechs.append(contentsOf: [.doubleBitAxe, .horseCollar, .forging, .fletching, .loom])
            if difficulty == .hard {
                desiredTechs.append(contentsOf: [.scaleMailArmor, .scaleBardingArmor, .bloodlines])
            }
            // Chinese AI: prioritize early tech research (discounted)
            if player.civilization == .chinese {
                desiredTechs.append(contentsOf: [.goldMining, .stoneMining, .masonry])
            }
            // Vikings AI: prioritize infantry upgrades
            if player.civilization == .vikings {
                desiredTechs.insert(.squires, at: 0)
            }
        }

        if player.currentAge.rawValue >= Age.castleAge.rawValue {
            desiredTechs.append(contentsOf: [.bowSaw, .wheelbarrow, .ironCasting, .bodkinArrow,
                                              .chainMailArmor, .chainBardingArmor, .masonry, .architecture])
            if difficulty == .hard {
                desiredTechs.append(contentsOf: [.heavyPlow, .goldMining, .ballistics, .arrowslits, .townWatch])
            }
        }

        // Remove techs that are already free for this civilization
        desiredTechs.removeAll { freeTechs.contains($0) }

        // Try to research each in order
        for tech in desiredTechs {
            if !player.researchedTechs.contains(tech) {
                // Check if we have the building
                let hasBuilding = player.buildings.contains { $0.type == tech.researchedAt && $0.isConstructed }
                if hasBuilding {
                    if techTree.research(tech: tech, player: player) {
                        // Only research one per decision cycle
                        return
                    }
                }
            }
        }
    }

    private func manageVillagers() {
        guard let scene = gameScene else { return }

        let idleVillagers = player.units.filter { $0.type == .villager && isIdle($0) }

        for villager in idleVillagers {
            let resourcePriority: ResourceType
            if player.resources.food < 100 {
                resourcePriority = .food
            } else if player.resources.wood < 100 {
                resourcePriority = .wood
            } else if player.resources.gold < 50 {
                resourcePriority = .gold
            } else {
                let foodWorkers = countGatherers(.food)
                let woodWorkers = countGatherers(.wood)
                let goldWorkers = countGatherers(.gold)

                if foodWorkers <= woodWorkers && foodWorkers <= goldWorkers {
                    resourcePriority = .food
                } else if woodWorkers <= goldWorkers {
                    resourcePriority = .wood
                } else {
                    resourcePriority = .gold
                }
            }

            if let resourceTile = scene.gameMap.findNearestResource(resourcePriority, from: villager.gridPosition) {
                scene.resourceSystem.sendVillagerToGather(
                    unit: villager, tilePos: resourceTile,
                    map: scene.gameMap, pathfinder: scene.pathfinder)
            }
        }

        // Send villagers to build unfinished buildings
        let unfinishedBuildings = player.buildings.filter { !$0.isConstructed }
        for building in unfinishedBuildings {
            let builders = player.units.filter {
                if case .building(let bid) = $0.state, bid == building.id { return true }
                return false
            }
            if builders.isEmpty {
                if let villager = idleVillagers.first(where: { isIdle($0) }) {
                    scene.resourceSystem.sendVillagerToBuild(
                        unit: villager, building: building, pathfinder: scene.pathfinder)
                }
            }
        }
    }

    // MARK: - Age Advance (Enhanced with Economy Check)

    private func advanceAgeIfPossible() {
        guard !player.isAdvancingAge else { return }
        guard player.currentAge != .imperialAge else { return }

        let nextAge = Age(rawValue: player.currentAge.rawValue + 1)!
        if player.canAfford(nextAge.advanceCost) {
            let villagerCount = player.units.filter { $0.type == .villager }.count
            let baseMinVillagers = player.currentAge.rawValue * 3 + 5

            // Require at least 3 more villagers than the base minimum before aging up
            // On hard difficulty, age up more aggressively (only 1 extra needed)
            let extraVillagersNeeded: Int
            switch difficulty {
            case .hard:
                extraVillagersNeeded = 1
            case .normal:
                extraVillagersNeeded = 3
            case .easy:
                extraVillagersNeeded = 3
            }

            let requiredVillagers = baseMinVillagers + extraVillagersNeeded

            if villagerCount >= requiredVillagers {
                player.spend(nextAge.advanceCost)
                player.isAdvancingAge = true
                player.ageAdvanceProgress = 0
            }
        }
    }

    // MARK: - Utility Methods

    private func isIdle(_ unit: Unit) -> Bool {
        if case .idle = unit.state { return true }
        return false
    }

    private func countGatherers(_ type: ResourceType) -> Int {
        player.units.filter {
            if case .gathering(let rt, _) = $0.state, rt == type { return true }
            return false
        }.count
    }

    private func buildNearTC(_ type: BuildingType) {
        guard let scene = gameScene else { return }
        guard let tc = player.buildings.first(where: { $0.type == .townCenter }) else { return }

        let basePos = tc.gridPosition
        for radius in 3...12 {
            for attempt in 0..<8 {
                let angle = CGFloat(attempt) * .pi / 4.0
                let dx = Int(CGFloat(radius) * cos(angle))
                let dy = Int(CGFloat(radius) * sin(angle))
                let pos = GridPosition(x: basePos.x + dx, y: basePos.y + dy)

                if scene.gameMap.canPlaceBuilding(type: type, at: pos) {
                    if let building = scene.buildingSystem.placeBuilding(
                        type: type, at: pos, player: player,
                        map: scene.gameMap, spriteFactory: scene.spriteFactory) {
                        scene.gameWorld.addChild(building.node!)

                        if let villager = player.units.first(where: { $0.type == .villager && isIdle($0) }) {
                            scene.resourceSystem.sendVillagerToBuild(
                                unit: villager, building: building, pathfinder: scene.pathfinder)
                        }
                        return
                    }
                }
            }
        }
    }

    private func buildNear(_ position: GridPosition, type: BuildingType) {
        guard let scene = gameScene else { return }

        for radius in 1...5 {
            for dy in -radius...radius {
                for dx in -radius...radius {
                    let pos = GridPosition(x: position.x + dx, y: position.y + dy)
                    if scene.gameMap.canPlaceBuilding(type: type, at: pos) {
                        if let building = scene.buildingSystem.placeBuilding(
                            type: type, at: pos, player: player,
                            map: scene.gameMap, spriteFactory: scene.spriteFactory) {
                            scene.gameWorld.addChild(building.node!)

                            if let villager = player.units.first(where: { $0.type == .villager && isIdle($0) }) {
                                scene.resourceSystem.sendVillagerToBuild(
                                    unit: villager, building: building, pathfinder: scene.pathfinder)
                            }
                            return
                        }
                    }
                }
            }
        }
    }

    private func findNearestResourceTile(_ type: ResourceType) -> GridPosition? {
        guard let scene = gameScene else { return nil }
        guard let tc = player.buildings.first(where: { $0.type == .townCenter }) else { return nil }
        return scene.gameMap.findNearestResource(type, from: tc.gridPosition)
    }

    private func buildWallSegmentNearBase() {
        guard let scene = gameScene else { return }
        guard let tc = player.buildings.first(where: { $0.type == .townCenter }) else { return }

        let basePos = tc.gridPosition
        let wallRadius = 8

        // Build walls in a rough perimeter
        let positions = [
            GridPosition(x: basePos.x - wallRadius, y: basePos.y),
            GridPosition(x: basePos.x + wallRadius, y: basePos.y),
            GridPosition(x: basePos.x, y: basePos.y - wallRadius),
            GridPosition(x: basePos.x, y: basePos.y + wallRadius),
            GridPosition(x: basePos.x - wallRadius, y: basePos.y - wallRadius),
            GridPosition(x: basePos.x + wallRadius, y: basePos.y + wallRadius),
            GridPosition(x: basePos.x - wallRadius, y: basePos.y + wallRadius),
            GridPosition(x: basePos.x + wallRadius, y: basePos.y - wallRadius),
        ]

        for pos in positions {
            if scene.gameMap.canPlaceBuilding(type: .wall, at: pos) {
                if let building = scene.buildingSystem.placeBuilding(
                    type: .wall, at: pos, player: player,
                    map: scene.gameMap, spriteFactory: scene.spriteFactory) {
                    building.isConstructed = true
                    building.hp = building.maxHP
                    building.constructionProgress = 1.0
                    scene.gameWorld.addChild(building.node!)
                    scene.spriteFactory.updateBuildingNode(building)
                    return
                }
            }
        }
    }

    // MARK: - Naval Strategy

    private func handleNavalStrategy() {
        guard let scene = gameScene else { return }
        // Vikings can build docks in Feudal Age; others wait for Castle Age
        let minNavalAge = player.civilization == .vikings ? Age.feudalAge : Age.castleAge
        guard player.currentAge.rawValue >= minNavalAge.rawValue else { return }

        let hasDock = player.buildings.contains { $0.type == .dock && $0.isConstructed }

        // Build dock if near water (Vikings prioritize this)
        if !hasDock && player.resources.wood >= 150 {
            // Find water-adjacent position
            if let tc = player.buildings.first(where: { $0.type == .townCenter }) {
                for radius in 5...15 {
                    for attempt in 0..<8 {
                        let angle = CGFloat(attempt) * .pi / 4.0
                        let dx = Int(CGFloat(radius) * cos(angle))
                        let dy = Int(CGFloat(radius) * sin(angle))
                        let pos = GridPosition(x: tc.gridPosition.x + dx, y: tc.gridPosition.y + dy)
                        if scene.gameMap.canPlaceBuilding(type: .dock, at: pos) {
                            if let building = scene.buildingSystem.placeBuilding(
                                type: .dock, at: pos, player: player,
                                map: scene.gameMap, spriteFactory: scene.spriteFactory) {
                                building.isConstructed = true
                                building.hp = building.maxHP
                                building.constructionProgress = 1.0
                                scene.gameWorld.addChild(building.node!)
                                scene.spriteFactory.updateBuildingNode(building)
                                return
                            }
                        }
                    }
                }
            }
        }

        // Train fishing boats for economy (Vikings get more)
        if hasDock {
            let fishingBoats = player.units.filter { $0.type == .fishingBoat }.count
            let maxFishingBoats = player.civilization == .vikings ? 5 : 3
            if fishingBoats < maxFishingBoats {
                if let dock = player.buildings.first(where: { $0.type == .dock && $0.isConstructed }) {
                    _ = scene.buildingSystem.trainUnit(type: .fishingBoat, at: dock, player: player)
                }
            }
        }
    }

    // MARK: - Wonder Awareness

    private func checkWonderThreat() {
        guard let scene = gameScene else { return }

        for enemy in scene.players where enemy.id != player.id {
            if enemy.wonderBuilt {
                wonderAwareness = true
                // Rush the wonder!
                if let wonder = enemy.buildings.first(where: { $0.type == .wonder }) {
                    strategy = .attack
                    for unit in player.units where unit.type != .villager && isIdle(unit) {
                        scene.unitSystem.attackBuilding(unit: unit, targetBuildingID: wonder.id, pathfinder: scene.pathfinder)
                    }
                }
                return
            }
        }
        wonderAwareness = false
    }

    // MARK: - Outpost Building

    private func buildOutpostsForVision() {
        guard let scene = gameScene else { return }
        guard player.currentAge.rawValue >= Age.feudalAge.rawValue else { return }

        let outpostCount = player.buildings.filter { $0.type == .outpost }.count
        guard outpostCount < 3 else { return }
        guard player.resources.wood >= 25 && player.resources.stone >= 5 else { return }

        // Place outposts at map quadrant centers for vision
        let positions = [
            GridPosition(x: scene.gameMap.width / 4, y: scene.gameMap.height / 4),
            GridPosition(x: scene.gameMap.width * 3 / 4, y: scene.gameMap.height / 4),
            GridPosition(x: scene.gameMap.width / 4, y: scene.gameMap.height * 3 / 4),
        ]

        for pos in positions {
            if scene.gameMap.canPlaceBuilding(type: .outpost, at: pos) {
                if let building = scene.buildingSystem.placeBuilding(
                    type: .outpost, at: pos, player: player,
                    map: scene.gameMap, spriteFactory: scene.spriteFactory) {
                    building.isConstructed = true
                    building.hp = building.maxHP
                    building.constructionProgress = 1.0
                    scene.gameWorld.addChild(building.node!)
                    scene.spriteFactory.updateBuildingNode(building)
                    return
                }
            }
        }
    }

    private func findNearestEnemyUnit(unit: Unit, humanPlayer: Player) -> Unit? {
        var nearestEnemy: Unit?
        var nearestDist: CGFloat = .infinity
        for enemy in humanPlayer.units {
            let dist = unit.gridPosition.distance(to: enemy.gridPosition)
            if dist < nearestDist {
                nearestDist = dist
                nearestEnemy = enemy
            }
        }
        return nearestDist < 15 ? nearestEnemy : nil
    }
}
