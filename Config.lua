return function(context)
    local Config = {
        Name = "personal-lua-client",
        Version = "0.2.0",
        Enabled = true,
        Keys = {
            ToggleOverlay = Enum.KeyCode.Insert,
            HoldTargeting = Enum.KeyCode.RightAlt,
        },
        Targeting = {
            Enabled = false,
            Active = false,
            WallCheck = true,
            TeamCheck = true,
            MaxDistance = 1000,
            FieldOfView = 120,
        },
        Overlay = {
            Enabled = false,
            Boxes = true,
            Names = true,
            Distance = true,
            HealthBars = true,
            Tracers = false,
            TeamColors = true,
            FriendlyColor = Color3.fromRGB(80, 180, 255),
            EnemyColor = Color3.fromRGB(255, 85, 85),
            NeutralColor = Color3.fromRGB(235, 235, 235),
        },
        Cache = {
            RefreshRate = 0.25,
        },
    }

    context.Config = Config

    return Config
end
