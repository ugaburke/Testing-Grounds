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
    case redemption    // Monks convert buildings
    case fervor        // Monks move faster
    case sanctity      // Monks +50% HP
    case conscription  // Units train 33% faster
    case murder_holes  // Buildings no min range
    case sappers       // Infantry +15 vs buildings

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
        case .redemption: return "Redemption"
        case .fervor: return "Fervor"
        case .sanctity: return "Sanctity"
        case .conscription: return "Conscription"
        case .murder_holes: return "Murder Holes"
        case .sappers: return "Sappers"
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
        case .redemption: return Resources(food: 0, gold: 150)
        case .fervor: return Resources(food: 0, gold: 100)
        case .sanctity: return Resources(food: 0, gold: 120)
        case .conscription: return Resources(food: 150, gold: 150)
        case .murder_holes: return Resources(food: 200, stone: 100)
        case .sappers: return Resources(food: 400, gold: 200)
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
        case .redemption, .fervor, .sanctity: return .castleAge
        case .conscription, .murder_holes, .sappers: return .imperialAge
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
        case .redemption, .fervor, .sanctity: return .monastery
        case .conscription: return .castle
        case .murder_holes: return .castle
        case .sappers: return .castle
        }
    }

    var icon: String {
        switch self {
        case .loom: return "🧵"
        case .wheelbarrow: return "🛒"
        case .handCart: return "🛞"
        case .doubleBitAxe, .bowSaw: return "🪓"
        case .horseCollar, .heavyPlow: return "🌾"
        case .goldMining: return "⛏"
        case .stoneMining: return "🪨"
        case .fletching, .bodkinArrow: return "🏹"
        case .forging, .ironCasting: return "⚔"
        case .scaleMailArmor, .chainMailArmor: return "🛡"
        case .scaleBardingArmor, .chainBardingArmor: return "🐴"
        case .paddedArcherArmor, .leatherArcherArmor: return "🎯"
        case .ballistics: return "💥"
        case .bloodlines: return "❤"
        case .redemption: return "✝"
        case .fervor: return "🏃"
        case .sanctity: return "💛"
        case .conscription: return "📯"
        case .murder_holes: return "🕳"
        case .sappers: return "⛏"
        }
    }

    var effectDescription: String {
        switch self {
        case .loom: return "+1 Villager DEF, +15 HP"
        case .wheelbarrow: return "+10% Speed, +5 Carry"
        case .handCart: return "+10% Speed, +5 Carry"
        case .doubleBitAxe: return "+20% Wood Gather"
        case .bowSaw: return "+20% Wood Gather"
        case .horseCollar: return "+25% Farm Gather"
        case .heavyPlow: return "+25% Farm Gather"
        case .goldMining: return "+15% Gold Gather"
        case .stoneMining: return "+15% Stone Gather"
        case .fletching: return "+1 Ranged ATK"
        case .bodkinArrow: return "+1 Ranged ATK"
        case .forging: return "+1 Melee ATK"
        case .ironCasting: return "+1 Melee ATK"
        case .scaleMailArmor: return "+1 Infantry DEF"
        case .chainMailArmor: return "+1 Infantry DEF"
        case .scaleBardingArmor: return "+1 Cavalry DEF"
        case .chainBardingArmor: return "+1 Cavalry DEF"
        case .paddedArcherArmor: return "+1 Archer DEF"
        case .leatherArcherArmor: return "+1 Archer DEF"
        case .ballistics: return "Improved Accuracy"
        case .bloodlines: return "+20 Cavalry HP"
        case .redemption: return "Monks convert buildings"
        case .fervor: return "+15% Monk speed"
        case .sanctity: return "+50% Monk HP"
        case .conscription: return "Units train 33% faster"
        case .murder_holes: return "No minimum attack range"
        case .sappers: return "+15 Infantry vs buildings"
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
