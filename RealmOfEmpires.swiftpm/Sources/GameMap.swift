import Foundation
import SpriteKit

class GameMap {
    let width: Int
    let height: Int
    let tileSize: CGFloat
    var tiles: [[MapTile]]
    let mapNode: SKNode
    var relics: [Relic] = []
    var deerHerds: [DeerHerd] = []
    let mapType: MapType

    init(width: Int = 80, height: Int = 80, tileSize: CGFloat = 32, mapType: MapType = .standard) {
        self.width = width
        self.height = height
        self.tileSize = tileSize
        self.mapType = mapType
        self.mapNode = SKNode()
        self.mapNode.name = "mapNode"

        // Initialize tiles
        self.tiles = (0..<height).map { y in
            (0..<width).map { x in
                MapTile(terrain: .grass, position: GridPosition(x: x, y: y))
            }
        }

        generateTerrain()
        generateRelics()
        generateDeerHerds()
    }

    // MARK: - Terrain Generation

    private func generateTerrain() {
        // Seed random
        let seed = UInt64.random(in: 0...UInt64.max)
        var rng = SeededRNG(seed: seed)

        switch mapType {
        case .standard:
            generateStandardTerrain(&rng)
        case .islands:
            generateIslandsTerrain(&rng)
        case .rivers:
            generateRiversTerrain(&rng)
        case .arena:
            generateArenaTerrain(&rng)
        case .blackForest:
            generateBlackForestTerrain(&rng)
        case .goldRush:
            generateGoldRushTerrain(&rng)
        }
    }

    // MARK: - Standard Map

    private func generateStandardTerrain(_ rng: inout SeededRNG) {
        generateWater(&rng)
        generateForests(&rng)
        generateResources(&rng)
        generateSand()
    }

    // MARK: - Islands Map

    private func generateIslandsTerrain(_ rng: inout SeededRNG) {
        let cx = width / 2
        let cy = height / 2

        // Fill ~40% of map with water in a large central body
        let waterRadiusX = CGFloat(width) * 0.35
        let waterRadiusY = CGFloat(height) * 0.35

        for y in 0..<height {
            for x in 0..<width {
                let dx = CGFloat(x - cx) / waterRadiusX
                let dy = CGFloat(y - cy) / waterRadiusY
                let dist = dx * dx + dy * dy
                // Create water in central area with noise for irregular edges
                let noise = CGFloat.random(in: -0.15...0.15, using: &rng)
                if dist < (0.8 + noise) {
                    tiles[y][x].terrain = dist < (0.5 + noise) ? .deepWater : .water
                }
            }
        }

        // Ensure corners are land "islands" - clear land areas in corners for players
        let islandRadius = min(width, height) / 5
        let corners = [
            GridPosition(x: islandRadius, y: islandRadius),
            GridPosition(x: width - islandRadius - 1, y: height - islandRadius - 1),
            GridPosition(x: islandRadius, y: height - islandRadius - 1),
            GridPosition(x: width - islandRadius - 1, y: islandRadius)
        ]

        for corner in corners {
            for dy in -islandRadius...islandRadius {
                for dx in -islandRadius...islandRadius {
                    let px = corner.x + dx
                    let py = corner.y + dy
                    guard px >= 0 && px < width && py >= 0 && py < height else { continue }
                    let dist = sqrt(CGFloat(dx * dx + dy * dy))
                    if dist < CGFloat(islandRadius) {
                        tiles[py][px].terrain = .grass
                    }
                }
            }
        }

        // Add some scattered small islands in the water
        let smallIslandCount = Int.random(in: 2...4, using: &rng)
        for _ in 0..<smallIslandCount {
            let ix = Int.random(in: width / 4..<(width * 3 / 4), using: &rng)
            let iy = Int.random(in: height / 4..<(height * 3 / 4), using: &rng)
            let r = Int.random(in: 2...4, using: &rng)
            for dy in -r...r {
                for dx in -r...r {
                    let px = ix + dx
                    let py = iy + dy
                    guard px >= 0 && px < width && py >= 0 && py < height else { continue }
                    if dx * dx + dy * dy < r * r {
                        tiles[py][px].terrain = .grass
                    }
                }
            }
        }

        generateForests(&rng)
        generateResources(&rng)
        generateSand()
    }

    // MARK: - Rivers Map

    private func generateRiversTerrain(_ rng: inout SeededRNG) {
        let riverWidth = 3
        let crossingWidth = 3

        // Horizontal river (with wandering)
        let midY = height / 2
        var ry = midY
        for x in 0..<width {
            ry += Int.random(in: -1...1, using: &rng)
            ry = max(riverWidth, min(height - riverWidth - 1, ry))
            for w in -riverWidth/2...riverWidth/2 {
                let y = ry + w
                if y >= 0 && y < height {
                    tiles[y][x].terrain = .water
                }
            }
        }

        // Vertical river (with wandering)
        let midX = width / 2
        var rx = midX
        for y in 0..<height {
            rx += Int.random(in: -1...1, using: &rng)
            rx = max(riverWidth, min(width - riverWidth - 1, rx))
            for w in -riverWidth/2...riverWidth/2 {
                let x = rx + w
                if x >= 0 && x < width {
                    tiles[y][x].terrain = .water
                }
            }
        }

        // Add shallow crossing points (sand bridges) at ~1/4 and ~3/4 of each river
        let hCrossings = [width / 4, width * 3 / 4]
        for cx in hCrossings {
            for dx in -crossingWidth...crossingWidth {
                let x = cx + dx
                guard x >= 0 && x < width else { continue }
                for y in 0..<height {
                    if tiles[y][x].terrain == .water {
                        tiles[y][x].terrain = .sand
                    }
                }
            }
        }

        let vCrossings = [height / 4, height * 3 / 4]
        for cy in vCrossings {
            for dy in -crossingWidth...crossingWidth {
                let y = cy + dy
                guard y >= 0 && y < height else { continue }
                for x in 0..<width {
                    if tiles[y][x].terrain == .water {
                        tiles[y][x].terrain = .sand
                    }
                }
            }
        }

        generateForests(&rng)
        generateResources(&rng)
        generateSand()
    }

