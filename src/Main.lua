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
    local Compatibility = context.Compatibility
    local renderStepName = "CometPrivateMain"

    local Main = {
        running = false
    }
    local lastOverlayUpdate = 0
    local errorState = {
        Overlay = {Count = 0, LastWarn = 0, Disabled = false},
        Targeting = {Count = 0, LastWarn = 0, Disabled = false}
    }

    context.LocalCharacter = LocalPlayer.Character or LocalPlayer.CharacterAdded:Wait()

    local function saveConfig()
        if Gui and Gui.saveConfig then
            Gui.saveConfig()
        end
    end

    local function focusedTextBox()
        local ok, result = pcall(function()
            return UserInputService:GetFocusedTextBox()
        end)

        return ok and result ~= nil
    end

    local function keyCodeFromName(name)
        if type(name) ~= "string" or name == "" then
            return nil
        end

        local ok, keyCode = pcall(function()
            return Enum.KeyCode[name]
        end)

        if ok then
            return keyCode
        end

        return nil
    end

    local function mouseInputFromBind(bind)
        if bind == "MB1" or bind == "MouseButton1" then
            return Enum.UserInputType.MouseButton1
        elseif bind == "MB2" or bind == "MouseButton2" then
            return Enum.UserInputType.MouseButton2
        elseif bind == "MB3" or bind == "MouseButton3" then
            return Enum.UserInputType.MouseButton3
        end

        return nil
    end

    local function inputMatches(input, bind)
        local mouseInput = mouseInputFromBind(bind)

        if mouseInput then
            return input.UserInputType == mouseInput
        end

        local keyCode = keyCodeFromName(bind)

        return keyCode ~= nil and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode == keyCode
    end

    local function bindingDown(bind)
        local mouseInput = mouseInputFromBind(bind)

        if mouseInput then
            local ok, result = pcall(function()
                return UserInputService:IsMouseButtonPressed(mouseInput)
            end)

            return ok and result
        end

        local keyCode = keyCodeFromName(bind)

        if keyCode then
            local ok, result = pcall(function()
                return UserInputService:IsKeyDown(keyCode)
            end)

            return ok and result
        end

        return false
    end

    local function currentAimMode()
        local mode = Config.Input and Config.Input.AimMode or Config.Feature1.AimMode or "Hold"

        if mode ~= "Hold" and mode ~= "Toggle" and mode ~= "Always" then
            mode = "Hold"
        end

        Config.Feature1.AimMode = mode

        return mode
    end

    local function clearTarget()
        if Targeting then
            Targeting.current = nil
        end
    end

    local function syncAimState()
        if not Config.Feature1.Enabled then
            Config.Feature1.Active = false
            clearTarget()
            return
        end

        local mode = currentAimMode()

        if mode == "Always" then
            Config.Feature1.Active = true
        elseif mode == "Hold" then
            Config.Feature1.Active = bindingDown(Config.Input.AimBind)
        end

        if not Config.Feature1.Active then
            clearTarget()
        end
    end

    local function toggleOverlay()
        Config.UI.Enabled = not Config.UI.Enabled

        if not Config.UI.Enabled and Overlay then
            Overlay.hideAll()
        end

        if Gui and Gui.refresh then
            Gui.refresh()
        end

        saveConfig()
    end

    local function describeTarget(target)
        if not target then
            return "none"
        end

        if target.Player then
            return target.Player.Name
        end

        if target.Character then
            return target.Character.Name
        end

        return "unknown"
    end

    local function rememberRuntimeError(name, err)
        local state = errorState[name]

        if not state then
            return
        end

        state.Count += 1

        local diagnostics = context.Diagnostics

        if diagnostics then
            diagnostics.Runtime = diagnostics.Runtime or {}
            diagnostics.Runtime.LastError = tostring(name) .. ": " .. tostring(err)
            diagnostics.Runtime[name .. "Errors"] = state.Count
        end

        local now = os.clock()

        if now - state.LastWarn >= 5 then
            state.LastWarn = now
            warn("Comet " .. name .. " error: " .. tostring(err))
        end

        if state.Count >= 10 then
            state.Disabled = true
            warn("Comet " .. name .. " disabled after repeated runtime errors.")
        end
    end

    local function clearRuntimeError(name)
        local state = errorState[name]

        if state then
            state.Count = 0
        end
    end

    local function runSafe(name, callback)
        local state = errorState[name]

        if state and state.Disabled then
            return false, nil
        end

        local ok, result = pcall(callback)

        if ok then
            clearRuntimeError(name)
            return true, result
        end

        rememberRuntimeError(name, result)
        return false, nil
    end

    local function updateRuntimeDiagnostics(startedAt, overlayStartedAt, overlayFinishedAt, targetStartedAt, targetFinishedAt, target)
        local diagnostics = context.Diagnostics

        if not diagnostics then
            return
        end

        local runtime = diagnostics.Runtime or {}
        diagnostics.Runtime = runtime

        local finishedAt = os.clock()
        local lastFrameAt = runtime.LastFrameAt

        if lastFrameAt and finishedAt > lastFrameAt then
            runtime.Fps = 1 / (finishedAt - lastFrameAt)
        end

        runtime.LastFrameAt = finishedAt
        runtime.FrameMs = (finishedAt - startedAt) * 1000
        runtime.OverlayMs = overlayFinishedAt and overlayStartedAt and (overlayFinishedAt - overlayStartedAt) * 1000 or 0
        runtime.TargetingMs = targetFinishedAt and targetStartedAt and (targetFinishedAt - targetStartedAt) * 1000 or 0
        runtime.LastTarget = describeTarget(target)
        runtime.CachedModels = Targeting and Targeting.models and #Targeting.models or 0
        runtime.AimActive = Config.Feature1.Active
        runtime.OverlayEnabled = Config.UI.Enabled
    end

    local function panicStop()
        Config.Feature1.Active = false
        clearTarget()

        if Main.stop then
            Main.stop()
        end
    end

    local function onInputBegan(input)
        if focusedTextBox() then
            return
        end

        if Config.Input and inputMatches(input, Config.Input.OverlayBind) then
            toggleOverlay()
            return
        end

        if Config.Input and inputMatches(input, Config.Input.PanicBind) then
            panicStop()
            return
        end

        if Config.Input and inputMatches(input, Config.Input.AimBind) then
            local mode = currentAimMode()

            if mode == "Toggle" then
                Config.Feature1.Active = not Config.Feature1.Active

                if not Config.Feature1.Active then
                    clearTarget()
                end
            elseif mode == "Hold" then
                Config.Feature1.Active = true
            end
        end
    end

    local function onInputEnded(input)
        if Config.Input and inputMatches(input, Config.Input.AimBind) and currentAimMode() == "Hold" then
            Config.Feature1.Active = false
            clearTarget()
        end
    end

    local function step()
        local startedAt = os.clock()

        syncAimState()

        local overlayStartedAt = nil
        local overlayFinishedAt = nil
        local now = os.clock()
        local overlayRate = math.clamp(tonumber(Config.UI and Config.UI.OverlayRate) or 30, 5, 60)

        if Overlay and Overlay.updateAll and now - lastOverlayUpdate >= 1 / overlayRate then
            lastOverlayUpdate = now
            overlayStartedAt = os.clock()
            runSafe("Overlay", function()
                Overlay.updateAll()
            end)
            overlayFinishedAt = os.clock()
        end

        local targetStartedAt = os.clock()
        local target = nil

        if Targeting and Targeting.update then
            local _, result = runSafe("Targeting", function()
                return Targeting.update()
            end)

            target = result
        end

        local targetFinishedAt = os.clock()

        updateRuntimeDiagnostics(startedAt, overlayStartedAt, overlayFinishedAt, targetStartedAt, targetFinishedAt, target)
    end

    local function supports(capability)
        return not Compatibility or Compatibility.supports(capability)
    end

    local function setLoopDiagnostic(mode, detail)
        if not context.Diagnostics then
            return
        end

        context.Diagnostics.Runtime = context.Diagnostics.Runtime or {}
        context.Diagnostics.Runtime.Loop = mode
        context.Diagnostics.Runtime.LoopDetail = detail
    end

    local function connectSignalLoop(signalName)
        local ok, connection = pcall(function()
            return RunService[signalName]:Connect(step)
        end)

        if ok and connection then
            Connections.add("RenderLoop", connection)
            setLoopDiagnostic(signalName, "connected through RunService." .. signalName)
            return true
        end

        return false, connection
    end

    local function bindRenderLoop()
        if supports("BindToRenderStep") then
            pcall(function()
                RunService:UnbindFromRenderStep(renderStepName)
            end)

            local bound, err = pcall(function()
                RunService:BindToRenderStep(renderStepName, Enum.RenderPriority.Camera.Value + 1, step)
            end)

            if bound then
                Connections.add("RenderLoop", {
                    Disconnect = function()
                        pcall(function()
                            RunService:UnbindFromRenderStep(renderStepName)
                        end)
                    end
                })
                setLoopDiagnostic("BindToRenderStep", "bound after camera update priority")
                return true
            end

            setLoopDiagnostic("BindToRenderStepFailed", tostring(err))
        end

        if supports("RenderStepped") then
            local connected = connectSignalLoop("RenderStepped")

            if connected then
                return true
            end
        end

        if supports("Heartbeat") then
            local connected = connectSignalLoop("Heartbeat")

            if connected then
                return true
            end
        end

        setLoopDiagnostic("None", "no RunService frame signal could be connected")
        warn("Comet render loop unavailable; overlay and targeting updates are disabled.")
        return false
    end

    function Main.start()
        if Main.running then
            return Main
        end

        Main.running = true

        if PlayerCache and PlayerCache.setupAll then
            PlayerCache.setupAll()
        end

        if Targeting and Targeting.start then
            Targeting.start()
        end

        if Weapons and Weapons.start then
            Weapons.start()
        end

        if Gui and Gui.start then
            Gui.start()
        end

        if Weapons and Weapons.syncState then
            Weapons.syncState()
        end

        if VersionCheck and VersionCheck.start then
            VersionCheck.start()
        end

        Connections.add("InputBegan", UserInputService.InputBegan:Connect(onInputBegan))
        Connections.add("InputEnded", UserInputService.InputEnded:Connect(onInputEnded))
        Connections.add("PlayerAdded", Players.PlayerAdded:Connect(function(player)
            if PlayerCache and PlayerCache.setup then
                PlayerCache.setup(player)
            end
        end))
        Connections.add("PlayerRemoving", Players.PlayerRemoving:Connect(function(player)
            if PlayerCache and PlayerCache.remove then
                PlayerCache.remove(player)
            end
        end))
        Connections.add("CharacterAdded", LocalPlayer.CharacterAdded:Connect(function(character)
            context.LocalCharacter = character
        end))
        bindRenderLoop()

        return Main
    end

    function Main.stop()
        if not Main.running then
            return Main
        end

        Main.running = false
        Config.Feature1.Active = false
        clearTarget()

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

        if Overlay and Overlay.hideAll then
            Overlay.hideAll()
        end

        if PlayerCache and PlayerCache.clear then
            PlayerCache.clear()
        end

        return Main
    end

    context.Main = Main

    return Main
end
