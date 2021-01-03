std = "lua51"
max_line_length = false
exclude_files = {
    ".luacheckrc",
}
ignore = {
    "11./SLASH_.*", -- Setting an undefined (Slash handler) global variable
    "11./BINDING_.*", -- Setting an undefined (Keybinding header) global variable
    "113/LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
    "113/NUM_LE_.*", -- Accessing an undefined (Lua ENUM type) global variable
    "211", -- Unused local variable
    "211/L", -- Unused local variable "CL"
    "211/CL", -- Unused local variable "CL"
    "212", -- Unused argument
    "213", -- Unused loop variable
    -- "231", -- Set but never accessed
    "311", -- Value assigned to a local variable is unused
    "314", -- Value of a field in a table literal is unused
    "42.", -- Shadowing a local variable, an argument, a loop variable.
    "43.", -- Shadowing an upvalue, an upvalue argument, an upvalue loop variable.
    "542", -- An empty if branch
}

globals = {
    "C_Map",
    "CreateFrame",
    "DEFAULT_CHAT_FRAME",
    "ENTER_BATTLE",
    "GetBattlefieldPortExpiration",
    "GetBattlefieldStatus",
    "GetBattlefieldTimeWaited",
    "GetMaxBattlefieldID",
    "GetTime",
    "InCombatLockdown",
    "MiniMapBattlefieldDropDown",
    "PLAYER",
    "PVPReadyDialog",
    "SafeQueue_FindPopup",
    "SafeQueue_Hide",
    "SafeQueue_OnShow",
    "SafeQueue_OnUpdate",
    "SafeQueue_PostClick",
    "SafeQueue_PreClick",
    "SafeQueue_Show",
    "SafeQueue_UpdateTimer",
    "SecondsToTime",
    "StaticPopup_Hide",
    "StaticPopup_Visible",
    "UnitInBattleground",
    "WOW_PROJECT_CLASSIC",
    "WOW_PROJECT_ID",
    "_G",
    "hooksecurefunc",
}
