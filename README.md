# personal-lua-client

A modular Lua client layout designed to be loaded from raw GitHub URLs.

## Loadstring

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/Loader.lua", true))()
```

`client` is a shared context table containing:

- `client.Config`
- `client.Connections`
- `client.PlayerCache`
- `client.Targeting`
- `client.Overlay`
- `client.Main`
- `client.Modules`

## Files

- `Loader.lua` loads every module in order.
- `Config.lua` stores shared settings and toggles.
- `Connections.lua` owns connection registration and cleanup.
- `PlayerCache.lua` tracks player lifecycle and cached character parts.
- `Targeting.lua` exposes inert targeting hooks.
- `Overlay.lua` exposes inert overlay hooks.
- `Main.lua` wires services, input, cache refresh, and the render loop.

## Visibility

The raw URLs only work for external clients when this repository is public or when the files are hosted somewhere reachable without authentication.
