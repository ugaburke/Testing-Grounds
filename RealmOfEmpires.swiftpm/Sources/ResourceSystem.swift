import Foundation
import SpriteKit

class ResourceSystem {
    weak var gameScene: GameScene?
    let gatherRate: CGFloat = 0.6   // base gather rate per second
    let baseCarryCapacity: Int = 15

    func effectiveCarryCapacity(for player: Player) -> Int {
        var cap = baseCarryCapacity
        if player.researchedTechs.contains(.wheelbarrow) { cap += 5 }
        if player.researchedTechs.contains(.handCart) { cap += 5 }
        return cap
    }

    func effectiveGatherSpeed(for player: Player, resourceType: ResourceType) -> CGFloat {
        var speed = gatherRate * player.civilization.gatherSpeedBonus
        // Wheelbarrow & Hand Cart: +10% gather speed each
        if player.researchedTechs.contains(.wheelbarrow) { speed *= 1.1 }
        if player.researchedTechs.contains(.handCart) { speed *= 1.1 }
        // Resource-specific techs
        switch resourceType {
        case .wood:
            if player.researchedTechs.contains(.doubleBitAxe) { speed *= 1.2 }
            if player.researchedTechs.contains(.bowSaw) { speed *= 1.2 }
        case .food:
            if player.researchedTechs.contains(.horseCollar) { speed *= 1.25 }
            if player.researchedTechs.contains(.heavyPlow) { speed *= 1.25 }
        case .gold:
            if player.researchedTechs.contains(.goldMining) { speed *= 1.15 }
        case .stone:
            if player.researchedTechs.contains(.stoneMining) { speed *= 1.15 }
        }
        return speed
    }

    var marketFluctuationTimer: CGFloat = 0
    var depletionWarningTimer: CGFloat = 0

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

            case .repairing(let buildingID):
                handleRepairing(unit: unit, buildingID: buildingID, player: player, deltaTime: deltaTime)

