import Foundation
import SpriteKit

// MARK: - Civilization

enum Civilization: String, CaseIterable {
    case britons
    case franks
    case mongols
    case byzantines

    var displayName: String {
        switch self {
        case .britons: return "Britons"
        case .franks: return "Franks"
        case .mongols: return "Mongols"
        case .byzantines: return "Byzantines"
        }
    }

    var icon: String {
        switch self {
        case .britons: return "\u{1F3F0}"
        case .franks: return "\u{2694}\u{FE0F}"
        case .mongols: return "\u{1F3F9}"
        case .byzantines: return "\u{1F6E1}\u{FE0F}"
        }
    }

    var bonus: String {
        switch self {
        case .britons: return "+20% Archer Range\n+10% Gather Speed"
        case .franks: return "+20% Knight HP\n+10% Farm Output"
        case .mongols: return "+30% Cavalry Speed\n+15% Hunt Bonus"
        case .byzantines: return "+25% Building HP\n+10% All Defense"
        }
    }

    var archerRangeBonus: CGFloat {
        self == .britons ? 1.2 : 1.0
    }

    var cavalryHPBonus: CGFloat {
        self == .franks ? 1.2 : 1.0
    }

    var cavalrySpeedBonus: CGFloat {
        self == .mongols ? 1.3 : 1.0
    }

    var buildingHPBonus: CGFloat {
        self == .byzantines ? 1.25 : 1.0
    }

    var gatherSpeedBonus: CGFloat {
        switch self {
        case .britons: return 1.1
        case .mongols: return 1.15
        default: return 1.0
        }
    }

    var farmBonus: CGFloat {
        self == .franks ? 1.1 : 1.0
    }

    var defenseBonus: CGFloat {
        self == .byzantines ? 1.1 : 1.0
    }
}

// MARK: - Age / Era

enum Age: Int, CaseIterable {
    case darkAge = 1
    case feudalAge = 2
    case castleAge = 3
    case imperialAge = 4

    var displayName: String {
        switch self {
        case .darkAge: return "Dark Age"
        case .feudalAge: return "Feudal Age"
        case .castleAge: return "Castle Age"
        case .imperialAge: return "Imperial Age"
        }
    }

    var advanceCost: Resources {
        switch self {
        case .darkAge: return Resources()
        case .feudalAge: return Resources(food: 500, gold: 200)
        case .castleAge: return Resources(food: 800, gold: 400, stone: 200)
        case .imperialAge: return Resources(food: 1200, gold: 800, stone: 400)
        }
    }
}

// MARK: - Resources

struct Resources {
    var food: Int = 0
    var wood: Int = 0
    var gold: Int = 0
    var stone: Int = 0

    static func + (lhs: Resources, rhs: Resources) -> Resources {
        Resources(food: lhs.food + rhs.food,
                  wood: lhs.wood + rhs.wood,
                  gold: lhs.gold + rhs.gold,
                  stone: lhs.stone + rhs.stone)
    }

    static func - (lhs: Resources, rhs: Resources) -> Resources {
        Resources(food: lhs.food - rhs.food,
                  wood: lhs.wood - rhs.wood,
                  gold: lhs.gold - rhs.gold,
                  stone: lhs.stone - rhs.stone)
    }

    func canAfford(_ cost: Resources) -> Bool {
        food >= cost.food && wood >= cost.wood && gold >= cost.gold && stone >= cost.stone
    }

    mutating func subtract(_ cost: Resources) {
        food -= cost.food
        wood -= cost.wood
        gold -= cost.gold
        stone -= cost.stone
    }

    mutating func add(_ amount: Resources) {
        food += amount.food
        wood += amount.wood
        gold += amount.gold
        stone += amount.stone
    }
}

// MARK: - Terrain

enum TerrainType: Int, CaseIterable {
    case grass = 0
    case forest = 1
    case water = 2
    case stone = 3
    case gold = 4
    case sand = 5
    case deepWater = 6
    case berryBush = 7
    case farm = 8

    var isPassable: Bool {
        switch self {
        case .water, .deepWater: return false
        default: return true
        }
    }

    var isBuildable: Bool {
        switch self {
        case .grass, .sand: return true
        default: return false
        }
    }

