return function(context)
    local Config = {
        Feature1 = {
            Enabled = true,
            Active = false,
            Range = 150,
            Speed = 8,
            Part = "Head",
            Check1 = true,
            Check2 = true
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
        },
        Keys = {
            ToggleGUI = {
                Type = "KeyCode",
                Name = "RightShift"
            },
            ToggleUI = {
                Type = "KeyCode",
                Name = "Insert"
            },
            HoldFeature1 = {
                Type = "KeyCode",
                Name = "LeftAlt"
            }
        }
    }

    context.Config = Config

    return Config
end
