local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local Reposition = Verb:new()
Reposition.id = "reposition"

function Reposition:getTargetType()
    return "empty"
end

function Reposition:getMaximumRange(unit, endPos)
    return 96
end

function Reposition:onPostUpdateUnit(unit, targetPos, strParam, path)
    unit.pos = targetPos
    --Wargroove.updateUnit(unit)
    unit.hadTurn = false
end

return Reposition
