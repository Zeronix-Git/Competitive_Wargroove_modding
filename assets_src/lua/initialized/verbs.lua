local Verb = require "wargroove/verbs"
local saveState = require "initialized/saveState"

-- Making UNDO REAL!!!!

function Verb:executeEntry(unitId, targetPos, strParam, path)
  return Resumable.run(function ()
      Wargroove.clearCaches()
      local unit = Wargroove.getUnitById(unitId)

      -- Save data
      saveState.save(getCurrentPlayerId())

      self:execute(unit, targetPos, strParam, path)
      self:updateSelfUnit(unit, targetPos, path)
      self:onPostUpdateUnit(unit, targetPos, strParam, path)

      Wargroove.updateUnit(unit)
  end)
end

return Verb