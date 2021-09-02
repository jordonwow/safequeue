
-- SafeQueue by Jordon

local addonName, addon = ...

-- Classic Era isn't updated yet
if (not PVPReadyDialog) then return end

local CreateFrame = CreateFrame
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GetBattlefieldPortExpiration = GetBattlefieldPortExpiration
local GetBattlefieldStatus = GetBattlefieldStatus
local GetBattlefieldTimeWaited = GetBattlefieldTimeWaited
local GetMapInfo = C_Map.GetMapInfo
local GetMaxBattlefieldID = GetMaxBattlefieldID
local GetTime = GetTime
local PVPReadyDialog = PVPReadyDialog
local PlaySound = PlaySound
local SOUNDKIT = SOUNDKIT
local SecondsToTime = SecondsToTime
local TOOLTIP_UPDATE_TIME = TOOLTIP_UPDATE_TIME
local hooksecurefunc = hooksecurefunc

local SafeQueue = CreateFrame("Frame", "SafeQueue")
SafeQueue:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
SafeQueue:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
SafeQueue:RegisterEvent("ADDON_LOADED")

local EXPIRES_FORMAT_RETAIL = "Expires in |cf%s%s|r"
local EXPIRES_FORMAT_CLASSIC = "\nSafeQueue expires in |cff%s%s|r\n\n|cff%s%s|r"
local ANNOUNCE_FORMAT = "Queue popped %s"

local ALTERAC_VALLEY = GetMapInfo(1459) and GetMapInfo(1459).name or "Alterac Valley"
local WARSONG_GULCH = GetMapInfo(1460) and GetMapInfo(1460).name or "Warsong Gulch"
local ARATHI_BASIN = GetMapInfo(1461) and GetMapInfo(1461).name or "Arathi Basin"

local COLORS = {
    default = "ffd100",
    [ALTERAC_VALLEY] = "007fff",
    [WARSONG_GULCH] = "00ff00",
    [ARATHI_BASIN] = "ffd100",
}

function SafeQueue:ADDON_LOADED(name)
    if name == addonName then
        self:UnregisterEvent("ADDON_LOADED")
        self.queues = {}
        self.timer = TOOLTIP_UPDATE_TIME
        self.retail = PVPReadyDialog.label
        self.format = self.retail and EXPIRES_FORMAT_RETAIL or EXPIRES_FORMAT_CLASSIC
        if (not self.retail) then
            PVPReadyDialog:SetHeight(120)

            -- add a minimize button
            local hideButton = CreateFrame("Button", nil, PVPReadyDialog, "UIPanelCloseButton")
            hideButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-HideButton-Up")
            hideButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-HideButton-Down")
            hideButton:SetPoint("TOPRIGHT", PVPReadyDialog, "TOPRIGHT", -3, -3)
            hideButton:SetScript("OnHide", function() PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end)
        end
    end
end

local function GetBattlefieldColor(mapName)
    return COLORS[mapName] or COLORS.default
end

function SafeQueue:SetText(battlefieldId)
    if (not battlefieldId) then return end
    local secs = GetBattlefieldPortExpiration(battlefieldId)
    if secs <= 0 then secs = 1 end
    local color
    if secs > 20 then
        color = "20ff20"
    elseif secs > 10 then
        color = "ffff00"
    else
        color = "ff0000"
    end
    if self.retail then
        PVPReadyDialog.label:SetText(EXPIRES_FORMAT_RETAIL:format(color, SecondsToTime(secs)))
    else
        local _, mapName = GetBattlefieldStatus(battlefieldId)
        PVPReadyDialog.text:SetText(EXPIRES_FORMAT_CLASSIC:format(
            color, SecondsToTime(secs),
            GetBattlefieldColor(mapName), mapName
        ))
    end
end

hooksecurefunc("PVPReadyDialog_Display", function(self, i)
    self = self or PVPReadyDialog
    if self.leaveButton then self.leaveButton:Hide() end
    if self.hideButton then self.hideButton:Hide() end
    self.enterButton:ClearAllPoints();
    self.enterButton:SetPoint("BOTTOM", self, "BOTTOM", 0, 25)
    SafeQueue:SetText(i)
end)

SafeQueue:SetScript("OnUpdate", function(self, elapsed)
    local battlefieldId = PVPReadyDialog.activeIndex
    if (not PVPReadyDialog:IsShown()) or (not battlefieldId) then return end
    local timer = self.timer
    timer = timer - elapsed
    if timer <= 0 then self:SetText(battlefieldId) end
    self.timer = timer
end)

function SafeQueue:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SafeQueue|r: " .. message)
end

function SafeQueue:UPDATE_BATTLEFIELD_STATUS()
    for i = 1, GetMaxBattlefieldID() do
        local status, mapName = GetBattlefieldStatus(i)
        if status == "confirm" then
            if self.queues[mapName] then
                local secs = GetTime() - self.queues[mapName]
                local message
                if secs < 1 then
                    message = "instantly!"
                else
                    message = "after " .. SecondsToTime(secs)
                end
                self:Print(ANNOUNCE_FORMAT:format(message))
                self.queues[mapName] = nil
            end
        else
            if mapName and status == "queued" then
                self.queues[mapName] = self.queues[mapName] or GetTime() - (GetBattlefieldTimeWaited(i) / 1000)
            end
            PVPReadyDialog:Hide()
        end
    end
end