    var color: SKColor {
        switch self {
        case .grass: return SKColor(red: 0.35, green: 0.55, blue: 0.2, alpha: 1.0)
        case .forest: return SKColor(red: 0.15, green: 0.4, blue: 0.1, alpha: 1.0)
        case .water: return SKColor(red: 0.2, green: 0.4, blue: 0.7, alpha: 1.0)
        case .stone: return SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1.0)
        case .gold: return SKColor(red: 0.8, green: 0.7, blue: 0.2, alpha: 1.0)
        case .sand: return SKColor(red: 0.76, green: 0.7, blue: 0.5, alpha: 1.0)
        case .deepWater: return SKColor(red: 0.1, green: 0.25, blue: 0.55, alpha: 1.0)
        case .berryBush: return SKColor(red: 0.5, green: 0.2, blue: 0.4, alpha: 1.0)
        case .farm: return SKColor(red: 0.6, green: 0.5, blue: 0.2, alpha: 1.0)
        }
    }

    var resourceType: ResourceType? {
        switch self {
        case .forest: return .wood
        case .stone: return .stone
        case .gold: return .gold
        case .berryBush: return .food
        case .farm: return .food
        default: return nil
        }
    }

    var resourceAmount: Int {
        switch self {
        case .forest: return 150
        case .stone: return 250
        case .gold: return 300
        case .berryBush: return 200
        case .farm: return 300
        default: return 0
        }
    }
}

enum ResourceType {
    case food
    case wood
    case gold
    case stone
}

// MARK: - Tile

class MapTile {
    var terrain: TerrainType
    var gridPosition: GridPosition
    var resourceRemaining: Int
    var building: Building?
    var isExplored: Bool = false
    var isVisible: Bool = false
    var node: SKShapeNode?

    init(terrain: TerrainType, position: GridPosition) {
        self.terrain = terrain
        self.gridPosition = position
        self.resourceRemaining = terrain.resourceAmount
    }
}

// MARK: - Grid Position

struct GridPosition: Hashable, Equatable {
    var x: Int
    var y: Int

    func distance(to other: GridPosition) -> CGFloat {
        let dx = CGFloat(x - other.x)
        let dy = CGFloat(y - other.y)
        return sqrt(dx * dx + dy * dy)
    }

    func manhattanDistance(to other: GridPosition) -> Int {
        abs(x - other.x) + abs(y - other.y)
    }

    var neighbors: [GridPosition] {
        [
            GridPosition(x: x - 1, y: y),
            GridPosition(x: x + 1, y: y),
            GridPosition(x: x, y: y - 1),
            GridPosition(x: x, y: y + 1),
            GridPosition(x: x - 1, y: y - 1),
            GridPosition(x: x + 1, y: y - 1),
            GridPosition(x: x - 1, y: y + 1),
            GridPosition(x: x + 1, y: y + 1),
        ]
    }
}

// MARK: - Player

class Player {
    let id: Int
    let civilization: Civilization
    var resources: Resources
    var currentAge: Age = .darkAge
    var buildings: [Building] = []
    var units: [Unit] = []
    var populationCap: Int = 10
    var isAdvancingAge: Bool = false
    var ageAdvanceProgress: CGFloat = 0
    var researchedTechs: Set<TechType> = []
    var isHuman: Bool

    var population: Int { units.count }

    init(id: Int, civilization: Civilization, isHuman: Bool) {
        self.id = id
        self.civilization = civilization
        self.isHuman = isHuman
        self.resources = Resources(food: 200, wood: 200, gold: 100, stone: 100)
    }

    func canAfford(_ cost: Resources) -> Bool {
        resources.canAfford(cost)
    }

    func spend(_ cost: Resources) {
        resources.subtract(cost)
    }
}

// MARK: - Building Types

enum BuildingType: CaseIterable {
    case townCenter
    case house
    case barracks
    case archeryRange
    case stable
    case blacksmith
    case market
    case castle
    case farm
    case lumberCamp
    case miningCamp
    case wall
    case tower

    var displayName: String {
        switch self {
        case .townCenter: return "Town Center"
        case .house: return "House"
        case .barracks: return "Barracks"
        case .archeryRange: return "Archery Range"
        case .stable: return "Stable"
        case .blacksmith: return "Blacksmith"
        case .market: return "Market"
        case .castle: return "Castle"
        case .farm: return "Farm"
        case .lumberCamp: return "Lumber Camp"
        case .miningCamp: return "Mining Camp"
        case .wall: return "Wall"
        case .tower: return "Tower"
        }
    }

    var icon: String {
        switch self {
        case .townCenter: return "TC"
        case .house: return "H"
        case .barracks: return "BK"
        case .archeryRange: return "AR"
        case .stable: return "ST"
        case .blacksmith: return "BS"
        case .market: return "MK"
        case .castle: return "CA"
        case .farm: return "FM"
        case .lumberCamp: return "LC"
        case .miningCamp: return "MC"
        case .wall: return "W"
        case .tower: return "TW"
        }
    }

