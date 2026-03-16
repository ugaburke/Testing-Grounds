import SpriteKit

enum WeatherType {
    case clear
    case rain
    case snow
}

class SpriteFactory {
    let tileSize: CGFloat
    static let playerColors: [SKColor] = [
        SKColor(red: 0.2, green: 0.4, blue: 0.8, alpha: 1.0),  // Player 1: Blue
        SKColor(red: 0.8, green: 0.2, blue: 0.2, alpha: 1.0),  // Player 2: Red
        SKColor(red: 0.2, green: 0.7, blue: 0.2, alpha: 1.0),  // Player 3: Green
        SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0),  // Player 4: Yellow
    ]

    private var shadowTexture: SKTexture?

    init(tileSize: CGFloat) {
        self.tileSize = tileSize
        self.shadowTexture = createGradientShadowTexture()
    }

    // MARK: - Cached Shadow Texture

    private func createGradientShadowTexture() -> SKTexture {
        let size = Int(tileSize)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        let context = CGContext(data: nil, width: size, height: size,
                                bitsPerComponent: 8, bytesPerRow: size * 4,
                                space: colorSpace, bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)!
        let center = CGFloat(size) / 2.0
        let radius = CGFloat(size) / 2.0
        for y in 0..<size {
            for x in 0..<size {
                let dx = CGFloat(x) - center
                let dy = CGFloat(y) - center
                let dist = sqrt(dx * dx + dy * dy) / radius
                let alpha = max(0, 1.0 - dist) * 0.3
                let ptr = context.data!.assumingMemoryBound(to: UInt8.self)
                let offset = (y * size + x) * 4
                ptr[offset] = 0
                ptr[offset + 1] = 0
                ptr[offset + 2] = 0
                ptr[offset + 3] = UInt8(alpha * 255)
            }
        }
        let cgImage = context.makeImage()!
        return SKTexture(cgImage: cgImage)
    }

    // MARK: - Unit Sprites

    func createUnitNode(unit: Unit) -> SKNode {
        let container = SKNode()
        container.name = "unit_\(unit.id)"
        container.zPosition = 10

        let playerColor = SpriteFactory.playerColors[unit.ownerID % SpriteFactory.playerColors.count]
        let bodySize = tileSize * 0.85

        // Shadow (gradient)
        if let shadowTex = shadowTexture {
            let shadow = SKSpriteNode(texture: shadowTex)
            shadow.size = CGSize(width: bodySize * 0.8, height: bodySize * 0.4)
            shadow.position = CGPoint(x: 0, y: -bodySize * 0.25)
            shadow.zPosition = -2
            shadow.name = "shadow"
            container.addChild(shadow)
        }

        // Selection ring (hidden by default) — non-rotating
        let selectionRing = SKShapeNode(circleOfRadius: bodySize * 0.55)
        selectionRing.fillColor = .clear
        selectionRing.strokeColor = SKColor(red: 0.2, green: 1.0, blue: 0.2, alpha: 0.8)
        selectionRing.lineWidth = 2
        selectionRing.name = "selectionRing"
        selectionRing.isHidden = true
        selectionRing.zPosition = -1
        container.addChild(selectionRing)

        // Body container (rotates to face movement direction)
        let bodyContainer = SKNode()
        bodyContainer.name = "bodyContainer"
        bodyContainer.zPosition = 1
        container.addChild(bodyContainer)
        unit.bodyNode = bodyContainer

        // Unit body shape
        let body: SKShapeNode
        if unit.type.isSiege {
            if unit.type == .batteringRam {
                // Wide rectangular ram shape
                body = SKShapeNode(rectOf: CGSize(width: bodySize * 0.9, height: bodySize * 0.45), cornerRadius: bodySize * 0.08)
                // Ram head (pointed front)
                let ramHead = SKShapeNode(rectOf: CGSize(width: bodySize * 0.15, height: bodySize * 0.2))
                ramHead.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
                ramHead.strokeColor = .clear
                ramHead.position = CGPoint(x: bodySize * 0.45, y: 0)
                bodyContainer.addChild(ramHead)
            } else {
                // Mangonel: triangle with circle (catapult shape)
                let path = CGMutablePath()
                path.move(to: CGPoint(x: -bodySize * 0.35, y: -bodySize * 0.3))
                path.addLine(to: CGPoint(x: bodySize * 0.35, y: -bodySize * 0.3))
                path.addLine(to: CGPoint(x: 0, y: bodySize * 0.3))
                path.closeSubpath()
                body = SKShapeNode(path: path)
                let boulder = SKShapeNode(circleOfRadius: bodySize * 0.12)
                boulder.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
                boulder.strokeColor = .clear
                boulder.position = CGPoint(x: 0, y: bodySize * 0.15)
                bodyContainer.addChild(boulder)
            }
        } else if unit.type.isCavalry {
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -bodySize * 0.5, y: -bodySize * 0.3,
                                        width: bodySize, height: bodySize * 0.6))
            body = SKShapeNode(path: path)
            // Mane detail
            let mane = SKShapeNode(rectOf: CGSize(width: bodySize * 0.15, height: bodySize * 0.35))
            mane.fillColor = playerColor.darker(by: 0.15)
            mane.strokeColor = .clear
            mane.position = CGPoint(x: bodySize * 0.2, y: bodySize * 0.1)
            bodyContainer.addChild(mane)
        } else if unit.type.isRanged {
            // Diamond shape for ranged units
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: bodySize * 0.4))
            path.addLine(to: CGPoint(x: -bodySize * 0.35, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -bodySize * 0.4))
            path.addLine(to: CGPoint(x: bodySize * 0.35, y: 0))
            path.closeSubpath()
            body = SKShapeNode(path: path)
            // Bowstring/arrow detail
            let bowString = SKShapeNode(rectOf: CGSize(width: 1, height: bodySize * 0.5))
            bowString.fillColor = SKColor.white.withAlphaComponent(0.6)
            bowString.strokeColor = .clear
            bowString.position = CGPoint(x: 0, y: bodySize * 0.05)
            bodyContainer.addChild(bowString)
        } else if unit.type == .villager {
            body = SKShapeNode(circleOfRadius: bodySize * 0.35)
        } else if unit.type == .monk {
            // Monk: cross/diamond shape
            body = SKShapeNode(circleOfRadius: bodySize * 0.35)
            let cross1 = SKShapeNode(rectOf: CGSize(width: 2, height: bodySize * 0.4))
            cross1.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 0.8)
            cross1.strokeColor = .clear
            bodyContainer.addChild(cross1)
            let cross2 = SKShapeNode(rectOf: CGSize(width: bodySize * 0.25, height: 2))
            cross2.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 0.8)
            cross2.strokeColor = .clear
            cross2.position = CGPoint(x: 0, y: bodySize * 0.08)
            bodyContainer.addChild(cross2)
        } else if unit.type == .tradeCart {
            // Trade cart: wider rectangle
            body = SKShapeNode(rectOf: CGSize(width: bodySize * 0.7, height: bodySize * 0.4), cornerRadius: bodySize * 0.06)
            let cargo = SKShapeNode(rectOf: CGSize(width: bodySize * 0.3, height: bodySize * 0.2))
            cargo.fillColor = SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 0.6)
            cargo.strokeColor = .clear
            cargo.position = CGPoint(x: -bodySize * 0.1, y: 0)
            bodyContainer.addChild(cargo)
        } else if unit.type == .fishingBoat {
            // Fishing boat: oval boat shape
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -bodySize * 0.4, y: -bodySize * 0.2,
                                        width: bodySize * 0.8, height: bodySize * 0.4))
            body = SKShapeNode(path: path)
            let mast = SKShapeNode(rectOf: CGSize(width: 1.5, height: bodySize * 0.35))
            mast.fillColor = SKColor.brown
            mast.strokeColor = .clear
            mast.position = CGPoint(x: 0, y: bodySize * 0.15)
            bodyContainer.addChild(mast)
        } else if unit.type == .trebuchet {
            // Trebuchet: triangle base with arm
            let path = CGMutablePath()
            path.move(to: CGPoint(x: -bodySize * 0.4, y: -bodySize * 0.3))
            path.addLine(to: CGPoint(x: bodySize * 0.4, y: -bodySize * 0.3))
            path.addLine(to: CGPoint(x: 0, y: bodySize * 0.2))
            path.closeSubpath()
            body = SKShapeNode(path: path)
            // Trebuchet arm
            let arm = SKShapeNode(rectOf: CGSize(width: 2, height: bodySize * 0.5))
            arm.fillColor = SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 0.9)
            arm.strokeColor = .clear
            arm.position = CGPoint(x: 0, y: bodySize * 0.15)
            arm.zRotation = 0.4
            bodyContainer.addChild(arm)
            // Counterweight
            let weight = SKShapeNode(circleOfRadius: bodySize * 0.1)
            weight.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)
            weight.strokeColor = .clear
            weight.position = CGPoint(x: -bodySize * 0.15, y: bodySize * 0.3)
            bodyContainer.addChild(weight)
        } else if unit.type == .warGalley {
            // War Galley: larger boat shape with ram
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -bodySize * 0.5, y: -bodySize * 0.25,
                                        width: bodySize, height: bodySize * 0.5))
            body = SKShapeNode(path: path)
            let ram = SKShapeNode(rectOf: CGSize(width: bodySize * 0.2, height: 3))
            ram.fillColor = SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
            ram.strokeColor = .clear
            ram.position = CGPoint(x: bodySize * 0.5, y: 0)
            bodyContainer.addChild(ram)
            let mast = SKShapeNode(rectOf: CGSize(width: 2, height: bodySize * 0.4))
            mast.fillColor = SKColor.brown
            mast.strokeColor = .clear
            mast.position = CGPoint(x: 0, y: bodySize * 0.2)
            bodyContainer.addChild(mast)
        } else if unit.type == .fireShip {
            // Fire Ship: boat with flame indicator
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -bodySize * 0.4, y: -bodySize * 0.2,
                                        width: bodySize * 0.8, height: bodySize * 0.4))
            body = SKShapeNode(path: path)
            let flame = SKShapeNode(circleOfRadius: bodySize * 0.15)
            flame.fillColor = SKColor(red: 1.0, green: 0.4, blue: 0.1, alpha: 0.8)
            flame.strokeColor = .clear
            flame.position = CGPoint(x: bodySize * 0.2, y: bodySize * 0.1)
            bodyContainer.addChild(flame)
        } else if unit.type == .petard {
            // Petard: small circle with fuse
            body = SKShapeNode(circleOfRadius: bodySize * 0.3)
            let fuse = SKShapeNode(rectOf: CGSize(width: 1.5, height: bodySize * 0.25))
            fuse.fillColor = SKColor(red: 0.9, green: 0.6, blue: 0.1, alpha: 1.0)
            fuse.strokeColor = .clear
            fuse.position = CGPoint(x: 0, y: bodySize * 0.3)
            bodyContainer.addChild(fuse)
        } else if unit.type == .camelRider {
            // Camel: tall ellipse
            let path = CGMutablePath()
            path.addEllipse(in: CGRect(x: -bodySize * 0.4, y: -bodySize * 0.35,
                                        width: bodySize * 0.8, height: bodySize * 0.7))
            body = SKShapeNode(path: path)
            let hump = SKShapeNode(circleOfRadius: bodySize * 0.12)
            hump.fillColor = playerColor.darker(by: 0.1)
            hump.strokeColor = .clear
            hump.position = CGPoint(x: 0, y: bodySize * 0.2)
            bodyContainer.addChild(hump)
        } else if unit.type == .handCannoneer {
            // Hand Cannoneer: diamond with cannon tube
            let path = CGMutablePath()
            path.move(to: CGPoint(x: 0, y: bodySize * 0.4))
            path.addLine(to: CGPoint(x: -bodySize * 0.35, y: 0))
            path.addLine(to: CGPoint(x: 0, y: -bodySize * 0.4))
            path.addLine(to: CGPoint(x: bodySize * 0.35, y: 0))
            path.closeSubpath()
            body = SKShapeNode(path: path)
            let cannon = SKShapeNode(rectOf: CGSize(width: bodySize * 0.4, height: 3))
            cannon.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 0.9)
            cannon.strokeColor = .clear
            cannon.position = CGPoint(x: bodySize * 0.15, y: 0)
            bodyContainer.addChild(cannon)
        } else if unit.type == .samurai {
            // Samurai: shield shape with katana
            let path = CGMutablePath()
            path.addRoundedRect(in: CGRect(x: -bodySize * 0.32, y: -bodySize * 0.32,
                                            width: bodySize * 0.64, height: bodySize * 0.64),
                                cornerWidth: bodySize * 0.12, cornerHeight: bodySize * 0.12)
            body = SKShapeNode(path: path)
            let katana = SKShapeNode(rectOf: CGSize(width: 2, height: bodySize * 0.5))
            katana.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.95, alpha: 0.9)
            katana.strokeColor = .clear
            katana.position = CGPoint(x: bodySize * 0.25, y: bodySize * 0.05)
            katana.zRotation = -0.2
            bodyContainer.addChild(katana)
        } else if unit.type == .warElephant {
            // War Elephant: large circle
            body = SKShapeNode(circleOfRadius: bodySize * 0.5)
            let tusk1 = SKShapeNode(rectOf: CGSize(width: 2, height: bodySize * 0.2))
            tusk1.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 0.9)
            tusk1.strokeColor = .clear
            tusk1.position = CGPoint(x: bodySize * 0.2, y: bodySize * 0.25)
            tusk1.zRotation = 0.3
            bodyContainer.addChild(tusk1)
            let tusk2 = SKShapeNode(rectOf: CGSize(width: 2, height: bodySize * 0.2))
            tusk2.fillColor = SKColor(red: 0.9, green: 0.9, blue: 0.85, alpha: 0.9)
            tusk2.strokeColor = .clear
            tusk2.position = CGPoint(x: bodySize * 0.2, y: -bodySize * 0.25)
            tusk2.zRotation = -0.3
            bodyContainer.addChild(tusk2)
        } else {
            // Melee infantry — rounded shield shape
            let path = CGMutablePath()
            path.addRoundedRect(in: CGRect(x: -bodySize * 0.32, y: -bodySize * 0.32,
                                            width: bodySize * 0.64, height: bodySize * 0.64),
                                cornerWidth: bodySize * 0.12, cornerHeight: bodySize * 0.12)
            body = SKShapeNode(path: path)
            // Sword detail
            let sword = SKShapeNode(rectOf: CGSize(width: 2, height: bodySize * 0.4))
            sword.fillColor = SKColor(red: 0.8, green: 0.8, blue: 0.85, alpha: 0.8)
            sword.strokeColor = .clear
            sword.position = CGPoint(x: bodySize * 0.2, y: bodySize * 0.05)
            sword.zRotation = -0.3
            bodyContainer.addChild(sword)
            // Horizontal armor line
            let armor = SKShapeNode(rectOf: CGSize(width: bodySize * 0.4, height: 1.5))
            armor.fillColor = playerColor.darker(by: 0.1)
            armor.strokeColor = .clear
            bodyContainer.addChild(armor)
        }

        body.fillColor = playerColor
        body.strokeColor = playerColor.lighter(by: 0.3)
        body.lineWidth = 1.5
        body.name = "unitBody"
        bodyContainer.addChild(body)

        // Unit type indicator label
        let label = SKLabelNode(text: unit.type.icon)
        label.fontSize = tileSize * 0.3
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        label.zPosition = 2
        bodyContainer.addChild(label)

        // HP bar background — non-rotating, stays on container
        let hpBarWidth = tileSize * 0.7
        let hpBarBg = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: 3))
        hpBarBg.fillColor = .darkGray
        hpBarBg.strokeColor = .clear
        hpBarBg.position = CGPoint(x: 0, y: bodySize * 0.45)
        hpBarBg.name = "hpBarBg"
        hpBarBg.zPosition = 12
        container.addChild(hpBarBg)

        let hpBar = SKShapeNode(rectOf: CGSize(width: hpBarWidth, height: 3))
        hpBar.fillColor = .green
        hpBar.strokeColor = .clear
        hpBar.position = CGPoint(x: 0, y: bodySize * 0.45)
        hpBar.name = "hpBar"
        hpBar.zPosition = 13
        container.addChild(hpBar)

        // State indicator (emoji above unit for villagers)
        let stateLabel = SKLabelNode(text: "")
        stateLabel.fontSize = tileSize * 0.35
        stateLabel.verticalAlignmentMode = .center
        stateLabel.position = CGPoint(x: 0, y: bodySize * 0.65)
        stateLabel.name = "stateIndicator"
        stateLabel.zPosition = 14
        container.addChild(stateLabel)

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
        if let ring = container.childNode(withName: "selectionRing") as? SKShapeNode {
            let wasHidden = ring.isHidden
            ring.isHidden = !unit.isSelected
            if unit.isSelected && ring.action(forKey: "pulse") == nil {
                // Pop animation on first selection
                if wasHidden {
                    ring.setScale(1.4)
                    ring.run(SKAction.scale(to: 1.0, duration: 0.15))
                }
                let pulse = SKAction.sequence([
                    SKAction.scale(to: 1.1, duration: 0.4),
                    SKAction.scale(to: 1.0, duration: 0.4)
                ])
                ring.run(SKAction.repeatForever(pulse), withKey: "pulse")
            } else if !unit.isSelected {
                ring.removeAction(forKey: "pulse")
                ring.setScale(1.0)
            }
        }

        // Update state indicator for villagers
        if unit.type == .villager, let stateLabel = container.childNode(withName: "stateIndicator") as? SKLabelNode {
            switch unit.state {
            case .gathering(let rt, _):
                switch rt {
                case .food: stateLabel.text = "\u{1F34E}"
                case .wood: stateLabel.text = "\u{1FAB5}"
                case .gold: stateLabel.text = "\u{1FA99}"
                case .stone: stateLabel.text = "\u{1FAA8}"
                }
            case .building(_): stateLabel.text = "\u{1F528}"
            case .returning(_, _, _): stateLabel.text = "\u{1F4E6}"
            default: stateLabel.text = ""
            }
        } else if let stateLabel = container.childNode(withName: "stateIndicator") as? SKLabelNode {
            stateLabel.text = ""
        }

        // Idle animation: gentle bob
        if let bodyNode = unit.bodyNode {
            let isIdle: Bool
            if case .idle = unit.state { isIdle = true } else { isIdle = false }

            if isIdle && bodyNode.action(forKey: "idleBob") == nil {
                let bob = SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: 0, y: 1.5, duration: 0.6),
                    SKAction.moveBy(x: 0, y: -1.5, duration: 0.6)
                ]))
                bodyNode.run(bob, withKey: "idleBob")
            } else if !isIdle {
                bodyNode.removeAction(forKey: "idleBob")
            }
        }

        // Update carry indicator for villagers
        updateCarryIndicator(unit: unit)

        // Update damaged unit health bar (shown on all damaged units, not just selected)
        updateDamagedUnitHealthBar(unit: unit)
    }

    // MARK: - Damaged Unit Health Bars

    func updateDamagedUnitHealthBar(unit: Unit) {
        let healthBarName = "damagedHealthBar"
        if unit.hp < unit.maxHP && !unit.isSelected {
            if unit.node?.childNode(withName: healthBarName) == nil {
                let barWidth: CGFloat = tileSize * 0.8
                let barHeight: CGFloat = 3
                let bg = SKShapeNode(rectOf: CGSize(width: barWidth, height: barHeight))
                bg.fillColor = .red
                bg.strokeColor = .clear
                bg.position = CGPoint(x: 0, y: tileSize * 0.5)
                bg.zPosition = 12
                bg.name = healthBarName

                let hpRatio = CGFloat(unit.hp) / CGFloat(unit.maxHP)
                let fg = SKShapeNode(rectOf: CGSize(width: barWidth * hpRatio, height: barHeight))
                fg.fillColor = hpRatio > 0.5 ? .green : (hpRatio > 0.25 ? .yellow : .red)
                fg.strokeColor = .clear
                fg.position = CGPoint(x: -(barWidth * (1 - hpRatio)) / 2, y: 0)
                fg.name = "hpFill"
                bg.addChild(fg)
                unit.node?.addChild(bg)
            } else if let bar = unit.node?.childNode(withName: healthBarName) as? SKShapeNode {
                // Update existing
                let barWidth: CGFloat = tileSize * 0.8
                let hpRatio = CGFloat(unit.hp) / CGFloat(unit.maxHP)
                if let fg = bar.childNode(withName: "hpFill") as? SKShapeNode {
                    fg.xScale = hpRatio
                    fg.fillColor = hpRatio > 0.5 ? .green : (hpRatio > 0.25 ? .yellow : .red)
                }
            }
        } else {
            unit.node?.childNode(withName: healthBarName)?.removeFromParent()
        }
    }

    // MARK: - Unit Facing

    func updateUnitFacing(_ unit: Unit, deltaTime: CGFloat) {
        guard let bodyNode = unit.bodyNode else { return }
        guard !unit.path.isEmpty else { return }

        // Calculate direction from movement
        let targetAngle = unit.lastDirection
        let currentAngle = bodyNode.zRotation

        // Smooth rotation lerp
        var diff = targetAngle - currentAngle
        // Normalize to -pi...pi
        while diff > .pi { diff -= .pi * 2 }
        while diff < -.pi { diff += .pi * 2 }
        bodyNode.zRotation += diff * 0.15
    }

    // MARK: - Carry Indicator

    func updateCarryIndicator(unit: Unit) {
        guard let container = unit.node else { return }

        // Remove existing carry indicator if present
        container.childNode(withName: "carryIndicator")?.removeFromParent()

        // Only show for villagers carrying resources
        guard unit.type == .villager, let resource = unit.carriedResource, unit.carriedAmount > 0 else { return }

        let dotRadius: CGFloat = tileSize * 0.1
        let dot = SKShapeNode(circleOfRadius: dotRadius)
        dot.strokeColor = .clear
        dot.name = "carryIndicator"
        dot.zPosition = 15

        switch resource {
        case .food:
            dot.fillColor = SKColor(red: 0.2, green: 0.8, blue: 0.2, alpha: 0.9)
        case .wood:
            dot.fillColor = SKColor(red: 0.55, green: 0.35, blue: 0.15, alpha: 0.9)
        case .gold:
            dot.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.2, alpha: 0.9)
        case .stone:
            dot.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 0.9)
        }

        let bodySize = tileSize * 0.85
        dot.position = CGPoint(x: bodySize * 0.3, y: -bodySize * 0.3)
        container.addChild(dot)
    }

    // MARK: - Movement Dust

    func createMovementDust(at position: CGPoint) -> SKNode {
        let dust = SKShapeNode(circleOfRadius: tileSize * 0.15)
        dust.fillColor = SKColor(red: 0.55, green: 0.45, blue: 0.3, alpha: 0.35)
        dust.strokeColor = .clear
        dust.position = CGPoint(x: position.x + CGFloat.random(in: -3...3),
                                y: position.y + CGFloat.random(in: -3...3))
        dust.zPosition = 1
        dust.name = "movementDust"

        dust.run(SKAction.sequence([
            SKAction.group([
                SKAction.fadeOut(withDuration: 0.4),
                SKAction.scale(to: 1.8, duration: 0.4)
            ]),
            SKAction.removeFromParent()
        ]))

        return dust
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

        // Dark foundation band at building base
        let foundation = SKShapeNode(rectOf: CGSize(width: w, height: h * 0.12))
        foundation.fillColor = SKColor(red: 0.15, green: 0.12, blue: 0.08, alpha: 0.6)
        foundation.strokeColor = .clear
        foundation.position = CGPoint(x: 0, y: -h * 0.44)
        foundation.zPosition = 0.5
        container.addChild(foundation)

        // Roof triangle on TC and Castle
        if building.type == .townCenter || building.type == .castle {
            let roofPath = CGMutablePath()
            roofPath.move(to: CGPoint(x: -w * 0.45, y: h * 0.4))
            roofPath.addLine(to: CGPoint(x: 0, y: h * 0.6))
            roofPath.addLine(to: CGPoint(x: w * 0.45, y: h * 0.4))
            roofPath.closeSubpath()
            let roof = SKShapeNode(path: roofPath)
            roof.fillColor = SKColor(red: 0.5, green: 0.25, blue: 0.1, alpha: 0.8)
            roof.strokeColor = playerColor.withAlphaComponent(0.5)
            roof.lineWidth = 1
            roof.zPosition = 1.1
            container.addChild(roof)
        }

        // Architectural detail per building type
        addBuildingDetail(to: container, type: building.type, w: w, h: h, playerColor: playerColor)

        // Building label
        let label = SKLabelNode(text: building.type.icon)
        label.fontSize = min(w, h) * 0.3
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

        // Construction scaffolding + progress bar
        if !building.isConstructed {
            let progressBar = SKShapeNode(rectOf: CGSize(width: 1, height: 4))
            progressBar.fillColor = .orange
            progressBar.strokeColor = .clear
            progressBar.position = CGPoint(x: -hpBarWidth / 2, y: h * 0.5 + 10)
            progressBar.name = "progressBar"
            progressBar.zPosition = 3
            container.addChild(progressBar)

            // Scaffolding lines
            let scaffolding = SKNode()
            scaffolding.name = "scaffolding"
            scaffolding.zPosition = 1.5
            for i in 0..<3 {
                let line = SKShapeNode(rectOf: CGSize(width: w * 0.8, height: 1))
                line.fillColor = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 0.6)
                line.strokeColor = .clear
                line.position = CGPoint(x: 0, y: -h * 0.3 + CGFloat(i) * h * 0.3)
                scaffolding.addChild(line)
            }
            // Pulsing opacity on scaffolding
            let pulse = SKAction.sequence([
                SKAction.fadeAlpha(to: 0.3, duration: 0.8),
                SKAction.fadeAlpha(to: 0.8, duration: 0.8)
            ])
            scaffolding.run(SKAction.repeatForever(pulse))
            container.addChild(scaffolding)
        }

        // Flag for player color
        let flagPole = SKShapeNode(rectOf: CGSize(width: 1, height: 14))
        flagPole.fillColor = .gray
        flagPole.strokeColor = .clear
        flagPole.position = CGPoint(x: w * 0.35, y: h * 0.3)
        flagPole.zPosition = 2
        flagPole.name = "flagPole"
        container.addChild(flagPole)

        let flag = SKShapeNode(rectOf: CGSize(width: 7, height: 5))
        flag.fillColor = playerColor
        flag.strokeColor = .clear
        flag.position = CGPoint(x: w * 0.35 + 3.5, y: h * 0.3 + 7)
        flag.zPosition = 2
        flag.name = "flag"
        container.addChild(flag)

        // Flag waving animation
        let wave = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 0.8, duration: 0.4),
            SKAction.scaleX(to: 1.0, duration: 0.3),
            SKAction.scaleX(to: 1.1, duration: 0.3),
            SKAction.scaleX(to: 1.0, duration: 0.4)
        ]))
        flag.run(wave)

        // Building breathing animation (subtle scale pulse)
        let breathe = SKAction.repeatForever(SKAction.sequence([
            SKAction.scale(to: 1.01, duration: 2.0),
            SKAction.scale(to: 0.99, duration: 2.0)
        ]))
        body.run(breathe)

        return container
    }

    private func addBuildingDetail(to container: SKNode, type: BuildingType, w: CGFloat, h: CGFloat, playerColor: SKColor) {
        let detailZ: CGFloat = 1.2

        switch type {
        case .townCenter:
            // Door
            let door = SKShapeNode(rectOf: CGSize(width: w * 0.15, height: h * 0.25))
            door.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
            door.strokeColor = .clear
            door.position = CGPoint(x: 0, y: -h * 0.25)
            door.zPosition = detailZ
            container.addChild(door)
            // Windows
            for xOff in [-w * 0.25, w * 0.25] {
                let window = SKShapeNode(rectOf: CGSize(width: w * 0.08, height: h * 0.08))
                window.fillColor = SKColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 0.8)
                window.strokeColor = SKColor.white.withAlphaComponent(0.5)
                window.lineWidth = 0.5
                window.position = CGPoint(x: xOff, y: h * 0.1)
                window.zPosition = detailZ
                container.addChild(window)
            }

        case .house:
            // Small door
            let door = SKShapeNode(rectOf: CGSize(width: w * 0.12, height: h * 0.2))
            door.fillColor = SKColor(red: 0.35, green: 0.25, blue: 0.12, alpha: 1.0)
            door.strokeColor = .clear
            door.position = CGPoint(x: -w * 0.15, y: -h * 0.28)
            door.zPosition = detailZ
            container.addChild(door)
            // Window
            let window = SKShapeNode(rectOf: CGSize(width: w * 0.1, height: w * 0.1))
            window.fillColor = SKColor(red: 0.6, green: 0.7, blue: 0.9, alpha: 0.7)
            window.strokeColor = SKColor.white.withAlphaComponent(0.4)
            window.lineWidth = 0.5
            window.position = CGPoint(x: w * 0.15, y: h * 0.05)
            window.zPosition = detailZ
            container.addChild(window)

        case .barracks, .archeryRange, .stable:
            // Double door
            for xOff in [-w * 0.06, w * 0.06] as [CGFloat] {
                let door = SKShapeNode(rectOf: CGSize(width: w * 0.1, height: h * 0.22))
                door.fillColor = SKColor(red: 0.3, green: 0.2, blue: 0.1, alpha: 1.0)
                door.strokeColor = .clear
                door.position = CGPoint(x: xOff, y: -h * 0.26)
                door.zPosition = detailZ
                container.addChild(door)
            }
            // Emblem
            if type == .barracks {
                let emblem = SKShapeNode(rectOf: CGSize(width: 3, height: 8))
                emblem.fillColor = .white
                emblem.strokeColor = .clear
                emblem.position = CGPoint(x: 0, y: h * 0.1)
                emblem.zPosition = detailZ
                container.addChild(emblem)
                let crossbar = SKShapeNode(rectOf: CGSize(width: 6, height: 2))
                crossbar.fillColor = .white
                crossbar.strokeColor = .clear
                crossbar.position = CGPoint(x: 0, y: h * 0.13)
                crossbar.zPosition = detailZ
                container.addChild(crossbar)
            }

        case .castle:
            // Gate
            let gate = SKShapeNode(rectOf: CGSize(width: w * 0.18, height: h * 0.22))
            gate.fillColor = SKColor(red: 0.25, green: 0.2, blue: 0.15, alpha: 1.0)
            gate.strokeColor = .clear
            gate.position = CGPoint(x: 0, y: -h * 0.28)
            gate.zPosition = detailZ
            container.addChild(gate)
            // Corner turrets with merlons
            for (xOff, yOff) in [(-w * 0.35, h * 0.35), (w * 0.35, h * 0.35),
                                  (-w * 0.35, -h * 0.35), (w * 0.35, -h * 0.35)] {
                let turret = SKShapeNode(circleOfRadius: w * 0.08)
                turret.fillColor = type.color.darker(by: 0.1)
                turret.strokeColor = playerColor
                turret.lineWidth = 1
                turret.position = CGPoint(x: xOff, y: yOff)
                turret.zPosition = detailZ
                container.addChild(turret)
            }

        case .tower:
            // Arrow slits
            for yOff in [-h * 0.1, h * 0.1] as [CGFloat] {
                let slit = SKShapeNode(rectOf: CGSize(width: 2, height: h * 0.15))
                slit.fillColor = SKColor.black.withAlphaComponent(0.6)
                slit.strokeColor = .clear
                slit.position = CGPoint(x: 0, y: yOff)
                slit.zPosition = detailZ
                container.addChild(slit)
            }

        case .blacksmith:
            // Anvil shape
            let anvil = SKShapeNode(rectOf: CGSize(width: w * 0.2, height: h * 0.12))
            anvil.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.35, alpha: 1.0)
            anvil.strokeColor = .clear
            anvil.position = CGPoint(x: 0, y: -h * 0.1)
            anvil.zPosition = detailZ
            container.addChild(anvil)
            // Chimney
            let chimney = SKShapeNode(rectOf: CGSize(width: w * 0.08, height: h * 0.2))
            chimney.fillColor = type.color.darker(by: 0.15)
            chimney.strokeColor = .clear
            chimney.position = CGPoint(x: w * 0.3, y: h * 0.3)
            chimney.zPosition = detailZ
            container.addChild(chimney)

        default:
            break
        }
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
                container.childNode(withName: "scaffolding")?.removeFromParent()
            } else {
                let barWidth = w * 0.8 * building.constructionProgress
                let path = CGPath(rect: CGRect(x: 0, y: -2, width: barWidth, height: 4), transform: nil)
                progressBar.path = path
            }
        }

        // Show fire on heavily damaged buildings
        let hpRatio = CGFloat(building.hp) / CGFloat(building.maxHP)
        if building.isConstructed && hpRatio < 0.4 {
            if container.childNode(withName: "torchFire") == nil {
                let w = CGFloat(building.type.size.width) * tileSize
                let h = CGFloat(building.type.size.height) * tileSize
                let fire = createTorchEffect(at: CGPoint(x: CGFloat.random(in: -w*0.2...w*0.2),
                                                           y: CGFloat.random(in: -h*0.1...h*0.2)))
                container.addChild(fire)
            }
        } else {
            container.childNode(withName: "torchFire")?.removeFromParent()
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
            let container = SKNode()
            container.position = position
            container.zPosition = 15
            container.name = "projectile"

            // Main projectile
            let projectile = SKShapeNode(circleOfRadius: 2.5)
            projectile.fillColor = .yellow
            projectile.strokeColor = .orange
            projectile.lineWidth = 1
            container.addChild(projectile)

            // Glow halo
            let glow = SKShapeNode(circleOfRadius: 5)
            glow.fillColor = SKColor.yellow.withAlphaComponent(0.2)
            glow.strokeColor = .clear
            glow.run(SKAction.repeatForever(SKAction.sequence([
                SKAction.fadeAlpha(to: 0.1, duration: 0.1),
                SKAction.fadeAlpha(to: 0.3, duration: 0.1)
            ])))
            container.addChild(glow)

            // Rotation
            projectile.run(SKAction.repeatForever(SKAction.rotate(byAngle: .pi * 2, duration: 0.3)))

            return container
        } else {
            // Enhanced melee effect: multiple slashes + hit splatter
            let container = SKNode()
            container.position = position
            container.zPosition = 15

            // Multiple slash lines
            for i in 0..<3 {
                let slash = SKShapeNode(rectOf: CGSize(width: 10, height: 2))
                slash.fillColor = .white
                slash.strokeColor = .clear
                slash.zRotation = CGFloat.random(in: 0...(.pi * 2))
                slash.alpha = 0.9

                let fadeOut = SKAction.sequence([
                    SKAction.wait(forDuration: TimeInterval(i) * 0.05),
                    SKAction.group([
                        SKAction.fadeOut(withDuration: 0.25),
                        SKAction.scale(to: 2.0, duration: 0.25)
                    ]),
                    SKAction.removeFromParent()
                ])
                slash.run(fadeOut)
                container.addChild(slash)
            }

            // Hit splatter particles
            for _ in 0..<4 {
                let dot = SKShapeNode(circleOfRadius: 1.5)
                dot.fillColor = [SKColor.red, SKColor.orange].randomElement()!
                dot.strokeColor = .clear
                let dx = CGFloat.random(in: -8...8)
                let dy = CGFloat.random(in: -8...8)
                let splat = SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: dx, y: dy, duration: 0.2),
                        SKAction.fadeOut(withDuration: 0.2)
                    ]),
                    SKAction.removeFromParent()
                ])
                dot.run(splat)
                container.addChild(dot)
            }

            let cleanup = SKAction.sequence([
                SKAction.wait(forDuration: 0.4),
                SKAction.removeFromParent()
            ])
            container.run(cleanup)
            return container
        }
    }

    func createDamageNumber(at position: CGPoint, damage: Int) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 25

        // Dark shadow label for readability
        let shadow = SKLabelNode(text: "-\(damage)")
        shadow.fontSize = 18
        shadow.fontName = "Helvetica-Bold"
        shadow.fontColor = SKColor.black.withAlphaComponent(0.7)
        shadow.verticalAlignmentMode = .center
        shadow.horizontalAlignmentMode = .center
        shadow.position = CGPoint(x: 1, y: -1)
        container.addChild(shadow)

        let label = SKLabelNode(text: "-\(damage)")
        label.fontSize = 18
        label.fontName = "Helvetica-Bold"
        label.fontColor = .red
        label.verticalAlignmentMode = .center
        label.horizontalAlignmentMode = .center
        container.addChild(label)

        let floatUp = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: CGFloat.random(in: -5...5), y: 30, duration: 1.0),
                SKAction.fadeOut(withDuration: 1.0)
            ]),
            SKAction.removeFromParent()
        ])
        container.run(floatUp)
        return container
    }

    func createDepositFeedback(at position: CGPoint, amount: Int, resourceType: ResourceType) -> SKNode {
        let color: SKColor
        switch resourceType {
        case .food: color = SKColor(red: 0.9, green: 0.3, blue: 0.3, alpha: 1.0)
        case .wood: color = SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .gold: color = SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 1.0)
        case .stone: color = SKColor(red: 0.7, green: 0.7, blue: 0.7, alpha: 1.0)
        }

        let label = SKLabelNode(text: "+\(amount)")
        label.fontSize = 12
        label.fontName = "Helvetica-Bold"
        label.fontColor = color
        label.position = position
        label.zPosition = 25
        label.verticalAlignmentMode = .center

        let floatUp = SKAction.sequence([
            SKAction.group([
                SKAction.moveBy(x: 0, y: 18, duration: 0.5),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ])
        label.run(floatUp)
        return label
    }

    func createProjectileTrail(at position: CGPoint) -> SKNode {
        let dot = SKShapeNode(circleOfRadius: 1)
        dot.fillColor = SKColor.yellow.withAlphaComponent(0.6)
        dot.strokeColor = .clear
        dot.position = position
        dot.zPosition = 14

        let fade = SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ])
        dot.run(fade)
        return dot
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

    func createMoveIndicator(at position: CGPoint) -> SKNode {
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.4)
        ring.fillColor = .clear
        ring.strokeColor = SKColor.green.withAlphaComponent(0.8)
        ring.lineWidth = 2
        ring.position = position
        ring.zPosition = 15
        ring.setScale(1.5)

        let anim = SKAction.sequence([
            SKAction.group([
                SKAction.scale(to: 0.5, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.4)
            ]),
            SKAction.removeFromParent()
        ])
        ring.run(anim)
        return ring
    }

    func createRallyFlag(at position: CGPoint, playerColor: SKColor) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 25
        container.name = "rallyFlag"

        // Flag pole
        let pole = SKShapeNode(rectOf: CGSize(width: 1.5, height: tileSize * 0.8))
        pole.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        pole.strokeColor = .clear
        pole.position = CGPoint(x: 0, y: tileSize * 0.2)
        container.addChild(pole)

        // Flag triangle
        let flagPath = CGMutablePath()
        flagPath.move(to: CGPoint(x: 1, y: tileSize * 0.6))
        flagPath.addLine(to: CGPoint(x: tileSize * 0.4, y: tileSize * 0.45))
        flagPath.addLine(to: CGPoint(x: 1, y: tileSize * 0.3))
        flagPath.closeSubpath()
        let flag = SKShapeNode(path: flagPath)
        flag.fillColor = playerColor
        flag.strokeColor = playerColor.withAlphaComponent(0.8)
        flag.lineWidth = 0.5
        container.addChild(flag)

        // Gentle wave animation
        let wave = SKAction.repeatForever(SKAction.sequence([
            SKAction.scaleX(to: 1.1, duration: 0.6),
            SKAction.scaleX(to: 0.9, duration: 0.6)
        ]))
        flag.run(wave)

        return container
    }

    func createDeathEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 20

        // Larger white flash
        let flash = SKShapeNode(circleOfRadius: tileSize * 0.6)
        flash.fillColor = SKColor.white.withAlphaComponent(0.8)
        flash.strokeColor = .clear
        flash.run(SKAction.sequence([
            SKAction.fadeOut(withDuration: 0.3),
            SKAction.removeFromParent()
        ]))
        container.addChild(flash)

        // 16 particles with wider spread
        for _ in 0..<16 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 1.5...3.5))
            particle.fillColor = [SKColor.orange, SKColor.red, SKColor.yellow].randomElement()!
            particle.strokeColor = .clear
            particle.position = .zero

            let dx = CGFloat.random(in: -25...25)
            let dy = CGFloat.random(in: -25...25)

            let anim = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.7),
                    SKAction.fadeOut(withDuration: 0.7),
                    SKAction.scale(to: 0.1, duration: 0.7)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(anim)
            container.addChild(particle)
        }

        // Scorch mark on ground (persists 3s)
        let scorch = SKShapeNode(circleOfRadius: tileSize * 0.35)
        scorch.fillColor = SKColor(red: 0.15, green: 0.1, blue: 0.05, alpha: 0.5)
        scorch.strokeColor = .clear
        scorch.zPosition = -1
        scorch.run(SKAction.sequence([
            SKAction.wait(forDuration: 3.0),
            SKAction.fadeOut(withDuration: 0.5),
            SKAction.removeFromParent()
        ]))
        container.addChild(scorch)

        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: 3.8),
            SKAction.removeFromParent()
        ])
        container.run(cleanup)
        return container
    }

    func createBuildingDestructionEffect(at position: CGPoint, buildingSize: CGSize) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 20

        // Large dust cloud
        for _ in 0..<20 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...5))
            particle.fillColor = [
                SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 0.8),
                SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 0.7),
                SKColor.orange.withAlphaComponent(0.5)
            ].randomElement()!
            particle.strokeColor = .clear

            let dx = CGFloat.random(in: -buildingSize.width * 0.5...buildingSize.width * 0.5)
            let dy = CGFloat.random(in: -buildingSize.height * 0.3...buildingSize.height * 0.5)

            let anim = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.8),
                    SKAction.fadeOut(withDuration: 0.8),
                    SKAction.scale(to: 2.0, duration: 0.8)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(anim)
            container.addChild(particle)
        }

        // Debris falling
        for _ in 0..<8 {
            let debris = SKShapeNode(rectOf: CGSize(width: CGFloat.random(in: 3...6),
                                                     height: CGFloat.random(in: 2...4)))
            debris.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
            debris.strokeColor = .clear

            let dx = CGFloat.random(in: -30...30)
            let dy = CGFloat.random(in: 10...40)

            let fall = SKAction.sequence([
                SKAction.moveBy(x: dx, y: dy, duration: 0.3),
                SKAction.moveBy(x: dx * 0.5, y: -dy * 1.5, duration: 0.4),
                SKAction.fadeOut(withDuration: 0.3),
                SKAction.removeFromParent()
            ])
            debris.zRotation = CGFloat.random(in: 0...(CGFloat.pi * 2))
            debris.run(fall)
            container.addChild(debris)
        }

        let cleanup = SKAction.sequence([
            SKAction.wait(forDuration: 2.0),
            SKAction.removeFromParent()
        ])
        container.run(cleanup)
        return container
    }

    func createWeatherEffect(type: WeatherType, viewSize: CGSize) -> SKNode {
        let container = SKNode()
        container.name = "weatherEffect"
        container.zPosition = 80

        switch type {
        case .rain:
            for _ in 0..<40 {
                let drop = SKShapeNode(rectOf: CGSize(width: 1, height: 8))
                drop.fillColor = SKColor(red: 0.5, green: 0.6, blue: 0.9, alpha: 0.3)
                drop.strokeColor = .clear
                drop.position = CGPoint(
                    x: CGFloat.random(in: -viewSize.width/2...viewSize.width/2),
                    y: CGFloat.random(in: -viewSize.height/2...viewSize.height/2)
                )

                let fall = SKAction.repeatForever(SKAction.sequence([
                    SKAction.moveBy(x: -20, y: -viewSize.height, duration: Double.random(in: 0.5...1.0)),
                    SKAction.run { drop.position.y += viewSize.height; drop.position.x += 20 }
                ]))
                drop.run(fall)
                container.addChild(drop)
            }
        case .snow:
            for _ in 0..<25 {
                let flake = SKShapeNode(circleOfRadius: CGFloat.random(in: 1...3))
                flake.fillColor = SKColor.white.withAlphaComponent(CGFloat.random(in: 0.3...0.6))
                flake.strokeColor = .clear
                flake.position = CGPoint(
                    x: CGFloat.random(in: -viewSize.width/2...viewSize.width/2),
                    y: CGFloat.random(in: -viewSize.height/2...viewSize.height/2)
                )

                let drift = SKAction.repeatForever(SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -10...10), y: -viewSize.height, duration: Double.random(in: 2...4)),
                    ]),
                    SKAction.run { flake.position.y += viewSize.height }
                ]))
                flake.run(drift)
                container.addChild(flake)
            }
        case .clear:
            break
        }

        return container
    }

    func createTorchEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 16
        container.name = "torchFire"

        let fireAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak container] in
                guard let container = container else { return }
                let flame = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
                flame.fillColor = [SKColor.orange, SKColor.red, SKColor.yellow].randomElement()!
                flame.strokeColor = .clear
                flame.position = CGPoint(x: CGFloat.random(in: -3...3), y: 0)

                let rise = SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -2...2), y: CGFloat.random(in: 8...14), duration: 0.4),
                        SKAction.fadeOut(withDuration: 0.4),
                        SKAction.scale(to: 0.3, duration: 0.4)
                    ]),
                    SKAction.removeFromParent()
                ])
                flame.run(rise)
                container.addChild(flame)
            },
            SKAction.wait(forDuration: 0.15)
        ]))
        container.run(fireAction)

        return container
    }

    func createPlacementGhost(type: BuildingType, validPlacement: Bool) -> SKNode {
        let w = CGFloat(type.size.width) * tileSize
        let h = CGFloat(type.size.height) * tileSize

        let ghost = SKShapeNode(rectOf: CGSize(width: w - 2, height: h - 2))
        ghost.fillColor = validPlacement
            ? SKColor.green.withAlphaComponent(0.3)
            : SKColor.red.withAlphaComponent(0.3)
        ghost.strokeColor = validPlacement
            ? SKColor.green.withAlphaComponent(0.8)
            : SKColor.red.withAlphaComponent(0.8)
        ghost.lineWidth = 2
        ghost.zPosition = 45
        ghost.name = "placementGhost"

        // Size label
        let label = SKLabelNode(text: type.icon)
        label.fontSize = min(w, h) * 0.3
        label.fontName = "Helvetica-Bold"
        label.fontColor = .white
        label.verticalAlignmentMode = .center
        ghost.addChild(label)

        // Pulsing effect
        let pulse = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 0.5),
            SKAction.fadeAlpha(to: 1.0, duration: 0.5)
        ]))
        ghost.run(pulse)

        return ghost
    }

    // MARK: - Relic Sprite

    func createRelicNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 4
        container.name = "relic"

        let glow = SKShapeNode(circleOfRadius: tileSize * 0.4)
        glow.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.2, alpha: 0.3)
        glow.strokeColor = .clear
        container.addChild(glow)

        let body = SKShapeNode(rectOf: CGSize(width: tileSize * 0.3, height: tileSize * 0.4), cornerRadius: 2)
        body.fillColor = SKColor(red: 0.85, green: 0.7, blue: 0.1, alpha: 1.0)
        body.strokeColor = SKColor(red: 0.6, green: 0.5, blue: 0.1, alpha: 1.0)
        body.lineWidth = 1.5
        container.addChild(body)

        let cross = SKLabelNode(text: "\u{271A}")
        cross.fontSize = tileSize * 0.25
        cross.fontColor = SKColor(red: 0.95, green: 0.85, blue: 0.3, alpha: 1.0)
        cross.verticalAlignmentMode = .center
        cross.horizontalAlignmentMode = .center
        container.addChild(cross)

        // Shimmer animation
        let shimmer = SKAction.repeatForever(SKAction.sequence([
            SKAction.fadeAlpha(to: 0.5, duration: 1.0),
            SKAction.fadeAlpha(to: 1.0, duration: 1.0)
        ]))
        glow.run(shimmer)

        return container
    }

    // MARK: - Building Smoke Effect

    func createBuildingSmokeEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 16
        container.name = "buildingSmoke"

        let smokeAction = SKAction.repeatForever(SKAction.sequence([
            SKAction.run { [weak container] in
                guard let container = container else { return }
                let smoke = SKShapeNode(circleOfRadius: CGFloat.random(in: 3...6))
                smoke.fillColor = SKColor(red: 0.3, green: 0.3, blue: 0.3, alpha: 0.4)
                smoke.strokeColor = .clear
                smoke.position = CGPoint(x: CGFloat.random(in: -8...8), y: 0)

                let rise = SKAction.sequence([
                    SKAction.group([
                        SKAction.moveBy(x: CGFloat.random(in: -5...5), y: CGFloat.random(in: 12...20), duration: 1.0),
                        SKAction.fadeOut(withDuration: 1.0),
                        SKAction.scale(to: 2.0, duration: 1.0)
                    ]),
                    SKAction.removeFromParent()
                ])
                smoke.run(rise)
                container.addChild(smoke)
            },
            SKAction.wait(forDuration: 0.3)
        ]))
        container.run(smokeAction)

        return container
    }

    // MARK: - Impact/Hit Effect

    func createImpactEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 15

        for _ in 0..<4 {
            let particle = SKShapeNode(circleOfRadius: 2)
            particle.fillColor = SKColor(red: 0.8, green: 0.6, blue: 0.2, alpha: 0.8)
            particle.strokeColor = .clear
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 5...12)
            let dx = cos(angle) * dist
            let dy = sin(angle) * dist
            let scatter = SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: dx, y: dy, duration: 0.3),
                    SKAction.fadeOut(withDuration: 0.3)
                ]),
                SKAction.removeFromParent()
            ])
            particle.run(scatter)
            container.addChild(particle)
        }

        let removeContainer = SKAction.sequence([
            SKAction.wait(forDuration: 0.4),
            SKAction.removeFromParent()
        ])
        container.run(removeContainer)
        return container
    }

    // MARK: - Building Rubble

    func createRubbleNode(at position: CGPoint, size: CGSize) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 3
        container.name = "rubble"

        for _ in 0..<5 {
            let rubble = SKShapeNode(rectOf: CGSize(
                width: CGFloat.random(in: 4...8),
                height: CGFloat.random(in: 3...6)
            ))
            rubble.fillColor = SKColor(red: 0.45, green: 0.4, blue: 0.35, alpha: 0.7)
            rubble.strokeColor = .clear
            rubble.position = CGPoint(
                x: CGFloat.random(in: -size.width/3...size.width/3),
                y: CGFloat.random(in: -size.height/3...size.height/3)
            )
            rubble.zRotation = CGFloat.random(in: 0...(.pi * 2))
            container.addChild(rubble)
        }

        // Fade out rubble after 15 seconds
        container.run(SKAction.sequence([
            SKAction.wait(forDuration: 15.0),
            SKAction.fadeOut(withDuration: 2.0),
            SKAction.removeFromParent()
        ]))

        return container
    }

    // MARK: - Rally Point Flag

    func createRallyFlagNode(at position: CGPoint, playerColor: SKColor) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 6
        container.name = "rallyFlag"

        let pole = SKShapeNode(rectOf: CGSize(width: 1.5, height: tileSize * 0.5))
        pole.fillColor = SKColor(red: 0.4, green: 0.3, blue: 0.2, alpha: 1.0)
        pole.strokeColor = .clear
        pole.position = CGPoint(x: 0, y: tileSize * 0.15)
        container.addChild(pole)

        let flag = SKShapeNode(rectOf: CGSize(width: tileSize * 0.25, height: tileSize * 0.15))
        flag.fillColor = playerColor
        flag.strokeColor = .clear
        flag.position = CGPoint(x: tileSize * 0.13, y: tileSize * 0.35)
        container.addChild(flag)

        // Flag waving
        let wave = SKAction.repeatForever(SKAction.sequence([
            SKAction.moveBy(x: 2, y: 0, duration: 0.4),
            SKAction.moveBy(x: -2, y: 0, duration: 0.4)
        ]))
        flag.run(wave)

        return container
    }

    // MARK: - Explosion Effect (for Petard)

    func createExplosionEffect(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 20

        // Central flash
        let flash = SKShapeNode(circleOfRadius: tileSize * 0.6)
        flash.fillColor = SKColor(red: 1.0, green: 0.8, blue: 0.2, alpha: 0.9)
        flash.strokeColor = .clear
        container.addChild(flash)

        // Expanding ring
        let ring = SKShapeNode(circleOfRadius: tileSize * 0.3)
        ring.fillColor = .clear
        ring.strokeColor = SKColor(red: 1.0, green: 0.5, blue: 0.1, alpha: 0.8)
        ring.lineWidth = 3
        container.addChild(ring)

        // Particles
        for _ in 0..<8 {
            let particle = SKShapeNode(circleOfRadius: CGFloat.random(in: 2...4))
            particle.fillColor = [SKColor.orange, SKColor.red, SKColor.yellow].randomElement()!
            particle.strokeColor = .clear
            let angle = CGFloat.random(in: 0...(2 * .pi))
            let dist = CGFloat.random(in: 15...30)
            particle.run(SKAction.sequence([
                SKAction.group([
                    SKAction.moveBy(x: cos(angle) * dist, y: sin(angle) * dist, duration: 0.5),
                    SKAction.fadeOut(withDuration: 0.5)
                ]),
                SKAction.removeFromParent()
            ]))
            container.addChild(particle)
        }

        container.run(SKAction.sequence([
            SKAction.group([
                SKAction.sequence([
                    SKAction.scale(to: 2.0, duration: 0.3),
                    SKAction.scale(to: 0.5, duration: 0.2)
                ]),
                SKAction.fadeOut(withDuration: 0.5)
            ]),
            SKAction.removeFromParent()
        ]))

        return container
    }

    // MARK: - Day/Night Overlay

    func createDayNightOverlay(viewSize: CGSize) -> SKShapeNode {
        let overlay = SKShapeNode(rectOf: CGSize(width: viewSize.width * 2, height: viewSize.height * 2))
        overlay.fillColor = .clear
        overlay.strokeColor = .clear
        overlay.zPosition = 75
        overlay.name = "dayNightOverlay"
        overlay.isUserInteractionEnabled = false
        return overlay
    }

    // MARK: - Fish Trap Sprite

    func createFishTrapNode(at position: CGPoint) -> SKNode {
        let container = SKNode()
        container.position = position
        container.zPosition = 3

        let net = SKShapeNode(circleOfRadius: tileSize * 0.35)
        net.fillColor = SKColor(red: 0.3, green: 0.45, blue: 0.5, alpha: 0.5)
        net.strokeColor = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 0.7)
        net.lineWidth = 1.5
        container.addChild(net)

        // Net lines
        for i in 0..<4 {
            let line = SKShapeNode(rectOf: CGSize(width: 1, height: tileSize * 0.6))
            line.fillColor = SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 0.5)
            line.strokeColor = .clear
            line.zRotation = CGFloat(i) * .pi / 4.0
            container.addChild(line)
        }

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
