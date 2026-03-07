local addonName, addon = ...
local PinBoard = addon

-------------------------------------------------------------------------------
-- UI Constants
-------------------------------------------------------------------------------
local WINDOW_WIDTH = 380
local WINDOW_HEIGHT = 480
local ROW_HEIGHT = 38
local CATEGORY_HEIGHT = 26
local HEADER_HEIGHT = 32
local TOOLBAR_HEIGHT = 30
local STATUSBAR_HEIGHT = 20
local SCROLLBAR_WIDTH = 16
local CONTENT_WIDTH = WINDOW_WIDTH - 20

local BACKDROP_MAIN = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 14,
    insets = { left = 3, right = 3, top = 3, bottom = 3 },
}

local BACKDROP_INNER = {
    bgFile = "Interface\\Buttons\\WHITE8x8",
    edgeFile = "Interface\\Buttons\\WHITE8x8",
    tile = true, tileSize = 16, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
}

local C = {
    bg          = { 0.06, 0.06, 0.08, 0.95 },
    headerBg    = { 0.10, 0.10, 0.13, 1 },
    innerBg     = { 0.04, 0.04, 0.06, 1 },
    innerBorder = { 0.18, 0.18, 0.22, 1 },
    border      = { 0.25, 0.25, 0.30, 1 },
    accent      = { 1, 0.82, 0, 1 },
    text        = { 0.90, 0.90, 0.90, 1 },
    textDim     = { 0.50, 0.50, 0.50, 1 },
    highlight   = { 0.20, 0.35, 0.60, 0.35 },
    activeGlow  = { 0.10, 0.65, 0.10, 0.30 },
    rowHover    = { 0.15, 0.15, 0.20, 0.50 },
    catBg       = { 0.08, 0.08, 0.11, 0.90 },
    danger      = { 0.80, 0.20, 0.20, 1 },
    green       = { 0.30, 0.85, 0.30, 1 },
}

-------------------------------------------------------------------------------
-- Row pool
-------------------------------------------------------------------------------
local rowPool = {}
local activeRows = {}

local function AcquireRow(parent)
    local row = tremove(rowPool)
    if not row then
        row = CreateFrame("Button", nil, parent, "BackdropTemplate")
        row:SetHeight(ROW_HEIGHT)

        -- Hover highlight
        row.highlight = row:CreateTexture(nil, "HIGHLIGHT")
        row.highlight:SetAllPoints()
        row.highlight:SetColorTexture(unpack(C.rowHover))

        -- Active indicator (left edge)
        row.activeBar = row:CreateTexture(nil, "OVERLAY")
        row.activeBar:SetPoint("TOPLEFT", 0, 0)
        row.activeBar:SetPoint("BOTTOMLEFT", 0, 0)
        row.activeBar:SetWidth(3)
        row.activeBar:SetColorTexture(unpack(C.green))
        row.activeBar:Hide()

        -- Active background
        row.activeBg = row:CreateTexture(nil, "BACKGROUND", nil, 1)
        row.activeBg:SetAllPoints()
        row.activeBg:SetColorTexture(unpack(C.activeGlow))
        row.activeBg:Hide()

        -- Zone + coords line
        row.zoneLine = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        row.zoneLine:SetPoint("TOPLEFT", 10, -4)
        row.zoneLine:SetPoint("RIGHT", -70, 0)
        row.zoneLine:SetJustifyH("LEFT")
        row.zoneLine:SetWordWrap(false)

        -- Title line
        row.titleLine = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        row.titleLine:SetPoint("TOPLEFT", 10, -18)
        row.titleLine:SetPoint("RIGHT", -70, 0)
        row.titleLine:SetJustifyH("LEFT")
        row.titleLine:SetWordWrap(false)

        -- Distance text
        row.distText = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        row.distText:SetPoint("RIGHT", -52, 0)
        row.distText:SetJustifyH("RIGHT")

        -- Set button
        row.setBtn = CreateFrame("Button", nil, row)
        row.setBtn:SetSize(22, 22)
        row.setBtn:SetPoint("RIGHT", -26, 0)
        row.setBtn:SetNormalAtlas("Waypoint-MapPin-ChatIcon")
        row.setBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        row.setBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Set Waypoint")
            GameTooltip:Show()
        end)
        row.setBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Delete button
        row.delBtn = CreateFrame("Button", nil, row)
        row.delBtn:SetSize(16, 16)
        row.delBtn:SetPoint("RIGHT", -6, 0)
        row.delBtn:SetNormalTexture("Interface\\Buttons\\UI-StopButton")
        row.delBtn:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
        row.delBtn:SetScript("OnEnter", function(self)
            GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
            GameTooltip:SetText("Remove")
            GameTooltip:Show()
        end)
        row.delBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

        -- Separator line at bottom
        row.sep = row:CreateTexture(nil, "OVERLAY")
        row.sep:SetPoint("BOTTOMLEFT", 8, 0)
        row.sep:SetPoint("BOTTOMRIGHT", -8, 0)
        row.sep:SetHeight(1)
        row.sep:SetColorTexture(0.15, 0.15, 0.18, 0.5)

        row.rowType = "waypoint"
    end

    row:SetParent(parent)
    row:Show()
    tinsert(activeRows, row)
    return row
