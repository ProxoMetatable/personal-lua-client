-- personal-lua-client
-- Main loadstring entrypoint.

local Client = {}
Client.__index = Client

Client.Name = "personal-lua-client"
Client.Version = "0.1.0"

local function detectExecutor()
    if typeof ~= nil then
        return "roblox"
    end

    if _VERSION then
        return _VERSION
    end

    return "lua"
end

function Client.new(options)
    options = options or {}

    local self = setmetatable({}, Client)
    self.name = options.name or Client.Name
    self.version = Client.Version
    self.environment = detectExecutor()
    self.started = false
    self.config = options.config or {}

    return self
end

function Client:start()
    if self.started then
        return self
    end

    self.started = true
    return self
end

function Client:stop()
    self.started = false
    return self
end

function Client:isRunning()
    return self.started == true
end

function Client:info()
    return {
        name = self.name,
        version = self.version,
        environment = self.environment,
        started = self.started,
    }
end

function Client:log(message)
    message = tostring(message or "")
    print(("[%s] %s"):format(self.name, message))
    return self
end

local defaultClient = Client.new()

defaultClient.Client = Client

defaultClient:start()

defaultClient:log("loaded")

return defaultClient
