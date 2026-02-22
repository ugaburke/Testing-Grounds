import Foundation
import SpriteKit

class CombatSystem {
    weak var gameScene: GameScene?
    let attackInterval: CGFloat = 1.2

    func update(deltaTime: CGFloat, players: [Player], map: GameMap, pathfinder: Pathfinder) {
        guard let scene = gameScene else { return }

        for player in players {
            var unitsToRemove: [Unit] = []

            for unit in player.units {
                switch unit.state {
                case .attacking(let targetID):
                    handleUnitAttack(unit: unit, targetID: targetID, player: player,
                                    allPlayers: players, map: map, pathfinder: pathfinder,
                                    deltaTime: deltaTime)

                case .attackingBuilding(let targetBuildingID):
                    handleBuildingAttack(unit: unit, targetBuildingID: targetBuildingID,
                                        player: player, allPlayers: players, map: map,
                                        pathfinder: pathfinder, deltaTime: deltaTime)

                default:
                    break
                }

                // Check if unit is dead
                if unit.hp <= 0 {
                    unitsToRemove.append(unit)
                }
            }

            for unit in unitsToRemove {
                scene.unitSystem.killUnit(unit, player: player)
            }

            // Check destroyed buildings
            var buildingsToRemove: [Building] = []
            for building in player.buildings {
                if building.hp <= 0 {
                    buildingsToRemove.append(building)
                }
            }
            for building in buildingsToRemove {
                if let pos = building.node?.position {
                    let effect = scene.spriteFactory.createDeathEffect(at: pos)
                    scene.gameWorld.addChild(effect)
                }
                scene.buildingSystem.destroyBuilding(building, player: player, map: map)
            }
        }
    }

    private func handleUnitAttack(unit: Unit, targetID: Int, player: Player,
                                   allPlayers: [Player], map: GameMap, pathfinder: Pathfinder,
                                   deltaTime: CGFloat) {
        // Find target unit among all enemy players
        var target: Unit?
        var targetPlayer: Player?
        for p in allPlayers where p.id != player.id {
            if let t = p.units.first(where: { $0.id == targetID }) {
                target = t
                targetPlayer = p
                break
            }
        }

        guard let target = target, let _ = targetPlayer else {
            unit.state = .idle
            unit.path = []
            return
        }

        let dist = unit.gridPosition.distance(to: target.gridPosition)

        // Check if in range
        if dist <= unit.type.attackRange {
            unit.path = []

            // Attack with cooldown
            if unit.attackCooldown <= 0 {
                var damage = max(1, unit.effectiveAttack - target.effectiveDefense)

                // Bonus damage (spearman vs cavalry)
                if target.type.isCavalry {
                    damage += unit.type.bonusVsCavalry
                }

                target.hp -= damage
                unit.attackCooldown = attackInterval

                // Visual effect
                if let scene = gameScene {
                    if unit.type.isRanged {
                        // Projectile animation
                        let projectile = scene.spriteFactory.createAttackEffect(at: unit.position, isRanged: true)
                        scene.gameWorld.addChild(projectile)

                        let moveToTarget = SKAction.move(to: target.position, duration: 0.2)
                        let remove = SKAction.removeFromParent()
                        projectile.run(SKAction.sequence([moveToTarget, remove]))
                    } else {
                        let effect = scene.spriteFactory.createAttackEffect(at: target.position, isRanged: false)
                        scene.gameWorld.addChild(effect)
                    }
                }
            }
        } else {
            // Move towards target
            if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
            }
        }
    }

    private func handleBuildingAttack(unit: Unit, targetBuildingID: Int, player: Player,
                                       allPlayers: [Player], map: GameMap, pathfinder: Pathfinder,
                                       deltaTime: CGFloat) {
        var target: Building?
        var targetPlayer: Player?

        for p in allPlayers where p.id != player.id {
            if let b = p.buildings.first(where: { $0.id == targetBuildingID }) {
                target = b
                targetPlayer = p
                break
            }
        }

        guard let target = target, let _ = targetPlayer else {
            unit.state = .idle
            unit.path = []
            return
        }

        let dist = unit.gridPosition.distance(to: target.gridPosition)

        if dist <= unit.type.attackRange + 1.0 {
            unit.path = []

            if unit.attackCooldown <= 0 {
                let damage = max(1, unit.effectiveAttack)
                target.hp -= damage
                unit.attackCooldown = attackInterval

                if let scene = gameScene {
                    if let buildingPos = target.node?.position {
                        let effect = scene.spriteFactory.createAttackEffect(at: buildingPos, isRanged: false)
                        scene.gameWorld.addChild(effect)
                    }
                }
            }
        } else {
            if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
            }
        }
    }
}
