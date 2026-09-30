local Addon = select(2, ...) ---@type Addon
local Widgets = Addon:GetModule("Widgets")
local Waffle = Addon.Waffle

--- @class RankScreen
local RankScreen = Addon:GetModule("RankScreen")

-- ============================================================================
-- RankScreen
-- ============================================================================

--- Builds and returns a root component describing the Rank Screen.
--- @return RankScreenComponent root
function RankScreen:Build()
  --- @class RankScreenComponent : WaffleFlexComponent
  local root = Waffle:Flex({
    visibility = "GONE",
    -- height = "AUTO",
    gap = Widgets:Padding()
  })

  --- Shows the given rank.
  --- @param ability TameableAbility
  --- @param rank TameableAbilityRank
  function root:SetRank(ability, rank)
    -- TODO
  end

  return root
end
