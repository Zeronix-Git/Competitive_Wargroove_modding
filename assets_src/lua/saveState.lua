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
                copy[orig_key] = self:copyTable(orig_value)
            end
        else -- number, string, boolean, etc
            copy = orig
        end
        return copy
    end

    function saveState:save(playerId)
        if saveState.loadedState[#saveState.loadedState].playerId ~= playerId
            or saveState.loadedState[#saveState.loadedState].turnNumber ~= Wargroove.getTurnNumber() then
            -- Flush savestate
            for i, _ in ipairs(saveState.loadedState) do
                saveState.loadedState[i] = nil
            end
        end

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
            saveUnits[unit.id] = copiedTable
        end
        newState.units = saveUnits

        -- Save map counters, flags, campaign flags, party and fired triggers
        newState.matchState = Events.getMatchState()

        -- Extensible section if this module is used in other mods
        self:modSpecificSave(newState)
        
        newState.playerId = playerId
        table.insert(saveState.loadedState, newState)
        print(#saveState.loadedState)
    end

    function saveState:canLoad(playerId)
        return (saveState.loadedState[#saveState.loadedState] ~= nil and saveState.loadedState[#saveState.loadedState].playerId == playerId)
    end

    function saveState:load(playerId)
        -- Load gold
        for id = 0, Wargroove.getNumPlayers(false)-1 do
            Wargroove.setMoney(id, saveState.loadedState[#saveState.loadedState].gold[id])
        end

        -- Load map counters
        local matchState = Events.getMatchState()
        matchState = saveState.loadedState[#saveState.loadedState].matchState

        -- Reset Match State so triggers will now recognize changed counters and flags
        Events.startSession(matchState)

        -- Extensible section if this module is used in other mods
        self:modSpecificLoad(playerId)
    end

    function saveState:loadOnPost(playerId)
        for _, unit in ipairs(Wargroove.getUnitsAtLocation()) do
            if(saveState.loadedState[#saveState.loadedState].units[unit.id] ~= nil) then
                -- We are copying over instead of changing the reference because we don't save unitClass
                unit = saveState.loadedState[#saveState.loadedState].units[unit.id]
                Wargroove.updateUnit(unit)

                saveState.loadedState[#saveState.loadedState].units[unit.id] = nil
            else
                -- This unit did not exist before. Kill it
                unit:setHealth(0, unit.id)
                Wargroove.updateUnit(unit)
            end
        end

        -- Bring units BACK
        for _, unit in pairs(saveState.loadedState[#saveState.loadedState].units) do
            if unit.pos.x >= 0 and unit.pos.y >= 0 then
                self:spawnCopy(unit, saveState.loadedState[#saveState.loadedState].units)
            end
        end

        -- Extensible section if this module is used in other mods
        self:modSpecificLoadOnPost(playerId)

        -- Clear loadedState so players can't undo into the same state multiple times
        saveState.loadedState[#saveState.loadedState] = nil
    end

    -- Copies a unit description to spawn an exact copy of the unit at the same position and
    -- return that unit's table
    function saveState:spawnCopy(unitId, allUnits)
        local unitInfo = allUnits[unitId]
        Wargroove.spawnUnit(unitInfo.playerId, unitInfo.pos, unitInfo.unitClassId, unitInfo.hadTurn)

        Wargroove.waitFrame()
        
        -- Health
        local unit = Wargroove.getUnitAt(unitInfo.pos)
        unit:setHealth(unitInfo.health, unit.id)

        -- Loaded units
        for _, id in ipairs(unitInfo.loadedUnits) do
            local transportedUnit = self:spawnCopy(allUnits[id], allUnits)
            local Load = require "verbs/load"
            Load:execute(transportedUnit, unitInfo.pos, "")
        end
        
        -- State
        unit.state = unitInfo.state

        -- Groove Charge
        unit.grooveCharge = unitInfo.grooveCharge

        Wargroove.updateUnit(unit)

        return unit
    end

end

return saveState

-- Not undoing if the turn is different