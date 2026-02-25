import Foundation
import SpriteKit

class FogOfWar {
    let map: GameMap
    let sightRange: Int = 8
    var fogNodes: [[SKSpriteNode?]]
    private var previouslyVisible: Set<Int> = Set<Int>()

    init(map: GameMap) {
        self.map = map
        self.fogNodes = Array(repeating: Array(repeating: nil, count: map.width), count: map.height)
    }

    func update(player: Player) {
        // Clear only previously visible tiles instead of all 50*50
        for key in previouslyVisible {
            let y = key / map.width
            let x = key % map.width
            map.tiles[y][x].isVisible = false
        }
        previouslyVisible.removeAll(keepingCapacity: true)

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
        let minY = max(0, center.y - range)
        let maxY = min(map.height - 1, center.y + range)
        let minX = max(0, center.x - range)
        let maxX = min(map.width - 1, center.x + range)
        let rangeSq = CGFloat(range * range)

        for y in minY...maxY {
            for x in minX...maxX {
                let dx = CGFloat(x - center.x)
                let dy = CGFloat(y - center.y)
                if dx * dx + dy * dy <= rangeSq {
                    map.tiles[y][x].isVisible = true
                    map.tiles[y][x].isExplored = true
                    previouslyVisible.insert(y * map.width + x)
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
                    fogNodes[y][x]?.removeFromParent()
                    fogNodes[y][x] = nil
                    tile.node?.alpha = 1.0
                } else if tile.isExplored {
                    tile.node?.alpha = 0.5
                    if fogNodes[y][x] == nil {
                        let fogNode = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.4),
                                                    size: CGSize(width: map.tileSize, height: map.tileSize))
                        fogNode.position = map.gridToWorld(GridPosition(x: x, y: y))
                        fogNode.zPosition = 50
                        map.mapNode.addChild(fogNode)
                        fogNodes[y][x] = fogNode
                    }
                } else {
                    tile.node?.alpha = 0.0
                    if fogNodes[y][x] == nil {
                        let fogNode = SKSpriteNode(color: SKColor.black.withAlphaComponent(0.85),
                                                    size: CGSize(width: map.tileSize, height: map.tileSize))
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

        let minX = max(0, centerTileX - tilesX)
        let maxX = min(map.width - 1, centerTileX + tilesX)
        let minY = max(0, centerTileY - tilesY)
        let maxY = min(map.height - 1, centerTileY + tilesY)

        // Only iterate the border region, not the entire map
        for y in 0..<map.height {
            for x in 0..<map.width {
                if x < minX || x > maxX || y < minY || y > maxY {
                    if let node = fogNodes[y][x] {
                        node.removeFromParent()
                        fogNodes[y][x] = nil
                    }
                }
            }
        }
    }
}
