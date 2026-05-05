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

    local folderAddedConn = nil
    local folderChildConn = nil
    local folderDestroyConn = nil
    local baselineConn = nil

    local nativeInfinite = {}
    local managedFolders = {}
    local scannedWeaponFolders = {}

    local function isFolder(instance)
        return typeof(instance) == "Instance" and instance:IsA("Folder")
    end

    local function isWeaponsFolder(instance)
        return isFolder(instance) and instance.Name == WEAPONS_NAME
    end

    local function hasMarker(folder)
        if not folder then
            return nil
        end

        return folder:FindFirstChild(MARKER_NAME)
    end

    local function cacheNativeState(folder)
        if not isWeaponsFolder(folder) then
            return
        end

        if scannedWeaponFolders[folder] then
            return
        end

        scannedWeaponFolders[folder] = true

        local children = folder:GetChildren()

        for _, child in ipairs(children) do
            if isFolder(child) and hasMarker(child) then
                nativeInfinite[child] = true
            end
        end
    end

    local function removeManagedMarkers()
        for folder in pairs(managedFolders) do
            if isFolder(folder) then
                local marker = folder:FindFirstChild(MARKER_NAME)

                if marker and marker:IsA("Folder") then
                    pcall(function()
                        marker:Destroy()
                    end)
                end
            end
        end

        managedFolders = {}
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

    local function processWeaponFolderChild(child)
        if not isFolder(child) then
            return
        end

        local marker = hasMarker(child)

        if marker then
            return
        end

        if nativeInfinite[child] then
            return
        end

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

    local function processWeaponFolderChildren(folder)
        if not isWeaponsFolder(folder) then
            return
        end

        local children = folder:GetChildren()

        for _, child in ipairs(children) do
            processWeaponFolderChild(child)
        end
    end

    local function clearFolderConns()
        Connections.disconnect("WeaponsFolderChild")
        Connections.disconnect("WeaponsFolderDestroy")
        folderChildConn = nil
        folderDestroyConn = nil
    end

    captureBaseline()

    local function attachWeaponFolder(folder)
        if not isWeaponsFolder(folder) then
            return
        end

        if Weapons.weaponsFolder == folder and folderChildConn and folderDestroyConn then
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

        if not (Config.Feature3 and Config.Feature3.InfiniteAmmo) then
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

        if weaponsFolder and isWeaponsFolder(weaponsFolder) then
            if not Weapons.baselineCaptured then
                cacheNativeState(weaponsFolder)
                Weapons.baselineCaptured = true
            end

            attachWeaponFolder(weaponsFolder)
        end

        return Weapons
    end

    function Weapons.stop()
        if not Weapons.running and next(managedFolders) == nil then
            return Weapons
        end

        Weapons.running = false
        Weapons.weaponsFolder = nil

        removeManagedMarkers()

        if folderAddedConn then
            Connections.disconnect("WeaponsFolderAdded")
            folderAddedConn = nil
        end

        clearFolderConns()

        return Weapons
    end

    function Weapons.setEnabled(enabled)
        if Config.Feature3 then
            Config.Feature3.InfiniteAmmo = enabled
        end

        if enabled then
            Weapons.start()
        else
            Weapons.stop()
        end

        return Weapons
    end

    context.Weapons = Weapons

    return Weapons
end
