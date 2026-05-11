return function(context)
    local Config = context.Config

    local VersionCheck = {
        running = false,
        checked = false,
        notifiedOutdated = false,
        lastError = nil
    }

    local function notify(title, content, duration, subContent)
        if context.Notify then
            context.Notify(title, content, duration, subContent)
        end
    end

    local function readRelease(source)
        local chunk = loadstring(source)

        if not chunk then
            return nil
        end

        local ok, data = pcall(chunk)

        if not ok then
            return nil
        end

        if type(data) == "table" then
            data.Version = data.Version or data.Number
            return data
        end

        if type(data) == "string" then
            return {
                Version = data,
                Number = data
            }
        end

        return nil
    end

    local function parseVersion(value)
        local parts = {0, 0, 0}
        local index = 1

        for part in tostring(value or ""):gmatch("(%d+)") do
            if index <= 3 then
                parts[index] = tonumber(part) or 0
                index += 1
            end
        end

        return parts
    end

    local function compareVersions(left, right)
        local a = parseVersion(left)
        local b = parseVersion(right)

        for index = 1, 3 do
            if a[index] > b[index] then
                return 1
            elseif a[index] < b[index] then
                return -1
            end
        end

        return 0
    end

    local function severityFor(latest, current)
        local latestVersion = latest.Version or latest.Number or "0.0.0"
        local currentVersion = current.Number or "0.0.0"
        local comparison = compareVersions(latestVersion, currentVersion)
        local latestBuild = tonumber(latest.Build)
        local currentBuild = tonumber(current.Build)

        if tonumber(latest.MinLoader) and tonumber(latest.MinLoader) > tonumber(context.LoaderVersion or 1) then
            return "Incompatible", "Incompatible"
        end

        if comparison <= 0 and (not latestBuild or not currentBuild or latestBuild <= currentBuild) then
            return "Latest", "Current"
        end

        local latestParts = parseVersion(latestVersion)
        local currentParts = parseVersion(currentVersion)

        if latestParts[1] > currentParts[1] then
            return "Major Update", "Major"
        elseif latestParts[2] > currentParts[2] then
            return "Update Available", "Minor"
        elseif latestParts[3] > currentParts[3] then
            return "Patch Available", "Patch"
        end

        if latestBuild and currentBuild and latestBuild > currentBuild then
            return "Build Available", "Build"
        end

        return "Update Available", "Unknown"
    end

    local function markVersion(version, status, severity, latest)
        version.Status = status
        version.Severity = severity

        if latest then
            version.Latest = latest.Version or latest.Number
            version.LatestBuild = latest.Build
            version.LatestChannel = latest.Channel
            version.LatestChangelog = latest.Changelog
        end
    end

    local function releaseSummary(latest, current)
        local currentVersion = current.Number or "0.0.0"
        local latestVersion = latest.Version or latest.Number or "unknown"
        local latestBuild = latest.Build and (" build " .. tostring(latest.Build)) or ""

        return "Running " .. currentVersion .. ". Latest is " .. latestVersion .. latestBuild .. "."
    end

    local function releasePath()
        local manifest = context.Manifest

        for _, module in ipairs(manifest and manifest.Modules or {}) do
            if module.Name == "Version" and type(module.Path) == "string" then
                return module.Path
            end
        end

        return "src/core/Version.lua"
    end

    function VersionCheck.check()
        local compatibility = context.Compatibility

        if compatibility and (not compatibility.supports("HttpGet") or not compatibility.supports("Loadstring")) then
            if Config.Version then
                Config.Version.Status = "Unknown"
                Config.Version.Severity = "Compatibility"
            end

            VersionCheck.lastError = "HttpGet/loadstring support is incomplete"
            return Config.Version and Config.Version.Status or nil
        end

        local version = Config.Version

        if not version then
            return nil
        end

        local ok, source = pcall(function()
            return game:HttpGet(context.BaseUrl .. releasePath() .. "?check=" .. tostring(os.time()), true)
        end)

        if not ok or type(source) ~= "string" or source == "" then
            VersionCheck.lastError = source or "empty response"
            markVersion(version, "Unknown", "Network")
            return version.Status
        end

        local latest = readRelease(source)

        if not latest then
            VersionCheck.lastError = "invalid release metadata"
            markVersion(version, "Unknown", "Parse")
            return version.Status
        end

        local status, severity = severityFor(latest, version)
        markVersion(version, status, severity, latest)

        if status ~= "Latest" and not VersionCheck.notifiedOutdated then
            notify("Comet", releaseSummary(latest, version), 8, status)
            VersionCheck.notifiedOutdated = true
        end

        VersionCheck.checked = true
        VersionCheck.lastError = nil

        return version.Status
    end

    function VersionCheck.start()
        if VersionCheck.running then
            return VersionCheck
        end

        local compatibility = context.Compatibility

        if compatibility and (not compatibility.supports("HttpGet") or not compatibility.supports("Loadstring")) then
            VersionCheck.check()
            return VersionCheck
        end

        VersionCheck.running = true

        task.spawn(function()
            VersionCheck.check()

            while VersionCheck.running do
                local interval = tonumber(Config.Version and Config.Version.CheckInterval) or 300
                task.wait(math.clamp(interval, 60, 3600))

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
