import Foundation
import SpriteKit

class FogOfWar {
    let map: GameMap
    let sightRange: Int = 8
    var fogNodes: [[SKShapeNode?]]

    init(map: GameMap) {
        self.map = map
        self.fogNodes = Array(repeating: Array(repeating: nil, count: map.width), count: map.height)
    }

    func update(player: Player) {
        // Reset visibility
        for y in 0..<map.height {
            for x in 0..<map.width {
                map.tiles[y][x].isVisible = false
            }
        }

        // Reveal around units (scouts and mounted units get bonus vision)
        for unit in player.units {
            var unitRange = sightRange
            if unit.type == .scout || unit.type == .mangudai { unitRange += 4 }
            else if unit.type == .lightCavalry { unitRange += 2 }
            revealArea(around: unit.gridPosition, range: unitRange)
        }

        // Reveal around buildings (use building-specific sight ranges)
        let hasTownWatch = player.researchedTechs.contains(.townWatch)
        for building in player.buildings {
            var buildingRange = building.type.sightRange
            // Town Watch: +2 LOS for all buildings
            if hasTownWatch { buildingRange += 2 }
            revealArea(around: building.gridPosition, range: buildingRange)
        }
    }

    private func revealArea(around center: GridPosition, range: Int) {
        for dy in -range...range {
            for dx in -range...range {
                let pos = GridPosition(x: center.x + dx, y: center.y + dy)
                guard map.isValid(pos) else { continue }
                let dist = center.distance(to: pos)
                if dist <= CGFloat(range) {
                    map.tiles[pos.y][pos.x].isVisible = true
                    map.tiles[pos.y][pos.x].isExplored = true
                }
            }
        }
    }

