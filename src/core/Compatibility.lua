return function(context)
    local Players = game:GetService("Players")
    local Workspace = game:GetService("Workspace")
    local RunService = game:GetService("RunService")
    local UserInputService = game:GetService("UserInputService")
    local GuiService = game:GetService("GuiService")

    local Config = context.Config

    local Compatibility = {
        Capabilities = {},
        Disabled = {}
    }

    local function setCapability(name, ok, detail)
        Compatibility.Capabilities[name] = {
            Ok = ok == true,
            Detail = detail
        }

        return ok == true
    end

    local function disable(feature, reason)
        Compatibility.Disabled[feature] = reason

        if Config.Diagnostics then
            Config.Diagnostics.LastMessage = tostring(feature) .. " disabled: " .. tostring(reason)
        end
    end

    local function testDrawing()
        if typeof(Drawing) ~= "table" or typeof(Drawing.new) ~= "function" then
            return false, "Drawing.new is unavailable"
        end

        local ok, err = pcall(function()
            local circle = Drawing.new("Circle")
            circle.Visible = false
            circle.Radius = 12
            circle.Position = Vector2.new(20, 20)
            circle.Color = Color3.fromRGB(255, 255, 255)

            if circle.Remove then
                circle:Remove()
            end

            local text = Drawing.new("Text")
            text.Visible = false
            text.Text = "compat"
            text.Position = Vector2.new(20, 20)

            if text.Remove then
                text:Remove()
            end
        end)

        return ok, err
    end

    local function ensureFolder(path)
        if typeof(isfolder) ~= "function" or typeof(makefolder) ~= "function" then
            return false
        end

        if not isfolder(path) then
            makefolder(path)
        end

        return true
    end

    local function testFileSystem()
        if typeof(writefile) ~= "function"
            or typeof(readfile) ~= "function"
            or typeof(isfile) ~= "function"
            or typeof(isfolder) ~= "function"
            or typeof(makefolder) ~= "function" then
            return false, "file API is incomplete"
        end

        local ok, err = pcall(function()
            ensureFolder("CometPrivate")
            local path = "CometPrivate/compat.tmp"
            writefile(path, "ok")

            if not isfile(path) then
                error("isfile returned false after writefile")
            end

            if readfile(path) ~= "ok" then
                error("readfile did not match written content")
            end

            if typeof(delfile) == "function" then
                pcall(function()
                    delfile(path)
                end)
            end
        end)

        return ok, err
    end

    local function testHttpGet()
        if typeof(game.HttpGet) ~= "function" then
            return false, "game:HttpGet is unavailable"
        end

        return true
    end

    local function testCameraProjection()
        local camera = Workspace.CurrentCamera

        if not camera then
            return true, "deferred until Workspace.CurrentCamera exists"
        end

        local ok, err = pcall(function()
            camera:WorldToViewportPoint(camera.CFrame.Position + camera.CFrame.LookVector)
        end)

        if not ok then
            return false, err
        end

        return true
    end

    local function testGuiInset()
        local ok, err = pcall(function()
            GuiService:GetGuiInset()
        end)

        if not ok then
            return false, err
        end

        return true
    end

    local function testMouseLocation()
        local ok, err = pcall(function()
            UserInputService:GetMouseLocation()
        end)

        if not ok then
            return false, err
        end

        return true
    end

    local function testRenderStep()
        local ok, result = pcall(function()
            return typeof(RunService.BindToRenderStep) == "function" and typeof(RunService.UnbindFromRenderStep) == "function"
        end)

        if not ok then
            return false, result
        end

        return result, result and nil or "BindToRenderStep/UnbindFromRenderStep unavailable"
    end

    local function testLocalPlayer()
        if Players.LocalPlayer then
            return true
        end

        return false, "Players.LocalPlayer is nil"
    end

    local function applyFeatureFallbacks()
        if not Compatibility.supports("Drawing") then
            Config.UI.Enabled = false
            Config.Feature2.Style1 = false
            Config.Feature2.Style2 = false
            Config.Feature2.Style3 = false
            Config.Feature2.Style4 = false
            Config.Feature2.Style5 = false
            disable("Overlay", "Drawing API is unavailable or incomplete")
        end

        if not Compatibility.supports("FileSystem") then
            disable("Profiles", "file API is unavailable or incomplete")
        end

        if not Compatibility.supports("HttpGet") or not Compatibility.supports("Loadstring") then
            Config.GUI.Enabled = false
            disable("ExternalUI", "external UI libraries require HttpGet and loadstring")
            disable("VersionCheck", "remote version checks require HttpGet and loadstring")
        end

        if not Compatibility.supports("CameraProjection") then
            Config.Feature1.Enabled = false
            disable("Aiming", "camera projection is unavailable")
        end
    end

    function Compatibility.supports(name)
        local capability = Compatibility.Capabilities[name]
        return capability ~= nil and capability.Ok == true
    end

    function Compatibility.report()
        local lines = {}

        for name, capability in pairs(Compatibility.Capabilities) do
            local status = capability.Ok and "OK" or "Missing"
            local detail = capability.Detail and (": " .. tostring(capability.Detail)) or ""
            lines[#lines + 1] = name .. " - " .. status .. detail
        end

        for feature, reason in pairs(Compatibility.Disabled) do
            lines[#lines + 1] = "Disabled " .. feature .. " - " .. tostring(reason)
        end

        table.sort(lines)

        return table.concat(lines, "\n")
    end

    setCapability("Loadstring", typeof(loadstring) == "function", "required for remote/bundled module execution")
    setCapability("HttpGet", testHttpGet())
    setCapability("Task", typeof(task) == "table" and typeof(task.spawn) == "function" and typeof(task.wait) == "function", "task.spawn/task.wait")
    setCapability("TaskDelay", typeof(task) == "table" and typeof(task.delay) == "function", "task.delay")
    setCapability("Drawing", testDrawing())
    setCapability("FileSystem", testFileSystem())
    setCapability("CameraProjection", testCameraProjection())
    setCapability("GuiInset", testGuiInset())
    setCapability("MouseLocation", testMouseLocation())
    setCapability("RenderStep", testRenderStep())
    setCapability("LocalPlayer", testLocalPlayer())

    applyFeatureFallbacks()

    context.Compatibility = Compatibility

    if context.Diagnostics then
        context.Diagnostics.Compatibility = {
            Capabilities = Compatibility.Capabilities,
            Disabled = Compatibility.Disabled
        }
    end

    return Compatibility
end
