local AddonName, Addon = ...
local AceAddon = Addon.Libs.AceAddon
local Commands = Addon.Commands
local MinimapIcon = Addon.UI.MinimapIcon
local PinHelper = Addon.UI.PinHelper
local UI = Addon.UI

function Commands:Initialize()
  AceAddon:RegisterChatCommand(AddonName, function(...) self:Handle(...) end)
  self.Initialize = nil
end

function Commands:Handle(...)
  local s = ...

  if type(s) == "string" then
    local cmd = AceAddon:GetArgs(s)
    if cmd == "icon" then
      return MinimapIcon:Toggle()
    elseif cmd == "clear" then
      return PinHelper:Clear()
    end
  end

  UI:Toggle()
end
