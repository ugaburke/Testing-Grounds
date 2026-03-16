import Foundation
import SpriteKit

class GameMap {
    let width: Int
    let height: Int
    let tileSize: CGFloat
    var tiles: [[MapTile]]
    let mapNode: SKNode

    init(width: Int = 80, height: Int = 80, tileSize: CGFloat = 32) {
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
        // Create 2-3 lakes
        let lakeCount = Int.random(in: 2...3, using: &rng)
        for _ in 0..<lakeCount {
            let cx = Int.random(in: 15..<(width - 15), using: &rng)
            let cy = Int.random(in: 15..<(height - 15), using: &rng)
            let radiusX = Int.random(in: 4...8, using: &rng)
            let radiusY = Int.random(in: 3...6, using: &rng)

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
        let clumpCount = Int.random(in: 8...15, using: &rng)
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
        let goldCount = Int.random(in: 5...8, using: &rng)
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
        let stoneCount = Int.random(in: 4...7, using: &rng)
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
        let berryCount = Int.random(in: 4...6, using: &rng)
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

        // Fish in deep water
        for y in 2..<(height-2) {
            for x in 2..<(width-2) {
                if tiles[y][x].terrain == .deepWater {
                    // Add fish resource to some deep water tiles
                    if CGFloat.random(in: 0...1, using: &rng) < 0.15 {
                        tiles[y][x].resourceRemaining = 500  // Fish amount
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
                    let node = SKShapeNode(rectOf: CGSize(width: tileSize, height: tileSize))
                    var fillColor = tile.terrain.color
                    // Subtle grass variation on ~1/4 of grass tiles
                    if tile.terrain == .grass && (x * 7 + y * 13) % 4 == 0 {
                        let variation = CGFloat((x * 31 + y * 47) % 100) / 1000.0 - 0.05
                        fillColor = fillColor.lighter(by: variation)
                    }
                    node.fillColor = fillColor
                    node.strokeColor = fillColor  // No grid lines
                    node.lineWidth = 0.5
                    node.position = gridToWorld(GridPosition(x: x, y: y))
                    node.zPosition = 0

                    // Add detail for resources
                    if tile.terrain == .forest {
                        let tree = SKShapeNode(circleOfRadius: tileSize * 0.3)
                        tree.fillColor = SKColor(red: 0.1, green: 0.35, blue: 0.08, alpha: 1.0)
                        tree.strokeColor = .clear
                        tree.position = CGPoint(x: 0, y: tileSize * 0.1)
                        node.addChild(tree)
                    } else if tile.terrain == .gold {
                        let nugget = SKShapeNode(rectOf: CGSize(width: tileSize * 0.4, height: tileSize * 0.3))
                        nugget.fillColor = SKColor(red: 0.9, green: 0.8, blue: 0.1, alpha: 1.0)
                        nugget.strokeColor = .clear
                        node.addChild(nugget)
                    } else if tile.terrain == .stone {
                        let rock = SKShapeNode(circleOfRadius: tileSize * 0.25)
                        rock.fillColor = SKColor(red: 0.65, green: 0.65, blue: 0.65, alpha: 1.0)
                        rock.strokeColor = .clear
                        node.addChild(rock)
                    } else if tile.terrain == .berryBush {
                        let bush = SKShapeNode(circleOfRadius: tileSize * 0.25)
                        bush.fillColor = SKColor(red: 0.6, green: 0.15, blue: 0.3, alpha: 1.0)
                        bush.strokeColor = .clear
                        node.addChild(bush)
                    }

                    // Set initial alpha based on fog state to prevent flash
                    if !tile.isExplored {
                        node.alpha = 0.0
                    } else if !tile.isVisible {
                        node.alpha = 0.65
                    }

                    mapNode.addChild(node)
                    tile.node = node
                }
            }
        }
    }

    func removeFarTiles(cameraPosition: CGPoint, viewSize: CGSize) {
        let bufferTiles = 6
        let tilesX = Int(viewSize.width / tileSize) / 2 + bufferTiles
        let tilesY = Int(viewSize.height / tileSize) / 2 + bufferTiles
        let centerTileX = Int(cameraPosition.x / tileSize)
        let centerTileY = Int(cameraPosition.y / tileSize)

        for y in 0..<height {
            for x in 0..<width {
                if abs(x - centerTileX) > tilesX || abs(y - centerTileY) > tilesY {
                    if let node = tiles[y][x].node {
                        node.removeFromParent()
                        tiles[y][x].node = nil
                    }
                }
            }
        }
    }

    // MARK: - Terrain Animations

    func animateWaterTiles(time: CGFloat, cameraPosition: CGPoint, viewSize: CGSize) {
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
                guard let node = tile.node else { continue }

                if tile.terrain == .water || tile.terrain == .deepWater {
                    // Oscillate wave highlight
                    let offset = CGFloat(x * 7 + y * 13)
                    let wave = sin(time * 1.5 + offset) * 0.15
                    let baseColor = tile.terrain.color
                    var r: CGFloat = 0, g: CGFloat = 0, b: CGFloat = 0, a: CGFloat = 0
                    baseColor.getRed(&r, green: &g, blue: &b, alpha: &a)
                    node.fillColor = SKColor(red: min(1, r + wave * 0.3),
                                             green: min(1, g + wave * 0.2),
                                             blue: min(1, b + wave),
                                             alpha: a)

                    // Move wave highlight child if exists
                    if node.childNode(withName: "waveHighlight") == nil {
                        let highlight = SKShapeNode(rectOf: CGSize(width: tileSize * 0.4, height: 2))
                        highlight.fillColor = SKColor.white.withAlphaComponent(0.2)
                        highlight.strokeColor = .clear
                        highlight.name = "waveHighlight"
                        highlight.zPosition = 0.1
                        node.addChild(highlight)

                        // Second wave offset by half phase
                        let highlight2 = SKShapeNode(rectOf: CGSize(width: tileSize * 0.3, height: 1.5))
                        highlight2.fillColor = SKColor.white.withAlphaComponent(0.15)
                        highlight2.strokeColor = .clear
                        highlight2.name = "waveHighlight2"
                        highlight2.zPosition = 0.1
                        node.addChild(highlight2)
                    }
                    if let highlight = node.childNode(withName: "waveHighlight") {
                        let waveX = sin(time * 2.0 + offset) * tileSize * 0.2
                        let waveY = cos(time * 1.3 + offset) * tileSize * 0.15
                        highlight.position = CGPoint(x: waveX, y: waveY)
                        let alpha = 0.1 + 0.25 * (0.5 + 0.5 * sin(time * 1.5 + offset))
                        (highlight as? SKShapeNode)?.fillColor = SKColor.white.withAlphaComponent(alpha)
                    }
                    if let highlight2 = node.childNode(withName: "waveHighlight2") {
                        let waveX2 = sin(time * 2.0 + offset + .pi) * tileSize * 0.15
                        let waveY2 = cos(time * 1.3 + offset + .pi) * tileSize * 0.1
                        highlight2.position = CGPoint(x: waveX2, y: waveY2)
                    }
                } else if tile.terrain == .forest {
                    // Tree swaying
                    if let canopy = node.children.first {
                        let phase = CGFloat(x * 17 + y * 23)
                        let sway = sin(time * 0.7 + phase) * 1.5
                        canopy.position.x = sway
                    }
                }
            }
        }
    }

