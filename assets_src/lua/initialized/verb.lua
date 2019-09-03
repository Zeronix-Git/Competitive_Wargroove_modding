local Wargroove = require "wargroove/wargroove"
local Resumable = require "wargroove/resumable"
local saveState = require "saveState"

local OldVerb = require "wargroove/verb"
local Verb = {}

function Verb.init()
  -- Overwrite to make UNDO REAL!!!
  OldVerb.executeEntry = function (self, unitId, targetPos, strParam, path)
    print("Executing action!")
    return Resumable.run(function ()
        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
  
        -- Save data
        if(self.id ~= "undo") then
          saveState:save(Wargroove.getCurrentPlayerId())
        end
  
        self:execute(unit, targetPos, strParam, path)
        self:updateSelfUnit(unit, targetPos, path)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
  
        Wargroove.updateUnit(unit)
    end)
  end
  print("Initializing Verb")
end

return Verb