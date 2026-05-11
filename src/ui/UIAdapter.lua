return function(context)
    local Config = context.Config
    local manifest = context.Manifest or {}
    local providerUrls = manifest.UIProviders or {}

    local UIAdapter = {
        Provider = nil,
        Library = nil,
        Window = nil,
        Tabs = {},
        LastError = nil
    }

    local function enumKey(name, fallback)
        if type(name) ~= "string" then
            return fallback
        end

        local ok, value = pcall(function()
            return Enum.KeyCode[name]
        end)

        if ok and value then
            return value
        end

        return fallback
    end

    local function loadRemote(url)
        local ok, result = pcall(function()
            return loadstring(game:HttpGet(url, true))()
        end)

        if ok then
            return true, result
        end

        return false, result
    end

    local function setDiagnostics(message)
        UIAdapter.LastError = message

        if Config.Diagnostics then
            Config.Diagnostics.LastMessage = tostring(message)
        end
    end

    local function makeFluentTab(rawTab, fluent)
        local tab = {
            Raw = rawTab,
            Provider = "Fluent"
        }

        function tab:addSection(title)
            pcall(function()
                rawTab:AddSection(title)
            end)
        end

        function tab:addParagraph(opts)
            local control = nil

            pcall(function()
                control = rawTab:AddParagraph({
                    Title = opts.title or opts.Title or "",
                    Content = opts.content or opts.Content or ""
                })
            end)

            return control
        end

        function tab:addButton(opts)
            return rawTab:AddButton({
                Title = opts.title or opts.Title,
                Description = opts.description or opts.Description,
                Callback = opts.callback or opts.Callback
            })
        end

        function tab:addToggle(id, opts)
            local control = rawTab:AddToggle(id, {
                Title = opts.title or opts.Title,
                Default = opts.default or opts.CurrentValue or false
            })

            if opts.callback or opts.Callback then
                control:OnChanged(opts.callback or opts.Callback)
            end

            return control
        end

        function tab:addSlider(id, opts)
            local control = rawTab:AddSlider(id, {
                Title = opts.title or opts.Title,
                Description = opts.description or opts.Description or opts.suffix,
                Default = opts.default or opts.CurrentValue or 0,
                Min = opts.min or (opts.Range and opts.Range[1]) or 0,
                Max = opts.max or (opts.Range and opts.Range[2]) or 100,
                Rounding = opts.rounding or opts.Increment or 1
            })

            if opts.callback or opts.Callback then
                control:OnChanged(opts.callback or opts.Callback)
            end

            return control
        end

        function tab:addDropdown(id, opts)
            local values = opts.values or opts.Values or {}
            local default = opts.default or opts.Default
            local fluentDefault = default

            if type(default) == "string" then
                for index, value in ipairs(values) do
                    if value == default then
                        fluentDefault = index
                        break
                    end
                end
            end

            local control = rawTab:AddDropdown(id, {
                Title = opts.title or opts.Title,
                Description = opts.description or opts.Description,
                Values = values,
                Multi = opts.multi or opts.Multi or false,
                Default = fluentDefault
            })

            if opts.callback or opts.Callback then
                control:OnChanged(opts.callback or opts.Callback)
            end

            if type(default) == "string" then
                pcall(function()
                    control:SetValue(default)
                end)
            end

            return control
        end

        function tab:addInput(id, opts)
            local control = rawTab:AddInput(id, {
                Title = opts.title or opts.Title,
                Default = opts.default or opts.CurrentValue or "",
                Placeholder = opts.placeholder or opts.PlaceholderText or "",
                Numeric = opts.numeric or opts.Numeric or false,
                Finished = opts.finished or opts.Finished or false,
                Callback = opts.callback or opts.Callback
            })

            return control
        end

        function tab:addColorPicker(id, opts)
            local control = rawTab:AddColorpicker(id, {
                Title = opts.title or opts.Title,
                Default = opts.color or opts.Color or opts.default or Color3.fromRGB(255, 255, 255)
            })

            if opts.callback or opts.Callback then
                local callback = opts.callback or opts.Callback

                control:OnChanged(function()
                    callback(control.Value)
                end)
            end

            return control
        end

        function tab:addKeybind(id, opts)
            local control = rawTab:AddKeybind(id, {
                Title = opts.title or opts.Title,
                Mode = opts.mode or opts.Mode or "Hold",
                Default = opts.default or opts.Default or "RightShift",
                Callback = opts.callback or opts.Callback,
                ChangedCallback = opts.changedCallback or opts.ChangedCallback
            })

            return control
        end

        return tab
    end

    local function makeRayfieldTab(rawTab)
        local tab = {
            Raw = rawTab,
            Provider = "Rayfield"
        }

        function tab:addSection(title)
            return rawTab:CreateSection(title)
        end

        function tab:addParagraph(opts)
            if rawTab.CreateParagraph then
                return rawTab:CreateParagraph({
                    Title = opts.title or opts.Title or "",
                    Content = opts.content or opts.Content or ""
                })
            end

            return nil
        end

        function tab:addButton(opts)
            return rawTab:CreateButton({
                Name = opts.title or opts.Title,
                Callback = opts.callback or opts.Callback
            })
        end

        function tab:addToggle(id, opts)
            return rawTab:CreateToggle({
                Name = opts.title or opts.Title,
                CurrentValue = opts.default or opts.CurrentValue or false,
                Flag = id,
                Callback = opts.callback or opts.Callback
            })
        end

        function tab:addSlider(id, opts)
            return rawTab:CreateSlider({
                Name = opts.title or opts.Title,
                Range = opts.Range or {opts.min or 0, opts.max or 100},
                Increment = opts.Increment or opts.rounding or 1,
                Suffix = opts.suffix or "",
                CurrentValue = opts.default or opts.CurrentValue or 0,
                Flag = id,
                Callback = opts.callback or opts.Callback
            })
        end

        function tab:addDropdown(id, opts)
            if rawTab.CreateDropdown then
                return rawTab:CreateDropdown({
                    Name = opts.title or opts.Title,
                    Options = opts.values or opts.Values or {},
                    CurrentOption = opts.default or opts.Default,
                    MultipleOptions = opts.multi or opts.Multi or false,
                    Flag = id,
                    Callback = opts.callback or opts.Callback
                })
            end

            return nil
        end

        function tab:addInput(id, opts)
            return rawTab:CreateInput({
                Name = opts.title or opts.Title,
                CurrentValue = opts.default or opts.CurrentValue or "",
                PlaceholderText = opts.placeholder or opts.PlaceholderText or "",
                RemoveTextAfterFocusLost = false,
                Flag = id,
                Callback = opts.callback or opts.Callback
            })
        end

        function tab:addColorPicker(id, opts)
            return rawTab:CreateColorPicker({
                Name = opts.title or opts.Title,
                Color = opts.color or opts.Color or opts.default or Color3.fromRGB(255, 255, 255),
                Flag = id,
                Callback = opts.callback or opts.Callback
            })
        end

        function tab:addKeybind(id, opts)
            if rawTab.CreateKeybind then
                return rawTab:CreateKeybind({
                    Name = opts.title or opts.Title,
                    CurrentKeybind = opts.default or opts.Default or "RightShift",
                    HoldToInteract = (opts.mode or opts.Mode) == "Hold",
                    Flag = id,
                    Callback = opts.callback or opts.Callback
                })
            end

            return nil
        end

        return tab
    end

    local function createFluentWindow(opts)
        local url = providerUrls.Fluent or "https://github.com/dawid-scripts/Fluent/releases/latest/download/main.lua"
        local ok, fluent = loadRemote(url)

        if not ok or not fluent then
            return false, fluent or "Fluent returned nil"
        end

        local window = fluent:CreateWindow({
            Title = opts.title or "Comet",
            SubTitle = opts.subtitle or "stable",
            TabWidth = 150,
            Size = UDim2.fromOffset(620, 500),
            Acrylic = Config.UI.Acrylic == true,
            Theme = Config.UI.Theme or "Dark",
            MinimizeKey = enumKey(Config.Input and Config.Input.MenuBind, Enum.KeyCode.RightShift)
        })

        pcall(function()
            if fluent.ToggleTransparency then
                fluent:ToggleTransparency(Config.UI.Transparency == true)
            end
        end)

        UIAdapter.Provider = "Fluent"
        UIAdapter.Library = fluent
        UIAdapter.Window = window

        return true, {
            Provider = "Fluent",
            Library = fluent,
            Window = window,
            addTab = function(_, id, title, icon)
                local rawTab = window:AddTab({
                    Title = title,
                    Icon = icon or ""
                })
                local tab = makeFluentTab(rawTab, fluent)
                UIAdapter.Tabs[id] = tab
                return tab
            end,
            notify = function(_, title, content, duration, subContent)
                pcall(function()
                    fluent:Notify({
                        Title = title,
                        Content = content,
                        SubContent = subContent,
                        Duration = duration or 5
                    })
                end)
            end,
            selectTab = function(_, index)
                pcall(function()
                    window:SelectTab(index)
                end)
            end,
            destroy = function()
                pcall(function()
                    fluent:Destroy()
                end)
                pcall(function()
                    window:Destroy()
                end)
            end
        }
    end

    local function createRayfieldWindow(opts)
        local url = providerUrls.Rayfield or "https://sirius.menu/rayfield"
        local ok, rayfield = loadRemote(url)

        if not ok or not rayfield then
            return false, rayfield or "Rayfield returned nil"
        end

        local window = rayfield:CreateWindow({
            Name = opts.title or "Comet",
            Icon = 0,
            LoadingTitle = opts.title or "Comet",
            LoadingSubtitle = opts.subtitle or "stable",
            ShowText = opts.title or "Comet",
            Theme = "Default",
            DisableRayfieldPrompts = true,
            DisableBuildWarnings = true,
            ConfigurationSaving = {
                Enabled = false,
                FolderName = "CometPrivate",
                FileName = "rayfield-disabled"
            },
            Discord = {
                Enabled = false,
                Invite = "",
                RememberJoins = false
            },
            KeySystem = false
        })

        UIAdapter.Provider = "Rayfield"
        UIAdapter.Library = rayfield
        UIAdapter.Window = window

        return true, {
            Provider = "Rayfield",
            Library = rayfield,
            Window = window,
            addTab = function(_, id, title)
                local rawTab = window:CreateTab(title, 0)
                local tab = makeRayfieldTab(rawTab)
                UIAdapter.Tabs[id] = tab
                return tab
            end,
            notify = function(_, title, content, duration)
                pcall(function()
                    rayfield:Notify({
                        Title = title,
                        Content = content,
                        Duration = duration or 5
                    })
                end)
            end,
            selectTab = function() end,
            destroy = function()
                pcall(function()
                    rayfield:Destroy()
                end)
            end
        }
    end

    function UIAdapter.createWindow(opts)
        local compatibility = context.Compatibility

        if compatibility and (not compatibility.supports("HttpGet") or not compatibility.supports("Loadstring")) then
            setDiagnostics("External UI disabled: HttpGet/loadstring support is incomplete")
            return nil
        end

        local requested = Config.UI.Provider or "Fluent"
        local attempts = {}

        if requested == "Fluent" then
            attempts = {createFluentWindow, createRayfieldWindow}
        else
            attempts = {createRayfieldWindow, createFluentWindow}
        end

        for _, create in ipairs(attempts) do
            local ran, ok, result = pcall(create, opts or {})

            if ran and ok then
                setDiagnostics("Using " .. tostring(result.Provider) .. " UI")
                return result
            end

            setDiagnostics(ran and result or ok)
        end

        return nil
    end

    context.UIAdapter = UIAdapter

    return UIAdapter
end
