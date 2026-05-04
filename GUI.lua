return function(context)
    local HttpService = game:GetService("HttpService")
    local Config = context.Config

    local Gui = {
        running = false,
        Rayfield = nil,
        Window = nil,
        overlayEnabledToggle = nil
    }

    local saveFolder = "CometPrivate"
    local saveFile = saveFolder .. "/config.json"

    local bindOptions = {
        "RightClick",
        "LeftClick",
        "MiddleClick",
        "LeftAlt",
        "RightAlt",
        "RightShift",
        "LeftShift",
        "Insert",
        "Q",
        "E",
        "F",
        "C",
        "X",
        "Z",
        "V"
    }

    local bindMap = {
        RightClick = Enum.UserInputType.MouseButton2,
        LeftClick = Enum.UserInputType.MouseButton1,
        MiddleClick = Enum.UserInputType.MouseButton3,
        LeftAlt = Enum.KeyCode.LeftAlt,
        RightAlt = Enum.KeyCode.RightAlt,
        RightShift = Enum.KeyCode.RightShift,
        LeftShift = Enum.KeyCode.LeftShift,
        Insert = Enum.KeyCode.Insert,
        Q = Enum.KeyCode.Q,
        E = Enum.KeyCode.E,
        F = Enum.KeyCode.F,
        C = Enum.KeyCode.C,
        X = Enum.KeyCode.X,
        Z = Enum.KeyCode.Z,
        V = Enum.KeyCode.V
    }

    local bindDefaults = {
        HoldFeature1 = "RightClick",
        ToggleUI = "Insert",
        ToggleGUI = "RightShift"
    }

    local bindNames = {}

    for name, value in pairs(bindMap) do
        bindNames[value] = name
    end

    local function bindName(value, fallback)
        return bindNames[value] or fallback or "RightShift"
    end

    local function selected(option)
        if type(option) == "table" then
            if type(option[1]) == "string" then
                return option[1]
            end

            for key, value in pairs(option) do
                if value == true and type(key) == "string" then
                    return key
                end

                if type(value) == "string" then
                    return value
                end
            end
        end

        if type(option) == "string" then
            return option
        end

        return nil
    end

    local function fileApiReady()
        return typeof(writefile) == "function" and typeof(readfile) == "function" and typeof(isfile) == "function"
    end

    local function prepareFolder()
        if typeof(isfolder) == "function" and typeof(makefolder) == "function" and not isfolder(saveFolder) then
            pcall(function()
                makefolder(saveFolder)
            end)
        end
    end

    local function encodeColor(color)
        return {
            R = math.floor(color.R * 255 + 0.5),
            G = math.floor(color.G * 255 + 0.5),
            B = math.floor(color.B * 255 + 0.5)
        }
    end

    local function decodeColor(value)
        if type(value) ~= "table" then
            return nil
        end

        local r = math.clamp(tonumber(value.R) or 255, 0, 255)
        local g = math.clamp(tonumber(value.G) or 0, 0, 255)
        local b = math.clamp(tonumber(value.B) or 0, 0, 255)

        return Color3.fromRGB(r, g, b)
    end

    local function snapshot()
        return {
            Version = 1,
            Feature1 = {
                Enabled = Config.Feature1.Enabled,
                Range = Config.Feature1.Range,
                Speed = Config.Feature1.Speed,
                Part = Config.Feature1.Part,
                Check1 = Config.Feature1.Check1,
                Check2 = Config.Feature1.Check2
            },
            Feature2 = {
                Style1 = Config.Feature2.Style1,
                Style2 = Config.Feature2.Style2,
                Style3 = Config.Feature2.Style3,
                Style4 = Config.Feature2.Style4,
                Style5 = Config.Feature2.Style5,
                MainColor = encodeColor(Config.Feature2.MainColor),
                UseTeam = Config.Feature2.UseTeam
            },
            UI = {
                Enabled = Config.UI.Enabled
            },
            GUI = {
                Enabled = Config.GUI.Enabled
            },
            Keys = {
                HoldFeature1 = bindName(Config.Keys.HoldFeature1, bindDefaults.HoldFeature1),
                ToggleUI = bindName(Config.Keys.ToggleUI, bindDefaults.ToggleUI),
                ToggleGUI = bindName(Config.Keys.ToggleGUI, bindDefaults.ToggleGUI)
            }
        }
    end

    local function saveConfig()
        if not fileApiReady() then
            return false
        end

        prepareFolder()

        local ok = pcall(function()
            writefile(saveFile, HttpService:JSONEncode(snapshot()))
        end)

        return ok
    end

    local function applySaved(data)
        if type(data) ~= "table" then
            return
        end

        local feature1 = data.Feature1

        if type(feature1) == "table" then
            if type(feature1.Enabled) == "boolean" then
                Config.Feature1.Enabled = feature1.Enabled
            end

            if type(feature1.Range) == "number" then
                Config.Feature1.Range = math.clamp(feature1.Range, 1, 2000)
            end

            if type(feature1.Speed) == "number" then
                Config.Feature1.Speed = math.clamp(feature1.Speed, 1, 100)
            end

            if type(feature1.Part) == "string" and feature1.Part ~= "" then
                Config.Feature1.Part = feature1.Part
            end

            if type(feature1.Check1) == "boolean" then
                Config.Feature1.Check1 = feature1.Check1
            end

            if type(feature1.Check2) == "boolean" then
                Config.Feature1.Check2 = feature1.Check2
            end
        end

        local feature2 = data.Feature2

        if type(feature2) == "table" then
            if type(feature2.Style1) == "boolean" then
                Config.Feature2.Style1 = feature2.Style1
            end

            if type(feature2.Style2) == "boolean" then
                Config.Feature2.Style2 = feature2.Style2
            end

            if type(feature2.Style3) == "boolean" then
                Config.Feature2.Style3 = feature2.Style3
            end

            if type(feature2.Style4) == "boolean" then
                Config.Feature2.Style4 = feature2.Style4
            end

            if type(feature2.Style5) == "boolean" then
                Config.Feature2.Style5 = feature2.Style5
            end

            if type(feature2.UseTeam) == "boolean" then
                Config.Feature2.UseTeam = feature2.UseTeam
            end

            local color = decodeColor(feature2.MainColor)

            if color then
                Config.Feature2.MainColor = color
            end
        end

        if type(data.UI) == "table" and type(data.UI.Enabled) == "boolean" then
            Config.UI.Enabled = data.UI.Enabled
        end

        if type(data.GUI) == "table" and type(data.GUI.Enabled) == "boolean" then
            Config.GUI.Enabled = data.GUI.Enabled
        end

        if type(data.Keys) == "table" then
            for keyName in pairs(bindDefaults) do
                local bind = bindMap[data.Keys[keyName]]

                if bind then
                    Config.Keys[keyName] = bind
                end
            end
        end

        Config.Feature1.Active = false
    end

    local function loadConfig()
        if not fileApiReady() then
            return false
        end

        local exists = false
        pcall(function()
            exists = isfile(saveFile)
        end)

        if not exists then
            return false
        end

        local ok, contents = pcall(function()
            return readfile(saveFile)
        end)

        if not ok or type(contents) ~= "string" or contents == "" then
            return false
        end

        local decodedOk, data = pcall(function()
            return HttpService:JSONDecode(contents)
        end)

        if decodedOk then
            applySaved(data)
            return true
        end

        return false
    end

    local function setBind(keyName, option)
        local name = selected(option)
        local bind = bindMap[name]

        if bind then
            Config.Keys[keyName] = bind
            saveConfig()
        end
    end

    local function hideOverlay()
        if context.Overlay and context.Overlay.hideAll then
            context.Overlay.hideAll()
        end
    end

    function Gui.refresh()
        if Gui.overlayEnabledToggle then
            pcall(function()
                Gui.overlayEnabledToggle:Set(Config.UI.Enabled)
            end)
        end
    end

    function Gui.shouldBlockInput()
        return false
    end

    function Gui.toggleVisibility()
        if not Gui.Rayfield then
            return
        end

        pcall(function()
            Gui.Rayfield:SetVisibility(not Gui.Rayfield:IsVisible())
        end)
    end

    function Gui.saveConfig()
        return saveConfig()
    end

    function Gui.loadConfig()
        return loadConfig()
    end

    local function addBindDropdown(tab, label, keyName)
        tab:CreateDropdown({
            Name = label,
            Options = bindOptions,
            CurrentOption = {bindName(Config.Keys[keyName], bindDefaults[keyName])},
            MultipleOptions = false,
            Flag = keyName .. "BindDropdown",
            Callback = function(option)
                setBind(keyName, option)
            end
        })
    end

    local function createInterface()
        local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()
        local uiTitle = "Comet"

        local Window = Rayfield:CreateWindow({
            Name = uiTitle,
            Icon = 0,
            LoadingTitle = uiTitle,
            LoadingSubtitle = "private client",
            ShowText = uiTitle,
            Theme = "Default",
            DisableRayfieldPrompts = true,
            DisableBuildWarnings = true,
            ConfigurationSaving = {
                Enabled = false,
                FolderName = saveFolder,
                FileName = "rayfield-disabled"
            },
            Discord = {
                Enabled = false,
                Invite = "",
                RememberJoins = false
            },
            KeySystem = false
        })

        Gui.Rayfield = Rayfield
        Gui.Window = Window

        local AimTab = Window:CreateTab("Aiming", 0)
        local OverlayTab = Window:CreateTab("Overlay", 0)
        local SettingsTab = Window:CreateTab("Settings", 0)

        AimTab:CreateSection("Camera Assist")
        AimTab:CreateToggle({
            Name = "Enabled",
            CurrentValue = Config.Feature1.Enabled,
            Flag = "Feature1Enabled",
            Callback = function(value)
                Config.Feature1.Enabled = value

                if not value then
                    Config.Feature1.Active = false
                end

                saveConfig()
            end
        })

        addBindDropdown(AimTab, "Aim Hold Bind", "HoldFeature1")

        AimTab:CreateSlider({
            Name = "Range",
            Range = {1, 2000},
            Increment = 1,
            Suffix = "px",
            CurrentValue = Config.Feature1.Range,
            Flag = "Feature1Range",
            Callback = function(value)
                Config.Feature1.Range = value
                saveConfig()
            end
        })

        AimTab:CreateSlider({
            Name = "Speed",
            Range = {1, 100},
            Increment = 1,
            Suffix = "smooth",
            CurrentValue = Config.Feature1.Speed,
            Flag = "Feature1Speed",
            Callback = function(value)
                Config.Feature1.Speed = value
                saveConfig()
            end
        })

        AimTab:CreateInput({
            Name = "Target Part",
            CurrentValue = Config.Feature1.Part,
            PlaceholderText = "Head",
            RemoveTextAfterFocusLost = false,
            Flag = "Feature1Part",
            Callback = function(text)
                if text and text ~= "" then
                    Config.Feature1.Part = text
                    saveConfig()
                end
            end
        })

        AimTab:CreateToggle({
            Name = "Wall Check",
            CurrentValue = Config.Feature1.Check1,
            Flag = "Feature1WallCheck",
            Callback = function(value)
                Config.Feature1.Check1 = value
                saveConfig()
            end
        })

        AimTab:CreateToggle({
            Name = "Team Check",
            CurrentValue = Config.Feature1.Check2,
            Flag = "Feature1TeamCheck",
            Callback = function(value)
                Config.Feature1.Check2 = value
                saveConfig()
            end
        })

        OverlayTab:CreateSection("Visibility")
        Gui.overlayEnabledToggle = OverlayTab:CreateToggle({
            Name = "Overlay Enabled",
            CurrentValue = Config.UI.Enabled,
            Flag = "OverlayEnabled",
            Callback = function(value)
                Config.UI.Enabled = value

                if not value then
                    hideOverlay()
                end

                saveConfig()
            end
        })

        addBindDropdown(OverlayTab, "Overlay Toggle Bind", "ToggleUI")

        OverlayTab:CreateSection("Elements")
        OverlayTab:CreateToggle({
            Name = "Boxes",
            CurrentValue = Config.Feature2.Style1,
            Flag = "OverlayBoxes",
            Callback = function(value)
                Config.Feature2.Style1 = value
                saveConfig()
            end
        })

        OverlayTab:CreateToggle({
            Name = "Names",
            CurrentValue = Config.Feature2.Style2,
            Flag = "OverlayNames",
            Callback = function(value)
                Config.Feature2.Style2 = value
                saveConfig()
            end
        })

        OverlayTab:CreateToggle({
            Name = "Health Bar",
            CurrentValue = Config.Feature2.Style3,
            Flag = "OverlayHealthBar",
            Callback = function(value)
                Config.Feature2.Style3 = value
                saveConfig()
            end
        })

        OverlayTab:CreateToggle({
            Name = "Distance",
            CurrentValue = Config.Feature2.Style4,
            Flag = "OverlayDistance",
            Callback = function(value)
                Config.Feature2.Style4 = value
                saveConfig()
            end
        })

        OverlayTab:CreateToggle({
            Name = "Tracer",
            CurrentValue = Config.Feature2.Style5,
            Flag = "OverlayTracer",
            Callback = function(value)
                Config.Feature2.Style5 = value
                saveConfig()
            end
        })

        OverlayTab:CreateToggle({
            Name = "Team Color",
            CurrentValue = Config.Feature2.UseTeam,
            Flag = "OverlayTeamColor",
            Callback = function(value)
                Config.Feature2.UseTeam = value
                saveConfig()
            end
        })

        OverlayTab:CreateColorPicker({
            Name = "Main Color",
            Color = Config.Feature2.MainColor,
            Flag = "OverlayMainColor",
            Callback = function(value)
                Config.Feature2.MainColor = value
                saveConfig()
            end
        })

        SettingsTab:CreateSection("Interface")
        addBindDropdown(SettingsTab, "Menu Toggle Bind", "ToggleGUI")

        SettingsTab:CreateButton({
            Name = "Save Settings",
            Callback = function()
                saveConfig()
            end
        })

        SettingsTab:CreateButton({
            Name = "Hide Menu",
            Callback = function()
                Rayfield:SetVisibility(false)
            end
        })

        SettingsTab:CreateButton({
            Name = "Stop Client",
            Callback = function()
                if context.Main and context.Main.stop then
                    context.Main.stop()
                end
            end
        })
    end

    function Gui.start()
        if Gui.running or not Config.GUI.Enabled then
            return Gui
        end

        loadConfig()
        Gui.running = true
        createInterface()
        saveConfig()

        return Gui
    end

    function Gui.destroy()
        Config.Feature1.Active = false
        saveConfig()

        if Gui.Rayfield and Gui.Rayfield.Destroy then
            pcall(function()
                Gui.Rayfield:Destroy()
            end)
        end

        Gui.Rayfield = nil
        Gui.Window = nil
        Gui.overlayEnabledToggle = nil
        Gui.running = false

        return Gui
    end

    context.Gui = Gui

    return Gui
end
