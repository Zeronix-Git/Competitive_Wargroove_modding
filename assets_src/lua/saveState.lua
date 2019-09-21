local Wargroove = require "wargroove/wargroove"
local Events = require "wargroove/events"

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
        -- Save your players' gold values
        newState.gold = {}
        for id = 0, Wargroove.getNumPlayers(false)-1 do
            newState.gold[id] = Wargroove.getMoney(id)
        end

        -- Save states of all units
        saveUnits = {}
        for _, unit in ipairs(Wargroove.getUnitsAtLocation()) do
            -- Copy unit into saveUnits
            local copiedTable = self:copyTable(unit)
            --print(copiedTable.id, saveUnits[unit.id]) -- here for testing purposes
            saveUnits[unit.id] = copiedTable
        end
        newState.units = saveUnits

        -- Save map counters, flags, campaign flags, party and fired triggers
        newState.matchState = Events.getMatchState()

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
        for id = 0, Wargroove.getNumPlayers(false)-1 do
            Wargroove.setMoney(id, saveState.loadedState.gold[id])
        end

        -- Load map counters
        local matchState = Events.getMatchState()
        matchState = saveState.loadedState.matchState

        -- Reset Match State so triggers will now recognize changed counters and flags
        Events.startSession(matchState)

        -- Extensible section if this module is used in other mods
        self:modSpecificLoad(playerId)
    end

    function saveState:respawnedUnitCorrections(unit, unitInfo)
        print("Setting " .. unit.unitClassId .. "'s health to", unitInfo.health)
        unit:setHealth(unitInfo.health, unit.id)
    end

    function saveState:loadOnPost(playerId)
        for _, unit in ipairs(Wargroove.getUnitsAtLocation()) do
            if(saveState.loadedState.units[unit.id] ~= nil) then
                -- We are copying over instead of changing the reference because we don't save unitClass
                self:overrideTable(unit, saveState.loadedState.units[unit.id])
                saveState.loadedState.units[unit.id] = nil
                Wargroove.updateUnit(unit)
            else
                -- This unit did not exist before. Kill it
                unit:setHealth(0, unit.id)
                Wargroove.updateUnit(unit)
            end
        end

        -- Bring units BACK
        -- SELF: Should this keep dying units alive and bring them back if necessary or just reset their values?
        -- Probably reset values for generality and modularity's sake
        for _, unit in pairs(saveState.loadedState.units) do
            print("Unit ", unit, unit.unitClassId)
            Wargroove.spawnUnit(unit.playerId, unit.pos, unit.unitClassId, unit.hadTurn)
            
            Wargroove.waitFrame()

            print("Unit", unit.unitClassId, Wargroove.getUnitAt(unit.pos))
            self:respawnedUnitCorrections(Wargroove.getUnitAt(unit.pos), unit)
        end

        -- Extensible section if this module is used in other mods
        self:modSpecificLoadOnPost(playerId)

        -- Clear loadedState so players can't undo into the same state multiple times
        saveState.loadedState = nil
    end

end

return saveState

-- Todo:
-- Resurrecting dead units
-- Deep copy of unit tables and changing references rather than copying back and over(?)
-- Test how much memory having, say, 50 states uses on the system
-- If the memory is too high, change it so each state only tracks changes to the game map