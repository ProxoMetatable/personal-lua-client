return function(context)
    local Players = game:GetService("Players")
    local LocalPlayer = Players.LocalPlayer

    local PlayerCache = {
        players = {},
    }

    local function getCharacterParts(player)
        local character = player.Character

        if not character then
            return nil
        end

        return {
            character = character,
            humanoid = character:FindFirstChildOfClass("Humanoid"),
            root = character:FindFirstChild("HumanoidRootPart"),
            head = character:FindFirstChild("Head"),
        }
    end

    function PlayerCache.create(player)
        if player == LocalPlayer then
            return nil
        end

        local entry = PlayerCache.players[player]

        if not entry then
            entry = {
                player = player,
                drawings = {},
                parts = {},
                alive = false,
            }

            PlayerCache.players[player] = entry
        end

        PlayerCache.refresh(player)

        return entry
    end

    function PlayerCache.refresh(player)
        local entry = PlayerCache.players[player]

        if not entry then
            return nil
        end

        local parts = getCharacterParts(player)
        entry.parts = parts or {}
        entry.alive = parts ~= nil and parts.humanoid ~= nil and parts.humanoid.Health > 0 and parts.root ~= nil

        return entry
    end

    function PlayerCache.remove(player)
        local entry = PlayerCache.players[player]

        if not entry then
            return
        end

        for _, drawing in pairs(entry.drawings) do
            if typeof(drawing) == "table" and drawing.Remove then
                drawing:Remove()
            end
        end

        PlayerCache.players[player] = nil
    end

    function PlayerCache.refreshAll()
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer then
                PlayerCache.create(player)
            end
        end

        for player in pairs(PlayerCache.players) do
            if not player.Parent then
                PlayerCache.remove(player)
            else
                PlayerCache.refresh(player)
            end
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
