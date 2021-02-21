local Wargroove = require "wargroove/wargroove"
local Resumable = require "wargroove/resumable"
local SaveState = require "SaveState"

local OldVerb = require "wargroove/verb"
local Verb = {}

local excludedVerbs = {
  undo=true,
  undo_turn=true,
  save_slot=true,
  load_slot=true
}

function Verb.init()
  OldVerb.executeEntry = function (self, unitId, targetPos, strParam, path)
    return Resumable.run(function ()
        -- Save data before getting unit
        if not excludedVerbs[self.id] then
          SaveState:save(Wargroove.getCurrentPlayerId())
        end

        Wargroove.clearCaches()
        local unit = Wargroove.getUnitById(unitId)
  
        self:execute(unit, targetPos, strParam, path)
        self:updateSelfUnit(unit, targetPos, path)
        self:onPostUpdateUnit(unit, targetPos, strParam, path)
  
        Wargroove.updateUnit(unit)

        Wargroove.setMetaLocationArea("last_move_path", path)
        Wargroove.setMetaLocation("last_unit", unit.pos)
    end)
  end
end

return Verb