end

local function AcquireCategoryRow(parent)
    local row = CreateFrame("Button", nil, parent, "BackdropTemplate")
    row:SetHeight(CATEGORY_HEIGHT)
    row:SetBackdrop(BACKDROP_INNER)
    row:SetBackdropColor(unpack(C.catBg))
    row:SetBackdropBorderColor(0, 0, 0, 0)

    row.arrow = row:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.arrow:SetPoint("LEFT", 8, 0)
    row.arrow:SetTextColor(unpack(C.accent))

    row.label = row:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.label:SetPoint("LEFT", 22, 0)
    row.label:SetTextColor(unpack(C.accent))

    row.count = row:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    row.count:SetPoint("RIGHT", -10, 0)

    row.rowType = "category"
    tinsert(activeRows, row)
    return row
end

local function ReleaseAllRows()
    for _, row in ipairs(activeRows) do
        row:Hide()
        row:SetParent(nil)
        if row.rowType == "waypoint" then
            tinsert(rowPool, row)
        end
    end
    wipe(activeRows)
end

-------------------------------------------------------------------------------
-- Main Frame
-------------------------------------------------------------------------------
local mainFrame

local function CreateMainFrame()
    if mainFrame then return mainFrame end

    local f = CreateFrame("Frame", "PinBoardFrame", UIParent, "BackdropTemplate")
    f:SetSize(WINDOW_WIDTH, WINDOW_HEIGHT)
    f:SetPoint("CENTER")
    f:SetBackdrop(BACKDROP_MAIN)
    f:SetBackdropColor(unpack(C.bg))
    f:SetBackdropBorderColor(unpack(C.border))
    f:SetMovable(true)
    f:SetClampedToScreen(true)
    f:SetFrameStrata("MEDIUM")
    f:EnableMouse(true)
    f:SetToplevel(true)

    -- ESC to close
    tinsert(UISpecialFrames, "PinBoardFrame")

    -- Header
    local header = CreateFrame("Frame", nil, f)
    header:SetPoint("TOPLEFT", 4, -4)
    header:SetPoint("TOPRIGHT", -4, -4)
    header:SetHeight(HEADER_HEIGHT)
    header:EnableMouse(true)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function() f:StartMoving() end)
    header:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

    local headerBg = header:CreateTexture(nil, "BACKGROUND")
    headerBg:SetAllPoints()
    headerBg:SetColorTexture(unpack(C.headerBg))

    local titleIcon = header:CreateTexture(nil, "ARTWORK")
    titleIcon:SetPoint("LEFT", 8, 0)
    titleIcon:SetSize(18, 18)
    titleIcon:SetTexture("Interface\\Icons\\INV_Misc_Map02")

    local title = header:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("LEFT", titleIcon, "RIGHT", 6, 0)
    title:SetText("|cFF00D1FFPinBoard|r")

    -- Close button
    local closeBtn = CreateFrame("Button", nil, header, "UIPanelCloseButtonNoScripts")
    closeBtn:SetPoint("TOPRIGHT", 2, 2)
    closeBtn:SetSize(24, 24)
    closeBtn:SetScript("OnClick", function() f:Hide() end)

    -- Toolbar
    local toolbar = CreateFrame("Frame", nil, f)
    toolbar:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -2)
    toolbar:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT", 0, -2)
    toolbar:SetHeight(TOOLBAR_HEIGHT)

    -- Search box
    local search = CreateFrame("EditBox", nil, toolbar, "BackdropTemplate")
    search:SetPoint("LEFT", 6, 0)
    search:SetSize(180, 22)
    search:SetBackdrop(BACKDROP_INNER)
    search:SetBackdropColor(0.08, 0.08, 0.10, 1)
    search:SetBackdropBorderColor(unpack(C.innerBorder))
    search:SetFontObject(GameFontHighlightSmall)
    search:SetAutoFocus(false)
    search:SetMaxLetters(50)
    search:SetTextInsets(6, 6, 0, 0)

    local searchIcon = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    searchIcon:SetPoint("LEFT", 4, 0)
    searchIcon:SetText("")
    search.placeholder = search:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    search.placeholder:SetPoint("LEFT", 6, 0)
    search.placeholder:SetText("Search...")
    search:SetScript("OnTextChanged", function(self)
        local text = self:GetText()
        self.placeholder:SetShown(text == "")
        PinBoard:RefreshList()
    end)
    search:SetScript("OnEscapePressed", function(self)
        self:SetText("")
        self:ClearFocus()
    end)
    f.searchBox = search

    -- Add Here button
    local addBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    addBtn:SetPoint("LEFT", search, "RIGHT", 4, 0)
    addBtn:SetSize(70, 22)
    addBtn:SetText("Pin Here")
    addBtn:SetScript("OnClick", function()
        PinBoard:QuickAddHere()
    end)
    addBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Pin your current location")
        GameTooltip:Show()
    end)
    addBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Import button
    local importBtn = CreateFrame("Button", nil, toolbar, "UIPanelButtonTemplate")
    importBtn:SetPoint("LEFT", addBtn, "RIGHT", 2, 0)
    importBtn:SetSize(64, 22)
    importBtn:SetText("Import")
    importBtn:SetScript("OnClick", function()
        PinBoard:ShowImportDialog()
    end)
    importBtn:SetScript("OnEnter", function(self)
        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
        GameTooltip:SetText("Import /way commands")
        GameTooltip:Show()
    end)
    importBtn:SetScript("OnLeave", function() GameTooltip:Hide() end)

    -- Scroll area
    local scrollBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
    scrollBg:SetPoint("TOPLEFT", toolbar, "BOTTOMLEFT", 4, -4)
    scrollBg:SetPoint("BOTTOMRIGHT", f, "BOTTOMRIGHT", -4, STATUSBAR_HEIGHT + 6)
    scrollBg:SetBackdrop(BACKDROP_INNER)
    scrollBg:SetBackdropColor(unpack(C.innerBg))
    scrollBg:SetBackdropBorderColor(unpack(C.innerBorder))

    local scrollFrame = CreateFrame("ScrollFrame", nil, scrollBg)
    scrollFrame:SetPoint("TOPLEFT", 2, -2)
    scrollFrame:SetPoint("BOTTOMRIGHT", -SCROLLBAR_WIDTH - 2, 2)
    scrollFrame:EnableMouseWheel(true)

    local scrollChild = CreateFrame("Frame")
    scrollChild:SetWidth(scrollFrame:GetWidth() or (CONTENT_WIDTH - SCROLLBAR_WIDTH - 8))
    scrollFrame:SetScrollChild(scrollChild)

    -- Scroll bar
    local scrollBar = CreateFrame("Slider", nil, scrollBg, "BackdropTemplate")
    scrollBar:SetPoint("TOPRIGHT", -3, -2)
    scrollBar:SetPoint("BOTTOMRIGHT", -3, 2)
    scrollBar:SetWidth(SCROLLBAR_WIDTH - 4)
    scrollBar:SetBackdrop({
        bgFile = "Interface\\Buttons\\WHITE8x8",
        insets = { left = 0, right = 0, top = 0, bottom = 0 },
    })
    scrollBar:SetBackdropColor(0.1, 0.1, 0.12, 0.5)
    scrollBar:SetOrientation("VERTICAL")
    scrollBar:SetMinMaxValues(0, 1)
    scrollBar:SetValue(0)
    scrollBar:SetValueStep(ROW_HEIGHT)

    local thumb = scrollBar:CreateTexture(nil, "OVERLAY")
    thumb:SetColorTexture(0.3, 0.3, 0.35, 0.8)
    thumb:SetSize(SCROLLBAR_WIDTH - 6, 40)
    scrollBar:SetThumbTexture(thumb)

    scrollBar:SetScript("OnValueChanged", function(_, value)
        scrollFrame:SetVerticalScroll(value)
    end)

    scrollFrame:SetScript("OnMouseWheel", function(_, delta)
        local cur = scrollBar:GetValue()
        local minV, maxV = scrollBar:GetMinMaxValues()
        local step = ROW_HEIGHT * 3
        local newVal = max(minV, min(maxV, cur - delta * step))
        scrollBar:SetValue(newVal)
    end)

    f.scrollFrame = scrollFrame
    f.scrollChild = scrollChild
    f.scrollBar = scrollBar
    f.scrollBg = scrollBg

    -- Status bar
    local statusBar = CreateFrame("Frame", nil, f)
    statusBar:SetPoint("BOTTOMLEFT", 4, 4)
    statusBar:SetPoint("BOTTOMRIGHT", -4, 4)
    statusBar:SetHeight(STATUSBAR_HEIGHT)

    local statusText = statusBar:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    statusText:SetPoint("LEFT", 6, 0)
    f.statusText = statusText

    local clearBtn = CreateFrame("Button", nil, statusBar)
    clearBtn:SetPoint("RIGHT", -4, 0)
    clearBtn:SetSize(60, 16)
    clearBtn.text = clearBtn:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    clearBtn.text:SetAllPoints()
    clearBtn.text:SetText("Clear Pin")
    clearBtn:SetScript("OnClick", function() PinBoard:ClearWaypoint() end)
    clearBtn:SetScript("OnEnter", function(self)
        self.text:SetTextColor(1, 1, 1)
        GameTooltip:SetOwner(self, "ANCHOR_TOP")
        GameTooltip:SetText("Clear active waypoint")
        GameTooltip:Show()
    end)
    clearBtn:SetScript("OnLeave", function(self)
        self.text:SetTextColor(unpack(C.textDim))
        GameTooltip:Hide()
    end)

    -- Resize on show to fix scrollChild width
    f:SetScript("OnShow", function()
        scrollChild:SetWidth(scrollFrame:GetWidth())
        PinBoard:RefreshList()
    end)

    mainFrame = f
    f:Hide()
    return f
