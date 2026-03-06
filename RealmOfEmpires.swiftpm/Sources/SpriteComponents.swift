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
        let darkerColor = playerColor.darker(by: 0.15)
        let lighterColor = playerColor.lighter(by: 0.25)

        // Drop shadow
        let shadowSize = tileSize * 0.5
        let shadow = SKShapeNode(ellipseOf: CGSize(width: shadowSize, height: shadowSize * 0.4))
        shadow.fillColor = SKColor.black.withAlphaComponent(0.25)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -tileSize * 0.2)
        shadow.zPosition = -2
        container.addChild(shadow)

        // Selection ring — cache reference for fast updates (under body)
        let bodySize = tileSize * 0.7
        let selectionRing = SKShapeNode(circleOfRadius: bodySize * 0.6)
        selectionRing.fillColor = SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.15)
        selectionRing.strokeColor = SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        selectionRing.lineWidth = 2
        selectionRing.glowWidth = 1
        selectionRing.isHidden = true
        selectionRing.zPosition = -1
        container.addChild(selectionRing)
        unit.selectionRingNode = selectionRing

        // Unit body
        let body: SKShapeNode

        if unit.type.isCavalry {
            // Horse-like shape: larger ellipse with a pointed front
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -bodySize * 0.5, y: -bodySize * 0.28,
                                        width: bodySize, height: bodySize * 0.56))
            body = SKShapeNode(path: path)
            body.fillColor = playerColor
            body.strokeColor = darkerColor
            body.lineWidth = 2
            // Rider dot on top
            let rider = SKShapeNode(circleOfRadius: bodySize * 0.15)
            rider.fillColor = lighterColor
            rider.strokeColor = darkerColor
            rider.lineWidth = 1
            rider.position = CGPoint(x: 0, y: bodySize * 0.1)
            rider.zPosition = 1
            container.addChild(rider)
        } else if unit.type.isRanged {
            // Diamond/arrow shape for ranged units
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: bodySize * 0.4))
            path.addLine(to: CGPoint(x: -bodySize * 0.3, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -bodySize * 0.3))
            path.addLine(to: CGPoint(x: bodySize * 0.3, y: 0))
            path.closeSubpath()
            body = SKShapeNode(path: path)
            body.fillColor = playerColor
            body.strokeColor = darkerColor
            body.lineWidth = 2
        } else if unit.type == .villager {
            // Rounded worker shape
            body = SKShapeNode(circleOfRadius: bodySize * 0.32)
            body.fillColor = playerColor
            body.strokeColor = darkerColor
            body.lineWidth = 2
            // Tool indicator (small square)
            let tool = SKShapeNode(rectOf: CGSize(width: 3, height: 6))
            tool.fillColor = SKColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 1.0)
            tool.strokeColor = .clear
            tool.position = CGPoint(x: bodySize * 0.25, y: bodySize * 0.1)
            tool.zPosition = 1
            container.addChild(tool)
        } else {
            // Shield shape for infantry
            let path = CGMutablePath()
            let hw = bodySize * 0.3
            let hh = bodySize * 0.32
            path.move(to: CGPoint(x: -hw, y: hh))
            path.addLine(to: CGPoint(x: hw, y: hh))
            path.addLine(to: CGPoint(x: hw, y: -hh * 0.3))
            path.addLine(to: CGPoint(x: 0, y: -hh))
            path.addLine(to: CGPoint(x: -hw, y: -hh * 0.3))
            path.closeSubpath()
            body = SKShapeNode(path: path)
            body.fillColor = playerColor
            body.strokeColor = darkerColor
            body.lineWidth = 2
        }
        container.addChild(body)

        // Unit type icon
        let label = SKLabelNode(text: unit.type.icon)
        label.fontSize = tileSize * 0.28
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 2
        container.addChild(label)

        // HP bar background with border
        let hpBarWidth = tileSize * 0.75
        let hpBarHeight: CGFloat = 4
        let hpBarY = bodySize * 0.5

        let hpBarBorder = SKShapeNode(rectOf: CGSize(width: hpBarWidth + 2, height: hpBarHeight + 2), cornerRadius: 1)
        hpBarBorder.fillColor = SKColor.black.withAlphaComponent(0.6)
        hpBarBorder.strokeColor = SKColor.black.withAlphaComponent(0.4)
        hpBarBorder.lineWidth = 0.5
        hpBarBorder.position = CGPoint(x: 0, y: hpBarY)
        hpBarBorder.zPosition = 3
        container.addChild(hpBarBorder)

        // HP bar fill — cache reference for fast updates
        let hpBar = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: hpBarHeight))
        hpBar.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.2, alpha: 1.0)
        hpBar.strokeColor = .clear
        hpBar.position = CGPoint(x: 0, y: hpBarY)
        hpBar.zPosition = 4
        container.addChild(hpBar)
        unit.hpBarNode = hpBar

        return container
    }

    func updateUnitNode(_ unit: Unit) {
        // Use cached references — avoids childNode(withName:) tree walk
        if let hpBar = unit.hpBarNode {
            let ratio = CGFloat(unit.hp) / CGFloat(unit.maxHP)
            let barWidth = tileSize * 0.75 * ratio
            let path = CGPath(rect: CGRect(x: -tileSize * 0.375, y: -2, width: barWidth, height: 4), transform: nil)
            hpBar.path = path
            if ratio > 0.6 {
                hpBar.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.2, alpha: 1.0)
            } else if ratio > 0.3 {
                hpBar.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.1, alpha: 1.0)
            } else {
                hpBar.fillColor = SKColor(red: 0.9, green: 0.15, blue: 0.1, alpha: 1.0)
            }
        }

        if let ring = unit.selectionRingNode {
            ring.isHidden = !unit.isSelected
        }
    }

    // MARK: - Building Sprites

    func createBuildingNode(building: Building) -> SKNode {
        let container = SKNode()
        container.name = "building_\(building.id)"
        container.zPosition = 5

        let playerColor = SpriteFactory.playerColors[building.ownerID % SpriteFactory.playerColors.count]
        let darkerBuildColor = building.type.color.darker(by: 0.15)

        let w = CGFloat(building.type.size.width) * tileSize
        let h = CGFloat(building.type.size.height) * tileSize

        // Building shadow
        let shadow = SKShapeNode(rectOf: CGSize(width: w - 1, height: h * 0.3), cornerRadius: 2)
        shadow.fillColor = SKColor.black.withAlphaComponent(0.2)
        shadow.strokeColor = .clear
        shadow.position = CGPoint(x: 2, y: -h * 0.35)
        shadow.zPosition = -1
        container.addChild(shadow)

        // Building base/foundation
        let base = SKShapeNode(rectOf: CGSize(width: w + 2, height: h + 2), cornerRadius: 2)
        base.fillColor = SKColor(red: 0.35, green: 0.3, blue: 0.2, alpha: 0.5)
        base.strokeColor = .clear
        base.zPosition = 0
        container.addChild(base)

        // Building body — cache reference
        let constructedAlpha: CGFloat = building.isConstructed ? 1.0 : 0.5
        let body = SKShapeNode(rectOf: CGSize(width: w - 2, height: h - 2), cornerRadius: 2)
        body.fillColor = building.isConstructed ? building.type.color : building.type.color.withAlphaComponent(constructedAlpha)
        body.strokeColor = playerColor
        body.lineWidth = 2
        body.zPosition = 1
        container.addChild(body)
        building.bodyNode = body

        // Roof/detail based on building type
        addBuildingDetail(to: container, type: building.type, w: w, h: h, playerColor: playerColor, darkerColor: darkerBuildColor)

        // Building icon label
        let label = SKLabelNode(text: building.type.icon)
        label.fontSize = min(w, h) * 0.3
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 3
        container.addChild(label)

        // HP bar with border
        let hpBarWidth = w * 0.85
        let hpBarHeight: CGFloat = 5

        let hpBarBorder = SKShapeNode(rectOf: CGSize(width: hpBarWidth + 2, height: hpBarHeight + 2), cornerRadius: 1)
        hpBarBorder.fillColor = SKColor.black.withAlphaComponent(0.6)
        hpBarBorder.strokeColor = .clear
        hpBarBorder.position = CGPoint(x: 0, y: h * 0.5 + 5)
        hpBarBorder.zPosition = 4
        container.addChild(hpBarBorder)

        // HP bar fill — cache reference
        let hpBar = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: hpBarHeight))
        hpBar.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.2, alpha: 1.0)
        hpBar.strokeColor = .clear
        hpBar.position = CGPoint(x: 0, y: h * 0.5 + 5)
        hpBar.zPosition = 5
        container.addChild(hpBar)
        building.hpBarNode = hpBar

        // Construction progress bar — cache reference
        if !building.isConstructed {
            let progressBorder = SKShapeNode(rectOf: CGSize(width: hpBarWidth + 2, height: hpBarHeight + 2), cornerRadius: 1)
            progressBorder.fillColor = SKColor.black.withAlphaComponent(0.5)
            progressBorder.strokeColor = .clear
            progressBorder.position = CGPoint(x: 0, y: h * 0.5 + 12)
            progressBorder.zPosition = 4
            container.addChild(progressBorder)

            let progressBar = SKShapeNode(rectOf: CGSize(width: 1, height: hpBarHeight))
            progressBar.fillColor = SKColor(red: 1.0, green: 0.65, blue: 0.1, alpha: 1.0)
            progressBar.strokeColor = .clear
            progressBar.position = CGPoint(x: -hpBarWidth / 2, y: h * 0.5 + 12)
            progressBar.zPosition = 5
            container.addChild(progressBar)
            building.progressBarNode = progressBar

            // Scaffolding lines for under-construction buildings
            for i in 0..<2 {
                let scaffold = SKShapeNode(rectOf: CGSize(width: 1.5, height: h * 0.6))
                scaffold.fillColor = SKColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 0.6)
                scaffold.strokeColor = .clear
                scaffold.position = CGPoint(x: w * 0.25 * CGFloat(i == 0 ? -1 : 1), y: 0)
                scaffold.zPosition = 2
                scaffold.name = "scaffold"
                container.addChild(scaffold)
            }
            let crossBar = SKShapeNode(rectOf: CGSize(width: w * 0.5, height: 1.5))
            crossBar.fillColor = SKColor(red: 0.5, green: 0.35, blue: 0.15, alpha: 0.6)
            crossBar.strokeColor = .clear
            crossBar.position = CGPoint(x: 0, y: h * 0.15)
            crossBar.zPosition = 2
            crossBar.name = "scaffold"
            container.addChild(crossBar)
        }

        // Flag for player color
        let flagPole = SKShapeNode(rectOf: CGSize(width: 1.5, height: 14))
        flagPole.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.35, alpha: 1.0)
        flagPole.strokeColor = .clear
        flagPole.position = CGPoint(x: w * 0.35, y: h * 0.3)
        flagPole.zPosition = 6
        container.addChild(flagPole)

        let flagPath = CGMutablePath()
        flagPath.move(to: CGPoint.zero)
        flagPath.addLine(to: CGPoint(x: 8, y: -1))
        flagPath.addLine(to: CGPoint(x: 6, y: -4))
        flagPath.addLine(to: CGPoint(x: 0, y: -3))
        flagPath.closeSubpath()
        let flag = SKShapeNode(path: flagPath)
        flag.fillColor = playerColor
        flag.strokeColor = playerColor.darker(by: 0.2)
        flag.lineWidth = 0.5
        flag.position = CGPoint(x: w * 0.35, y: h * 0.3 + 7)
        flag.zPosition = 6
        container.addChild(flag)

        return container
    }

    private func addBuildingDetail(to container: SKNode, type: BuildingType, w: CGFloat, h: CGFloat, playerColor: SKColor, darkerColor: SKColor) {
        switch type {
        case .townCenter:
            // Roof triangle
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: -w * 0.45, y: h * 0.2))
            roofPath.addLine(to: CGPoint(x: 0, y: h * 0.45))
            roofPath.addLine(to: CGPoint(x: w * 0.45, y: h * 0.2))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = darkerColor.darker(by: 0.1)
            roof.strokeColor = darkerColor.darker(by: 0.2)
            roof.lineWidth = 1
            roof.zPosition = 2
            container.addChild(roof)

        case .house:
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: -w * 0.4, y: h * 0.15))
            roofPath.addLine(to: CGPoint(x: 0, y: h * 0.4))
            roofPath.addLine(to: CGPoint(x: w * 0.4, y: h * 0.15))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.55, green: 0.2, blue: 0.1, alpha: 1.0)
            roof.strokeColor = .clear
            roof.zPosition = 2
            container.addChild(roof)

        case .barracks, .archeryRange, .stable:
            // Military building - add a stripe
            let stripe = SKShapeNode(rectOf: CGSize(width: w * 0.6, height: 2))
            stripe.fillColor = playerColor.withAlphaComponent(0.6)
            stripe.strokeColor = .clear
            stripe.position = CGPoint(x: 0, y: -h * 0.25)
            stripe.zPosition = 2
            container.addChild(stripe)

        case .castle:
            // Turret corners
            let turretSize: CGFloat = 6
            for dx in [-1.0, 1.0] as [CGFloat] {
                for dy in [-1.0, 1.0] as [CGFloat] {
                    let turret = SKShapeNode(rectOf: CGSize(width: turretSize, height: turretSize))
                    turret.fillColor = darkerColor
                    turret.strokeColor = playerColor
                    turret.lineWidth = 1
                    turret.position = CGPoint(x: dx * w * 0.4, y: dy * h * 0.4)
                    turret.zPosition = 2
                    container.addChild(turret)
                }
            }

        case .tower:
            // Battlement top
            for i in -1...1 {
                let merlon = SKShapeNode(rectOf: CGSize(width: 3, height: 3))
                merlon.fillColor = darkerColor
                merlon.strokeColor = .clear
                merlon.position = CGPoint(x: CGFloat(i) * 5, y: h * 0.35)
                merlon.zPosition = 2
                container.addChild(merlon)
            }

        case .farm:
            // Crop rows
            for i in -1...1 {
                let row = SKShapeNode(rectOf: CGSize(width: w * 0.6, height: 1.5))
                row.fillColor = SKColor(red: 0.4, green: 0.55, blue: 0.15, alpha: 0.7)
                row.strokeColor = .clear
                row.position = CGPoint(x: 0, y: CGFloat(i) * h * 0.2)
                row.zPosition = 2
                container.addChild(row)
            }

        default:
            break
        }
    }

    func updateBuildingNode(_ building: Building) {
        guard let container = building.node else { return }

        let w = CGFloat(building.type.size.width) * tileSize
        let h = CGFloat(building.type.size.height) * tileSize
        let hpBarWidth = w * 0.85

        // Update body appearance — use cached reference
        if let body = building.bodyNode {
            body.fillColor = building.isConstructed ? building.type.color : building.type.color.withAlphaComponent(0.3 + 0.7 * building.constructionProgress)
        }

        // Update HP bar — use cached reference
        if let hpBar = building.hpBarNode {
            let ratio = CGFloat(building.hp) / CGFloat(building.maxHP)
            let barWidth = hpBarWidth * ratio
            let path = CGPath(rect: CGRect(x: -hpBarWidth / 2, y: -2.5, width: barWidth, height: 5), transform: nil)
            hpBar.path = path
            if ratio > 0.6 {
                hpBar.fillColor = SKColor(red: 0.2, green: 0.85, blue: 0.2, alpha: 1.0)
            } else if ratio > 0.3 {
                hpBar.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.1, alpha: 1.0)
            } else {
                hpBar.fillColor = SKColor(red: 0.9, green: 0.15, blue: 0.1, alpha: 1.0)
            }
        }

        // Update construction progress — use cached reference
        if let progressBar = building.progressBarNode {
            if building.isConstructed {
                progressBar.removeFromParent()
                building.progressBarNode = nil
                // Remove scaffolding
                container.children.filter { $0.name == "scaffold" }.forEach { $0.removeFromParent() }
            } else {
                let barWidth = hpBarWidth * building.constructionProgress
                let path = CGPath(rect: CGRect(x: 0, y: -2.5, width: barWidth, height: 5), transform: nil)
                progressBar.path = path
            }
        }

        // Training indicator (infrequent, ok to use name lookup)
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
            let projectile = SKShapeNode(circleOfRadius: 3)
            projectile.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.2, alpha: 1.0)
            projectile.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 0.8)
            projectile.glowWidth = 2
            projectile.position = position
            projectile.zPosition = 15
            return projectile
        } else {
            let container = SKNode()
            container.position = position
            container.zPosition = 15

            // Slash arc
            let slash = SKShapeNode(rectOf: CGSize(width: 10, height: 2.5), cornerRadius: 1)
            slash.fillColor = .white
            slash.strokeColor = SKColor(red: 1.0, green: 0.9, blue: 0.5, alpha: 0.8)
            slash.lineWidth = 0.5
            slash.zRotation = CGFloat.random(in: 0...(.pi * 2))
            container.addChild(slash)

            // Impact spark
            let spark = SKShapeNode(circleOfRadius: 2)
            spark.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.3, alpha: 0.9)
            spark.strokeColor = .clear
            spark.glowWidth = 1
            container.addChild(spark)

            let fadeOut = SKAction.sequence([
                SKAction.group([
                    SKAction.fadeOut(withDuration: 0.25),
                    SKAction.scale(to: 2.5, duration: 0.25)
                ]),
                SKAction.removeFromParent()
            ])
            container.run(fadeOut)
            return container
        }
    }

    func createGatherEffect(at position: CGPoint, resourceType: ResourceType) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 15

        for i in 0..<2 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            switch resourceType {
            case .food: particle.fillColor = SKColor(red: 0.9, green: 0.2, blue: 0.15, alpha: 0.9)
            case .wood: particle.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 0.9)
            case .gold: particle.fillColor = SKColor(red: 1.0, green: 0.85, blue: 0.15, alpha: 0.9)
            case .stone: particle.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.55, alpha: 0.9)
            }
            particle.strokeColor = .clear
            particle.position = .zero

            let floatUp = SKAction.sequence([
                SKAction.wait(forDuration: Double(i) * 0.1),
                SKAction.group([
                    SKAction.moveBy(x: CGFloat.random(in: -8...8), y: CGFloat.random(in: 10...20), duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.3, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(floatUp)
            container.addChild(particle)
        }

        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: 0.7),
            SKAction.removeFromParent()
        ])
        container.run(cleanup)
        return container
    }

    func createDeathEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 20

        // Skull/X indicator
        let xMark = SKLabelNode(text: "\u{2620}")
        xMark.fontSize = 16
        xMark.verticalAlignmentMode = .center
        xMark.zPosition = 1
        container.addChild(xMark)

        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3))
            particle.fillColor = [SKColor.orange, SKColor.red, SKColor.yellow].randomElement()!
            particle.strokeColor = .clear
            particle.position = .zero

            let dx = CGFloat.random(in: -18...18)
            let dy = CGFloat.random(in: -18...18)

            let anim = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5),
                    SKAction.scale(to: 0.1, duration: 0.5)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(anim)
            container.addChild(particle)
        }

        let cleanup = SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.8),
                SKAction.moveBy(x: 0, y: 10, duration: 0.8)
            ]),
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
