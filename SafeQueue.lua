if WOW_PROJECT_ID ~= WOW_PROJECT_CLASSIC then return end

local addonName, addon = ...

local SAFEQUEUE_NUMPOPUPS = 3
local TOOLTIP_UPDATE_TIME = TOOLTIP_UPDATE_TIME
local EXPIRES_FORMAT = "SafeQueue expires in |cf%s%s|r"
local ANNOUNCE_FORMAT = "Queue popped %s"
local ENTER_BATTLE = ENTER_BATTLE
local PLAYER = PLAYER
local GetBattlefieldStatus = GetBattlefieldStatus
local GetBattlefieldPortExpiration = GetBattlefieldPortExpiration
local GetMaxBattlefieldID = GetMaxBattlefieldID
local InCombatLockdown = InCombatLockdown
local UnitInBattleground = UnitInBattleground
local MiniMapBattlefieldDropDown = MiniMapBattlefieldDropDown
local CreateFrame = CreateFrame
local SecondsToTime = SecondsToTime
local hooksecurefunc = hooksecurefunc
local DEFAULT_CHAT_FRAME = DEFAULT_CHAT_FRAME
local GetTime = GetTime
local GetBattlefieldTimeWaited = GetBattlefieldTimeWaited

local SafeQueue = CreateFrame("Frame", "SafeQueue")
SafeQueue:SetScript("OnEvent", function(self, event, ...) self[event](self, ...) end)
SafeQueue:RegisterEvent("UPDATE_BATTLEFIELD_STATUS")
SafeQueue.buttons = {}
SafeQueue.queues = {}

function SafeQueue:Print(message)
    DEFAULT_CHAT_FRAME:AddMessage("|cff33ff99SafeQueue|r: " .. message)
end

function SafeQueue:UPDATE_BATTLEFIELD_STATUS()
    for i = 1, GetMaxBattlefieldID() do
        local popup = SafeQueue_FindPopup(i)
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
            if (not popup) then
                SafeQueue_Show(i)
            end
        else
            if status == "queued" then
                self.queues[i] = self.queues[i] or GetTime() - (GetBattlefieldTimeWaited(i) / 1000)
            end
            if popup then
                SafeQueue_Hide(popup)
            end
        end
    end
end

function SafeQueue:RefreshDropdown()
    for i = 1, 10 do
        local button = _G["DropDownList1Button" .. i]
        if (not button) then break end
        if button:GetText() == ENTER_BATTLE then
            local battleground = _G["DropDownList1Button" .. i - 1]:GetText()
            SafeQueue.buttons[battleground] = button
        end
    end
end

function SafeQueue_Hide(self)
    SafeQueue.buttons[self.battleground] = nil
    self.battleground = nil
    self.battlegroundId = nil
    self:Hide()
end

function SafeQueue_Show(battlegroundId)
    local _, battleground = GetBattlefieldStatus(battlegroundId)
    for i = 1, SAFEQUEUE_NUMPOPUPS do
        local popup = _G["SafeQueuePopup" .. i]
        if (not popup:IsVisible()) then
            popup.battleground = battleground
            popup.battlegroundId = battlegroundId
            popup:Show()
            break
        end
    end
end

function SafeQueue_OnShow(self)
    SafeQueue_UpdateTimer(self)
    self.SubText:SetText(self.battleground)
end

function SafeQueue_FindPopup(battlegroundId)
    for i = 1, SAFEQUEUE_NUMPOPUPS do
        local popup = _G["SafeQueuePopup" .. i]
        if popup:IsVisible() and popup.battlegroundId == battlegroundId then
            return popup
        end
    end
end

function SafeQueue_UpdateTimer(self)
    local secs = GetBattlefieldPortExpiration(self.battlegroundId)
    if secs <= 0 then secs = 1 end
    local color
    if secs > 20 then
        color = "f20ff20"
    elseif secs > 10 then
        color = "fffff00"
    else
        color = "fff0000"
    end
    self.text:SetText(EXPIRES_FORMAT:format(color, SecondsToTime(secs)))
end

function SafeQueue_OnUpdate(self, elapsed)
    if (not self:IsVisible()) then return end
    local timer = self.timer
    timer = timer - elapsed
    if timer <= 0 then
        if (not self.battlegroundId) or GetBattlefieldStatus(self.battlegroundId) ~= "confirm" then
            SafeQueue_Hide(self)
            return
        end
        SafeQueue_UpdateTimer(self)
    end
    self.timer = timer
end

function SafeQueue_PreClick(self)
    SafeQueue:RefreshDropdown()

    if InCombatLockdown() then return end

    self:SetAttribute("macrotext", "")

    if UnitInBattleground(PLAYER) then return end

    local button = SafeQueue.buttons[self:GetParent().battleground]

    if (not button) then
        self:SetAttribute("macrotext", "/click MiniMapBattlefieldFrame RightButton\n" ..
            "/click MiniMapBattlefieldFrame RightButton"
        )
        return
    end

    self:SetAttribute("macrotext", "/click " .. button:GetName())
end

hooksecurefunc("ToggleDropDownMenu", function(_, _, dropDownFrame)
    if dropDownFrame == MiniMapBattlefieldDropDown then
        SafeQueue:RefreshDropdown()
    end
end)

hooksecurefunc("StaticPopup_Show", function(name)
    if name == "CONFIRM_BATTLEFIELD_ENTRY" then
        StaticPopup_Hide(name)
    end
end)
