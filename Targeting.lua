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

    local function wallCheck(character, part)
        local localCharacter = getLocalCharacter()

        if not localCharacter then
            return false
        end

        local origin = Camera.CFrame.Position
        local direction = part.Position - origin
        local ray = Ray.new(origin, direction)
        local hit = Workspace:FindPartOnRayWithIgnoreList(ray, {
            localCharacter,
            character
        })

        return hit == nil
    end

    local function considerCharacter(best, character, player)
        local humanoid = character and character:FindFirstChildOfClass("Humanoid")
        local root = character and character:FindFirstChild("HumanoidRootPart")
        local part = character and character:FindFirstChild(Config.Feature1.Part)

        if not humanoid or humanoid.Health <= 0 or not root or not part then
            return best
        end

        if player and Config.Feature1.Check2 and player.Team == LocalPlayer.Team then
            return best
        end

        local pos, visible = Camera:WorldToViewportPoint(root.Position)

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
                if descendant:FindFirstChildOfClass("Humanoid") and descendant:FindFirstChild("HumanoidRootPart") then
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
            local current = Camera.CFrame.LookVector
            local targetDir = (target.Part.Position - Camera.CFrame.Position).Unit

            Camera.CFrame = CFrame.new(
                Camera.CFrame.Position,
                Camera.CFrame.Position + current:Lerp(targetDir, 1 / Config.Feature1.Speed)
            )
        end

        return target
    end

    context.Targeting = Targeting

    return Targeting
end
