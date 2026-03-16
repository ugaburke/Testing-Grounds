import Foundation
import SpriteKit

enum FormationType {
    case box
    case line
    case spread
}

class UnitSystem {
    weak var gameScene: GameScene?
    let moveStepDuration: CGFloat = 0.3

    func update(deltaTime: CGFloat, player: Player, map: GameMap, pathfinder: Pathfinder) {
        for unit in player.units {
            // Move along path
            if !unit.path.isEmpty {
                moveAlongPath(unit: unit, map: map, deltaTime: deltaTime, player: player)
            }

            // Update attack cooldown
            if unit.attackCooldown > 0 {
                unit.attackCooldown -= deltaTime
            }

            // Auto-scout behavior
            if case .autoScouting = unit.state {
                handleAutoScout(unit: unit, player: player, map: map, pathfinder: pathfinder)
            }

            // Reset tilesMoved when unit is idle (not moving)
            if case .idle = unit.state, unit.path.isEmpty {
                unit.tilesMoved = 0
            }

            // Auto-attack nearby enemies if idle or moving
            let shouldAutoAttack: Bool
            switch unit.state {
            case .idle: shouldAutoAttack = (unit.stance != .noAttack)
            case .moving: shouldAutoAttack = (unit.stance != .standGround && unit.stance != .noAttack)
            default: shouldAutoAttack = false
            }
            if shouldAutoAttack && unit.type != .villager {
                if case .moving = unit.state {
                    autoAttackNearby(unit: unit, player: player, pathfinder: pathfinder, range: 3.0)
                } else {
                    autoAttackNearby(unit: unit, player: player, pathfinder: pathfinder)
                }
            }

            // Resume movement after combat if saved destination exists
            if case .idle = unit.state, let dest = unit.savedMoveDestination {
                unit.state = .moving(to: dest)
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: dest)
                unit.savedMoveDestination = nil
            }

            // Attack-move: move toward target, engage enemies along the way
            if case .attackMoving(let dest) = unit.state {
                if unit.path.isEmpty && unit.gridPosition.distance(to: dest) > 1.5 {
                    unit.path = pathfinder.findPath(from: unit.gridPosition, to: dest)
                }
                // Scan for nearby enemies while moving
                if let enemyID = findNearbyEnemy(unit: unit, player: player, range: 6.0) {
                    unit.attackMoveDestination = dest
                    unit.state = .attacking(targetUnitID: enemyID)
                } else if unit.path.isEmpty {
                    unit.state = .idle
                    unit.attackMoveDestination = nil
                }
            }

            // Resume attack-move after killing target
            if case .idle = unit.state, let dest = unit.attackMoveDestination {
                unit.state = .attackMoving(to: dest)
                unit.attackMoveDestination = nil
            }

            // Patrolling: move between two points, engage enemies
            if case .patrolling(let from, let to) = unit.state {
                if unit.path.isEmpty && unit.gridPosition.distance(to: to) > 1.5 {
                    unit.path = pathfinder.findPath(from: unit.gridPosition, to: to)
                }
                if let enemyID = findNearbyEnemy(unit: unit, player: player, range: 6.0) {
                    unit.patrolPoints = (from, to)
                    unit.state = .attacking(targetUnitID: enemyID)
                } else if unit.path.isEmpty {
                    // Reached destination, reverse patrol
                    unit.state = .patrolling(from: to, to: from)
                }
            }

            // Resume patrol after killing target
            if case .idle = unit.state, let points = unit.patrolPoints {
                unit.state = .patrolling(from: points.0, to: points.1)
                unit.patrolPoints = nil
            }

            // Process command queue (shift-queue)
            if case .idle = unit.state, !unit.commandQueue.isEmpty {
                processCommandQueue(unit: unit, pathfinder: pathfinder)
            }
        }
    }

    private func findNearbyEnemy(unit: Unit, player: Player, range: CGFloat) -> Int? {
        guard let scene = gameScene else { return nil }
        for enemy in scene.players where enemy.id != player.id {
            for enemyUnit in enemy.units {
                let dist = unit.gridPosition.distance(to: enemyUnit.gridPosition)
                if dist <= range {
                    return enemyUnit.id
                }
            }
        }
        return nil
    }

    private func moveAlongPath(unit: Unit, map: GameMap, deltaTime: CGFloat, player: Player) {
        guard let nextPos = unit.path.first else { return }

        let targetWorldPos = map.gridToWorld(nextPos)
        let dx = targetWorldPos.x - unit.position.x
        let dy = targetWorldPos.y - unit.position.y
        let dist = sqrt(dx * dx + dy * dy)

        // Smooth turning: interpolate facing direction instead of snapping
        if dist > 0.5 {
            let targetAngle = atan2(dy, dx)
            let angleDiff = targetAngle - unit.lastDirection
            let normalizedDiff = atan2(sin(angleDiff), cos(angleDiff))
            unit.lastDirection += normalizedDiff * min(1.0, deltaTime * 8.0)
        }

        var speedMultiplier: CGFloat = unit.type.isCavalry ? player.civilization.cavalrySpeedBonus : 1.0
        // Fervor: monks move 15% faster
        if unit.type == .monk, player.researchedTechs.contains(.fervor) {
            speedMultiplier *= 1.15
        }
        // Squires: infantry move 10% faster
        if unit.type.isInfantry, player.researchedTechs.contains(.squires) {
            speedMultiplier *= 1.1
        }
        let speed = unit.type.moveSpeed * speedMultiplier * map.tileSize * 2.0

        // Track distance moved for cavalry charge bonus
        unit.tilesMoved += deltaTime * speed / (map.tileSize * 2.0)

        if dist < 2.0 {
            unit.position = targetWorldPos
            unit.gridPosition = nextPos
            unit.path.removeFirst()
            unit.velocity = .zero
            unit.node?.position = unit.position
        } else {
            // Smooth movement using velocity interpolation
            let desiredVelX = (dx / dist) * speed
            let desiredVelY = (dy / dist) * speed
            unit.targetVelocity = CGPoint(x: desiredVelX, y: desiredVelY)

            // Lerp current velocity toward desired velocity (acceleration/deceleration)
            let lerpFactor: CGFloat = 0.15
            unit.velocity.x += (unit.targetVelocity.x - unit.velocity.x) * lerpFactor
            unit.velocity.y += (unit.targetVelocity.y - unit.velocity.y) * lerpFactor

            unit.position.x += unit.velocity.x * deltaTime
            unit.position.y += unit.velocity.y * deltaTime
            unit.node?.position = unit.position

            // Update grid position based on nearest tile
            unit.gridPosition = map.worldToGrid(unit.position)
        }

        // Apply separation force from nearby units
        if let scene = gameScene {
            applySeparation(unit: unit, allPlayers: scene.players, map: map)
        }

        // Spawn movement dust particles on land
        unit.dustTimer += deltaTime
        if unit.dustTimer >= 0.3 {
            unit.dustTimer = 0
            let tile = map.worldToGrid(unit.position)
            if map.isValid(tile) && map.tiles[tile.y][tile.x].terrain.isPassable {
                if let scene = gameScene {
                    let dust = scene.spriteFactory.createMovementDust(at: unit.position)
                    scene.gameWorld.addChild(dust)
                }
            }
        }
    }

    private func applySeparation(unit: Unit, allPlayers: [Player], map: GameMap) {
        let separationRadius: CGFloat = 1.5 * map.tileSize
        var pushX: CGFloat = 0
        var pushY: CGFloat = 0

        for player in allPlayers {
            for other in player.units {
                guard other.id != unit.id else { continue }
                let dx = unit.position.x - other.position.x
                let dy = unit.position.y - other.position.y
                let dist = sqrt(dx * dx + dy * dy)
                if dist < separationRadius && dist > 0.1 {
                    // Weighted repulsion: closer units push harder
                    let strength = (separationRadius - dist) / separationRadius
                    pushX += (dx / dist) * strength
                    pushY += (dy / dist) * strength
                }
            }
        }

        let pushMag = sqrt(pushX * pushX + pushY * pushY)
        if pushMag > 0.01 {
            // Cap separation offset at 30% of move speed per frame
            let maxPush: CGFloat = unit.type.moveSpeed * map.tileSize * 0.3
            let cappedMag = min(pushMag, maxPush)
            let finalX = (pushX / pushMag) * cappedMag
            let finalY = (pushY / pushMag) * cappedMag

            let newPos = CGPoint(x: unit.position.x + finalX, y: unit.position.y + finalY)
            let newGrid = map.worldToGrid(newPos)

            // Only apply if the resulting position is passable
            if map.isPassable(newGrid) {
                unit.position = newPos
                unit.node?.position = unit.position
            }
        }
    }

    func moveUnit(_ unit: Unit, to target: GridPosition, pathfinder: Pathfinder) {
        // Trebuchet must pack up before moving
        if unit.type == .trebuchet && !unit.isPackedSiege {
            unit.isPackedSiege = true
            unit.packTimer = 0
        }
        unit.path = pathfinder.findPath(from: unit.gridPosition, to: target)
        unit.state = .moving(to: target)
    }

    func moveUnits(_ units: [Unit], to target: GridPosition, pathfinder: Pathfinder, formation: FormationType = .box) {
        let count = units.count
        if count == 1 {
            moveUnit(units[0], to: target, pathfinder: pathfinder)
            return
        }

        switch formation {
        case .box:
            let cols = Int(ceil(sqrt(CGFloat(count))))
            for (i, unit) in units.enumerated() {
                let row = i / cols
                let col = i % cols
                let offsetX = (col - cols / 2) * 2  // 2-tile spacing between units
                let offsetY = (row - cols / 2) * 2  // 2-tile spacing between units
                var dest = GridPosition(x: target.x + offsetX, y: target.y + offsetY)
                // Nudge to nearest passable tile if destination is impassable
                if !pathfinder.map.isPassable(dest) {
                    dest = nearestPassable(to: dest, map: pathfinder.map) ?? target
                }
                moveUnit(unit, to: dest, pathfinder: pathfinder)
            }
        case .line:
            let halfCount = count / 2
            for (i, unit) in units.enumerated() {
                let offset = (i - halfCount) * 2  // 2-tile spacing between units
                var dest = GridPosition(x: target.x + offset, y: target.y)
                if !pathfinder.map.isPassable(dest) {
                    dest = nearestPassable(to: dest, map: pathfinder.map) ?? target
                }
                moveUnit(unit, to: dest, pathfinder: pathfinder)
            }
        case .spread:
            let radius = max(3, count / 2)  // Wider spread radius
            for (i, unit) in units.enumerated() {
                let angle = CGFloat(i) * (2.0 * .pi / CGFloat(count))
                let dx = Int(CGFloat(radius) * cos(angle))
                let dy = Int(CGFloat(radius) * sin(angle))
                var dest = GridPosition(x: target.x + dx, y: target.y + dy)
                if !pathfinder.map.isPassable(dest) {
                    dest = nearestPassable(to: dest, map: pathfinder.map) ?? target
                }
                moveUnit(unit, to: dest, pathfinder: pathfinder)
            }
        }
    }

    func selectUnitsInRect(_ rect: CGRect, player: Player) -> [Unit] {
        var selected: [Unit] = []
        for unit in player.units {
            if rect.contains(unit.position) {
                unit.isSelected = true
                selected.append(unit)
            } else {
                unit.isSelected = false
            }
        }
        return selected
    }

    func selectUnit(_ unit: Unit, player: Player) {
        // Deselect all
        for u in player.units { u.isSelected = false }
        unit.isSelected = true
    }

    func deselectAll(player: Player) {
        for u in player.units { u.isSelected = false }
    }

    func selectedUnits(for player: Player) -> [Unit] {
        player.units.filter { $0.isSelected }
    }

    private func autoAttackNearby(unit: Unit, player: Player, pathfinder: Pathfinder, range: CGFloat = 6.0) {
        guard let scene = gameScene else { return }

        // Stand ground melee units don't auto-engage; noAttack never engages
        if unit.stance == .noAttack { return }
        if unit.stance == .standGround && unit.type.attackRange <= 1.2 { return }

        let effectiveRange = unit.stance == .standGround ? unit.effectiveAttackRange : range

        for enemy in scene.players where enemy.id != player.id {
            for enemyUnit in enemy.units {
                let dist = unit.gridPosition.distance(to: enemyUnit.gridPosition)
                if dist <= effectiveRange {
                    // Save move destination before switching to attack
                    if case .moving(let dest) = unit.state {
                        unit.savedMoveDestination = dest
                    }
                    unit.state = .attacking(targetUnitID: enemyUnit.id)
                    if dist > unit.effectiveAttackRange {
                        unit.path = pathfinder.findPath(from: unit.gridPosition, to: enemyUnit.gridPosition)
                    }
                    return
                }
            }
        }
    }

    func attackTarget(unit: Unit, targetID: Int, pathfinder: Pathfinder) {
        unit.state = .attacking(targetUnitID: targetID)
        if let scene = gameScene {
            for player in scene.players {
                if let target = player.units.first(where: { $0.id == targetID }) {
                    let dist = unit.gridPosition.distance(to: target.gridPosition)
                    if dist > unit.effectiveAttackRange {
                        unit.path = pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
                    }
                    return
                }
            }
        }
    }

    func attackBuilding(unit: Unit, targetBuildingID: Int, pathfinder: Pathfinder) {
        unit.state = .attackingBuilding(targetBuildingID: targetBuildingID)
        if let scene = gameScene {
            for player in scene.players {
                if let target = player.buildings.first(where: { $0.id == targetBuildingID }) {
                    let dist = unit.gridPosition.distance(to: target.gridPosition)
                    if dist > unit.effectiveAttackRange {
                        unit.path = pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
                    }
                    return
                }
            }
        }
    }

    func killUnit(_ unit: Unit, player: Player) {
        if let scene = gameScene {
            let effect = scene.spriteFactory.createDeathEffect(at: unit.position)
            scene.gameWorld.addChild(effect)
            if player.isHuman {
                scene.totalUnitsLostHuman += 1
            }
        }
        // Death tilt/fall animation
        if let node = unit.node {
            let fallDirection = CGFloat.random(in: -1...1) * .pi / 3
            node.run(SKAction.sequence([
                SKAction.group([
                    SKAction.rotate(byAngle: fallDirection, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 0.6, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ]))
        }
        player.units.removeAll { $0.id == unit.id }
    }

    // MARK: - Shift-Queue Commands

    func queueCommand(unit: Unit, state: UnitState, position: GridPosition?) {
        unit.commandQueue.append((state, position))
    }

    func processCommandQueue(unit: Unit, pathfinder: Pathfinder) {
        guard case .idle = unit.state else { return }
        guard !unit.commandQueue.isEmpty else { return }

        let (nextState, position) = unit.commandQueue.removeFirst()
        unit.state = nextState
        if let pos = position {
            unit.path = pathfinder.findPath(from: unit.gridPosition, to: pos)
        }
    }

    // MARK: - Garrison

    func garrisonUnit(_ unit: Unit, into building: Building, player: Player) -> Bool {
        guard building.garrisonedUnits.count < building.garrisonCapacity else { return false }
        guard building.ownerID == unit.ownerID else { return false }

        let dist = unit.gridPosition.distance(to: building.gridPosition)
        if dist <= 3.0 {
            building.garrisonedUnits.append(unit.id)
            unit.state = .garrisoned(buildingID: building.id)
            unit.node?.isHidden = true
            return true
        }
        return false
    }

    func ungarrisonAll(building: Building, player: Player, map: GameMap) {
        for unitID in building.garrisonedUnits {
            if let unit = player.units.first(where: { $0.id == unitID }) {
                unit.state = .idle
                unit.node?.isHidden = false
                // Place near building
                if let spawnPos = findSpawnPosition(near: building, map: map) {
                    unit.gridPosition = spawnPos
                    unit.position = map.gridToWorld(spawnPos)
                    unit.node?.position = unit.position
                }
            }
        }
        building.garrisonedUnits.removeAll()
    }

    private func nearestPassable(to pos: GridPosition, map: GameMap) -> GridPosition? {
        // Search in expanding rings for a passable tile
        for radius in 1...5 {
            for dx in -radius...radius {
                for dy in -radius...radius {
                    if abs(dx) == radius || abs(dy) == radius {
                        let candidate = GridPosition(x: pos.x + dx, y: pos.y + dy)
                        if map.isPassable(candidate) {
                            return candidate
                        }
                    }
                }
            }
        }
        return nil
    }

    private func findSpawnPosition(near building: Building, map: GameMap) -> GridPosition? {
        let size = building.type.size
        let baseX = building.gridPosition.x
        let baseY = building.gridPosition.y

        for dx in -1...(size.width) {
            for dy in -1...(size.height) {
                if dx == -1 || dx == size.width || dy == -1 || dy == size.height {
                    let pos = GridPosition(x: baseX + dx, y: baseY + dy)
                    if map.isPassable(pos) {
                        return pos
                    }
                }
            }
        }
        return nil
    }

    // MARK: - Idle Military Alert

    func idleMilitaryUnits(for player: Player) -> [Unit] {
        player.units.filter { unit in
            unit.type != .villager && unit.type != .monk && unit.type != .fishingBoat && unit.type != .tradeCart
            && {
                if case .idle = unit.state { return true }
                return false
            }()
        }
    }

    // MARK: - Control Groups

    func setControlGroup(_ group: Int, units: [Unit], player: Player) {
        player.controlGroups[group] = units.map { $0.id }
        for unit in units { unit.controlGroup = group }
    }

    func selectControlGroup(_ group: Int, player: Player) -> [Unit] {
        let ids = player.controlGroups[group]
        let units = player.units.filter { ids.contains($0.id) }
        // Clean up dead units from group
        player.controlGroups[group] = units.map { $0.id }
        return units
    }

    // MARK: - Auto-Scout

    func handleAutoScout(unit: Unit, player: Player, map: GameMap, pathfinder: Pathfinder) {
        guard unit.path.isEmpty else { return }

        // Generate scout waypoints that explore unexplored areas
        let scoutTargets = [
            GridPosition(x: map.width / 4, y: map.height / 4),
            GridPosition(x: map.width * 3 / 4, y: map.height / 4),
            GridPosition(x: map.width / 2, y: map.height / 2),
            GridPosition(x: map.width / 4, y: map.height * 3 / 4),
            GridPosition(x: map.width * 3 / 4, y: map.height * 3 / 4),
            GridPosition(x: map.width / 6, y: map.height / 2),
            GridPosition(x: map.width * 5 / 6, y: map.height / 2),
            GridPosition(x: map.width / 2, y: map.height / 6),
            GridPosition(x: map.width / 2, y: map.height * 5 / 6),
        ]

        // Pick next unexplored target
        var bestTarget = scoutTargets[unit.autoScoutIndex % scoutTargets.count]
        for i in 0..<scoutTargets.count {
            let idx = (unit.autoScoutIndex + i) % scoutTargets.count
            let target = scoutTargets[idx]
            if map.isValid(target) && !map.tiles[target.y][target.x].isExplored {
                bestTarget = target
                unit.autoScoutIndex = idx + 1
                break
            }
        }
        unit.autoScoutIndex += 1

        if map.isPassable(bestTarget) {
            unit.path = pathfinder.findPath(from: unit.gridPosition, to: bestTarget)
        }
    }

    func startAutoScout(_ unit: Unit) {
        unit.state = .autoScouting
        unit.autoScoutIndex = 0
    }

    // MARK: - Select All Same Type

    func selectAllOfType(_ type: UnitType, player: Player) -> [Unit] {
        deselectAll(player: player)
        let matching = player.units.filter { $0.type == type }
        for unit in matching { unit.isSelected = true }
        return matching
    }

    // MARK: - Relic Collection

    func sendMonkToCollectRelic(unit: Unit, relic: Relic, pathfinder: Pathfinder) {
        guard unit.type == .monk else { return }
        guard !relic.isCollected else { return }
        unit.state = .collectingRelic(relicPos: relic.gridPosition)
        unit.path = pathfinder.findPath(from: unit.gridPosition, to: relic.gridPosition)
    }

    func handleRelicCollection(unit: Unit, relic: Relic, player: Player, map: GameMap) -> Bool {
        guard unit.type == .monk else { return false }
        let dist = unit.gridPosition.distance(to: relic.gridPosition)
        if dist <= 1.5 {
            relic.isCollected = true
            relic.collectedByPlayerID = player.id
            relic.node?.removeFromParent()
            unit.hasRelic = true
            player.relicsCollected += 1
            unit.state = .idle
            return true
        }
        return false
    }
}
