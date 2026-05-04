return function(context)
    local Binds = {}

    local aliases = {
        LMB = "MouseButton1",
        M1 = "MouseButton1",
        LeftClick = "MouseButton1",
        LeftMouse = "MouseButton1",
        RMB = "MouseButton2",
        M2 = "MouseButton2",
        RightClick = "MouseButton2",
        RightMouse = "MouseButton2",
        MMB = "MouseButton3",
        M3 = "MouseButton3",
        MiddleClick = "MouseButton3",
        MiddleMouse = "MouseButton3"
    }

    local friendly = {
        MouseButton1 = "LeftClick",
        MouseButton2 = "RightClick",
        MouseButton3 = "MiddleClick"
    }

    local function enumTypeName(value)
        local ok, result = pcall(function()
            return tostring(value.EnumType)
        end)

        if ok then
            return result
        end

        return nil
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
            local name = aliases[value] or value

            if Enum.UserInputType[name] then
                return {
                    Type = "UserInputType",
                    Name = name
                }
            end

            if Enum.KeyCode[name] then
                return {
                    Type = "KeyCode",
                    Name = name
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
