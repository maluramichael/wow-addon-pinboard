local addonName, addon = ...
local PinBoard = addon

function PinBoard:GetOptionsTable()
    return {
        type = "group",
        name = "PinBoard",
        args = {
            general = {
                name = "General",
                type = "group",
                order = 1,
                inline = true,
                args = {
                    autoTrack = {
                        name = "Auto-Track Waypoint",
                        desc = "Automatically show the on-screen arrow when setting a waypoint",
                        type = "toggle",
                        order = 1,
                        width = "full",
                        get = function() return self.db.profile.autoTrack end,
                        set = function(_, val) self.db.profile.autoTrack = val end,
                    },
                    useTomTom = {
                        name = "Use TomTom Navigation",
                        desc = "Also set a TomTom waypoint with arrow when setting a pin (requires TomTom addon)",
                        type = "toggle",
                        order = 2,
                        width = "full",
                        get = function() return self.db.profile.useTomTom end,
                        set = function(_, val) self.db.profile.useTomTom = val end,
                        disabled = function() return not (_G.TomTom and _G.TomTom.AddWaypoint) end,
                    },
                    confirmDelete = {
                        name = "Confirm Delete",
                        desc = "Show confirmation when removing waypoints (not yet implemented)",
                        type = "toggle",
                        order = 3,
                        width = "full",
                        get = function() return self.db.profile.confirmDelete end,
                        set = function(_, val) self.db.profile.confirmDelete = val end,
                    },
                    minimapIcon = {
                        name = "Show Minimap Button",
                        desc = "Toggle the minimap button",
                        type = "toggle",
                        order = 3,
                        get = function() return not self.db.profile.minimap.hide end,
                        set = function(_, val)
                            self.db.profile.minimap.hide = not val
                            if val then
                                LibStub("LibDBIcon-1.0"):Show("PinBoard")
                            else
                                LibStub("LibDBIcon-1.0"):Hide("PinBoard")
                            end
                        end,
                    },
                },
            },
            categories = {
                name = "Categories",
                type = "group",
                order = 2,
                inline = true,
                args = {
                    info = {
                        name = "Manage categories by right-clicking waypoints in the main window, " ..
                            "or use the context menu to move waypoints between categories.",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                    addCategory = {
                        name = "New Category",
                        desc = "Add a new category",
                        type = "input",
                        order = 2,
                        set = function(_, val)
                            if PinBoard:AddCategory(val) then
                                PinBoard:Print("Category added: " .. val)
                            end
                        end,
                    },
                },
            },
            commands = {
                name = "Slash Commands",
                type = "group",
                order = 3,
                inline = true,
                args = {
                    info = {
                        name = "|cFFFFD100/pb|r - Toggle window\n" ..
                            "|cFFFFD100/pb add|r - Pin current location\n" ..
                            "|cFFFFD100/pb import|r - Open import dialog\n" ..
                            "|cFFFFD100/pb clear|r - Clear active waypoint\n" ..
                            "|cFFFFD100/pb x y [desc]|r - Add and set waypoint\n" ..
                            "|cFFFFD100/pb config|r - Open this panel",
                        type = "description",
                        order = 1,
                        fontSize = "medium",
                    },
                },
            },
        },
    }
end
