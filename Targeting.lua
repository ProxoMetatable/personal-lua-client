return function(context)
    local Targeting = {
        current = nil,
    }

    function Targeting.findTarget()
        Targeting.current = nil
        return nil
    end

    function Targeting.update()
        Targeting.current = Targeting.findTarget()
        return Targeting.current
    end

    context.Targeting = Targeting

    return Targeting
end
