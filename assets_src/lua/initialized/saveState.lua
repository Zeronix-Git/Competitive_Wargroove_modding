local Wargroove = require "wargroove/wargroove"

local saveState = {}
saveState.loadedState = {}

--
-- Override these
--

function saveState.modSpecificSave(newState)
end

function saveState.modSpecificLoad(playerId)
end


--
-- Saving and Undoing Scripts
--

function saveState.save(playerId)
    local newState = {}
    -- Gold
    newState.gold = Wargroove.getMoney(playerId)

    -- Units

    -- Map Counters

    -- Map Flags

      modSpecificSave(newState)
      
      saveState.loadedState[playerId] = newState
end

function saveState.canLoad(playerId)
    return (saveState.loadedState[playerId] ~= nil)
end

function saveState.load(playerId)
    -- Gold
    Wargroove.setMoney(playerId, saveState.loadedState[playerId].gold)

    -- Units

    -- Map Counters

    -- Map Flags

      modSpecificLoad(playerId)
      
      saveState.loadedState[playerId] = nil
end

return saveState
