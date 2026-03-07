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
                building.trainingProgress += deltaTime / unitType.trainTime

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
        }

        // Update population cap
        player.populationCap = player.buildings
            .filter { $0.isConstructed }
            .reduce(0) { $0 + $1.type.populationProvided }
        player.populationCap = max(player.populationCap, 5)
    }

    func placeBuilding(type: BuildingType, at gridPos: GridPosition, player: Player,
                        map: GameMap, spriteFactory: SpriteFactory) -> Building? {
        guard map.canPlaceBuilding(type: type, at: gridPos) else { return nil }
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

    private func spawnUnit(type: UnitType, player: Player, building: Building,
                            map: GameMap, spriteFactory: SpriteFactory) {
        // Find spawn position near building
        let spawnPos = findSpawnPosition(near: building, map: map)
        guard let pos = spawnPos else { return }

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

        let range = building.type.attackRange
        let damage = building.type.attackDamage

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
                        unit.hp -= damage
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
                    }
                    return
                }
            }
        }
    }

    func destroyBuilding(_ building: Building, player: Player, map: GameMap) {
        let size = building.type.size
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

        building.node?.removeFromParent()
        player.buildings.removeAll { $0.id == building.id }
    }
}
