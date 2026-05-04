return function(context)
    local Overlay = {}

    function Overlay.setVisible(entry, visible)
        if not entry or not entry.drawings then
            return
        end

        for _, drawing in pairs(entry.drawings) do
            if typeof(drawing) == "table" and drawing.Visible ~= nil then
                drawing.Visible = visible
            end
        end
    end

    function Overlay.updateEntry(entry)
        Overlay.setVisible(entry, false)
    end

    function Overlay.updateAll()
        local cache = context.PlayerCache

        if not cache then
            return
        end

        for _, entry in pairs(cache.players) do
            Overlay.updateEntry(entry)
        end
    end

    function Overlay.hideAll()
        local cache = context.PlayerCache

        if not cache then
            return
        end

        for _, entry in pairs(cache.players) do
            Overlay.setVisible(entry, false)
        end
    end

    context.Overlay = Overlay

    return Overlay
end
