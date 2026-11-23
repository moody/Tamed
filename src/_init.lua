local ADDON_NAME = ... ---@type string

--- @class Addon
--- @field Waffle Waffle
--- @field Wux Wux
local Addon = select(2, ...)

-- ============================================================================
-- Consts
-- ============================================================================

Addon.VERSION = C_AddOns.GetAddOnMetadata(ADDON_NAME, "Version")
Addon.ICON = "Interface\\ICONS\\Ability_Hunter_BeastTaming"
Addon.IS_VANILLA = WOW_PROJECT_ID == WOW_PROJECT_CLASSIC
Addon.IS_TBC = WOW_PROJECT_ID == WOW_PROJECT_BURNING_CRUSADE_CLASSIC
Addon.IS_FOREVER = WOW_PROJECT_ID == WOW_PROJECT_CAMELOT

--- Highest level a player can reach on the running client.
Addon.MAX_LEVEL = Addon.IS_TBC and 70 or 60

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

--- Returns the full path to a file in the `/assets` folder.
--- @param fileName string
--- @return string
function Addon:GetAsset(fileName)
  return ("Interface\\AddOns\\%s\\assets\\%s"):format(ADDON_NAME, fileName)
end

do -- Addon:MergeTameableFamilies(), Addon:MergeTameableNPCs(), Addon:MergeTameableAbilities()
  --- Merges patches (key -> a full or partial record) into `target`. A patch's own fields overwrite the
  --- record's wholesale, not recursively; a key with no existing record is inserted as-is.
  --- @param target table<string, table>
  --- @param patches table<string, table>
  local function mergePatches(target, patches)
    for key, patch in pairs(patches) do
      local record = target[key]
      if record then
        for k, v in pairs(patch) do record[k] = v end
      else
        target[key] = patch
      end
    end
  end

  local TameableFamilies = Addon:GetModule("TameableFamilies")
  local TameableNPCs = Addon:GetModule("TameableNPCs")
  local TameableAbilities = Addon:GetModule("TameableAbilities")

  -- Merges patches (family key -> a full or partial record) into the TameableFamilies module.
  function Addon:MergeTameableFamilies(patches)
    mergePatches(TameableFamilies, patches)
  end

  -- Same as MergeTameableFamilies, for npc_id and the TameableNPCs module.
  function Addon:MergeTameableNPCs(patches)
    mergePatches(TameableNPCs, patches)
  end

  -- Same as MergeTameableFamilies, for ability key and the TameableAbilities module.
  function Addon:MergeTameableAbilities(patches)
    mergePatches(TameableAbilities, patches)
  end
end