    // MARK: - Arena Map

    private func generateArenaTerrain(_ rng: inout SeededRNG) {
        // Standard base terrain
        generateWater(&rng)
        generateForests(&rng)
        generateResources(&rng)
        generateSand()

        // Generate stone walls in a circle around each player starting position
        let wallRadius = 10
        let startPositions = [
            GridPosition(x: 15, y: 15),
            GridPosition(x: width - 16, y: height - 16)
        ]

        for center in startPositions {
            // Clear inside the arena
            for dy in -wallRadius...wallRadius {
                for dx in -wallRadius...wallRadius {
                    let px = center.x + dx
                    let py = center.y + dy
                    guard px >= 0 && px < width && py >= 0 && py < height else { continue }
                    let dist = sqrt(CGFloat(dx * dx + dy * dy))
                    if dist < CGFloat(wallRadius - 1) {
                        tiles[py][px].terrain = .grass
                        tiles[py][px].resourceRemaining = 0
                    }
                }
            }

            // Place stone walls in a ring
            for dy in -(wallRadius + 1)...(wallRadius + 1) {
                for dx in -(wallRadius + 1)...(wallRadius + 1) {
                    let px = center.x + dx
                    let py = center.y + dy
                    guard px >= 0 && px < width && py >= 0 && py < height else { continue }
                    let dist = sqrt(CGFloat(dx * dx + dy * dy))
                    if dist >= CGFloat(wallRadius - 1) && dist < CGFloat(wallRadius + 1) {
                        tiles[py][px].terrain = .stone
                        tiles[py][px].resourceRemaining = TerrainType.stone.resourceAmount
                    }
                }
            }

            // Create 2 gaps (breakout points) in the wall - one towards center, one perpendicular
            let gapWidth = 2
            let angles: [CGFloat] = [
                atan2(CGFloat(height / 2 - center.y), CGFloat(width / 2 - center.x)),
                atan2(CGFloat(height / 2 - center.y), CGFloat(width / 2 - center.x)) + .pi / 2
            ]
            for angle in angles {
                for r in (wallRadius - 1)...(wallRadius + 1) {
                    for g in -gapWidth...gapWidth {
                        let gx = center.x + Int(CGFloat(r) * cos(angle) + CGFloat(g) * sin(angle))
                        let gy = center.y + Int(CGFloat(r) * sin(angle) - CGFloat(g) * cos(angle))
                        guard gx >= 0 && gx < width && gy >= 0 && gy < height else { continue }
                        if tiles[gy][gx].terrain == .stone {
                            tiles[gy][gx].terrain = .grass
                            tiles[gy][gx].resourceRemaining = 0
                        }
                    }
                }
            }
        }
    }

    // MARK: - Black Forest Map

    private func generateBlackForestTerrain(_ rng: inout SeededRNG) {
        // Fill ~70% with forest
        for y in 0..<height {
            for x in 0..<width {
                if CGFloat.random(in: 0...1, using: &rng) < 0.70 {
                    tiles[y][x].terrain = .forest
                    tiles[y][x].resourceRemaining = TerrainType.forest.resourceAmount
                }
            }
        }

        // Carve clear areas around player starting positions
        let clearRadius = 8
        let startPositions = [
            GridPosition(x: 15, y: 15),
            GridPosition(x: width - 16, y: height - 16)
        ]

        for center in startPositions {
            for dy in -clearRadius...clearRadius {
                for dx in -clearRadius...clearRadius {
                    let px = center.x + dx
                    let py = center.y + dy
                    guard px >= 0 && px < width && py >= 0 && py < height else { continue }
                    let dist = sqrt(CGFloat(dx * dx + dy * dy))
                    if dist < CGFloat(clearRadius) {
                        tiles[py][px].terrain = .grass
                        tiles[py][px].resourceRemaining = 0
                    }
                }
            }
        }

        // Carve winding paths between player areas using a random walk
        let pathWidth = 2
        var px = startPositions[0].x
        var py = startPositions[0].y
        let targetX = startPositions[1].x
        let targetY = startPositions[1].y

        while abs(px - targetX) > 3 || abs(py - targetY) > 3 {
            // Move generally towards target with randomness
            let dx = targetX - px
            let dy = targetY - py

            if Int.random(in: 0...2, using: &rng) < 2 {
                // Move towards target
                if abs(dx) > abs(dy) {
                    px += dx > 0 ? 1 : -1
                } else {
                    py += dy > 0 ? 1 : -1
                }
            } else {
                // Random sideways movement for winding effect
                if Bool.random(using: &rng) {
                    px += Int.random(in: -1...1, using: &rng)
                } else {
                    py += Int.random(in: -1...1, using: &rng)
                }
            }

            px = max(1, min(width - 2, px))
            py = max(1, min(height - 2, py))

            // Clear path area
            for pdy in -pathWidth...pathWidth {
                for pdx in -pathWidth...pathWidth {
                    let cx = px + pdx
                    let cy = py + pdy
                    if cx >= 0 && cx < width && cy >= 0 && cy < height {
                        if tiles[cy][cx].terrain == .forest {
                            tiles[cy][cx].terrain = .grass
                            tiles[cy][cx].resourceRemaining = 0
                        }
                    }
                }
            }
        }

        // Carve a second winding path for variety
        px = startPositions[0].x
        py = startPositions[0].y + 10

        while abs(px - targetX) > 3 || abs(py - targetY + 10) > 3 {
            let dx = targetX - px
            let dy = (targetY - 10) - py

            if Int.random(in: 0...2, using: &rng) < 2 {
                if abs(dx) > abs(dy) {
                    px += dx > 0 ? 1 : -1
                } else {
                    py += dy > 0 ? 1 : -1
                }
            } else {
                if Bool.random(using: &rng) {
                    px += Int.random(in: -1...1, using: &rng)
                } else {
                    py += Int.random(in: -1...1, using: &rng)
                }
            }

            px = max(1, min(width - 2, px))
            py = max(1, min(height - 2, py))

            for pdy in -pathWidth...pathWidth {
                for pdx in -pathWidth...pathWidth {
                    let cx = px + pdx
                    let cy = py + pdy
                    if cx >= 0 && cx < width && cy >= 0 && cy < height {
                        if tiles[cy][cx].terrain == .forest {
                            tiles[cy][cx].terrain = .grass
                            tiles[cy][cx].resourceRemaining = 0
                        }
                    }
                }
            }
        }

        // Add some water bodies
        let lakeCount = Int.random(in: 1...2, using: &rng)
        for _ in 0..<lakeCount {
            let lx = Int.random(in: 20..<(width - 20), using: &rng)
            let ly = Int.random(in: 20..<(height - 20), using: &rng)
            let lr = Int.random(in: 3...5, using: &rng)
            for dy in -lr...lr {
                for dx in -lr...lr {
                    let cx = lx + dx
                    let cy = ly + dy
                    guard cx >= 0 && cx < width && cy >= 0 && cy < height else { continue }
                    if dx * dx + dy * dy < lr * lr {
                        tiles[cy][cx].terrain = .water
                        tiles[cy][cx].resourceRemaining = 0
                    }
                }
            }
        }

        generateResources(&rng)
        generateSand()
    }

