# Rebus Puzzle App - Development Handoff Document

## Project Overview

A nighttime-themed rebus puzzle mobile app for iOS. Players solve visual word puzzles by combining icons that represent sounds, words, or concepts. Positioned as a relaxing, pre-sleep casual game with a fantasy aesthetic.

**Target Platform:** iOS (SwiftUI)
**Monetization:** Rewarded video ads + in-app currency (no banner ads)
**Core Loop:** Solve rebus puzzles → earn currency → unlock cosmetics/hints

---

## Visual Identity

### Aesthetic Direction
- **Style:** Fantasy/whimsical with ornate, jeweled icon art
- **Color Palette:** Deep blues, teals, purples, gold accents
- **Backgrounds:** Illustrated fantasy environments (enchanted forests, starlit scenes)
- **Icons:** AI-generated assets with consistent gold-framed, luminous style
- **UI Elements:** Glowing effects, soft edges, magical particle effects

### Key Visual References
- Puzzle icons: Ornate, gold-trimmed, jewel-like illustrations on neutral backgrounds
- Backgrounds: Enchanted forest with bioluminescent mushrooms, fireflies, mystical lighting
- Letter wheel: Circular with glow effect, mossy/organic texture integration
- Typography: Elegant serif for headers (Cinzel-style), clean sans-serif for UI

---

## Core Gameplay Mechanics

### Puzzle Structure
Each puzzle displays 2+ icons with a plus sign between them. Player deciphers what each icon represents and combines them to form the answer word.

**Example:** 🌙 + 💡 = MOONLIGHT (moon + light)

### Logic Types (Difficulty Progression)

| Type | Description | Example | Difficulty |
|------|-------------|---------|------------|
| `compound_word` | Two words combine directly | butter + fly = BUTTERFLY | Easy |
| `syllable_smash` | Icons represent syllables | car + pet = CARPET | Easy |
| `letter_sound` | Single letter sound | B + hive = BEEHIVE | Easy |
| `homophone` | Icon sounds like target word | knight + mare = NIGHTMARE | Medium |
| `symbol_sub` | Icon substitutes phonetically | eye + land = ISLAND | Medium |
| `number_sub` | Number sounds like syllable | 4 + tune = FORTUNE | Medium |
| `visual_position` | Spatial arrangement matters | "ROAD" with wide D = BROADWAY | Hard |
| `subtraction` | Remove letters indicated | sand − d = SAN | Hard |
| `reversal` | Backwards reading | reversed "STOP" = POTS | Hard |

### Fairness Guardrails

1. **Context Tag (Mandatory):** Every puzzle displays a hint category above the icons (e.g., "Something You See at Night", "A Sea Creature"). This constrains the semantic search space.

2. **Post-Solve Explanation:** After completion, show breakdown card explaining the logic (e.g., "Moon (crescent moon) + Light (lightbulb) = Moonlight")

3. **Anchor Letters:** Difficult puzzles can pre-fill 1-2 letters in answer slots (not first letter) to provide scaffolding.

### Input Mechanics

- **Letter Wheel:** Circular arrangement of letters at bottom of screen
- **Swipe to Select:** Player traces path through letters to spell answer
- **Shuffle Button:** Rearrange letter positions
- **Hint Button:** Spend currency to reveal letter or explain icon

**Constraints:**
- Maximum answer length: 10 letters
- Maximum distractor letters: 3-4
- Wheel shows answer letters + distractors only

### Feedback System

