import Foundation
import SpriteKit

class GameMap {
    let width: Int
    let height: Int
    let tileSize: CGFloat
    var tiles: [[MapTile]]
    let mapNode: SKNode
    private var activeTilePositions: Set<Int> = Set<Int>()

    init(width: Int = 50, height: Int = 50, tileSize: CGFloat = 32) {
        self.width = width
        self.height = height
        self.tileSize = tileSize
        self.mapNode = SKNode()
        self.mapNode.name = "mapNode"

        // Initialize tiles
        self.tiles = (0..<height).map { y in
            (0..<width).map { x in
                MapTile(terrain: .grass, position: GridPosition(x: x, y: y))
            }
        }

        generateTerrain()
    }

    // MARK: - Terrain Generation

    private func generateTerrain() {
        // Seed random
        let seed = UInt64.random(in: 0...UInt64.max)
        var rng = SeededRNG(seed: seed)

        // Generate water bodies (lakes/rivers)
        generateWater(&rng)

        // Generate forests
        generateForests(&rng)

        // Generate resource deposits
        generateResources(&rng)

        // Generate sand near water
        generateSand()
    }

    private func generateWater(_ rng: inout SeededRNG) {
        // Create 1-2 lakes
        let lakeCount = Int.random(in: 1...2, using: &rng)
        for _ in 0..<lakeCount {
            let cx = Int.random(in: 12..<(width - 12), using: &rng)
            let cy = Int.random(in: 12..<(height - 12), using: &rng)
            let radiusX = Int.random(in: 3...6, using: &rng)
            let radiusY = Int.random(in: 2...5, using: &rng)

            for y in max(0, cy - radiusY)...min(height - 1, cy + radiusY) {
                for x in max(0, cx - radiusX)...min(width - 1, cx + radiusX) {
                    let dx = CGFloat(x - cx) / CGFloat(radiusX)
                    let dy = CGFloat(y - cy) / CGFloat(radiusY)
                    let dist = dx * dx + dy * dy
                    if dist < 1.0 {
                        tiles[y][x].terrain = dist < 0.5 ? .deepWater : .water
                    }
                }
            }
        }

        // Create a river
        if Bool.random(using: &rng) {
            var rx = Int.random(in: 0..<width, using: &rng)
            let riverWidth = Int.random(in: 2...3, using: &rng)
            for ry in 0..<height {
                rx += Int.random(in: -1...1, using: &rng)
                rx = max(2, min(width - 3, rx))
                for w in 0..<riverWidth {
                    let x = rx + w
                    if x >= 0 && x < width {
                        tiles[ry][x].terrain = .water
                    }
                }
            }
        }
    }

    private func generateForests(_ rng: inout SeededRNG) {
        let clumpCount = Int.random(in: 5...10, using: &rng)
        for _ in 0..<clumpCount {
            let cx = Int.random(in: 5..<(width - 5), using: &rng)
            let cy = Int.random(in: 5..<(height - 5), using: &rng)
            let radius = Int.random(in: 3...7, using: &rng)

            for y in max(0, cy - radius)...min(height - 1, cy + radius) {
                for x in max(0, cx - radius)...min(width - 1, cx + radius) {
                    let dist = GridPosition(x: x, y: y).distance(to: GridPosition(x: cx, y: cy))
                    if dist < CGFloat(radius) && tiles[y][x].terrain == .grass {
                        if CGFloat.random(in: 0...1, using: &rng) < 0.7 {
                            tiles[y][x].terrain = .forest
                            tiles[y][x].resourceRemaining = TerrainType.forest.resourceAmount
                        }
                    }
                }
            }
        }
    }

