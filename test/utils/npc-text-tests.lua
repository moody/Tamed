--- @diagnostic disable: undefined-global, missing-fields

local Harness = require("test/harness")

-- ============================================================================
-- Setup
-- ============================================================================

--- Returns `NpcText` from a new context. Each color wraps its text in a tag with the color's name.
--- @return NpcText NpcText
local function setupContext()
  local Context = Harness:NewContext()

  local Colors = {}
  for _, name in ipairs({ "DimGrey", "Gold", "Grey", "White" }) do
    Colors[name] = function(text) return ("<%s>%s</%s>"):format(name, text, name) end
  end
  Context:SetModule("Colors", Colors)
  Context:SetModule("Locale", { RANK = "Rank" })

  Context:Load("src/utils/npc-text.lua")

  return Context:GetModule("NpcText")
end

--- Returns an ability with the given name and icon.
--- @param name string
--- @param icon integer
--- @return table
local function mockAbility(name, icon)
  return { name = name, icon = icon }
end

-- ============================================================================
-- Tests - NpcText:Ability()
-- ============================================================================

-- Test: shows the icon, the name in white, and the rank in grey.
do
  local NpcText = setupContext()
  local npcAbility = { ability = mockAbility("Claw", 132), rank = 2 }
  assert(NpcText:Ability(npcAbility) == "|T132:0|t <White>Claw</White> <Grey>(Rank 2)</Grey>")
end

-- Test: dims the name and rank together when dimmed.
do
  local NpcText = setupContext()
  local npcAbility = { ability = mockAbility("Claw", 132), rank = 2 }
  assert(NpcText:Ability(npcAbility, true) == "|T132:0|t <DimGrey>Claw (Rank 2)</DimGrey>")
end

-- ============================================================================
-- Tests - NpcText:Abilities()
-- ============================================================================

-- Test: joins the abilities with commas, in order.
do
  local NpcText = setupContext()
  local npc = {
    abilities = {
      { ability = mockAbility("Bite", 1), rank = 1 },
      { ability = mockAbility("Claw", 2), rank = 3 },
    },
  }

  assert(NpcText:Abilities(npc) == "|T1:0|t <White>Bite</White> <Grey>(Rank 1)</Grey>, "
    .. "|T2:0|t <White>Claw</White> <Grey>(Rank 3)</Grey>")
end

-- ============================================================================
-- Tests - NpcText:Level()
-- ============================================================================

-- Test: returns the level range when the NPC has no classification.
do
  local NpcText = setupContext()
  assert(NpcText:Level({ level_range = "12-14" }) == "12-14")
end

-- Test: adds the classification in gold.
do
  local NpcText = setupContext()
  assert(NpcText:Level({ level_range = "12-14", classification = "Rare" }) == "12-14 (<Gold>Rare</Gold>)")
end