end

-------------------------------------------------------------------------------
-- Build visible row list
-------------------------------------------------------------------------------
local function GetFilteredWaypoints()
    local searchText = mainFrame and mainFrame.searchBox:GetText():lower() or ""
    local wps = PinBoard:GetWaypoints()
    local filtered = {}

    for _, wp in ipairs(wps) do
        if searchText == "" or
           (wp.title and wp.title:lower():find(searchText, 1, true)) or
           (wp.zoneName and wp.zoneName:lower():find(searchText, 1, true)) then
            tinsert(filtered, wp)
        end
    end

    return filtered
end

local function GroupByCategory(waypoints)
    local groups = {}
    local groupOrder = {}

    for _, cat in ipairs(PinBoard:GetCategories()) do
        groups[cat] = {}
        tinsert(groupOrder, cat)
    end

    for _, wp in ipairs(waypoints) do
        local cat = wp.category or "General"
        if not groups[cat] then
            groups[cat] = {}
            tinsert(groupOrder, cat)
        end
        tinsert(groups[cat], wp)
    end

    return groups, groupOrder
end

-------------------------------------------------------------------------------
-- Refresh List
-------------------------------------------------------------------------------
function PinBoard:RefreshList()
    if not mainFrame or not mainFrame:IsShown() then return end

    ReleaseAllRows()

    local filtered = GetFilteredWaypoints()
    local groups, groupOrder = GroupByCategory(filtered)
    local scrollChild = mainFrame.scrollChild
    local yOffset = 0
    local totalWPs = 0

    for _, catName in ipairs(groupOrder) do
        local catWPs = groups[catName]
        if #catWPs > 0 then
            -- Category header
            local catRow = AcquireCategoryRow(scrollChild)
            catRow:SetPoint("TOPLEFT", 0, -yOffset)
            catRow:SetPoint("RIGHT", 0, 0)

            local collapsed = self:IsCategoryCollapsed(catName)
            catRow.arrow:SetText(collapsed and "+" or "-")
            catRow.label:SetText(catName)
            catRow.count:SetText("(" .. #catWPs .. ")")
            catRow:SetScript("OnClick", function()
                PinBoard:ToggleCategory(catName)
            end)
            yOffset = yOffset + CATEGORY_HEIGHT

            -- Waypoint rows
            if not collapsed then
                for _, wp in ipairs(catWPs) do
                    local row = AcquireRow(scrollChild)
                    row:SetPoint("TOPLEFT", 0, -yOffset)
                    row:SetPoint("RIGHT", 0, 0)

                    -- Zone + coords
                    local zoneText = format("|cFFFFD100%s|r  |cFF808080(%.1f, %.1f)|r",
                        wp.zoneName or "?", wp.x * 100, wp.y * 100)
                    row.zoneLine:SetText(zoneText)

                    -- Title
                    local titleText = wp.title ~= "" and wp.title or "|cFF555555(no description)|r"
                    row.titleLine:SetText(titleText)

                    -- Distance
                    local dist = self:GetDistanceTo(wp)
                    if dist then
                        row.distText:SetText(format("%.0f yd", dist))
                        row.distText:Show()
                    else
                        row.distText:Hide()
                    end

                    -- Active state
                    local isActive = self:IsActiveWaypoint(wp.id)
                    row.activeBar:SetShown(isActive)
                    row.activeBg:SetShown(isActive)

                    -- Buttons
                    row.setBtn:SetScript("OnClick", function()
                        PinBoard:SetWaypoint(wp.id)
                        PinBoard:RefreshList()
                    end)
                    row.delBtn:SetScript("OnClick", function()
                        PinBoard:RemoveWaypoint(wp.id)
                    end)

                    -- Double-click to set
                    row:SetScript("OnDoubleClick", function()
                        PinBoard:SetWaypoint(wp.id)
                        PinBoard:RefreshList()
                    end)

                    -- Right-click context menu
                    row:RegisterForClicks("LeftButtonUp", "RightButtonUp")
                    row:SetScript("OnClick", function(_, button)
                        if button == "RightButton" then
                            PinBoard:ShowContextMenu(row, wp)
                        end
                    end)

                    -- Tooltip
                    row:SetScript("OnEnter", function(self)
                        GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
                        GameTooltip:AddLine(wp.zoneName or "Unknown", 1, 0.82, 0)
                        GameTooltip:AddLine(format("%.1f, %.1f", wp.x * 100, wp.y * 100), 1, 1, 1)
                        if wp.title and wp.title ~= "" then
                            GameTooltip:AddLine(wp.title, 0.7, 0.7, 0.7)
                        end
                        GameTooltip:AddLine(" ")
                        GameTooltip:AddLine("Double-click to set waypoint", 0.5, 0.5, 0.5)
                        GameTooltip:AddLine("Right-click for options", 0.5, 0.5, 0.5)
                        GameTooltip:Show()
                    end)
                    row:SetScript("OnLeave", function() GameTooltip:Hide() end)

                    yOffset = yOffset + ROW_HEIGHT
                    totalWPs = totalWPs + 1
                end
            else
                totalWPs = totalWPs + #catWPs
            end
        end
    end

    -- Update scroll range
    scrollChild:SetHeight(max(1, yOffset))
    local scrollMax = max(0, yOffset - mainFrame.scrollBg:GetHeight() + 4)
    mainFrame.scrollBar:SetMinMaxValues(0, scrollMax)
    mainFrame.scrollBar:SetShown(scrollMax > 0)

    -- Status text
    local statusParts = { tostring(totalWPs) .. " waypoint" .. (totalWPs ~= 1 and "s" or "") }
    if self.activeWaypointID then
        local awp = self:GetWaypoint(self.activeWaypointID)
        if awp then
            tinsert(statusParts, format("Active: %s", awp.zoneName))
        end
    end
    mainFrame.statusText:SetText(table.concat(statusParts, "  |cFF555555·|r  "))
end

-------------------------------------------------------------------------------
-- Context Menu
-------------------------------------------------------------------------------
local contextMenuFrame

function PinBoard:ShowContextMenu(anchor, wp)
    if not contextMenuFrame then
        contextMenuFrame = CreateFrame("Frame", "PinBoardContextMenu", UIParent, "UIDropDownMenuTemplate")
    end

    local function InitMenu(_, level)
        if not level then return end

        if level == 1 then
            local info = UIDropDownMenu_CreateInfo()

            -- Set Waypoint
            info.text = "Set Waypoint"
            info.notCheckable = true
            info.func = function()
                PinBoard:SetWaypoint(wp.id)
                PinBoard:RefreshList()
            end
            UIDropDownMenu_AddButton(info, level)

            -- Edit
            info = UIDropDownMenu_CreateInfo()
            info.text = "Edit"
            info.notCheckable = true
            info.func = function()
                PinBoard:ShowEditDialog(wp.id)
            end
            UIDropDownMenu_AddButton(info, level)

            -- Move to Category submenu
            info = UIDropDownMenu_CreateInfo()
            info.text = "Move to"
            info.notCheckable = true
            info.hasArrow = true
            info.value = "MOVE_TO"
            UIDropDownMenu_AddButton(info, level)

            -- Delete
            info = UIDropDownMenu_CreateInfo()
            info.text = "|cFFFF4444Remove|r"
            info.notCheckable = true
            info.func = function()
                PinBoard:RemoveWaypoint(wp.id)
            end
            UIDropDownMenu_AddButton(info, level)
        end

        if level == 2 and UIDROPDOWNMENU_MENU_VALUE == "MOVE_TO" then
            for _, cat in ipairs(PinBoard:GetCategories()) do
                local catInfo = UIDropDownMenu_CreateInfo()
                catInfo.text = cat
                catInfo.checked = (wp.category == cat)
                catInfo.func = function()
                    PinBoard:UpdateWaypoint(wp.id, { category = cat })
                    CloseDropDownMenus()
                end
                UIDropDownMenu_AddButton(catInfo, level)
            end

            -- New category option
            local newInfo = UIDropDownMenu_CreateInfo()
            newInfo.text = "|cFF00FF00+ New Category|r"
            newInfo.notCheckable = true
            newInfo.func = function()
                CloseDropDownMenus()
                PinBoard:ShowNewCategoryDialog(wp.id)
            end
            UIDropDownMenu_AddButton(newInfo, level)
        end
    end

    contextMenuFrame.initialize = InitMenu
    ToggleDropDownMenu(1, nil, contextMenuFrame, anchor, 0, 0)
end

-------------------------------------------------------------------------------
-- Import Dialog
-------------------------------------------------------------------------------
local importFrame

function PinBoard:ShowImportDialog()
    if not importFrame then
        local f = CreateFrame("Frame", "PinBoardImportFrame", UIParent, "BackdropTemplate")
        f:SetSize(400, 340)
        f:SetPoint("CENTER")
        f:SetBackdrop(BACKDROP_MAIN)
        f:SetBackdropColor(unpack(C.bg))
        f:SetBackdropBorderColor(unpack(C.border))
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)

        tinsert(UISpecialFrames, "PinBoardImportFrame")

        -- Header
        local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOP", 0, -10)
        header:SetText("|cFF00D1FFImport Waypoints|r")

        local dragRegion = CreateFrame("Frame", nil, f)
        dragRegion:SetPoint("TOPLEFT", 0, 0)
        dragRegion:SetPoint("TOPRIGHT", 0, 0)
        dragRegion:SetHeight(28)
        dragRegion:EnableMouse(true)
        dragRegion:RegisterForDrag("LeftButton")
        dragRegion:SetScript("OnDragStart", function() f:StartMoving() end)
        dragRegion:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButtonNoScripts")
        closeBtn:SetPoint("TOPRIGHT", 2, 2)
        closeBtn:SetSize(24, 24)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Instruction text
        local instr = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        instr:SetPoint("TOPLEFT", 14, -30)
        instr:SetPoint("RIGHT", -14, 0)
        instr:SetJustifyH("LEFT")
        instr:SetText("Paste /way commands below (one per line):")

        -- Edit box in scroll frame
        local scrollBg = CreateFrame("Frame", nil, f, "BackdropTemplate")
        scrollBg:SetPoint("TOPLEFT", 10, -48)
        scrollBg:SetPoint("BOTTOMRIGHT", -10, 72)
        scrollBg:SetBackdrop(BACKDROP_INNER)
        scrollBg:SetBackdropColor(0.04, 0.04, 0.06, 1)
        scrollBg:SetBackdropBorderColor(unpack(C.innerBorder))

        local scroll = CreateFrame("ScrollFrame", nil, scrollBg, "UIPanelScrollFrameTemplate")
        scroll:SetPoint("TOPLEFT", 6, -6)
        scroll:SetPoint("BOTTOMRIGHT", -24, 6)

        local editBox = CreateFrame("EditBox", nil, scroll)
        editBox:SetMultiLine(true)
        editBox:SetAutoFocus(false)
        editBox:SetFontObject(GameFontHighlightSmall)
        editBox:SetWidth(scroll:GetWidth() or 340)
        editBox:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        scroll:SetScrollChild(editBox)
        f.editBox = editBox

        -- Category dropdown label
        local catLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        catLabel:SetPoint("BOTTOMLEFT", 14, 44)
        catLabel:SetText("Category:")

        -- Simple category text button
        local catBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        catBtn:SetPoint("LEFT", catLabel, "RIGHT", 6, 0)
        catBtn:SetSize(100, 22)
        catBtn:SetText("General")
        f.selectedCategory = "General"
        catBtn:SetScript("OnClick", function(self)
            -- Cycle through categories
            local cats = PinBoard:GetCategories()
            local currentIdx = 1
            for i, cat in ipairs(cats) do
                if cat == f.selectedCategory then
                    currentIdx = i
                    break
                end
            end
            f.selectedCategory = cats[(currentIdx % #cats) + 1]
            self:SetText(f.selectedCategory)
        end)

        -- Import button
        local importBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        importBtn:SetPoint("BOTTOMRIGHT", -80, 10)
        importBtn:SetSize(80, 26)
        importBtn:SetText("Import")
        importBtn:SetScript("OnClick", function()
            local text = editBox:GetText()
            if text and text ~= "" then
                local count = PinBoard:ImportWayCommands(text, f.selectedCategory)
                PinBoard:Print(format("Imported %d waypoint%s.", count, count ~= 1 and "s" or ""))
                f:Hide()
            end
        end)

        -- Cancel button
        local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        cancelBtn:SetPoint("BOTTOMRIGHT", -10, 10)
        cancelBtn:SetSize(64, 26)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function() f:Hide() end)

        f:SetScript("OnShow", function()
            editBox:SetText("")
            editBox:SetFocus()
        end)

        importFrame = f
    end

    importFrame:Show()
end

-------------------------------------------------------------------------------
-- Edit Dialog
-------------------------------------------------------------------------------
local editFrame

function PinBoard:ShowEditDialog(wpID)
    local wp = self:GetWaypoint(wpID)
    if not wp then return end

    if not editFrame then
        local f = CreateFrame("Frame", "PinBoardEditFrame", UIParent, "BackdropTemplate")
        f:SetSize(320, 200)
        f:SetPoint("CENTER")
        f:SetBackdrop(BACKDROP_MAIN)
        f:SetBackdropColor(unpack(C.bg))
        f:SetBackdropBorderColor(unpack(C.border))
        f:SetMovable(true)
        f:SetClampedToScreen(true)
        f:SetFrameStrata("DIALOG")
        f:EnableMouse(true)

        tinsert(UISpecialFrames, "PinBoardEditFrame")

        local header = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        header:SetPoint("TOP", 0, -10)
        header:SetText("|cFF00D1FFEdit Waypoint|r")

        local dragRegion = CreateFrame("Frame", nil, f)
        dragRegion:SetPoint("TOPLEFT", 0, 0)
        dragRegion:SetPoint("TOPRIGHT", 0, 0)
        dragRegion:SetHeight(28)
        dragRegion:EnableMouse(true)
        dragRegion:RegisterForDrag("LeftButton")
        dragRegion:SetScript("OnDragStart", function() f:StartMoving() end)
        dragRegion:SetScript("OnDragStop", function() f:StopMovingOrSizing() end)

        local closeBtn = CreateFrame("Button", nil, f, "UIPanelCloseButtonNoScripts")
        closeBtn:SetPoint("TOPRIGHT", 2, 2)
        closeBtn:SetSize(24, 24)
        closeBtn:SetScript("OnClick", function() f:Hide() end)

        -- Title input
        local titleLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        titleLabel:SetPoint("TOPLEFT", 14, -34)
        titleLabel:SetText("Description:")

        local titleInput = CreateFrame("EditBox", nil, f, "BackdropTemplate")
        titleInput:SetPoint("TOPLEFT", 14, -48)
        titleInput:SetPoint("RIGHT", -14, 0)
        titleInput:SetHeight(24)
        titleInput:SetBackdrop(BACKDROP_INNER)
        titleInput:SetBackdropColor(0.08, 0.08, 0.10, 1)
        titleInput:SetBackdropBorderColor(unpack(C.innerBorder))
        titleInput:SetFontObject(GameFontHighlightSmall)
        titleInput:SetAutoFocus(false)
        titleInput:SetMaxLetters(100)
        titleInput:SetTextInsets(6, 6, 0, 0)
        titleInput:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
        titleInput:SetScript("OnEnterPressed", function(self) self:ClearFocus() end)
        f.titleInput = titleInput

        -- Zone (read-only)
        local zoneLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        zoneLabel:SetPoint("TOPLEFT", 14, -82)
        zoneLabel:SetText("Zone:")

        local zoneText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        zoneText:SetPoint("TOPLEFT", 14, -96)
        f.zoneText = zoneText

        -- Coords (read-only)
        local coordsLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        coordsLabel:SetPoint("TOPLEFT", 180, -82)
        coordsLabel:SetText("Coordinates:")

        local coordsText = f:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
        coordsText:SetPoint("TOPLEFT", 180, -96)
        f.coordsText = coordsText

        -- Category cycle button
        local catLabel = f:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        catLabel:SetPoint("TOPLEFT", 14, -120)
        catLabel:SetText("Category:")

        local catBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        catBtn:SetPoint("TOPLEFT", 14, -134)
        catBtn:SetSize(120, 22)
        f.catBtn = catBtn

        -- Save button
        local saveBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        saveBtn:SetPoint("BOTTOMRIGHT", -80, 10)
        saveBtn:SetSize(64, 26)
        saveBtn:SetText("Save")
        f.saveBtn = saveBtn

        -- Cancel button
        local cancelBtn = CreateFrame("Button", nil, f, "UIPanelButtonTemplate")
        cancelBtn:SetPoint("BOTTOMRIGHT", -10, 10)
        cancelBtn:SetSize(64, 26)
        cancelBtn:SetText("Cancel")
        cancelBtn:SetScript("OnClick", function() f:Hide() end)

        editFrame = f
    end

    -- Populate fields
    editFrame.titleInput:SetText(wp.title or "")
    editFrame.zoneText:SetText("|cFFFFD100" .. (wp.zoneName or "Unknown") .. "|r")
    editFrame.coordsText:SetText(format("|cFFFFD100%.1f, %.1f|r", wp.x * 100, wp.y * 100))
    editFrame.catBtn:SetText(wp.category or "General")
    editFrame._editCategory = wp.category or "General"

    editFrame.catBtn:SetScript("OnClick", function(self)
        local cats = PinBoard:GetCategories()
        local currentIdx = 1
        for i, cat in ipairs(cats) do
            if cat == editFrame._editCategory then
                currentIdx = i
                break
            end
        end
        editFrame._editCategory = cats[(currentIdx % #cats) + 1]
        self:SetText(editFrame._editCategory)
    end)

    editFrame.saveBtn:SetScript("OnClick", function()
        PinBoard:UpdateWaypoint(wpID, {
            title = editFrame.titleInput:GetText(),
            category = editFrame._editCategory,
        })
        editFrame:Hide()
    end)

    editFrame:Show()
    editFrame.titleInput:SetFocus()
end

-------------------------------------------------------------------------------
-- New Category Dialog (simple popup)
-------------------------------------------------------------------------------
StaticPopupDialogs["PINBOARD_NEW_CATEGORY"] = {
    text = "New category name:",
    button1 = "Create",
    button2 = "Cancel",
    hasEditBox = true,
    editBoxWidth = 200,
    OnAccept = function(self)
        local name = self.editBox:GetText()
        if PinBoard:AddCategory(name) then
            local wpID = self._pinboardWpID
            if wpID then
                PinBoard:UpdateWaypoint(wpID, { category = name })
            end
        end
    end,
    OnShow = function(self)
        self.editBox:SetText("")
        self.editBox:SetFocus()
    end,
    timeout = 0,
    whileDead = true,
    preferredIndex = 3,
}

function PinBoard:ShowNewCategoryDialog(wpID)
    local dialog = StaticPopup_Show("PINBOARD_NEW_CATEGORY")
    if dialog then
        dialog._pinboardWpID = wpID
    end
end

-------------------------------------------------------------------------------
-- Wire up addon methods
-------------------------------------------------------------------------------
function PinBoard:ToggleWindow()
    local f = CreateMainFrame()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
    end
end

-- Message handlers are registered in Core.lua OnEnable
