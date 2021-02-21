local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"
local SaveState = require "SaveState"

local Undo = Verb:new()
Undo.id = "undo"

function Undo:canExecuteAnywhere(unit)
    return SaveState:canLoad(unit.playerId)
end

function Undo:execute(unit, targetPos, strParam, path)
    SaveState:load(unit.playerId)
end

function Undo:onPostUpdateUnit(unit, targetPos, strParam, path)
    local shiftedPlayerId = SaveState:getUnitShiftedPlayerId(unit.id)
    SaveState:loadOnPost(unit.playerId)
    unit.hadTurn = false
    unit.playerId = shiftedPlayerId
end

return Undo
