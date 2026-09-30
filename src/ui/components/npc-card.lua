local Addon = select(2, ...) ---@type Addon
local Colors = Addon:GetModule("Colors")
local HBDPins = Addon:GetLibrary("HBDPins")
local L = Addon:GetModule("Locale")
local PinHelper = Addon:GetModule("PinHelper")
local Widgets = Addon:GetModule("Widgets")

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

-- =============================================================================
-- Local Functions
-- =============================================================================

--- Opens the world map to the given NPC's zone, pinning its spawn locations.
--- @param npc TameableNPC
local function showOnMap(npc)
  OpenWorldMap(npc.ui_map_id)
  PinHelper:Clear()
  for _, coord in ipairs(npc.coords) do
    HBDPins:AddWorldMapIconMap(
      Addon, PinHelper:Get(npc), npc.ui_map_id,
      coord.x * 0.01, coord.y * 0.01, HBD_PINS_WORLDMAP_SHOW_WORLD
    )
  end
end

-- =============================================================================
-- ComponentFactory - NpcCard
-- =============================================================================

--- Creates a card showing an NPC's name, level, and location. Clicking the
--- card or its button shows the NPC on the map, if it has a `ui_map_id`.
--- @return NpcCardComponent card
function ComponentFactory:NpcCard()
  --- @type TameableNPC?
  local npc

  --- @type { node: WaffleFlexComponent, getText: fun(npc: TameableNPC): string }[]
  local textLines = {}

  --- Highlights the card while hovered, if its NPC has a map.
  --- @param frame FrameWidget
  local function updateHighlight(frame)
    local alpha = (npc and npc.ui_map_id and frame:IsMouseOver()) and 0.5 or 0.25
    frame:SetBackdropColor(Colors.DarkGrey:GetRGBA(alpha))
    frame:SetBackdropBorderColor(Colors.White:GetRGBA(alpha))
  end

  local card

  --- @class NpcCardComponent : WaffleFlexComponent
  card = Addon.Waffle:Flex({
    direction = "ROW",
    align = "CENTER",
    gap = Widgets:Padding(),
    padding = Widgets:Padding(),

    --- @param parent Frame
    frameFactory = function(parent)
      local frame = Widgets:Frame({ parent = parent, frameType = "Button" })
      updateHighlight(frame)

      frame:SetScript("OnClick", function()
        if npc and npc.ui_map_id then showOnMap(npc) end
      end)

      frame:SetScript("OnEnter", updateHighlight)

      -- Stays highlighted while over the map button
      frame:SetScript("OnLeave", updateHighlight)

      return frame
    end,
  })

  -- Name, level, and location.
  local info = card:AddColumn({ height = "AUTO", gap = 2 })

  --- Adds a text line filled in by `getText` for the current NPC.
  --- @param fontObject string
  --- @param color Color
  --- @param wordWrap boolean
  --- @param getText fun(npc: TameableNPC): string
  local function addTextLine(fontObject, color, wordWrap, getText)
    local node = info:AddChild({
      height = "AUTO",

      --- @param parent Frame
      frameFactory = function(parent)
        local fontString = parent:CreateFontString(nil, "ARTWORK", fontObject)
        fontString:SetJustifyH("LEFT")
        fontString:SetWordWrap(wordWrap)
        fontString:SetTextColor(color:GetRGB())
        fontString:SetText(npc and getText(npc) or "")
        return fontString
      end,

      onMeasure = function(fontString, width)
        fontString:SetSize(width, 0)
        return width, fontString:GetStringHeight()
      end,
    })

    textLines[#textLines + 1] = { node = node, getText = getText }
  end

  addTextLine("GameFontNormal", Colors.Primary, false, function(n) return n.name end)
  addTextLine("GameFontNormalSmall", Colors.Grey, false, function(n) return ("%s %s"):format(L.LEVEL, n.level_range) end)
  addTextLine("GameFontNormalSmall", Colors.Grey, true, function(n) return n.location end)

  local mapButton = card:AddChild({
    width = 90,
    height = 20,

    --- @param parent Frame
    frameFactory = function(parent)
      return Widgets:Button({
        parent = parent,
        labelText = L.SHOW_ON_MAP,
        onClick = function()
          if npc then showOnMap(npc) end
        end,
        onLeave = function()
          local frame = card:GetFrame()
          if frame then updateHighlight(frame) end
        end,
      })
    end,
  })

  --- Sets the NPC shown.
  --- @param newNpc? TameableNPC
  function card:SetNpc(newNpc)
    npc = newNpc
    if not npc then return end

    for _, line in ipairs(textLines) do
      local fontString = line.node:GetFrame()
      if fontString then fontString:SetText(line.getText(npc)) end
    end

    mapButton:SetVisibility(npc.ui_map_id and "VISIBLE" or "GONE")

    local frame = self:GetFrame()
    if frame then updateHighlight(frame) end

    self:MarkDirty()
  end

  return card
end
