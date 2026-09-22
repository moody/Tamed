local _, Addon = ...
local Events = Addon:GetModule("Events") ---@class Events

-- ============================================================================
-- WoW Events
-- ============================================================================

Events.Wow = {
  PlayerLogin = "PLAYER_LOGIN",
}