    private func generateResources(_ rng: inout SeededRNG) {
        // Gold deposits
        let goldCount = Int.random(in: 3...5, using: &rng)
        for _ in 0..<goldCount {
            let cx = Int.random(in: 5..<(width - 5), using: &rng)
            let cy = Int.random(in: 5..<(height - 5), using: &rng)
            let size = Int.random(in: 2...4, using: &rng)

            for y in max(0, cy - size)...min(height - 1, cy + size) {
                for x in max(0, cx - size)...min(width - 1, cx + size) {
                    let dist = GridPosition(x: x, y: y).distance(to: GridPosition(x: cx, y: cy))
                    if dist < CGFloat(size) && tiles[y][x].terrain == .grass {
                        if CGFloat.random(in: 0...1, using: &rng) < 0.5 {
                            tiles[y][x].terrain = .gold
                            tiles[y][x].resourceRemaining = TerrainType.gold.resourceAmount
                        }
                    }
                }
            }
        }

        // Stone deposits
        let stoneCount = Int.random(in: 3...5, using: &rng)
        for _ in 0..<stoneCount {
            let cx = Int.random(in: 5..<(width - 5), using: &rng)
            let cy = Int.random(in: 5..<(height - 5), using: &rng)
            let size = Int.random(in: 2...3, using: &rng)

            for y in max(0, cy - size)...min(height - 1, cy + size) {
                for x in max(0, cx - size)...min(width - 1, cx + size) {
                    let dist = GridPosition(x: x, y: y).distance(to: GridPosition(x: cx, y: cy))
                    if dist < CGFloat(size) && tiles[y][x].terrain == .grass {
                        if CGFloat.random(in: 0...1, using: &rng) < 0.5 {
                            tiles[y][x].terrain = .stone
                            tiles[y][x].resourceRemaining = TerrainType.stone.resourceAmount
                        }
                    }
                }
            }
        }

        // Berry bushes
        let berryCount = Int.random(in: 3...4, using: &rng)
        for _ in 0..<berryCount {
            let cx = Int.random(in: 5..<(width - 5), using: &rng)
            let cy = Int.random(in: 5..<(height - 5), using: &rng)

            for y in max(0, cy - 1)...min(height - 1, cy + 1) {
                for x in max(0, cx - 1)...min(width - 1, cx + 1) {
                    if tiles[y][x].terrain == .grass {
                        tiles[y][x].terrain = .berryBush
                        tiles[y][x].resourceRemaining = TerrainType.berryBush.resourceAmount
                    }
                }
            }
        }
    }

    private func generateSand() {
        for y in 0..<height {
            for x in 0..<width {
                if tiles[y][x].terrain == .grass {
                    // Check if adjacent to water
                    for neighbor in GridPosition(x: x, y: y).neighbors {
                        if isValid(neighbor) {
                            let t = tiles[neighbor.y][neighbor.x].terrain
                            if t == .water || t == .deepWater {
                                if CGFloat.random(in: 0...1) < 0.4 {
                                    tiles[y][x].terrain = .sand
                                }
                                break
                            }
                        }
                    }
                }
            }
        }
    }

    // MARK: - Rendering

    func renderVisibleTiles(cameraPosition: CGPoint, viewSize: CGSize) {
        let tilesX = Int(viewSize.width / tileSize) + 4
        let tilesY = Int(viewSize.height / tileSize) + 4

        let centerTileX = Int(cameraPosition.x / tileSize)
        let centerTileY = Int(cameraPosition.y / tileSize)

        let minX = max(0, centerTileX - tilesX / 2)
        let maxX = min(width - 1, centerTileX + tilesX / 2)
        let minY = max(0, centerTileY - tilesY / 2)
        let maxY = min(height - 1, centerTileY + tilesY / 2)

        for y in minY...maxY {
            for x in minX...maxX {
                let tile = tiles[y][x]
                if tile.node == nil {
                    let tileNode = createTileSprite(tile: tile, x: x, y: y)
                    tileNode.position = gridToWorld(GridPosition(x: x, y: y))
                    tileNode.zPosition = 0

                    mapNode.addChild(tileNode)
                    tile.node = tileNode
                    activeTilePositions.insert(y * width + x)
                }
            }
        }
    }

