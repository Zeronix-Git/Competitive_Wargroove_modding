local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Reposition = Verb:new()
Reposition.id = "reposition"

function Reposition:getTargetType()
    return "empty"
end

function Reposition:canExecuteAnywhere(unit)
    return true
end

function Reposition:execute(unit, targetPos, strParam, path)
    unit.pos = targetPos
    Wargroove.updateUnit(unit)
end

function Reposition:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.hadTurn = false
end

return Reposition
