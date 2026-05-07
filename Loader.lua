local BASE_URL = "https://raw.githubusercontent.com/ProxoMetatable/personal-lua-client/main/"
local LOADER_VERSION = 2
local FETCH_RETRIES = 3

local DEFAULT_MANIFEST = {
    Name = "Comet",
    Version = "1.2.0",
    Build = 120,
    Channel = "stable",
    Cache = "build",
    RequiredLoader = 2,
    Modules = {
        {Name = "Version", Path = "Version.lua", Required = true},
        {Name = "Config", Path = "Config.lua", Required = true},
        {Name = "Connections", Path = "Connections.lua", Required = true},
        {Name = "ConfigMigrator", Path = "ConfigMigrator.lua", Required = true},
        {Name = "PlayerCache", Path = "PlayerCache.lua", Required = true},
        {Name = "Targeting", Path = "Targeting.lua", Required = true},
        {Name = "Weapons", Path = "Weapons.lua", Required = false},
        {Name = "Overlay", Path = "Overlay.lua", Required = true},
        {Name = "UIAdapter", Path = "UIAdapter.lua", Required = false},
        {Name = "GUI", Path = "GUI.lua", Required = false},
        {Name = "VersionCheck", Path = "VersionCheck.lua", Required = false},
        {Name = "Main", Path = "Main.lua", Required = true},
    },
    UIProviders = {
        Fluent = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
        Rayfield = "https://sirius.menu/rayfield"
    }
}

local context = {
    BaseUrl = BASE_URL,
    LoaderVersion = LOADER_VERSION,
    Manifest = nil,
    Modules = {},
    Authorized = true,
    Diagnostics = {
        Boot = {
            StartedAt = os.clock(),
            FinishedAt = nil,
            Status = "Booting",
            Entries = {}
        },
        Modules = {},
        Notifications = {},
        Errors = {},
        Runtime = {}
    }
}

local function cloneArray(value)
    local copy = {}

    for index, item in ipairs(value or {}) do
        if type(item) == "table" then
            local itemCopy = {}

            for key, child in pairs(item) do
                itemCopy[key] = child
            end

            copy[index] = itemCopy
        else
            copy[index] = item
        end
    end

    return copy
end

local function cloneManifest(value)
    local copy = {}

    for key, child in pairs(value) do
        if key == "Modules" then
            copy.Modules = cloneArray(child)
        elseif key == "UIProviders" and type(child) == "table" then
            copy.UIProviders = {}

            for provider, url in pairs(child) do
                copy.UIProviders[provider] = url
            end
        else
            copy[key] = child
        end
    end

    return copy
end

local function record(level, message, data)
    local entry = {
        At = os.clock(),
        Level = level,
        Message = message,
        Data = data
    }

    table.insert(context.Diagnostics.Boot.Entries, entry)

    if level == "error" then
        table.insert(context.Diagnostics.Errors, entry)
        warn("Comet loader: " .. message)
    end

    return entry
end

local function cacheToken()
    local manifest = context.Manifest

    if manifest and manifest.Cache == "none" then
        return tostring(os.time())
    end

    if manifest and manifest.Build then
        return tostring(manifest.Build)
    end

    return tostring(os.time())
end

local function fetch(path, token)
    local query = token or cacheToken()
    local url = BASE_URL .. path .. "?v=" .. tostring(query)
    local lastError = nil

    for attempt = 1, FETCH_RETRIES do
        local ok, source = pcall(function()
            return game:HttpGet(url, true)
        end)

        if ok and type(source) == "string" and source ~= "" then
            return true, source
        end

        lastError = source or "empty response"

        if attempt < FETCH_RETRIES and task and task.wait then
            task.wait(0.2 * attempt)
        end
    end

    return false, tostring(lastError)
end

local function evaluateSource(path, source)
    local chunk, compileError = loadstring(source)

    if not chunk then
        return false, "compile failed: " .. tostring(compileError)
    end

    local ok, value = pcall(chunk)

    if not ok then
        return false, "runtime failed: " .. tostring(value)
    end

    return true, value
end

local function loadManifest()
    local manifest = cloneManifest(DEFAULT_MANIFEST)
    local ok, source = fetch("Manifest.lua", tostring(os.time()))

    if ok then
        local loaded, data = evaluateSource("Manifest.lua", source)

        if loaded and type(data) == "table" then
            manifest = data
            record("info", "Loaded remote manifest", {Build = manifest.Build, Version = manifest.Version})
        else
            record("error", "Manifest failed; using fallback manifest", data)
        end
    else
        record("error", "Manifest fetch failed; using fallback manifest", source)
    end

    context.Manifest = manifest

    if tonumber(manifest.RequiredLoader) and tonumber(manifest.RequiredLoader) > LOADER_VERSION then
        record("error", "Manifest requires a newer loader", {
            Required = manifest.RequiredLoader,
            Current = LOADER_VERSION
        })
        context.Diagnostics.Boot.Status = "Incompatible"
        return false
    end

    return true
end

local function runModule(module)
    local name = module.Name or module.Path
    local path = module.Path or (tostring(name) .. ".lua")
    local required = module.Required ~= false
    local status = {
        Name = name,
        Path = path,
        Required = required,
        StartedAt = os.clock(),
        FinishedAt = nil,
        Status = "Loading",
        Error = nil
    }

    context.Diagnostics.Modules[name] = status

    local fetched, source = fetch(path)

    if not fetched then
        status.Status = "FetchFailed"
        status.Error = source
        status.FinishedAt = os.clock()
        record(required and "error" or "warn", "Module fetch failed: " .. tostring(name), source)
        return not required
    end

    local loaded, value = evaluateSource(path, source)

    if not loaded then
        status.Status = "LoadFailed"
        status.Error = value
        status.FinishedAt = os.clock()
        record(required and "error" or "warn", "Module load failed: " .. tostring(name), value)
        return not required
    end

    local result = value

    if typeof(value) == "function" then
        local ok, moduleResult = pcall(value, context)

        if not ok then
            status.Status = "StartFailed"
            status.Error = moduleResult
            status.FinishedAt = os.clock()
            record(required and "error" or "warn", "Module start failed: " .. tostring(name), moduleResult)
            return not required
        end

        result = moduleResult
    end

    context.Modules[name] = result

    if name == "Version" or path == "Version.lua" then
        context.Version = result
    end

    status.Status = "Loaded"
    status.FinishedAt = os.clock()

    return true
end

function context.Notify(title, content, duration, subContent)
    local entry = {
        Title = title,
        Content = content,
        SubContent = subContent,
        Duration = duration or 5,
        At = os.clock()
    }

    table.insert(context.Diagnostics.Notifications, entry)

    local gui = context.Gui

    if gui and gui.notify then
        gui.notify(title, content, duration, subContent)
    end

    return entry
end

local manifestOk = loadManifest()

if manifestOk then
    for _, module in ipairs(context.Manifest.Modules or {}) do
        if not runModule(module) then
            context.Diagnostics.Boot.Status = "Failed"
            break
        end
    end
end

if context.Diagnostics.Boot.Status ~= "Failed" and context.Diagnostics.Boot.Status ~= "Incompatible" then
    local main = context.Modules.Main

    if main and main.start then
        local ok, err = pcall(function()
            main.start()
        end)

        if ok then
            context.Diagnostics.Boot.Status = "Running"
        else
            context.Diagnostics.Boot.Status = "Failed"
            record("error", "Main start failed", err)
        end
    else
        context.Diagnostics.Boot.Status = "Failed"
        record("error", "Main module did not expose start()")
    end
end

context.Diagnostics.Boot.FinishedAt = os.clock()

return context
