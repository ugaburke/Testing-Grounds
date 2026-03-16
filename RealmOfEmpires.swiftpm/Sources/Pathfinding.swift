import Foundation

// MARK: - Path Cache Key

private struct PathCacheKey: Hashable {
    let start: GridPosition
    let end: GridPosition
}

// MARK: - LRU Path Cache

private class LRUPathCache {
    private var cache: [PathCacheKey: [GridPosition]] = [:]
    private var accessOrder: [PathCacheKey] = []
    private let maxEntries: Int

    init(maxEntries: Int = GameConstants.pathCacheMaxEntries) {
        self.maxEntries = maxEntries
    }

    func get(_ key: PathCacheKey) -> [GridPosition]? {
        guard let result = cache[key] else { return nil }
        // Move to end (most recently used)
        accessOrder.removeAll { $0 == key }
        accessOrder.append(key)
        return result
    }

    func set(_ key: PathCacheKey, path: [GridPosition]) {
        if cache[key] != nil {
            accessOrder.removeAll { $0 == key }
        } else if cache.count >= maxEntries {
            // Evict least recently used
            if let oldest = accessOrder.first {
                cache.removeValue(forKey: oldest)
                accessOrder.removeFirst()
            }
        }
        cache[key] = path
        accessOrder.append(key)
    }

    func invalidate() {
        cache.removeAll()
        accessOrder.removeAll()
    }
}

class Pathfinder {
    let map: GameMap
    private var pathCache = LRUPathCache()

    init(map: GameMap) {
        self.map = map
    }

    /// Call when buildings are placed or destroyed to clear cached paths.
    func invalidateCache() {
        pathCache.invalidate()
    }

    // A* pathfinding
    func findPath(from start: GridPosition, to end: GridPosition, maxIterations: Int = GameConstants.pathfindingMaxIterations) -> [GridPosition] {
        guard map.isValid(start) && map.isValid(end) else { return [] }

        // If destination is not passable, find nearest passable tile
        let target: GridPosition
        if map.isPassable(end) {
            target = end
        } else {
            guard let nearest = findNearestPassable(to: end, from: start) else { return [] }
            target = nearest
        }

        if start == target { return [target] }

        // Check cache
        let cacheKey = PathCacheKey(start: start, end: target)
        if let cached = pathCache.get(cacheKey) {
            return cached
        }

        var openSet = PriorityQueue<PathNode>()
        var closedSet = Set<GridPosition>()
        var cameFrom: [GridPosition: GridPosition] = [:]
        var gScore: [GridPosition: CGFloat] = [start: 0]

        openSet.push(PathNode(position: start, f: start.distance(to: target)))

        var iterations = 0

        while let current = openSet.pop() {
            iterations += 1
            if iterations > maxIterations { break }

            if current.position == target {
                let path = reconstructPath(cameFrom: cameFrom, current: target)
                pathCache.set(cacheKey, path: path)
                return path
            }

            closedSet.insert(current.position)

            for neighbor in current.position.neighbors {
                guard map.isValid(neighbor) && !closedSet.contains(neighbor) else { continue }

                // Allow walking to the target even if it has a building (for attacking)
                if neighbor != target && !map.isPassable(neighbor) { continue }

                let isDiagonal = abs(neighbor.x - current.position.x) + abs(neighbor.y - current.position.y) == 2
                let moveCost: CGFloat = isDiagonal ? 1.414 : 1.0

                let tentativeG = (gScore[current.position] ?? .infinity) + moveCost

                if tentativeG < (gScore[neighbor] ?? .infinity) {
                    cameFrom[neighbor] = current.position
                    gScore[neighbor] = tentativeG
                    let f = tentativeG + neighbor.distance(to: target)
                    openSet.push(PathNode(position: neighbor, f: f))
                }
            }
        }

        return []
    }

    private func reconstructPath(cameFrom: [GridPosition: GridPosition], current: GridPosition) -> [GridPosition] {
        var path: [GridPosition] = [current]
        var node = current
        while let prev = cameFrom[node] {
            path.insert(prev, at: 0)
            node = prev
        }
        // Remove the starting position
        if path.count > 1 {
            path.removeFirst()
        }
        return path
    }

    private func findNearestPassable(to target: GridPosition, from source: GridPosition) -> GridPosition? {
        var bestPos: GridPosition?
        var bestDist: CGFloat = .infinity

        for neighbor in target.neighbors {
            if map.isPassable(neighbor) {
                let dist = source.distance(to: neighbor)
                if dist < bestDist {
                    bestDist = dist
                    bestPos = neighbor
                }
            }
        }
        return bestPos
    }
}

// MARK: - Path Node

struct PathNode: Comparable {
    let position: GridPosition
    let f: CGFloat

    static func < (lhs: PathNode, rhs: PathNode) -> Bool {
        lhs.f < rhs.f
    }
}

// MARK: - Priority Queue (Min-Heap)

struct PriorityQueue<T: Comparable> {
    private var heap: [T] = []

    var isEmpty: Bool { heap.isEmpty }

    mutating func push(_ element: T) {
        heap.append(element)
        siftUp(heap.count - 1)
    }

    mutating func pop() -> T? {
        guard !heap.isEmpty else { return nil }
        if heap.count == 1 { return heap.removeFirst() }
        heap.swapAt(0, heap.count - 1)
        let min = heap.removeLast()
        if !heap.isEmpty { siftDown(0) }
        return min
    }

    private mutating func siftUp(_ index: Int) {
        var child = index
        var parent = (child - 1) / 2
        while child > 0 && heap[child] < heap[parent] {
            heap.swapAt(child, parent)
            child = parent
            parent = (child - 1) / 2
        }
    }

    private mutating func siftDown(_ index: Int) {
        var parent = index
        while true {
            let left = 2 * parent + 1
            let right = 2 * parent + 2
            var smallest = parent

            if left < heap.count && heap[left] < heap[smallest] { smallest = left }
            if right < heap.count && heap[right] < heap[smallest] { smallest = right }

            if smallest == parent { break }
            heap.swapAt(parent, smallest)
            parent = smallest
        }
    }
}
