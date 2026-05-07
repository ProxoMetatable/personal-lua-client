return function(context)
    local HttpService = game:GetService("HttpService")

    local Config = context.Config
    local ConfigMigrator = context.ConfigMigrator
    local Weapons = context.Weapons
    local UIAdapter = context.UIAdapter

    local Gui = {
        running = false,
        UI = nil,
        Window = nil,
        Library = nil,
        overlayEnabledToggle = nil,
        activeProfileInput = nil
    }

    local saveRoot = "CometPrivate"
    local legacySaveFile = saveRoot .. "/config.json"
    local SAVE_DEBOUNCE = 0.45
    local saveToken = 0
    local savePending = false
    local pendingProfileName = nil

    local function fileApiReady()
        return typeof(writefile) == "function"
            and typeof(readfile) == "function"
            and typeof(isfile) == "function"
    end

    local function folderApiReady()
        return typeof(isfolder) == "function" and typeof(makefolder) == "function"
    end

    local function ensureFolder(path)
        if not folderApiReady() then
            return
        end

        local current = ""

        for segment in string.gmatch(path, "[^/]+") do
            if current == "" then
                current = segment
            else
                current = current .. "/" .. segment
            end

            if not isfolder(current) then
                pcall(function()
                    makefolder(current)
                end)
            end
        end
    end

    local function trim(value)
        return tostring(value or ""):match("^%s*(.-)%s*$")
    end

    local function sanitizeProfileName(value)
        local cleaned = trim(value)

        if cleaned == "" then
            cleaned = "default"
        end

        cleaned = cleaned:gsub("[^%w%-%_%. ]", "_")

        if cleaned == "" then
            cleaned = "default"
        end

        return cleaned
    end

    local function placeFolder()
        if not Config.Profiles.PerPlace then
            return "global"
        end

        local ok, placeId = pcall(function()
            return tostring(game.PlaceId)
        end)

        if ok and placeId and placeId ~= "" then
            return placeId
        end

        return "global"
    end

    local function profileFolder()
        return (Config.Profiles.Folder or (saveRoot .. "/profiles")) .. "/" .. placeFolder()
    end

    local function profileFile(profileName)
        return profileFolder() .. "/" .. sanitizeProfileName(profileName or Config.Profiles.Active) .. ".json"
    end

    local function readJson(path)
        if not fileApiReady() then
            return nil
        end

        local exists = false

        pcall(function()
            exists = isfile(path)
        end)

        if not exists then
            return nil
        end

        local ok, contents = pcall(function()
            return readfile(path)
        end)

        if not ok or type(contents) ~= "string" or contents == "" then
            return nil
        end

        local decodedOk, data = pcall(function()
            return HttpService:JSONDecode(contents)
        end)

        if decodedOk then
            return data
        end

        return nil
    end

    local function writeJson(path, data)
        if not fileApiReady() then
            return false
        end

        local folder = path:match("^(.*)/[^/]+$")

        if folder then
            ensureFolder(folder)
        end

        local ok = pcall(function()
            writefile(path, HttpService:JSONEncode(data))
        end)

        return ok
    end

    local function normalizeDropdown(value)
        if type(value) == "string" then
            return value
        end

        if type(value) == "table" then
            if type(value[1]) == "string" then
                return value[1]
            end

            for key, enabled in pairs(value) do
                if enabled then
                    return key
                end
            end
        end

        return nil
    end

    local function bindingName(value)
        if type(value) == "string" then
            return value
        end

        local text = tostring(value or "")
        local name = text:match("%.([^%.]+)$") or text

        if name == "MouseButton1" then
            return "MB1"
        elseif name == "MouseButton2" then
            return "MB2"
        elseif name == "MouseButton3" then
            return "MB3"
        end

        return name
    end

    local function hideOverlay()
        if context.Overlay and context.Overlay.hideAll then
            context.Overlay.hideAll()
        end
    end

    local function diagnosticSummary()
        local diagnostics = context.Diagnostics or {}
        local boot = diagnostics.Boot or {}
        local runtime = diagnostics.Runtime or {}
        local moduleCount = 0
        local failedCount = 0

        for _, status in pairs(diagnostics.Modules or {}) do
            moduleCount += 1

            if status.Status ~= "Loaded" then
                failedCount += 1
            end
        end

        local target = runtime.LastTarget or "none"
        local cachedModels = runtime.CachedModels and tostring(runtime.CachedModels) or "n/a"
        local fps = runtime.Fps and tostring(math.floor(runtime.Fps + 0.5)) or "n/a"
        local frameMs = runtime.FrameMs and string.format("%.2f", runtime.FrameMs) or "n/a"
        local version = Config.Version
        local versionText = (version.Number or "0.0.0") .. " / " .. (version.Status or "Checking")

        return table.concat({
            "Boot: " .. tostring(boot.Status or "Unknown"),
            "Modules: " .. tostring(moduleCount - failedCount) .. " loaded, " .. tostring(failedCount) .. " failed",
            "Version: " .. versionText,
            "UI: " .. tostring(Config.UI.Provider),
            "Profile: " .. tostring(Config.Profiles.Active),
            "FPS: " .. fps,
            "Frame: " .. frameMs .. " ms",
            "Cached models: " .. cachedModels,
            "Target: " .. target
        }, "\n")
    end

    local function flushSaveConfig(profileName)
        if not ConfigMigrator then
            return false
        end

        local active = sanitizeProfileName(profileName or Config.Profiles.Active)
        Config.Profiles.Active = active
        savePending = false
        pendingProfileName = nil

        local snapshot = ConfigMigrator.snapshot()
        local ok = writeJson(profileFile(active), snapshot)

        if ok then
            writeJson(legacySaveFile, snapshot)
        end

        if Config.Diagnostics then
            Config.Diagnostics.LastConfigSaveAt = os.clock()
            Config.Diagnostics.LastConfigSaveOk = ok
        end

        return ok
    end

    local function cancelPendingSave()
        saveToken += 1
        savePending = false
        pendingProfileName = nil
    end

    local function saveConfig(profileName, immediate)
        if not ConfigMigrator then
            return false
        end

        local active = sanitizeProfileName(profileName or Config.Profiles.Active)
        Config.Profiles.Active = active
        pendingProfileName = active

        if immediate then
            saveToken += 1
            return flushSaveConfig(active)
        end

        savePending = true
        saveToken += 1

        local token = saveToken

        if task and task.delay then
            task.delay(SAVE_DEBOUNCE, function()
                if token ~= saveToken or not savePending then
                    return
                end

                flushSaveConfig(pendingProfileName)
            end)

            return true
        end

        return flushSaveConfig(active)
    end

    local function loadConfig(profileName)
        if not ConfigMigrator then
            return false
        end

        cancelPendingSave()

        local active = sanitizeProfileName(profileName or Config.Profiles.Active)
        local data = readJson(profileFile(active))

        if not data and active == "default" then
            data = readJson(legacySaveFile)
        end

        if not data then
            return false
        end

        local applied = ConfigMigrator.apply(data)

        if applied then
            Config.Profiles.Active = active
        end

        return applied
    end

    local function syncWeapons()
        if Weapons and Weapons.syncState then
            Weapons.syncState()
        end
    end

    local function setToggle(control, value)
        if not control then
            return
        end

        pcall(function()
            if control.SetValue then
                control:SetValue(value)
            elseif control.Set then
                control:Set(value)
            end
        end)
    end

    function Gui.refresh()
        setToggle(Gui.overlayEnabledToggle, Config.UI.Enabled)
    end

    function Gui.saveConfig(profileName)
        return saveConfig(profileName)
    end

    function Gui.flushConfig(profileName)
        return saveConfig(profileName, true)
    end

    function Gui.loadConfig(profileName)
        local loaded = loadConfig(profileName)

        if loaded then
            syncWeapons()
            Gui.refresh()
        end

        return loaded
    end

    function Gui.notify(title, content, duration, subContent)
        if Gui.UI and Gui.UI.notify then
            Gui.UI:notify(title, content, duration, subContent)
        end
    end

    local function addAimTab(tab)
        tab:addSection("Camera Assist")

        tab:addToggle("Feature1Enabled", {
            title = "Enabled",
            default = Config.Feature1.Enabled,
            callback = function(value)
                Config.Feature1.Enabled = value

                if not value then
                    Config.Feature1.Active = false
                end

                saveConfig()
            end
        })

        tab:addDropdown("Feature1AimMode", {
            title = "Activation Mode",
            values = {"Hold", "Toggle", "Always"},
            default = Config.Input.AimMode,
            callback = function(value)
                local selected = normalizeDropdown(value)

                if selected then
                    Config.Input.AimMode = selected
                    Config.Feature1.AimMode = selected
                    Config.Feature1.Active = false
                    saveConfig()
                end
            end
        })

        tab:addKeybind("Feature1AimBind", {
            title = "Activation Bind",
            mode = "Hold",
            default = Config.Input.AimBind,
            changedCallback = function(value)
                Config.Input.AimBind = bindingName(value)
                Config.Feature1.Active = false
                saveConfig()
            end
        })

        tab:addSlider("Feature1Range", {
            title = "Range",
            min = 1,
            max = 2000,
            rounding = 1,
            suffix = "px",
            default = Config.Feature1.Range,
            callback = function(value)
                Config.Feature1.Range = value
                saveConfig()
            end
        })

        tab:addSlider("Feature1Speed", {
            title = "Speed",
            min = 1,
            max = 100,
            rounding = 1,
            suffix = "smooth",
            default = Config.Feature1.Speed,
            callback = function(value)
                Config.Feature1.Speed = value
                saveConfig()
            end
        })

        tab:addInput("Feature1Part", {
            title = "Target Part",
            default = Config.Feature1.Part,
            placeholder = "Head",
            callback = function(text)
                if text and text ~= "" then
                    Config.Feature1.Part = text
                    saveConfig()
                end
            end
        })

        tab:addToggle("Feature1WallCheck", {
            title = "Wall Check",
            default = Config.Feature1.Check1,
            callback = function(value)
                Config.Feature1.Check1 = value
                saveConfig()
            end
        })

        tab:addToggle("Feature1TeamCheck", {
            title = "Team Check",
            default = Config.Feature1.Check2,
            callback = function(value)
                Config.Feature1.Check2 = value
                saveConfig()
            end
        })

        tab:addSection("Performance")

        tab:addSlider("Feature1ScanRate", {
            title = "Scan Rate",
            min = 4,
            max = 50,
            rounding = 1,
            suffix = "hz",
            default = math.floor(1 / math.max(Config.Feature1.ScanInterval, 0.02) + 0.5),
            callback = function(value)
                Config.Feature1.ScanInterval = 1 / math.clamp(value, 4, 50)
                saveConfig()
            end
        })

        tab:addSlider("Feature1MaxTargets", {
            title = "Max Cached Targets",
            min = 8,
            max = 256,
            rounding = 1,
            suffix = "models",
            default = Config.Feature1.MaxTargets,
            callback = function(value)
                Config.Feature1.MaxTargets = math.floor(value)
                saveConfig()
            end
        })

        tab:addSlider("Feature1MaxBelowLocal", {
            title = "Max Below Local",
            min = 10,
            max = 2000,
            rounding = 1,
            suffix = "studs",
            default = Config.Feature1.MaxBelowLocal,
            callback = function(value)
                Config.Feature1.MaxBelowLocal = value
                saveConfig()
            end
        })
    end

    local function addOverlayTab(tab)
        tab:addSection("Visibility")

        Gui.overlayEnabledToggle = tab:addToggle("OverlayEnabled", {
            title = "Overlay Enabled",
            default = Config.UI.Enabled,
            callback = function(value)
                Config.UI.Enabled = value

                if not value then
                    hideOverlay()
                end

                saveConfig()
            end
        })

        tab:addKeybind("OverlayBind", {
            title = "Overlay Toggle Bind",
            mode = "Toggle",
            default = Config.Input.OverlayBind,
            changedCallback = function(value)
                Config.Input.OverlayBind = bindingName(value)
                saveConfig()
            end
        })

        tab:addSection("Elements")

        tab:addToggle("OverlayBoxes", {
            title = "Boxes",
            default = Config.Feature2.Style1,
            callback = function(value)
                Config.Feature2.Style1 = value
                saveConfig()
            end
        })

        tab:addToggle("OverlayNames", {
            title = "Names",
            default = Config.Feature2.Style2,
            callback = function(value)
                Config.Feature2.Style2 = value
                saveConfig()
            end
        })

        tab:addToggle("OverlayHealthBar", {
            title = "Health Bar",
            default = Config.Feature2.Style3,
            callback = function(value)
                Config.Feature2.Style3 = value
                saveConfig()
            end
        })

        tab:addToggle("OverlayDistance", {
            title = "Distance",
            default = Config.Feature2.Style4,
            callback = function(value)
                Config.Feature2.Style4 = value
                saveConfig()
            end
        })

        tab:addToggle("OverlayTracer", {
            title = "Tracer",
            default = Config.Feature2.Style5,
            callback = function(value)
                Config.Feature2.Style5 = value
                saveConfig()
            end
        })

        tab:addToggle("OverlayTeamColor", {
            title = "Team Color",
            default = Config.Feature2.UseTeam,
            callback = function(value)
                Config.Feature2.UseTeam = value
                saveConfig()
            end
        })

        tab:addColorPicker("OverlayMainColor", {
            title = "Main Color",
            color = Config.Feature2.MainColor,
            callback = function(value)
                if value then
                    Config.Feature2.MainColor = value
                    saveConfig()
                end
            end
        })

        tab:addSlider("OverlayTextSize", {
            title = "Text Size",
            min = 10,
            max = 20,
            rounding = 1,
            default = Config.Feature2.TextSize,
            callback = function(value)
                Config.Feature2.TextSize = math.floor(value)
                saveConfig()
            end
        })

        tab:addSlider("OverlayBoxThickness", {
            title = "Box Thickness",
            min = 1,
            max = 5,
            rounding = 1,
            default = Config.Feature2.BoxThickness,
            callback = function(value)
                Config.Feature2.BoxThickness = math.floor(value)
                saveConfig()
            end
        })

        tab:addDropdown("OverlayTracerOrigin", {
            title = "Tracer Origin",
            values = {"Bottom", "Center", "Mouse"},
            default = Config.Feature2.TracerOrigin,
            callback = function(value)
                local selected = normalizeDropdown(value)

                if selected then
                    Config.Feature2.TracerOrigin = selected
                    saveConfig()
                end
            end
        })
    end

    local function addWeaponsTab(tab)
        tab:addSection("Ammunition")

        tab:addToggle("InfiniteAmmo", {
            title = "Infinite Ammo",
            default = Config.Feature3.InfiniteAmmo,
            callback = function(value)
                Config.Feature3.InfiniteAmmo = value

                if Weapons and Weapons.setEnabled then
                    Weapons.setEnabled("InfiniteAmmo", value)
                end

                saveConfig()
            end
        })

        tab:addToggle("ProjectileTravel", {
            title = "Projectile Travel Instantly",
            default = Config.Feature3.ProjectileTravel,
            callback = function(value)
                Config.Feature3.ProjectileTravel = value

                if Weapons and Weapons.setEnabled then
                    Weapons.setEnabled("ProjectileTravel", value)
                end

                saveConfig()
            end
        })

        tab:addToggle("NoSpread", {
            title = "No Spread",
            default = Config.Feature3.NoSpread,
            callback = function(value)
                Config.Feature3.NoSpread = value

                if Weapons and Weapons.setEnabled then
                    Weapons.setEnabled("NoSpread", value)
                end

                saveConfig()
            end
        })

        tab:addToggle("NoRecoilControl", {
            title = "No Recoil",
            default = Config.Feature3.NoRecoilControl,
            callback = function(value)
                Config.Feature3.NoRecoilControl = value

                if Weapons and Weapons.setEnabled then
                    Weapons.setEnabled("NoRecoilControl", value)
                end

                saveConfig()
            end
        })
    end

    local function addSettingsTab(tab)
        tab:addSection("Profiles")

        Gui.activeProfileInput = tab:addInput("ProfileName", {
            title = "Profile Name",
            default = Config.Profiles.Active,
            placeholder = "default",
            callback = function(value)
                Config.Profiles.Active = sanitizeProfileName(value)
            end
        })

        tab:addToggle("ProfilesPerPlace", {
            title = "Per-Place Profiles",
            default = Config.Profiles.PerPlace,
            callback = function(value)
                Config.Profiles.PerPlace = value
                saveConfig()
            end
        })

        tab:addButton({
            title = "Save Profile",
            description = "Writes the active settings to the selected profile.",
            callback = function()
                if saveConfig(Config.Profiles.Active, true) then
                    Gui.notify("Comet", "Saved profile " .. Config.Profiles.Active .. ".", 4)
                else
                    Gui.notify("Comet", "Profile save failed.", 4)
                end
            end
        })

        tab:addButton({
            title = "Load Profile",
            description = "Applies settings from the selected profile.",
            callback = function()
                if Gui.loadConfig(Config.Profiles.Active) then
                    Gui.notify("Comet", "Loaded profile " .. Config.Profiles.Active .. ".", 4)
                else
                    Gui.notify("Comet", "Profile not found.", 4)
                end
            end
        })

        tab:addSection("Interface")

        tab:addDropdown("UIProvider", {
            title = "UI Provider",
            values = {"Fluent", "Rayfield"},
            default = Config.UI.Provider,
            callback = function(value)
                local selected = normalizeDropdown(value)

                if selected then
                    Config.UI.Provider = selected
                    saveConfig()
                    Gui.notify("Comet", "Restart the client to apply " .. selected .. ".", 5)
                end
            end
        })

        tab:addInput("UITheme", {
            title = "Theme",
            default = Config.UI.Theme,
            placeholder = "Dark",
            callback = function(value)
                if value and value ~= "" then
                    Config.UI.Theme = value
                    saveConfig()
                end
            end
        })

        tab:addToggle("UIAcrylic", {
            title = "Acrylic",
            default = Config.UI.Acrylic,
            callback = function(value)
                Config.UI.Acrylic = value
                saveConfig()
                Gui.notify("Comet", "Restart the client to apply acrylic changes.", 4)
            end
        })

        tab:addToggle("UITransparency", {
            title = "Transparency",
            default = Config.UI.Transparency,
            callback = function(value)
                Config.UI.Transparency = value
                saveConfig()
                Gui.notify("Comet", "Restart the client to apply transparency changes.", 4)
            end
        })

        tab:addKeybind("MenuBind", {
            title = "Menu Bind",
            mode = "Toggle",
            default = Config.Input.MenuBind,
            changedCallback = function(value)
                Config.Input.MenuBind = bindingName(value)
                saveConfig()
                Gui.notify("Comet", "Restart the client to apply the menu bind.", 4)
            end
        })

        tab:addKeybind("PanicBind", {
            title = "Panic Stop Bind",
            mode = "Toggle",
            default = Config.Input.PanicBind,
            changedCallback = function(value)
                Config.Input.PanicBind = bindingName(value)
                saveConfig()
            end
        })

        tab:addButton({
            title = "Hide Menu",
            callback = function()
                if Gui.Library and Gui.Library.SetVisibility then
                    Gui.Library:SetVisibility(false)
                else
                    Gui.notify("Comet", "Use " .. tostring(Config.Input.MenuBind) .. " to minimize the menu.", 4)
                end
            end
        })

        tab:addButton({
            title = "Stop Client",
            callback = function()
                if context.Main and context.Main.stop then
                    context.Main.stop()
                end
            end
        })
    end

    local function addDiagnosticsTab(tab)
        tab:addSection("Status")

        tab:addParagraph({
            title = "Snapshot",
            content = diagnosticSummary()
        })

        tab:addButton({
            title = "Show Diagnostics",
            description = "Displays the current boot and runtime state.",
            callback = function()
                Gui.notify("Comet Diagnostics", diagnosticSummary(), 8)
            end
        })

        tab:addButton({
            title = "Check Version",
            callback = function()
                if context.VersionCheck and context.VersionCheck.check then
                    local status = context.VersionCheck.check()
                    Gui.notify("Comet", "Version status: " .. tostring(status), 5)
                else
                    Gui.notify("Comet", "Version checker is unavailable.", 4)
                end
            end
        })
    end

    local function createInterface()
        if not UIAdapter then
            Gui.notify("Comet", "UI adapter is unavailable.", 4)
            return
        end

        local version = Config.Version
        local ui = UIAdapter.createWindow({
            title = Config.Name,
            subtitle = (version.Number or "0.0.0") .. " / " .. (version.Channel or "stable")
        })

        if not ui then
            warn("Comet GUI: failed to create UI")
            return
        end

        Gui.UI = ui
        Gui.Window = ui.Window
        Gui.Library = ui.Library

        local aimTab = ui:addTab("Aim", "Aiming", "crosshair")
        local overlayTab = ui:addTab("Overlay", "Overlay", "scan")
        local weaponsTab = ui:addTab("Weapons", "Weapons", "target")
        local settingsTab = ui:addTab("Settings", "Settings", "settings")
        local diagnosticsTab = ui:addTab("Diagnostics", "Diagnostics", "activity")

        addAimTab(aimTab)
        addOverlayTab(overlayTab)
        addWeaponsTab(weaponsTab)
        addSettingsTab(settingsTab)
        addDiagnosticsTab(diagnosticsTab)

        ui:selectTab(1)
        Gui.notify("Comet", "Loaded with " .. tostring(ui.Provider) .. ".", 5)
    end

    function Gui.start()
        if Gui.running or not Config.GUI.Enabled then
            return Gui
        end

        loadConfig(Config.Profiles.Active)
        Gui.running = true

        local ok, err = pcall(createInterface)

        if not ok then
            Gui.running = false

            if Gui.UI and Gui.UI.destroy then
                pcall(function()
                    Gui.UI:destroy()
                end)
            end

            Gui.UI = nil
            Gui.Window = nil
            Gui.Library = nil

            if Config.Diagnostics then
                Config.Diagnostics.LastMessage = "GUI failed: " .. tostring(err)
            end
            warn("Comet GUI: " .. tostring(err))
            return Gui
        end

        saveConfig(Config.Profiles.Active, true)

        return Gui
    end

    function Gui.destroy()
        Config.Feature1.Active = false
        saveConfig(Config.Profiles.Active, true)

        if Gui.UI and Gui.UI.destroy then
            Gui.UI:destroy()
        end

        Gui.UI = nil
        Gui.Window = nil
        Gui.Library = nil
        Gui.overlayEnabledToggle = nil
        Gui.activeProfileInput = nil
        Gui.running = false

        return Gui
    end

    context.Gui = Gui

    return Gui
end
