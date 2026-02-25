import Foundation

class Pathfinder {
    let map: GameMap

    init(map: GameMap) {
        self.map = map
    }

    // A* pathfinding with optimized heuristic and data structures
    func findPath(from start: GridPosition, to end: GridPosition, maxIterations: Int = 500) -> [GridPosition] {
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

        var openSet = PriorityQueue<PathNode>()
        var closedSet = Set<GridPosition>()
        var cameFrom: [GridPosition: GridPosition] = [:]
        var gScore: [GridPosition: CGFloat] = [start: 0]

        // Use octile distance — admissible and consistent heuristic for 8-directional movement
        openSet.push(PathNode(position: start, f: start.octileDistance(to: target)))

        var iterations = 0

        while let current = openSet.pop() {
            iterations += 1
            if iterations > maxIterations { break }

            if current.position == target {
                return reconstructPath(cameFrom: cameFrom, current: target)
            }

            // Skip duplicates already in closed set
            if closedSet.contains(current.position) { continue }
            closedSet.insert(current.position)

            let currentG = gScore[current.position] ?? .infinity

            // Inline neighbor iteration — avoids allocating an 8-element array each loop
            current.position.forEachNeighbor { neighbor in
                guard map.isValid(neighbor) && !closedSet.contains(neighbor) else { return }

                // Allow walking to the target even if it has a building (for attacking)
                if neighbor != target && !map.isPassable(neighbor) { return }

                let isDiagonal = abs(neighbor.x - current.position.x) + abs(neighbor.y - current.position.y) == 2
                let moveCost: CGFloat = isDiagonal ? 1.414 : 1.0

                let tentativeG = currentG + moveCost

                if tentativeG < (gScore[neighbor] ?? .infinity) {
                    cameFrom[neighbor] = current.position
                    gScore[neighbor] = tentativeG
                    let f = tentativeG + neighbor.octileDistance(to: target)
                    openSet.push(PathNode(position: neighbor, f: f))
                }
            }
        }

        return []
    }

    // O(n) reconstruction — append + reverse instead of O(n²) insert(at:0)
    private func reconstructPath(cameFrom: [GridPosition: GridPosition], current: GridPosition) -> [GridPosition] {
        var path: [GridPosition] = [current]
        var node = current
        while let prev = cameFrom[node] {
            path.append(prev)
            node = prev
        }
        path.reverse()
        // Remove the starting position
        if path.count > 1 {
            path.removeFirst()
        }
        return path
    }

    private func findNearestPassable(to target: GridPosition, from source: GridPosition) -> GridPosition? {
        var bestPos: GridPosition?
        var bestDistSq: Int = .max

        target.forEachNeighbor { neighbor in
            if map.isPassable(neighbor) {
                let distSq = source.distanceSquared(to: neighbor)
                if distSq < bestDistSq {
                    bestDistSq = distSq
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
