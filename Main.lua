return function(context)
    local Players = game:GetService("Players")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    local Config = context.Config
    local Connections = context.Connections
    local PlayerCache = context.PlayerCache
    local Targeting = context.Targeting
    local Overlay = context.Overlay
    local Gui = context.Gui
    local Binds = context.Binds

    local Main = {
        running = false
    }

    context.LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local function onInputBegan(input, gameProcessed)
        if gameProcessed then
            return
        end

        if Gui and Gui.shouldBlockInput and Gui.shouldBlockInput() then
            return
        end

        if Binds.matches(input, Config.Keys.ToggleGUI) then
            if Gui and Gui.toggleVisibility then
                Gui.toggleVisibility()
            end
            return
        end

        if Binds.matches(input, Config.Keys.ToggleUI) then
            Config.UI.Enabled = not Config.UI.Enabled

            if not Config.UI.Enabled then
                Overlay.hideAll()
            end

            if Gui and Gui.refresh then
                Gui.refresh()
            end

            return
        end

        if Binds.matches(input, Config.Keys.HoldFeature1) then
            Config.Feature1.Active = true
        end
    end

    local function onInputEnded(input)
        if Gui and Gui.shouldBlockInput and Gui.shouldBlockInput() then
            return
        end

        if Binds.matches(input, Config.Keys.HoldFeature1) then
            Config.Feature1.Active = false
            Targeting.current = nil
        end
    end

    local function step()
        Overlay.updateAll()
        Targeting.update()
    end

    function Main.start()
        if Main.running then
            return Main
        end

        Main.running = true
        PlayerCache.setupAll()

        if Gui and Gui.start then
            Gui.start()
        end

        Connections.add("InputBegan", UserInputService.InputBegan:Connect(onInputBegan))
        Connections.add("InputEnded", UserInputService.InputEnded:Connect(onInputEnded))
        Connections.add("PlayerAdded", Players.PlayerAdded:Connect(function(player)
            PlayerCache.setup(player)
        end))
        Connections.add("PlayerRemoving", Players.PlayerRemoving:Connect(function(player)
            PlayerCache.remove(player)
        end))
        Connections.add("CharacterAdded", LocalPlayer.CharacterAdded:Connect(function(character)
            context.LocalCharacter = character
        end))
        Connections.add("RenderStepped", RunService.RenderStepped:Connect(step))

        return Main
    end

    function Main.stop()
        if not Main.running then
            return Main
        end

        Main.running = false

        if Gui and Gui.destroy then
            Gui.destroy()
        end

        Connections.disconnectAll()
        Overlay.hideAll()
        PlayerCache.clear()

        return Main
    end

    context.Main = Main

    return Main
end
