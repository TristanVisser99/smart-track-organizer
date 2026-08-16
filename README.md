# Smart Track Organizer

Smart Track Organizer is a REAPER Lua ReaScript that cleans up large sessions by classifying tracks, coloring them, renaming them, sorting them, and optionally creating visible category folder tracks.

## What It Does

- Detects common track families: drums, bass, vocals, guitars, keys, synths, strings, brass/winds, FX, returns/buses, reference tracks, and miscellaneous tracks.
- Applies distinct colors per family.
- Renames tracks with short prefixes such as `DRM - Kick`, `VOX - Lead Vocal`, and `GTR - Rhythm L`.
- Sorts tracks into a practical mix order.
- Creates `STO - ...` folder headers for each detected family when enabled.
- Supports all tracks or selected tracks only.
- Includes a dry-run preview before committing changes.

## Install In REAPER

1. Open REAPER.
2. Go to `Actions > Show action list...`.
3. Click `New action... > Load ReaScript...`.
4. Select `Smart Track Organizer.lua` from this folder.
5. Run `Smart Track Organizer` from the Action List.

Keep the `src` folder next to `Smart Track Organizer.lua`; the script loads its organizer engine from there.

## Usage

When run, the script asks for four comma-separated options:

- `Scope`: `all` or `selected`
- `Create folder groups?`: `yes` or `no`
- `Prefix renamed tracks?`: `yes` or `no`
- `Dry run?`: `yes` or `no`

The default is:

```text
all,yes,yes,no
```

For a safe preview, use:

```text
all,yes,yes,yes
```

## Tests

Run the test suite from this folder:

```sh
./run_tests.sh
```

The tests exercise classification, word-boundary matching, renaming, sorting, grouping, selected-track scope, dry-run behavior, prompt cancellation, repeated runs with existing generated folders, folder insertion math, and color planning.

Current coverage includes 13 core organizer tests and 8 mocked REAPER adapter tests.
