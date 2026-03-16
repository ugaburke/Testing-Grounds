import Foundation
import SpriteKit

class BuildingSystem {
    weak var gameScene: GameScene?

    func update(deltaTime: CGFloat, player: Player, map: GameMap, spriteFactory: SpriteFactory) {
        for building in player.buildings {
            guard building.isConstructed else { continue }

            // Process training queue
            if !building.trainingQueue.isEmpty {
                let unitType = building.trainingQueue[0]
                var trainSpeed = unitType.trainTime
                if player.researchedTechs.contains(.conscription) {
                    trainSpeed *= 0.67  // 33% faster
                }
                building.trainingProgress += deltaTime / trainSpeed

                if building.trainingProgress >= 1.0 {
                    building.trainingProgress = 0
                    building.trainingQueue.removeFirst()

                    // Spawn unit
                    if player.population < player.populationCap {
                        spawnUnit(type: unitType, player: player, building: building,
                                  map: map, spriteFactory: spriteFactory)
                    }
                }
            }

            // Heal garrisoned units slowly
            if !building.garrisonedUnits.isEmpty {
                for unitID in building.garrisonedUnits {
                    if let unit = player.units.first(where: { $0.id == unitID }) {
                        if unit.hp < unit.maxHP {
                            unit.hp = min(unit.maxHP, unit.hp + 3)
                        }
                    }
                }
            }

            // Process research queue
            if let tech = building.currentResearch {
                building.researchProgress += deltaTime / tech.researchTime
                if building.researchProgress >= 1.0 {
                    player.researchedTechs.insert(tech)
                    building.currentResearch = nil
                    building.researchProgress = 0
                    if let scene = gameScene {
                        scene.hud.showStatus("\(tech.displayName) researched!")
                    }
                }
            }

            // Building attack (towers, TC, castle)
            if building.type.attackDamage > 0 {
                handleBuildingAttack(building: building, map: map)
            }

            // Smoke effect for damaged buildings (below 50% HP)
            if let scene = gameScene {
                let hpRatio = CGFloat(building.hp) / CGFloat(building.maxHP)
                if hpRatio < 0.5 && building.smokeNode == nil {
                    if let pos = building.node?.position {
                        let smoke = scene.spriteFactory.createBuildingSmokeEffect(at: pos)
                        scene.gameWorld.addChild(smoke)
                        building.smokeNode = smoke
                    }
                } else if hpRatio >= 0.5 && building.smokeNode != nil {
                    building.smokeNode?.removeFromParent()
                    building.smokeNode = nil
                }
            }

            // Wonder timer tracking
            if building.type == .wonder {
                player.wonderBuilt = true
            }
        }

        // Update population cap
        player.populationCap = player.buildings
            .filter { $0.isConstructed }
            .reduce(0) { $0 + $1.type.populationProvided }
        player.populationCap = max(player.populationCap, 5)
    }

    func placeBuilding(type: BuildingType, at gridPos: GridPosition, player: Player,
                        map: GameMap, spriteFactory: SpriteFactory) -> Building? {
        // Fish traps go on water
        if type == .fishTrap {
            guard map.canPlaceFishTrap(at: gridPos) else { return nil }
        } else {
            guard map.canPlaceBuilding(type: type, at: gridPos) else { return nil }
        }
        guard player.canAfford(type.cost) else { return nil }
        guard player.currentAge.rawValue >= type.requiredAge.rawValue else { return nil }

        player.spend(type.cost)

        let building = Building(type: type, ownerID: player.id, position: gridPos,
                                civilizationBonus: player.civilization.buildingHPBonus)

        // Mark tiles as occupied
        let size = type.size
        for dy in 0..<size.height {
            for dx in 0..<size.width {
                let tilePos = GridPosition(x: gridPos.x + dx, y: gridPos.y + dy)
                if map.isValid(tilePos) {
                    map.tiles[tilePos.y][tilePos.x].building = building
                }
            }
        }

        // If farm, set terrain
        if type == .farm {
            for dy in 0..<size.height {
                for dx in 0..<size.width {
                    let tilePos = GridPosition(x: gridPos.x + dx, y: gridPos.y + dy)
                    if map.isValid(tilePos) {
                        map.tiles[tilePos.y][tilePos.x].terrain = .farm
                        map.tiles[tilePos.y][tilePos.x].resourceRemaining = TerrainType.farm.resourceAmount
                        if let node = map.tiles[tilePos.y][tilePos.x].node {
                            node.removeAllChildren()
                            node.fillColor = TerrainType.farm.color
                            node.strokeColor = TerrainType.farm.color.withAlphaComponent(0.7)
                        }
                    }
                }
            }
        }

        player.buildings.append(building)

        // Create sprite
        let node = spriteFactory.createBuildingNode(building: building)
        let worldPos = map.gridToWorld(gridPos)
        let offsetX = CGFloat(size.width - 1) * map.tileSize / 2
        let offsetY = CGFloat(size.height - 1) * map.tileSize / 2
        node.position = CGPoint(x: worldPos.x + offsetX, y: worldPos.y + offsetY)
        building.node = node

        return building
    }

