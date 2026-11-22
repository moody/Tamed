local Addon = select(2, ...) ---@type Addon

--- @class ComponentFactory
local ComponentFactory = Addon:GetModule("ComponentFactory")

--- Width of an NPC card's level column.
ComponentFactory.NPC_CARD_LEVEL_WIDTH = 90

--- Width of an NPC card's location column.
ComponentFactory.NPC_CARD_LOCATION_WIDTH = 140
