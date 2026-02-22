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

        for y in minY...maxY {
            for x in minX...maxX {
                let tile = map.tiles[y][x]

                if tile.isVisible {
                    // Fully visible - remove fog
                    fogNodes[y][x]?.removeFromParent()
                    fogNodes[y][x] = nil

                    // Show tile and entities
                    tile.node?.alpha = 1.0
                } else if tile.isExplored {
                    // Explored but not visible - dim
                    tile.node?.alpha = 0.5

                    if fogNodes[y][x] == nil {
                        let fogNode = SKShapeNode(rectOf: CGSize(width: map.tileSize, height: map.tileSize))
                        fogNode.fillColor = SKColor.black.withAlphaComponent(0.4)
                        fogNode.strokeColor = .clear
                        fogNode.position = map.gridToWorld(GridPosition(x: x, y: y))
                        fogNode.zPosition = 50
                        map.mapNode.addChild(fogNode)
                        fogNodes[y][x] = fogNode
                    }
                } else {
                    // Unexplored - black
                    tile.node?.alpha = 0.0

                    if fogNodes[y][x] == nil {
                        let fogNode = SKShapeNode(rectOf: CGSize(width: map.tileSize, height: map.tileSize))
                        fogNode.fillColor = SKColor.black.withAlphaComponent(0.85)
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
