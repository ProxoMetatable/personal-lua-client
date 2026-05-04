# Comet - Private

A modular Lua client layout designed to be loaded from raw GitHub URLs.

## Loadstring

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/Loader.lua?v=6", true))()
```

The loader only starts for `UserId == 1871025207`. Other users receive a disabled context and no modules are loaded.

## Controls

- Hold right click to activate Feature1 by default.
- `RightShift` opens and closes the settings menu by default.
- `Insert` toggles the overlay by default.
- Use the Rayfield dropdowns to change the aim, menu, and overlay binds.

## Files

- `Loader.lua` authorizes the local player and loads every module in order.
- `Config.lua` stores shared settings and default controls.
- `Connections.lua` owns connection registration and cleanup.
- `PlayerCache.lua` creates and removes Drawing objects per player.
- `Targeting.lua` owns target selection and camera assist logic.
- `Overlay.lua` updates boxes, names, health bars, distances, tracers, and the range circle.
- `GUI.lua` builds the Rayfield customization menu.
- `Main.lua` wires services, input, GUI lifecycle, player lifecycle, character lifecycle, and the render loop.

## Visibility

The raw URLs only work for external clients when this repository is public or when the files are hosted somewhere reachable without authentication.
