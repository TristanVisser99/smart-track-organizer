# Smart Track Organizer Pro

**Smart Track Organizer Pro** is a modern DAW session organization suite for Cockos REAPER. It automatically classifies, formats, color-codes, sorts, and groups tracks using an industry-standard production lexicon and an interactive pure-Lua studio dashboard.

Built with a clean 3-layer architecture, 100% self-contained pure Lua, bundled RTK (REAPER Toolkit), and zero external binary dependencies.

![Smart Track Organizer Pro Dashboard](docs/assets/screenshot.png)



---

## Authors

- **Tristan** (27933024)
- **Rahul** (28259882)



---

## Key Features

- **Context-Aware Classification Engine**:
  - Over 150+ stems and shorthand terms recognized across 11 professional studio categories (Drums, Bass, Vocals, Guitars, Keys, Synths, Strings, Brass & Winds, FX, Mix Buses & Aux Returns, Reference).
- **FX-Chain Inspection Clues**:
  - Resolves ambiguous track names (such as `Audio 01`, `Track 05`) by inspecting loaded VST/AU instruments and plugins (e.g. Serum, Superior Drummer, Kontakt, Guitar Rig, Melodyne, Omnisphere).
- **5 Studio Color Palettes**:
  - *Modern Studio*: Vibrant, high-contrast dark theme.
  - *Pastel Soft*: Gentle, low-fatigue studio palette.
  - *Vintage Console*: Inspired by classic SSL and Neve desk channels.
  - *Cyber Neon*: Vivid, modern synthwave styling.
  - *Monochrome Slate*: Sleek, minimalist grayscale workflow.
- **Audio Engineering Technical Acronym Preservation**:
  - Cleans up messy stem names while strictly preserving critical engineering markers (`DI`, `FX`, `EQ`, `MIDI`, `BGV`, `DBL`, `NY`, `VCA`, `L`, `R`, `OH`, `SUB`, `RMS`).
- **Interactive Pure-Lua Studio Dashboard**:
  - Modern dark glass aesthetic with rounded corners, real-time live search, animated focus borders, and instant live preview rows.
- **Multi-Strategy Sorting**:
  - *Studio Mix Order*: Drums -> Bass -> Guitars -> Keys -> Synths -> Vocals -> FX -> Buses.
  - *Vocal-First Flow*: Vocals -> Drums -> Bass -> Instruments -> FX -> Buses.
  - *Alphabetical (A-Z)*: Clean alphabetical sorting by cleaned stem label.
  - *Original Project Order*: Preserves existing track arrangement while applying colors and formatting.
- **Folder Hierarchy Automation**:
  - Automatically generates parent folder tracks (`STO - Drums`, `STO - Vocals`, etc.) with correct REAPER folder depth calculations.
- **Selective Per-Track Toggle & Search**:
  - Individual track checkboxes, a master select-all toggle, and an instant search filter.
- **Atomic Undo & Redo Integration**:
  - Single-step undo (`Ctrl+Z` / `Cmd+Z`) safely restores your session without corrupting routing, sends, or existing folders, with instant redo (`Ctrl+Shift+Z` / `Cmd+Shift+Z`).


---

## Studio Categories & Color Palette

Smart Track Organizer Pro automatically groups and colors tracks into 12 dedicated studio categories using calibrated HSL color harmonies:

