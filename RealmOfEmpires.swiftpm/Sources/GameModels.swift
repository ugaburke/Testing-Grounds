import Foundation
import SpriteKit

// MARK: - Civilization

enum Civilization: String, CaseIterable {
    case britons
    case franks
    case mongols
    case byzantines
    case japanese
    case persians
    case chinese
    case vikings

    var displayName: String {
        switch self {
        case .britons: return "Britons"
        case .franks: return "Franks"
        case .mongols: return "Mongols"
        case .byzantines: return "Byzantines"
        case .japanese: return "Japanese"
        case .persians: return "Persians"
        case .chinese: return "Chinese"
        case .vikings: return "Vikings"
        }
    }

    var icon: String {
        switch self {
        case .britons: return "\u{1F3F0}"
        case .franks: return "\u{2694}\u{FE0F}"
        case .mongols: return "\u{1F3F9}"
        case .byzantines: return "\u{1F6E1}\u{FE0F}"
        case .japanese: return "\u{2328}\u{FE0F}"
        case .persians: return "\u{1F451}"
        case .chinese: return "\u{1F3EF}"
        case .vikings: return "\u{2693}"
        }
    }

    var bonus: String {
        switch self {
        case .britons: return "+20% Archer Range\n+10% Gather Speed"
        case .franks: return "+20% Knight HP\n+10% Farm Output"
        case .mongols: return "+30% Cavalry Speed\n+15% Hunt Bonus"
        case .byzantines: return "+25% Building HP\n+10% All Defense"
        case .japanese: return "+15% Infantry ATK Speed\n+10% Fishing"
        case .persians: return "+20% TC Work Rate\n+15% Cavalry HP"
        case .chinese: return "+3 Starting Villagers\n-10% Tech Cost"
        case .vikings: return "Free Wheelbarrow/Hand Cart\n+20% Infantry HP"
        }
    }

    var archerRangeBonus: CGFloat {
        self == .britons ? 1.2 : 1.0
    }