    private func createTileSprite(tile: MapTile, x: Int, y: Int) -> SKSpriteNode {
        let size = CGSize(width: tileSize, height: tileSize)
        // Use deterministic hash for consistent tile variation
        let hash = (x &* 73856093) ^ (y &* 19349663)

        let baseColor = tile.terrain.color
        // Subtle color variation per tile for natural look
        let variation = CGFloat((hash & 0xFF)) / 255.0 * 0.08 - 0.04
        var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
        baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
        let variedColor = SKColor(
            red: max(0, min(1, r + variation)),
            green: max(0, min(1, g + variation * 0.8)),
            blue: max(0, min(1, b + variation * 0.5)),
            alpha: a
        )

        let tileNode = SKSpriteNode(color: variedColor, size: size)

        // Add terrain decorations
        switch tile.terrain {
        case .grass:
            // Occasional grass tufts
            if hash % 5 == 0 {
                let tuft = SKShapeNode(rectOf: CGSize(width: 2, height: 4))
                tuft.fillColor = SKColor(red: 0.25, green: 0.5, blue: 0.15, alpha: 0.6)
                tuft.strokeColor = .clear
                tuft.position = CGPoint(x: CGFloat((hash >> 8) % 16) - 8, y: CGFloat((hash >> 12) % 16) - 8)
                tileNode.addChild(tuft)
            }

        case .forest:
            // Tree canopy circles
            let treeR: CGFloat = tileSize * 0.3
            let tree = SKShapeNode(circleOfRadius: treeR)
            tree.fillColor = SKColor(red: 0.1 + variation, green: 0.35 + CGFloat(hash % 10) / 100.0, blue: 0.08, alpha: 1.0)
            tree.strokeColor = SKColor(red: 0.05, green: 0.25, blue: 0.05, alpha: 0.8)
            tree.lineWidth = 1.0
            tree.position = CGPoint(x: CGFloat((hash >> 4) % 6) - 3, y: CGFloat((hash >> 8) % 6) - 3)
            tree.zPosition = 1
            tileNode.addChild(tree)
            // Small trunk
            let trunk = SKShapeNode(rectOf: CGSize(width: 3, height: 4))
            trunk.fillColor = SKColor(red: 0.35, green: 0.22, blue: 0.1, alpha: 1.0)
            trunk.strokeColor = .clear
            trunk.position = CGPoint(x: tree.position.x, y: tree.position.y - treeR * 0.6)
            tileNode.addChild(trunk)

        case .water:
            // Wave highlights
            if hash % 3 == 0 {
                let wave = SKShapeNode(rectOf: CGSize(width: 8, height: 1.5))
                wave.fillColor = SKColor(red: 0.4, green: 0.6, blue: 0.85, alpha: 0.4)
                wave.strokeColor = .clear
                wave.position = CGPoint(x: CGFloat((hash >> 4) % 14) - 7, y: CGFloat((hash >> 8) % 14) - 7)
                tileNode.addChild(wave)
            }

        case .deepWater:
            if hash % 4 == 0 {
                let wave = SKShapeNode(rectOf: CGSize(width: 10, height: 1.5))
                wave.fillColor = SKColor(red: 0.2, green: 0.35, blue: 0.65, alpha: 0.3)
                wave.strokeColor = .clear
                wave.position = CGPoint(x: CGFloat((hash >> 4) % 14) - 7, y: CGFloat((hash >> 8) % 14) - 7)
                tileNode.addChild(wave)
            }

        case .gold:
            // Gold nugget sparkle
            let nugget = SKShapeNode(rectOf: CGSize(width: 6, height: 5), cornerRadius: 2)
            nugget.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.15, alpha: 1.0)
            nugget.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.1, alpha: 1.0)
            nugget.lineWidth = 1
            nugget.position = CGPoint(x: CGFloat((hash >> 4) % 8) - 4, y: CGFloat((hash >> 8) % 8) - 4)
            nugget.zPosition = 1
            tileNode.addChild(nugget)
            // Sparkle dot
            let sparkle = SKShapeNode(circleOfRadius: 1.5)
            sparkle.fillColor = .white
            sparkle.strokeColor = .clear
            sparkle.position = CGPoint(x: nugget.position.x + 2, y: nugget.position.y + 2)
            sparkle.zPosition = 2
            sparkle.alpha = 0.7
            tileNode.addChild(sparkle)