    func addTerrainBlending(cameraPosition: CGPoint, viewSize: CGSize) {
        let tilesX = Int(viewSize.width / tileSize) + 4
        let tilesY = Int(viewSize.height / tileSize) + 4
        let centerTileX = Int(cameraPosition.x / tileSize)
        let centerTileY = Int(cameraPosition.y / tileSize)
        let minX = max(0, centerTileX - tilesX / 2)
        let maxX = min(width - 1, centerTileX + tilesX / 2)
        let minY = max(0, centerTileY - tilesY / 2)
        let maxY = min(height - 1, centerTileY + tilesY / 2)

        let blendPairs: Set<String> = ["grass-sand", "grass-water", "sand-water", "grass-forest",
                                         "sand-deepWater", "grass-deepWater"]

        for y in minY...maxY {
            for x in minX...maxX {
                let tile = tiles[y][x]
                guard let node = tile.node else { continue }
                guard node.childNode(withName: "blend") == nil else { continue }

                let terrain = tile.terrain
                // Check each edge neighbor
                let edgeNeighbors: [(dx: Int, dy: Int, offsetX: CGFloat, offsetY: CGFloat)] = [
                    (1, 0, tileSize * 0.35, 0),
                    (-1, 0, -tileSize * 0.35, 0),
                    (0, 1, 0, tileSize * 0.35),
                    (0, -1, 0, -tileSize * 0.35),
                ]

                for neighbor in edgeNeighbors {
                    let nx = x + neighbor.dx
                    let ny = y + neighbor.dy
                    guard nx >= 0 && nx < width && ny >= 0 && ny < height else { continue }
                    let neighborTerrain = tiles[ny][nx].terrain
                    if neighborTerrain == terrain { continue }

                    let key1 = "\(terrain)-\(neighborTerrain)"
                    let key2 = "\(neighborTerrain)-\(terrain)"
                    guard blendPairs.contains(key1) || blendPairs.contains(key2) else { continue }

                    let isHorizontal = neighbor.dy == 0
                    let blendSize = isHorizontal ?
                        CGSize(width: tileSize * 0.3, height: tileSize) :
                        CGSize(width: tileSize, height: tileSize * 0.3)

                    let blend = SKShapeNode(rectOf: blendSize)
                    blend.fillColor = neighborTerrain.color.withAlphaComponent(0.25)
                    blend.strokeColor = .clear
                    blend.position = CGPoint(x: neighbor.offsetX, y: neighbor.offsetY)
                    blend.name = "blend"
                    blend.zPosition = 0.05
                    node.addChild(blend)
                }
            }
        }
    }

