local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local SaveState = require "SaveState"

local UndoTurn = Verb:new()
UndoTurn.id = "undo_turn"

function UndoTurn:canExecuteAnywhere(unit)
    return SaveState:canLoadTurn(unit.playerId)
end

function UndoTurn:execute(unit, targetPos, strParam, path)
    SaveState:loadTurn(unit.playerId)
end

function UndoTurn:onPostUpdateUnit(unit, targetPos, strParam, path)
    local shiftedPlayerId = SaveState:getUnitShiftedPlayerId(unit.id)
    SaveState:loadOnPost(unit.playerId)
    unit.hadTurn = false
    unit.playerId = shiftedPlayerId
end

return UndoTurn
