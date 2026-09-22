local ADDON_NAME, Addon = ...

-- ============================================================================
-- Consts
-- ============================================================================

Addon.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
Addon.ICON = "Interface\\ICONS\\Ability_Hunter_BeastTaming"
Addon.IS_TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC

-- ============================================================================
-- Functions
-- ============================================================================

do -- Addon:GetModule()
  local modules = {}

  function Addon:GetModule(key)
    key = key:upper()
    if type(modules[key]) ~= "table" then modules[key] = {} end
    return modules[key]
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

do -- Addon:GetLibrary()
  local libraries = {
    AceAddon = LibStub("AceAddon-3.0"):NewAddon(ADDON_NAME, "AceConsole-3.0"),
    AceGUI = LibStub("AceGUI-3.0"),
    HBD = LibStub("HereBeDragons-2.0"),
    HBDPins = LibStub("HereBeDragons-Pins-2.0"),
    LDB = LibStub("LibDataBroker-1.1"),
    LDBIcon = LibStub("LibDBIcon-1.0")
  }

  function Addon:GetLibrary(key)
    return libraries[key] or error("Invalid library: " .. key)
  end
end

do -- AceAddon:OnInitialize().
  local AceAddon = Addon:GetLibrary("AceAddon")

  function AceAddon:OnInitialize()
    Addon:GetModule("DB"):Initialize()
    Addon:GetModule("Data"):Initialize()
    Addon:GetModule("MinimapIcon"):Initialize()
    Addon:GetModule("Commands"):Initialize()
  end
end
