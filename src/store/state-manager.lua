local Addon = select(2, ...) ---@type Addon
local E = Addon:GetModule("Events")
local EventManager = Addon:GetModule("EventManager")
local Wux = Addon.Wux

--- @class StateManager
local StateManager = Addon:GetModule("StateManager")

local SAVED_VARIABLES_KEY = "__TAMED_ADDON_DB__"

-- ============================================================================
-- LuaCATS Annotations
-- ============================================================================

--- @class MinimapIconState
--- @field hide boolean

--- @class TamedState
--- @field minimapIcon MinimapIconState
--- @field npc_tooltips boolean

-- ============================================================================
-- ActionTypes
-- ============================================================================

local ActionTypes = {
  PATCH_MINIMAP_ICON = "minimapIcon/patch",
  SET_NPC_TOOLTIPS = "npcTooltips/set",
}

-- ============================================================================
-- DefaultState
-- ============================================================================

--- @type TamedState
local DefaultState = {
  minimapIcon = { hide = false },
  npc_tooltips = true,
}

-- ============================================================================
-- Store
-- ============================================================================

--- @type WuxStore<TamedState>
local _Store

-- Create store once the `Wow.PlayerLogin` event fires.
EventManager:Once(E.Wow.PlayerLogin, function()
  local reducer = Wux:CombineReducers({
    minimapIcon = Wux:CreatePatchReducer(ActionTypes.PATCH_MINIMAP_ICON, DefaultState.minimapIcon),
    npc_tooltips = Wux:CreatePayloadReducer(ActionTypes.SET_NPC_TOOLTIPS, DefaultState.npc_tooltips),
  })

  _Store = Wux:CreateStore(reducer, Wux:ReadSavedVariables(SAVED_VARIABLES_KEY))
  _Store:ConnectSavedVariables(SAVED_VARIABLES_KEY)

  EventManager:Fire(E.StoreCreated)
end)

-- ============================================================================
-- StateManager
-- ============================================================================

--- Returns the underlying Wux store.
--- @return WuxStore<TamedState>
function StateManager:GetStore()
  return _Store
end

--- Returns the current state.
--- @return TamedState
function StateManager:GetState()
  return _Store:GetState()
end

--- Shallow-merges patch into the minimap icon's own state. Fields not
--- present in patch are left as-is.
--- @param patch table
function StateManager:PatchMinimapIcon(patch)
  _Store:Dispatch({ type = ActionTypes.PATCH_MINIMAP_ICON, payload = patch })
end

--- Sets whether NPC tooltips are shown.
--- @param value boolean
function StateManager:SetNpcTooltipsEnabled(value)
  _Store:Dispatch({ type = ActionTypes.SET_NPC_TOOLTIPS, payload = value })
end
