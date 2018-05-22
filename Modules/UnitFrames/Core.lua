local T, C, L = Tukui:unpack()

local Panels = T.Panels
local UnitFrames = T.UnitFrames

local gsub = gsub
local format = format



local borderSize = C.General.BorderSize
UnitFrames.FrameHeight = 32

local ufSpacing = C.General.FrameSpacing
local ufYoffset = -160

-- Empty table for class specific functions
UnitFrames.EditClassFeatures = {}


-- Notes: 1- The Tukui version of ShortValue uses a local "Value" which seems unnecessary
--           I left it out, maybe something weird will happen so I can learn why it was there.
--        2- Conditionals are (hopefully) ordered from most to least likely
function UnitFrames:ShortValue()
    if self < 1e3 then
        return self
    elseif self < 2e4 then
        return gsub(format("%.1fK", self / 1e3), "%.?0+([KMB])$", "%1")
    elseif self < 1e6 then
        return ("%dK"):format(self / 1e3)
    elseif self < 2e7 then
        return gsub(format("%.1fM", self / 1e6), "%.?0+([KMB])$", "%1")
    elseif self < 1e9 then
        return format("%dM", self / 1e6)
    elseif self < 2e10 then
        return gsub(format("%.1fB", self / 1e9), "%.?0+([KMB])$", "%1")
    else
        return format("%dB", self / 1e9)
    end
end


