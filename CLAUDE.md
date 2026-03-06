# CLAUDE.md — Realm of Empires

## Project Overview

Realm of Empires is an Age of Empires-style real-time strategy (RTS) game for iOS, built entirely in Swift using SwiftUI (menus) and SpriteKit (gameplay). It features resource gathering, base building, unit training, combat, tech research, fog of war, and an AI opponent.

## Repository Structure

```
Testing-Grounds/
├── AgeOfEmpiresClone/             # Primary source code (16 Swift files + assets)
│   ├── AgeOfEmpiresCloneApp.swift # @main app entry point
│   ├── ContentView.swift          # SwiftUI menu & game container
│   ├── GameScene.swift            # SpriteKit game loop & system coordination
│   ├── GameModels.swift           # Core data models (Units, Buildings, Resources, Players)
│   ├── UnitSystem.swift           # Unit movement, selection, state machine
│   ├── BuildingSystem.swift       # Construction, training queues, population
│   ├── ResourceSystem.swift       # Villager gathering, drop-off, farm automation
│   ├── CombatSystem.swift         # Attack mechanics, damage, death handling
│   ├── Pathfinding.swift          # A* pathfinding on 80x80 grid
│   ├── GameMap.swift              # Procedural terrain & resource generation
│   ├── FogOfWar.swift             # Visibility, exploration tracking, fog rendering
│   ├── TechTree.swift             # 21 technologies, age progression, bonuses
│   ├── AIOpponent.swift           # AI strategy, economy, military decisions
│   ├── HUDOverlay.swift           # Resource bar, minimap, build/info panels
│   ├── SpriteComponents.swift     # Sprite creation, effects, shadows
│   ├── MainMenuScene.swift        # Placeholder (menus handled via SwiftUI)
│   └── Assets.xcassets/           # App icon, accent color
├── AgeOfEmpiresClone.xcodeproj/   # Xcode project configuration
│   └── project.pbxproj
└── RealmOfEmpires.swiftpm/        # Swift Playgrounds / SPM package version
    ├── Package.swift              # SPM manifest (iOS 17.0+, swift-tools 5.9)
    └── Sources/                   # Duplicated source files for SPM target
```

The project has two build targets that share the same source files:
- **Xcode project** (`AgeOfEmpiresClone.xcodeproj`) — standard iOS app build
- **Swift Package** (`RealmOfEmpires.swiftpm`) — Swift Playgrounds compatible

## Architecture

```
ContentView (SwiftUI) → GameScene (SpriteKit)
    ├── GameMap          — 80x80 tile grid, terrain, resources
    ├── Players[]        — Human + 1 AI opponent
    └── Systems (updated each frame):
        ├── UnitSystem       — movement, pathfinding, state
        ├── BuildingSystem   — construction, training
        ├── ResourceSystem   — gathering, drop-off
        ├── CombatSystem     — damage, death
        ├── FogOfWar         — visibility
        └── AIOpponent       — strategic decisions
```

`GameScene` is the central coordinator — all systems hold a `weak var gameScene: GameScene?` reference and are updated each frame via `update(_ currentTime:)`.

## Tech Stack

- **Language:** Swift (100%)
- **Frameworks:** SwiftUI, SpriteKit (no external dependencies)
- **Min Platform:** iOS 17.0
- **Swift Tools:** 5.9
- **Orientation:** Landscape only

## Code Conventions

### Naming
- **Types** (classes, structs, enums): `PascalCase` — `GameScene`, `GridPosition`, `UnitType`
- **Enum cases**: `camelCase` — `UnitType.villager`, `Age.darkAge`
- **Functions/properties**: `camelCase` — `updateStrategy()`, `carriedAmount`

### Patterns
- `// MARK: - Section Name` used extensively for code organization
- `weak var` references from systems back to `GameScene` to avoid retain cycles
- Classes for mutable game entities (`Unit`, `Building`, `Player`); structs for value types (`GridPosition`, `Resources`, `PathNode`)
- Factory pattern: `SpriteFactory` for visual creation
- State machine: `UnitState` enum drives unit behavior
- Enum extensions for computed properties (display names, costs, bonuses)

### File Organization
- Each system lives in its own file (e.g., `CombatSystem.swift`)
- Data models are consolidated in `GameModels.swift`
- Keep related logic together; avoid splitting a system across multiple files

## Development Notes

### Building
- Open `AgeOfEmpiresClone.xcodeproj` in Xcode, or open `RealmOfEmpires.swiftpm` in Swift Playgrounds on iPad
- No external dependencies to install — builds with Apple frameworks only
- Target device: iPad (primary), iPhone (supported)

### Testing
- No test suite exists. Manual testing on simulator or device is the current workflow.

### Key Game Constants
- Map size: 80x80 grid (`GameMap`)
- Civilizations: Britons, Franks, Mongols, Byzantines
- Ages: Dark Age → Feudal → Castle → Imperial
- Resources: Food, Wood, Gold, Stone
- Unit types: 11 (Villager + 10 military)
- Building types: 13 (Town Center, Barracks, farms, towers, etc.)
- Technologies: 21 researchable upgrades

### When Modifying Code
- Changes to source files in `AgeOfEmpiresClone/` should be mirrored in `RealmOfEmpires.swiftpm/Sources/` (or vice versa) to keep both targets in sync
- Adding new `.swift` files requires updating `project.pbxproj` (via Xcode) and the SPM `Sources/` directory
- Game balance values (costs, damage, HP, gather rates) are defined inline in `GameModels.swift` and system files — search for the relevant enum/struct extensions
