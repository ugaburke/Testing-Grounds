import Foundation
import SpriteKit

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

            // Auto-attack nearby enemies if idle or moving
            let shouldAutoAttack: Bool
            switch unit.state {
            case .idle: shouldAutoAttack = true
            case .moving: shouldAutoAttack = (unit.stance != .standGround)
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

        // Track facing direction
        if dist > 0.5 {
            unit.lastDirection = atan2(dy, dx)
        }

        let speedMultiplier: CGFloat = unit.type.isCavalry ? player.civilization.cavalrySpeedBonus : 1.0
        let speed = unit.type.moveSpeed * speedMultiplier * map.tileSize * 2.0

        if dist < 2.0 {
            unit.position = targetWorldPos
            unit.gridPosition = nextPos
            unit.path.removeFirst()
            unit.node?.position = unit.position
        } else {
            let moveX = (dx / dist) * speed * deltaTime
            let moveY = (dy / dist) * speed * deltaTime
            unit.position.x += moveX
            unit.position.y += moveY
            unit.node?.position = unit.position

            // Update grid position based on nearest tile
            unit.gridPosition = map.worldToGrid(unit.position)
        }
    }

    func moveUnit(_ unit: Unit, to target: GridPosition, pathfinder: Pathfinder) {
        unit.path = pathfinder.findPath(from: unit.gridPosition, to: target)
        unit.state = .moving(to: target)
    }

    func moveUnits(_ units: [Unit], to target: GridPosition, pathfinder: Pathfinder) {
        // Formation movement: spread units around the target
        let count = units.count
        if count == 1 {
            moveUnit(units[0], to: target, pathfinder: pathfinder)
            return
        }

        let cols = Int(ceil(sqrt(CGFloat(count))))
        for (i, unit) in units.enumerated() {
            let row = i / cols
            let col = i % cols
            let offsetX = col - cols / 2
            let offsetY = row - cols / 2
            let dest = GridPosition(x: target.x + offsetX, y: target.y + offsetY)
            moveUnit(unit, to: dest, pathfinder: pathfinder)
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

        // Stand ground melee units don't auto-engage (can't reach without moving)
        if unit.stance == .standGround && unit.type.attackRange <= 1.2 { return }

        let effectiveRange = unit.stance == .standGround ? unit.type.attackRange : range

        for enemy in scene.players where enemy.id != player.id {
            for enemyUnit in enemy.units {
                let dist = unit.gridPosition.distance(to: enemyUnit.gridPosition)
                if dist <= effectiveRange {
                    // Save move destination before switching to attack
                    if case .moving(let dest) = unit.state {
                        unit.savedMoveDestination = dest
                    }
                    unit.state = .attacking(targetUnitID: enemyUnit.id)
                    if dist > unit.type.attackRange {
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
                    if dist > unit.type.attackRange {
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
                    if dist > unit.type.attackRange {
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
        unit.node?.removeFromParent()
        player.units.removeAll { $0.id == unit.id }
    }
}