| Category | Prefix | Default Color (Modern Studio) | Description & Stems Included |
| :--- | :---: | :---: | :--- |
| **Drums** | `DRM` | `#E0564C` (Coral Red) | Kick, Snare, Hi-Hats, Toms, Overheads, Room, Claps, Cymbals, Percussion |
| **Bass** | `BAS` | `#2E8B57` (Sea Green) | Bass DI, Bass Amp, Sub Bass, 808, Synth Bass |
| **Vocals** | `VOX` | `#9D65E8` (Royal Violet) | Lead Vocals, Backing Vocals, Doubles, Harmonies, Ad-libs |
| **Guitars** | `GTR` | `#E0A030` (Amber Gold) | Acoustic, Electric, Rhythm, Lead, Clean, Heavy, DI Guitars |
| **Keys** | `KEY` | `#3A9BC2` (Azure Cyan) | Acoustic Piano, Electric Piano, Rhodes, Organs, Keyboards |
| **Synths** | `SYN` | `#26C6B8` (Mint Teal) | Synth Leads, Pads, Arpeggios, Plucks, Modular |
| **Strings** | `STR` | `#C96D87` (Rose Quartz) | Violins, Viola, Cello, Double Bass, String Ensembles |
| **Brass & Winds** | `HORN` | `#D6A838` (Brass Ochre) | Trumpets, Trombones, Saxophones, Brass Sections, Flutes |
| **FX** | `FX` | `#4A74F0` (Cobalt Glow) | Sweeps, Risers, Impacts, Drops, Sound Effects, Foley |
| **Buses & Returns** | `BUS` | `#737F8D` (Slate Grey) | Reverbs, Delays, Parallel Compression, Submixes, Master |
| **Reference** | `REF` | `#9E9E9E` (Neutral Silver) | Mix References, Guide Tracks, Click Tracks |
| **Other** | `MISC` | `#546E7A` (Charcoal Blue) | Unclassified or miscellaneous session tracks |

---

## Intelligent Track Renaming Examples

The core engine removes clutter, underscores, and duplicate numbering while preserving audio engineering markers:

| Original Messy Track Name | Cleaned & Organized Name | Category Detected & Applied Rule |
| :--- | :--- | :--- |
| `snr_top_raw_01` | `DRM Snr Top` | Drums (`DRM`) |
| `gtr_ac_st_mic_L` | `GTR Ac St Mic L` | Guitars (`GTR`) - Stereo channel preserved |
| `lead_vox_comp_v3` | `VOX Lead Vox` | Vocals (`VOX`) - Take version clutter stripped |
| `sub_kick_in_di` | `DRM Sub Kick In DI` | Drums (`DRM`) - Critical `DI` acronym kept |
| `Audio 01` *(Serum plugin loaded)* | `SYN Audio 01` | Synths (`SYN`) - Discovered via FX-chain inspection |
| `synth_bass_808` | `BAS Synth Bass 808` | Bass (`BAS`) - Low-end stem hierarchy |
| `bgv_harm_high` | `VOX BGV Harm High` | Vocals (`VOX`) - Vocal harmony preserved |


## Architecture & Code Structure

The codebase is built following separation of concerns:

```
smart-track-organizer/
├── Smart Track Organizer.lua      # ReaScript main entry point and ReaPack metadata header
├── src/
│   ├── smart_track_organizer_core.lua # Pure business logic: classification, sorting, color plan
│   ├── lexicon.lua                # Production lexicon, category schemas, and acronym definitions
│   ├── palettes.lua               # 5 curated studio color themes and hex/RGB math
│   ├── reaper_adapter.lua         # REAPER API bridge, track collection, extstate, and undo blocks
│   ├── ui_state.lua               # Reactive UI state coordinator (selection, options, filters)
│   ├── ui_components.lua          # Modular UI component and layout builders
│   ├── ui_rtk.lua                 # Thin RTK GUI controller
│   ├── ui_draw_helpers.lua        # Modern vector drawing routines (cards, pill badges, dots)
│   ├── ui_native.lua              # Headless/fallback UI runner
│   ├── theme.lua                  # Central design tokens, color constants, and typography scales
│   └── lib/
│       └── rtk.lua                # Bundled self-contained REAPER Toolkit (pure Lua)
└── tests/
    ├── test_smart_track_organizer.lua # Core classification and sorting test suite
    ├── test_lexicon.lua               # Lexicon and acronym dictionary validation
    ├── test_palettes.lua              # Palette completeness and RGB conversion tests
    ├── test_reaper_adapter.lua        # REAPER API mock adapter and undo block tests
    ├── test_advanced_features.lua     # Multi-strategy sorting and FX context tests
    ├── test_strict_edge_cases.lua     # Folder depth math and edge-case stem names
    ├── test_ui_rtk.lua                # RTK component instantiation and NativeMenu tests
    └── test_ui_state.lua              # Isolated UI state store and filtering tests
```

