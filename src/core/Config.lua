return function(context)
    local release = context.Version or {}
    local manifest = context.Manifest or {}
    local versionNumber = release.Version or release.Number or manifest.Version or "1.2.4"

    local Config = {
        Name = "Comet",
        Version = {
            Number = versionNumber,
            Latest = nil,
            Build = tonumber(release.Build) or tonumber(manifest.Build) or 124,
            LatestBuild = nil,
            Channel = release.Channel or manifest.Channel or "stable",
            Status = "Checking",
            Severity = "Unknown",
            Changelog = release.Changelog or {},
            CheckInterval = tonumber(manifest.CheckInterval) or 300
        },
        Loader = {
            Version = context.LoaderVersion or 1,
            Status = context.Diagnostics and context.Diagnostics.Boot and context.Diagnostics.Boot.Status or "Booting"
        },
        Feature1 = {
            Enabled = true,
            Active = false,
            Range = 150,
            Speed = 8,
            Part = "Head",
            Check1 = true,
            Check2 = true,
            ScanInterval = 0.05,
            MaxTargets = 64,
            MaxBelowLocal = 220,
            AimMode = "Hold"
        },
        Feature2 = {
            Style1 = true,
            Style2 = true,
            Style3 = true,
            Style4 = true,
            Style5 = true,
            MainColor = Color3.fromRGB(255, 0, 0),
            UseTeam = true,
            TextSize = 13,
            BoxThickness = 2,
            TracerOrigin = "Bottom"
        },
        Feature3 = {
            InfiniteAmmo = false,
            ProjectileTravel = false,
            NoSpread = false,
            NoRecoilControl = false
        },
        Input = {
            AimBind = "MB2",
            AimMode = "Hold",
            OverlayBind = "Insert",
            MenuBind = "RightShift",
            PanicBind = "End"
        },
        UI = {
            Enabled = true,
            Provider = "Fluent",
            Theme = "Dark",
            Acrylic = false,
            Transparency = false,
            DrawingInset = true,
            OverlayRate = 30
        },
        GUI = {
            Enabled = true
        },
        Profiles = {
            Active = "default",
            PerPlace = true,
            Folder = "CometPrivate/profiles"
        },
        Diagnostics = {
            Enabled = true,
            ShowBootStatus = true,
            LastMessage = ""
        }
    }

    context.Config = Config

    return Config
end