    var cavalryHPBonus: CGFloat {
        switch self {
        case .franks: return 1.2
        case .persians: return 1.15
        default: return 1.0
        }
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

    var infantryAttackSpeedBonus: CGFloat {
        self == .japanese ? 0.85 : 1.0  // Lower = faster attacks
    }

    var tcWorkRateBonus: CGFloat {
        self == .persians ? 1.2 : 1.0
    }

    var fishingBonus: CGFloat {
        self == .japanese ? 1.1 : 1.0
    }

    var techCostBonus: CGFloat {
        self == .chinese ? 0.9 : 1.0
    }

    var startingVillagerBonus: Int {
        self == .chinese ? 3 : 0
    }

    var infantryHPBonus: CGFloat {
        self == .vikings ? 1.2 : 1.0
    }

    var freeEcoUpgrades: [TechType] {
        self == .vikings ? [.wheelbarrow, .handCart] : []
    }

    var uniqueUnitType: UnitType {
        switch self {
        case .britons: return .longbowman
        case .franks: return .throwingAxeman
        case .mongols: return .mangudai
        case .byzantines: return .cataphract
        case .japanese: return .samurai
        case .persians: return .warElephant
        case .chinese: return .chuKoNu
        case .vikings: return .berserk
        }
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
    var controlGroups: [[Int]] = Array(repeating: [], count: 10)
    var relicsCollected: Int = 0
    var wonderBuilt: Bool = false
    var wonderTimer: CGFloat = 0  // Countdown to wonder victory
    var totalKills: Int = 0
    var totalUnitsLost: Int = 0
    var totalResourcesGathered: Resources = Resources()
    var marketPrices: [ResourceType: CGFloat] = [.food: 1.0, .wood: 1.0, .gold: 1.0, .stone: 1.0]

    var population: Int { units.count }

    init(id: Int, civilization: Civilization, isHuman: Bool) {
        self.id = id
        self.civilization = civilization
        self.isHuman = isHuman
        self.resources = Resources(food: 200, wood: 200, gold: 150, stone: 100)
    }

    func canAfford(_ cost: Resources) -> Bool {
        resources.canAfford(cost)
    }

    func spend(_ cost: Resources) {
        guard canAfford(cost) else { return }
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
    case gate
    case tower
    case siegeWorkshop
    case monastery
    case dock
    // New buildings
    case university
    case wonder
    case outpost
    case fishTrap

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
        case .siegeWorkshop: return "Siege Workshop"
        case .gate: return "Gate"
        case .monastery: return "Monastery"
        case .dock: return "Dock"
        case .university: return "University"
        case .wonder: return "Wonder"
        case .outpost: return "Outpost"
        case .fishTrap: return "Fish Trap"
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
        case .siegeWorkshop: return "SW"
        case .gate: return "GT"
        case .monastery: return "MO"
        case .dock: return "DK"
        case .university: return "UN"
        case .wonder: return "WD"
        case .outpost: return "OP"
        case .fishTrap: return "FT"
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
        case .siegeWorkshop: return (3, 3)
        case .gate: return (1, 1)
        case .monastery: return (2, 2)
        case .dock: return (2, 2)
        case .university: return (3, 3)
        case .wonder: return (5, 5)
        case .outpost: return (1, 1)
        case .fishTrap: return (1, 1)
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
        case .siegeWorkshop: return Resources(food: 0, wood: 200)
        case .gate: return Resources(food: 0, wood: 0, gold: 0, stone: 30)
        case .monastery: return Resources(food: 0, wood: 175, gold: 0, stone: 0)
        case .dock: return Resources(food: 0, wood: 150, gold: 0, stone: 0)
        case .university: return Resources(food: 0, wood: 200, gold: 0, stone: 0)
        case .wonder: return Resources(food: 1000, wood: 1000, gold: 1000, stone: 1000)
        case .outpost: return Resources(food: 0, wood: 25, stone: 5)
        case .fishTrap: return Resources(food: 0, wood: 100)
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
        case .siegeWorkshop: return 1200
        case .gate: return 1800
        case .monastery: return 1200
        case .dock: return 1200
        case .university: return 1200
        case .wonder: return 6000
        case .outpost: return 400
        case .fishTrap: return 300
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
        case .siegeWorkshop: return 12
        case .gate: return 3
        case .monastery: return 10
        case .dock: return 10
        case .university: return 12
        case .wonder: return 60
        case .outpost: return 3
        case .fishTrap: return 4
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
        case .archeryRange, .stable, .blacksmith, .market, .wall, .gate, .tower: return .feudalAge
        case .castle, .siegeWorkshop, .monastery, .dock: return .castleAge
        case .university: return .castleAge
        case .wonder: return .imperialAge
        case .outpost: return .feudalAge
        case .fishTrap: return .feudalAge
        }
    }

    var trainableUnits: [UnitType] {
        switch self {
        case .townCenter: return [.villager]
        case .barracks: return [.militia, .manAtArms, .spearman, .petard]
        case .archeryRange: return [.archer, .crossbowman, .skirmisher, .handCannoneer]
        case .stable: return [.scout, .knight, .lightCavalry, .camelRider]
        case .castle: return [.uniqueUnit]
        case .siegeWorkshop: return [.batteringRam, .mangonel]
        case .monastery: return [.monk]
        case .dock: return [.fishingBoat, .tradeCart, .warGalley, .fireShip]
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
        case .siegeWorkshop: return SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0)
        case .gate: return SKColor(red: 0.55, green: 0.55, blue: 0.55, alpha: 1.0)
        case .monastery: return SKColor(red: 0.6, green: 0.45, blue: 0.55, alpha: 1.0)
        case .dock: return SKColor(red: 0.4, green: 0.45, blue: 0.55, alpha: 1.0)
        case .university: return SKColor(red: 0.45, green: 0.35, blue: 0.55, alpha: 1.0)
        case .wonder: return SKColor(red: 0.75, green: 0.65, blue: 0.4, alpha: 1.0)
        case .outpost: return SKColor(red: 0.5, green: 0.5, blue: 0.45, alpha: 1.0)
        case .fishTrap: return SKColor(red: 0.35, green: 0.5, blue: 0.55, alpha: 1.0)
        }
    }

    var attackDamage: Int {
        switch self {
        case .townCenter: return 5
        case .tower: return 8
        case .castle: return 12
        case .outpost: return 0
        default: return 0
        }
    }

    var attackRange: CGFloat {
        switch self {
        case .townCenter: return 5.0
        case .tower: return 7.0
        case .castle: return 9.0
        case .outpost: return 0
        default: return 0
        }
    }

    var garrisonCapacity: Int {
        switch self {
        case .townCenter: return 15
        case .castle: return 20
        case .tower: return 5
        default: return 0
        }
    }

