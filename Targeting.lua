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

    function Targeting.findTarget()
        Camera = Workspace.CurrentCamera

        local best = nil
        local bestDist = Config.Feature1.Range
        local screenCenter = Vector2.new(Camera.ViewportSize.X / 2, Camera.ViewportSize.Y / 2)

        for _, player in ipairs(Players:GetPlayers()) do
            if player ~= LocalPlayer and player.Character then
                local character = player.Character
                local humanoid = character:FindFirstChild("Humanoid")
                local root = character:FindFirstChild("HumanoidRootPart")
                local part = character:FindFirstChild(Config.Feature1.Part)

                if humanoid and humanoid.Health > 0 and root and part then
                    if Config.Feature1.Check2 and player.Team == LocalPlayer.Team then
                        continue
                    end

                    local pos, visible = Camera:WorldToViewportPoint(root.Position)

                    if not visible then
                        continue
                    end

                    local screenPos = Vector2.new(pos.X, pos.Y)
                    local dist = (screenPos - screenCenter).Magnitude

                    if dist < bestDist then
                        if Config.Feature1.Check1 and not wallCheck(character, part) then
                            continue
                        end

                        bestDist = dist
                        best = player
                    end
                end
            end
        end

        Targeting.current = best
        return best
    end

    function Targeting.update()
        if not Config.Feature1.Enabled or not Config.Feature1.Active then
            Targeting.current = nil
            return nil
        end

        Camera = Workspace.CurrentCamera

        local target = Targeting.findTarget()

        if target and target.Character and target.Character:FindFirstChild(Config.Feature1.Part) then
            local targetPart = target.Character[Config.Feature1.Part]
            local current = Camera.CFrame.LookVector
            local targetDir = (targetPart.Position - Camera.CFrame.Position).Unit

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
