import Foundation

enum TechType: String, CaseIterable {
    case loom
    case wheelbarrow
    case handCart
    case doubleBitAxe
    case bowSaw
    case horseCollar
    case heavyPlow
    case goldMining
    case stoneMining
    case fletching
    case bodkinArrow
    case forging
    case ironCasting
    case scaleMailArmor
    case chainMailArmor
    case scaleBardingArmor
    case chainBardingArmor
    case paddedArcherArmor
    case leatherArcherArmor
    case ballistics
    case bloodlines

    var displayName: String {
        switch self {
        case .loom: return "Loom"
        case .wheelbarrow: return "Wheelbarrow"
        case .handCart: return "Hand Cart"
        case .doubleBitAxe: return "Double-Bit Axe"
        case .bowSaw: return "Bow Saw"
        case .horseCollar: return "Horse Collar"
        case .heavyPlow: return "Heavy Plow"
        case .goldMining: return "Gold Mining"
        case .stoneMining: return "Stone Mining"
        case .fletching: return "Fletching"
        case .bodkinArrow: return "Bodkin Arrow"
        case .forging: return "Forging"
        case .ironCasting: return "Iron Casting"
        case .scaleMailArmor: return "Scale Mail"
        case .chainMailArmor: return "Chain Mail"
        case .scaleBardingArmor: return "Scale Barding"
        case .chainBardingArmor: return "Chain Barding"
        case .paddedArcherArmor: return "Padded Armor"
        case .leatherArcherArmor: return "Leather Armor"
        case .ballistics: return "Ballistics"
        case .bloodlines: return "Bloodlines"
        }
    }

    var cost: Resources {
        switch self {
        case .loom: return Resources(food: 0, gold: 50)
        case .wheelbarrow: return Resources(food: 175, wood: 50)
        case .handCart: return Resources(food: 300, wood: 200)
        case .doubleBitAxe: return Resources(food: 100, wood: 50)
        case .bowSaw: return Resources(food: 150, wood: 100)
        case .horseCollar: return Resources(food: 75, wood: 75)
        case .heavyPlow: return Resources(food: 125, wood: 125)
        case .goldMining: return Resources(food: 100, wood: 75)
        case .stoneMining: return Resources(food: 100, wood: 75)
        case .fletching: return Resources(food: 100, gold: 50)
        case .bodkinArrow: return Resources(food: 200, gold: 100)
        case .forging: return Resources(food: 150)
        case .ironCasting: return Resources(food: 220, gold: 120)
        case .scaleMailArmor: return Resources(food: 100)
        case .chainMailArmor: return Resources(food: 200, gold: 100)
        case .scaleBardingArmor: return Resources(food: 150)
        case .chainBardingArmor: return Resources(food: 250, gold: 150)
        case .paddedArcherArmor: return Resources(food: 100)
        case .leatherArcherArmor: return Resources(food: 150, gold: 150)
        case .ballistics: return Resources(food: 0, wood: 300, gold: 175)
        case .bloodlines: return Resources(food: 150, gold: 100)
        }
    }

    var requiredAge: Age {
        switch self {
        case .loom: return .darkAge
        case .wheelbarrow, .doubleBitAxe, .horseCollar, .goldMining, .stoneMining,
             .fletching, .forging, .scaleMailArmor, .scaleBardingArmor, .paddedArcherArmor,
             .bloodlines:
            return .feudalAge
        case .handCart, .bowSaw, .heavyPlow, .bodkinArrow, .ironCasting, .chainMailArmor,
             .chainBardingArmor, .leatherArcherArmor, .ballistics:
            return .castleAge
        }
    }

    var researchedAt: BuildingType {
        switch self {
        case .loom, .wheelbarrow, .handCart: return .townCenter
        case .doubleBitAxe, .bowSaw: return .lumberCamp
        case .horseCollar, .heavyPlow: return .miningCamp
        case .goldMining, .stoneMining: return .miningCamp
        case .fletching, .bodkinArrow, .paddedArcherArmor, .leatherArcherArmor, .ballistics: return .blacksmith
        case .forging, .ironCasting, .scaleMailArmor, .chainMailArmor,
             .scaleBardingArmor, .chainBardingArmor: return .blacksmith
        case .bloodlines: return .stable
        }
    }

    var researchTime: CGFloat {
        switch self {
        case .loom: return 8
        case .wheelbarrow, .doubleBitAxe, .horseCollar, .goldMining, .stoneMining,
             .fletching, .forging, .scaleMailArmor, .scaleBardingArmor, .paddedArcherArmor,
             .bloodlines:
            return 12
        default: return 18
        }
    }
}

class TechTree {
    func availableTechs(for player: Player) -> [TechType] {
        TechType.allCases.filter { tech in
            !player.researchedTechs.contains(tech) &&
            player.currentAge.rawValue >= tech.requiredAge.rawValue &&
            player.canAfford(tech.cost)
        }
    }

    func research(tech: TechType, player: Player) -> Bool {
        guard !player.researchedTechs.contains(tech) else { return false }
        guard player.canAfford(tech.cost) else { return false }
        guard player.currentAge.rawValue >= tech.requiredAge.rawValue else { return false }

        player.spend(tech.cost)
        player.researchedTechs.insert(tech)
        return true
    }
}