    var sightRange: Int {
        switch self {
        case .outpost: return 14
        case .tower: return 11
        case .castle: return 10
        default: return 8
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
    var currentResearch: TechType?
    var researchProgress: CGFloat = 0
    var node: SKNode?
    var rallyFlagNode: SKNode?
    var garrisonedUnits: [Int] = []  // unit IDs
    var garrisonCapacity: Int { type.garrisonCapacity }
    var autoReseed: Bool = false
    var smokeNode: SKNode?
    var healthBarNode: SKNode?

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
    case batteringRam
    case mangonel
    case longbowman
    case throwingAxeman
    case mangudai
    case cataphract
    case monk
    case trebuchet
    case fishingBoat
    case tradeCart
    // New units
    case warGalley
    case fireShip
    case petard
    case camelRider
    case handCannoneer
    case samurai
    case warElephant
    case chuKoNu
    case berserk

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
        case .batteringRam: return "Battering Ram"
        case .mangonel: return "Mangonel"
        case .longbowman: return "Longbowman"
        case .throwingAxeman: return "Throwing Axeman"
        case .mangudai: return "Mangudai"
        case .cataphract: return "Cataphract"
        case .monk: return "Monk"
        case .trebuchet: return "Trebuchet"
        case .fishingBoat: return "Fishing Boat"
        case .tradeCart: return "Trade Cart"
        case .warGalley: return "War Galley"
        case .fireShip: return "Fire Ship"
        case .petard: return "Petard"
        case .camelRider: return "Camel Rider"
        case .handCannoneer: return "Hand Cannoneer"
        case .samurai: return "Samurai"
        case .warElephant: return "War Elephant"
        case .chuKoNu: return "Chu-Ko-Nu"
        case .berserk: return "Berserk"
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
        case .batteringRam: return "RM"
        case .mangonel: return "MG"
        case .longbowman: return "LB"
        case .throwingAxeman: return "TA"
        case .mangudai: return "MD"
        case .cataphract: return "CT"
        case .monk: return "MK"
        case .trebuchet: return "TB"
        case .fishingBoat: return "FB"
        case .tradeCart: return "TC"
        case .warGalley: return "WG"
        case .fireShip: return "FS"
        case .petard: return "PT"
        case .camelRider: return "CR"
        case .handCannoneer: return "HC"
        case .samurai: return "SM"
        case .warElephant: return "WE"
        case .chuKoNu: return "CK"
        case .berserk: return "BK"
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
        case .knight: return Resources(food: 60, gold: 90)
        case .lightCavalry: return Resources(food: 80)
        case .uniqueUnit: return Resources(food: 60, gold: 60)
        case .batteringRam: return Resources(food: 0, wood: 160, gold: 75)
        case .mangonel: return Resources(food: 0, wood: 140, gold: 100)
        case .longbowman: return Resources(food: 35, wood: 40, gold: 40)
        case .throwingAxeman: return Resources(food: 60, gold: 50)
        case .mangudai: return Resources(food: 60, wood: 0, gold: 60)
        case .cataphract: return Resources(food: 80, gold: 100)
        case .monk: return Resources(food: 0, gold: 100)
        case .trebuchet: return Resources(food: 0, wood: 200, gold: 200)
        case .fishingBoat: return Resources(food: 0, wood: 75)
        case .tradeCart: return Resources(food: 100, gold: 50)
        case .warGalley: return Resources(food: 0, wood: 135, gold: 60)
        case .fireShip: return Resources(food: 0, wood: 135, gold: 50)
        case .petard: return Resources(food: 65, gold: 20)
        case .camelRider: return Resources(food: 55, gold: 60)
        case .handCannoneer: return Resources(food: 45, gold: 50)
        case .samurai: return Resources(food: 60, gold: 30)
        case .warElephant: return Resources(food: 200, gold: 75)
        case .chuKoNu: return Resources(food: 40, wood: 35, gold: 40)
        case .berserk: return Resources(food: 65, gold: 25)
        }
    }

