local Wargroove = require "wargroove/wargroove"
local Resumable = require "wargroove/resumable"
local saveState = require "saveState"

local OldVerb = require "wargroove/verb"
local Verb = {}

function Verb.init()
  OldVerb.executeEntry = function (self, unitId, targetPos, strParam, path)
    return Resumable.run(function ()
        -- Save data before getting unit
        if(self.id ~= "undo") then
          saveState:save(Wargroove.getCurrentPlayerId())
        end

        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
  
        self:execute(unit, targetPos, strParam, path)
        self:updateSelfUnit(unit, targetPos, path)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
  
        Wargroove.updateUnit(unit)
    end)
  end
end

return Verb