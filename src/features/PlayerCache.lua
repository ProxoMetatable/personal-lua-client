return function(context)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local PlayerCache = {
        players = {}
    }

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

    local function createDrawing(kind)
        return Drawing.new(kind)
    end

    function PlayerCache.setup(player)
        if player == LocalPlayer then
            return nil
        end

        if PlayerCache.players[player] then
            return PlayerCache.players[player]
        end

        local items = {
            Box = createDrawing("Square"),
            Text1 = createDrawing("Text"),
            Bar = createDrawing("Square"),
            Text2 = createDrawing("Text"),
            Text3 = createDrawing("Text"),
            Line = createDrawing("Line"),
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

        PlayerCache.players[player] = items

        return items
    end

    function PlayerCache.remove(player)
        local data = PlayerCache.players[player]

        if data then
            removeDrawing(data)
            PlayerCache.players[player] = nil
        end
    end

    function PlayerCache.setupAll()
        for _, player in ipairs(Players:GetPlayers()) do
            PlayerCache.setup(player)
        end
    end

    function PlayerCache.clear()
        for player in pairs(PlayerCache.players) do
            PlayerCache.remove(player)
        end
    end

    context.PlayerCache = PlayerCache

    return PlayerCache
end
