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
    local SPREAD_NAME = "Spread"
    local SPREAD_RECOVERY_NAME = "SpreadRecovery"
    local RECOIL_CONTROL_NAME = "RecoilControl"
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
    local spreadOriginals = {}
    local spreadModified = {}
    local recoilOriginals = {}
    local recoilModified = {}

    local function isFolder(instance)
        return typeof(instance) == "Instance" and instance:IsA("Folder")
    end

    local function isWeaponsFolder(instance)
        return isFolder(instance) and instance.Name == WEAPONS_NAME
    end

    local function hasAnyEnabled()
        return Config.Feature3 and (Config.Feature3.InfiniteAmmo or Config.Feature3.ProjectileTravel or Config.Feature3.NoSpread or Config.Feature3.NoRecoilControl)
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

    local function snapshotNumericValues(weapon, valueNames)
        if not isFolder(weapon) then
            return nil
        end

        local data = {}

        for _, name in ipairs(valueNames) do
            local valueObj = weapon:FindFirstChild(name)

            if isNumericValue(valueObj) then
                data[name] = valueObj.Value
            end
        end

        if next(data) ~= nil then
            return data
        end

        return nil
    end

    local function snapshotSpreadValues(weapon)
        if not isFolder(weapon) then
            return
        end

        if spreadOriginals[weapon] then
            return
        end

        local values = snapshotNumericValues(weapon, {SPREAD_NAME, SPREAD_RECOVERY_NAME})

        if values then
            spreadOriginals[weapon] = values
        end
    end

    local function snapshotRecoilValues(weapon)
        if not isFolder(weapon) then
            return
        end

        if recoilOriginals[weapon] then
            return
        end

        local values = snapshotNumericValues(weapon, {RECOIL_CONTROL_NAME})

        if values then
            recoilOriginals[weapon] = values
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

    local function applyValueSettings(weapon, values, originals, modified, enabled, value)
        local touched = {}
        local snapshot = originals[weapon]

        if not snapshot then
            return
        end

        for _, name in ipairs(values) do
            local valueObj = weapon:FindFirstChild(name)

            if isNumericValue(valueObj) and snapshot[name] ~= nil then
                if enabled then
                    pcall(function()
                        valueObj.Value = value
                    end)
                end

                touched[name] = true
            end
        end

        if next(touched) ~= nil then
            modified[weapon] = touched
        else
            modified[weapon] = nil
        end
    end

    local function applySpreadSettings(weapon, enabled)
        if not isFolder(weapon) then
            return
        end

        snapshotSpreadValues(weapon)

        if not spreadOriginals[weapon] then
            return
        end

        applyValueSettings(weapon, {SPREAD_NAME, SPREAD_RECOVERY_NAME}, spreadOriginals, spreadModified, enabled, 0)
    end

    local function revertSettings(weapon, originals, modified)
        local touched = modified[weapon]

        if not touched then
            return
        end

        local snapshot = originals[weapon]

        if not snapshot then
            modified[weapon] = nil
            return
        end

        for name in pairs(touched) do
            local valueObj = weapon:FindFirstChild(name)

            if isNumericValue(valueObj) and snapshot[name] ~= nil then
                pcall(function()
                    valueObj.Value = snapshot[name]
                end)
            end
        end

        modified[weapon] = nil
    end

    local function applyRecoilSettings(weapon, enabled)
        if not isFolder(weapon) then
            return
        end

        snapshotRecoilValues(weapon)

        if not recoilOriginals[weapon] then
            return
        end

        applyValueSettings(weapon, {RECOIL_CONTROL_NAME}, recoilOriginals, recoilModified, enabled, 0)
    end

    local function revertSpreadSettings(weapon)
        revertSettings(weapon, spreadOriginals, spreadModified)
    end

    local function revertRecoilSettings(weapon)
        revertSettings(weapon, recoilOriginals, recoilModified)
    end

    local function revertAllProjectiles()
        for weapon in pairs(projectileModified) do
            revertProjectileSettings(weapon)
        end
    end

    local function revertAllSpreads()
        for weapon in pairs(spreadModified) do
            revertSpreadSettings(weapon)
        end
    end

    local function revertAllRecoil()
        for weapon in pairs(recoilModified) do
            revertRecoilSettings(weapon)
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

        if Config.Feature3.NoSpread then
            applySpreadSettings(child, true)
        end

        if Config.Feature3.NoRecoilControl then
            applyRecoilSettings(child, true)
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

        if not Config.Feature3.NoSpread then
            revertAllSpreads()
        end

        if not Config.Feature3.NoRecoilControl then
            revertAllRecoil()
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
            spreadModified[child] = nil
            spreadOriginals[child] = nil
            recoilModified[child] = nil
            recoilOriginals[child] = nil
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
        if not Weapons.running and next(managedFolders) == nil and next(projectileModified) == nil and next(spreadModified) == nil and next(recoilModified) == nil then
            return Weapons
        end

        Weapons.running = false
        Weapons.weaponsFolder = nil

        removeManagedMarkers()
        revertAllProjectiles()
        revertAllSpreads()
        revertAllRecoil()

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
            elseif feature == "NoSpread" then
                Config.Feature3.NoSpread = enabled
            elseif feature == "NoRecoilControl" then
                Config.Feature3.NoRecoilControl = enabled
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
