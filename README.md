# Comet - Private

A modular Lua client layout designed to be loaded from raw GitHub URLs.

## Loadstring

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/Loader.lua", true))()
```

The loader only starts for `UserId == 1871025207`. Other users receive a disabled context and no modules are loaded.

## Version

- A small top-right badge shows `Comet - version - Latest/Old`.
- The badge starts as `Checking` and updates after fetching `Version.lua`.
- Rayfield shows a notification with the current/latest version when `Rayfield:Notify` is available.

## Controls

- Hold right click to activate the aimbot.
- Release right click to stop the aimbot.
- `Insert` toggles the overlay.
- Rayfield handles the window UI normally.
- Settings autosave to `CometPrivate/config.json` without saving or loading custom binds.

## Target Safety

- Locked targets are revalidated before camera movement.
- Dead humanoids, dead humanoid states, off-FOV targets, underground parts, and targets too far above/below the local character are dropped instantly.
- `MaxVerticalDelta` and `FloorBuffer` in `Config.lua` prevent down-map death models from causing obvious camera flicks.

## Performance

- NPC-style workspace models are cached instead of discovered with `Workspace:GetDescendants()` every frame.
- Target scans are throttled by the Scan Rate setting while camera smoothing still runs every frame.
- Max Cached Targets limits how many cached models are evaluated per scan.

## Files

- `Version.lua` stores the latest version number.
- `Loader.lua` authorizes the local player and loads every module in order.
- `Config.lua` stores shared settings and runtime version state.
- `Connections.lua` owns connection registration and cleanup.
- `PlayerCache.lua` creates and removes Drawing objects per player.
- `Targeting.lua` owns cached target selection for players and NPC-style workspace models.
- `Overlay.lua` updates boxes, names, health bars, distances, tracers, the range circle, and the version badge.
- `GUI.lua` builds the Rayfield customization menu and owns Comet config saving.
- `VersionCheck.lua` compares the running version to the remote latest version and sends Rayfield notifications.
- `Main.lua` wires services, fixed input controls, GUI lifecycle, player lifecycle, character lifecycle, version check startup, and the render loop after Roblox camera updates.

## Visibility

The raw URLs only work for external clients when this repository is public or when the files are hosted somewhere reachable without authentication.