-- Create a macro conditional for Healing specs (cache the string since it won't change)
function UnitFrames:GetHealerConditional()
    if (not self.HealerConditionalString) then
        local NumSpecs = GetNumSpecializations()
        local HealerSpecs = {}
        for spec = 1, NumSpecs do
             if (GetSpecializationRole(spec) == "HEALER") then
                table.insert(HealerSpecs, "spec:"..spec)
            end
        end
        self.HealerConditionalString = string.format("[%s]", table.concat(HealerSpecs, ","))
    end
    return self.HealerConditionalString
end


function UnitFrames:CheckInterrupt(unit)
    if (unit == "vehicle") then
        unit = "player"
    end

    if (self.interrupt and UnitCanAttack("player", unit)) then
        self:SetStatusBarColor(1, 0, 0, 1)
    else
        self:SetStatusBarColor(0.31, 0.45, 0.63, 1)
    end
end


local function CreateUnits(self)
    local Player = self.Units.Player
    local Target = self.Units.Target
    local ToT = self.Units.TargetOfTarget
    local Pet = self.Units.Pet
    local Focus = self.Units.Focus
    local FocusTarget = self.Units.FocusTarget

    Player:ClearAllPoints()
    Player:SetParent(Panels.UnitFrameAnchor)
    Player:Point("LEFT", Panels.UnitFrameAnchor)
    Player:Size(self.PlayerTargetWidth, self.FrameHeight)

    Target:ClearAllPoints()
    Target:Point("RIGHT", Panels.UnitFrameAnchor)
    Target:Size(self.PlayerTargetWidth, self.FrameHeight)

    Pet:ClearAllPoints()
    Pet:SetParent(Panels.UnitFrameAnchor)
    Pet:Point("RIGHT", Panels.UnitFrameAnchor, "LEFT", -ufSpacing, 0)
    Pet:Size(self.PetTotWidth, self.FrameHeight)

    ToT:ClearAllPoints()
    ToT:SetParent(Panels.UnitFrameAnchor)
    ToT:Point("LEFT", Panels.UnitFrameAnchor, "RIGHT", ufSpacing, 0)
    ToT:Size(self.PetTotWidth, self.FrameHeight)

    Focus:ClearAllPoints()
    Focus:Point("TOPRIGHT", UIParent, "CENTER", -415, 300)
    Focus:Size(self.OtherWidth, self.OtherHeight)

    FocusTarget:ClearAllPoints()
    FocusTarget:Point("TOP", Focus, "BOTTOM", 0, -35)
    FocusTarget:Size(self.OtherWidth, self.OtherHeight)

    if (C.UnitFrames.Arena) then
        local Arena = UnitFrames.Units.Arena

        for i = 1, 5 do
            Arena[i]:ClearAllPoints()
            if (i == 1) then
                Arena[i]:Point("TOPLEFT", UIParent, "CENTER", 500, -130)
            else
                Arena[i]:Point("BOTTOM", Arena[i-1], "TOP", 0, 32)
            end
            Arena[i]:Size(self.OtherWidth, self.OtherHeight)
        end
    end

    if (C.UnitFrames.Boss) then
        local Boss = UnitFrames.Units.Boss

        for i = 1, 5 do
            Boss[i]:ClearAllPoints()
            if (i == 1) then
                Boss[i]:Point("TOPLEFT", UIParent, "CENTER", 500, -130)
            else
                Boss[i]:Point("BOTTOM", Boss[i-1], "TOP", 0, 32)
            end
            Boss[i]:Size(self.OtherWidth, self.OtherHeight)
        end
    end

    if (C.Party.Enable) then
        local Party = UnitFrames.Headers.Party

        Party:ClearAllPoints()
        Party:Point("LEFT", UIParent, "LEFT", 30, 35)
    end

    if (C.Raid.Enable) then
        local Raid = UnitFrames.Headers.Raid

        Raid:ClearAllPoints()
        Raid:Point("TOP", Panels.UnitFrameAnchor, "BOTTOM", 0, -50)

        if (C.Raid.ShowPets) then
            local Pets = UnitFrames.Headers.RaidPet

            Pets:ClearAllPoints()
            Pets:Point("TOPRIGHT", Raid, "TOPLEFT", -ufSpacing, 0)
        end
    end
end


function UnitFrames:GetPartyFramesAttributes()
    return
        "TukuiParty",
        nil,
        "custom [spec:3] hide;show",
        "oUF-initialConfigFunction", [[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]],
        "initial-width", self.ListMinWidth,
        "initial-height", self.ListMinHeight,
        "showSolo", C["Party"].ShowSolo,
        "showParty", true,
        "showPlayer", C["Party"].ShowPlayer,
        "showRaid", true,
        "groupFilter", "1,2,3,4,5,6,7,8",
        "groupingOrder", "1,2,3,4,5,6,7,8",
        "groupBy", "GROUP",
        "yOffset", T.Scale(-ufSpacing)
end


function UnitFrames:GetRaidFramesAttributes()
    -- local Properties = C.Party.Enable and "custom [spec:3] show;hide" or "solo,party,raid"
    local Properties = string.format("custom %s show;hide", self:GetHealerConditional())

    return
        "TukuiRaid",
        nil,
        Properties,
        "oUF-initialConfigFunction", [[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]],
        "initial-width", self.GridWidth,
        "initial-height", self.GridMaxHeight,
        "showParty", true,
        "showRaid", true,
        "showPlayer", true,
        "showSolo", C["Raid"].ShowSolo,
        "xoffset", T.Scale(ufSpacing),
        "yOffset", T.Scale(-ufSpacing),
        "point", "LEFT",
        "groupFilter", "1,2,3,4,5,6,7,8",
        "groupingOrder", "1,2,3,4,5,6,7,8",
        "groupBy", C["Raid"].GroupBy.Value,
        "maxColumns", math.ceil(40/C["Raid"].MaxUnitPerColumn),
        "unitsPerColumn", C["Raid"].MaxUnitPerColumn,
        "columnSpacing", T.Scale(ufSpacing),
        "columnAnchorPoint", "TOP"
end


function UnitFrames:GetPetRaidFramesAttributes()
    local Properties = C.Party.Enable and "custom [@raid6,exists] show;hide" or "custom [@raid26,exists] hide;show"

    return
        "TukuiRaidPet",
        "SecureGroupPetHeaderTemplate",
        Properties,
        "showParty", false,
        "showRaid", C["Raid"].ShowPets,
        "showSolo", false, -- testing
        "maxColumns", math.ceil(40 / 5),
        "point", "TOP",
        "unitsPerColumn", C["Raid"].MaxUnitPerColumn,
        "columnSpacing", T.Scale(ufSpacing),
        "columnAnchorPoint", "RIGHT",
        "xOffset", T.Scale(ufSpacing),
        "yOffset", T.Scale(-ufSpacing),
        "initial-width", self.GridWidth,
        "initial-height", self.GridMaxHeight,
        "oUF-initialConfigFunction", [[
            local header = self:GetParent()
            self:SetWidth(header:GetAttribute("initial-width"))
            self:SetHeight(header:GetAttribute("initial-height"))
        ]]
end


-- Skin Auras
local function PostCreateAura(self, button)
    button:HideInsets()
    button.cd:SetInside()
    button.icon:SetInside()
end


function UnitFrames:UpdateDebuffsHeaderPosition()
    local NumBuffs = self.visibleBuffs
    local PerRow = self.numRow
    local Size = self.size
    local Row = math.ceil((NumBuffs / PerRow))
    local Parent = self:GetParent()
    local Debuffs = Parent.Debuffs
    local Y = Size * Row
    local Offset = 3

    if NumBuffs == 0 then
        Offset = 14
    end

    Debuffs:ClearAllPoints()
    Debuffs:SetPoint("BOTTOMLEFT", self, "BOTTOMLEFT", 0, Y + Offset)
end


function UnitFrames:Highlight()
    if UnitIsUnit("focus", self.unit) then
        self.Highlight:SetBackdropBorderColor(218 / 255, 197 / 255, 92 / 255, .7)
        self.Highlight:Show()
    elseif UnitIsUnit("target", self.unit) then
        self.Highlight:SetBackdropBorderColor(100 / 255, 100 / 255, 100 / 255, 1)
        self.Highlight:Show()
    else
        self.Highlight:Hide()
    end
end


-- All the stuff that needs to be changed with spec and does not need a protected environment
-- This might end up getting moved somewhere else since it's not strictly unitframe stuff
local PrevSpec = 0
function UnitFrames:AdjustForSpec()
    local NewSpec = GetSpecialization()
    if (NewSpec == PrevSpec) then return end

    local SpecName = select(2, GetSpecializationInfo(NewSpec))
    local SpecRole = GetSpecializationRole(NewSpec)
    local IsRanged = (SpecRole == "HEALER"  or
                     T.MyClass == "MAGE"    or
                     T.MyClass == "WARLOCK" or
                     T.MyClass == "PRIEST"  or
                    (T.MyClass == "DRUID"  and SpecName == "Balance")  or
                    (T.MyClass == "HUNTER" and SpecName ~= "Survival") or
                    (T.MyClass == "SHAMAN" and SpecName == "Elemental"))

    self:SetPlayerProfile(SpecRole, IsRanged)

    if (SpecRole == "HEALER") then
        Panels.CenterActionBars[2]:Hide()
    else
        Panels.CenterActionBars[2]:Show()
    end

    if (self.ClassSpecChanges) then
        self:ClassSpecChanges(NewSpec)
    end

    PrevSpec = NewSpec
end


-- All the raid size adjustments than don't require a protected environment
local prevNumGroups = -1
function UnitFrames:AdjustRaidSize()
    local numGroups = math.max(1, math.ceil(GetNumGroupMembers() / 5))

    if (numGroups == prevNumGroups) then return end

    -- For list frames
    local h = self.ListMinHeight + self.ListHeightIncr*(8 - numGroups)
    local w = self.ListMinWidth + self.ListWidthIncr*(8 - numGroups)

    local frames = { self.Headers.Party:GetChildren() }
    for _,frame in ipairs(frames) do
        frame:UpdateForSize(w, h, numGroups == 1)
    end

    -- For grid frames
    h = math.min(self.GridMaxHeight, math.floor(self.GridTotalHeight / numGroups))

    local frames = { self.Headers.Raid:GetChildren() }
    for _,frame in ipairs(frames) do
        frame:UpdateForSize(w, h)
    end

    prevNumGroups = numGroups
end


function UnitFrames:EnableEdits()
    local SecureRaidAdjuster = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")

    SecureRaidAdjuster:SetFrameRef("ListHeader", self.Headers.Party)
    SecureRaidAdjuster:SetFrameRef("GridHeader", self.Headers.Raid)

    SecureRaidAdjuster:SetAttribute("_onstate-groups", string.format([[
        -- Note: Arguments are self, stateid, newstate
        local numGroups = newstate

        local h = %d + %d*(8 - numGroups)
        local w = %d + %d*(8 - numGroups)

        local header = self:GetFrameRef("ListHeader")
        header:SetAttribute("initial-width", w)
        header:SetAttribute("initial-height", h)
        local frames = newtable(header:GetChildren())
        for _,frame in ipairs(frames) do
            frame:SetWidth(w)
            frame:SetHeight(h)
        end

        h = math.min(%d, math.floor(%d / numGroups))
        header = self:GetFrameRef("GridHeader")
        header:SetAttribute("initial-height", h)
        frames = newtable(header:GetChildren())
        for _,frame in ipairs(frames) do
            frame:SetHeight(h)
        end
        ]], self.ListMinHeight, self.ListHeightIncr, self.ListMinWidth, self.ListWidthIncr,
            self.GridMaxHeight, self.GridTotalHeight))

    RegisterStateDriver(SecureRaidAdjuster, "groups", "[@raid36,exists] 8;[@raid31,exists] 7;[@raid26,exists] 6;[@raid21,exists] 5;[@raid16,exists] 4;[@raid11,exists] 3;[@raid6,exists] 2; 1")

    local SecureSpecAdjuster = CreateFrame("Frame", nil, UIParent, "SecureHandlerStateTemplate")
    SecureSpecAdjuster:SetFrameRef("ufAnchor", Panels.UnitFrameAnchor)
    SecureSpecAdjuster:SetAttribute("_onstate-role", [[
        -- Note: Arguments are self, stateid, newstate
        local ufAnchor = self:GetFrameRef("ufAnchor")
        if (newstate == "heal") then
            ufAnchor:SetPoint("TOP", UIParent, "CENTER", 0, -160)
        elseif (newstate == "dpstank") then
            ufAnchor:SetPoint("TOP", UIParent, "CENTER", 0, -(160 + ufAnchor:GetHeight()))
        end
        ]])

    RegisterStateDriver(SecureSpecAdjuster, "role", string.format("%s heal; dpstank", self:GetHealerConditional()))

    local UnitFrameAdjuster = CreateFrame("Frame", nil, UIParent)
    UnitFrameAdjuster.CurrentSpec = 0


    UnitFrameAdjuster:SetScript("OnEvent", function(self, event)
        if (event == "GROUP_ROSTER_UPDATE") then
            UnitFrames:AdjustRaidSize()
        else -- event == ACTIVE_TALENT_GROUP_CHANGED
            UnitFrames:AdjustForSpec()
        end
    end)
    UnitFrameAdjuster:RegisterEvent("ACTIVE_TALENT_GROUP_CHANGED")
    UnitFrameAdjuster:RegisterEvent("GROUP_ROSTER_UPDATE")

    self:AdjustForSpec()
    self:AdjustRaidSize()

    self.SecureRaidAdjuster = SecureRaidAdjuster
    self.SecureSpecAdjuster = SecureSpecAdjuster
    self.UnitFrameAdjuster = UnitFrameAdjuster
end



hooksecurefunc(UnitFrames, "CreateUnits", CreateUnits)
hooksecurefunc(UnitFrames, "PostCreateAura", PostCreateAura)
hooksecurefunc(UnitFrames, "Enable", UnitFrames.EnableEdits)