    var size: (width: Int, height: Int) {
        switch self {
        case .townCenter: return (3, 3)
        case .castle: return (4, 4)
        case .barracks, .archeryRange, .stable, .blacksmith, .market: return (2, 2)
        case .house, .lumberCamp, .miningCamp: return (2, 2)
        case .farm: return (2, 2)
        case .wall: return (1, 1)
        case .tower: return (1, 1)
        }
    }

    var cost: Resources {
        switch self {
        case .townCenter: return Resources(food: 0, wood: 275, gold: 0, stone: 100)
        case .house: return Resources(food: 0, wood: 25, gold: 0, stone: 0)
        case .barracks: return Resources(food: 0, wood: 175, gold: 0, stone: 0)
        case .archeryRange: return Resources(food: 0, wood: 175, gold: 0, stone: 0)
        case .stable: return Resources(food: 0, wood: 175, gold: 0, stone: 0)
        case .blacksmith: return Resources(food: 0, wood: 150, gold: 0, stone: 0)
        case .market: return Resources(food: 0, wood: 175, gold: 0, stone: 0)
        case .castle: return Resources(food: 0, wood: 0, gold: 0, stone: 650)
        case .farm: return Resources(food: 0, wood: 60, gold: 0, stone: 0)
        case .lumberCamp: return Resources(food: 0, wood: 100, gold: 0, stone: 0)
        case .miningCamp: return Resources(food: 0, wood: 100, gold: 0, stone: 0)
        case .wall: return Resources(food: 0, wood: 0, gold: 0, stone: 5)
        case .tower: return Resources(food: 0, wood: 50, gold: 0, stone: 125)
        }
    }

    var maxHP: Int {
        switch self {
        case .townCenter: return 2400
        case .house: return 550
        case .barracks: return 1200
        case .archeryRange: return 1200
        case .stable: return 1200
        case .blacksmith: return 1200
        case .market: return 1200
        case .castle: return 4800
        case .farm: return 400
        case .lumberCamp: return 600
        case .miningCamp: return 600
        case .wall: return 900
        case .tower: return 1500
        }
    }

    var buildTime: CGFloat {
        switch self {
        case .townCenter: return 20
        case .house: return 5
        case .barracks: return 10
        case .archeryRange: return 10
        case .stable: return 10
        case .blacksmith: return 8
        case .market: return 10
        case .castle: return 30
        case .farm: return 4
        case .lumberCamp: return 6
        case .miningCamp: return 6
        case .wall: return 2
        case .tower: return 15
        }
    }

    var populationProvided: Int {
        switch self {
        case .townCenter: return 5
        case .house: return 5
        case .castle: return 5
        default: return 0
        }
    }

    var requiredAge: Age {
        switch self {
        case .townCenter, .house, .farm, .lumberCamp, .miningCamp, .barracks: return .darkAge
        case .archeryRange, .stable, .blacksmith, .market, .wall, .tower: return .feudalAge
        case .castle: return .castleAge
        }
    }

    var trainableUnits: [UnitType] {
        switch self {
        case .townCenter: return [.villager]
        case .barracks: return [.militia, .manAtArms, .spearman]
        case .archeryRange: return [.archer, .crossbowman, .skirmisher]
        case .stable: return [.scout, .knight, .lightCavalry]
        case .castle: return [.uniqueUnit]
        default: return []
        }
    }

    var color: SKColor {
        switch self {
        case .townCenter: return SKColor(red: 0.7, green: 0.5, blue: 0.2, alpha: 1.0)
        case .house: return SKColor(red: 0.6, green: 0.4, blue: 0.2, alpha: 1.0)
        case .barracks: return SKColor(red: 0.5, green: 0.3, blue: 0.3, alpha: 1.0)
        case .archeryRange: return SKColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0)
        case .stable: return SKColor(red: 0.4, green: 0.35, blue: 0.5, alpha: 1.0)
        case .blacksmith: return SKColor(red: 0.4, green: 0.4, blue: 0.4, alpha: 1.0)
        case .market: return SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        case .castle: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        case .farm: return SKColor(red: 0.6, green: 0.55, blue: 0.2, alpha: 1.0)
        case .lumberCamp: return SKColor(red: 0.5, green: 0.4, blue: 0.2, alpha: 1.0)
        case .miningCamp: return SKColor(red: 0.45, green: 0.45, blue: 0.35, alpha: 1.0)
        case .wall: return SKColor(red: 0.5, green: 0.5, blue: 0.5, alpha: 1.0)
        case .tower: return SKColor(red: 0.55, green: 0.55, blue: 0.5, alpha: 1.0)
        }
    }

    var attackDamage: Int {
        switch self {
        case .townCenter: return 5
        case .tower: return 8
        case .castle: return 12
        default: return 0
        }
    }

    var attackRange: CGFloat {
        switch self {
        case .townCenter: return 5.0
        case .tower: return 7.0
        case .castle: return 9.0
        default: return 0
        }
    }
}

