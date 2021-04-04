local AddonName, Addon = ...
local AceGUI = Addon.Libs.AceGUI
local L = Addon.Libs.L
local pairs = pairs
local TameableAbilities = Addon.TameableAbilities
local UI = Addon.UI
local Widgets = Addon.UI.Widgets

-- ============================================================================
-- Functions
-- ============================================================================

function UI:IsShown()
  return self.frame and self.frame:IsShown()
end

function UI:Toggle()
  if self:IsShown() then
    self:Hide()
  else
    self:Show()
  end
end

function UI:Show()
  if not self.frame then self:Create() end
  self.frame:Show()
end

function UI:Hide()
  if not self.frame then return end
  self.frame:Hide()
end

function UI:Create()
  local frame = AceGUI:Create("Frame")
  frame:SetTitle(AddonName)
  frame:SetWidth(600)
  frame:SetHeight(500)
  frame.frame:SetMinResize(600, 500)
  frame:SetLayout("Flow")
  self.frame = frame

  -- Heading.
  Widgets:Heading(
    frame,
    ("%s: %s"):format(
      L.VERSION,
      "|cFFAAD372" .. Addon.VERSION .. "|r"
    )
  )

  Widgets:Spacer(frame)

  -- Container for the TreeGroup.
  local treeGroupContainer = Widgets:SimpleGroup({
    parent = frame,
    fullWidth = true,
    fullHeight = true,
    layout = "Fill"
  })

  -- Set up groups.
  local treeGroup =  AceGUI:Create("TreeGroup")
  treeGroup:SetLayout("Fill")
  treeGroup:EnableButtonTooltips(false)

  local abilities = {}
  for id, ability in pairs(TameableAbilities) do
    local children = {}

    for i in ipairs(ability.ranks) do
      children[#children+1] = {
        text = "Rank " .. i,
        value = i
      }
    end

    abilities[#abilities+1] = {
      text = ability.name,
      value = id,
      icon = select(3, _G.GetSpellInfo(ability.ranks[1].spell_id)),
      disabled = true,
      children = children
    }
  end

  -- Sort abilities by text.
  table.sort(abilities, function(a, b) return a.text < b.text end)
  treeGroup:SetTree(abilities)

  -- Add `OnGroupSelected` callback.
  treeGroup:SetCallback("OnGroupSelected", function(this, event, key)
    this:ReleaseChildren()

    local parent = AceGUI:Create("ScrollFrame")
    parent:SetLayout("Flow")
    parent:PauseLayout()

    local abilityId, abilityRank = key:match("^(.+)\001(%d+)$")
    local ability = TameableAbilities[abilityId] or error("Invalid ability id: " .. abilityId)
    UI.Ability:Create(parent, ability, tonumber(abilityRank))

    parent:ResumeLayout()
    parent:DoLayout()

    this:AddChild(parent)
  end)

  treeGroup:SelectByPath(abilities[1].value, abilities[1].children[1].value)
  treeGroupContainer:AddChild(treeGroup)

  -- This function should only be called once.
  self.Create = nil
end

do -- Hook "CloseSpecialWindows" to hide UI when Esc is pressed
  local closeSpecialWindows = _G.CloseSpecialWindows
  _G.CloseSpecialWindows = function()
    local found = closeSpecialWindows()

    if UI:IsShown() then
      UI:Hide()
      return true
    end

    return found
  end
end
