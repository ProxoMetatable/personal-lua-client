return function(context)
    local Config = context.Config

    local Gui = {
        running = false,
        Rayfield = nil,
        Window = nil,
        overlayEnabledToggle = nil
    }

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

    local function createInterface()
        local Rayfield = loadstring(game:HttpGet("https://sirius.menu/rayfield"))()

        local Window = Rayfield:CreateWindow({
            Name = "personal-lua-client",
            Icon = 0,
            LoadingTitle = "personal-lua-client",
            LoadingSubtitle = "private dev client",
            ShowText = "personal-lua-client",
            Theme = "Default",
            DisableRayfieldPrompts = true,
            DisableBuildWarnings = true,
            ConfigurationSaving = {
                Enabled = false
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
            end
        })

        AimTab:CreateSlider({
            Name = "Range",
            Range = {1, 2000},
            Increment = 1,
            Suffix = "px",
            CurrentValue = Config.Feature1.Range,
            Flag = "Feature1Range",
            Callback = function(value)
                Config.Feature1.Range = value
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
                end
            end
        })

        AimTab:CreateToggle({
            Name = "Wall Check",
            CurrentValue = Config.Feature1.Check1,
            Flag = "Feature1WallCheck",
            Callback = function(value)
                Config.Feature1.Check1 = value
            end
        })

        AimTab:CreateToggle({
            Name = "Team Check",
            CurrentValue = Config.Feature1.Check2,
            Flag = "Feature1TeamCheck",
            Callback = function(value)
                Config.Feature1.Check2 = value
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
            end
        })

        OverlayTab:CreateSection("Elements")
        OverlayTab:CreateToggle({
            Name = "Boxes",
            CurrentValue = Config.Feature2.Style1,
            Flag = "OverlayBoxes",
            Callback = function(value)
                Config.Feature2.Style1 = value
            end
        })

        OverlayTab:CreateToggle({
            Name = "Names",
            CurrentValue = Config.Feature2.Style2,
            Flag = "OverlayNames",
            Callback = function(value)
                Config.Feature2.Style2 = value
            end
        })

        OverlayTab:CreateToggle({
            Name = "Health Bar",
            CurrentValue = Config.Feature2.Style3,
            Flag = "OverlayHealthBar",
            Callback = function(value)
                Config.Feature2.Style3 = value
            end
        })

        OverlayTab:CreateToggle({
            Name = "Distance",
            CurrentValue = Config.Feature2.Style4,
            Flag = "OverlayDistance",
            Callback = function(value)
                Config.Feature2.Style4 = value
            end
        })

        OverlayTab:CreateToggle({
            Name = "Tracer",
            CurrentValue = Config.Feature2.Style5,
            Flag = "OverlayTracer",
            Callback = function(value)
                Config.Feature2.Style5 = value
            end
        })

        OverlayTab:CreateToggle({
            Name = "Team Color",
            CurrentValue = Config.Feature2.UseTeam,
            Flag = "OverlayTeamColor",
            Callback = function(value)
                Config.Feature2.UseTeam = value
            end
        })

        OverlayTab:CreateColorPicker({
            Name = "Main Color",
            Color = Config.Feature2.MainColor,
            Flag = "OverlayMainColor",
            Callback = function(value)
                Config.Feature2.MainColor = value
            end
        })

        SettingsTab:CreateSection("Fixed Controls")
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

        Gui.running = true
        createInterface()

        return Gui
    end

    function Gui.destroy()
        Config.Feature1.Active = false

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
