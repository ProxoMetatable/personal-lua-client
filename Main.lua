return function(context)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local Config = context.Config
    local Connections = context.Connections
    local PlayerCache = context.PlayerCache
    local Targeting = context.Targeting
    local Overlay = context.Overlay

    local Main = {
        running = false,
    }

    local function onInputBegan(input, processed)
        if processed then
            return
        end

        if input.KeyCode == Config.Keys.ToggleOverlay then
            Config.Overlay.Enabled = not Config.Overlay.Enabled

            if not Config.Overlay.Enabled then
                Overlay.hideAll()
            end
        end

        if input.KeyCode == Config.Keys.HoldTargeting then
            Config.Targeting.Active = true
        end
    end

    local function onInputEnded(input)
        if input.KeyCode == Config.Keys.HoldTargeting then
            Config.Targeting.Active = false
            Targeting.current = nil
        end
    end

    local function step()
        if not Config.Enabled then
            return
        end

        PlayerCache.refreshAll()

        if Config.Targeting.Enabled and Config.Targeting.Active then
            Targeting.update()
        else
            Targeting.current = nil
        end

        if Config.Overlay.Enabled then
            Overlay.updateAll()
        else
            Overlay.hideAll()
        end
    end

    function Main.start()
        if Main.running then
            return Main
        end

        Main.running = true
        PlayerCache.refreshAll()

        Connections.add("PlayerAdded", Players.PlayerAdded:Connect(function(player)
            PlayerCache.create(player)
        end))

        Connections.add("PlayerRemoving", Players.PlayerRemoving:Connect(function(player)
            PlayerCache.remove(player)
        end))

        Connections.add("InputBegan", UserInputService.InputBegan:Connect(onInputBegan))
        Connections.add("InputEnded", UserInputService.InputEnded:Connect(onInputEnded))
        Connections.add("RenderStepped", RunService.RenderStepped:Connect(step))

        return Main
    end

    function Main.stop()
        if not Main.running then
            return Main
        end

        Main.running = false
        Connections.disconnectAll()
        Overlay.hideAll()
        PlayerCache.clear()

        return Main
    end

    context.Main = Main

    return Main
end