// MARK: - Building

class Building {
    static var nextID: Int = 0

    let id: Int
    let type: BuildingType
    let ownerID: Int
    var gridPosition: GridPosition
    var hp: Int
    var maxHP: Int
    var isConstructed: Bool = false
    var constructionProgress: CGFloat = 0
    var trainingQueue: [UnitType] = []
    var trainingProgress: CGFloat = 0
    var rallyPoint: GridPosition?
    var node: SKNode?

    init(type: BuildingType, ownerID: Int, position: GridPosition, civilizationBonus: CGFloat = 1.0) {
        self.id = Building.nextID
        Building.nextID += 1
        self.type = type
        self.ownerID = ownerID
        self.gridPosition = position
        self.maxHP = Int(CGFloat(type.maxHP) * civilizationBonus)
        self.hp = isConstructed ? maxHP : 1
    }
}

// MARK: - Unit Types

enum UnitType: CaseIterable {
    case villager
    case militia
    case manAtArms
    case spearman
    case archer
    case crossbowman
    case skirmisher
    case scout
    case knight
    case lightCavalry
    case uniqueUnit

    var displayName: String {
        switch self {
        case .villager: return "Villager"
        case .militia: return "Militia"
        case .manAtArms: return "Man-at-Arms"
        case .spearman: return "Spearman"
        case .archer: return "Archer"
        case .crossbowman: return "Crossbowman"
        case .skirmisher: return "Skirmisher"
        case .scout: return "Scout"
        case .knight: return "Knight"
        case .lightCavalry: return "Light Cavalry"
        case .uniqueUnit: return "Champion"
        }
    }

    var icon: String {
        switch self {
        case .villager: return "V"
        case .militia: return "M"
        case .manAtArms: return "MA"
        case .spearman: return "SP"
        case .archer: return "A"
        case .crossbowman: return "XB"
        case .skirmisher: return "SK"
        case .scout: return "SC"
        case .knight: return "KN"
        case .lightCavalry: return "LC"
        case .uniqueUnit: return "UU"
        }
    }

    var cost: Resources {
        switch self {
        case .villager: return Resources(food: 50)
        case .militia: return Resources(food: 60, gold: 20)
        case .manAtArms: return Resources(food: 60, gold: 20)
        case .spearman: return Resources(food: 35, wood: 25)
        case .archer: return Resources(food: 0, wood: 25, gold: 45)
        case .crossbowman: return Resources(food: 0, wood: 25, gold: 45)
        case .skirmisher: return Resources(food: 25, wood: 35)
        case .scout: return Resources(food: 80)
        case .knight: return Resources(food: 60, gold: 75)
        case .lightCavalry: return Resources(food: 80)
        case .uniqueUnit: return Resources(food: 60, gold: 60)
        }
    }

    var maxHP: Int {
        switch self {
        case .villager: return 25
        case .militia: return 40
        case .manAtArms: return 50
        case .spearman: return 45
        case .archer: return 30
        case .crossbowman: return 35
        case .skirmisher: return 30
        case .scout: return 60
        case .knight: return 100
        case .lightCavalry: return 60
        case .uniqueUnit: return 80
        }
    }

    var attack: Int {
        switch self {
        case .villager: return 3
        case .militia: return 4
        case .manAtArms: return 6
        case .spearman: return 3
        case .archer: return 4
        case .crossbowman: return 5
        case .skirmisher: return 2
        case .scout: return 5
        case .knight: return 10
        case .lightCavalry: return 7
        case .uniqueUnit: return 12
        }
    }

    var defense: Int {
        switch self {
        case .villager: return 0
        case .militia: return 1
        case .manAtArms: return 2
        case .spearman: return 2
        case .archer: return 0
        case .crossbowman: return 0
        case .skirmisher: return 1
        case .scout: return 1
        case .knight: return 4
        case .lightCavalry: return 2
        case .uniqueUnit: return 3
        }
    }

