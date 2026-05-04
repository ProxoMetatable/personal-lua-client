# Comet - Private

A modular Lua client layout designed to be loaded from raw GitHub URLs.

## Loadstring

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/Loader.lua?v=12", true))()
```

The loader only starts for `UserId == 1871025207`. Other users receive a disabled context and no modules are loaded.

## Controls

- Right click toggles the aimbot active state.
- `Insert` toggles the overlay.
- Rayfield handles the window UI normally.
- Settings autosave to `CometPrivate/config.json` without saving or loading custom binds.

## Files

- `Loader.lua` authorizes the local player and loads every module in order.
- `Config.lua` stores shared settings.
- `Connections.lua` owns connection registration and cleanup.
- `PlayerCache.lua` creates and removes Drawing objects per player.
- `Targeting.lua` owns target selection for players and NPC-style workspace models.
- `Overlay.lua` updates boxes, names, health bars, distances, tracers, and the range circle.
- `GUI.lua` builds the Rayfield customization menu and owns Comet config saving.
- `Main.lua` wires services, fixed input controls, GUI lifecycle, player lifecycle, character lifecycle, and the render loop after Roblox camera updates.

## Visibility

The raw URLs only work for external clients when this repository is public or when the files are hosted somewhere reachable without authentication.
