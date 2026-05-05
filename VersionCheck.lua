return function(context)
    local Config = context.Config

    local VersionCheck = {
        checked = false
    }

    local function notify(title, content)
        local gui = context.Gui
        local rayfield = gui and gui.Rayfield

        if not rayfield or typeof(rayfield.Notify) ~= "function" then
            return
        end

        pcall(function()
            rayfield:Notify({
                Title = title,
                Content = content,
                Duration = 6
            })
        end)
    end

    local function readVersion(source)
        local chunk = loadstring(source)

        if not chunk then
            return nil
        end

        local ok, data = pcall(chunk)

        if not ok then
            return nil
        end

        if type(data) == "table" then
            return data.Number
        end

        if type(data) == "string" then
            return data
        end

        return nil
    end

    function VersionCheck.check()
        local version = Config.Version

        if not version then
            return nil
        end

        local current = version.Number or "0.0.0"
        local latest = nil

        local ok, source = pcall(function()
            return game:HttpGet(context.BaseUrl .. "Version.lua?check=" .. tostring(os.time()), true)
        end)

        if ok and type(source) == "string" then
            latest = readVersion(source)
        end

        version.Latest = latest

        if not latest then
            version.Status = "Unknown"
            notify("Comet", "Version check failed. Running " .. current .. ".")
            return version.Status
        end

        if latest == current then
            version.Status = "Latest"
            notify("Comet", "Running " .. current .. " - Latest.")
        else
            version.Status = "Old"
            notify("Comet", "Running " .. current .. " - Old. Latest is " .. latest .. ".")
        end

        VersionCheck.checked = true
        return version.Status
    end

    function VersionCheck.start()
        task.spawn(function()
            VersionCheck.check()
        end)

        return VersionCheck
    end

    context.VersionCheck = VersionCheck

    return VersionCheck
end
