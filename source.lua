local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local UserInputService = game:GetService("UserInputService")
local Workspace = game:GetService("Workspace")

local Camera = Workspace.CurrentCamera
local LocalPlayer = Players.LocalPlayer
local LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

local connections = {}
local drawings = {}
local cache = {}

local Config = {
    Feature1 = {
        Enabled = false,
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
    }
}

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

local function removeDrawing(obj)
    if typeof(obj) == "table" then
        for _, child in pairs(obj) do
            removeDrawing(child)
        end
    else
        pcall(function()
            obj:Remove()
        end)
    end
end

connections[#connections + 1] = UserInputService.InputBegan:Connect(function(input, gameProcessed)
    if gameProcessed then return end

    if input.KeyCode == Enum.KeyCode.Insert then
        Config.UI.Enabled = not Config.UI.Enabled
    end
end)

local circle = Drawing.new("Circle")
circle.Thickness = 2
circle.NumSides = 64
circle.Radius = Config.Feature1.Range
circle.Color = Color3.fromRGB(255, 255, 255)
circle.Transparency = 0.7
circle.Filled = false
circle.Visible = false

table.insert(drawings, circle)

local function setup(player)
    if player == LocalPlayer then return end
    if cache[player] then return end

    local items = {
        Box = Drawing.new("Square"),
        Text1 = Drawing.new("Text"),
        Bar = Drawing.new("Square"),
        Text2 = Drawing.new("Text"),
        Text3 = Drawing.new("Text"),
        Line = Drawing.new("Line"),
        Lines = {}
    }

    items.Box.Thickness = 2
    items.Box.Transparency = 1
    items.Box.Filled = false
    items.Box.Visible = false

    items.Bar.Filled = true
    items.Bar.Thickness = 0
    items.Bar.Transparency = 1
    items.Bar.Visible = false

    for _, text in pairs({items.Text1, items.Text2, items.Text3}) do
        text.Size = 13
        text.Center = true
        text.Outline = true
        text.Font = 2
        text.Visible = false
    end

    items.Line.Thickness = 1
    items.Line.Transparency = 0.8
    items.Line.Visible = false

    cache[player] = items
end

local function findTarget()
    local best = nil
    local bestDist = Config.Feature1.Range

    for _, player in ipairs(Players:GetPlayers()) do
        if player ~= LocalPlayer
            and player.Character
            and player.Character:FindFirstChild("Humanoid")
            and player.Character.Humanoid.Health > 0
        then
            local root = player.Character:FindFirstChild("HumanoidRootPart")
            local head = player.Character:FindFirstChild("Head")

            if not root or not head then
                continue
            end

            if Config.Feature1.Check2 and player.Team == LocalPlayer.Team then
                continue
            end

            local pos, visible = Camera:WorldToViewportPoint(root.Position)

            if not visible then
                continue
            end

            local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
            local screenPos = Vector2.new(pos.X, pos.Y)
            local dist = (screenPos - screenCenter).Magnitude

            if dist < bestDist then
                if Config.Feature1.Check1 then
                    local origin = Camera.CFrame.Position
                    local direction = head.Position - origin
                    local ray = Ray.new(origin, direction)

                    local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {
                        LocalCharacter,
                        player.Character
                    })

                    if hit then
                        continue
                    end
                end

                bestDist = dist
                best = player
            end
        end
    end

    return best
end

for _, player in ipairs(Players:GetPlayers()) do
    setup(player)
end

Players.PlayerAdded:Connect(setup)

Players.PlayerRemoving:Connect(function(player)
    local data = cache[player]

    if data then
        removeDrawing(data)
        cache[player] = nil
    end
end)

connections[#connections + 1] = RunService.RenderStepped:Connect(function()
    circle.Visible = Config.UI.Enabled and Config.Feature1.Enabled
    circle.Radius = Config.Feature1.Range
    circle.Position = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

    if Config.Feature1.Enabled then
        local target = findTarget()

        if target and target.Character and target.Character:FindFirstChild(Config.Feature1.Part) then
            local targetPart = target.Character[Config.Feature1.Part]
            local current = Camera.CFrame.LookVector
            local targetDir = (targetPart.Position - Camera.CFrame.Position).Unit

            Camera.CFrame = CFrame.new(
                Camera.CFrame.Position,
                Camera.CFrame.Position + current:Lerp(targetDir, 1 / Config.Feature1.Speed)
            )
        end
    end

    for _, player in ipairs(Players:GetPlayers()) do
        if player == LocalPlayer then
            continue
        end

        if not cache[player] then
            setup(player)
        end

        local data = cache[player]

        if not data then
            continue
        end

        if not Config.UI.Enabled then
            setVisible(data, false)
            continue
        end

        local char = player.Character

        if not char
            or not char:FindFirstChild("HumanoidRootPart")
            or not char:FindFirstChild("Head")
            or not char:FindFirstChild("Humanoid")
        then
            setVisible(data, false)
            continue
        end

        local root = char.HumanoidRootPart
        local head = char.Head
        local hum = char.Humanoid

        if hum.Health <= 0 then
            setVisible(data, false)
            continue
        end

        local rPos, onScreen = Camera:WorldToViewportPoint(root.Position)

        if not onScreen then
            setVisible(data, false)
            continue
        end

        local top = Camera:WorldToViewportPoint(head.Position + Vector3.new(0, 2.5, 0))
        local bot = Camera:WorldToViewportPoint(root.Position - Vector3.new(0, 3, 0))

        local h = bot.Y - top.Y
        local w = h / 2

        if h <= 0 then
            setVisible(data, false)
            continue
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
            local pct = math.clamp(hum.Health / hum.MaxHealth, 0, 1)

            data.Bar.Size = Vector2.new(4, h * pct)
            data.Bar.Position = Vector2.new(top.X - w / 2 - 6, top.Y + h * (1 - pct))
            data.Bar.Color = Color3.fromRGB(255 - (255 * pct), 255 * pct, 0)
            data.Bar.Visible = true

            data.Text2.Text = tostring(math.floor(hum.Health))
            data.Text2.Position = Vector2.new(top.X - w / 2 - 20, top.Y + h / 2)
            data.Text2.Color = data.Bar.Color
            data.Text2.Visible = true
        else
            data.Bar.Visible = false
            data.Text2.Visible = false
        end

        if Config.Feature2.Style4 then
            local localRoot = LocalCharacter and LocalCharacter:FindFirstChild("HumanoidRootPart")

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
end)

LocalPlayer.CharacterAdded:Connect(function(character)
    LocalCharacter = character
end)
