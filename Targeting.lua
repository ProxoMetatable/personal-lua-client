return function(context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")

    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local Config = context.Config
    local Connections = context.Connections

    local Targeting = {
        current = nil,
        models = {},
        modelSet = {},
        lastScan = 0,
        running = false
    }

    local rayParams = RaycastParams.new()

    pcall(function()
        rayParams.FilterType = Enum.RaycastFilterType.Exclude
    end)

    if tostring(rayParams.FilterType) ~= "Enum.RaycastFilterType.Exclude" then
        pcall(function()
            rayParams.FilterType = Enum.RaycastFilterType.Blacklist
        end)
    end

    local function getLocalCharacter()
        return context.LocalCharacter or LocalPlayer.Character
    end

    local function getTargetPart(character)
        if not character then
            return nil
        end

        return character:FindFirstChild(Config.Feature1.Part)
            or character:FindFirstChild("Head")
            or character:FindFirstChild("UpperTorso")
            or character:FindFirstChild("Torso")
            or character:FindFirstChild("HumanoidRootPart")
    end

    local function getRoot(character)
        if not character then
            return nil
        end

        return character:FindFirstChild("HumanoidRootPart") or character.PrimaryPart or getTargetPart(character)
    end

    local function humanoidAlive(humanoid)
        if not humanoid or humanoid.Health <= 0 then
            return false
        end

        local ok, state = pcall(function()
            return humanoid:GetState()
        end)

        if ok and state == Enum.HumanoidStateType.Dead then
            return false
        end

        return true
    end

    local function isPlayerCharacter(model)
        return Players:GetPlayerFromCharacter(model) ~= nil
    end

    local function hasHumanoid(model)
        return model and model:IsA("Model") and model:FindFirstChildOfClass("Humanoid") ~= nil
    end

    local function inAimRange(part, screenCenter, rangeSquared)
        local pos, visible = Camera:WorldToViewportPoint(part.Position)

        if not visible then
            return false, rangeSquared
        end

        local dx = pos.X - screenCenter.X
        local dy = pos.Y - screenCenter.Y
        local distSquared = dx * dx + dy * dy

        return distSquared <= rangeSquared, distSquared
    end

    local function addModel(model)
        local localCharacter = getLocalCharacter()

        if not model or not model:IsA("Model") or model == localCharacter or isPlayerCharacter(model) or Targeting.modelSet[model] then
            return
        end

        if not hasHumanoid(model) then
            return
        end

        Targeting.modelSet[model] = true
        Targeting.models[#Targeting.models + 1] = model
    end

    local function removeModel(model)
        if not Targeting.modelSet[model] then
            return
        end

        Targeting.modelSet[model] = nil
    end

    local function addFromInstance(instance)
        if instance:IsA("Model") then
            addModel(instance)
            return
        end

        local model = instance:FindFirstAncestorOfClass("Model")

        if model then
            addModel(model)
        end
    end

    local function rebuildModelCache()
        table.clear(Targeting.models)
        table.clear(Targeting.modelSet)

        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("Humanoid") then
                addModel(descendant.Parent)
            end
        end
    end

    local function validModel(model)
        local localCharacter = getLocalCharacter()

        return model
            and Targeting.modelSet[model]
            and model.Parent ~= nil
            and model ~= localCharacter
            and not isPlayerCharacter(model)
            and hasHumanoid(model)
    end

    local function wallCheck(character, part)
        local localCharacter = getLocalCharacter()

        if not localCharacter then
            return true
        end

        rayParams.FilterDescendantsInstances = {
            localCharacter,
            character
        }

        return Workspace:Raycast(Camera.CFrame.Position, part.Position - Camera.CFrame.Position, rayParams) == nil
    end

    local function basicGeometryValid(root, part)
        return root ~= nil
            and part ~= nil
            and root.Parent ~= nil
            and part.Parent ~= nil
    end

    local function droppedTooFar(current, root)
        local lastY = current.LastRootY or root.Position.Y
        local maxDrop = Config.Feature1.MaxDownwardDrop or 45

        return root.Position.Y < lastY - maxDrop
    end

    local function rememberHeight(target, root)
        target.LastRootY = math.max(target.LastRootY or root.Position.Y, root.Position.Y)
    end

    local function considerCharacter(best, character, player, screenCenter, rangeSquared)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")

        if not humanoidAlive(humanoid) then
            return best
        end

        if player and Config.Feature1.Check2 and player.Team == LocalPlayer.Team then
            return best
        end

        local root = getRoot(character)
        local part = getTargetPart(character)

        if not basicGeometryValid(root, part) then
            return best
        end

        local inRange, distSquared = inAimRange(part, screenCenter, rangeSquared)

        if not inRange or distSquared >= best.DistanceSquared then
            return best
        end

        if Config.Feature1.Check1 and not wallCheck(character, part) then
            return best
        end

        best.Character = character
        best.Part = part
        best.Root = root
        best.Player = player
        best.DistanceSquared = distSquared
        best.LastRootY = root.Position.Y

        return best
    end

    local function scanPlayers(best, screenCenter, rangeSquared)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                best = considerCharacter(best, player.Character, player, screenCenter, rangeSquared)
            end
        end

        return best
    end

    local function scanModels(best, screenCenter, rangeSquared)
        local writeIndex = 1
        local maxTargets = Config.Feature1.MaxTargets or 64

        for readIndex = 1, #Targeting.models do
            local model = Targeting.models[readIndex]

            if validModel(model) then
                Targeting.models[writeIndex] = model
                writeIndex += 1

                if writeIndex <= maxTargets + 1 then
                    best = considerCharacter(best, model, nil, screenCenter, rangeSquared)
                end
            else
                Targeting.modelSet[model] = nil
            end
        end

        for index = writeIndex, #Targeting.models do
            Targeting.models[index] = nil
        end

        return best
    end

    local function currentValid()
        local current = Targeting.current

        if not current or not current.Character then
            return false
        end

        local humanoid = current.Character:FindFirstChildOfClass("Humanoid")

        if not humanoidAlive(humanoid) then
            return false
        end

        local root = getRoot(current.Character)
        local part = getTargetPart(current.Character)

        if not basicGeometryValid(root, part) then
            return false
        end

        if droppedTooFar(current, root) then
            return false
        end

        if current.Player and Config.Feature1.Check2 and current.Player.Team == LocalPlayer.Team then
            return false
        end

        local range = Config.Feature1.Range or 150
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local inRange = inAimRange(part, screenCenter, range * range)

        if not inRange then
            return false
        end

        current.Root = root
        current.Part = part
        rememberHeight(current, root)

        return true
    end

    function Targeting.findTarget()
        Camera = Workspace.CurrentCamera

        local range = Config.Feature1.Range or 150
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local best = {
            Character = nil,
            Part = nil,
            Root = nil,
            Player = nil,
            DistanceSquared = range * range,
            LastRootY = nil
        }

        best = scanPlayers(best, screenCenter, best.DistanceSquared)
        best = scanModels(best, screenCenter, best.DistanceSquared)

        if best.Character then
            Targeting.current = best
            return best
        end

        Targeting.current = nil
        return nil
    end

    function Targeting.update()
        if not Config.Feature1.Enabled or not Config.Feature1.Active then
            Targeting.current = nil
            return nil
        end

        Camera = Workspace.CurrentCamera

        local now = os.clock()
        local interval = Config.Feature1.ScanInterval or 0.05

        if not currentValid() or now - Targeting.lastScan >= interval then
            Targeting.lastScan = now
            Targeting.findTarget()
        end

        local target = Targeting.current

        if target and target.Part and currentValid() then
            local delta = target.Part.Position - Camera.CFrame.Position

            if delta.Magnitude > 0 then
                local alpha = math.clamp(1 / math.max(Config.Feature1.Speed, 1), 0, 1)
                local goal = CFrame.new(Camera.CFrame.Position, target.Part.Position)

                Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
            end
        end

        return target
    end

    function Targeting.start()
        if Targeting.running then
            return Targeting
        end

        Targeting.running = true
        rebuildModelCache()

        if Connections then
            Connections.add("TargetingDescendantAdded", Workspace.DescendantAdded:Connect(addFromInstance))
            Connections.add("TargetingDescendantRemoving", Workspace.DescendantRemoving:Connect(function(instance)
                if instance:IsA("Model") then
                    removeModel(instance)
                end
            end))
        end

        return Targeting
    end

    function Targeting.stop()
        Targeting.running = false
        Targeting.current = nil
        table.clear(Targeting.models)
        table.clear(Targeting.modelSet)

        return Targeting
    end

    context.Targeting = Targeting

    return Targeting
end