## Architecture & Data Flow

```
[ REAPER Session Tracks ]
          │
          ▼
[ reaper_adapter.lua ] ──(Collect Raw Tracks & FX Names)──┐
          │                                               │
          ▼                                               ▼
   [ ui_state.lua ] ◄──(User Search / Filters)── [ ui_components.lua ]
          │                                               ▲
          ▼                                               │
[ smart_track_organizer_core.lua ] ─────────── (Render Live GUI Preview)
   ├── lexicon.lua (150+ Stems & FX Clues)                │
   └── palettes.lua (5 Themes & Color Math)               │
          │                                               │
          ▼                                               │
[ Organization Plan (Sorted, Colored, Foldered) ] ────────┘
          │
    (Apply Button Clicked)
          │
          ▼
[ reaper_adapter.lua ] ──(Atomic Undo Block)──► [ Mutated REAPER Project ]
```

---

## Installation & Setup

### Step 1: Download the Repository
Choose one of the two options:

- **Option A (Direct ZIP Download)**: Go to `https://github.com/TristanVisser99/smart-track-organizer`, click the green **Code** button, select **Download ZIP**, and unzip the folder.
- **Option B (Git Clone)**: Run `git clone https://github.com/TristanVisser99/smart-track-organizer.git` in your terminal.

Place the entire `smart-track-organizer` folder on your computer (for example, inside REAPER's `Scripts` directory found via **Options > Show REAPER resource path in explorer/finder...**).

### Step 2: Load into REAPER
1. Open REAPER.
2. Open the Action List: **Actions > Show action list...** (or press `?`).
3. Click **New action... > Load ReaScript...**.
4. Select `Smart Track Organizer.lua` from the project directory and click **Open**.
5. Select `Script: Smart Track Organizer.lua` and click **Run** (or assign a custom keyboard shortcut / toolbar icon).

---

## Quick Test Run Scenario

To quickly test the tool and see how it works in action:

1. Create a few empty tracks in a new REAPER project and name them:
   - `kick_in_raw`
   - `snare_top`
   - `bass_di`
   - `lead_vox_comp`
   - `gtr_ac_mic`
   - `reverb_bus`
2. Open the Action List (`?`), find `Smart Track Organizer`, and click **Run**.
3. In the studio window that pops up, notice how:
   - All tracks are categorized with color dots and live output names (`DRM Kick In Raw`, `BAS Bass DI`, etc.).
   - The summary bar displays the stem breakdown.
4. Select a color theme from the **Palette** dropdown (e.g. *Pastel Soft* or *Cyber Neon*).
5. Click **Apply Organization**.
6. Check your project: tracks are sorted, color-coded, prefixed, and grouped under neat folder tracks (`STO - Drums`, `STO - Bass`, etc.).
7. **Undo & Redo**:
   - Press **`Ctrl + Z`** (`Cmd + Z` on Mac) to instantly return the project to its original unorganized state.
   - Press **`Ctrl + Shift + Z`** (`Cmd + Shift + Z` on Mac) to redo and reapply the organization.


---

## Testing & Quality Assurance

The project includes an automated test suite containing 38 unit tests across 8 test suites.

To run the entire test suite locally:

```bash
./run_tests.sh
```

### What the Test Suite Validates:
- 150+ stem token classifications and boundary regexes.
- Contextual FX plugin heuristic classification.
- Audio acronym preservation and titlecasing algorithms.
- Zero-based REAPER folder insertion mathematics and non-nesting guarantees.
- Mocked REAPER API adapter transactions (undo blocks, extstate persistence, track mutations).
- Reactive UI state store transitions and search filtering.
- Lua 5.4, Lua 5.3, and LuaJIT cross-compatibility.

---

## License

Copyright (c) 2026 Tristan (27933024), Rahul (28259882). All Rights Reserved.

This software is provided for personal, educational, and professional use in Cockos REAPER. Unauthorized modification, redistribution, mirroring, or commercial exploitation is strictly prohibited. See [LICENSE](LICENSE) for full legal terms.





