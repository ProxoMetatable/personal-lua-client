return function(context)
    local Connections = {
        items = {}
    }

    function Connections.add(name, connection)
        Connections.disconnect(name)
        Connections.items[name] = connection
        return connection
    end

    function Connections.disconnect(name)
        local connection = Connections.items[name]

        if connection then
            if typeof(connection) == "RBXScriptConnection" or typeof(connection) == "table" then
                pcall(function()
                    connection:Disconnect()
                end)
            elseif type(connection) == "function" then
                pcall(connection)
            end

            Connections.items[name] = nil
        end
    end

    function Connections.disconnectAll()
        for name in pairs(Connections.items) do
            Connections.disconnect(name)
        end
    end

    context.Connections = Connections

    return Connections
end
