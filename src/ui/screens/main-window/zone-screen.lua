local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local ComponentFactory = Addon:GetModule("ComponentFactory")
local L = Addon:GetModule("Locale")
local Widgets = Addon:GetModule("Widgets")

--- @class ZoneScreen
local ZoneScreen = Addon:GetModule("ZoneScreen")

-- ============================================================================
-- Local Functions
-- ============================================================================

--- Returns one line per ability taught in `zone`, listing its ranks there,
--- e.g. "Bite (Rank 2, 3)".
--- @param zone TameableZone
--- @return string
local function formatZoneAbilities(zone)
  local lines = {}

  --- @type TameableAbility?, string[]
  local ability, rankNumbers

  local function flush()
    if not ability then return end
    lines[#lines + 1] = ("|T%s:0|t %s %s"):format(
      ability.icon,
      ability.name,
      Colors.Grey(("(%s %s)"):format(L.RANK, table.concat(rankNumbers, ", ")))
    )
  end

  -- `zone.ranks` is sorted by ability name, so each ability's ranks are adjacent.
  for _, zoneRank in ipairs(zone.ranks) do
    if zoneRank.ability ~= ability then
      flush()
      ability, rankNumbers = zoneRank.ability, {}
    end
    rankNumbers[#rankNumbers + 1] = tostring(zoneRank.rank.rank)
  end
  flush()

  return table.concat(lines, "\n")
end

-- ============================================================================
-- ZoneScreen
-- ============================================================================

--- Builds and returns a root component describing the Zone Screen.
--- @return ZoneScreenComponent root
function ZoneScreen:Build()
  local Components = {}

  -- ------------------------------------------------------
  -- Root Component
  -- ------------------------------------------------------

  --- @class ZoneScreenComponent : WaffleFlexComponent
  Components.Root = Addon.Waffle:Flex({
    visibility = "GONE",
    direction = "COLUMN",
    gap = Widgets:Padding(),
  })

  --- Shows the given zone.
  --- @param zone TameableZone
  function Components.Root:SetZone(zone)
    Components.HeadingText:GetFrame():SetText(Colors.White(zone.name))
    Components.AbilitiesRow:SetText(formatZoneAbilities(zone))
    Components.NpcList:SetNpcIds(zone.npc_ids)
    self:MarkDirty()
  end

  -- ------------------------------------------------------
  -- Heading Components
  -- ------------------------------------------------------

  Components.HeadingText = Components.Root:AddChild({
    height = 32,

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalHuge")
      fontString:SetJustifyH("LEFT")
      fontString:SetWordWrap(false)
      return fontString
    end,
  })

  -- ------------------------------------------------------
  -- Details Components
  -- ------------------------------------------------------

  -- Details card. Grows with its text, shrinking the NPC list.
  Components.DetailsCard = Components.Root:AddColumn({
    height = "AUTO",
    gap = Widgets:Padding(0.5),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:Frame({ parent = parent })
    end,
  })

  --- @type DetailRowComponent
  Components.AbilitiesRow = Components.DetailsCard:AttachComponent(
    ComponentFactory:DetailRow({ labelText = L.ABILITIES })
  )

  -- ------------------------------------------------------
  -- NPCs Components
  -- ------------------------------------------------------

  -- Tameable NPCs heading.
  Components.Root:AddChild({
    height = 24,

    --- @param parent Frame
    frameFactory = function(parent)
      local fontString = parent:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
      fontString:SetJustifyH("LEFT")
      fontString:SetText(Colors.White(L.TAMEABLE_NPCS))
      return fontString
    end,
  })

  -- NPC list: cards and slider, each card listing the NPC's abilities.
  --- @type NpcListComponent
  Components.NpcList = Components.Root:AttachComponent(ComponentFactory:NpcList({ showAbilities = true }))

  return Components.Root
end
