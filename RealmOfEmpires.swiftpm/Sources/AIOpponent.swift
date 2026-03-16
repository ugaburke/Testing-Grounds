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

        // Hard AI gets hidden gather bonus
        if difficulty == .hard {
            player.resources.food += Int(deltaTime * 0.5)
            player.resources.wood += Int(deltaTime * 0.3)
        }

        guard decisionTimer >= decisionInterval else { return }
        decisionTimer = 0

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
    }

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

        // Retreat behavior: pull back wounded units
        for unit in player.units where unit.type != .villager {
            if CGFloat(unit.hp) < CGFloat(unit.maxHP) * 0.25 {
                // Critically wounded, retreat to TC
                if let tc = player.buildings.first(where: { $0.type == .townCenter }) {
                    let distToTC = unit.gridPosition.distance(to: tc.gridPosition)
                    if distToTC > 5 {
                        if case .attacking(_) = unit.state {
                            scene.unitSystem.moveUnit(unit, to: tc.gridPosition, pathfinder: scene.pathfinder)
                        }
                    }
                }
            }
        }

        let idleMilitary = player.units.filter { $0.type != .villager && isIdle($0) }
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

    private func updateStrategy() {
        let villagerCount = player.units.filter { $0.type == .villager }.count
        let militaryCount = player.units.filter { $0.type != .villager }.count
        let hasBarracks = player.buildings.contains { $0.type == .barracks && $0.isConstructed }

        if villagerCount < 8 || !hasBarracks {
            strategy = .economy
        } else if militaryCount < 6 {
            strategy = .military
        } else if rushTimer > attackTimerThreshold || militaryCount >= militaryThreshold {
            strategy = .attack
        } else {
            strategy = .military
        }
    }

    private func handleEconomy() {
        guard let scene = gameScene else { return }

        let villagerCount = player.units.filter { $0.type == .villager }.count
        let hasBarracks = player.buildings.contains { $0.type == .barracks && $0.isConstructed }

        // Train villagers
        let maxVillagers = difficulty == .hard ? 20 : (difficulty == .normal ? 15 : 12)
        if villagerCount < maxVillagers {
            if let tc = player.buildings.first(where: { $0.type == .townCenter && $0.isConstructed }) {
                if tc.trainingQueue.count < 2 {
                    _ = scene.buildingSystem.trainUnit(type: .villager, at: tc, player: player)
                }
            }
        }

        // Send scout to explore
        let scouts = player.units.filter { $0.type == .scout && isIdle($0) }
        if let scout = scouts.first {
            let mapCenter = GridPosition(x: scene.gameMap.width / 2, y: scene.gameMap.height / 2)
            let scoutTargets = [
                GridPosition(x: scene.gameMap.width / 4, y: scene.gameMap.height / 4),
                GridPosition(x: scene.gameMap.width * 3 / 4, y: scene.gameMap.height / 4),
                GridPosition(x: scene.gameMap.width / 4, y: scene.gameMap.height * 3 / 4),
                GridPosition(x: scene.gameMap.width * 3 / 4, y: scene.gameMap.height * 3 / 4),
                mapCenter
            ]
            let target = scoutTargets.randomElement() ?? mapCenter
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
        }

        // Castle age buildings
        if player.currentAge.rawValue >= Age.castleAge.rawValue {
            if !player.buildings.contains(where: { $0.type == .stable }) && player.resources.wood >= 175 {
                buildNearTC(.stable)
            }
            if !player.buildings.contains(where: { $0.type == .siegeWorkshop }) && player.resources.wood >= 200 {
                buildNearTC(.siegeWorkshop)
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

    private func analyzeEnemyComposition() -> (cavalry: Int, ranged: Int, infantry: Int) {
        guard let scene = gameScene else { return (0, 0, 0) }
        var cav = 0, ranged = 0, inf = 0
        for enemy in scene.players where enemy.id != player.id {
            for unit in enemy.units where unit.type != .villager {
                if unit.type.isCavalry { cav += 1 }
                if unit.type.isRanged { ranged += 1 }
                if unit.type.isInfantry { inf += 1 }
            }
        }
        return (cav, ranged, inf)
    }

    private func handleMilitary() {
        guard let scene = gameScene else { return }

        let enemy = analyzeEnemyComposition()
        let totalEnemy = enemy.cavalry + enemy.ranged + enemy.infantry

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
                // Counter-build: skirmishers if enemy is 40%+ ranged
                if totalEnemy > 0 && enemy.ranged * 100 / max(totalEnemy, 1) > 40 {
                    _ = scene.buildingSystem.trainUnit(type: .skirmisher, at: building, player: player)
                } else if player.currentAge.rawValue >= Age.castleAge.rawValue {
                    _ = scene.buildingSystem.trainUnit(type: .crossbowman, at: building, player: player)
                } else {
                    _ = scene.buildingSystem.trainUnit(type: .archer, at: building, player: player)
                }
            case .stable:
                // Knights crush infantry-heavy compositions
                if totalEnemy > 0 && enemy.infantry * 100 / max(totalEnemy, 1) > 50 {
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
                if player.resources.wood >= 200 && player.resources.gold >= 200 {
                    _ = scene.buildingSystem.trainUnit(type: .trebuchet, at: building, player: player)
                } else if player.resources.wood >= 160 && player.resources.gold >= 75 {
                    _ = scene.buildingSystem.trainUnit(type: .batteringRam, at: building, player: player)
                }
            case .monastery:
                if player.resources.gold >= 100 {
                    _ = scene.buildingSystem.trainUnit(type: .monk, at: building, player: player)
                }
            default:
                break
            }
        }
    }

    private func handleAttack() {
        guard let scene = gameScene else { return }
        guard let humanPlayer = scene.players.first(where: { $0.isHuman }) else { return }

        let militaryUnits = player.units.filter { $0.type != .villager }
        guard !militaryUnits.isEmpty else {
            strategy = .military
            return
        }

        // Split fast units for harassment if we have enough
        let fastUnits = militaryUnits.filter { $0.type == .scout || $0.type == .lightCavalry }
        let mainArmy = militaryUnits.filter { $0.type != .scout && $0.type != .lightCavalry }

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

        if player.currentAge.rawValue >= Age.feudalAge.rawValue {
            desiredTechs.append(contentsOf: [.doubleBitAxe, .horseCollar, .forging, .fletching, .loom])
            if difficulty == .hard {
                desiredTechs.append(contentsOf: [.scaleMailArmor, .scaleBardingArmor, .bloodlines])
            }
        }

        if player.currentAge.rawValue >= Age.castleAge.rawValue {
            desiredTechs.append(contentsOf: [.bowSaw, .wheelbarrow, .ironCasting, .bodkinArrow,
                                              .chainMailArmor, .chainBardingArmor])
            if difficulty == .hard {
                desiredTechs.append(contentsOf: [.heavyPlow, .goldMining, .ballistics])
            }
        }

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

    private func advanceAgeIfPossible() {
        guard !player.isAdvancingAge else { return }
        guard player.currentAge != .imperialAge else { return }

        let nextAge = Age(rawValue: player.currentAge.rawValue + 1)!
        if player.canAfford(nextAge.advanceCost) {
            let villagerCount = player.units.filter { $0.type == .villager }.count
            if villagerCount >= (player.currentAge.rawValue * 3 + 5) {
                player.spend(nextAge.advanceCost)
                player.isAdvancingAge = true
                player.ageAdvanceProgress = 0
            }
        }
    }

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
