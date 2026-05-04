return function(context)
    local Binds = {}

    local aliases = {
        lmb = "MouseButton1",
        m1 = "MouseButton1",
        leftclick = "MouseButton1",
        leftmouse = "MouseButton1",
        rmb = "MouseButton2",
        m2 = "MouseButton2",
        rightclick = "MouseButton2",
        rightmouse = "MouseButton2",
        mmb = "MouseButton3",
        m3 = "MouseButton3",
        middleclick = "MouseButton3",
        middlemouse = "MouseButton3"
    }

    local friendly = {
        MouseButton1 = "LeftClick",
        MouseButton2 = "RightClick",
        MouseButton3 = "MiddleClick"
    }

    local keyCodes = {}
    local inputTypes = {}

    for _, item in ipairs(Enum.KeyCode:GetEnumItems()) do
        keyCodes[item.Name:lower()] = item
    end

    for _, item in ipairs(Enum.UserInputType:GetEnumItems()) do
        inputTypes[item.Name:lower()] = item
    end

    local function enumTypeName(value)
        local ok, result = pcall(function()
            return tostring(value.EnumType)
        end)

        if ok then
            return result
        end

        return nil
    end

    local function compact(value)
        return tostring(value):gsub("%s+", "")
    end

    function Binds.from(value)
        if typeof(value) == "EnumItem" then
            local enumType = enumTypeName(value)

            if enumType == "Enum.KeyCode" then
                return {
                    Type = "KeyCode",
                    Name = value.Name
                }
            end

            if enumType == "Enum.UserInputType" then
                return {
                    Type = "UserInputType",
                    Name = value.Name
                }
            end
        end

        if type(value) == "table" and value.Type and value.Name then
            return {
                Type = value.Type,
                Name = value.Name
            }
        end

        if type(value) == "string" then
            local raw = compact(value)
            local lowered = raw:lower()
            local name = aliases[lowered] or raw
            local lookup = name:lower()
            local inputType = inputTypes[lookup]
            local keyCode = keyCodes[lookup]

            if inputType then
                return {
                    Type = "UserInputType",
                    Name = inputType.Name
                }
            end

            if keyCode then
                return {
                    Type = "KeyCode",
                    Name = keyCode.Name
                }
            end
        end

        return nil
    end

    function Binds.name(value)
        local bind = Binds.from(value)

        if not bind then
            return "Unbound"
        end

        return friendly[bind.Name] or bind.Name
    end

    function Binds.matches(input, value)
        local bind = Binds.from(value)

        if not bind then
            return false
        end

        if bind.Type == "KeyCode" then
            return input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode.Name == bind.Name
        end

        if bind.Type == "UserInputType" then
            return input.UserInputType.Name == bind.Name
        end

        return false
    end

    function Binds.fromInput(input)
        if input.UserInputType == Enum.UserInputType.Keyboard and input.KeyCode ~= Enum.KeyCode.Unknown then
            return Binds.from(input.KeyCode)
        end

        if input.UserInputType == Enum.UserInputType.MouseButton1 or input.UserInputType == Enum.UserInputType.MouseButton2 or input.UserInputType == Enum.UserInputType.MouseButton3 then
            return Binds.from(input.UserInputType)
        end

        return nil
    end

    function Binds.set(target, key, value)
        local bind = Binds.from(value)

        if bind then
            target[key] = bind
            return bind
        end

        return nil
    end

    context.Binds = Binds

    return Binds
end
