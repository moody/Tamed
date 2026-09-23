local ADDON_NAME = ... ---@type string

--- @class Addon
--- @field Wux Wux
local Addon = select(2, ...)

-- ============================================================================
-- Consts
-- ============================================================================

Addon.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
Addon.ICON = "Interface\\AddOns\\Tamed\\assets\\tamed-icon"
Addon.IS_TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

-- ============================================================================
-- Functions
-- ============================================================================

do -- Addon:GetModule()
  --- @type table<string, table>
  local modules = {}

  --- Gets or creates a module table for the given `key`.
  --- @generic T
  --- @param key `T`
  --- @return T
  function Addon:GetModule(key)
    --- @cast key +string
    key = key:upper()
    if type(modules[key]) ~= "table" then modules[key] = {} end
    return modules[key]
  end
end

do -- Addon:GetLibrary()
  --- @enum (key) LibraryKey
  local libraries = {
    HBD = LibStub("HereBeDragons-2.0"),
    HBDPins = LibStub("HereBeDragons-Pins-2.0"),
    LDB = LibStub("LibDataBroker-1.1"),
    LDBIcon = LibStub("LibDBIcon-1.0")
  }

  --- Returns a library based on the given `key`.
  --- @param key LibraryKey
  --- @return table
  function Addon:GetLibrary(key)
    return libraries[key] or error("Invalid library: " .. key)
  end
end

do -- Addon:MergeTameableNPCs()
  local TameableNPCs = Addon:GetModule("TameableNPCs")

  -- Merges patches (npc_id -> a full or partial record) into the TameableNPCs
  -- module, creating it on the first call. A patch's own fields overwrite the
  -- target's wholesale, not recursively; an npc_id with no existing record is
  -- inserted as-is.
  function Addon:MergeTameableNPCs(patches)
    for npc_id, patch in pairs(patches) do
      local npc = TameableNPCs[npc_id]
      if npc then
        for k, v in pairs(patch) do npc[k] = v end
      else
        TameableNPCs[npc_id] = patch
      end
    end
  end
end

do -- Addon:MergeTameableAbilities()
  local TameableAbilities = Addon:GetModule("TameableAbilities")

  -- Same as MergeTameableNPCs, for the TameableAbilities module.
  function Addon:MergeTameableAbilities(patches)
    for key, patch in pairs(patches) do
      local ability = TameableAbilities[key]
      if ability then
        for k, v in pairs(patch) do ability[k] = v end
      else
        TameableAbilities[key] = patch
      end
    end
  end
end
