local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local SaveState = require "SaveState"

local SaveSlot = Verb:new()
SaveSlot.id = "save_slot"

local slotSelectorDist = 1

function SaveSlot:getMaximumRange(unit, endPos)
    return slotSelectorDist * 2
end

function SaveSlot:getTargetType()
    return "all"
end

function SaveSlot:isInSquare(unit, targetPos)
    return math.abs(unit.pos.x - targetPos.x) <= slotSelectorDist and
        math.abs(unit.pos.y - targetPos.y) <= slotSelectorDist
end

function SaveSlot:getSlotId(unit, targetPos)
    local dx = targetPos.x - unit.pos.x + slotSelectorDist
    local dy = targetPos.y - unit.pos.y + slotSelectorDist

    return dx + dy * (1 + slotSelectorDist * 2)
end

function SaveSlot:canExecuteWithTarget(unit, endPos, targetPos, strParam)
    return SaveSlot:isInSquare(unit, targetPos)
end

function SaveSlot:execute(unit, targetPos, strParam, path)
    local slotId = SaveSlot:getSlotId(unit, targetPos)
    SaveState:saveSlot(unit.playerId, slotId)
end

function SaveSlot:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
end

return SaveSlot
