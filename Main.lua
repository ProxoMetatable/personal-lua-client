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
    local renderStepName = "CometPrivateMain"

    local Main = {
        running = false
    }

    context.LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local function bindType(bind)
        local ok, result = pcall(function()
            return tostring(bind.EnumType)
        end)

        if ok then
            return result
        end

        return nil
    end

    local function matches(input, bind)
        local kind = bindType(bind)

        if kind == "Enum.KeyCode" then
            return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == bind
        end

        if kind == "Enum.UserInputType" then
            return input.UserInputType == bind
        end

        return false
    end

    local function mouseDown(bind)
        local ok, result = pcall(function()
            return UserInputService:IsMouseButtonPressed(bind)
        end)

        return ok and result
    end

    local function bindDown(bind)
        local kind = bindType(bind)

        if kind == "Enum.KeyCode" then
            return UserInputService:IsKeyDown(bind)
        end

        if kind == "Enum.UserInputType" then
            if bind == Enum.UserInputType.MouseButton1 or bind == Enum.UserInputType.MouseButton2 or bind == Enum.UserInputType.MouseButton3 then
                return mouseDown(bind)
            end
        end

        return false
    end

    local function syncAimHold()
        if Config.Feature1.Enabled then
            Config.Feature1.Active = bindDown(Config.Keys.HoldFeature1)
        else
            Config.Feature1.Active = false
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

        if Gui and Gui.saveConfig then
            Gui.saveConfig()
        end
    end

    local function onInputBegan(input, gameProcessed)
        if matches(input, Config.Keys.HoldFeature1) then
            Config.Feature1.Active = true
            return
        end

        if matches(input, Config.Keys.ToggleGUI) then
            if Gui and Gui.toggleVisibility then
                Gui.toggleVisibility()
            end
            return
        end

        if matches(input, Config.Keys.ToggleUI) then
            toggleOverlay()
            return
        end

        if gameProcessed then
            return
        end
    end

    local function onInputEnded(input)
        if matches(input, Config.Keys.HoldFeature1) then
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
        bindRenderStep()

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