    var maxHP: Int {
        switch self {
        case .villager: return 25
        case .militia: return 45
        case .manAtArms: return 55
        case .spearman: return 50
        case .archer: return 40
        case .crossbowman: return 45
        case .skirmisher: return 40
        case .scout: return 60
        case .knight: return 85
        case .lightCavalry: return 60
        case .uniqueUnit: return 80
        case .batteringRam: return 200
        case .mangonel: return 70
        case .longbowman: return 40
        case .throwingAxeman: return 60
        case .mangudai: return 65
        case .cataphract: return 100
        case .monk: return 30
        case .trebuchet: return 95
        case .fishingBoat: return 60
        case .tradeCart: return 70
        case .warGalley: return 120
        case .fireShip: return 100
        case .petard: return 25
        case .camelRider: return 70
        case .handCannoneer: return 40
        case .samurai: return 80
        case .warElephant: return 350
        case .chuKoNu: return 45
        case .berserk: return 65
        }
    }

    var attack: Int {
        switch self {
        case .villager: return 3
        case .militia: return 5
        case .manAtArms: return 7
        case .spearman: return 6
        case .archer: return 5
        case .crossbowman: return 6
        case .skirmisher: return 5
        case .scout: return 5
        case .knight: return 10
        case .lightCavalry: return 7
        case .uniqueUnit: return 12
        case .batteringRam: return 2
        case .mangonel: return 16
        case .longbowman: return 6
        case .throwingAxeman: return 8
        case .mangudai: return 7
        case .cataphract: return 12
        case .monk: return 0
        case .trebuchet: return 20
        case .fishingBoat: return 0
        case .tradeCart: return 0
        case .warGalley: return 8
        case .fireShip: return 3
        case .petard: return 30
        case .camelRider: return 6
        case .handCannoneer: return 7
        case .samurai: return 8
        case .warElephant: return 15
        case .chuKoNu: return 4
        case .berserk: return 9
        }
    }

    var defense: Int {
        switch self {
        case .villager: return 0
        case .militia: return 1
        case .manAtArms: return 2
        case .spearman: return 2
        case .archer: return 1
        case .crossbowman: return 1
        case .skirmisher: return 1
        case .scout: return 1
        case .knight: return 3
        case .lightCavalry: return 2
        case .uniqueUnit: return 3
        case .batteringRam: return 3
        case .mangonel: return 0
        case .longbowman: return 0
        case .throwingAxeman: return 2
        case .mangudai: return 1
        case .cataphract: return 5
        case .monk: return 0
        case .trebuchet: return 1
        case .fishingBoat: return 0
        case .tradeCart: return 0
        case .warGalley: return 3
        case .fireShip: return 1
        case .petard: return 0
        case .camelRider: return 2
        case .handCannoneer: return 1
        case .samurai: return 3
        case .warElephant: return 5
        case .chuKoNu: return 1
        case .berserk: return 2
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
        case .batteringRam: return 0.6
        case .mangonel: return 0.6
        case .longbowman: return 0.96
        case .throwingAxeman: return 0.9
        case .mangudai: return 2.5
        case .cataphract: return 1.2
        case .monk: return 0.8
        case .trebuchet: return 0.5
        case .fishingBoat: return 1.2
        case .tradeCart: return 1.0
        case .warGalley: return 1.3
        case .fireShip: return 1.4
        case .petard: return 1.2
        case .camelRider: return 1.4
        case .handCannoneer: return 0.85
        case .samurai: return 1.0
        case .warElephant: return 0.6
        case .chuKoNu: return 0.96
        case .berserk: return 1.1
        }
    }

    var attackRange: CGFloat {
        switch self {
        case .archer: return 5.0
        case .crossbowman: return 5.0
        case .skirmisher: return 4.0
        case .mangonel: return 7.0
        case .trebuchet: return 10.0
        case .longbowman: return 7.0
        case .throwingAxeman: return 3.0
        case .mangudai: return 4.0
        case .warGalley: return 6.0
        case .fireShip: return 2.0
        case .handCannoneer: return 5.0
        case .chuKoNu: return 5.0
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
        case .batteringRam: return 10.0
        case .mangonel: return 12.0
        case .longbowman: return 10.0
        case .throwingAxeman: return 10.0
        case .mangudai: return 10.0
        case .cataphract: return 12.0
        case .monk: return 10.0
        case .trebuchet: return 15.0
        case .fishingBoat: return 8.0
        case .tradeCart: return 10.0
        case .warGalley: return 10.0
        case .fireShip: return 10.0
        case .petard: return 6.0
        case .camelRider: return 8.0
        case .handCannoneer: return 10.0
        case .samurai: return 10.0
        case .warElephant: return 15.0
        case .chuKoNu: return 10.0
        case .berserk: return 10.0
        }
    }

