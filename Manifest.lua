return {
    Name = "Comet",
    Version = "1.2.1",
    Build = 121,
    Channel = "stable",
    Cache = "build",
    RequiredLoader = 2,
    CheckInterval = 300,
    Modules = {
        {Name = "Version", Path = "src/core/Version.lua", Required = true},
        {Name = "Config", Path = "src/core/Config.lua", Required = true},
        {Name = "Connections", Path = "src/core/Connections.lua", Required = true},
        {Name = "ConfigMigrator", Path = "src/core/ConfigMigrator.lua", Required = true},
        {Name = "PlayerCache", Path = "src/features/PlayerCache.lua", Required = true},
        {Name = "Targeting", Path = "src/features/Targeting.lua", Required = true},
        {Name = "Weapons", Path = "src/features/Weapons.lua", Required = false},
        {Name = "Overlay", Path = "src/features/Overlay.lua", Required = true},
        {Name = "UIAdapter", Path = "src/ui/UIAdapter.lua", Required = false},
        {Name = "GUI", Path = "src/ui/GUI.lua", Required = false},
        {Name = "VersionCheck", Path = "src/core/VersionCheck.lua", Required = false},
        {Name = "Main", Path = "src/Main.lua", Required = true},
    },
    UIProviders = {
        Fluent = "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua",
        Rayfield = "https://sirius.menu/rayfield"
    }
}
