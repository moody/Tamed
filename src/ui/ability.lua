local _, Addon = ...
local Ability = Addon.UI.Ability
local HBDPins = Addon.Libs.HBDPins
local L = Addon.Locale
local PinHelper = Addon.UI.PinHelper
local Widgets = Addon.UI.Widgets

function Ability:Create(parent, ability, rankIndex)
  -- Tooltip/heading button.
  local title = (L.ABILITY_WITH_RANK):format(ability.name, rankIndex)
  Widgets:Button({
    parent = parent,
    fullWidth = true,
    text = "|cFFFFFFFF" .. title .. "|r",
    height = 34,
    onEnter = function()
      _G.GameTooltip:SetOwner(_G.UIParent, "ANCHOR_CURSOR")
      _G.GameTooltip:SetHyperlink("spell:" .. ability.ranks[rankIndex].spell_id)
      _G.GameTooltip:Show()
    end,
    onLeave = function()
      _G.GameTooltip:Hide()
    end
  })

  self:AddPetLevelGroup(parent, ability, rankIndex)
  self:AddTrainingCostGroup(parent, ability, rankIndex)
  self:AddLearnedByGroup(parent, ability, rankIndex)
  self:AddTameableNPCsGroup(parent, ability, rankIndex)
end

function Ability:AddPetLevelGroup(parent, ability, rankIndex)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.PET_LEVEL,
    fullWidth = true,
  })

  Widgets:Label({
    parent = parent,
    text = ability.ranks[rankIndex].pet_level or 1,
    fullWidth = true
  })
end

function Ability:AddTrainingCostGroup(parent, ability, rankIndex)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.TRAINING_COST,
    fullWidth = true,
  })

  Widgets:Label({
    parent = parent,
    text = ability.ranks[rankIndex].training_cost or 0,
    fullWidth = true
  })
end

function Ability:AddLearnedByGroup(parent, ability)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.LEARNABLE_BY,
    fullWidth = true,
  })

  Widgets:Label({
    parent = parent,
    text = (
      #ability.learned_by > 0 and
      table.concat(ability.learned_by, ", ") or
      L.ALL_PET_FAMILIES
    ),
    fullWidth = true
  })
end

function Ability:AddTameableNPCsGroup(parent, ability, rankIndex)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = L.TAMEABLE_NPCS,
    fullWidth = true
  })

  local npc_ids = ability.ranks[rankIndex].npc_ids
  if #npc_ids > 0 then
    for _, npc_id in ipairs(npc_ids) do
      local npc = Addon.TameableNPCs[tostring(npc_id)]
      self:AddNPC(parent, npc)
    end
  else
    Widgets:Label({
      parent = parent,
      text = L.NONE,
      fullWidth = true
    })
  end
end

function Ability:AddNPC(parent, npc)
  parent = Widgets:InlineGroup({
    parent = parent,
    title = npc.name,
    fullWidth = true
  })

  -- Level.
  Widgets:Label({
    parent = parent,
    text = ("%s: %s"):format(L.LEVEL, table.concat(npc.level_range, "-")),
    fullWidth = true
  })

  -- Type.
  Widgets:Label({
    parent = parent,
    text = ("%s: %s"):format(L.TYPE, npc.type),
    fullWidth = true
  })

  -- Zone.
  Widgets:Label({
    parent = parent,
    text = ("%s: %s"):format(L.ZONE, npc.location),
    fullWidth = true
  })

  -- "Show on Map" button.
  local b = Widgets:Button({
    parent = parent,
    -- fullWidth = true,
    text = L.SHOW_ON_MAP,
    onClick = function()
      _G.WorldMapFrame:Show()
      _G.WorldMapFrame:SetMapID(npc.ui_map_id)

      PinHelper:Clear()

      for _, coords in pairs(npc.coords) do
        HBDPins:AddWorldMapIconMap(
          Addon,
          PinHelper:Get(npc),
          npc.ui_map_id,
          coords.x  * 0.01,
          coords.y * 0.01,
          HBD_PINS_WORLDMAP_SHOW_WORLD
        )
      end
    end,
  })

  if not npc.ui_map_id then
    b:SetText(L.MAP_UNAVAILABLE)
    b:SetDisabled(true)
  end
end
