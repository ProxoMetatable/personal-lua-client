local BASE_URL = "https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/"
local ALLOWED_USER_ID = 1871025207

local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer

local context = {
    BaseUrl = BASE_URL,
    Modules = {},
    Authorized = LocalPlayer and LocalPlayer.UserId == ALLOWED_USER_ID,
}

if not context.Authorized then
    warn("personal-lua-client: unauthorized user")
    return context
end

local order = {
    "Version.lua",
    "Config.lua",
    "Connections.lua",
    "PlayerCache.lua",
    "Targeting.lua",
    "Overlay.lua",
    "GUI.lua",
    "Main.lua",
}

local function fetch(path)
    return game:HttpGet(BASE_URL .. path .. "?v=" .. tostring(os.time()), true)
end

local function run(path)
    local source = fetch(path)
    local chunk = loadstring(source)
    local value = chunk()
    local result = value

    if typeof(value) == "function" then
        result = value(context)
    end

    context.Modules[path:gsub("%.lua$", "")] = result

    if path == "Version.lua" then
        context.Version = result
    end

    return result
end

for _, path in ipairs(order) do
    run(path)
end

local main = context.Modules.Main

if main and main.start then
    main.start()
end

return context
