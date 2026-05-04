# personal-lua-client

A small Lua client entrypoint designed to be loaded from a raw URL.

## Loadstring

```lua
local client = loadstring(game:HttpGet("https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/client.lua"))()
client:log("ready")
```

The returned `client` starts automatically and exposes:

- `client:log(message)`
- `client:isRunning()`
- `client:stop()`
- `client:start()`
- `client:info()`
- `client.Client.new(options)` for creating another client instance

## Important

This repository is currently private. A normal `game:HttpGet` request usually cannot fetch private GitHub raw content. To use the exact loadstring URL above from an external runtime, make the repository public or host `client.lua` somewhere reachable without authentication.
