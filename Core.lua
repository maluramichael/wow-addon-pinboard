local addonName, addon = ...
local PinBoard = LibStub("AceAddon-3.0"):NewAddon(addon, addonName,
    "AceEvent-3.0", "AceConsole-3.0")
_G["PinBoard"] = PinBoard

PinBoard.version = C_AddOns.GetAddOnMetadata(addonName, "Version") or "1.0.0"

-------------------------------------------------------------------------------
-- Constants
-------------------------------------------------------------------------------
local DEFAULT_CATEGORY = "General"

local defaults = {
    profile = {
        minimap = { hide = false },
        waypoints = {},
        categories = { DEFAULT_CATEGORY, "Dailies", "Farming", "Rares" },
        collapsed = {},
        sortMode = "category",
        autoTrack = true,
        confirmDelete = true,
        nextID = 1,
    },
}

-------------------------------------------------------------------------------
-- Zone Lookup (built once, maps zone name -> mapID)
-------------------------------------------------------------------------------
local zoneLookup = {}
local zoneLookupReady = false

local function BuildZoneLookup()
    if zoneLookupReady then return end

    -- BFS traversal from Cosmic map
    local queue = { 946 }
    local visited = {}
    while #queue > 0 do
        local mapID = tremove(queue, 1)
        if not visited[mapID] then
            visited[mapID] = true
            local info = C_Map.GetMapInfo(mapID)
            if info and info.name and info.name ~= "" then
                local key = strlower(info.name)
                if not zoneLookup[key] then
                    zoneLookup[key] = mapID
                end
            end
            local children = C_Map.GetMapChildrenInfo(mapID)
            if children then
                for _, child in ipairs(children) do
                    if not visited[child.mapID] then
                        tinsert(queue, child.mapID)
                    end
                end
            end
        end
    end

    zoneLookupReady = true
end

function PinBoard:GetMapIDForZone(zoneName)
    BuildZoneLookup()
    return zoneLookup[strlower(strtrim(zoneName))]
end

function PinBoard:GetZoneName(mapID)
    if not mapID then return "Unknown" end
    local info = C_Map.GetMapInfo(mapID)
    return info and info.name or "Unknown"
end

function PinBoard:GetPlayerLocation()
    local mapID = C_Map.GetBestMapForUnit("player")
    if not mapID then return nil end

    local pos = C_Map.GetPlayerMapPosition(mapID, "player")
    if not pos then return nil end

    local x, y = pos:GetXY()
    return mapID, x, y
end

-------------------------------------------------------------------------------
-- /way Parsing
-------------------------------------------------------------------------------
function PinBoard:ParseWayCommand(input)
    input = strtrim(input)

    -- Remove leading /way
    input = input:gsub("^/way%s+", "")

    -- Try: #mapID x y description
    local mapID, x, y, desc = input:match("^#(%d+)%s+([%d%.]+)[,%s]+([%d%.]+)%s*(.*)")
    if mapID then
        return tonumber(mapID), tonumber(x) / 100, tonumber(y) / 100, strtrim(desc)
    end

    -- Try: x y description (no zone — use current zone)
    x, y, desc = input:match("^([%d%.]+)[,%s]+([%d%.]+)%s*(.*)")
    if x then
        local currentMapID = C_Map.GetBestMapForUnit("player")
        return currentMapID, tonumber(x) / 100, tonumber(y) / 100, strtrim(desc)
    end

    -- Try: ZoneName x y description
    local zone, rest = input:match("^(.-)%s+([%d%.]+.*)$")
    if zone and rest then
        x, y, desc = rest:match("^([%d%.]+)[,%s]+([%d%.]+)%s*(.*)")
        if x then
            local zoneMapID = self:GetMapIDForZone(zone)
            if zoneMapID then
                return zoneMapID, tonumber(x) / 100, tonumber(y) / 100, strtrim(desc)
            end
        end
    end

    return nil
end