    var requiredAge: Age {
        switch self {
        case .villager, .militia: return .darkAge
        case .manAtArms, .archer, .skirmisher, .scout, .spearman: return .feudalAge
        case .crossbowman, .knight, .lightCavalry: return .castleAge
        case .uniqueUnit: return .castleAge
        case .batteringRam, .mangonel: return .castleAge
        case .longbowman, .throwingAxeman, .mangudai, .cataphract: return .castleAge
        case .monk, .trebuchet: return .castleAge
        case .fishingBoat, .tradeCart: return .castleAge
        case .warGalley, .fireShip: return .castleAge
        case .petard: return .castleAge
        case .camelRider: return .castleAge
        case .handCannoneer: return .imperialAge
        case .samurai, .warElephant: return .castleAge
        case .chuKoNu, .berserk: return .castleAge
        }
    }

    var isCavalry: Bool {
        switch self {
        case .scout, .knight, .lightCavalry, .mangudai, .cataphract, .camelRider, .warElephant: return true
        default: return false
        }
    }

    var bonusVsCavalry: Int {
        switch self {
        case .spearman: return 15
        case .camelRider: return 10
        default: return 0
        }
    }

    var bonusVsRanged: Int {
        switch self {
        case .skirmisher: return 5
        default: return 0
        }
    }

    var isInfantry: Bool {
        switch self {
        case .militia, .manAtArms, .spearman, .throwingAxeman, .samurai, .berserk: return true
        default: return false
        }
    }

    var isSiege: Bool {
        switch self {
        case .batteringRam, .mangonel, .trebuchet: return true
        default: return false
        }
    }

    var isNaval: Bool {
        switch self {
        case .fishingBoat, .tradeCart, .warGalley, .fireShip: return true
        default: return false
        }
    }

    var bonusVsBuilding: Int {
        switch self {
        case .batteringRam: return 40
        case .mangonel: return 15
        case .trebuchet: return 60
        case .petard: return 80
        default: return 0
        }
    }

    var bonusVsNaval: Int {
        switch self {
        case .fireShip: return 15
        default: return 0
        }
    }

    var pierceArmor: Int {
        switch self {
        case .knight, .cataphract: return 2
        case .manAtArms, .spearman: return 1
        case .militia: return 0
        case .batteringRam: return 5
        case .trebuchet: return 1
        case .warGalley: return 3
        case .fireShip: return 2
        case .warElephant: return 4
        case .camelRider: return 1
        case .berserk: return 1
        default: return 0
        }
    }

