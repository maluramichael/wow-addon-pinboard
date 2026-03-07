-- Luacheck configuration for PinBoard
-- WoW Retail (Midnight) addon

std = "lua51"
codes = true
quiet = 1
max_line_length = false

exclude_files = {
    ".release/",
    "libs/",
    "Libs/",
    ".git/",
}

ignore = {
    "212",          -- Unused argument
    "213",          -- Unused loop variable
    "311",          -- Value assigned to variable is unused
    "211/addonName", -- Unused addonName from addon bootstrap
    "432",          -- Shadowing upvalue argument (common in OnEnter/OnLeave callbacks)
}

globals = {
    "_G",
    "PinBoard",
    "PinBoardFrame",
    "StaticPopupDialogs",
}

read_globals = {
    -- Lua standard
    "abs", "ceil", "floor", "max", "min", "mod", "random", "sqrt",
    "format", "gmatch", "gsub", "strbyte", "strfind", "strlen", "strlower",
    "strmatch", "strsub", "strupper", "strsplit", "strjoin", "strtrim",
    "date", "time", "difftime",
    "sort", "tinsert", "tremove", "wipe", "unpack",
    "pairs", "ipairs", "next", "select", "type", "tonumber", "tostring",
    "getmetatable", "setmetatable", "rawget", "rawset",
    "pcall", "xpcall", "error", "assert", "loadstring",
    "print", "debugstack",

    -- Libraries
    "LibStub",

    -- Frame API
    "CreateFrame", "UIParent", "UISpecialFrames", "GameTooltip",
    "GameFontNormal", "GameFontNormalSmall", "GameFontNormalLarge",
    "GameFontHighlight", "GameFontHighlightSmall",
    "GameFontDisableSmall",
    "BackdropTemplateMixin",
    "GameTooltip_SetDefaultAnchor",

    -- Map API
    "C_Map", "C_SuperTrack", "C_Navigation",
    "UiMapPoint",

    -- Unit API
    "UnitName", "UnitLevel", "UnitClass",

    -- Misc API
    "GetTime", "GetRealmName",
    "InCombatLockdown",
    "Settings", "C_Timer", "C_AddOns",
    "PlaySound", "SOUNDKIT",
    "StaticPopup_Show", "StaticPopup_Hide",
    "CloseDropDownMenus", "UIDropDownMenu_CreateInfo",
    "UIDropDownMenu_AddButton", "ToggleDropDownMenu",
    "UIDROPDOWNMENU_MENU_VALUE",

    -- Constants
    "NORMAL_FONT_COLOR", "HIGHLIGHT_FONT_COLOR", "GRAY_FONT_COLOR",
    "RED_FONT_COLOR", "GREEN_FONT_COLOR",
}
