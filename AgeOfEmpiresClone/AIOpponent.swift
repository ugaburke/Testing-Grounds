import Foundation
import SpriteKit

class AIOpponent {
    weak var gameScene: GameScene?
    let player: Player
    var decisionTimer: CGFloat = 0
    let decisionInterval: CGFloat = 3.0
    var strategy: AIStrategy = .economy
    var rushTimer: CGFloat = 0
    var hasAttacked = false
    var defenseTimer: CGFloat = 0
    let defenseInterval: CGFloat = 2.0

    enum AIStrategy {
        case economy
        case military
        case attack
    }

    init(player: Player) {
        self.player = player
    }

    func update(deltaTime: CGFloat) {
        decisionTimer += deltaTime
        rushTimer += deltaTime

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

        // Defense check (every 2 seconds)
        defenseTimer += decisionInterval
        if defenseTimer >= defenseInterval {
            defenseTimer = 0
            handleDefense()
        }
    }

    private func handleDefense() {
        guard let scene = gameScene else { return }

        // Find damaged units or buildings under attack
        var threatPositions: [GridPosition] = []

        for unit in player.units where unit.hp < unit.maxHP {
            threatPositions.append(unit.gridPosition)
        }
        for building in player.buildings where building.hp < building.maxHP && building.isConstructed {
            threatPositions.append(building.gridPosition)
        }

        guard !threatPositions.isEmpty else { return }

        // Send idle military units to the nearest threat
        let idleMilitary = player.units.filter { $0.type != .villager && isIdle($0) }
        guard !idleMilitary.isEmpty else { return }

        // Pick the first threat
        let threatPos = threatPositions[0]

        for unit in idleMilitary {
            let dist = unit.gridPosition.distance(to: threatPos)
            if dist < 25 {
                // Find nearest enemy near the threat
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
        } else if rushTimer > 120 || militaryCount >= 12 {
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
        if villagerCount < 15 {
            if let tc = player.buildings.first(where: { $0.type == .townCenter && $0.isConstructed }) {
                if tc.trainingQueue.count < 2 {
                    _ = scene.buildingSystem.trainUnit(type: .villager, at: tc, player: player)
                }
            }
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
        }
    }

    private func handleMilitary() {
        guard let scene = gameScene else { return }

        // Train military units
        for building in player.buildings where building.isConstructed {
            guard building.trainingQueue.count < 2 else { continue }

            switch building.type {
            case .barracks:
                if player.currentAge.rawValue >= Age.feudalAge.rawValue {
                    _ = scene.buildingSystem.trainUnit(type: .manAtArms, at: building, player: player)
                } else {
                    _ = scene.buildingSystem.trainUnit(type: .militia, at: building, player: player)
                }
            case .archeryRange:
                if player.currentAge.rawValue >= Age.castleAge.rawValue {
                    _ = scene.buildingSystem.trainUnit(type: .crossbowman, at: building, player: player)
                } else {
                    _ = scene.buildingSystem.trainUnit(type: .archer, at: building, player: player)
                }
            case .stable:
                if player.currentAge.rawValue >= Age.castleAge.rawValue && player.resources.gold >= 75 {
                    _ = scene.buildingSystem.trainUnit(type: .knight, at: building, player: player)
                } else {
                    _ = scene.buildingSystem.trainUnit(type: .scout, at: building, player: player)
                }
            default:
                break
            }
        }
    }

    private func handleAttack() {
        guard let scene = gameScene else { return }

        // Find human player
        guard let humanPlayer = scene.players.first(where: { $0.isHuman }) else { return }

        let militaryUnits = player.units.filter { $0.type != .villager }
        guard !militaryUnits.isEmpty else {
            strategy = .military
            return
        }

        // Find attack target
        let target: GridPosition
        if let enemyTC = humanPlayer.buildings.first(where: { $0.type == .townCenter }) {
            target = enemyTC.gridPosition
        } else if let enemyBuilding = humanPlayer.buildings.first {
            target = enemyBuilding.gridPosition
        } else if let enemyUnit = humanPlayer.units.first {
            target = enemyUnit.gridPosition
        } else {
            return
        }

        // Send military units to attack
        for unit in militaryUnits {
            if case .idle = unit.state {
                // Find nearest enemy unit first
                var nearestEnemy: Unit?
                var nearestDist: CGFloat = .infinity
                for enemy in humanPlayer.units {
                    let dist = unit.gridPosition.distance(to: enemy.gridPosition)
                    if dist < nearestDist {
                        nearestDist = dist
                        nearestEnemy = enemy
                    }
                }

                if let enemy = nearestEnemy, nearestDist < 15 {
                    scene.unitSystem.attackTarget(unit: unit, targetID: enemy.id, pathfinder: scene.pathfinder)
                } else {
                    scene.unitSystem.moveUnit(unit, to: target, pathfinder: scene.pathfinder)
                }
            }
        }

        hasAttacked = true
    }

    private func manageVillagers() {
        guard let scene = gameScene else { return }

        let idleVillagers = player.units.filter { $0.type == .villager && isIdle($0) }

        for villager in idleVillagers {
            // Assign to resources based on need
            let resourcePriority: ResourceType
            if player.resources.food < 100 {
                resourcePriority = .food
            } else if player.resources.wood < 100 {
                resourcePriority = .wood
            } else if player.resources.gold < 50 {
                resourcePriority = .gold
            } else {
                // Balanced distribution
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

            // Find resource and send villager
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
            // Only advance if we have enough economy
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

                        // Send a villager to build
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
}
