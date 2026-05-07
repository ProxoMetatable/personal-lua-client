return {
    Name = "Comet",
    Version = "1.2.0",
    Build = 120,
    Channel = "stable",
    Cache = "build",
    RequiredLoader = 2,
    CheckInterval = 300,
    Modules = {
        {Name = "Version", Path = "Version.lua", Required = true},
        {Name = "Config", Path = "Config.lua", Required = true},
        {Name = "Connections", Path = "Connections.lua", Required = true},
        {Name = "ConfigMigrator", Path = "ConfigMigrator.lua", Required = true},
        {Name = "PlayerCache", Path = "PlayerCache.lua", Required = true},
        {Name = "Targeting", Path = "Targeting.lua", Required = true},
        {Name = "Weapons", Path = "Weapons.lua", Required = false},
        {Name = "Overlay", Path = "Overlay.lua", Required = true},
        {Name = "UIAdapter", Path = "UIAdapter.lua", Required = false},
        {Name = "GUI", Path = "GUI.lua", Required = false},
        {Name = "VersionCheck", Path = "VersionCheck.lua", Required = false},
        {Name = "Main", Path = "Main.lua", Required = true},
    },
    UIProviders = {
        Fluent = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
        Rayfield = "https://sirius.menu/rayfield"
    }
}
