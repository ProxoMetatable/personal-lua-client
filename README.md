# Comet - Private

A modular Lua client layout designed to be loaded from raw GitHub URLs.

## Loadstring

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/Loader.lua", true))()
```

The loader only starts for `UserId == 1871025207`. Other users receive a disabled context and no modules are loaded.

## Controls

- Hold right click to activate the aimbot.
- Release right click to stop the aimbot.
- `Insert` toggles the overlay.
- Rayfield handles the window UI normally.
- Settings autosave to `CometPrivate/config.json` without saving or loading custom binds.

## Performance

- NPC-style workspace models are cached instead of discovered with `Workspace:GetDescendants()` every frame.
- Target scans are throttled by the Scan Rate setting while camera smoothing still runs every frame.
- Max Cached Targets limits how many cached models are evaluated per scan.

## Files

- `Loader.lua` authorizes the local player and loads every module in order.
- `Config.lua` stores shared settings.
- `Connections.lua` owns connection registration and cleanup.
- `PlayerCache.lua` creates and removes Drawing objects per player.
- `Targeting.lua` owns cached target selection for players and NPC-style workspace models.
- `Overlay.lua` updates boxes, names, health bars, distances, tracers, and the range circle.
- `GUI.lua` builds the Rayfield customization menu and owns Comet config saving.
- `Main.lua` wires services, fixed input controls, GUI lifecycle, player lifecycle, character lifecycle, and the render loop after Roblox camera updates.

## Visibility

The raw URLs only work for external clients when this repository is public or when the files are hosted somewhere reachable without authentication.