    func trainUnit(type: UnitType, at building: Building, player: Player) -> Bool {
        guard building.isConstructed else { return false }
        guard building.trainingQueue.count < 5 else { return false }
        // Resolve unique unit to civ-specific type
        let actualType = (type == .uniqueUnit) ? player.civilization.uniqueUnitType : type
        guard building.type.trainableUnits.contains(type) else { return false }
        guard player.canAfford(actualType.cost) else { return false }
        guard player.currentAge.rawValue >= actualType.requiredAge.rawValue else { return false }
        let totalQueued = player.buildings.reduce(0) { $0 + $1.trainingQueue.count }
        guard player.population + totalQueued < player.populationCap else { return false }

        player.spend(actualType.cost)
        building.trainingQueue.append(actualType)
        return true
    }

    func cancelTraining(at building: Building, player: Player) -> Bool {
        guard !building.trainingQueue.isEmpty else { return false }

        // Cancel last item in queue
        let cancelIndex = building.trainingQueue.count - 1
        let unitType = building.trainingQueue[cancelIndex]
        building.trainingQueue.remove(at: cancelIndex)

        // If we canceled the actively training unit (index 0), reset progress
        if cancelIndex == 0 {
            building.trainingProgress = 0
        }

        // Refund 75% of cost
        let cost = unitType.cost
        player.resources.food += Int(Double(cost.food) * 0.75)
        player.resources.wood += Int(Double(cost.wood) * 0.75)
        player.resources.gold += Int(Double(cost.gold) * 0.75)
        player.resources.stone += Int(Double(cost.stone) * 0.75)

        return true
    }

    private func spawnUnit(type: UnitType, player: Player, building: Building,
                            map: GameMap, spriteFactory: SpriteFactory) {
        // Find spawn position near building
        let spawnPos = findSpawnPosition(near: building, map: map)
        guard let pos = spawnPos else {
            // Re-queue the unit so it retries next frame instead of being lost
            building.trainingQueue.insert(type, at: 0)
            return
        }

        let hpBonus: CGFloat = type.isCavalry ? player.civilization.cavalryHPBonus : 1.0
        let unit = Unit(type: type, ownerID: player.id, position: pos,
                        hpBonus: hpBonus, speedBonus: type.isCavalry ? player.civilization.cavalrySpeedBonus : 1.0)
        unit.ownerPlayer = player
        unit.gridPosition = pos
        unit.position = map.gridToWorld(pos)
        // Apply loom HP bonus for villagers
        if type == .villager && player.researchedTechs.contains(.loom) {
            unit.maxHP += 15
            unit.hp = unit.maxHP
        }
        // Apply bloodlines HP bonus for cavalry
        if type.isCavalry && player.researchedTechs.contains(.bloodlines) {
            unit.maxHP += 20
            unit.hp = unit.maxHP
        }
        // Apply sanctity HP bonus for monks
        if type == .monk && player.researchedTechs.contains(.sanctity) {
            unit.maxHP = Int(CGFloat(unit.maxHP) * 1.5)
            unit.hp = unit.maxHP
        }
        // Apply infantry HP bonus (Vikings)
        if type.isInfantry {
            let infBonus = player.civilization.infantryHPBonus
            if infBonus != 1.0 {
                unit.maxHP = Int(CGFloat(unit.maxHP) * infBonus)
                unit.hp = unit.maxHP
            }
        }

        let node = spriteFactory.createUnitNode(unit: unit)
        node.position = unit.position
        unit.node = node

        // Move to rally point if set
        if let rally = building.rallyPoint {
            unit.state = .moving(to: rally)
        }

        player.units.append(unit)

        if let scene = gameScene {
            scene.gameWorld.addChild(node)
        }
    }

    private func findSpawnPosition(near building: Building, map: GameMap) -> GridPosition? {
        let size = building.type.size
        let baseX = building.gridPosition.x
        let baseY = building.gridPosition.y

        // Check around the building perimeter
        var candidates: [GridPosition] = []

        for dx in -1...(size.width) {
            for dy in -1...(size.height) {
                if dx == -1 || dx == size.width || dy == -1 || dy == size.height {
                    let pos = GridPosition(x: baseX + dx, y: baseY + dy)
                    if map.isPassable(pos) {
                        candidates.append(pos)
                    }
                }
            }
        }

        return candidates.randomElement()
    }