function PinBoard:ImportWayCommands(text, category)
    category = category or DEFAULT_CATEGORY
    local count = 0

    for line in text:gmatch("[^\r\n]+") do
        line = strtrim(line)
        if line ~= "" then
            local mapID, x, y, desc = self:ParseWayCommand(line)
            if mapID and x and y then
                self:AddWaypoint(mapID, x, y, desc ~= "" and desc or nil, category)
                count = count + 1
            end
        end
    end

    return count
end

-------------------------------------------------------------------------------
-- Waypoint CRUD
-------------------------------------------------------------------------------
function PinBoard:AddWaypoint(mapID, x, y, title, category)
    local wp = {
        id = self.db.profile.nextID,
        mapID = mapID,
        x = x,
        y = y,
        title = title or "",
        category = category or DEFAULT_CATEGORY,
        zoneName = self:GetZoneName(mapID),
        created = time(),
    }
    self.db.profile.nextID = self.db.profile.nextID + 1
    tinsert(self.db.profile.waypoints, wp)

    self:SendMessage("PINBOARD_WAYPOINTS_CHANGED")
    return wp
end

function PinBoard:RemoveWaypoint(id)
    local wps = self.db.profile.waypoints
    for i, wp in ipairs(wps) do
        if wp.id == id then
            tremove(wps, i)
            self:SendMessage("PINBOARD_WAYPOINTS_CHANGED")
            return true
        end
    end
    return false
end

function PinBoard:UpdateWaypoint(id, fields)
    for _, wp in ipairs(self.db.profile.waypoints) do
        if wp.id == id then
            for k, v in pairs(fields) do
                wp[k] = v
            end
            if fields.mapID then
                wp.zoneName = self:GetZoneName(fields.mapID)
            end
            self:SendMessage("PINBOARD_WAYPOINTS_CHANGED")
            return true
        end
    end
    return false
end

function PinBoard:GetWaypoint(id)
    for _, wp in ipairs(self.db.profile.waypoints) do
        if wp.id == id then return wp end
    end
    return nil
end

function PinBoard:GetWaypoints()
    return self.db.profile.waypoints
end

function PinBoard:GetWaypointCount()
    return #self.db.profile.waypoints
end

-------------------------------------------------------------------------------
-- Category Management
-------------------------------------------------------------------------------
function PinBoard:GetCategories()
    return self.db.profile.categories
end

function PinBoard:AddCategory(name)
    name = strtrim(name)
    if name == "" then return false end
    for _, cat in ipairs(self.db.profile.categories) do
        if strlower(cat) == strlower(name) then return false end
    end
    tinsert(self.db.profile.categories, name)
    self:SendMessage("PINBOARD_WAYPOINTS_CHANGED")
    return true
end

function PinBoard:RemoveCategory(name)
    if name == DEFAULT_CATEGORY then return false end
    local cats = self.db.profile.categories
    for i, cat in ipairs(cats) do
        if cat == name then
            tremove(cats, i)
            -- Move waypoints in this category to General
            for _, wp in ipairs(self.db.profile.waypoints) do
                if wp.category == name then
                    wp.category = DEFAULT_CATEGORY
                end
            end
            self:SendMessage("PINBOARD_WAYPOINTS_CHANGED")
            return true
        end
    end
    return false
end

function PinBoard:IsCategoryCollapsed(name)
    return self.db.profile.collapsed[name]
end

function PinBoard:ToggleCategory(name)
    self.db.profile.collapsed[name] = not self.db.profile.collapsed[name]
    self:SendMessage("PINBOARD_WAYPOINTS_CHANGED")
end

-------------------------------------------------------------------------------
-- Blizzard Waypoint Integration
-------------------------------------------------------------------------------
PinBoard.activeWaypointID = nil