        case .stone:
            // Rock shapes
            let rock = SKShapeNode(rectOf: CGSize(width: 8, height: 6), cornerRadius: 2)
            rock.fillColor = SKColor(red: 0.6, green: 0.58, blue: 0.55, alpha: 1.0)
            rock.strokeColor = SKColor(red: 0.4, green: 0.4, blue: 0.38, alpha: 0.8)
            rock.lineWidth = 1
            rock.position = CGPoint(x: CGFloat((hash >> 4) % 8) - 4, y: CGFloat((hash >> 8) % 8) - 4)
            rock.zPosition = 1
            tileNode.addChild(rock)

        case .berryBush:
            // Berry bush with berries
            let bush = SKShapeNode(circleOfRadius: tileSize * 0.25)
            bush.fillColor = SKColor(red: 0.2, green: 0.45, blue: 0.15, alpha: 1.0)
            bush.strokeColor = SKColor(red: 0.15, green: 0.3, blue: 0.1, alpha: 0.8)
            bush.lineWidth = 1
            bush.zPosition = 1
            tileNode.addChild(bush)
            // Berries
            for i in 0..<3 {
                let berry = SKShapeNode(circleOfRadius: 2)
                berry.fillColor = SKColor(red: 0.7, green: 0.1, blue: 0.2, alpha: 1.0)
                berry.strokeColor = .clear
                let angle = CGFloat(i) * 2.094 + CGFloat(hash % 10) * 0.1
                berry.position = CGPoint(x: cos(angle) * 4, y: sin(angle) * 4)
                berry.zPosition = 2
                tileNode.addChild(berry)
            }

        case .sand:
            // Sand speckles
            if hash % 3 == 0 {
                let dot = SKShapeNode(circleOfRadius: 1)
                dot.fillColor = SKColor(red: 0.82, green: 0.75, blue: 0.55, alpha: 0.5)
                dot.strokeColor = .clear
                dot.position = CGPoint(x: CGFloat((hash >> 4) % 14) - 7, y: CGFloat((hash >> 8) % 14) - 7)
                tileNode.addChild(dot)
            }

