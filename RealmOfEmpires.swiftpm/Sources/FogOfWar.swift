import Foundation
import SpriteKit

class FogOfWar {
    let map: GameMap
    let sightRange: Int = GameConstants.baseSightRange
    var fogNodes: [[SKShapeNode?]]

    // Track last known unit positions to skip recalculation for stationary units
    private var lastUnitPositions: [Int: GridPosition] = [:]
    private var lastBuildingCount: Int = 0
    private var lastHasTownWatch: Bool = false
    // Track which tiles were revealed by stationary entities to avoid full reset
    private var needsFullRecalc: Bool = true

    init(map: GameMap) {
        self.map = map
        self.fogNodes = Array(repeating: Array(repeating: nil, count: map.width), count: map.height)
    }

    func update(player: Player) {
        let hasTownWatch = player.researchedTechs.contains(.townWatch)

        // Check if we need full recalculation
        let buildingCountChanged = player.buildings.count != lastBuildingCount
        let townWatchChanged = hasTownWatch != lastHasTownWatch

        // Determine which units moved
        var movedUnitIDs: Set<Int> = []
        var currentUnitIDs: Set<Int> = []
        for unit in player.units {
            currentUnitIDs.insert(unit.id)
            if let lastPos = lastUnitPositions[unit.id] {
                if lastPos != unit.gridPosition {
                    movedUnitIDs.insert(unit.id)
                }
            } else {
                // New unit, treat as moved
                movedUnitIDs.insert(unit.id)
            }
        }

        // Check for removed units
        let removedUnits = lastUnitPositions.keys.filter { !currentUnitIDs.contains($0) }

        // Force full recalc if buildings changed, units removed, or town watch researched
        if buildingCountChanged || townWatchChanged || !removedUnits.isEmpty || needsFullRecalc {
            // Full recalculation
            for y in 0..<map.height {
                for x in 0..<map.width {
                    map.tiles[y][x].isVisible = false
                }
            }

            for unit in player.units {
                var unitRange = sightRange
                if unit.type == .scout || unit.type == .mangudai { unitRange += GameConstants.scoutVisionBonus }
                else if unit.type == .lightCavalry { unitRange += GameConstants.cavalryVisionBonus }
                revealArea(around: unit.gridPosition, range: unitRange)
            }

            for building in player.buildings {
                var buildingRange = building.type.sightRange
                if hasTownWatch { buildingRange += GameConstants.townWatchBonus }
                revealArea(around: building.gridPosition, range: buildingRange)
            }

            needsFullRecalc = false
        } else if !movedUnitIDs.isEmpty {
            // Incremental: only reset visibility for tiles around moved units' old positions
            // then re-reveal everything (we must reset all visibility since we can't track
            // which tiles were revealed by which entity). But we only do full reset if units moved.
            for y in 0..<map.height {
                for x in 0..<map.width {
                    map.tiles[y][x].isVisible = false
                }
            }

            for unit in player.units {
                var unitRange = sightRange
                if unit.type == .scout || unit.type == .mangudai { unitRange += GameConstants.scoutVisionBonus }
                else if unit.type == .lightCavalry { unitRange += GameConstants.cavalryVisionBonus }
                revealArea(around: unit.gridPosition, range: unitRange)
            }

            for building in player.buildings {
                var buildingRange = building.type.sightRange
                if hasTownWatch { buildingRange += GameConstants.townWatchBonus }
                revealArea(around: building.gridPosition, range: buildingRange)
            }
        }
        // If no units moved and no structural changes, skip entirely (visibility stays same)

        // Update tracking state
        lastUnitPositions.removeAll(keepingCapacity: true)
        for unit in player.units {
            lastUnitPositions[unit.id] = unit.gridPosition
        }
        lastBuildingCount = player.buildings.count
        lastHasTownWatch = hasTownWatch
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
                    // Explored but not visible — dimmed with consistent fog overlay
                    let visNeighbors = visibleNeighborCount(x: x, y: y)

                    // Tile stays visible but dimmed
                    let tileAlpha: CGFloat = visNeighbors > 0
                        ? min(0.85, 0.6 + CGFloat(visNeighbors) * 0.04)
                        : 0.6

                    if let tileNode = tile.node, abs(tileNode.alpha - tileAlpha) > 0.03 {
                        tileNode.run(SKAction.fadeAlpha(to: tileAlpha, duration: fadeDuration), withKey: "fogFade")
                    }

                    // Fog overlay: single alpha value (no separate fill alpha)
                    let fogTargetAlpha: CGFloat = visNeighbors > 0
                        ? max(0.15, 0.4 - CGFloat(visNeighbors) * 0.04)
                        : 0.4

                    if let fogNode = fogNodes[y][x] {
                        if abs(fogNode.alpha - fogTargetAlpha) > 0.05 {
                            fogNode.run(SKAction.fadeAlpha(to: fogTargetAlpha, duration: fadeDuration), withKey: "fogFade")
                        }
                        fogNode.fillColor = SKColor.black
                    } else {
                        let fogNode = SKShapeNode(rectOf: CGSize(width: map.tileSize * 1.05, height: map.tileSize * 1.05))
                        fogNode.fillColor = SKColor.black
                        fogNode.strokeColor = .clear
                        fogNode.position = map.gridToWorld(GridPosition(x: x, y: y))
                        fogNode.zPosition = 50
                        fogNode.alpha = 0
                        map.mapNode.addChild(fogNode)
                        fogNode.run(SKAction.fadeAlpha(to: fogTargetAlpha, duration: fadeDuration), withKey: "fogFade")
                        fogNodes[y][x] = fogNode
                    }
                } else {
                    // Unexplored — fully black with soft edges at boundary
                    let expNeighbors = exploredNeighborCount(x: x, y: y)

                    if let tileNode = tile.node, tileNode.alpha > 0.05 {
                        tileNode.run(SKAction.fadeAlpha(to: 0.0, duration: fadeDuration), withKey: "fogFade")
                    }

                    // Unexplored tiles are fully opaque black; boundary tiles slightly softer
                    let fogTargetAlpha: CGFloat = expNeighbors > 0
                        ? max(0.7, 0.95 - CGFloat(expNeighbors) * 0.04)
                        : 1.0

                    if let fogNode = fogNodes[y][x] {
                        if abs(fogNode.alpha - fogTargetAlpha) > 0.05 {
                            fogNode.run(SKAction.fadeAlpha(to: fogTargetAlpha, duration: fadeDuration), withKey: "fogFade")
                        }
                        fogNode.fillColor = SKColor.black
                    } else {
                        let fogNode = SKShapeNode(rectOf: CGSize(width: map.tileSize * 1.05, height: map.tileSize * 1.05))
                        fogNode.fillColor = SKColor.black
                        fogNode.strokeColor = .clear
                        fogNode.position = map.gridToWorld(GridPosition(x: x, y: y))
                        fogNode.zPosition = 50
                        fogNode.alpha = fogTargetAlpha
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