| Input | Response |
|-------|----------|
| Correct answer | Celebration animation, star completes, currency awarded |
| Valid word but wrong | Letters wiggle, soft thud sound, fade back to wheel |
| Invalid letter sequence | No response (letters don't connect) |

---

## Progression System: Constellation Map

### Hierarchy

```
GALAXY (Meta-Category)
  └── CONSTELLATION (Theme Pack, 10 puzzles each)
        └── STAR (Individual Puzzle)
```

### Example Structure

```
🌌 NATURE GALAXY
    ├── 🌲 Forest Constellation (10 puzzles)
    ├── 🌊 Ocean Constellation (10 puzzles)
    └── 🌸 Garden Constellation (10 puzzles)

🏙️ URBAN GALAXY
    ├── 🍳 Kitchen Constellation
    ├── 🛋️ Living Room Constellation
    └── 🚗 Traffic Constellation
```

### Progression Rules

- Complete 7/10 stars to "finish" a constellation (allows skipping frustrating puzzles)
- Finishing a constellation unlocks adjacent constellations
- Galaxies unlock sequentially
- First constellation in each galaxy teaches new logic types
- Stars within constellation connected visually; must complete adjacent star to unlock next

### Visual Representation

- Night sky background with nebula effects
- Stars connected by glowing lines (constellation pattern)
- Completed stars: Gold glow
- Current/available stars: Cyan pulse
- Locked stars: Dim gray
- Locked constellations: Dashed circle with icon

---

## Data Models

### Puzzle JSON Schema

```json
{
  "puzzle_id": "nature_forest_007",
  "theme": "forest",
  "galaxy": "nature",
  "context_tag": "Something You See at Night",
  "background": "enchanted_forest_01.png",
  
  "icons": [
    { "image": "moon_crescent.png", "represents": "MOON" },
    { "image": "lightbulb.png", "represents": "LIGHT" }
  ],
  
  "answer": "MOONLIGHT",
  "letters": ["M", "O", "O", "N", "L", "I", "G", "H", "T"],
  "distractor_letters": ["S", "E", "A", "R"],
  
  "difficulty": 2,
  "anchor_letters": [],
  
  "explanation": {
    "breakdown": "Moon (crescent moon) + Light (lightbulb) = Moonlight",
    "logic_type": "compound_word"
  }
}
```

### Galaxy/Constellation JSON Schema

```json
{
  "galaxy_id": "nature",
  "galaxy_name": "Nature",
  "unlock_requirement": null,
  "constellations": [
    {
      "constellation_id": "forest",
      "constellation_name": "Forest",
      "icon": "🌲",
      "unlock_requirement": null,
      "puzzles_to_complete": 7,
      "puzzle_ids": ["nature_forest_001", "nature_forest_002"],
      "star_positions": [
        { "puzzle_id": "nature_forest_001", "x": 120, "y": 80 },
        { "puzzle_id": "nature_forest_002", "x": 180, "y": 140 }
      ],
      "connections": [[1, 2], [2, 3], [2, 4]]
    }
  ]
}
```

### Player Progress Model

```json
{
  "completed_puzzles": ["nature_forest_001", "nature_forest_002"],
  "current_puzzle": "nature_forest_008",
  "currency": 1250,
  "unlocked_constellations": ["forest"],
  "unlocked_galaxies": ["nature"],
  "unlocked_soundscapes": ["quiet_night"],
  "unlocked_themes": ["chalk_default"],
  "hints_used": 12,
  "total_puzzles_solved": 47
}
```

---

## Economy & Monetization

### Currency: "Moonstones"

**Earning:**
- Solve puzzle: 10-30 moonstones (based on difficulty)
- Complete constellation: 100 moonstone bonus
- Daily puzzle: 50 moonstones
- Watch rewarded video: 50 moonstones

**Spending:**

| Item | Cost | Effect |
|------|------|--------|
| Reveal Letter | 25 | Shows one letter in answer |
| Explain Icon | 50 | Tooltip explains what icon represents |
| Skip Puzzle | 100 | Mark as complete, move on |
| Soundscape | 500 | Unlock ambient audio track |
| Visual Theme | 750 | Change icon art style |
| Sticker Frame | 200 | Cosmetic for collection book |

### Ad Strategy

- **Rewarded Video:** Opt-in for currency (primary monetization)
- **Interstitial:** Only after completing entire constellation (every 10 puzzles)
- **No Banner Ads:** Preserves relaxation aesthetic

---

## Audio Design

### Ambient Soundscapes (Unlockable)
- Quiet Night (default): Soft crickets
- Rain on Roof
- Distant Train
- Library Fireplace
- Cat Purring
- Ocean Waves

### Sound Effects
- Letter selection: Soft chime
- Correct answer: Gentle celebration melody
- Wrong word: Dull thud (not harsh buzzer)
- Star completion: Magical shimmer
- Constellation complete: Orchestral swell

### Design Principles
- No high-pitched sounds
- All audio should support relaxation
- Haptic feedback on letter wheel (subtle, fluid)

---

## UI Layout (Puzzle Screen)

```
┌─────────────────────────────────┐
│      CONTEXT TAG (hint)         │  ← "Something You See at Night"
├─────────────────────────────────┤
│                                 │
│   ┌─────────────────────────┐   │
│   │   ICON  +  ICON  +  ... │   │  ← Puzzle images on neutral bg
│   └─────────────────────────┘   │
│                                 │
│       □ □ □ □ □ □ □ □ □         │  ← Answer slots
│                                 │
│    [Shuffle]  ◯ LETTER ◯  [Hint]│
│              ◯ WHEEL  ◯         │  ← Circular letter input
│               ◯  ◯  ◯           │
│                                 │
│   [Level] [Currency] [Gift/Ad]  │  ← Bottom UI elements
└─────────────────────────────────┘
```

---

## Xcode Project Structure

```
Rebus/
├── RebusApp.swift
├── Models/
│   ├── Puzzle.swift
│   ├── Constellation.swift
│   ├── Galaxy.swift
│   └── PlayerProgress.swift
├── Views/
│   ├── Game/
│   │   ├── PuzzleView.swift
│   │   ├── LetterWheelView.swift
│   │   ├── AnswerSlotsView.swift
│   │   └── IconDisplayView.swift
│   ├── Map/
│   │   ├── GalaxyMapView.swift
│   │   ├── ConstellationMapView.swift
│   │   └── StarNodeView.swift
│   ├── Components/
│   │   ├── ContextTagView.swift
│   │   ├── HintButtonView.swift
│   │   └── CurrencyDisplayView.swift
│   └── Screens/
│       ├── MainMenuView.swift
│       ├── SettingsView.swift
│       └── CollectionView.swift
├── ViewModels/
│   ├── PuzzleViewModel.swift
│   ├── ProgressViewModel.swift
│   └── EconomyViewModel.swift
├── Services/
│   ├── PuzzleLoader.swift
│   ├── ProgressManager.swift
│   ├── AudioManager.swift
│   └── AdManager.swift
├── Data/
│   ├── puzzles.json
│   ├── galaxies.json
│   └── store_items.json
├── Resources/
│   ├── Backgrounds/
│   ├── Icons/
│   ├── Audio/
│   └── Fonts/
└── Utilities/
    ├── Constants.swift
    └── Extensions.swift
```

---

## Development Priorities

### Phase 1: Core Loop
1. Data models (Puzzle, Constellation, Galaxy)
2. JSON loading system
3. Basic puzzle view with static icons
4. Letter wheel with swipe-to-select
5. Answer validation

### Phase 2: Progression
1. Constellation map visualization
2. Star/puzzle unlocking logic
3. Player progress persistence (UserDefaults or Core Data)
4. Galaxy navigation

### Phase 3: Polish
1. Animations (star completion, letter selection)
2. Audio integration
3. Haptic feedback
4. Visual themes

### Phase 4: Economy
1. Currency system
2. Hint functionality
3. Rewarded video ad integration
4. Store UI

### Phase 5: Content
1. Puzzle content pipeline
2. AI asset generation workflow
3. 50+ puzzles across multiple constellations
4. Beta testing for difficulty calibration

---

## Key Design Decisions Made

1. **No timers** - Never punish player for being slow
2. **Context tags mandatory** - Reduce frustration by constraining search space
3. **7/10 completion threshold** - Allow skipping without blocking progress
4. **10-letter max** - Keep letter wheel usable
5. **No banner ads** - Protect relaxation aesthetic
6. **Fantasy visual style** - Committed to ornate/jeweled over minimal/chalk
7. **Themed backgrounds per constellation** - Reinforce category identity
8. **Post-solve explanations** - Turn confusion into learning

---

## Open Questions for Development

1. Core Data vs UserDefaults for progress persistence?
2. SpriteKit vs pure SwiftUI for constellation map animations?
3. How to handle iCloud sync for cross-device progress?
4. Accessibility considerations (VoiceOver for visual puzzles)?
5. Localization strategy (puzzles are language-dependent)?

---

## Assets Created

- Constellation map React mockup (reference for SwiftUI implementation)
- Sample puzzle mockups (enchanted forest theme)
- Test icons: moon, lightbulb, star, fish, butter, fly

---

## Contact/Context

This handoff is from a brainstorming session covering:
- Core concept validation
- Frustration vs. relaxation design tension
- Visual style exploration
- Progression system architecture
- Economy design
- Technical data modeling

The app is in early prototyping. No code written yet. Ready to begin Xcode project setup and Phase 1 development.
