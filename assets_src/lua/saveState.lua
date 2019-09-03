local Wargroove = require "wargroove/wargroove"

-- Savestate is a global variable. This builds saveState if it doesn't exist, but lets it be otherwise

if(not saveState) then

  saveState = {}
  saveState.loadedState = {}

  print("Reloading saveState")
  print("Loaded state", saveState.loadedState)

  --
  -- Override these
  --

  function saveState:modSpecificSave(newState)
  end

  function saveState:modSpecificLoad(playerId)
  end


  --
  -- Saving and Undoing Scripts
  --

  function saveState:save(playerId)

      local newState = {}
      -- Gold
      print(playerId, Wargroove.getMoney(playerId))
      newState.gold = Wargroove.getMoney(playerId)
      print("Now:", newState.gold, newState)

      -- Units

      -- Map Counters

      -- Map Flags

      self:modSpecificSave(newState)
      
      saveState.loadedState[playerId] = newState
  end

  function saveState:canLoad(playerId)
      return (saveState.loadedState[playerId] ~= nil)
  end

  function saveState:load(playerId)
      print(playerId)
      print(saveState.loadedState[playerId].gold)
      -- Gold
      Wargroove.setMoney(playerId, saveState.loadedState[playerId].gold)

      -- Units

      -- Map Counters

      -- Map Flags

      self:modSpecificLoad(playerId)
        
      saveState.loadedState[playerId] = nil
  end

end

return saveState
