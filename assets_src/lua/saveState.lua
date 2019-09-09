local Wargroove = require "wargroove/wargroove"

-- Savestate is a global variable. This builds saveState if it doesn't exist, but lets it be otherwise

if(not saveState) then

    saveState = {}
    saveState.loadedState = {}

    --
    -- Override these
    --

    function saveState:modSpecificSave(newState)
    end

    function saveState:modSpecificLoad(playerId)
    end

    function saveState:modSpecificLoadOnPost(playerId)
    end


    --
    -- Saving and Undoing Scripts
    --

    function saveState:copyTable(orig)
        local copy
        if type(orig) == 'table' then
            copy = {}
            for orig_key, orig_value in pairs(orig) do
                if(orig_key ~= "unitClass") then
                    copy[orig_key] = self:copyTable(orig_value)
                end
            end
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end

    function saveState:overrideTable(rep, orig)
        for orig_key, orig_value in pairs(orig) do
            rep[orig_key] = orig_value
        end
    end

    function saveState:save(playerId)
        local newState = {}
        -- Save your player's gold value
        newState.gold = Wargroove.getMoney(playerId)

        -- Save states of all units
        saveUnits = {}
        for _, unit in ipairs(Wargroove.getUnitsAtLocation()) do
            -- Copy unit into saveUnits
            local copiedTable = self:copyTable(unit)
            print(copiedTable.id)
            table.insert(saveUnits, copiedTable)
        end
        newState.units = saveUnits

        -- Extensible section if this module is used in other mods
        self:modSpecificSave(newState)
        
        newState.playerId = playerId
        saveState.loadedState = newState
    end

    function saveState:canLoad(playerId)
        return (saveState.loadedState ~= nil and saveState.loadedState.playerId == playerId)
    end

    function saveState:load(playerId)
        -- Load gold
        Wargroove.setMoney(playerId, saveState.loadedState.gold)

        -- Extensible section if this module is used in other mods
        self:modSpecificLoad(playerId)
    end

    function saveState:loadOnPost(playerId)
        for _, unit in ipairs(saveState.loadedState.units) do
            local u = Wargroove.getUnitById(unit.id)
            self:overrideTable(u, unit)
            Wargroove.updateUnit(u)
        end

        -- Extensible section if this module is used in other mods
        self:modSpecificLoadOnPost(playerId)

        -- Clear loadedState so players can't undo into the same state multiple times
        saveState.loadedState = nil
    end

end

return saveState

-- Todo:
-- When loading, check if there are any NEW units, and destroy them
-- Save and load gold of other players
-- Save and load map counters and flags
-- Save and load trigger flags