    // MARK: - Gold Rush Map

    private func generateGoldRushTerrain(_ rng: inout SeededRNG) {
        // Standard water and forests
        generateWater(&rng)
        generateForests(&rng)

        // Reduced gold near edges (player starting areas)
        let edgeGoldCount = Int.random(in: 1...2, using: &rng)
        for _ in 0..<edgeGoldCount {
            let inCorner = Bool.random(using: &rng)
            let cx: Int
            let cy: Int
            if inCorner {
                cx = Int.random(in: 5...15, using: &rng)
                cy = Int.random(in: 5...15, using: &rng)
            } else {
                cx = Int.random(in: (width - 16)..<(width - 5), using: &rng)
                cy = Int.random(in: (height - 16)..<(height - 5), using: &rng)
            }
            let size = 1
            for y in max(0, cy - size)...min(height - 1, cy + size) {
                for x in max(0, cx - size)...min(width - 1, cx + size) {
                    if tiles[y][x].terrain == .grass {
                        tiles[y][x].terrain = .gold
                        tiles[y][x].resourceRemaining = TerrainType.gold.resourceAmount
                    }
                }
            }
        }

        // Massive gold deposits in center
        let centerX = width / 2
        let centerY = height / 2
        let centerGoldRadius = min(width, height) / 8

        for dy in -centerGoldRadius...centerGoldRadius {
            for dx in -centerGoldRadius...centerGoldRadius {
                let px = centerX + dx
                let py = centerY + dy
                guard px >= 0 && px < width && py >= 0 && py < height else { continue }
                let dist = sqrt(CGFloat(dx * dx + dy * dy))
                if dist < CGFloat(centerGoldRadius) && tiles[py][px].terrain == .grass {
                    if CGFloat.random(in: 0...1, using: &rng) < 0.6 {
                        tiles[py][px].terrain = .gold
                        tiles[py][px].resourceRemaining = TerrainType.gold.resourceAmount * 2
                    }
                }
            }
        }

        // Normal stone deposits
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

    private func generateRelics() {
        // Place 3-5 relics on the map in random passable locations
        let relicCount = Int.random(in: 3...5)
        for _ in 0..<relicCount {
            for _ in 0..<50 {  // Max attempts
                let x = Int.random(in: 10..<(width - 10))
                let y = Int.random(in: 10..<(height - 10))
                let pos = GridPosition(x: x, y: y)
                if tiles[y][x].terrain == .grass && tiles[y][x].building == nil {
                    let relic = Relic(position: pos)
                    relics.append(relic)
                    break
                }
            }
        }
    }

    private func generateDeerHerds() {
        let herdCount = Int.random(in: 3...5)
        for _ in 0..<herdCount {
            for _ in 0..<50 {  // Max attempts
                let x = Int.random(in: 15..<(width - 15))
                let y = Int.random(in: 15..<(height - 15))
                let pos = GridPosition(x: x, y: y)
                if tiles[y][x].terrain == .grass && tiles[y][x].building == nil {
                    // Ensure away from typical player starts
                    let distFromP1 = pos.distance(to: GridPosition(x: 12, y: 12))
                    let distFromP2 = pos.distance(to: GridPosition(x: width - 15, y: height - 15))
                    if distFromP1 > 15 && distFromP2 > 15 {
                        let herd = DeerHerd(position: pos)
                        deerHerds.append(herd)
                        break
                    }
                }
            }
        }
    }

    func isWater(_ pos: GridPosition) -> Bool {
        guard isValid(pos) else { return false }
        let terrain = tiles[pos.y][pos.x].terrain
        return terrain == .water || terrain == .deepWater
    }

    func canPlaceFishTrap(at pos: GridPosition) -> Bool {
        guard isValid(pos) else { return false }
        return isWater(pos) && tiles[pos.y][pos.x].building == nil
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
                    // Enhanced grass variation - 3 tiers based on deterministic hash
                    if tile.terrain == .grass {
                        let grassHash = (x * 31 + y * 47) % 100
                        if grassHash < 25 {
                            // Dark lush grass patches
                            fillColor = fillColor.lighter(by: -0.06)
                        } else if grassHash >= 75 {
                            // Lighter sun-bleached patches
                            fillColor = fillColor.lighter(by: 0.05)
                        }
                        // Grass tufts on ~30% of grass tiles
                        if grassHash % 10 < 3 {
                            let tuftSeed = (x * 53 + y * 71)
                            let tuftCount = 2 + (tuftSeed % 2) // 2 or 3 blades
                            for i in 0..<tuftCount {
                                let bladePath = CGMutablePath()
                                let bx = CGFloat((tuftSeed &* (i + 1) &* 37) % 20) - 10.0
                                let by = CGFloat((tuftSeed &* (i + 1) &* 41) % 14) - 7.0
                                let bladeH = CGFloat(2 + ((tuftSeed &* (i + 1)) % 3)) // 2-4px
                                bladePath.move(to: CGPoint(x: bx, y: by))
                                bladePath.addLine(to: CGPoint(x: bx + CGFloat(i) * 0.5 - 0.5, y: by + bladeH))
                                let tuft = SKShapeNode(path: bladePath)
                                let greenVar = CGFloat((tuftSeed &* (i + 1)) % 30) / 100.0
                                tuft.strokeColor = SKColor(red: 0.15 + greenVar, green: 0.4 + greenVar, blue: 0.1, alpha: 0.7)
                                tuft.lineWidth = 0.5
                                tuft.name = "grassTuft"
                                tuft.zPosition = 0.05
                                node.addChild(tuft)
                            }
                        }
                    }
                    node.fillColor = fillColor
                    node.strokeColor = fillColor  // No grid lines
                    node.lineWidth = 0.5
                    node.position = gridToWorld(GridPosition(x: x, y: y))
                    node.zPosition = 0

                    // Add detail for resources
                    if tile.terrain == .forest {
                        let treeHash = (x * 31 + y * 47) % 100
                        // Size variation: some trees 15% bigger, some 10% smaller
                        let sizeScale: CGFloat = treeHash < 20 ? 1.15 : (treeHash > 80 ? 0.90 : 1.0)
                        // Hue variation per tree
                        let hueShift = CGFloat(treeHash % 20) / 100.0 - 0.10

                        // Ground shadow
                        let shadow = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.35 * sizeScale, height: tileSize * 0.15 * sizeScale))
                        shadow.fillColor = SKColor(red: 0, green: 0, blue: 0, alpha: 0.2)
                        shadow.strokeColor = .clear
                        shadow.position = CGPoint(x: tileSize * 0.02, y: -tileSize * 0.15)
                        shadow.zPosition = 0.05
                        shadow.name = "treeShadow"
                        node.addChild(shadow)

                        // Trunk - slightly wider at base (trapezoidal)
                        let trunkPath = CGMutablePath()
                        let trunkW: CGFloat = tileSize * 0.08 * sizeScale
                        let trunkH: CGFloat = tileSize * 0.25 * sizeScale
                        trunkPath.move(to: CGPoint(x: -trunkW * 0.7, y: -trunkH * 0.5))
                        trunkPath.addLine(to: CGPoint(x: trunkW * 0.7, y: -trunkH * 0.5))
                        trunkPath.addLine(to: CGPoint(x: trunkW * 0.4, y: trunkH * 0.5))
                        trunkPath.addLine(to: CGPoint(x: -trunkW * 0.4, y: trunkH * 0.5))
                        trunkPath.closeSubpath()
                        let trunk = SKShapeNode(path: trunkPath)
                        trunk.fillColor = SKColor(red: 0.4, green: 0.28, blue: 0.12, alpha: 1.0)
                        trunk.strokeColor = .clear
                        trunk.position = CGPoint(x: 0, y: -tileSize * 0.05)
                        trunk.zPosition = 0.1
                        trunk.name = "trunk"
                        node.addChild(trunk)

                        // Canopy layer 1 (darkest, back)
                        let canopyBase = SKShapeNode(circleOfRadius: tileSize * 0.32 * sizeScale)
                        canopyBase.fillColor = SKColor(red: max(0, 0.06 + hueShift * 0.3), green: min(1, 0.25 + hueShift), blue: 0.05, alpha: 1.0)
                        canopyBase.strokeColor = .clear
                        canopyBase.position = CGPoint(x: 0, y: tileSize * 0.10)
                        canopyBase.zPosition = 0.2
                        canopyBase.name = "canopy1"
                        node.addChild(canopyBase)

                        // Canopy layer 2 (medium)
                        let canopyMid = SKShapeNode(circleOfRadius: tileSize * 0.26 * sizeScale)
                        canopyMid.fillColor = SKColor(red: max(0, 0.10 + hueShift * 0.3), green: min(1, 0.35 + hueShift), blue: 0.08, alpha: 1.0)
                        canopyMid.strokeColor = .clear
                        canopyMid.position = CGPoint(x: 0, y: tileSize * 0.17)
                        canopyMid.zPosition = 0.3
                        canopyMid.name = "canopy2"
                        node.addChild(canopyMid)

                        // Canopy layer 3 (lightest, top)
                        let canopyTop = SKShapeNode(circleOfRadius: tileSize * 0.18 * sizeScale)
                        canopyTop.fillColor = SKColor(red: max(0, 0.15 + hueShift * 0.3), green: min(1, 0.45 + hueShift), blue: 0.12, alpha: 1.0)
                        canopyTop.strokeColor = .clear
                        canopyTop.position = CGPoint(x: 0, y: tileSize * 0.24)
                        canopyTop.zPosition = 0.35
                        canopyTop.name = "canopy3"
                        node.addChild(canopyTop)

                        // Highlight spot
                        let highlight = SKShapeNode(circleOfRadius: tileSize * 0.08 * sizeScale)
                        highlight.fillColor = SKColor(red: max(0, 0.25 + hueShift * 0.3), green: min(1, 0.55 + hueShift), blue: 0.18, alpha: 0.5)
                        highlight.strokeColor = .clear
                        highlight.position = CGPoint(x: -tileSize * 0.06, y: tileSize * 0.28)
                        highlight.zPosition = 0.4
                        highlight.name = "treeHighlight"
                        node.addChild(highlight)
                    } else if tile.terrain == .gold {
                        // Gold ore pile (multiple nuggets)
                        let goldHash = (x * 31 + y * 47) % 10
                        let baseNugget = SKShapeNode(rectOf: CGSize(width: tileSize * 0.35, height: tileSize * 0.25), cornerRadius: tileSize * 0.05)
                        baseNugget.fillColor = SKColor(red: 0.85, green: 0.7, blue: 0.1, alpha: 1.0)
                        baseNugget.strokeColor = SKColor(red: 0.7, green: 0.55, blue: 0.05, alpha: 1.0)
                        baseNugget.lineWidth = 1
                        baseNugget.position = CGPoint(x: 0, y: -tileSize * 0.05)
                        baseNugget.zPosition = 0.1
                        baseNugget.name = "goldBase"
                        node.addChild(baseNugget)
                        // Middle nugget
                        let topNugget = SKShapeNode(rectOf: CGSize(width: tileSize * 0.2, height: tileSize * 0.15), cornerRadius: tileSize * 0.03)
                        topNugget.fillColor = SKColor(red: 0.95, green: 0.85, blue: 0.15, alpha: 1.0)
                        topNugget.strokeColor = SKColor(red: 0.75, green: 0.6, blue: 0.05, alpha: 1.0)
                        topNugget.lineWidth = 0.5
                        topNugget.position = CGPoint(x: CGFloat(goldHash % 3) * 0.5 - 0.5, y: tileSize * 0.1)
                        topNugget.zPosition = 0.2
                        topNugget.name = "goldMid"
                        node.addChild(topNugget)
                        // Small top nugget for extra pile depth
                        let smallNugget = SKShapeNode(rectOf: CGSize(width: tileSize * 0.12, height: tileSize * 0.09), cornerRadius: tileSize * 0.02)
                        smallNugget.fillColor = SKColor(red: 1.0, green: 0.9, blue: 0.25, alpha: 1.0)
                        smallNugget.strokeColor = SKColor(red: 0.8, green: 0.65, blue: 0.1, alpha: 1.0)
                        smallNugget.lineWidth = 0.5
                        smallNugget.position = CGPoint(x: CGFloat(goldHash % 5) * 0.4 - 0.8, y: tileSize * 0.18)
                        smallNugget.zPosition = 0.25
                        smallNugget.name = "goldSmall"
                        node.addChild(smallNugget)
                        // Sparkle (animated via goldSparkle name)
                        let sparkle = SKShapeNode(circleOfRadius: tileSize * 0.04)
                        sparkle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: 0.7)
                        sparkle.strokeColor = .clear
                        sparkle.position = CGPoint(x: tileSize * 0.08, y: tileSize * 0.12)
                        sparkle.zPosition = 0.3
                        sparkle.name = "goldSparkle"
                        node.addChild(sparkle)
                    } else if tile.terrain == .stone {
                        // Stacked stone rocks
                        let rock1 = SKShapeNode(circleOfRadius: tileSize * 0.2)
                        rock1.fillColor = SKColor(red: 0.6, green: 0.6, blue: 0.6, alpha: 1.0)
                        rock1.strokeColor = SKColor(red: 0.45, green: 0.45, blue: 0.45, alpha: 1.0)
                        rock1.lineWidth = 1
                        rock1.position = CGPoint(x: -tileSize * 0.05, y: -tileSize * 0.05)
                        rock1.zPosition = 0.1
                        rock1.name = "stoneRock1"
                        node.addChild(rock1)
                        let rock2 = SKShapeNode(circleOfRadius: tileSize * 0.15)
                        rock2.fillColor = SKColor(red: 0.68, green: 0.68, blue: 0.68, alpha: 1.0)
                        rock2.strokeColor = SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
                        rock2.lineWidth = 0.5
                        rock2.position = CGPoint(x: tileSize * 0.1, y: tileSize * 0.08)
                        rock2.zPosition = 0.2
                        rock2.name = "stoneRock2"
                        node.addChild(rock2)
                        // Third small rock (different shade)
                        let rock3 = SKShapeNode(circleOfRadius: tileSize * 0.1)
                        rock3.fillColor = SKColor(red: 0.55, green: 0.54, blue: 0.52, alpha: 1.0)
                        rock3.strokeColor = SKColor(red: 0.42, green: 0.42, blue: 0.4, alpha: 1.0)
                        rock3.lineWidth = 0.5
                        rock3.position = CGPoint(x: -tileSize * 0.1, y: tileSize * 0.1)
                        rock3.zPosition = 0.25
                        rock3.name = "stoneRock3"
                        node.addChild(rock3)
                        // Stone vein highlight 1
                        let vein = SKShapeNode(rectOf: CGSize(width: tileSize * 0.15, height: 1))
                        vein.fillColor = SKColor(red: 0.75, green: 0.75, blue: 0.75, alpha: 0.5)
                        vein.strokeColor = .clear
                        vein.position = CGPoint(x: -tileSize * 0.05, y: -tileSize * 0.02)
                        vein.zRotation = 0.3
                        vein.zPosition = 0.15
                        vein.name = "stoneVein1"
                        node.addChild(vein)
                        // Stone vein highlight 2
                        let vein2 = SKShapeNode(rectOf: CGSize(width: tileSize * 0.12, height: 1))
                        vein2.fillColor = SKColor(red: 0.78, green: 0.76, blue: 0.74, alpha: 0.4)
                        vein2.strokeColor = .clear
                        vein2.position = CGPoint(x: tileSize * 0.08, y: tileSize * 0.06)
                        vein2.zRotation = -0.5
                        vein2.zPosition = 0.22
                        vein2.name = "stoneVein2"
                        node.addChild(vein2)
                    } else if tile.terrain == .berryBush {
                        // Bush foliage - back layer (darker)
                        let bushBack = SKShapeNode(circleOfRadius: tileSize * 0.28)
                        bushBack.fillColor = SKColor(red: 0.2, green: 0.45, blue: 0.15, alpha: 1.0)
                        bushBack.strokeColor = .clear
                        bushBack.position = CGPoint(x: 0, y: tileSize * 0.02)
                        bushBack.zPosition = 0.1
                        bushBack.name = "bushBack"
                        node.addChild(bushBack)
                        // Bush foliage - front layer (lighter, smaller) for depth
                        let bushFront = SKShapeNode(circleOfRadius: tileSize * 0.2)
                        bushFront.fillColor = SKColor(red: 0.28, green: 0.52, blue: 0.2, alpha: 1.0)
                        bushFront.strokeColor = .clear
                        bushFront.position = CGPoint(x: tileSize * 0.03, y: tileSize * 0.06)
                        bushFront.zPosition = 0.12
                        bushFront.name = "bushFront"
                        node.addChild(bushFront)
                        // Berry clusters with tiny stems
                        let berryPositions: [(CGFloat, CGFloat)] = [
                            (-0.1, 0.1), (0.12, 0.08), (0.0, -0.1),
                            (-0.08, -0.02), (0.1, -0.06)
                        ]
                        for (bx, by) in berryPositions {
                            // Tiny stem/leaf between berries
                            let stemPath = CGMutablePath()
                            stemPath.move(to: CGPoint(x: tileSize * bx, y: tileSize * by + tileSize * 0.02))
                            stemPath.addLine(to: CGPoint(x: tileSize * bx + 1.0, y: tileSize * by + tileSize * 0.02 + 2.0))
                            let stem = SKShapeNode(path: stemPath)
                            stem.strokeColor = SKColor(red: 0.15, green: 0.35, blue: 0.1, alpha: 0.6)
                            stem.lineWidth = 0.5
                            stem.name = "berryStem"
                            stem.zPosition = 0.15
                            node.addChild(stem)
                            // Berry
                            let berry = SKShapeNode(circleOfRadius: tileSize * 0.05)
                            berry.fillColor = SKColor(red: 0.75, green: 0.1, blue: 0.2, alpha: 1.0)
                            berry.strokeColor = .clear
                            berry.position = CGPoint(x: tileSize * bx, y: tileSize * by + tileSize * 0.02)
                            berry.zPosition = 0.2
                            berry.name = "berry"
                            node.addChild(berry)
                        }
                    }

                    // Decorative elements on some grass tiles (~18%)
                    if tile.terrain == .grass && tile.building == nil {
                        let hash = (x * 31 + y * 47) % 100
                        if hash < 5 {
                            // Small flower cluster (2-3 flowers)
                            let flowerCount = 2 + (hash % 2)
                            for fi in 0..<flowerCount {
                                let flower = SKShapeNode(circleOfRadius: tileSize * 0.06)
                                let flowerColors: [SKColor] = [
                                    SKColor.yellow,
                                    SKColor(red: 0.8, green: 0.3, blue: 0.5, alpha: 1.0),
                                    SKColor(red: 0.6, green: 0.4, blue: 0.8, alpha: 1.0)
                                ]
                                flower.fillColor = flowerColors[fi % flowerColors.count]
                                flower.strokeColor = .clear
                                let fx = CGFloat(hash % 3) * 3 - 3 + CGFloat(fi) * 2.5 - 1.5
                                let fy = CGFloat(hash % 5) * 2 - 4 + CGFloat(fi % 2) * 1.5
                                flower.position = CGPoint(x: fx, y: fy)
                                flower.name = "decor"
                                flower.zPosition = 0.1
                                node.addChild(flower)
                            }
                        } else if hash >= 5 && hash < 8 {
                            // Small rock
                            let rock = SKShapeNode(circleOfRadius: tileSize * 0.06)
                            rock.fillColor = SKColor(red: 0.5, green: 0.48, blue: 0.45, alpha: 0.6)
                            rock.strokeColor = .clear
                            rock.position = CGPoint(x: CGFloat(hash % 7) - 3, y: CGFloat(hash % 5) - 2)
                            rock.name = "decor"
                            rock.zPosition = 0.1
                            node.addChild(rock)
                        } else if hash >= 8 && hash < 11 {
                            // Small mushroom
                            let mStem = SKShapeNode(rectOf: CGSize(width: tileSize * 0.05, height: tileSize * 0.08))
                            mStem.fillColor = SKColor(red: 0.85, green: 0.8, blue: 0.7, alpha: 0.8)
                            mStem.strokeColor = .clear
                            mStem.position = CGPoint(x: CGFloat(hash % 5) - 2, y: CGFloat(hash % 3) - 3)
                            mStem.name = "decor"
                            mStem.zPosition = 0.1
                            node.addChild(mStem)
                            let cap = SKShapeNode(circleOfRadius: tileSize * 0.06)
                            cap.fillColor = hash < 10 ? SKColor(red: 0.7, green: 0.2, blue: 0.15, alpha: 0.8) : SKColor(red: 0.6, green: 0.5, blue: 0.2, alpha: 0.8)
                            cap.strokeColor = .clear
                            cap.position = CGPoint(x: CGFloat(hash % 5) - 2, y: CGFloat(hash % 3) - 3 + tileSize * 0.06)
                            cap.name = "decor"
                            cap.zPosition = 0.12
                            node.addChild(cap)
                        } else if hash >= 11 && hash < 15 {
                            // Small grass clump - 3 tiny green lines fanned out
                            let clumpX = CGFloat(hash % 7) - 3.0
                            let clumpY = CGFloat(hash % 5) - 2.0
                            let angles: [CGFloat] = [-0.4, 0.0, 0.4]
                            for (ai, angle) in angles.enumerated() {
                                let bladePath = CGMutablePath()
                                bladePath.move(to: CGPoint(x: clumpX, y: clumpY))
                                let tipX = clumpX + sin(angle) * tileSize * 0.12
                                let tipY = clumpY + cos(angle) * tileSize * 0.12
                                bladePath.addLine(to: CGPoint(x: tipX, y: tipY))
                                let blade = SKShapeNode(path: bladePath)
                                let gv = CGFloat(ai) * 0.05
                                blade.strokeColor = SKColor(red: 0.18 + gv, green: 0.45 + gv, blue: 0.12, alpha: 0.65)
                                blade.lineWidth = 0.5
                                blade.name = "decorGrassClump"
                                blade.zPosition = 0.05
                                node.addChild(blade)
                            }
                        } else if hash >= 15 && hash < 18 {
                            // Cattails near water edges (only if adjacent to water)
                            var nearWater = false
                            for neighbor in GridPosition(x: x, y: y).neighbors {
                                if isValid(neighbor) {
                                    let nt = tiles[neighbor.y][neighbor.x].terrain
                                    if nt == .water || nt == .deepWater {
                                        nearWater = true
                                        break
                                    }
                                }
                            }
                            if nearWater {
                                // Cattail: thin brown stick with oval brown top
                                let stickPath = CGMutablePath()
                                stickPath.move(to: CGPoint(x: 0, y: -tileSize * 0.1))
                                stickPath.addLine(to: CGPoint(x: 0, y: tileSize * 0.15))
                                let stick = SKShapeNode(path: stickPath)
                                stick.strokeColor = SKColor(red: 0.45, green: 0.35, blue: 0.18, alpha: 0.8)
                                stick.lineWidth = 1.0
                                stick.name = "decorCattail"
                                stick.zPosition = 0.15
                                node.addChild(stick)
                                let cattailTop = SKShapeNode(ellipseOf: CGSize(width: 2.5, height: 5))
                                cattailTop.fillColor = SKColor(red: 0.4, green: 0.28, blue: 0.12, alpha: 0.9)
                                cattailTop.strokeColor = .clear
                                cattailTop.position = CGPoint(x: 0, y: tileSize * 0.17)
                                cattailTop.name = "decorCattailTop"
                                cattailTop.zPosition = 0.16
                                node.addChild(cattailTop)
                            }
                        }
                    }

                    // Shore foam on sand tiles adjacent to water
                    if tile.terrain == .sand {
                        for neighbor in GridPosition(x: x, y: y).neighbors {
                            if isValid(neighbor) {
                                let nt = tiles[neighbor.y][neighbor.x].terrain
                                if nt == .water || nt == .deepWater {
                                    let dx = CGFloat(neighbor.x - x)
                                    let dy = CGFloat(neighbor.y - y)
                                    let foamSeed = (x * 53 + y * 71 + neighbor.x * 37) % 100
                                    let foamCount = 2 + foamSeed % 2 // 2-3 foam patches
                                    for fi in 0..<foamCount {
                                        let foam = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.2, height: tileSize * 0.06))
                                        let foamAlpha = 0.15 + CGFloat(foamSeed % 15) / 100.0
                                        foam.fillColor = SKColor.white.withAlphaComponent(foamAlpha)
                                        foam.strokeColor = .clear
                                        let spreadOffset = CGFloat(fi) * tileSize * 0.2 - tileSize * 0.15
                                        let edgeX = dx * tileSize * 0.35
                                        let edgeY = dy * tileSize * 0.35
                                        if dx != 0 {
                                            foam.position = CGPoint(x: edgeX, y: spreadOffset)
                                        } else {
                                            foam.position = CGPoint(x: spreadOffset, y: edgeY)
                                        }
                                        foam.name = "shoreFoam"
                                        foam.zPosition = 0.1
                                        node.addChild(foam)
                                    }
                                    break // Only add foam for one water neighbor
                                }
                            }
                        }
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

                    // Create wave highlight ellipses if they don't exist
                    if node.childNode(withName: "waveHighlight") == nil {
                        // First wave - ellipse instead of rectangle for curved look
                        let highlight = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.4, height: 3))
                        highlight.fillColor = SKColor.white.withAlphaComponent(0.2)
                        highlight.strokeColor = .clear
                        highlight.name = "waveHighlight"
                        highlight.zPosition = 0.1
                        node.addChild(highlight)

                        // Second wave offset by half phase
                        let highlight2 = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.3, height: 2.5))
                        highlight2.fillColor = SKColor.white.withAlphaComponent(0.15)
                        highlight2.strokeColor = .clear
                        highlight2.name = "waveHighlight2"
                        highlight2.zPosition = 0.1
                        node.addChild(highlight2)

                        // Third wave - shorter and brighter, offset by 2*pi/3
                        let highlight3 = SKShapeNode(ellipseOf: CGSize(width: tileSize * 0.2, height: 2))
                        highlight3.fillColor = SKColor.white.withAlphaComponent(0.25)
                        highlight3.strokeColor = .clear
                        highlight3.name = "waveHighlight3"
                        highlight3.zPosition = 0.12
                        node.addChild(highlight3)

                        // Deep water undercurrent effect
                        if tile.terrain == .deepWater {
                            let undercurrent = SKShapeNode(rectOf: CGSize(width: tileSize * 0.5, height: 1.5))
                            undercurrent.fillColor = SKColor(red: 0, green: 0, blue: 0.1, alpha: 0.08)
                            undercurrent.strokeColor = .clear
                            undercurrent.name = "undercurrent"
                            undercurrent.zPosition = 0.08
                            node.addChild(undercurrent)
                        }
                    }
                    if let highlight = node.childNode(withName: "waveHighlight") {
                        let waveX = sin(time * 2.0 + offset) * tileSize * 0.2
                        let waveY = cos(time * 1.3 + offset) * tileSize * 0.15
                        highlight.position = CGPoint(x: waveX, y: waveY)
                        let wAlpha = 0.1 + 0.25 * (0.5 + 0.5 * sin(time * 1.5 + offset))
                        (highlight as? SKShapeNode)?.fillColor = SKColor.white.withAlphaComponent(wAlpha)
                    }
                    if let highlight2 = node.childNode(withName: "waveHighlight2") {
                        let waveX2 = sin(time * 2.0 + offset + .pi) * tileSize * 0.15
                        let waveY2 = cos(time * 1.3 + offset + .pi) * tileSize * 0.1
                        highlight2.position = CGPoint(x: waveX2, y: waveY2)
                        let w2Alpha = 0.08 + 0.2 * (0.5 + 0.5 * sin(time * 1.5 + offset + .pi))
                        (highlight2 as? SKShapeNode)?.fillColor = SKColor.white.withAlphaComponent(w2Alpha)
                    }
                    if let highlight3 = node.childNode(withName: "waveHighlight3") {
                        let phase3 = 2.0 * CGFloat.pi / 3.0
                        let waveX3 = sin(time * 2.0 + offset + phase3) * tileSize * 0.18
                        let waveY3 = cos(time * 1.3 + offset + phase3) * tileSize * 0.12
                        highlight3.position = CGPoint(x: waveX3, y: waveY3)
                        let w3Alpha = 0.12 + 0.3 * (0.5 + 0.5 * sin(time * 1.8 + offset + phase3))
                        (highlight3 as? SKShapeNode)?.fillColor = SKColor.white.withAlphaComponent(w3Alpha)
                    }
                    // Animate deep water undercurrent
                    if let undercurrent = node.childNode(withName: "undercurrent") {
                        let ucX = sin(time * 0.5 + offset * 0.3) * tileSize * 0.3
                        let ucY = cos(time * 0.3 + offset * 0.2) * tileSize * 0.1
                        undercurrent.position = CGPoint(x: ucX, y: ucY)
                    }
                    // Fish jumping animation on deep water with fish
                    if tile.terrain == .deepWater && tile.resourceRemaining > 0 {
                        let fishPhase = (time * 0.5 + CGFloat(x * 13 + y * 29))
                        if abs(sin(fishPhase)) < 0.02 {
                            if node.childNode(withName: "fishJump") == nil {
                                let fish = SKShapeNode(ellipseOf: CGSize(width: 4, height: 2))
                                fish.fillColor = SKColor(red: 0.7, green: 0.7, blue: 0.8, alpha: 0.8)
                                fish.strokeColor = .clear
                                fish.name = "fishJump"
                                fish.zPosition = 1
                                node.addChild(fish)
                                fish.run(SKAction.sequence([
                                    SKAction.moveBy(x: 0, y: 8, duration: 0.2),
                                    SKAction.moveBy(x: 0, y: -8, duration: 0.2),
                                    SKAction.removeFromParent()
                                ]))
                            }
                        }
                    }
                } else if tile.terrain == .forest {
                    // Tree swaying - sway all canopy layers
                    let phase = CGFloat(x * 17 + y * 23)
                    let sway = sin(time * 0.7 + phase) * 1.5
                    for canopyName in ["canopy1", "canopy2", "canopy3", "treeHighlight"] {
                        if let child = node.childNode(withName: canopyName) {
                            child.position.x = sway
                        }
                    }
                } else if tile.terrain == .sand {
                    // Animate shore foam alpha pulsing
                    node.enumerateChildNodes(withName: "shoreFoam") { foam, _ in
                        let foamOffset = CGFloat(x * 11 + y * 19)
                        let foamAlpha = 0.15 + 0.10 * (0.5 + 0.5 * sin(time * 1.2 + foamOffset))
                        (foam as? SKShapeNode)?.fillColor = SKColor.white.withAlphaComponent(foamAlpha)
                    }
                } else if tile.terrain == .gold {
                    // Animate gold sparkle alpha pulse
                    if let sparkle = node.childNode(withName: "goldSparkle") as? SKShapeNode {
                        let sparkleOffset = CGFloat(x * 23 + y * 37)
                        let sparkleAlpha = 0.3 + 0.5 * (0.5 + 0.5 * sin(time * 2.5 + sparkleOffset))
                        sparkle.fillColor = SKColor(red: 1.0, green: 1.0, blue: 0.8, alpha: sparkleAlpha)
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
                // Check each edge neighbor (cardinal directions)
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
                    blend.fillColor = neighborTerrain.color.withAlphaComponent(0.35)
                    blend.strokeColor = .clear
                    blend.position = CGPoint(x: neighbor.offsetX, y: neighbor.offsetY)
                    blend.name = "blend"
                    blend.zPosition = 0.05
                    node.addChild(blend)
                }

                // Diagonal blending for corner neighbors at lower alpha
                let diagonalNeighbors: [(dx: Int, dy: Int, offsetX: CGFloat, offsetY: CGFloat)] = [
                    (1, 1, tileSize * 0.35, tileSize * 0.35),
                    (-1, 1, -tileSize * 0.35, tileSize * 0.35),
                    (1, -1, tileSize * 0.35, -tileSize * 0.35),
                    (-1, -1, -tileSize * 0.35, -tileSize * 0.35),
                ]

                for diag in diagonalNeighbors {
                    let nx = x + diag.dx
                    let ny = y + diag.dy
                    guard nx >= 0 && nx < width && ny >= 0 && ny < height else { continue }
                    let neighborTerrain = tiles[ny][nx].terrain
                    if neighborTerrain == terrain { continue }

                    let key1 = "\(terrain)-\(neighborTerrain)"
                    let key2 = "\(neighborTerrain)-\(terrain)"
                    guard blendPairs.contains(key1) || blendPairs.contains(key2) else { continue }

                    let diagBlend = SKShapeNode(rectOf: CGSize(width: tileSize * 0.25, height: tileSize * 0.25))
                    diagBlend.fillColor = neighborTerrain.color.withAlphaComponent(0.15)
                    diagBlend.strokeColor = .clear
                    diagBlend.position = CGPoint(x: diag.offsetX, y: diag.offsetY)
                    diagBlend.name = "blend"
                    diagBlend.zPosition = 0.05
                    node.addChild(diagBlend)
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