        case .farm:
            // Farm rows pattern
            for i in 0..<3 {
                let row = SKShapeNode(rectOf: CGSize(width: tileSize * 0.7, height: 1.5))
                row.fillColor = SKColor(red: 0.45, green: 0.38, blue: 0.12, alpha: 0.6)
                row.strokeColor = .clear
                row.position = CGPoint(x: 0, y: CGFloat(i - 1) * (tileSize * 0.25))
                tileNode.addChild(row)
            }
        }

        return tileNode
    }

    func removeFarTiles(cameraPosition: CGPoint, viewSize: CGSize) {
        let bufferTiles = 6
        let tilesX = Int(viewSize.width / tileSize) / 2 + bufferTiles
        let tilesY = Int(viewSize.height / tileSize) / 2 + bufferTiles
        let centerTileX = Int(cameraPosition.x / tileSize)
        let centerTileY = Int(cameraPosition.y / tileSize)

        var toRemove: [Int] = []
        for key in activeTilePositions {
            let ty = key / width
            let tx = key % width
            if abs(tx - centerTileX) > tilesX || abs(ty - centerTileY) > tilesY {
                tiles[ty][tx].node?.removeFromParent()
                tiles[ty][tx].node = nil
                toRemove.append(key)
            }
        }
        for key in toRemove {
            activeTilePositions.remove(key)
        }
    }

    // MARK: - Utilities

    func gridToWorld(_ pos: GridPosition) -> CGPoint {
        CGPoint(x: CGFloat(pos.x) * tileSize + tileSize / 2,
                y: CGFloat(pos.y) * tileSize + tileSize / 2)
    }

    func worldToGrid(_ point: CGPoint) -> GridPosition {
        GridPosition(x: Int(floor(point.x / tileSize)), y: Int(floor(point.y / tileSize)))
    }

    func isValid(_ pos: GridPosition) -> Bool {
        pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height
    }

    func isPassable(_ pos: GridPosition) -> Bool {
        guard isValid(pos) else { return false }
        let tile = tiles[pos.y][pos.x]
        return tile.terrain.isPassable && tile.building == nil
    }

    func isBuildable(_ pos: GridPosition) -> Bool {
        guard isValid(pos) else { return false }
        let tile = tiles[pos.y][pos.x]
        return tile.terrain.isBuildable && tile.building == nil
    }

    func canPlaceBuilding(type: BuildingType, at pos: GridPosition) -> Bool {
        let size = type.size
        for dy in 0..<size.height {
            for dx in 0..<size.width {
                let checkPos = GridPosition(x: pos.x + dx, y: pos.y + dy)
                if !isBuildable(checkPos) { return false }
            }
        }
        return true
    }

    func tile(at pos: GridPosition) -> MapTile? {
        guard isValid(pos) else { return nil }
        return tiles[pos.y][pos.x]
    }

    func findNearestResource(_ type: ResourceType, from pos: GridPosition, maxRange: Int = 20) -> GridPosition? {
        var bestPos: GridPosition?
        var bestDist: CGFloat = .infinity

        for dy in -maxRange...maxRange {
            for dx in -maxRange...maxRange {
                let checkPos = GridPosition(x: pos.x + dx, y: pos.y + dy)
                guard isValid(checkPos) else { continue }
                let tile = tiles[checkPos.y][checkPos.x]
                if tile.terrain.resourceType == type && tile.resourceRemaining > 0 {
                    let dist = pos.distance(to: checkPos)
                    if dist < bestDist {
                        bestDist = dist
                        bestPos = checkPos
                    }
                }
            }
        }
        return bestPos
    }

    func findNearestDropOff(for resourceType: ResourceType, ownerID: Int, from pos: GridPosition, buildings: [Building]) -> GridPosition? {
        var bestPos: GridPosition?
        var bestDist: CGFloat = .infinity

        for building in buildings {
            guard building.ownerID == ownerID && building.isConstructed else { continue }
            let isDropOff: Bool
            switch building.type {
            case .townCenter: isDropOff = true
            case .lumberCamp: isDropOff = (resourceType == .wood)
            case .miningCamp: isDropOff = (resourceType == .gold || resourceType == .stone)
            default: isDropOff = false
            }
            if isDropOff {
                let dist = pos.distance(to: building.gridPosition)
                if dist < bestDist {
                    bestDist = dist
                    bestPos = building.gridPosition
                }
            }
        }
        return bestPos
    }

    func clearStartingArea(center: GridPosition, radius: Int) {
        for dy in -radius...radius {
            for dx in -radius...radius {
                let pos = GridPosition(x: center.x + dx, y: center.y + dy)
                guard isValid(pos) else { continue }
                let dist = center.distance(to: pos)
                if dist < CGFloat(radius) {
                    let tile = tiles[pos.y][pos.x]
                    if tile.terrain != .grass && tile.terrain != .sand {
                        tile.terrain = .grass
                        tile.resourceRemaining = 0
                        if let node = tile.node {
                            node.removeFromParent()
                            tile.node = nil
                        }
                    }
                }
            }
        }
    }
}

// MARK: - Seeded RNG

struct SeededRNG: RandomNumberGenerator {
    var state: UInt64

    init(seed: UInt64) {
        state = seed
    }

    mutating func next() -> UInt64 {
        state &+= 0x9e3779b97f4a7c15
        var z = state
        z = (z ^ (z >> 30)) &* 0xbf58476d1ce4e5b9
        z = (z ^ (z >> 27)) &* 0x94d049bb133111eb
        return z ^ (z >> 31)
    }
}
