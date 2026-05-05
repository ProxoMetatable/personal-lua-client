return function(context)
    local version = context.Version or {Number = "1.1.3"}

    local Config = {
        Name = "Comet - Private",
        Version = {
            Number = version.Number or "1.1.3",
            Latest = nil,
            Status = "Checking"
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
            MaxBelowLocal = 220
        },
        Feature2 = {
            Style1 = true,
            Style2 = true,
            Style3 = true,
            Style4 = true,
            Style5 = true,
            MainColor = Color3.fromRGB(255, 0, 0),
            UseTeam = true
        },
        UI = {
            Enabled = true
        },
        GUI = {
            Enabled = true
        }
    }

    context.Config = Config

    return Config
end
