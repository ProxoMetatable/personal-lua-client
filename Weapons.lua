return function(context)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Config = context.Config
    local Connections = context.Connections

    local Weapons = {
        running = false,
        weaponsFolder = nil,
        baselineCaptured = false
    }

    local WEAPONS_NAME = "Weapons"
    local MARKER_NAME = "Infinite"
    local PROJECTILE_NAME = "Projectile"
    local SPEED_NAME = "Speed"
    local MAX_SPEED_NAME = "MaxSpeed"
    local SPEED_PCT_NAME = "Speed%"
    local SPEED_TRAVEL_VALUE = 70000
    local SPEED_PCT_TRAVEL_VALUE = 0

    local folderAddedConn = nil
    local folderChildConn = nil
    local folderChildRemovedConn = nil
    local folderDestroyConn = nil
    local baselineConn = nil

    local nativeInfinite = {}
    local managedFolders = {}
    local scannedWeaponFolders = {}
    local projectileOriginals = {}
    local projectileModified = {}

    local function isFolder(instance)
        return typeof(instance) == "Instance" and instance:IsA("Folder")
    end

    local function isWeaponsFolder(instance)
        return isFolder(instance) and instance.Name == WEAPONS_NAME
    end

    local function hasAnyEnabled()
        return Config.Feature3 and (Config.Feature3.InfiniteAmmo or Config.Feature3.ProjectileTravel)
    end

    local function hasProjectileFolder(instance)
        if not isFolder(instance) then
            return false
        end

        local projectile = instance:FindFirstChild(PROJECTILE_NAME)

        return projectile ~= nil and projectile:IsA("Folder")
    end

    local function isNumericValue(instance)
        return instance ~= nil and (instance:IsA("IntValue") or instance:IsA("NumberValue"))
    end

    local function hasInfiniteMarker(folder)
        if not isFolder(folder) then
            return nil
        end

        local marker = folder:FindFirstChild(MARKER_NAME)

        if marker and marker:IsA("Folder") then
            return marker
        end

        return nil
    end

    local function cacheNativeState(folder)
        if not isWeaponsFolder(folder) then
            return
        end

        if scannedWeaponFolders[folder] then
            return
        end

        scannedWeaponFolders[folder] = true

        for _, child in ipairs(folder:GetChildren()) do
            if isFolder(child) and hasInfiniteMarker(child) then
                nativeInfinite[child] = true
            end
        end
    end

    local function removeManagedMarkers()
        for folder in pairs(managedFolders) do
            if isFolder(folder) then
                local marker = hasInfiniteMarker(folder)

                if marker then
                    pcall(function()
                        marker:Destroy()
                    end)
                end
            end
        end

        managedFolders = {}
    end

    local function snapshotProjectileValues(weapon)
        if not isFolder(weapon) or not hasProjectileFolder(weapon) then
            return
        end

        local entry = projectileOriginals[weapon]

        if entry then
            return
        end

        local speed = weapon:FindFirstChild(SPEED_NAME)
        local maxSpeed = weapon:FindFirstChild(MAX_SPEED_NAME)
        local speedP = weapon:FindFirstChild(SPEED_PCT_NAME)
        local data = {}

        if isNumericValue(speed) then
            data.Speed = speed.Value
        end

        if isNumericValue(maxSpeed) then
            data.MaxSpeed = maxSpeed.Value
        end

        if isNumericValue(speedP) then
            data["Speed%"] = speedP.Value
        end

        if next(data) ~= nil then
            projectileOriginals[weapon] = data
        end
    end

    local function applyProjectileSettings(weapon, enabled)
        if not isFolder(weapon) or not hasProjectileFolder(weapon) then
            return
        end

        snapshotProjectileValues(weapon)
        local snapshot = projectileOriginals[weapon]

        if not snapshot then
            return
        end

        local speed = weapon:FindFirstChild(SPEED_NAME)
        local maxSpeed = weapon:FindFirstChild(MAX_SPEED_NAME)
        local speedP = weapon:FindFirstChild(SPEED_PCT_NAME)
        local touched = {}

        if enabled then
            if isNumericValue(speed) and snapshot.Speed ~= nil then
                pcall(function()
                    speed.Value = SPEED_TRAVEL_VALUE
                end)

                touched.Speed = true
            end

            if isNumericValue(maxSpeed) and snapshot.MaxSpeed ~= nil then
                pcall(function()
                    maxSpeed.Value = SPEED_TRAVEL_VALUE
                end)

                touched.MaxSpeed = true
            end

            if isNumericValue(speedP) and snapshot["Speed%"] ~= nil then
                pcall(function()
                    speedP.Value = SPEED_PCT_TRAVEL_VALUE
                end)

                touched["Speed%"] = true
            end
        end

        if next(touched) ~= nil then
            projectileModified[weapon] = touched
        else
            projectileModified[weapon] = nil
        end
    end

    local function revertProjectileSettings(weapon)
        if not isFolder(weapon) then
            return
        end

        local touched = projectileModified[weapon]

        if not touched then
            return
        end

        local snapshot = projectileOriginals[weapon]

        if not snapshot then
            projectileModified[weapon] = nil
            return
        end

        local speed = weapon:FindFirstChild(SPEED_NAME)
        local maxSpeed = weapon:FindFirstChild(MAX_SPEED_NAME)
        local speedP = weapon:FindFirstChild(SPEED_PCT_NAME)

        if touched.Speed and isNumericValue(speed) and snapshot.Speed ~= nil then
            pcall(function()
                speed.Value = snapshot.Speed
            end)
        end

        if touched.MaxSpeed and isNumericValue(maxSpeed) and snapshot.MaxSpeed ~= nil then
            pcall(function()
                maxSpeed.Value = snapshot.MaxSpeed
            end)
        end

        if touched["Speed%"] and isNumericValue(speedP) and snapshot["Speed%"] ~= nil then
            pcall(function()
                speedP.Value = snapshot["Speed%"]
            end)
        end

        projectileModified[weapon] = nil
    end

    local function revertAllProjectiles()
        for weapon in pairs(projectileModified) do
            revertProjectileSettings(weapon)
        end
    end

    local function processWeaponFolderChild(child)
        if not isFolder(child) then
            return
        end

        if Config.Feature3.InfiniteAmmo then
            local marker = hasInfiniteMarker(child)

            if not marker then
                if not nativeInfinite[child] then
                    local newMarker = Instance.new("Folder")
                    newMarker.Name = MARKER_NAME

                    local added = false

                    pcall(function()
                        newMarker.Parent = child
                        added = true
                    end)

                    if added then
                        managedFolders[child] = true
                    end
                end
            elseif not nativeInfinite[child] then
                managedFolders[child] = true
            else
                managedFolders[child] = nil
            end
        end

        if Config.Feature3.ProjectileTravel then
            applyProjectileSettings(child, true)
        end
    end

    local function processWeaponFolderChildren(folder)
        if not isWeaponsFolder(folder) then
            return
        end

        for _, child in ipairs(folder:GetChildren()) do
            processWeaponFolderChild(child)
        end
    end

    local function captureBaseline()
        if Weapons.baselineCaptured then
            return
        end

        local folder = ReplicatedStorage:FindFirstChild(WEAPONS_NAME)

        if isWeaponsFolder(folder) then
            cacheNativeState(folder)
            Weapons.baselineCaptured = true
            return
        end

        if not baselineConn then
            baselineConn = Connections.add("WeaponsBaseline", ReplicatedStorage.ChildAdded:Connect(function(child)
                if isWeaponsFolder(child) then
                    cacheNativeState(child)
                    Weapons.baselineCaptured = true
                    if baselineConn then
                        Connections.disconnect("WeaponsBaseline")
                        baselineConn = nil
                    end
                end
            end))
        end
    end

    local function clearFolderConns()
        Connections.disconnect("WeaponsFolderChild")
        Connections.disconnect("WeaponsFolderRemoved")
        Connections.disconnect("WeaponsFolderDestroy")
        folderChildConn = nil
        folderChildRemovedConn = nil
        folderDestroyConn = nil
    end

    local function applyStateToCurrent()
        local weaponsFolder = ReplicatedStorage:FindFirstChild(WEAPONS_NAME)

        if not isWeaponsFolder(weaponsFolder) then
            return
        end

        processWeaponFolderChildren(weaponsFolder)

        if not Config.Feature3.InfiniteAmmo then
            removeManagedMarkers()
        end

        if not Config.Feature3.ProjectileTravel then
            revertAllProjectiles()
        end
    end

    local function attachWeaponFolder(folder)
        if not isWeaponsFolder(folder) then
            return
        end

        if Weapons.weaponsFolder == folder and folderChildConn and folderChildRemovedConn and folderDestroyConn then
            return
        end

        Weapons.weaponsFolder = folder

        clearFolderConns()

        if not Weapons.baselineCaptured then
            cacheNativeState(folder)
            Weapons.baselineCaptured = true
            if baselineConn then
                Connections.disconnect("WeaponsBaseline")
                baselineConn = nil
            end
        end

        if Weapons.baselineCaptured then
            cacheNativeState(folder)
        end

        processWeaponFolderChildren(folder)

        folderChildConn = Connections.add("WeaponsFolderChild", folder.ChildAdded:Connect(function(child)
            processWeaponFolderChild(child)
        end))

        folderChildRemovedConn = Connections.add("WeaponsFolderRemoved", folder.ChildRemoved:Connect(function(child)
            if not isFolder(child) then
                return
            end

            managedFolders[child] = nil
            projectileModified[child] = nil
            projectileOriginals[child] = nil
        end))

        folderDestroyConn = Connections.add("WeaponsFolderDestroy", folder.Destroying:Connect(function()
            Weapons.weaponsFolder = nil
            clearFolderConns()
        end))
    end

    function Weapons.refresh()
        local folder = ReplicatedStorage:FindFirstChild(WEAPONS_NAME)

        if not folder then
            return Weapons
        end

        if not Weapons.running then
            return Weapons
        end

        attachWeaponFolder(folder)

        return Weapons
    end

    function Weapons.start()
        if Weapons.running then
            return Weapons
        end

        if not hasAnyEnabled() then
            return Weapons
        end

        Weapons.running = true

        captureBaseline()

        folderAddedConn = Connections.add("WeaponsFolderAdded", ReplicatedStorage.ChildAdded:Connect(function(child)
            if child.Name == WEAPONS_NAME and isFolder(child) then
                if not Weapons.baselineCaptured then
                    cacheNativeState(child)
                    Weapons.baselineCaptured = true
                end

                attachWeaponFolder(child)
            end
        end))

        local weaponsFolder = ReplicatedStorage:FindFirstChild(WEAPONS_NAME)

        if weaponsFolder then
            attachWeaponFolder(weaponsFolder)
        end

        return Weapons
    end

    function Weapons.stop()
        if not Weapons.running and next(managedFolders) == nil and next(projectileModified) == nil then
            return Weapons
        end

        Weapons.running = false
        Weapons.weaponsFolder = nil

        removeManagedMarkers()
        revertAllProjectiles()

        if folderAddedConn then
            Connections.disconnect("WeaponsFolderAdded")
            folderAddedConn = nil
        end

        clearFolderConns()

        return Weapons
    end

    function Weapons.setEnabled(feature, enabled)
        if type(feature) == "boolean" then
            enabled = feature
            feature = "InfiniteAmmo"
        end

        if type(feature) == "string" then
            if feature == "InfiniteAmmo" then
                Config.Feature3.InfiniteAmmo = enabled
            elseif feature == "ProjectileTravel" then
                Config.Feature3.ProjectileTravel = enabled
            end
        end

        if hasAnyEnabled() then
            if Weapons.running then
                applyStateToCurrent()
            else
                Weapons.start()
            end
        else
            Weapons.stop()
        end

        return Weapons
    end

    context.Weapons = Weapons

    return Weapons
end
