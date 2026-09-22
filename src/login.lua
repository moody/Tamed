local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")

EventManager:Once(E.Wow.PlayerLogin, function()
  Addon:GetModule("DB"):Initialize()
  Addon:GetModule("Data"):Initialize()
  Addon:GetModule("MinimapIcon"):Initialize()
end)
