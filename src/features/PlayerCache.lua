return function(context)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer
    local Compatibility = context.Compatibility
    local drawingReady = Compatibility == nil or Compatibility.supports("Drawing")

    local PlayerCache = {
        players = {}
    }

    local function removeDrawing(obj)
        if not obj then
            return
        end

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
        local ok, drawing = pcall(function()
            return Drawing.new(kind)
        end)

        if ok then
            return drawing
        end

        drawingReady = false
        return nil
    end

    function PlayerCache.setup(player)
        if player == LocalPlayer or not drawingReady then
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

        if not items.Box or not items.Text1 or not items.Bar or not items.Text2 or not items.Text3 or not items.Line then
            removeDrawing(items)
            return nil
        end

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