    var meleeArmor: Int {
        switch self {
        case .knight, .cataphract: return 3
        case .manAtArms: return 2
        case .spearman, .militia: return 1
        case .batteringRam: return 3
        case .trebuchet: return 1
        case .scout, .lightCavalry: return 1
        case .warGalley: return 3
        case .fireShip: return 1
        case .camelRider: return 2
        case .samurai: return 3
        case .warElephant: return 5
        case .berserk: return 2
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
        case .batteringRam: return SKColor(red: 0.5, green: 0.35, blue: 0.2, alpha: 1.0)
        case .mangonel: return SKColor(red: 0.55, green: 0.4, blue: 0.2, alpha: 1.0)
        case .longbowman: return SKColor(red: 0.2, green: 0.5, blue: 0.2, alpha: 1.0)
        case .throwingAxeman: return SKColor(red: 0.6, green: 0.25, blue: 0.25, alpha: 1.0)
        case .mangudai: return SKColor(red: 0.6, green: 0.5, blue: 0.3, alpha: 1.0)
        case .cataphract: return SKColor(red: 0.5, green: 0.45, blue: 0.6, alpha: 1.0)
        case .monk: return SKColor(red: 0.6, green: 0.5, blue: 0.7, alpha: 1.0)
        case .trebuchet: return SKColor(red: 0.5, green: 0.4, blue: 0.25, alpha: 1.0)
        case .fishingBoat: return SKColor(red: 0.3, green: 0.5, blue: 0.6, alpha: 1.0)
        case .tradeCart: return SKColor(red: 0.6, green: 0.55, blue: 0.3, alpha: 1.0)
        case .warGalley: return SKColor(red: 0.3, green: 0.35, blue: 0.55, alpha: 1.0)
        case .fireShip: return SKColor(red: 0.7, green: 0.3, blue: 0.15, alpha: 1.0)
        case .petard: return SKColor(red: 0.65, green: 0.5, blue: 0.2, alpha: 1.0)
        case .camelRider: return SKColor(red: 0.6, green: 0.5, blue: 0.35, alpha: 1.0)
        case .handCannoneer: return SKColor(red: 0.4, green: 0.4, blue: 0.45, alpha: 1.0)
        case .samurai: return SKColor(red: 0.7, green: 0.2, blue: 0.2, alpha: 1.0)
        case .warElephant: return SKColor(red: 0.5, green: 0.45, blue: 0.4, alpha: 1.0)
        case .chuKoNu: return SKColor(red: 0.3, green: 0.45, blue: 0.25, alpha: 1.0)
        case .berserk: return SKColor(red: 0.7, green: 0.25, blue: 0.25, alpha: 1.0)
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
    case attackMoving(to: GridPosition)
    case patrolling(from: GridPosition, to: GridPosition)
    case garrisoned(buildingID: Int)
    case healing(targetUnitID: Int)
    case converting(targetUnitID: Int)
    case guarding(targetUnitID: Int)
    case fishing(tilePos: GridPosition)
    case trading(marketPos: GridPosition, targetMarketPos: GridPosition)
    case repairing(buildingID: Int)
    case collectingRelic(relicPos: GridPosition)
    case autoScouting
}

// MARK: - Unit Stance

enum UnitStance {
    case aggressive  // Auto-attack and chase enemies
    case defensive   // Attack enemies in range, return to anchor if they flee
    case standGround // Don't move, attack only enemies in weapon range
    case noAttack    // Never auto-attack, only move
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
    var bodyNode: SKNode?
    var healthBarNode: SKNode?
    var isSelected: Bool = false
    var lastAttackTime: TimeInterval = 0
    var lastDirection: CGFloat = 0
    var gatherAccumulator: CGFloat = 0
    var attackMoveDestination: GridPosition?
    var savedMoveDestination: GridPosition?
    var patrolPoints: (GridPosition, GridPosition)?
    var killCount: Int = 0
    var stance: UnitStance = .aggressive
    var stanceAnchorPosition: GridPosition?
    var guardTargetID: Int?
    var commandQueue: [(UnitState, GridPosition?)] = []
    var controlGroup: Int?
    var conversionProgress: CGFloat = 0
    var healCooldown: CGFloat = 0
    var tradeGold: Int = 0
    var hasRelic: Bool = false
    var autoScoutIndex: Int = 0
    var isExploding: Bool = false  // For petard
    var velocity: CGPoint = .zero
    var targetVelocity: CGPoint = .zero
    var dustTimer: CGFloat = 0  // Timer for movement dust particles
    var isPackedSiege: Bool = false  // Trebuchets must unpack to fire
    var packTimer: CGFloat = 0
    var tilesMoved: CGFloat = 0  // Track distance moved for charge bonus
    weak var ownerPlayer: Player?

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

    var veterancyLevel: Int {
        if killCount >= 5 { return 2 }
        if killCount >= 3 { return 1 }
        return 0
    }

    var effectiveAttack: Int {
        var atk = type.attack
        guard let techs = ownerPlayer?.researchedTechs else { return atk + min(veterancyLevel, 2) }

        if type.isInfantry || type.isCavalry {
            // Melee attack upgrades
            if techs.contains(.forging) { atk += 1 }
            if techs.contains(.ironCasting) { atk += 1 }
        }
        if type.isRanged {
            // Ranged attack upgrades
            if techs.contains(.fletching) { atk += 1 }
            if techs.contains(.bodkinArrow) { atk += 1 }
        }
        atk += min(veterancyLevel, 2)
        return atk
    }

    var effectiveDefense: Int {
        var def = type.defense
        guard let techs = ownerPlayer?.researchedTechs else { return def }

        if type.isInfantry {
            if techs.contains(.scaleMailArmor) { def += 1 }
            if techs.contains(.chainMailArmor) { def += 1 }
        }
        if type.isCavalry {
            if techs.contains(.scaleBardingArmor) { def += 1 }
            if techs.contains(.chainBardingArmor) { def += 1 }
        }
        if type.isRanged {
            if techs.contains(.paddedArcherArmor) { def += 1 }
            if techs.contains(.leatherArcherArmor) { def += 1 }
        }
        if type == .villager && techs.contains(.loom) {
            def += 1
        }
        if veterancyLevel >= 2 { def += 1 }
        return def
    }

    var effectiveAttackRange: CGFloat {
        var range = type.attackRange
        // Siege Engineers: +1 range for siege
        if type.isSiege, let techs = ownerPlayer?.researchedTechs, techs.contains(.siegeEngineers) {
            range += 1.0
        }
        // Briton archer range bonus
        if type.isRanged, let civ = ownerPlayer?.civilization {
            range *= civ.archerRangeBonus
        }
        return range
    }

    func bonusDamage(against target: Unit) -> Int {
        var bonus = 0
        if target.type.isCavalry {
            bonus += type.bonusVsCavalry
        }
        if target.type.isRanged {
            bonus += type.bonusVsRanged
        }
        return bonus
    }
}

// MARK: - Map Type

enum MapType: String, CaseIterable {
    case standard
    case islands
    case rivers
    case arena
    case blackForest
    case goldRush

    var displayName: String {
        switch self {
        case .standard: return "Standard"
        case .islands: return "Islands"
        case .rivers: return "Rivers"
        case .arena: return "Arena"
        case .blackForest: return "Black Forest"
        case .goldRush: return "Gold Rush"
        }
    }

    var description: String {
        switch self {
        case .standard: return "Classic balanced map"
        case .islands: return "Large water body, land islands"
        case .rivers: return "Rivers divide map into quadrants"
        case .arena: return "Walled-in starting positions"
        case .blackForest: return "Dense forests with narrow paths"
        case .goldRush: return "Gold concentrated in the center"
        }
    }

    var icon: String {
        switch self {
        case .standard: return "\u{1F30D}"
        case .islands: return "\u{1F3DD}\u{FE0F}"
        case .rivers: return "\u{1F30A}"
        case .arena: return "\u{1F3DF}\u{FE0F}"
        case .blackForest: return "\u{1F332}"
        case .goldRush: return "\u{1FA99}"
        }
    }
}

enum MapSize: String, CaseIterable {
    case small
    case medium
    case large

    var displayName: String {
        switch self {
        case .small: return "Small"
        case .medium: return "Medium"
        case .large: return "Large"
        }
    }

    var description: String {
        switch self {
        case .small: return "60x60 - Quick games"
        case .medium: return "80x80 - Balanced"
        case .large: return "100x100 - Epic battles"
        }
    }

    var dimensions: (width: Int, height: Int) {
        switch self {
        case .small: return (60, 60)
        case .medium: return (80, 80)
        case .large: return (100, 100)
        }
    }
}

// MARK: - Game State

enum GameState {
    case playing
    case paused
    case victory
    case defeat
}

// MARK: - Victory Condition

enum VictoryCondition {
    case conquest     // Destroy all enemy buildings
    case wonder       // Build wonder, hold for 200 seconds
    case relic        // Collect all relics, hold for 200 seconds
}

// MARK: - Relic

class Relic {
    static var nextID: Int = 0
    let id: Int
    var gridPosition: GridPosition
    var isCollected: Bool = false
    var collectedByPlayerID: Int?
    var node: SKNode?

    init(position: GridPosition) {
        self.id = Relic.nextID
        Relic.nextID += 1
        self.gridPosition = position
    }
}

// MARK: - Day/Night Cycle

enum TimeOfDay {
    case dawn
    case day
    case dusk
    case night

    var ambientAlpha: CGFloat {
        switch self {
        case .dawn: return 0.1
        case .day: return 0.0
        case .dusk: return 0.15
        case .night: return 0.35
        }
    }

    var ambientColor: SKColor {
        switch self {
        case .dawn: return SKColor(red: 1.0, green: 0.8, blue: 0.5, alpha: 1.0)
        case .day: return .clear
        case .dusk: return SKColor(red: 1.0, green: 0.5, blue: 0.3, alpha: 1.0)
        case .night: return SKColor(red: 0.1, green: 0.1, blue: 0.3, alpha: 1.0)
        }
    }
}

// MARK: - Deer Herd

class DeerHerd {
    var gridPosition: GridPosition
    var foodRemaining: Int = 200
    var node: SKNode?
    var wanderTimer: CGFloat = 0

    init(position: GridPosition) {
        self.gridPosition = position
    }
}

// MARK: - Action Mode

enum ActionMode {
    case normal
    case placingBuilding(BuildingType)
    case attackMove
    case settingRallyPoint(Building)
    case settingPatrol
    case guardMode
}