    // MARK: - Utilities

    func gridToWorld(_ pos: GridPosition) -> CGPoint {
        CGPoint(x: CGFloat(pos.x) * tileSize + tileSize / 2,
                y: CGFloat(pos.y) * tileSize + tileSize / 2)
    }

    func worldToGrid(_ point: CGPoint) -> GridPosition {
        GridPosition(x: Int(point.x / tileSize), y: Int(point.y / tileSize))
    }

    func isValid(_ pos: GridPosition) -> Bool {
        pos.x >= 0 && pos.x < width && pos.y >= 0 && pos.y < height
    }

    func isPassable(_ pos: GridPosition) -> Bool {
        guard isValid(pos) else { return false }
        let tile = tiles[pos.y][pos.x]
        return tile.terrain.isPassable && (tile.building == nil || tile.building?.type == .gate)
    }

    func isBuildable(_ pos: GridPosition) -> Bool {
        guard isValid(pos) else { return false }
        let tile = tiles[pos.y][pos.x]
        return tile.terrain.isBuildable && tile.building == nil
    }

    func canPlaceBuilding(type: BuildingType, at pos: GridPosition) -> Bool {
        let size = type.size

        if type == .dock {
            // Dock must be on land adjacent to water
            var hasWaterNeighbor = false
            for dy in 0..<size.height {
                for dx in 0..<size.width {
                    let checkPos = GridPosition(x: pos.x + dx, y: pos.y + dy)
                    if !isBuildable(checkPos) { return false }
                    // Check neighbors for water
                    for neighbor in checkPos.neighbors {
                        if isValid(neighbor) {
                            let t = tiles[neighbor.y][neighbor.x].terrain
                            if t == .water || t == .deepWater {
                                hasWaterNeighbor = true
                            }
                        }
                    }
                }
            }
            return hasWaterNeighbor
        }

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
            case .dock: isDropOff = (resourceType == .food)
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