    // Count how many adjacent tiles are visible for smooth boundary transition
    private func visibleNeighborCount(x: Int, y: Int) -> Int {
        var count = 0
        for dy in -1...1 {
            for dx in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let nx = x + dx
                let ny = y + dy
                if nx >= 0 && nx < map.width && ny >= 0 && ny < map.height {
                    if map.tiles[ny][nx].isVisible {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    // Count how many adjacent tiles are explored for unexplored boundary transition
    private func exploredNeighborCount(x: Int, y: Int) -> Int {
        var count = 0
        for dy in -1...1 {
            for dx in -1...1 {
                if dx == 0 && dy == 0 { continue }
                let nx = x + dx
                let ny = y + dy
                if nx >= 0 && nx < map.width && ny >= 0 && ny < map.height {
                    if map.tiles[ny][nx].isExplored {
                        count += 1
                    }
                }
            }
        }
        return count
    }

    func updateVisuals(cameraPosition: CGPoint, viewSize: CGSize) {
        let tilesX = Int(viewSize.width / map.tileSize) + 4
        let tilesY = Int(viewSize.height / map.tileSize) + 4
        let centerTileX = Int(cameraPosition.x / map.tileSize)
        let centerTileY = Int(cameraPosition.y / map.tileSize)

        let minX = max(0, centerTileX - tilesX / 2)
        let maxX = min(map.width - 1, centerTileX + tilesX / 2)
        let minY = max(0, centerTileY - tilesY / 2)
        let maxY = min(map.height - 1, centerTileY + tilesY / 2)

        let fadeDuration: TimeInterval = 0.3

        for y in minY...maxY {
            for x in minX...maxX {
                let tile = map.tiles[y][x]

                if tile.isVisible {
                    // Fully visible — fade out fog but keep node for reuse
                    if let fogNode = fogNodes[y][x] {
                        if fogNode.alpha > 0.01 {
                            fogNode.run(SKAction.fadeAlpha(to: 0.0, duration: fadeDuration), withKey: "fogFade")
                        }
                    }

                    // Fade tile to full visibility
                    if let tileNode = tile.node, tileNode.alpha < 1.0 {
                        tileNode.run(SKAction.fadeAlpha(to: 1.0, duration: fadeDuration), withKey: "fogFade")
                    }
                } else if tile.isExplored {
                    // Explored but not visible - smooth boundary transition
                    let visNeighbors = visibleNeighborCount(x: x, y: y)

                    // Tile alpha: more visible neighbors means brighter (smoother edge)
                    let tileAlpha: CGFloat = visNeighbors > 0
                        ? min(0.9, 0.65 + CGFloat(visNeighbors) * 0.035)
                        : 0.65

                    if let tileNode = tile.node, abs(tileNode.alpha - tileAlpha) > 0.03 {
                        tileNode.run(SKAction.fadeAlpha(to: tileAlpha, duration: fadeDuration), withKey: "fogFade")
                    }

                    // Fog overlay alpha: boundary tiles get lighter fog for gradient effect
                    let fogTargetAlpha: CGFloat = visNeighbors > 0
                        ? max(0.2, 1.0 - CGFloat(visNeighbors) * 0.1)
                        : 1.0

                    // Fog fill opacity also varies at boundary for smoother blend
                    let fogFillAlpha: CGFloat = visNeighbors > 0
                        ? max(0.08, 0.25 - CGFloat(visNeighbors) * 0.02)
                        : 0.25

                    if let fogNode = fogNodes[y][x] {
                        // Reuse existing fog node — adjust alpha
                        if abs(fogNode.alpha - fogTargetAlpha) > 0.05 {
                            fogNode.run(SKAction.fadeAlpha(to: fogTargetAlpha, duration: fadeDuration), withKey: "fogFade")
                        }
                        fogNode.fillColor = SKColor.black.withAlphaComponent(fogFillAlpha)
                    } else {
                        // Use slightly larger fog node at boundaries for overlap blending
                        let nodeSize = visNeighbors > 0
                            ? CGSize(width: map.tileSize * 1.15, height: map.tileSize * 1.15)
                            : CGSize(width: map.tileSize, height: map.tileSize)
                        let fogNode = SKShapeNode(rectOf: nodeSize, cornerRadius: visNeighbors > 0 ? map.tileSize * 0.15 : 0)
                        fogNode.fillColor = SKColor.black.withAlphaComponent(fogFillAlpha)
                        fogNode.strokeColor = .clear
                        fogNode.position = map.gridToWorld(GridPosition(x: x, y: y))
                        fogNode.zPosition = 50
                        fogNode.alpha = 0
                        map.mapNode.addChild(fogNode)
                        fogNode.run(SKAction.fadeAlpha(to: fogTargetAlpha, duration: fadeDuration), withKey: "fogFade")
                        fogNodes[y][x] = fogNode
                    }
                } else {
                    // Unexplored — smooth boundary for tiles adjacent to explored areas
                    let expNeighbors = exploredNeighborCount(x: x, y: y)

                    if let tileNode = tile.node, tileNode.alpha > 0.05 {
                        tileNode.run(SKAction.fadeAlpha(to: 0.0, duration: fadeDuration), withKey: "fogFade")
                    }

                    // Boundary unexplored tiles get softer fog for gradient transition
                    let unexploredFillAlpha: CGFloat = expNeighbors > 0
                        ? max(0.45, 0.75 - CGFloat(expNeighbors) * 0.04)
                        : 0.75

                    if let fogNode = fogNodes[y][x] {
                        fogNode.fillColor = SKColor.black.withAlphaComponent(unexploredFillAlpha)
                    } else {
                        let nodeSize = expNeighbors > 0
                            ? CGSize(width: map.tileSize * 1.1, height: map.tileSize * 1.1)
                            : CGSize(width: map.tileSize, height: map.tileSize)
                        let fogNode = SKShapeNode(rectOf: nodeSize, cornerRadius: expNeighbors > 0 ? map.tileSize * 0.1 : 0)
                        fogNode.fillColor = SKColor.black.withAlphaComponent(unexploredFillAlpha)
                        fogNode.strokeColor = .clear
                        fogNode.position = map.gridToWorld(GridPosition(x: x, y: y))
                        fogNode.zPosition = 50
                        map.mapNode.addChild(fogNode)
                        fogNodes[y][x] = fogNode
                    }
                }
            }
        }
    }

    func removeFarFogNodes(cameraPosition: CGPoint, viewSize: CGSize) {
        let bufferTiles = 6
        let tilesX = Int(viewSize.width / map.tileSize) / 2 + bufferTiles
        let tilesY = Int(viewSize.height / map.tileSize) / 2 + bufferTiles
        let centerTileX = Int(cameraPosition.x / map.tileSize)
        let centerTileY = Int(cameraPosition.y / map.tileSize)

        for y in 0..<map.height {
            for x in 0..<map.width {
                if abs(x - centerTileX) > tilesX || abs(y - centerTileY) > tilesY {
                    fogNodes[y][x]?.removeFromParent()
                    fogNodes[y][x] = nil
                }
            }
        }
    }
}
