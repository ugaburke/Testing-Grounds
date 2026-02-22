import SpriteKit

class SpriteFactory {
    let tileSize: CGFloat
    static let playerColors: [SKColor] = [
        SKColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),  // Player 1: Blue
        SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0),  // Player 2: Red
        SKColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0),  // Player 3: Green
        SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0),  // Player 4: Yellow
    ]

    init(tileSize: CGFloat) {
        self.tileSize = tileSize
    }

    // MARK: - Unit Sprites

    func createUnitNode(unit: Unit) -> SKNode {
        let container = SKNode()
        container.name = "unit_\(unit.id)"
        container.zPosition = 10

        let playerColor = SpriteFactory.playerColors[unit.ownerID % SpriteFactory.playerColors.count]

        // Unit body
        let bodySize = tileSize * 0.7
        let body: SKShapeNode

        if unit.type.isCavalry {
            // Horse-like shape for cavalry
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -bodySize * 0.5, y: -bodySize * 0.3,
                                        width: bodySize, height: bodySize * 0.6))
            body = SKShapeNode(path: path)
        } else if unit.type.isRanged {
            // Triangle for ranged units
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: bodySize * 0.4))
            path.addLine(to: CGPoint(x: -bodySize * 0.35, y: -bodySize * 0.3))
            path.addLine(to: CGPoint(x: bodySize * 0.35, y: -bodySize * 0.3))
            path.closeSubpath()
            body = SKShapeNode(path: path)
        } else if unit.type == .villager {
            // Circle for villagers
            body = SKShapeNode(circleOfRadius: bodySize * 0.35)
        } else {
            // Square for melee infantry
            body = SKShapeNode(rectOf: CGSize(width: bodySize * 0.6, height: bodySize * 0.6))
        }

        body.fillColor = playerColor
        body.strokeColor = playerColor.lighter(by: 0.3)
        body.lineWidth = 1.5
        body.name = "unitBody"
        container.addChild(body)

        // Unit type indicator
        let label = SKLabelNode(text: unit.type.icon)
        label.fontSize = tileSize * 0.3
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        container.addChild(label)

        // HP bar background
        let hpBarWidth = tileSize * 0.7
        let hpBarBg = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: 3))
        hpBarBg.fillColor = .darkGray
        hpBarBg.strokeColor = .clear
        hpBarBg.position = CGPoint(x: 0, y: bodySize * 0.45)
        hpBarBg.name = "hpBarBg"
        hpBarBg.zPosition = 2
        container.addChild(hpBarBg)

        // HP bar fill
        let hpBar = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: 3))
        hpBar.fillColor = .green
        hpBar.strokeColor = .clear
        hpBar.position = CGPoint(x: 0, y: bodySize * 0.45)
        hpBar.name = "hpBar"
        hpBar.zPosition = 3
        container.addChild(hpBar)

        // Selection ring (hidden by default)
        let selectionRing = SKShapeNode(circleOfRadius: bodySize * 0.55)
        selectionRing.fillColor = .clear
        selectionRing.strokeColor = SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        selectionRing.lineWidth = 2
        selectionRing.name = "selectionRing"
        selectionRing.isHidden = true
        selectionRing.zPosition = -1
        container.addChild(selectionRing)

        return container
    }

    func updateUnitNode(_ unit: Unit) {
        guard let container = unit.node else { return }

        // Update HP bar
        if let hpBar = container.childNode(withName: "hpBar") as? SKShapeNode {
            let ratio = CGFloat(unit.hp) / CGFloat(unit.maxHP)
            let barWidth = tileSize * 0.7 * ratio
            let path = CGPath(rect: CGRect(x: -tileSize * 0.35, y: -1.5, width: barWidth, height: 3), transform: nil)
            hpBar.path = path
            if ratio > 0.6 {
                hpBar.fillColor = .green
            } else if ratio > 0.3 {
                hpBar.fillColor = .yellow
            } else {
                hpBar.fillColor = .red
            }
        }

        // Update selection ring
        if let ring = container.childNode(withName: "selectionRing") {
            ring.isHidden = !unit.isSelected
        }
    }

    // MARK: - Building Sprites

    func createBuildingNode(building: Building) -> SKNode {
        let container = SKNode()
        container.name = "building_\(building.id)"
        container.zPosition = 5

        let playerColor = SpriteFactory.playerColors[building.ownerID % SpriteFactory.playerColors.count]

        let w = CGFloat(building.type.size.width) * tileSize
        let h = CGFloat(building.type.size.height) * tileSize

        // Building body
        let body = SKShapeNode(rectOf: CGSize(width: w - 2, height: h - 2))
        body.fillColor = building.isConstructed ? building.type.color : building.type.color.withAlphaComponent(0.5)
        body.strokeColor = playerColor
        body.lineWidth = 2
        body.name = "buildingBody"
        container.addChild(body)

        // Building label
        let label = SKLabelNode(text: building.type.icon)
        label.fontSize = min(w, h) * 0.35
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 1
        container.addChild(label)

        // HP bar
        let hpBarWidth = w * 0.8
        let hpBarBg = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: 4))
        hpBarBg.fillColor = .darkGray
        hpBarBg.strokeColor = .clear
        hpBarBg.position = CGPoint(x: 0, y: h * 0.5 + 4)
        hpBarBg.name = "hpBarBg"
        hpBarBg.zPosition = 2
        container.addChild(hpBarBg)

        let hpBar = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: 4))
        hpBar.fillColor = .green
        hpBar.strokeColor = .clear
        hpBar.position = CGPoint(x: 0, y: h * 0.5 + 4)
        hpBar.name = "hpBar"
        hpBar.zPosition = 3
        container.addChild(hpBar)

        // Construction progress bar
        if !building.isConstructed {
            let progressBar = SKShapeNode(rectOf: CGSize(width: 1, height: 4))
            progressBar.fillColor = .orange
            progressBar.strokeColor = .clear
            progressBar.position = CGPoint(x: -hpBarWidth / 2, y: h * 0.5 + 10)
            progressBar.name = "progressBar"
            progressBar.zPosition = 3
            container.addChild(progressBar)
        }

        // Flag for player color
        let flagPole = SKShapeNode(rectOf: CGSize(width: 1, height: 12))
        flagPole.fillColor = .gray
        flagPole.strokeColor = .clear
        flagPole.position = CGPoint(x: w * 0.35, y: h * 0.3)
        flagPole.zPosition = 2
        container.addChild(flagPole)

        let flag = SKShapeNode(rectOf: CGSize(width: 6, height: 4))
        flag.fillColor = playerColor
        flag.strokeColor = .clear
        flag.position = CGPoint(x: w * 0.35 + 3, y: h * 0.3 + 6)
        flag.zPosition = 2
        container.addChild(flag)

        return container
    }

    func updateBuildingNode(_ building: Building) {
        guard let container = building.node else { return }

        let w = CGFloat(building.type.size.width) * tileSize
        let h = CGFloat(building.type.size.height) * tileSize

        // Update body appearance
        if let body = container.childNode(withName: "buildingBody") as? SKShapeNode {
            body.fillColor = building.isConstructed ? building.type.color : building.type.color.withAlphaComponent(0.3 + 0.7 * building.constructionProgress)
        }

        // Update HP bar
        if let hpBar = container.childNode(withName: "hpBar") as? SKShapeNode {
            let ratio = CGFloat(building.hp) / CGFloat(building.maxHP)
            let barWidth = w * 0.8 * ratio
            let path = CGPath(rect: CGRect(x: -w * 0.4, y: -2, width: barWidth, height: 4), transform: nil)
            hpBar.path = path
            if ratio > 0.6 {
                hpBar.fillColor = .green
            } else if ratio > 0.3 {
                hpBar.fillColor = .yellow
            } else {
                hpBar.fillColor = .red
            }
        }

        // Update construction progress
        if let progressBar = container.childNode(withName: "progressBar") as? SKShapeNode {
            if building.isConstructed {
                progressBar.removeFromParent()
            } else {
                let barWidth = w * 0.8 * building.constructionProgress
                let path = CGPath(rect: CGRect(x: 0, y: -2, width: barWidth, height: 4), transform: nil)
                progressBar.path = path
            }
        }

        // Training indicator
        if !building.trainingQueue.isEmpty {
            if container.childNode(withName: "trainingIndicator") == nil {
                let indicator = SKShapeNode(circleOfRadius: 4)
                indicator.fillColor = .cyan
                indicator.strokeColor = .clear
                indicator.position = CGPoint(x: -w * 0.35, y: h * 0.5 + 10)
                indicator.name = "trainingIndicator"
                indicator.zPosition = 4

                let pulse = SKAction.sequence([
                    SKAction.fadeAlpha(to: 0.3, duration: 0.5),
                    SKAction.fadeAlpha(to: 1.0, duration: 0.5)
                ])
                indicator.run(SKAction.repeatForever(pulse))
                container.addChild(indicator)
            }
        } else {
            container.childNode(withName: "trainingIndicator")?.removeFromParent()
        }
    }

    // MARK: - Effects

    func createAttackEffect(at position: CGPoint, isRanged: Bool) -> SKNode {
        if isRanged {
            let projectile = SKShapeNode(circleOfRadius: 2)
            projectile.fillColor = .yellow
            projectile.strokeColor = .orange
            projectile.position = position
            projectile.zPosition = 15
            return projectile
        } else {
            let slash = SKShapeNode(rectOf: CGSize(width: 8, height: 2))
            slash.fillColor = .white
            slash.strokeColor = .clear
            slash.position = position
            slash.zPosition = 15
            slash.zRotation = CGFloat.random(in: 0...(.pi * 2))

            let fadeOut = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.3),
                    SKAction.scale(to: 2.0, duration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])
            slash.run(fadeOut)
            return slash
        }
    }

    func createGatherEffect(at position: CGPoint, resourceType: ResourceType) -> SKNode {
        let particle = SKShapeNode(circleOfRadius: 3)
        switch resourceType {
        case .food: particle.fillColor = .red
        case .wood: particle.fillColor = .brown
        case .gold: particle.fillColor = .yellow
        case .stone: particle.fillColor = .gray
        }
        particle.strokeColor = .clear
        particle.position = position
        particle.zPosition = 15

        let floatUp = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -5...5), y: 15, duration: 0.6),
                SKAction.fadeOut(withDuration: 0.6)
            ]),
            SKAction.removeFromParent()
        ])
        particle.run(floatUp)
        return particle
    }

    func createDeathEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 20

        for _ in 0..<6 {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = .orange
            particle.strokeColor = .red
            particle.position = .zero

            let dx = CGFloat.random(in: -15...15)
            let dy = CGFloat.random(in: -15...15)

            let anim = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.4),
                    SKAction.fadeOut(withDuration: 0.4),
                    SKAction.scale(to: 0.1, duration: 0.4)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(anim)
            container.addChild(particle)
        }

        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: 0.5),
            SKAction.removeFromParent()
        ])
        container.run(cleanup)
        return container
    }
}

// MARK: - Color Extension

extension SKColor {
    func lighter(by percentage: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: min(r + percentage, 1.0),
                       green: min(g + percentage, 1.0),
                       blue: min(b + percentage, 1.0),
                       alpha: a)
    }

    func darker(by percentage: CGFloat) -> SKColor {
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        getRed(&r, green: &g, blue: &b, alpha: &a)
        return SKColor(red: max(r - percentage, 0),
                       green: max(g - percentage, 0),
                       blue: max(b - percentage, 0),
                       alpha: a)
    }
}
