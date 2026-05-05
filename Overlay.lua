return function(context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")

    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local Config = context.Config

    local Overlay = {
        drawings = {}
    }

    local circle = Drawing.new("Circle")
    circle.Thickness = 2
    circle.NumSides = 64
    circle.Radius = Config.Feature1.Range
    circle.Color = Color3.fromRGB(255, 255, 255)
    circle.Transparency = 0.7
    circle.Filled = false
    circle.Visible = false

    local versionText = Drawing.new("Text")
    versionText.Size = 14
    versionText.Center = false
    versionText.Outline = true
    versionText.Font = 2
    versionText.Transparency = 1
    versionText.Visible = true

    table.insert(Overlay.drawings, circle)
    table.insert(Overlay.drawings, versionText)

    local function valueFromInstance(instance)
        local ok, value = pcall(function()
            return tonumber(instance.Value)
        end)

        if ok and value then
            return value
        end

        return nil
    end

    local function getHealthData(player, humanoid)
        local nrpbs = player and player:FindFirstChild("NRPBS")
        local health = valueFromInstance(nrpbs and nrpbs:FindFirstChild("Health"))

        if health ~= nil then
            local maxHealth = valueFromInstance(nrpbs and nrpbs:FindFirstChild("MaxHealth"))

            if maxHealth == nil then
                maxHealth = humanoid and tonumber(humanoid.MaxHealth) or 100
            end

            return health, maxHealth
        end

        if humanoid then
            local current = tonumber(humanoid.Health)
            local maxHealth = tonumber(humanoid.MaxHealth)

            return current, maxHealth
        end

        return nil, nil
    end

    local function setVisible(obj, visible)
        if typeof(obj) == "table" then
            for _, child in pairs(obj) do
                setVisible(child, visible)
            end
        else
            pcall(function()
                obj.Visible = visible
            end)
        end
    end

    local function updateVersionBadge()
        Camera = Workspace.CurrentCamera

        local version = Config.Version or {}
        local status = version.Status or "Checking"
        local number = version.Number or "0.0.0"

        versionText.Text = "Comet - " .. number .. " - " .. status

        if status == "Old" then
            versionText.Color = Color3.fromRGB(255, 210, 210)
        else
            versionText.Color = Color3.fromRGB(255, 255, 255)
        end

        local width = 260

        pcall(function()
            width = math.max(120, versionText.TextBounds.X)
        end)

        local x = Camera.ViewportSize.X - width - 12
        local y = 12

        if x < 12 then
            x = 12
            y = 8
        end

        versionText.Position = Vector2.new(x, y)
        versionText.Visible = true
    end

    function Overlay.setVisible(obj, visible)
        setVisible(obj, visible)
    end

    function Overlay.hidePlayer(data)
        setVisible(data, false)
    end

    function Overlay.hideAll()
        circle.Visible = false

        for _, data in pairs(context.PlayerCache.players) do
            Overlay.hidePlayer(data)
        end

        updateVersionBadge()
    end

    function Overlay.updateCircle()
        Camera = Workspace.CurrentCamera
        circle.Visible = Config.UI.Enabled and Config.Feature1.Enabled
        circle.Radius = Config.Feature1.Range
        circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
    end

    function Overlay.updatePlayer(player, data)
        Camera = Workspace.CurrentCamera

        if player == LocalPlayer then
            return
        end

        if not data then
            return
        end

        if not Config.UI.Enabled then
            Overlay.hidePlayer(data)
            return
        end

        local character = player.Character

        if not character or not character:FindFirstChild("HumanoidRootPart") or not character:FindFirstChild("Head") or not character:FindFirstChild("Humanoid") then
            Overlay.hidePlayer(data)
            return
        end

        local root = character.HumanoidRootPart
        local head = character.Head
        local humanoid = character.Humanoid
        local health, maxHealth = getHealthData(player, humanoid)

        if not health or health <= 0 then
            Overlay.hidePlayer(data)
            return
        end

        local rPos, onScreen = Camera:WorldToViewportPoint(root.Position)

        if not onScreen then
            Overlay.hidePlayer(data)
            return
        end

        local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
        local bot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))
        local h = bot.Y - top.Y
        local w = h / 2

        if h <= 0 then
            Overlay.hidePlayer(data)
            return
        end

        local col = Config.Feature2.MainColor

        if Config.Feature2.UseTeam and player.Team == LocalPlayer.Team then
            col = Color3.fromRGB(0, 255, 0)
        end

        if Config.Feature2.Style1 then
            data.Box.Size = Vector2.new(w, h)
            data.Box.Position = Vector2.new(top.X - w / 2, top.Y)
            data.Box.Color = col
            data.Box.Visible = true
        else
            data.Box.Visible = false
        end

        if Config.Feature2.Style2 then
            data.Text1.Text = player.Name
            data.Text1.Position = Vector2.new(rPos.X, top.Y - 15)
            data.Text1.Color = col
            data.Text1.Visible = true
        else
            data.Text1.Visible = false
        end

        if Config.Feature2.Style3 then
            local maxHealthValue = maxHealth

            if maxHealthValue == nil or maxHealthValue <= 0 then
                maxHealthValue = 100
            end

            local pct = math.clamp(health / maxHealthValue, 0, 1)

            data.Bar.Size = Vector2.new(4, h * pct)
            data.Bar.Position = Vector2.new(top.X - w / 2 - 6, top.Y + h * (1 - pct))
            data.Bar.Color = Color3.fromRGB(255 - (255 * pct), 255 * pct, 0)
            data.Bar.Visible = true

            data.Text2.Text = tostring(math.floor(health))
            data.Text2.Position = Vector2.new(top.X - w / 2 - 20, top.Y + h / 2)
            data.Text2.Color = data.Bar.Color
            data.Text2.Visible = true
        else
            data.Bar.Visible = false
            data.Text2.Visible = false
        end

        if Config.Feature2.Style4 then
            local localCharacter = context.LocalCharacter or LocalPlayer.Character
            local localRoot = localCharacter and localCharacter:FindFirstChild("HumanoidRootPart")

            if localRoot then
                local d = math.floor((localRoot.Position - root.Position).Magnitude)

                data.Text3.Text = d .. " studs"
                data.Text3.Position = Vector2.new(rPos.X, bot.Y + 5)
                data.Text3.Color = col
                data.Text3.Visible = true
            else
                data.Text3.Visible = false
            end
        else
            data.Text3.Visible = false
        end

        if Config.Feature2.Style5 then
            data.Line.From = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y)
            data.Line.To = Vector2.new(rPos.X, rPos.Y)
            data.Line.Color = col
            data.Line.Visible = true
        else
            data.Line.Visible = false
        end
    end

    function Overlay.updateAll()
        Overlay.updateCircle()
        updateVersionBadge()

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                local data = context.PlayerCache.players[player] or context.PlayerCache.setup(player)
                Overlay.updatePlayer(player, data)
            end
        end
    end

    context.Overlay = Overlay

    return Overlay
end
