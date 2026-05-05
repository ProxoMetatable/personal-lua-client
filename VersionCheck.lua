return function(context)
    local Config = context.Config

    local VersionCheck = {
        running = false,
        checked = false,
        notifiedOutdated = false
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

    local function markVersion(version, status, latest)
        version.Status = status
        if latest then
            version.Latest = latest
        end
    end

    local function compareVersions(latest, current)
        return latest == current
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

        if not latest then
            markVersion(version, "Unknown")
            return version.Status
        end

        if compareVersions(latest, current) then
            markVersion(version, "Latest", latest)
        else
            markVersion(version, "Old", latest)
            if not VersionCheck.notifiedOutdated then
                notify("Comet", "Version out of date. Running " .. current .. ". Latest is " .. latest .. ".")
                VersionCheck.notifiedOutdated = true
            end
        end

        VersionCheck.checked = true
        return version.Status
    end

    function VersionCheck.start()
        if VersionCheck.running then
            return VersionCheck
        end

        VersionCheck.running = true

        task.spawn(function()
            VersionCheck.check()
            while VersionCheck.running do
                task.wait(10)
                if not VersionCheck.running then
                    break
                end
                VersionCheck.check()
            end
        end)

        return VersionCheck
    end

    function VersionCheck.stop()
        VersionCheck.running = false

        return VersionCheck
    end

    context.VersionCheck = VersionCheck

    return VersionCheck
end
