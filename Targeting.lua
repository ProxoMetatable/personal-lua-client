return function(context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")

    local Camera = Workspace.CurrentCamera
    local LocalPlayer = Players.LocalPlayer
    local Config = context.Config

    local Targeting = {
        current = nil
    }

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

    local function wallCheck(character, part)
        local localCharacter = getLocalCharacter()

        if not localCharacter then
            return true
        end

        local origin = Camera.CFrame.Position
        local direction = part.Position - origin
        local params = RaycastParams.new()

        local filterOk = pcall(function()
            params.FilterType = Enum.RaycastFilterType.Exclude
        end)

        if not filterOk then
            params.FilterType = Enum.RaycastFilterType.Blacklist
        end

        params.FilterDescendantsInstances = {
            localCharacter,
            character
        }

        return Workspace:Raycast(origin, direction, params) == nil
    end

    local function considerCharacter(best, character, player)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = getRoot(character)
        local part = getTargetPart(character)

        if not humanoid or humanoid.Health <= 0 or not root or not part then
            return best
        end

        if player and Config.Feature1.Check2 and player.Team == LocalPlayer.Team then
            return best
        end

        local pos, visible = Camera:WorldToViewportPoint(part.Position)

        if not visible then
            return best
        end

        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)
        local screenPos = Vector2.new(pos.X, pos.Y)
        local dist = (screenPos - screenCenter).Magnitude

        if dist >= best.Distance then
            return best
        end

        if Config.Feature1.Check1 and not wallCheck(character, part) then
            return best
        end

        return {
            Character = character,
            Part = part,
            Root = root,
            Player = player,
            Distance = dist
        }
    end

    local function scanPlayers(best)
        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                best = considerCharacter(best, player.Character, player)
            end
        end

        return best
    end

    local function scanWorkspaceModels(best)
        local localCharacter = getLocalCharacter()

        for _, descendant in ipairs(Workspace:GetDescendants()) do
            if descendant:IsA("Model") and descendant ~= localCharacter and not Players:GetPlayerFromCharacter(descendant) then
                if descendant:FindFirstChildOfClass("Humanoid") then
                    best = considerCharacter(best, descendant, nil)
                end
            end
        end

        return best
    end

    function Targeting.findTarget()
        Camera = Workspace.CurrentCamera

        local best = {
            Character = nil,
            Part = nil,
            Root = nil,
            Player = nil,
            Distance = Config.Feature1.Range
        }

        best = scanPlayers(best)
        best = scanWorkspaceModels(best)

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

        local target = Targeting.findTarget()

        if target and target.Part then
            local delta = target.Part.Position - Camera.CFrame.Position

            if delta.Magnitude > 0 then
                local alpha = math.clamp(1 / math.max(Config.Feature1.Speed, 1), 0, 1)
                local goal = CFrame.new(Camera.CFrame.Position, target.Part.Position)

                Camera.CFrame = Camera.CFrame:Lerp(goal, alpha)
            end
        end

        return target
    end

    context.Targeting = Targeting

    return Targeting
end