    private func handleBuildingAttack(building: Building, map: GameMap) {
        guard let scene = gameScene else { return }

        let ownerPlayer = scene.players.first { $0.id == building.ownerID }
        let range = building.type.attackRange
        let garrisonBonus = building.garrisonedUnits.count * 2
        var damage = building.type.attackDamage + garrisonBonus
        // Arrowslits: towers get +3 attack
        if building.type == .tower, let p = ownerPlayer, p.researchedTechs.contains(.arrowslits) {
            damage += 3
        }
        // Heated Shot: towers do +4 vs naval units
        let hasHeatedShot = ownerPlayer?.researchedTechs.contains(.heatedShot) ?? false

        // Find nearest enemy unit in range
        for player in scene.players {
            guard player.id != building.ownerID else { continue }
            for unit in player.units {
                let dist = building.gridPosition.distance(to: unit.gridPosition)
                if dist <= range {
                    let currentTime = scene.gameTime
                    let buildingKey = "building_attack_\(building.id)"
                    let lastAttack = scene.lastBuildingAttackTimes[buildingKey] ?? 0
                    if currentTime - lastAttack >= 2.0 {
                        var finalDamage = damage
                        if hasHeatedShot && unit.type.isNaval { finalDamage += 4 }
                        unit.hp -= finalDamage
                        scene.lastBuildingAttackTimes[buildingKey] = currentTime

                        // Visual effect
                        let effect = scene.spriteFactory.createAttackEffect(
                            at: unit.position, isRanged: true)
                        scene.gameWorld.addChild(effect)

                        let fadeOut = SKAction.sequence([
                            SKAction.wait(forDuration: 0.3),
                            SKAction.removeFromParent()
                        ])
                        effect.run(fadeOut)

                        // If building has garrisoned ranged units, show arrow projectile
                        if !building.garrisonedUnits.isEmpty, let buildingPos = building.node?.position {
                            let projectile = scene.spriteFactory.createAttackEffect(at: buildingPos, isRanged: true)
                            scene.gameWorld.addChild(projectile)
                            let moveToTarget = SKAction.move(to: unit.position, duration: 0.3)
                            projectile.run(SKAction.sequence([moveToTarget, SKAction.removeFromParent()]))
                        }
                    }
                    return
                }
            }
        }
    }

    func destroyBuilding(_ building: Building, player: Player, map: GameMap) {
        let size = building.type.size

        // Leave rubble behind
        if let scene = gameScene, let pos = building.node?.position, building.type != .wall && building.type != .farm {
            let rubbleSize = CGSize(width: CGFloat(size.width) * map.tileSize,
                                     height: CGFloat(size.height) * map.tileSize)
            let rubble = scene.spriteFactory.createRubbleNode(at: pos, size: rubbleSize)
            scene.gameWorld.addChild(rubble)
        }

        // Remove smoke effect
        building.smokeNode?.removeFromParent()
        building.smokeNode = nil

        // Track wonder destruction
        if building.type == .wonder {
            player.wonderBuilt = false
            player.wonderTimer = 0
        }

        for dy in 0..<size.height {
            for dx in 0..<size.width {
                let tilePos = GridPosition(x: building.gridPosition.x + dx, y: building.gridPosition.y + dy)
                if map.isValid(tilePos) {
                    map.tiles[tilePos.y][tilePos.x].building = nil
                    if building.type == .farm {
                        map.tiles[tilePos.y][tilePos.x].terrain = .grass
                        if let node = map.tiles[tilePos.y][tilePos.x].node {
                            node.fillColor = TerrainType.grass.color
                            node.strokeColor = TerrainType.grass.color.withAlphaComponent(0.7)
                        }
                    }
                }
            }
        }

        // Ungarrison all units
        for unitID in building.garrisonedUnits {
            if let unit = player.units.first(where: { $0.id == unitID }) {
                unit.state = .idle
                unit.node?.isHidden = false
                // Place near building
                let spawnOffset = GridPosition(x: building.gridPosition.x - 1, y: building.gridPosition.y - 1)
                if map.isValid(spawnOffset) && map.isPassable(spawnOffset) {
                    unit.gridPosition = spawnOffset
                    unit.position = map.gridToWorld(spawnOffset)
                    unit.node?.position = unit.position
                }
            }
        }
        building.garrisonedUnits.removeAll()

        building.rallyFlagNode?.removeFromParent()
        building.node?.removeFromParent()
        player.buildings.removeAll { $0.id == building.id }
    }

    func cancelResearch(at building: Building, player: Player) -> Bool {
        guard let tech = building.currentResearch else { return false }
        // Refund 50% of cost
        let cost = tech.cost
        player.resources.food += Int(Double(cost.food) * 0.5)
        player.resources.wood += Int(Double(cost.wood) * 0.5)
        player.resources.gold += Int(Double(cost.gold) * 0.5)
        player.resources.stone += Int(Double(cost.stone) * 0.5)
        building.currentResearch = nil
        building.researchProgress = 0
        return true
    }

    func toggleAutoReseed(building: Building) {
        guard building.type == .farm else { return }
        building.autoReseed = !building.autoReseed
    }
}
