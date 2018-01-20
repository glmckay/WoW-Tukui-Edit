local T, C, L = unpack(Tukui)

local Loading = T.Loading

Loading.OldOnEvent = Loading.OnEvent

function Loading:OnEvent(event, addon)
    self:OldOnEvent(event, addon)
    if (event == "PLAYER_LOGIN") then
        if (C.AuraTimers.Enable) then
            T["AuraTimers"]:Enable()
        end
    end
end

Loading:SetScript("OnEvent", Loading.OnEvent)

-- hooksecurefunc(Loading, "OnEvent", LoadExtraModules)