    var moveSpeed: CGFloat {
        switch self {
        case .villager: return 1.0
        case .militia, .manAtArms: return 0.9
        case .spearman: return 1.0
        case .archer, .crossbowman, .skirmisher: return 0.96
        case .scout: return 1.55
        case .knight: return 1.35
        case .lightCavalry: return 1.5
        case .uniqueUnit: return 1.1
        }
    }

    var attackRange: CGFloat {
        switch self {
        case .archer: return 4.0
        case .crossbowman: return 5.0
        case .skirmisher: return 4.0
        default: return 1.2
        }
    }

    var isRanged: Bool {
        attackRange > 2.0
    }

    var trainTime: CGFloat {
        switch self {
        case .villager: return 5.0
        case .militia: return 6.0
        case .manAtArms: return 6.0
        case .spearman: return 5.0
        case .archer: return 7.0
        case .crossbowman: return 8.0
        case .skirmisher: return 5.0
        case .scout: return 6.0
        case .knight: return 10.0
        case .lightCavalry: return 8.0
        case .uniqueUnit: return 12.0
        }
    }

    var requiredAge: Age {
        switch self {
        case .villager, .militia: return .darkAge
        case .manAtArms, .archer, .skirmisher, .scout, .spearman: return .feudalAge
        case .crossbowman, .knight, .lightCavalry: return .castleAge
        case .uniqueUnit: return .castleAge
        }
    }

    var isCavalry: Bool {
        switch self {
        case .scout, .knight, .lightCavalry: return true
        default: return false
        }
    }

    var bonusVsCavalry: Int {
        switch self {
        case .spearman: return 15
        default: return 0
        }
    }

    var color: SKColor {
        switch self {
        case .villager: return SKColor(red: 0.3, green: 0.6, blue: 0.3, alpha: 1.0)
        case .militia, .manAtArms: return SKColor(red: 0.6, green: 0.3, blue: 0.3, alpha: 1.0)
        case .spearman: return SKColor(red: 0.5, green: 0.4, blue: 0.3, alpha: 1.0)
        case .archer, .crossbowman: return SKColor(red: 0.3, green: 0.5, blue: 0.3, alpha: 1.0)
        case .skirmisher: return SKColor(red: 0.4, green: 0.5, blue: 0.4, alpha: 1.0)
        case .scout, .lightCavalry: return SKColor(red: 0.5, green: 0.4, blue: 0.5, alpha: 1.0)
        case .knight: return SKColor(red: 0.6, green: 0.5, blue: 0.2, alpha: 1.0)
        case .uniqueUnit: return SKColor(red: 0.7, green: 0.3, blue: 0.5, alpha: 1.0)
        }
    }
}

// MARK: - Unit State

enum UnitState {
    case idle
    case moving(to: GridPosition)
    case gathering(resourceType: ResourceType, tilePos: GridPosition)
    case returning(dropOff: GridPosition, resourceType: ResourceType, carried: Int)
    case building(buildingID: Int)
    case attacking(targetUnitID: Int)
    case attackingBuilding(targetBuildingID: Int)
    case patrolling(from: GridPosition, to: GridPosition)
    case garrisoned(buildingID: Int)
}

// MARK: - Unit

class Unit {
    static var nextID: Int = 0

    let id: Int
    let type: UnitType
    let ownerID: Int
    var position: CGPoint
    var gridPosition: GridPosition
    var hp: Int
    var maxHP: Int
    var state: UnitState = .idle
    var path: [GridPosition] = []
    var carriedResource: ResourceType?
    var carriedAmount: Int = 0
    var attackCooldown: CGFloat = 0
    var node: SKNode?
    var isSelected: Bool = false
    var lastAttackTime: TimeInterval = 0

    init(type: UnitType, ownerID: Int, position: GridPosition, hpBonus: CGFloat = 1.0, speedBonus: CGFloat = 1.0) {
        self.id = Unit.nextID
        Unit.nextID += 1
        self.type = type
        self.ownerID = ownerID
        self.gridPosition = position
        self.position = CGPoint(x: 0, y: 0)
        self.maxHP = Int(CGFloat(type.maxHP) * hpBonus)
        self.hp = self.maxHP
    }

    var effectiveAttack: Int {
        type.attack
    }

    var effectiveDefense: Int {
        type.defense
    }
}

// MARK: - Game State

enum GameState {
    case playing
    case paused
    case victory
    case defeat
}

// MARK: - Action Mode

enum ActionMode {
    case normal
    case placingBuilding(BuildingType)
    case attackMove
}
