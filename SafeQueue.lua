
-- SafeQueue by Jordon

local addonName, addon = ...

local C_Map = C_Map
local CreateFrame = CreateFrame
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local ENTER_BATTLE = ENTER_BATTLE
local GetBattlefieldPortExpiration = GetBattlefieldPortExpiration
local GetBattlefieldStatus = GetBattlefieldStatus
local GetBattlefieldTimeWaited = GetBattlefieldTimeWaited
local GetMaxBattlefieldID = GetMaxBattlefieldID
local GetTime = GetTime
local InCombatLockdown = InCombatLockdown
local MiniMapBattlefieldDropDown = MiniMapBattlefieldDropDown
local PLAYER = PLAYER
local PVPReadyDialog = PVPReadyDialog
local SecondsToTime = SecondsToTime
local StaticPopup_Visible = StaticPopup_Visible
local UnitInBattleground = UnitInBattleground
local hooksecurefunc = hooksecurefunc

local SafeQueue = CreateFrame("Frame", "SafeQueue")
SafeQueue:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
SafeQueue:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")

local EXPIRES_FORMAT = (WOW_PROJECT_ID == WOW_PROJECT_MAINLINE and "Expires in " or "SafeQueue expires in ") ..
    "|cf%s%s|r"
local ANNOUNCE_FORMAT = "Queue popped %s"

local function GetTimerText(battlefieldId)
    if (not battlefieldId) then return end
    local secs = GetBattlefieldPortExpiration(battlefieldId)
    if secs <= 0 then secs = 1 end
    local color
    if secs > 20 then
        color = "f20ff20"
    elseif secs > 10 then
        color = "fffff00"
    else
        color = "fff0000"
    end
    return EXPIRES_FORMAT:format(color, SecondsToTime(secs))
end

if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
    SafeQueue:SetScript("OnUpdate", function()
        if PVPReadyDialog:IsShown() and PVPReadyDialog.activeIndex then
            PVPReadyDialog.label:SetText(GetTimerText(PVPReadyDialog.activeIndex))
        end
    end)

    hooksecurefunc("PVPReadyDialog_Display", function(self)
        self.leaveButton:Hide()
        self.enterButton:ClearAllPoints();
        self.enterButton:SetPoint("BOTTOM", self, "BOTTOM", 0, 25)
    end)
else
    local SAFEQUEUE_NUMPOPUPS = 3
    local ALTERAC_VALLEY = C_Map.GetMapInfo(1459).name
    local WARSONG_GULCH = C_Map.GetMapInfo(1460).name
    local ARATHI_BASIN = C_Map.GetMapInfo(1461).name
    local COLORS = {
        [ALTERAC_VALLEY] = { r = 0, g = 0.5, b = 1 },
        [WARSONG_GULCH] = { r = 0, g = 1, b = 0 },
        [ARATHI_BASIN] = { r = 1, g = 0.82, b = 0 },
    }
    SafeQueue:RegisterEvent("PLAYER_REGEN_ENABLED")
    SafeQueue.createQueue = {}

    function SafeQueue_OnShow(self)
        self.text:SetText(GetTimerText(self.battlefieldId))
        self.SubText:SetText(self.battleground)
        local color = COLORS[self.battleground]
        if color then self.SubText:SetTextColor(color.r, color.g, color.b) end
    end

    function SafeQueue:Create(battlefieldId)
        local status, battleground = GetBattlefieldStatus(battlefieldId)
        if status ~= "confirm" then return end
        if InCombatLockdown() then
            self.createQueue[battlefieldId] = true
            return
        end
        for i = 1, SAFEQUEUE_NUMPOPUPS do
            local popup = _G["SafeQueuePopup" .. i]
            if (not popup:IsVisible()) then
                if StaticPopup_Visible("CONFIRM_BATTLEFIELD_ENTRY") then
                    StaticPopup_Hide("CONFIRM_BATTLEFIELD_ENTRY")
                end
                popup.battleground = battleground
                popup.battlefieldId = battlefieldId
                popup:Show()
                break
            end
        end
    end

    function SafeQueue_FindPopup(battlefieldId)
        for i = 1, SAFEQUEUE_NUMPOPUPS do
            local popup = _G["SafeQueuePopup" .. i]
            if popup:IsVisible() and popup.battlefieldId == battlefieldId then
                return popup
            end
        end
    end

    function SafeQueue:PLAYER_REGEN_ENABLED()
        for battlefieldId, _ in pairs(self.createQueue) do
            self.createQueue[battlefieldId] = nil
            if (not SafeQueue_FindPopup(battlefieldId)) then self:Create(battlefieldId) end
        end
    end

    function SafeQueue_OnUpdate(self, elapsed)
        if (not self:IsVisible()) then return end
        local timer = self.timer
        timer = timer - elapsed
        if timer <= 0 then
            if (not self.battlefieldId) or GetBattlefieldStatus(self.battlefieldId) ~= "confirm" then
                self:Hide()
                return
            end
            self.text:SetText(GetTimerText(self.battlefieldId))
        end
        self.timer = timer
    end

    local function GetButtonNameById(id)
        local n
        if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then
            n = id * 2
        else
            n = (id * 3) - 1
        end
        return "DropDownList1Button" .. n
    end

    function SafeQueue_PreClick(self)
        if InCombatLockdown() then return end
        self:SetAttribute("macrotext", "")
        if UnitInBattleground(PLAYER) then return end
        local id = self:GetParent().battlefieldId
        if (not id) then return end
        local button = "DropDownList1Button" .. GetButtonNameById(id)
        self:SetAttribute("macrotext", "/click MiniMapBattlefieldFrame RightButton\n/click " .. GetButtonNameById(id))
    end

    hooksecurefunc("StaticPopup_Show", function(name)
        if name == "CONFIRM_BATTLEFIELD_ENTRY" and (not InCombatLockdown()) then
            StaticPopup_Hide(name)
        end
    end)
end

SafeQueue.queues = {}

function SafeQueue:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SafeQueue|r: " .. message)
end

function SafeQueue:UPDATE_BATTLEFIELD_STATUS()
    for i = 1, GetMaxBattlefieldID() do
        local popup = SafeQueue_FindPopup and SafeQueue_FindPopup(i)
        local status = GetBattlefieldStatus(i)
        if status == "confirm" then
            if self.queues[i] then
                local secs = GetTime() - self.queues[i]
                local message
                if secs <= 0 then
                    message = "instantly!"
                else
                    message = "after " .. SecondsToTime(secs)
                end
                self:Print(ANNOUNCE_FORMAT:format(message))
                self.queues[i] = nil
            end
            if (not popup) and self.Create then
                self:Create(i)
            end
        else
            if status == "queued" then
                self.queues[i] = self.queues[i] or GetTime() - (GetBattlefieldTimeWaited(i) / 1000)
            end
            if popup then
               popup:Hide()
            end
        end
    end
end
