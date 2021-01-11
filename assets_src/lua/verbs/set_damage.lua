local Wargroove = require "wargroove/wargroove"
local Verb = require "wargroove/verb"

local SetDamage = Verb:new()

function SetDamage:getMaximumRange(unit, endPos)
    return 0
end

function SetDamage:getTargetType()
    return nil
end

function SetDamage:execute(unit, targetPos, strParam, path)
  --TODO: Open a recruit menu and use unit classes as digits 0-9 to set damage for the next encounter
  unit.nextAttackDamage = 42
  unit.nextCounterattackDamage = 31
end

return SetDamage