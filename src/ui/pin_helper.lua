local AddonName, Addon = ...
local HBDPins = Addon.Libs.HBDPins
local L = Addon.Locale
local PinHelper = Addon.UI.PinHelper

local pins = {}
local pool = {}
local count = 0

-- ============================================================================
-- Callbacks
-- ============================================================================

local function onEnter(self)
  -- Show highlight
  self.highlight:SetAlpha(0.4)
  -- Show tooltip
  _G.GameTooltip:SetOwner(self, "ANCHOR_RIGHT")
  _G.GameTooltip:SetText(self.npc.name)
  _G.GameTooltip:AddDoubleLine(L.LEVEL, self.npc.level_range, 1, 1, 1, 1, 1, 1)
  _G.GameTooltip:AddDoubleLine(L.DIET, self.npc.diet, 1, 1, 1, 1, 1, 1)
  _G.GameTooltip:AddDoubleLine(L.FAMILY, self.npc.family, 1, 1, 1, 1, 1, 1)
  _G.GameTooltip:AddDoubleLine(L.TYPE, self.npc.type, 1, 1, 1, 1, 1, 1)
  _G.GameTooltip:AddDoubleLine(L.LOCATION, self.npc.location, 1, 1, 1, 1, 1, 1)
  _G.GameTooltip:AddLine(("<%s>"):format(L.CLICK_TO_CLEAR), 0.6, 0.6, 0.6)
  _G.GameTooltip:Show()
end

local function onLeave(self)
  self.highlight:SetAlpha(0)
  _G.GameTooltip:Hide()
end

local function onClick(self)
  PinHelper:Clear()
end

-- ============================================================================
-- Functions
-- ============================================================================

function PinHelper:Get(npc)
  local pin = next(pool)

  if pin then
    pool[pin] = nil
  else
    count = count + 1
    pin = _G.CreateFrame("Button", AddonName.."Pin"..count, _G.WorldMapFrame)
    pin:SetSize(20, 20)

    pin.texture = pin:CreateTexture(AddonName.."PinTexture"..count, "BACKGROUND")
    pin.texture:SetTexture(Addon.ICON)
    pin.texture:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    pin.texture:SetAllPoints()

    pin.highlight = pin:CreateTexture(pin:GetName().."Hightlight", "HIGHLIGHT")
    pin.highlight:SetTexture(Addon.ICON)
    pin.highlight:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    pin.highlight:SetBlendMode("ADD")
    pin.highlight:SetAlpha(0)
    pin.highlight:SetAllPoints(pin.texture)

    pin:SetScript("OnEnter", onEnter)
    pin:SetScript("OnLeave", onLeave)
    pin:SetScript("OnClick", onClick)

    pins[#pins+1] = pin
  end

  pin.npc = npc
  pin:Show()
  return pin
end

function PinHelper:Clear()
  for _, pin in next, pins do
    pin:Hide()
    pool[pin] = true
  end
  HBDPins:RemoveAllWorldMapIcons(Addon)
end

function PinHelper:Hide()
  for _, pin in next, pins do pin:Hide() end
end
