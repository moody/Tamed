local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local PinHelper = Addon:GetModule("PinHelper")
local UI = Addon:GetModule("UI")

--- @class Commands
local Commands = Addon:GetModule("Commands")

-- ============================================================================
-- Events
-- ============================================================================

-- Register the `/tamed` slash command on login.
EventManager:Once(E.Wow.PlayerLogin, function()
  SLASH_TAMED1 = "/tamed"
  SlashCmdList.TAMED = function(msg)
    msg = strlower(msg or "")

    -- Split message into args.
    local args = {}
    for arg in msg:gmatch("%S+") do args[#args + 1] = strlower(arg) end

    -- First arg is command name.
    local key = table.remove(args, 1) or "ui"
    key = type(Commands[key]) == "function" and key or "ui"
    Commands[key](unpack(args))
  end
end)

-- ============================================================================
-- Commands
-- ============================================================================

--- Toggles the UI.
function Commands.ui()
  UI:Toggle()
end

--- Clear map pins.
function Commands.clear()
  PinHelper:Clear()
end
