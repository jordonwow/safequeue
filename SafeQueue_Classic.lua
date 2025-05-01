if WOW_PROJECT_ID == WOW_PROJECT_MAINLINE then return end

local SafeQueue = SafeQueue

local CreateFrame = CreateFrame
local ENTER_BATTLE = ENTER_BATTLE
local GetBattlefieldStatus = GetBattlefieldStatus
local GetMapInfo = C_Map.GetMapInfo
local GetMaxBattlefieldID = GetMaxBattlefieldID
local InCombatLockdown = InCombatLockdown
local PVPReadyDialog = PVPReadyDialog
local PlaySound = PlaySound
local REQUIRES_RELOAD = REQUIRES_RELOAD
local SOUNDKIT = SOUNDKIT
local StaticPopupSpecial_Hide = StaticPopupSpecial_Hide
local StaticPopup_Hide = StaticPopup_Hide
local format = format
local hooksecurefunc = hooksecurefunc
local issecurevariable = issecurevariable

local alteracValleyInfo = GetMapInfo(1459)
local warsongGulchInfo = GetMapInfo(1460)
local arathiBasinInfo = GetMapInfo(1461)

local ALTERAC_VALLEY = alteracValleyInfo and alteracValleyInfo.name or "Alterac Valley"
local WARSONG_GULCH = warsongGulchInfo and warsongGulchInfo.name or "Warsong Gulch"
local ARATHI_BASIN = arathiBasinInfo and arathiBasinInfo.name or "Arathi Basin"

local BATTLEGROUND_COLORS = {
    default = "ffd100",
    [ALTERAC_VALLEY] = "007fff",
    [WARSONG_GULCH] = "00ff00",
    [ARATHI_BASIN] = "ffd100",
}
-- Textures for the battlegrounds
local battlegroundTextures = {
    ["Warsong Gulch"] = "Interface\\AddOns\\SafeQueue\\Media\\Textures\\wsglogo.png",
    ["Alterac Valley"] = "Interface\\AddOns\\SafeQueue\\Media\\Textures\\avlogo.png",
    ["Arathi Basin"] = "Interface\\AddOns\\SafeQueue\\Media\\Textures\\ablogo.png",
}

function SafeQueue:SetBackground(battleground)
    if not self.BattlegroundTexture then
        print("BattlegroundTexture is nil!")
        return
    end

    local texturePath = battlegroundTextures[battleground]
    if texturePath then
        self.BattlegroundTexture:SetTexture(texturePath)
        self.BattlegroundTexture:SetTexCoord(0, 1, 0, 1)
        self.BattlegroundTexture:SetSize(300, 115) -- Match popup template dimensions
        self.BattlegroundTexture:SetDrawLayer("BACKGROUND") -- Ensure texture is rendered below the popup
        self.BattlegroundTexture:SetAlpha(0.7) -- Set alpha 
        self.BattlegroundTexture:Show()
    else
        print("No texture found for:", battleground)
        self.BattlegroundTexture:Hide()
    end
end


if PVPReadyDialog then
    PVPReadyDialog:SetHeight(120)
    -- add a minimize button
    local hideButton = CreateFrame("Button", nil, PVPReadyDialog, "UIPanelCloseButton")
    hideButton:SetNormalTexture("Interface\\Buttons\\UI-Panel-HideButton-Up")
    hideButton:SetPushedTexture("Interface\\Buttons\\UI-Panel-HideButton-Down")
    hideButton:SetPoint("TOPRIGHT", PVPReadyDialog, "TOPRIGHT", -3, -3)
    hideButton:SetScript("OnHide", function() PlaySound(SOUNDKIT.U_CHAT_SCROLL_BUTTON) end)
else
    -- Classic Era
    hooksecurefunc("StaticPopup_Show", function(name, _,_, i)
        if name ~= "CONFIRM_BATTLEFIELD_ENTRY" then return end
        SafeQueue.battlefieldId = i
        SafeQueue:ShowPopup()
    end)
end

SafeQueue:RegisterEvent("ADDON_ACTION_FORBIDDEN")

function SafeQueue:ADDON_ACTION_FORBIDDEN(_, func)
    if (not self:IsVisible()) then return end
    if func == "AcceptBattlefieldPort()" then self.popupTainted = true end
    if func == "func()" then self.minimapTainted = true end
    if (not self.popupTainted) or (not self.minimapTainted) then return end
    StaticPopup_Hide("ADDON_ACTION_FORBIDDEN")
    self:SetMacroText()
end

function SafeQueue:HideBlizzardPopup()
    if PVPReadyDialog then
        StaticPopupSpecial_Hide(PVPReadyDialog)
    else
        StaticPopup_Hide("CONFIRM_BATTLEFIELD_ENTRY")
    end
