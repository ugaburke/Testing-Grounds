import Foundation
import SpriteKit

class ResourceSystem {
    weak var gameScene: GameScene?
    let gatherRate: CGFloat = 0.4   // base gather rate per second
    let carryCapacity: Int = 10

    func update(deltaTime: CGFloat, player: Player, map: GameMap, pathfinder: Pathfinder) {
        for unit in player.units {
            guard unit.type == .villager else { continue }

            switch unit.state {
            case .gathering(let resourceType, let tilePos):
                handleGathering(unit: unit, resourceType: resourceType, tilePos: tilePos,
                               player: player, map: map, deltaTime: deltaTime, pathfinder: pathfinder)

            case .returning(let dropOff, let resourceType, let carried):
                handleReturning(unit: unit, dropOff: dropOff, resourceType: resourceType,
                               carried: carried, player: player, map: map, pathfinder: pathfinder)

            case .building(let buildingID):
                handleBuilding(unit: unit, buildingID: buildingID, player: player, deltaTime: deltaTime)

            default:
                break
            }
        }

        // Farm auto-gathering
        for building in player.buildings where building.type == .farm && building.isConstructed {
            let tile = map.tile(at: building.gridPosition)
            if tile?.terrain != .farm {
                tile?.terrain = .farm
                tile?.resourceRemaining = TerrainType.farm.resourceAmount
            }
        }
    }

    private func handleGathering(unit: Unit, resourceType: ResourceType, tilePos: GridPosition,
                                  player: Player, map: GameMap, deltaTime: CGFloat, pathfinder: Pathfinder) {
        // Check if unit is at the resource tile
        let dist = unit.gridPosition.distance(to: tilePos)
        if dist > 1.5 {
            // Move to resource
            if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: tilePos)
            }
            return
        }

        guard let tile = map.tile(at: tilePos) else { return }

        if tile.resourceRemaining <= 0 {
            // Resource depleted, find another
            if let newTile = map.findNearestResource(resourceType, from: unit.gridPosition) {
                unit.state = .gathering(resourceType: resourceType, tilePos: newTile)
            } else {
                unit.state = .idle
            }
            return
        }

        // Gather resources
        let gatherSpeed = gatherRate * player.civilization.gatherSpeedBonus
        let amountToGather = Int(gatherSpeed * deltaTime * 10)

        if amountToGather > 0 {
            let actualGathered = min(amountToGather, tile.resourceRemaining, carryCapacity - unit.carriedAmount)
            tile.resourceRemaining -= actualGathered
            unit.carriedAmount += actualGathered
            unit.carriedResource = resourceType

            // Show gather effect
            if let scene = gameScene, Int.random(in: 0..<10) == 0 {
                let effect = scene.spriteFactory.createGatherEffect(
                    at: map.gridToWorld(tilePos), resourceType: resourceType)
                scene.gameWorld.addChild(effect)
            }

            // Update tile visual if depleted
            if tile.resourceRemaining <= 0 {
                tile.terrain = .grass
                if let node = tile.node {
                    node.removeAllChildren()
                    node.fillColor = TerrainType.grass.color
                    node.strokeColor = TerrainType.grass.color.withAlphaComponent(0.7)
                }
            }
        }

        // Return when full
        if unit.carriedAmount >= carryCapacity {
            if let dropOff = map.findNearestDropOff(for: resourceType, ownerID: player.id,
                                                     from: unit.gridPosition, buildings: player.buildings) {
                unit.state = .returning(dropOff: dropOff, resourceType: resourceType, carried: unit.carriedAmount)
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: dropOff)
            }
        }
    }

    private func handleReturning(unit: Unit, dropOff: GridPosition, resourceType: ResourceType,
                                  carried: Int, player: Player, map: GameMap, pathfinder: Pathfinder) {
        let dist = unit.gridPosition.distance(to: dropOff)
        if dist > 2.0 {
            if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: dropOff)
            }
            return
        }

        // Deposit resources
        switch resourceType {
        case .food: player.resources.food += carried
        case .wood: player.resources.wood += carried
        case .gold: player.resources.gold += carried
        case .stone: player.resources.stone += carried
        }

        // Deposit feedback: "+N" floating text
        if let scene = gameScene {
            let worldPos = map.gridToWorld(dropOff)
            let feedback = scene.spriteFactory.createDepositFeedback(at: worldPos, amount: carried, resourceType: resourceType)
            scene.gameWorld.addChild(feedback)
        }

        unit.carriedAmount = 0
        unit.carriedResource = nil

        // Go back to gathering
        if let tile = map.findNearestResource(resourceType, from: unit.gridPosition) {
            unit.state = .gathering(resourceType: resourceType, tilePos: tile)
            unit.path = pathfinder.findPath(from: unit.gridPosition, to: tile)
        } else {
            unit.state = .idle
        }
    }

    private func handleBuilding(unit: Unit, buildingID: Int, player: Player, deltaTime: CGFloat) {
        guard let building = player.buildings.first(where: { $0.id == buildingID }) else {
            unit.state = .idle
            return
        }

        if building.isConstructed {
            unit.state = .idle
            return
        }

        let dist = unit.gridPosition.distance(to: building.gridPosition)
        if dist > 2.5 {
            return
        }

        // Build progress
        let buildRate: CGFloat = 1.0 / building.type.buildTime
        building.constructionProgress += buildRate * deltaTime
        building.hp = max(1, Int(CGFloat(building.maxHP) * building.constructionProgress))

        if building.constructionProgress >= 1.0 {
            building.constructionProgress = 1.0
            building.isConstructed = true
            building.hp = building.maxHP
            unit.state = .idle

            // Completion feedback: flash effect
            if let node = building.node {
                let flash = SKAction.sequence([
                    SKAction.run { node.children.forEach { child in
                        if let shape = child as? SKShapeNode, shape.name == "buildingBody" {
                            shape.fillColor = .white
                        }
                    }},
                    SKAction.wait(forDuration: 0.15),
                    SKAction.run { [weak building] in
                        guard let building = building else { return }
                        if let shape = node.childNode(withName: "buildingBody") as? SKShapeNode {
                            shape.fillColor = building.type.color
                        }
                    }
                ])
                node.run(flash)
            }

            // Status message for human player
            if let scene = gameScene, building.ownerID == scene.humanPlayer.id {
                scene.hud.showStatus("\(building.type.displayName) completed!")
            }
        }
    }

    func sendVillagerToGather(unit: Unit, tilePos: GridPosition, map: GameMap, pathfinder: Pathfinder) {
        guard unit.type == .villager else { return }
        guard let tile = map.tile(at: tilePos) else { return }

        if let resourceType = tile.terrain.resourceType, tile.resourceRemaining > 0 {
            unit.state = .gathering(resourceType: resourceType, tilePos: tilePos)
            unit.path = pathfinder.findPath(from: unit.gridPosition, to: tilePos)
        }
    }

    func sendVillagerToBuild(unit: Unit, building: Building, pathfinder: Pathfinder) {
        guard unit.type == .villager else { return }
        unit.state = .building(buildingID: building.id)
        unit.path = pathfinder.findPath(from: unit.gridPosition, to: building.gridPosition)
    }
}
