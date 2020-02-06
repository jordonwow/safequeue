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
    "_G",
    "DEFAULT_CHAT_FRAME",
    "WOW_PROJECT_ID",
    "WOW_PROJECT_CLASSIC",
    "TOOLTIP_UPDATE_TIME",
    "ENTER_BATTLE",
    "PLAYER",
    "GetBattlefieldStatus",
    "GetMaxBattlefieldID",
    "InCombatLockdown",
    "UnitInBattleground",
    "MiniMapBattlefieldDropDown",
    "GetBattlefieldPortExpiration",
    "GetTime",
    "GetBattlefieldTimeWaited",
    "CreateFrame",
    "hooksecurefunc",
    "SecondsToTime",
    "StaticPopup_Hide",
    "SafeQueue_FindPopup",
    "SafeQueue_Hide",
    "SafeQueue_Show",
    "SafeQueue_OnShow",
    "SafeQueue_UpdateTimer",
    "SafeQueue_OnUpdate",
    "SafeQueue_PreClick",
    "SafeQueue_PostClick",
}
