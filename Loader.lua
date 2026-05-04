local BASE_URL = "https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/"

local order = {
    "Config.lua",
    "Connections.lua",
    "PlayerCache.lua",
    "Targeting.lua",
    "Overlay.lua",
    "Main.lua",
}

local context = {
    BaseUrl = BASE_URL,
    Modules = {},
}

local function fetch(path)
    return game:HttpGet(BASE_URL .. path, true)
end

local function run(path)
    local source = fetch(path)
    local chunk = loadstring(source)
    local result = chunk(context)
    context.Modules[path:gsub("%.lua$", "")] = result
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
