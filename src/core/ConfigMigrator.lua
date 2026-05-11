return function(context)
    local Config = context.Config

    local ConfigMigrator = {
        CurrentVersion = 7
    }

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

    local function setBoolean(target, key, value)
        if type(value) == "boolean" then
            target[key] = value
        end
    end

    local function setNumber(target, key, value, minValue, maxValue, floorValue)
        if type(value) ~= "number" then
            return
        end

        local nextValue = math.clamp(value, minValue, maxValue)

        if floorValue then
            nextValue = math.floor(nextValue)
        end

        target[key] = nextValue
    end

    local function setString(target, key, value, allowed)
        if type(value) ~= "string" or value == "" then
            return
        end

        if allowed then
            for _, item in ipairs(allowed) do
                if value == item then
                    target[key] = value
                    return
                end
            end

            return
        end

        target[key] = value
    end

    function ConfigMigrator.snapshot()
        return {
            Version = ConfigMigrator.CurrentVersion,
            Feature1 = {
                Enabled = Config.Feature1.Enabled,
                Range = Config.Feature1.Range,
                Speed = Config.Feature1.Speed,
                Part = Config.Feature1.Part,
                Check1 = Config.Feature1.Check1,
                Check2 = Config.Feature1.Check2,
                ScanInterval = Config.Feature1.ScanInterval,
                MaxTargets = Config.Feature1.MaxTargets,
                MaxBelowLocal = Config.Feature1.MaxBelowLocal,
                AimMode = Config.Feature1.AimMode
            },
            Feature2 = {
                Style1 = Config.Feature2.Style1,
                Style2 = Config.Feature2.Style2,
                Style3 = Config.Feature2.Style3,
                Style4 = Config.Feature2.Style4,
                Style5 = Config.Feature2.Style5,
                MainColor = encodeColor(Config.Feature2.MainColor),
                UseTeam = Config.Feature2.UseTeam,
                TextSize = Config.Feature2.TextSize,
                BoxThickness = Config.Feature2.BoxThickness,
                TracerOrigin = Config.Feature2.TracerOrigin
            },
            Feature3 = {
                InfiniteAmmo = Config.Feature3.InfiniteAmmo,
                ProjectileTravel = Config.Feature3.ProjectileTravel,
                NoSpread = Config.Feature3.NoSpread,
                NoRecoilControl = Config.Feature3.NoRecoilControl
            },
            Input = {
                AimBind = Config.Input.AimBind,
                AimMode = Config.Input.AimMode,
                OverlayBind = Config.Input.OverlayBind,
                MenuBind = Config.Input.MenuBind,
                PanicBind = Config.Input.PanicBind
            },
            UI = {
                Enabled = Config.UI.Enabled,
                Provider = Config.UI.Provider,
                Theme = Config.UI.Theme,
                Acrylic = Config.UI.Acrylic,
                Transparency = Config.UI.Transparency,
                DrawingInset = Config.UI.DrawingInset,
                OverlayRate = Config.UI.OverlayRate
            },
            GUI = {
                Enabled = Config.GUI.Enabled
            },
            Profiles = {
                Active = Config.Profiles.Active,
                PerPlace = Config.Profiles.PerPlace
            },
            Diagnostics = {
                Enabled = Config.Diagnostics.Enabled,
                ShowBootStatus = Config.Diagnostics.ShowBootStatus
            }
        }
    end

    function ConfigMigrator.apply(data)
        if type(data) ~= "table" then
            return false
        end

        local feature1 = data.Feature1

        if type(feature1) == "table" then
            setBoolean(Config.Feature1, "Enabled", feature1.Enabled)
            setNumber(Config.Feature1, "Range", feature1.Range, 1, 2000)
            setNumber(Config.Feature1, "Speed", feature1.Speed, 1, 100)
            setString(Config.Feature1, "Part", feature1.Part)
            setBoolean(Config.Feature1, "Check1", feature1.Check1)
            setBoolean(Config.Feature1, "Check2", feature1.Check2)
            setNumber(Config.Feature1, "ScanInterval", feature1.ScanInterval, 0.02, 0.25)
            setNumber(Config.Feature1, "MaxTargets", feature1.MaxTargets, 8, 256, true)
            setNumber(Config.Feature1, "MaxBelowLocal", feature1.MaxBelowLocal, 10, 2000)
            setString(Config.Feature1, "AimMode", feature1.AimMode, {"Hold", "Toggle", "Always"})
        end

        local feature2 = data.Feature2

        if type(feature2) == "table" then
            setBoolean(Config.Feature2, "Style1", feature2.Style1)
            setBoolean(Config.Feature2, "Style2", feature2.Style2)
            setBoolean(Config.Feature2, "Style3", feature2.Style3)
            setBoolean(Config.Feature2, "Style4", feature2.Style4)
            setBoolean(Config.Feature2, "Style5", feature2.Style5)
            setBoolean(Config.Feature2, "UseTeam", feature2.UseTeam)
            setNumber(Config.Feature2, "TextSize", feature2.TextSize, 10, 20, true)
            setNumber(Config.Feature2, "BoxThickness", feature2.BoxThickness, 1, 5, true)
            setString(Config.Feature2, "TracerOrigin", feature2.TracerOrigin, {"Bottom", "Center", "Mouse"})

            local color = decodeColor(feature2.MainColor)

            if color then
                Config.Feature2.MainColor = color
            end
        end

        local feature3 = data.Feature3

        if type(feature3) == "table" then
            setBoolean(Config.Feature3, "InfiniteAmmo", feature3.InfiniteAmmo)
            setBoolean(Config.Feature3, "ProjectileTravel", feature3.ProjectileTravel)
            setBoolean(Config.Feature3, "NoSpread", feature3.NoSpread)
            setBoolean(Config.Feature3, "NoRecoilControl", feature3.NoRecoilControl)
        end

        local input = data.Input

        if type(input) == "table" then
            setString(Config.Input, "AimBind", input.AimBind)
            setString(Config.Input, "AimMode", input.AimMode, {"Hold", "Toggle", "Always"})
            setString(Config.Input, "OverlayBind", input.OverlayBind)
            setString(Config.Input, "MenuBind", input.MenuBind)
            setString(Config.Input, "PanicBind", input.PanicBind)
        elseif feature1 and type(feature1.AimMode) == "string" then
            setString(Config.Input, "AimMode", feature1.AimMode, {"Hold", "Toggle", "Always"})
        end

        Config.Feature1.AimMode = Config.Input.AimMode

        local ui = data.UI

        if type(ui) == "table" then
            setBoolean(Config.UI, "Enabled", ui.Enabled)
            setString(Config.UI, "Provider", ui.Provider, {"Fluent", "Rayfield"})
            setString(Config.UI, "Theme", ui.Theme)
            setBoolean(Config.UI, "Acrylic", ui.Acrylic)
            setBoolean(Config.UI, "Transparency", ui.Transparency)
            setBoolean(Config.UI, "DrawingInset", ui.DrawingInset)
            setNumber(Config.UI, "OverlayRate", ui.OverlayRate, 5, 60, true)
        end

        if type(data.GUI) == "table" then
            setBoolean(Config.GUI, "Enabled", data.GUI.Enabled)
        end

        if type(data.Profiles) == "table" then
            setString(Config.Profiles, "Active", data.Profiles.Active)
            setBoolean(Config.Profiles, "PerPlace", data.Profiles.PerPlace)
        end

        if type(data.Diagnostics) == "table" then
            setBoolean(Config.Diagnostics, "Enabled", data.Diagnostics.Enabled)
            setBoolean(Config.Diagnostics, "ShowBootStatus", data.Diagnostics.ShowBootStatus)
        end

        Config.Feature1.Active = false

        return true
    end

    context.ConfigMigrator = ConfigMigrator

    return ConfigMigrator
end
