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
    local VersionCheck = context.VersionCheck
    local Weapons = context.Weapons
    local renderStepName = "CometPrivateMain"

    local Main = {
        running = false
    }

    context.LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local function saveConfig()
        if Gui and Gui.saveConfig then
            Gui.saveConfig()
        end
    end

    local function rightClickDown()
        local ok, result = pcall(function()
            return UserInputService:IsMouseButtonPressed(Enum.UserInputType.MouseButton2)
        end)

        return ok and result
    end

    local function syncAimHold()
        if Config.Feature1.Enabled then
            Config.Feature1.Active = rightClickDown()
        else
            Config.Feature1.Active = false
        end

        if not Config.Feature1.Active then
            Targeting.current = nil
        end
    end

    local function toggleOverlay()
        Config.UI.Enabled = not Config.UI.Enabled

        if not Config.UI.Enabled then
            Overlay.hideAll()
        end

        if Gui and Gui.refresh then
            Gui.refresh()
        end

        saveConfig()
    end

    local function onInputBegan(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == Enum.KeyCode.Insert then
            toggleOverlay()
        end
    end

    local function onInputEnded(input)
        if input.UserInputType == Enum.UserInputType.MouseButton2 then
            Config.Feature1.Active = false
            Targeting.current = nil
        end
    end

    local function step()
        syncAimHold()
        Overlay.updateAll()
        Targeting.update()
    end

    local function bindRenderStep()
        pcall(function()
            RunService:UnbindFromRenderStep(renderStepName)
        end)

        local bound = pcall(function()
            RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Camera.Value + 1, step)
        end)

        if bound then
            Connections.add("RenderStepped", {
                Disconnect = function()
                    pcall(function()
                        RunService:UnbindFromRenderStep(renderStepName)
                    end)
                end
            })
        else
            Connections.add("RenderStepped", RunService.RenderStepped:Connect(step))
        end
    end

    function Main.start()
        if Main.running then
            return Main
        end

        Main.running = true
        PlayerCache.setupAll()

        if Targeting and Targeting.start then
            Targeting.start()
        end

        if Weapons and Weapons.start then
            Weapons.start()
        end

        if Gui and Gui.start then
            Gui.start()
        end

        if VersionCheck and VersionCheck.start then
            VersionCheck.start()
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
        bindRenderStep()

        return Main
    end

    function Main.stop()
        if not Main.running then
            return Main
        end

        Main.running = false
        Config.Feature1.Active = false
        Targeting.current = nil

        if Gui and Gui.destroy then
            Gui.destroy()
        end

        Connections.disconnectAll()

        if Targeting and Targeting.stop then
            Targeting.stop()
        end

        if Weapons and Weapons.stop then
            Weapons.stop()
        end

        if VersionCheck and VersionCheck.stop then
            VersionCheck.stop()
        end

        Overlay.hideAll()
        PlayerCache.clear()

        return Main
    end

    context.Main = Main

    return Main
end