function PinBoard:SetWaypoint(id)
    local wp = self:GetWaypoint(id)
    if not wp then return false end

    local point = UiMapPoint.CreateFromCoordinates(wp.mapID, wp.x, wp.y)
    C_Map.SetUserWaypoint(point)

    if self.db.profile.autoTrack then
        C_SuperTrack.SetSuperTrackedUserWaypoint(true)
    end

    self.activeWaypointID = id
    self:SendMessage("PINBOARD_ACTIVE_CHANGED")
    return true
end

function PinBoard:ClearWaypoint()
    if C_Map.HasUserWaypoint() then
        C_Map.ClearUserWaypoint()
    end
    self.activeWaypointID = nil
    self:SendMessage("PINBOARD_ACTIVE_CHANGED")
end

function PinBoard:IsActiveWaypoint(id)
    return self.activeWaypointID == id
end

function PinBoard:GetDistanceTo(wp)
    local playerMapID, px, py = self:GetPlayerLocation()
    if not playerMapID or playerMapID ~= wp.mapID then return nil end

    local dx = (wp.x - px) * 10000
    local dy = (wp.y - py) * 10000
    return sqrt(dx * dx + dy * dy)
end

-------------------------------------------------------------------------------
-- LDB
-------------------------------------------------------------------------------
function PinBoard:SetupLDB()
    local ldb = LibStub("LibDataBroker-1.1")
    local dataObj = ldb:NewDataObject("PinBoard", {
        type = "launcher",
        icon = "Interface\\Icons\\INV_Misc_Map02",
        OnClick = function(_, button)
            if button == "LeftButton" then
                self:ToggleWindow()
            elseif button == "RightButton" then
                self:OpenConfig()
            end
        end,
        OnTooltipShow = function(tooltip)
            tooltip:AddLine("|cFF00D1FFPinBoard|r")
            tooltip:AddLine(" ")

            local count = self:GetWaypointCount()
            tooltip:AddDoubleLine("Saved Waypoints", tostring(count), 1, 1, 1, 1, 0.82, 0)

            if self.activeWaypointID then
                local wp = self:GetWaypoint(self.activeWaypointID)
                if wp then
                    tooltip:AddLine(" ")
                    tooltip:AddLine("Active:", 0, 0.8, 0)
                    tooltip:AddLine(format("  %s (%.1f, %.1f)", wp.zoneName,
                        wp.x * 100, wp.y * 100), 1, 1, 1)
                    if wp.title ~= "" then
                        tooltip:AddLine("  " .. wp.title, 0.7, 0.7, 0.7)
                    end
                end
            end

            -- Show closest waypoints in current zone
            local mapID = C_Map.GetBestMapForUnit("player")
            if mapID then
                local zoneWPs = {}
                for _, wp in ipairs(self:GetWaypoints()) do
                    if wp.mapID == mapID then
                        local dist = self:GetDistanceTo(wp)
                        if dist then
                            tinsert(zoneWPs, { wp = wp, dist = dist })
                        end
                    end
                end
                if #zoneWPs > 0 then
                    sort(zoneWPs, function(a, b) return a.dist < b.dist end)
                    tooltip:AddLine(" ")
                    tooltip:AddLine("Nearby:", 1, 0.82, 0)
                    for i = 1, min(5, #zoneWPs) do
                        local entry = zoneWPs[i]
                        local label = entry.wp.title ~= "" and entry.wp.title or
                            format("(%.1f, %.1f)", entry.wp.x * 100, entry.wp.y * 100)
                        tooltip:AddDoubleLine("  " .. label,
                            format("%.0f yd", entry.dist),
                            1, 1, 1, 0.5, 0.5, 0.5)
                    end
                end
            end

            tooltip:AddLine(" ")
            tooltip:AddLine("|cFFFFFFFFLeft-click:|r Toggle window", 0.5, 0.5, 0.5)
            tooltip:AddLine("|cFFFFFFFFRight-click:|r Options", 0.5, 0.5, 0.5)
        end,
    })

    local icon = LibStub("LibDBIcon-1.0")
    icon:Register("PinBoard", dataObj, self.db.profile.minimap)
end

-------------------------------------------------------------------------------
-- Addon Lifecycle
-------------------------------------------------------------------------------
function PinBoard:OnInitialize()
    self.db = LibStub("AceDB-3.0"):New("PinBoardDB", defaults, true)

    LibStub("AceConfig-3.0"):RegisterOptionsTable(addonName, self:GetOptionsTable())
    self.optionsCategoryID = select(2,
        LibStub("AceConfigDialog-3.0"):AddToBlizOptions(addonName, "PinBoard"))

    self:SetupLDB()

    self:RegisterChatCommand("pb", "SlashCommand")
    self:RegisterChatCommand("pinboard", "SlashCommand")
end

function PinBoard:OnEnable()
    self:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:RegisterEvent("USER_WAYPOINT_UPDATED")
    self:RegisterMessage("PINBOARD_WAYPOINTS_CHANGED", "RefreshList")
    self:RegisterMessage("PINBOARD_ACTIVE_CHANGED", "RefreshList")

    -- Build zone lookup in background
    C_Timer.After(2, BuildZoneLookup)
end

function PinBoard:PLAYER_ENTERING_WORLD()
    -- Ensure zone lookup is ready
    BuildZoneLookup()
end

function PinBoard:USER_WAYPOINT_UPDATED()
    -- If Blizzard waypoint was cleared externally, update our state
    if not C_Map.HasUserWaypoint() and self.activeWaypointID then
        self.activeWaypointID = nil
        self:SendMessage("PINBOARD_ACTIVE_CHANGED")
    end
end

-------------------------------------------------------------------------------
-- Slash Commands
-------------------------------------------------------------------------------
function PinBoard:SlashCommand(input)
    input = strtrim(strlower(input or ""))

    if input == "" or input == "toggle" then
        self:ToggleWindow()
    elseif input == "add" then
        self:QuickAddHere()
    elseif input == "import" then
        self:ShowImportDialog()
    elseif input == "clear" then
        self:ClearWaypoint()
        self:Print("Waypoint cleared.")
    elseif input == "config" or input == "options" then
        self:OpenConfig()
    elseif input == "help" then
        self:PrintHelp()
    else
        -- Try parsing as coordinates: /pb 54.9 27.3 description
        local mapID, x, y, desc = self:ParseWayCommand(input)
        if mapID and x and y then
            local wp = self:AddWaypoint(mapID, x, y, desc ~= "" and desc or nil)
            self:SetWaypoint(wp.id)
            self:Print(format("Pinned: %s (%.1f, %.1f)%s",
                wp.zoneName, wp.x * 100, wp.y * 100,
                wp.title ~= "" and " - " .. wp.title or ""))
        else
            self:PrintHelp()
        end
    end
end

function PinBoard:PrintHelp()
    self:Print("PinBoard Commands:")
    self:Print("  /pb - Toggle window")
    self:Print("  /pb add - Pin current location")
    self:Print("  /pb import - Open import dialog")
    self:Print("  /pb clear - Clear active waypoint")
    self:Print("  /pb x y [desc] - Add and set waypoint")
    self:Print("  /pb config - Open options")
end

function PinBoard:QuickAddHere()
    local mapID, x, y = self:GetPlayerLocation()
    if not mapID then
        self:Print("Cannot determine your location.")
        return
    end

    local zoneName = self:GetZoneName(mapID)
    local wp = self:AddWaypoint(mapID, x, y, "")
    self:Print(format("Pinned current location: %s (%.1f, %.1f)", zoneName, x * 100, y * 100))

    -- Open rename if UI is available
    if self.ShowEditDialog then
        self:ShowEditDialog(wp.id)
    end
end

function PinBoard:OpenConfig()
    if Settings and Settings.OpenToCategory then
        pcall(Settings.OpenToCategory, self.optionsCategoryID or "PinBoard")
    end
end

-- UI stubs (overridden by UI.lua)
function PinBoard:ToggleWindow() end
function PinBoard:ShowImportDialog() end
function PinBoard:ShowEditDialog() end