            default:
                break
            }
        }

        // Handle fishing boats
        for unit in player.units where unit.type == .fishingBoat {
            if case .fishing(let tilePos) = unit.state {
                handleFishing(unit: unit, tilePos: tilePos, player: player, map: map, deltaTime: deltaTime, pathfinder: pathfinder)
            }
        }

        // Handle trade carts
        for unit in player.units where unit.type == .tradeCart {
            if case .trading(let marketPos, let targetMarketPos) = unit.state {
                handleTrading(unit: unit, marketPos: marketPos, targetMarketPos: targetMarketPos, player: player, map: map, pathfinder: pathfinder)
            }
        }

        // Fish trap income
        for building in player.buildings where building.type == .fishTrap && building.isConstructed {
            let tile = map.tile(at: building.gridPosition)
            if let tile = tile, tile.resourceRemaining > 0 {
                let fishRate: CGFloat = 0.6 * player.civilization.fishingBonus * deltaTime * 10
                let amount = Int(fishRate)
                if amount > 0 {
                    tile.resourceRemaining -= amount
                    player.resources.food += amount
                }
            }
        }

        // Relic gold income (30 gold per relic per 30 seconds)
        if player.relicsCollected > 0 {
            let relicGoldRate = CGFloat(player.relicsCollected) * deltaTime * 1.0
            let goldAmount = Int(relicGoldRate)
            if goldAmount > 0 {
                player.resources.gold += goldAmount
            }
        }

        // Market price fluctuation (every 60 seconds)
        marketFluctuationTimer += deltaTime
        if marketFluctuationTimer >= 60.0 {
            marketFluctuationTimer = 0
            fluctuateMarketPrices(player: player)
        }

        // Resource depletion warnings (every 5 seconds)
        depletionWarningTimer += deltaTime
        if depletionWarningTimer >= 5.0 {
            depletionWarningTimer = 0
            checkResourceWarnings(player: player, map: map)
        }

        // Farm auto-gathering and auto-reseed
        for building in player.buildings where building.type == .farm && building.isConstructed {
            let tile = map.tile(at: building.gridPosition)
            if tile?.terrain != .farm {
                tile?.terrain = .farm
                tile?.resourceRemaining = TerrainType.farm.resourceAmount
            }
            // Auto-reseed: if farm is depleted and auto-reseed is on, reset resources
            if let tile = tile, tile.resourceRemaining <= 0 && building.autoReseed {
                if player.resources.wood >= 30 {
                    player.resources.wood -= 30
                    tile.resourceRemaining = TerrainType.farm.resourceAmount
                    if let scene = gameScene {
                        scene.hud.showStatus("Farm auto-reseeded")
                    }
                }
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

        // Gather resources using accumulator for sub-frame precision
        let gatherSpeed = effectiveGatherSpeed(for: player, resourceType: resourceType)
        let carryCapacity = effectiveCarryCapacity(for: player)
        unit.gatherAccumulator += gatherSpeed * deltaTime * 10
        let amountToGather = Int(unit.gatherAccumulator)

        if amountToGather > 0 {
            unit.gatherAccumulator -= CGFloat(amountToGather)
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
        if unit.carriedAmount >= carryCapacity || (amountToGather > 0 && tile.resourceRemaining <= 0 && unit.carriedAmount > 0) {
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

    private func handleFishing(unit: Unit, tilePos: GridPosition, player: Player, map: GameMap, deltaTime: CGFloat, pathfinder: Pathfinder) {
        let dist = unit.gridPosition.distance(to: tilePos)
        if dist > 2.0 {
            if unit.path.isEmpty {
                // Water pathfinding: just move directly since boats go over water
                unit.path = [tilePos]
            }
            return
        }

        guard let tile = map.tile(at: tilePos) else { return }
        guard tile.terrain == .water || tile.terrain == .deepWater else {
            unit.state = .idle
            return
        }

        // Generate food from fishing
        unit.gatherAccumulator += 0.5 * deltaTime * 10
        let amount = Int(unit.gatherAccumulator)
        if amount > 0 {
            unit.gatherAccumulator -= CGFloat(amount)
            player.resources.food += amount
        }
    }

    private func handleTrading(unit: Unit, marketPos: GridPosition, targetMarketPos: GridPosition, player: Player, map: GameMap, pathfinder: Pathfinder) {
        let distToTarget = unit.gridPosition.distance(to: targetMarketPos)
        let distToHome = unit.gridPosition.distance(to: marketPos)

        if unit.tradeGold == 0 {
            // Going to target market
            if distToTarget <= 2.0 {
                // Calculate gold based on distance between markets
                let tradeDist = marketPos.distance(to: targetMarketPos)
                unit.tradeGold = max(5, Int(tradeDist * 1.5))
                // Now head back
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: marketPos)
            } else if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: targetMarketPos)
            }
        } else {
            // Returning to home market
            if distToHome <= 2.0 {
                var goldEarned = unit.tradeGold
                if player.researchedTechs.contains(.guilds) {
                    goldEarned = Int(CGFloat(goldEarned) * 1.15)
                }
                player.resources.gold += goldEarned
                if let scene = gameScene {
                    let feedback = scene.spriteFactory.createDepositFeedback(
                        at: map.gridToWorld(marketPos), amount: unit.tradeGold, resourceType: .gold)
                    scene.gameWorld.addChild(feedback)
                }
                unit.tradeGold = 0
                // Go back to target market
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: targetMarketPos)
            } else if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: marketPos)
            }
        }
    }

    func checkResourceWarnings(player: Player, map: GameMap) {
        guard let scene = gameScene else { return }

        // Check for depleted resource tiles near active gatherers
        for unit in player.units where unit.type == .villager {
            if case .gathering(let rt, let tilePos) = unit.state {
                if let tile = map.tile(at: tilePos), tile.resourceRemaining > 0 && tile.resourceRemaining < 20 {
                    let resourceName: String
                    switch rt {
                    case .food: resourceName = "Food"
                    case .wood: resourceName = "Wood"
                    case .gold: resourceName = "Gold"
                    case .stone: resourceName = "Stone"
                    }
                    scene.hud.showStatus("\(resourceName) running low nearby!")
                    return // Only show one warning per cycle
                }
            }
        }

        // Warn about critically low total resources
        if player.resources.food < 30 && player.resources.food > 0 {
            scene.hud.showStatus("Food reserves critically low!")
        } else if player.resources.wood < 30 && player.resources.wood > 0 {
            scene.hud.showStatus("Wood reserves critically low!")
        } else if player.resources.gold < 20 && player.resources.gold > 0 {
            scene.hud.showStatus("Gold reserves critically low!")
        }
    }

    func autoAssignVillager(_ unit: Unit, player: Player, map: GameMap, pathfinder: Pathfinder) {
        guard unit.type == .villager else { return }

        let foodWorkers = player.units.filter { if case .gathering(.food, _) = $0.state { return true }; return false }.count
        let woodWorkers = player.units.filter { if case .gathering(.wood, _) = $0.state { return true }; return false }.count
        let goldWorkers = player.units.filter { if case .gathering(.gold, _) = $0.state { return true }; return false }.count

        // Target ratios: food 40%, wood 30%, gold 20%, stone 10%
        let totalWorkers = max(1, foodWorkers + woodWorkers + goldWorkers)
        let foodRatio = CGFloat(foodWorkers) / CGFloat(totalWorkers)
        let woodRatio = CGFloat(woodWorkers) / CGFloat(totalWorkers)

        let resourcePriority: ResourceType
        if player.resources.food < 50 || foodRatio < 0.3 {
            resourcePriority = .food
        } else if player.resources.wood < 50 || woodRatio < 0.2 {
            resourcePriority = .wood
        } else if player.resources.gold < 30 {
            resourcePriority = .gold
        } else if player.resources.stone < 20 {
            resourcePriority = .stone
        } else {
            resourcePriority = .food
        }

        if let tile = map.findNearestResource(resourcePriority, from: unit.gridPosition) {
            sendVillagerToGather(unit: unit, tilePos: tile, map: map, pathfinder: pathfinder)
        }
    }

    // MARK: - Repair

    private func handleRepairing(unit: Unit, buildingID: Int, player: Player, deltaTime: CGFloat) {
        guard let building = player.buildings.first(where: { $0.id == buildingID }) else {
            unit.state = .idle
            return
        }

        if building.hp >= building.maxHP {
            unit.state = .idle
            return
        }

        let dist = unit.gridPosition.distance(to: building.gridPosition)
        if dist > 2.5 {
            return
        }

        // Repair rate: 1% of max HP per second, costs resources proportionally
        let repairRate = CGFloat(building.maxHP) * 0.01 * deltaTime
        let hpToRepair = min(repairRate, CGFloat(building.maxHP - building.hp))
        let costFraction = hpToRepair / CGFloat(building.maxHP)
        let woodCost = Int(CGFloat(building.type.cost.wood) * costFraction * 0.5)
        let stoneCost = Int(CGFloat(building.type.cost.stone) * costFraction * 0.5)

        if player.resources.wood >= max(woodCost, 1) || player.resources.stone >= max(stoneCost, 1) {
            building.hp = min(building.maxHP, building.hp + max(1, Int(hpToRepair)))
            player.resources.wood -= min(woodCost, player.resources.wood)
            player.resources.stone -= min(stoneCost, player.resources.stone)
        }
    }

    func sendVillagerToRepair(unit: Unit, building: Building, pathfinder: Pathfinder) {
        guard unit.type == .villager else { return }
        guard building.hp < building.maxHP else { return }
        unit.state = .repairing(buildingID: building.id)
        unit.path = pathfinder.findPath(from: unit.gridPosition, to: building.gridPosition)
    }

    // MARK: - Market

    private func fluctuateMarketPrices(player: Player) {
        // Prices fluctuate between 0.6 and 1.4
        for resource in [ResourceType.food, .wood, .gold, .stone] {
            let current = player.marketPrices[resource] ?? 1.0
            let change = CGFloat.random(in: -0.1...0.1)
            player.marketPrices[resource] = max(0.6, min(1.4, current + change))
        }
    }

    func marketTrade(buy: ResourceType, sell: ResourceType, player: Player, amount: Int = 100) -> Bool {
        // Market exchange rate: affected by fluctuating prices
        let sellPrice = player.marketPrices[sell] ?? 1.0
        let buyPrice = player.marketPrices[buy] ?? 1.0
        let sellAmount = amount
        let buyAmount = Int(Double(amount) * 0.9 * Double(sellPrice / buyPrice))

        switch sell {
        case .food: guard player.resources.food >= sellAmount else { return false }
        case .wood: guard player.resources.wood >= sellAmount else { return false }
        case .gold: guard player.resources.gold >= sellAmount else { return false }
        case .stone: guard player.resources.stone >= sellAmount else { return false }
        }

        // Deduct sold resource
        switch sell {
        case .food: player.resources.food -= sellAmount
        case .wood: player.resources.wood -= sellAmount
        case .gold: player.resources.gold -= sellAmount
        case .stone: player.resources.stone -= sellAmount
        }

        // Add bought resource
        switch buy {
        case .food: player.resources.food += buyAmount
        case .wood: player.resources.wood += buyAmount
        case .gold: player.resources.gold += buyAmount
        case .stone: player.resources.stone += buyAmount
        }

        return true
    }
}
