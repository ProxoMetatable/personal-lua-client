return function(context)
    local Players = game:GetService("Players")
    local UserInputService = game:GetService("UserInputService")

    local LocalPlayer = Players.LocalPlayer
    local Config = context.Config

    local Gui = {
        running = false,
        screen = nil,
        panel = nil,
        controls = {},
        connections = {},
        capturing = nil,
        blockUntil = 0
    }

    local rowOrder = 0

    local function connect(signal, callback)
        local connection = signal:Connect(callback)
        table.insert(Gui.connections, connection)
        return connection
    end

    local function disconnectAll()
        for _, connection in ipairs(Gui.connections) do
            connection:Disconnect()
        end

        Gui.connections = {}
    end

    local function make(className, props, parent)
        local object = Instance.new(className)

        for key, value in pairs(props) do
            object[key] = value
        end

        object.Parent = parent
        return object
    end

    local function keyName(keyCode)
        if keyCode and keyCode.Name then
            return keyCode.Name
        end

        return "None"
    end

    local function colorText(value)
        return tostring(math.floor(math.clamp(value, 0, 1) * 255 + 0.5))
    end

    local function setButtonState(button, state)
        button.Text = state and "ON" or "OFF"
        button.BackgroundColor3 = state and Color3.fromRGB(45, 170, 95) or Color3.fromRGB(120, 45, 55)
    end

    function Gui.refresh()
        for _, refresh in ipairs(Gui.controls) do
            refresh()
        end
    end

    function Gui.shouldBlockInput()
        return Gui.capturing ~= nil or os.clock() < Gui.blockUntil
    end

    local function addControl(refresh)
        table.insert(Gui.controls, refresh)
        refresh()
    end

    local function createRow(parent, height)
        rowOrder = rowOrder + 1

        return make("Frame", {
            BackgroundTransparency = 1,
            LayoutOrder = rowOrder,
            Size = UDim2.new(1, 0, 0, height or 32)
        }, parent)
    end

    local function addSection(parent, text)
        local row = createRow(parent, 26)
        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -8, 1, 0),
            Position = UDim2.new(0, 4, 0, 0),
            Font = Enum.Font.GothamBold,
            Text = text,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)
    end

    local function addToggle(parent, label, getter, setter)
        local row = createRow(parent, 34)
        local button = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.new(0, 62, 0, 24),
            AutoButtonColor = true,
            Font = Enum.Font.GothamBold,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12
        }, row)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -78, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            Font = Enum.Font.Gotham,
            Text = label,
            TextColor3 = Color3.fromRGB(225, 225, 225),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)

        connect(button.MouseButton1Click, function()
            setter(not getter())
            Gui.refresh()
        end)

        addControl(function()
            setButtonState(button, getter())
        end)
    end

    local function addNumber(parent, label, getter, setter, minValue, maxValue)
        local row = createRow(parent, 34)
        local box = make("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.new(0, 76, 0, 24),
            BackgroundColor3 = Color3.fromRGB(42, 45, 54),
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12
        }, row)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -92, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            Font = Enum.Font.Gotham,
            Text = label,
            TextColor3 = Color3.fromRGB(225, 225, 225),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)

        connect(box.FocusLost, function()
            local value = tonumber(box.Text)

            if value then
                if minValue then
                    value = math.max(minValue, value)
                end

                if maxValue then
                    value = math.min(maxValue, value)
                end

                setter(value)
            end

            Gui.refresh()
        end)

        addControl(function()
            box.Text = tostring(getter())
        end)
    end

    local function addText(parent, label, getter, setter)
        local row = createRow(parent, 34)
        local box = make("TextBox", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.new(0, 104, 0, 24),
            BackgroundColor3 = Color3.fromRGB(42, 45, 54),
            BorderSizePixel = 0,
            ClearTextOnFocus = false,
            Font = Enum.Font.Gotham,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12
        }, row)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -120, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            Font = Enum.Font.Gotham,
            Text = label,
            TextColor3 = Color3.fromRGB(225, 225, 225),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)

        connect(box.FocusLost, function()
            if box.Text ~= "" then
                setter(box.Text)
            end

            Gui.refresh()
        end)

        addControl(function()
            box.Text = tostring(getter())
        end)
    end

    local function addKey(parent, label, getter, setter)
        local row = createRow(parent, 34)
        local button = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -6, 0.5, 0),
            Size = UDim2.new(0, 104, 0, 24),
            BackgroundColor3 = Color3.fromRGB(42, 45, 54),
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Font = Enum.Font.Gotham,
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12
        }, row)

        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -120, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            Font = Enum.Font.Gotham,
            Text = label,
            TextColor3 = Color3.fromRGB(225, 225, 225),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)

        connect(button.MouseButton1Click, function()
            Gui.capturing = {
                setter = setter,
                button = button
            }
            Gui.blockUntil = os.clock() + 0.25
            button.Text = "Press key"
        end)

        addControl(function()
            if not Gui.capturing or Gui.capturing.button ~= button then
                button.Text = keyName(getter())
            end
        end)
    end

    local function addColor(parent, label, getter, setter)
        local row = createRow(parent, 38)
        local values = {}
        local names = {"R", "G", "B"}

        make("TextLabel", {
            BackgroundTransparency = 1,
            Size = UDim2.new(1, -150, 1, 0),
            Position = UDim2.new(0, 6, 0, 0),
            Font = Enum.Font.Gotham,
            Text = label,
            TextColor3 = Color3.fromRGB(225, 225, 225),
            TextSize = 12,
            TextXAlignment = Enum.TextXAlignment.Left
        }, row)

        for index, name in ipairs(names) do
            local box = make("TextBox", {
                AnchorPoint = Vector2.new(1, 0.5),
                Position = UDim2.new(1, -6 - ((3 - index) * 46), 0.5, 0),
                Size = UDim2.new(0, 40, 0, 24),
                BackgroundColor3 = Color3.fromRGB(42, 45, 54),
                BorderSizePixel = 0,
                ClearTextOnFocus = false,
                Font = Enum.Font.Gotham,
                PlaceholderText = name,
                TextColor3 = Color3.fromRGB(255, 255, 255),
                TextSize = 12
            }, row)

            values[index] = box

            connect(box.FocusLost, function()
                local r = tonumber(values[1].Text) or math.floor(getter().R * 255)
                local g = tonumber(values[2].Text) or math.floor(getter().G * 255)
                local b = tonumber(values[3].Text) or math.floor(getter().B * 255)

                r = math.clamp(r, 0, 255)
                g = math.clamp(g, 0, 255)
                b = math.clamp(b, 0, 255)

                setter(Color3.fromRGB(r, g, b))
                Gui.refresh()
            end)
        end

        addControl(function()
            local color = getter()
            values[1].Text = colorText(color.R)
            values[2].Text = colorText(color.G)
            values[3].Text = colorText(color.B)
        end)
    end

    local function build()
        rowOrder = 0

        local parent = LocalPlayer:WaitForChild("PlayerGui")
        local old = parent:FindFirstChild("PersonalLuaClientGui")

        if old then
            old:Destroy()
        end

        local screen = make("ScreenGui", {
            Name = "PersonalLuaClientGui",
            ResetOnSpawn = false,
            IgnoreGuiInset = true
        }, parent)

        local toggle = make("TextButton", {
            Position = UDim2.new(0, 16, 0.5, -260),
            Size = UDim2.new(0, 44, 0, 30),
            BackgroundColor3 = Color3.fromRGB(28, 31, 38),
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Font = Enum.Font.GothamBold,
            Text = "PL",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 13
        }, screen)

        local panel = make("Frame", {
            Position = UDim2.new(0, 68, 0.5, -260),
            Size = UDim2.new(0, 330, 0, 520),
            BackgroundColor3 = Color3.fromRGB(22, 24, 30),
            BorderSizePixel = 0,
            Visible = Config.GUI.Visible
        }, screen)

        local title = make("TextLabel", {
            Active = true,
            BackgroundColor3 = Color3.fromRGB(32, 36, 45),
            BorderSizePixel = 0,
            Size = UDim2.new(1, 0, 0, 38),
            Font = Enum.Font.GothamBold,
            Text = "personal-lua-client",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 14
        }, panel)

        local close = make("TextButton", {
            AnchorPoint = Vector2.new(1, 0.5),
            Position = UDim2.new(1, -8, 0, 19),
            Size = UDim2.new(0, 28, 0, 24),
            BackgroundColor3 = Color3.fromRGB(48, 52, 62),
            BorderSizePixel = 0,
            AutoButtonColor = true,
            Font = Enum.Font.GothamBold,
            Text = "X",
            TextColor3 = Color3.fromRGB(255, 255, 255),
            TextSize = 12
        }, panel)

        local scroll = make("ScrollingFrame", {
            Position = UDim2.new(0, 8, 0, 46),
            Size = UDim2.new(1, -16, 1, -54),
            BackgroundTransparency = 1,
            BorderSizePixel = 0,
            CanvasSize = UDim2.new(0, 0, 0, 0),
            ScrollBarThickness = 4
        }, panel)

        local list = make("UIListLayout", {
            Padding = UDim.new(0, 4),
            SortOrder = Enum.SortOrder.LayoutOrder
        }, scroll)

        connect(list:GetPropertyChangedSignal("AbsoluteContentSize"), function()
            scroll.CanvasSize = UDim2.new(0, 0, 0, list.AbsoluteContentSize.Y + 8)
        end)

        addSection(scroll, "Aiming")
        addToggle(scroll, "Enabled", function() return Config.Feature1.Enabled end, function(value) Config.Feature1.Enabled = value end)
        addKey(scroll, "Aim Hold Key", function() return Config.Keys.HoldFeature1 end, function(value) Config.Keys.HoldFeature1 = value end)
        addNumber(scroll, "Range", function() return Config.Feature1.Range end, function(value) Config.Feature1.Range = value end, 1, 2000)
        addNumber(scroll, "Speed", function() return Config.Feature1.Speed end, function(value) Config.Feature1.Speed = value end, 1, 100)
        addText(scroll, "Target Part", function() return Config.Feature1.Part end, function(value) Config.Feature1.Part = value end)
        addToggle(scroll, "Wall Check", function() return Config.Feature1.Check1 end, function(value) Config.Feature1.Check1 = value end)
        addToggle(scroll, "Team Check", function() return Config.Feature1.Check2 end, function(value) Config.Feature1.Check2 = value end)

        addSection(scroll, "Overlay")
        addToggle(scroll, "Overlay Enabled", function() return Config.UI.Enabled end, function(value) Config.UI.Enabled = value end)
        addKey(scroll, "Overlay Toggle Key", function() return Config.Keys.ToggleUI end, function(value) Config.Keys.ToggleUI = value end)
        addToggle(scroll, "Boxes", function() return Config.Feature2.Style1 end, function(value) Config.Feature2.Style1 = value end)
        addToggle(scroll, "Names", function() return Config.Feature2.Style2 end, function(value) Config.Feature2.Style2 = value end)
        addToggle(scroll, "Health Bar", function() return Config.Feature2.Style3 end, function(value) Config.Feature2.Style3 = value end)
        addToggle(scroll, "Distance", function() return Config.Feature2.Style4 end, function(value) Config.Feature2.Style4 = value end)
        addToggle(scroll, "Tracer", function() return Config.Feature2.Style5 end, function(value) Config.Feature2.Style5 = value end)
        addToggle(scroll, "Team Color", function() return Config.Feature2.UseTeam end, function(value) Config.Feature2.UseTeam = value end)
        addColor(scroll, "Main Color", function() return Config.Feature2.MainColor end, function(value) Config.Feature2.MainColor = value end)

        connect(toggle.MouseButton1Click, function()
            Config.GUI.Visible = not Config.GUI.Visible
            panel.Visible = Config.GUI.Visible
        end)

        connect(close.MouseButton1Click, function()
            Config.GUI.Visible = false
            panel.Visible = false
        end)

        local dragging = false
        local dragInput = nil
        local dragStart = nil
        local startPos = nil

        connect(title.InputBegan, function(input)
            if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.Touch then
                dragging = true
                dragStart = input.Position
                startPos = panel.Position

                connect(input.Changed, function()
                    if input.UserInputState == Enum.UserInputState.End then
                        dragging = false
                    end
                end)
            end
        end)

        connect(title.InputChanged, function(input)
            if input.UserInputType == Enum.UserInputType.MouseMovement or input.UserInputType == Enum.UserInputType.Touch then
                dragInput = input
            end
        end)

        connect(UserInputService.InputChanged, function(input)
            if dragging and input == dragInput then
                local delta = input.Position - dragStart
                panel.Position = UDim2.new(startPos.X.Scale, startPos.X.Offset + delta.X, startPos.Y.Scale, startPos.Y.Offset + delta.Y)
            end
        end)

        connect(UserInputService.InputBegan, function(input)
            if Gui.capturing and input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
                Gui.capturing.setter(input.KeyCode)
                Gui.capturing = nil
                Gui.blockUntil = os.clock() + 0.25
                Gui.refresh()
            end
        end)

        Gui.screen = screen
        Gui.panel = panel
        Gui.toggle = toggle
        Gui.refresh()
    end

    function Gui.start()
        if Gui.running or not Config.GUI.Enabled then
            return Gui
        end

        Gui.running = true
        build()

        return Gui
    end

    function Gui.destroy()
        disconnectAll()

        if Gui.screen then
            Gui.screen:Destroy()
        end

        Gui.screen = nil
        Gui.panel = nil
        Gui.toggle = nil
        Gui.controls = {}
        Gui.capturing = nil
        Gui.running = false

        return Gui
    end

    context.Gui = Gui

    return Gui
end
