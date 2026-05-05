return function(context)
    local ReplicatedStorage = game:GetService("ReplicatedStorage")
    local Config = context.Config
    local Connections = context.Connections

    local Weapons = {
        running = false,
        weaponsFolder = nil
    }

    local WEAPONS_NAME = "Weapons"
    local MARKER_NAME = "Infinite"

    local folderAddedConn = nil
    local folderChildConn = nil
    local folderDestroyConn = nil

    local function validWeaponsFolder(folder)
        return typeof(folder) == "Instance" and folder:IsA("Folder") and folder.Name == WEAPONS_NAME
    end

    local function ensureInfiniteMarker(folder)
        if not folder or not folder:IsA("Folder") then
            return false
        end

        local existing = folder:FindFirstChild(MARKER_NAME)

        if existing then
            return existing:IsA("Folder")
        end

        local marker = Instance.new("Folder")
        marker.Name = MARKER_NAME

        local added = false
        pcall(function()
            marker.Parent = folder
            added = true
        end)

        return added
    end

    local function processFolderChildren(folder)
        local children = folder:GetChildren()

        for _, child in ipairs(children) do
            if child:IsA("Folder") then
                ensureInfiniteMarker(child)
            end
        end
    end

    local function clearFolderConns()
        Connections.disconnect("WeaponsFolderChild")
        Connections.disconnect("WeaponsFolderDestroy")
        folderChildConn = nil
        folderDestroyConn = nil
    end

    local function attachWeaponFolder(folder)
        if not validWeaponsFolder(folder) then
            return
        end

        if Weapons.weaponsFolder == folder and folderChildConn and folderDestroyConn then
            return
        end

        Weapons.weaponsFolder = folder
        clearFolderConns()

        processFolderChildren(folder)

        folderChildConn = Connections.add("WeaponsFolderChild", folder.ChildAdded:Connect(function(child)
            if child:IsA("Folder") then
                ensureInfiniteMarker(child)
            end
        end))

        folderDestroyConn = Connections.add("WeaponsFolderDestroy", folder.Destroying:Connect(function()
            Weapons.weaponsFolder = nil
            clearFolderConns()
        end))
    end

    function Weapons.refresh()
        if not Config.Feature3 or not Config.Feature3.InfiniteAmmo then
            return Weapons
        end

        local folder = ReplicatedStorage:FindFirstChild(WEAPONS_NAME)

        if folder and validWeaponsFolder(folder) then
            attachWeaponFolder(folder)
        end

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

        local weaponsFolder = ReplicatedStorage:FindFirstChild(WEAPONS_NAME)

        if weaponsFolder then
            attachWeaponFolder(weaponsFolder)
        else
            folderAddedConn = Connections.add("WeaponsFolderAdded", ReplicatedStorage.ChildAdded:Connect(function(child)
                if child.Name == WEAPONS_NAME and child:IsA("Folder") then
                    attachWeaponFolder(child)
                end
            end))
        end

        return Weapons
    end

    function Weapons.stop()
        Weapons.running = false
        Weapons.weaponsFolder = nil

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
