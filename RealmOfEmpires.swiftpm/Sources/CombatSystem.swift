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

                case .healing(let targetID):
                    handleHealing(unit: unit, targetID: targetID, player: player, deltaTime: deltaTime)

                case .converting(let targetID):
                    handleConversion(unit: unit, targetID: targetID, player: player, allPlayers: players, deltaTime: deltaTime)

                case .guarding(let targetID):
                    handleGuarding(unit: unit, targetID: targetID, player: player, allPlayers: players, pathfinder: pathfinder)

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
            if let guardID = unit.guardTargetID {
                unit.state = .guarding(targetUnitID: guardID)
            }
            unit.path = []
            return
        }

        let dist = unit.gridPosition.distance(to: target.gridPosition)

        // Check if in range
        if dist <= unit.type.attackRange {
            unit.path = []

            // Attack with cooldown
            if unit.attackCooldown <= 0 {
                let bonus = unit.bonusDamage(against: target)
                let armorReduction = unit.type.isRanged ? target.type.pierceArmor : target.type.meleeArmor
                let damage = max(1, unit.effectiveAttack + bonus - (target.effectiveDefense + armorReduction) / 2 + Int.random(in: 0...1))

                target.hp -= damage
                unit.attackCooldown = attackInterval

                // Track kills for veterancy
                if target.hp <= 0 {
                    unit.killCount += 1
                    updateVeterancyIndicator(unit: unit)
                }

                // Visual effect
                if let scene = gameScene {
                    // Damage number
                    let dmgNum = scene.spriteFactory.createDamageNumber(at: target.position, damage: damage)
                    scene.gameWorld.addChild(dmgNum)

                    if unit.type.isRanged {
                        // Projectile with trail
                        let projectile = scene.spriteFactory.createAttackEffect(at: unit.position, isRanged: true)
                        scene.gameWorld.addChild(projectile)

                        // Trail dots during flight
                        let trailAction = SKAction.repeat(SKAction.sequence([
                            SKAction.run { [weak scene, weak projectile] in
                                guard let scene = scene, let proj = projectile else { return }
                                let trail = scene.spriteFactory.createProjectileTrail(at: proj.position)
                                scene.gameWorld.addChild(trail)
                            },
                            SKAction.wait(forDuration: 0.05)
                        ]), count: 4)

                        let moveToTarget = SKAction.move(to: target.position, duration: 0.2)
                        let remove = SKAction.removeFromParent()
                        projectile.run(SKAction.sequence([
                            SKAction.group([moveToTarget, trailAction]),
                            remove
                        ]))
                    } else {
                        let effect = scene.spriteFactory.createAttackEffect(at: target.position, isRanged: false)
                        scene.gameWorld.addChild(effect)
                    }
                }
            }
        } else {
            // Move towards target (stance-aware)
            if unit.stance == .standGround {
                // Can't reach target, go idle
                unit.state = .idle
                unit.path = []
            } else if unit.stance == .defensive {
                // Only chase within limited range from anchor
                if let anchor = unit.stanceAnchorPosition,
                   unit.gridPosition.distance(to: anchor) > 8.0 {
                    // Too far from anchor, return
                    unit.state = .moving(to: anchor)
                    unit.path = pathfinder.findPath(from: unit.gridPosition, to: anchor)
                } else {
                    if unit.path.isEmpty {
                        unit.path = pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
                    }
                }
            } else {
                if unit.path.isEmpty {
                    unit.path = pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
                }
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
                let damage = max(1, unit.effectiveAttack + unit.type.bonusVsBuilding)
                target.hp -= damage
                unit.attackCooldown = attackInterval

                if let scene = gameScene {
                    if let buildingPos = target.node?.position {
                        let effect = scene.spriteFactory.createAttackEffect(at: buildingPos, isRanged: false)
                        scene.gameWorld.addChild(effect)
                        let dmgNum = scene.spriteFactory.createDamageNumber(at: buildingPos, damage: damage)
                        scene.gameWorld.addChild(dmgNum)
                    }
                }
            }
        } else {
            if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
            }
        }
    }

    private func handleHealing(unit: Unit, targetID: Int, player: Player, deltaTime: CGFloat) {
        guard unit.type == .monk else { unit.state = .idle; return }
        guard let target = player.units.first(where: { $0.id == targetID }) else {
            unit.state = .idle
            return
        }

        // Check if target is at full HP
        if target.hp >= target.maxHP {
            unit.state = .idle
            return
        }

        let dist = unit.gridPosition.distance(to: target.gridPosition)
        if dist <= 4.0 {
            unit.path = []
            unit.healCooldown -= deltaTime
            if unit.healCooldown <= 0 {
                target.hp = min(target.maxHP, target.hp + 3)
                unit.healCooldown = 1.5

                // Healing visual effect
                if let scene = gameScene {
                    let effect = createHealEffect(at: target.position)
                    scene.gameWorld.addChild(effect)
                }
            }
        } else {
            if let scene = gameScene {
                if unit.path.isEmpty {
                    unit.path = scene.pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
                }
            }
        }
    }

    private func handleConversion(unit: Unit, targetID: Int, player: Player, allPlayers: [Player], deltaTime: CGFloat) {
        guard unit.type == .monk else { unit.state = .idle; return }

        var target: Unit?
        var targetPlayer: Player?
        for p in allPlayers where p.id != player.id {
            if let t = p.units.first(where: { $0.id == targetID }) {
                target = t
                targetPlayer = p
                break
            }
        }

        guard let target = target, let targetPlayer = targetPlayer else {
            unit.state = .idle
            unit.conversionProgress = 0
            return
        }

        let dist = unit.gridPosition.distance(to: target.gridPosition)
        if dist <= 6.0 {
            unit.path = []
            unit.conversionProgress += deltaTime / 8.0  // 8 seconds to convert

            // Visual: golden glow on target
            if let scene = gameScene, Int(unit.conversionProgress * 10) % 3 == 0 {
                let glow = createConversionEffect(at: target.position)
                scene.gameWorld.addChild(glow)
            }

            if unit.conversionProgress >= 1.0 {
                // Convert the unit!
                let newUnit = Unit(type: target.type, ownerID: player.id, position: target.gridPosition)
                newUnit.ownerPlayer = player
                newUnit.gridPosition = target.gridPosition
                newUnit.position = target.position
                newUnit.hp = target.hp
                newUnit.maxHP = target.maxHP
                newUnit.killCount = target.killCount

                if let scene = gameScene {
                    let node = scene.spriteFactory.createUnitNode(unit: newUnit)
                    node.position = newUnit.position
                    newUnit.node = node
                    scene.gameWorld.addChild(node)

                    // Remove old unit
                    target.node?.removeFromParent()
                    targetPlayer.units.removeAll { $0.id == target.id }
                    player.units.append(newUnit)

                    scene.hud.showStatus("Unit converted!")
                }

                unit.conversionProgress = 0
                unit.state = .idle
            }
        } else {
            if let scene = gameScene, unit.path.isEmpty {
                unit.path = scene.pathfinder.findPath(from: unit.gridPosition, to: target.gridPosition)
            }
        }
    }

    private func handleGuarding(unit: Unit, targetID: Int, player: Player, allPlayers: [Player], pathfinder: Pathfinder) {
        // Find the unit we're guarding
        guard let guardTarget = player.units.first(where: { $0.id == targetID }) else {
            unit.state = .idle
            return
        }

        let dist = unit.gridPosition.distance(to: guardTarget.gridPosition)

        // Stay near the guard target
        if dist > 3.0 {
            if unit.path.isEmpty {
                unit.path = pathfinder.findPath(from: unit.gridPosition, to: guardTarget.gridPosition)
            }
        }

        // Check for nearby enemies threatening the guard target
        for enemy in allPlayers where enemy.id != player.id {
            for enemyUnit in enemy.units {
                let enemyDist = enemyUnit.gridPosition.distance(to: guardTarget.gridPosition)
                if enemyDist <= 5.0 {
                    unit.guardTargetID = targetID
                    unit.state = .attacking(targetUnitID: enemyUnit.id)
                    return
                }
            }
        }
    }

    private func createHealEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 15

        let cross = SKLabelNode(text: "+")
        cross.fontSize = 16
        cross.fontName = "Helvetica-Bold"
        cross.fontColor = SKColor(red: 0.3, green: 0.9, blue: 0.3, alpha: 1.0)
        cross.verticalAlignmentMode = .center
        container.addChild(cross)

        let fadeUp = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 15, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ])
        container.run(fadeUp)
        return container
    }

    private func createConversionEffect(at position: CGPoint) -> SKNode {
        let glow = SKShapeNode(circleOfRadius: 8)
        glow.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 0.5)
        glow.strokeColor = .clear
        glow.position = position
        glow.zPosition = 14

        let fadeOut = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 2.0, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ])
        glow.run(fadeOut)
        return glow
    }

    private func updateVeterancyIndicator(unit: Unit) {
        guard unit.veterancyLevel > 0 else { return }
        unit.node?.childNode(withName: "vetStar")?.removeFromParent()

        let star = SKLabelNode(text: unit.veterancyLevel >= 2 ? "\u{2605}\u{2605}" : "\u{2605}")
        star.fontSize = 8
        star.fontName = "Helvetica-Bold"
        star.fontColor = unit.veterancyLevel >= 2 ? .yellow : SKColor(red: 0.8, green: 0.8, blue: 0.8, alpha: 1.0)
        star.position = CGPoint(x: 0, y: 10)
        star.verticalAlignmentMode = .bottom
        star.name = "vetStar"
        star.zPosition = 15
        unit.node?.addChild(star)
    }
}
