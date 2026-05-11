# Comet - Private

A modular Lua client layout designed to be loaded from raw GitHub URLs.

## Loadstring

Modular loader:

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/Loader.lua", true))()
```

Production bundle:

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/dist/client.lua", true))()
```

The loader is not bound to a specific Roblox `UserId`; any user who can load the raw URL can start the client.

## Loader

- `Loader.lua` fetches `Manifest.lua`, checks the required loader version, then loads modules in manifest order.
- Module fetch/load/start failures are recorded in `context.Diagnostics.Modules`.
- Required modules stop boot on failure; optional modules can fail without stopping the whole client.
- Cache busting uses the manifest build by default instead of forcing a new URL every run.
- `source.lua` delegates to `Loader.lua` so the modular build remains the source of truth.
- Implementation modules live under `src/`; the public loader files stay at the repository root.
- `dist/client.lua` embeds the manifest and every module for one-file production loading.

## Version

- `src/core/Version.lua` now stores release metadata: semantic version, build, channel, minimum loader, and changelog.
- `VersionCheck.lua` compares semantic versions and build numbers instead of plain string equality.
- The checker reports `Latest`, `Patch Available`, `Update Available`, `Major Update`, `Build Available`, `Incompatible`, or `Unknown`.
- Remote checks run on the manifest interval, defaulting to every 300 seconds.

## Interface

- Fluent is the preferred UI provider, loaded from `https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua`.
- Rayfield remains available as a fallback provider.
- `UIAdapter.lua` keeps `GUI.lua` from depending directly on one UI library.
- The Settings tab can switch the saved UI provider; restart the client after changing providers.

## Profiles

- Settings are saved through `ConfigMigrator.lua`.
- Profiles live under `CometPrivate/profiles/<PlaceId>/<profile>.json` when per-place profiles are enabled.
- A legacy copy is still written to `CometPrivate/config.json` for compatibility.
- Config version `6` adds saved keybinds, UI provider settings, profile settings, diagnostics settings, and the `MaxBelowLocal` value.
- UI setting changes are debounced before writing to disk; explicit profile saves and shutdown still flush immediately.

## Bundle Build

Regenerate the production bundle after changing `Loader.lua`, `Manifest.lua`, or files under `src/`:

```powershell
.\scripts\build-bundle.ps1
```

The build script writes `dist/client.lua` and validates that every manifest path exists.

## Controls

- Aim activation supports `Hold`, `Toggle`, and `Always` modes.
- Default aim bind is `MB2`.
- Default overlay toggle bind is `Insert`.
- Default menu bind is `RightShift`.
- Default panic stop bind is `End`.

## Overlay

- The overlay supports boxes, names, health bars, distances, tracers, range circle, and version badge.
- Text size, box thickness, tracer origin, team color use, and main color are saved in profiles.
- Tracer origin can be `Bottom`, `Center`, or `Mouse`.
- ESP updates are throttled separately from camera assist; default is 30 Hz.
- Screen inset correction is enabled by default for executor Drawing alignment.

## Diagnostics

- Loader/module status is stored in `context.Diagnostics`.
- Runtime diagnostics track FPS, frame time, overlay time, targeting time, cached model count, active state, and current target.
- The Diagnostics tab can show the current runtime snapshot and manually trigger a version check.
- Render-loop overlay/targeting errors are caught and warning-throttled so a repeated runtime issue does not spam the console every frame.
- `src/core/Compatibility.lua` runs executor capability checks at startup and disables unsupported feature areas instead of letting missing APIs break the script.
- The Diagnostics tab includes a compatibility report when the UI can load.

## Executor Compatibility

The preflight checks these capabilities:

- `loadstring`
- `game:HttpGet`
- `Drawing.new` with the Circle, Square, Text, and Line objects/properties used by the ESP/FOV overlay
- file APIs: `writefile`, `readfile`, `isfile`, `isfolder`, `makefolder`
- `task.spawn`, `task.wait`, and `task.delay`
- camera projection with `WorldToViewportPoint`
- GUI inset and mouse location APIs
- frame loop support through `BindToRenderStep`, `RenderStepped`, or `Heartbeat`
- `Players.LocalPlayer`

Feature fallbacks:

- Missing `Drawing` disables ESP/FOV overlay only.
- Missing file APIs disables profile persistence only.
- Missing `HttpGet` or `loadstring` disables external UI libraries and remote version checks.
- Missing camera projection disables aiming.
- Missing `BindToRenderStep` alone does not disable features; the client falls back to `RenderStepped`, then `Heartbeat`, which is meant for low-level executors such as Solara.

## Files

- `Loader.lua` initializes diagnostics, loads the manifest, loads modules, and starts `Main`.
- `Manifest.lua` defines release metadata, module order, optional modules, and UI provider URLs.
- `client.lua` and `source.lua` delegate to the public root loader.
- `src/Main.lua` wires lifecycle, input, player events, character events, and the render loop after Roblox camera updates.
- `src/core/Version.lua` stores release metadata used by the checker.
- `src/core/Config.lua` stores default settings.
- `src/core/Compatibility.lua` checks executor capabilities and applies feature fallbacks.
- `src/core/ConfigMigrator.lua` snapshots, applies, and migrates saved settings.
- `src/core/Connections.lua` owns connection registration and cleanup.
- `src/core/VersionCheck.lua` compares the running release to the remote latest release.
- `src/features/PlayerCache.lua` creates and removes Drawing objects per player.
- `src/features/Targeting.lua` owns cached target selection for players and NPC-style workspace models.
- `src/features/Overlay.lua` updates boxes, names, health bars, distances, tracers, the range circle, and the version badge.
- `src/features/Weapons.lua` owns weapon-folder snapshot, apply, and revert behavior.
- `src/ui/UIAdapter.lua` wraps Fluent and Rayfield.
- `src/ui/GUI.lua` builds the customization menu, profiles, keybind controls, and diagnostics.

## Repository Layout

```text
.
├── Loader.lua
├── Manifest.lua
├── client.lua
├── dist/
│   └── client.lua
├── source.lua
├── src/
│   ├── Main.lua
│   ├── core/
│   ├── features/
│   └── ui/
└── scripts/
```

## Visibility

The raw URLs only work for external clients when this repository is public or when the files are hosted somewhere reachable without authentication.
