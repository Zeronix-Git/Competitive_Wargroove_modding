local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local SaveState = require "SaveState"

local LoadSlot = Verb:new()
LoadSlot.id = "load_slot"

local slotSelectorDist = 1

function LoadSlot:getMaximumRange(unit, endPos)
    return slotSelectorDist * 2
end

function LoadSlot:getTargetType()
    return "all"
end

function LoadSlot:isInSquare(unit, targetPos)
    return math.abs(unit.pos.x - targetPos.x) <= slotSelectorDist and
        math.abs(unit.pos.y - targetPos.y) <= slotSelectorDist
end

function LoadSlot:getSlotId(unit, targetPos)
    local dx = targetPos.x - unit.pos.x + slotSelectorDist
    local dy = targetPos.y - unit.pos.y + slotSelectorDist

    return dx + dy * (1 + slotSelectorDist * 2)
end

function LoadSlot:canExecuteWithTarget(unit, endPos, targetPos, strParam)

    if not LoadSlot:isInSquare(unit, targetPos) then
        return false
    end

    local slotId = LoadSlot:getSlotId(unit, targetPos)
    return SaveState:canLoadSlot(unit.playerId, slotId)
end

function LoadSlot:execute(unit, targetPos, strParam, path)
    local slotId = LoadSlot:getSlotId(unit, targetPos)
    SaveState:loadSlot(unit.playerId, slotId)
end

function LoadSlot:onPostUpdateUnit(unit, targetPos, strParam, path)
    local shiftedPlayerId = SaveState:getUnitShiftedPlayerId(unit.id)
    SaveState:loadOnPost(unit.playerId)
    unit.hadTurn = false
    unit.playerId = shiftedPlayerId
end

return LoadSlot
