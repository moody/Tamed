local _, Addon = ...
local Events = Addon:GetModule("Events") ---@class Events

-- ============================================================================
-- Tamed Events
-- ============================================================================

Events.DataLoaded = "Tamed_DataLoaded"
Events.StateUpdated = "Tamed_StateUpdated"
Events.StoreCreated = "Tamed_StoreCreated"

-- ============================================================================
-- WoW Events
-- ============================================================================

Events.Wow = {
  PlayerLogin = "PLAYER_LOGIN",
}
