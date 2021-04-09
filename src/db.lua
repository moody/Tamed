local _, Addon = ...
local DB = Addon.DB

local defaults = {
  global = {
    minimapIcon = { hide = false },
    npc_tooltips = true,
  }
}

function DB:Initialize()
  local db = _G.LibStub("AceDB-3.0"):New("__TAMED_ADDON_DB__", defaults)
  setmetatable(self, { __index = db })
  self.Initialize = nil
end