end

SafeQueue:SetScript("OnShow", function(self)
    if (not self.battlefieldId) then return end
    if InCombatLockdown() then
        self.showPending = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end

    local status, battleground = GetBattlefieldStatus(self.battlefieldId)

    if status ~= "confirm" then return end

    self:HideBlizzardPopup()

    self.showPending = nil
    self.hidePending = nil

    self:SetBackground(battleground) -- Ensure the background is set when the popup is shown
    self:SetExpiresText()
    self.SubText:SetText(format("|cff%s%s|r", self.color, battleground))
    local color = self.color and self.color.rgb
    if color then self.SubText:SetTextColor(color.r, color.g, color.b) end

    self:SetMacroText()
end)

SafeQueue:SetScript("OnHide", function(self)
    self.battleground = nil
    self.battlefieldId = nil
    self.EnterButton:SetAttribute("macrotext", "")
    self.EnterButton:SetText(ENTER_BATTLE)
end)

function SafeQueue:ShowPopup()
    local battlefieldId = self.battlefieldId
    if (not battlefieldId) then return end
    local status, battleground = GetBattlefieldStatus(battlefieldId)
    if status ~= "confirm" then return end

    -- Reset the minimized state when showing the popup
    self.isMinimized = false

    self.battleground = battleground
    self.color = BATTLEGROUND_COLORS[battleground] or BATTLEGROUND_COLORS.default
    self:SetExpiresText()
    if InCombatLockdown() then
        self.showPending = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self:Show()
end

function SafeQueue:HidePopup()
    self:HideBlizzardPopup()
    if InCombatLockdown() then
        self.hidePending = true
        self:RegisterEvent("PLAYER_REGEN_ENABLED")
        return
    end
    self:Hide()
end

function SafeQueue:PLAYER_REGEN_ENABLED()
    self:UnregisterEvent("PLAYER_REGEN_ENABLED")
    if self.hidePending then self:Hide() end
    if self.showPending then self:Show() end
end

local function GetDropDownListEnterButton(battlefieldId)
    local index = -1
    for i = 1, GetMaxBattlefieldID() do
        local status = GetBattlefieldStatus(i)
        if status ~= "none" then index = index + 3 end
        if i == battlefieldId then return "DropDownList1Button" .. index end
    end
end

function SafeQueue:SetMacroText()
    if InCombatLockdown() then return end
    if (not self.battlefieldId) then return end
    if (not issecurevariable("CURRENT_BATTLEFIELD_QUEUES")) then self.popupTainted = true end
    if self.popupTainted and self.minimapTainted then
        self.EnterButton:SetText(REQUIRES_RELOAD)
        self.EnterButton:SetAttribute("macrotext", "/reload")
    else
        local macrotext = "/click PVPReadyDialogEnterBattleButton\n"
        local button = GetDropDownListEnterButton(self.battlefieldId)
        if button then
            macrotext = macrotext .. "/click MiniMapBattlefieldFrame RightButton\n/click " .. button
        end
        self.EnterButton:SetAttribute("macrotext", macrotext)
    end
end

-- Ensure the frame is movable
SafeQueue:SetMovable(true)
SafeQueue:EnableMouse(true)
SafeQueue:RegisterForDrag("LeftButton")
SafeQueue:SetScript("OnDragStart", function(self)
    if InCombatLockdown() then return end -- Prevent dragging during combat
    self:StartMoving()
end)
SafeQueue:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    self:SavePosition() -- Save position when dragging stops
end)

-- Function to save the window's position
function SafeQueue:SavePosition()
    if not SafeQueueDB then SafeQueueDB = {} end
    local point, _, relativePoint, x, y = self:GetPoint()
    SafeQueueDB.position = { point = point, relativePoint = relativePoint, x = x, y = y }
end

-- Function to restore the window's position
function SafeQueue:RestorePosition()
    if SafeQueueDB and SafeQueueDB.position then
        local pos = SafeQueueDB.position
        self:ClearAllPoints()
        self:SetPoint(pos.point, UIParent, pos.relativePoint, pos.x, pos.y)
    else
        -- Default position if no saved position exists
        self:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    end
end

-- Restore position when the addon loads
SafeQueue:RestorePosition()

local LDB = LibStub("LibDataBroker-1.1", true)
local LDBIcon = LibStub("LibDBIcon-1.0", true)

local hideButton = CreateFrame("Button", nil, SafeQueue, "UIPanelCloseButton")
hideButton:SetPoint("TOPRIGHT", SafeQueue, "TOPRIGHT", -3, -3)
hideButton:SetScript("OnClick", function()
    SafeQueue.isMinimized = true -- Set a flag to track the minimized state
    SafeQueue:Hide() -- Hide the popup
end)

