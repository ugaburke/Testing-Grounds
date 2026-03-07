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

        // Reveal around units
        for unit in player.units {
            revealArea(around: unit.gridPosition, range: sightRange)
        }

        // Reveal around buildings
        for building in player.buildings {
            let buildingRange = building.type == .tower ? sightRange + 3 : sightRange
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
                    // Fully visible — fade out fog smoothly
                    if let fogNode = fogNodes[y][x] {
                        fogNode.run(SKAction.sequence([
                            SKAction.fadeOut(withDuration: fadeDuration),
                            SKAction.removeFromParent()
                        ]))
                        fogNodes[y][x] = nil
                    }

                    // Fade tile to full visibility
                    if let tileNode = tile.node, tileNode.alpha < 1.0 {
                        tileNode.run(SKAction.fadeAlpha(to: 1.0, duration: fadeDuration), withKey: "fogFade")
                    }
                } else if tile.isExplored {
                    // Explored but not visible - dim
                    if let tileNode = tile.node, abs(tileNode.alpha - 0.65) > 0.05 {
                        tileNode.run(SKAction.fadeAlpha(to: 0.65, duration: fadeDuration), withKey: "fogFade")
                    }

                    if fogNodes[y][x] == nil {
                        let fogNode = SKShapeNode(rectOf: CGSize(width: map.tileSize, height: map.tileSize))
                        fogNode.fillColor = SKColor.black.withAlphaComponent(0.25)
                        fogNode.strokeColor = .clear
                        fogNode.position = map.gridToWorld(GridPosition(x: x, y: y))
                        fogNode.zPosition = 50
                        fogNode.alpha = 0
                        map.mapNode.addChild(fogNode)
                        fogNode.run(SKAction.fadeAlpha(to: 1.0, duration: fadeDuration))
                        fogNodes[y][x] = fogNode
                    }
                } else {
                    // Unexplored - black
                    if let tileNode = tile.node, tileNode.alpha > 0.05 {
                        tileNode.run(SKAction.fadeAlpha(to: 0.0, duration: fadeDuration), withKey: "fogFade")
                    }

                    if fogNodes[y][x] == nil {
                        let fogNode = SKShapeNode(rectOf: CGSize(width: map.tileSize, height: map.tileSize))
                        fogNode.fillColor = SKColor.black.withAlphaComponent(0.75)
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
