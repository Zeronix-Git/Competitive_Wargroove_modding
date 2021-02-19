local Wargroove = require "wargroove/wargroove"
local Events = require "wargroove/events"
local utils = require "utils"

-- Savestate is a global variable. This builds saveState if it doesn't exist, but lets it be otherwise

if(not SaveState) then

    SaveState = {}
    SaveState.lastState = nil
    SaveState.deltaTurn = 0
    SaveState.deltaPlayer = 0
    SaveState.slots = {}

    --
    -- Override these
    --

    function SaveState:modSpecificSave(newState)
    end

    function SaveState:modSpecificLoad(playerId)
    end

    function SaveState:modSpecificLoadOnPost(playerId)
    end


    --
    -- Functions to get and set playerId / turnNumber realtive to the current state
    --

    function SaveState:updateDeltaPlayer(playerId, statePlayerId)
        local n = Wargroove.getNumPlayers(false)
        SaveState.deltaPlayer = (n + playerId - statePlayerId)  % n
    end

    function SaveState:updateDeltaTurn(statePlayerId, stateTurnNumber)
        local n = Wargroove.getNumPlayers(false)
        local gameTurn = (Wargroove.getTurnNumber() - 1) * n + Wargroove.getCurrentPlayerId()
        SaveState.deltaTurn = (stateTurnNumber - 1) * n + statePlayerId - gameTurn
    end

    function SaveState:getShiftedPlayerId(playerId, back)
        if(playerId < 0) then
            return playerId
        end

        local n = Wargroove.getNumPlayers(false)
        local side = back and 1 or -1
        return (playerId + (SaveState.deltaPlayer * side) + n) % n
    end

    function SaveState:getShiftedTurnNumber()
        --local playerId = Wargroove.getPlayerId()
        local n = Wargroove.getNumPlayers(false)
        local turn = (Wargroove.getTurnNumber() - 1) * n + SaveState.deltaTurn

        return (turn - (turn % n)) / n + 1
    end

    function SaveState:getUnitShiftedPlayerId(unitId)

        return self:getShiftedPlayerId(SaveState.lastState.units[unitId].playerId)
    end


    --
    -- Functions to generate and save states
    --

    function SaveState:save(playerId)
        local newState = self:generate(playerId)
        SaveState.lastState = newState

        -- Extensible section if this module is used in other mods
        self:modSpecificSave(newState)
    end

    function SaveState:saveSlot(playerId, index)
        index = tonumber(index)
        SaveState.slots[index] = self:generate(playerId)
    end

    function SaveState:generate(playerId)
        --[[if not self:canLoad(playerId) then
            -- Flush savestate
            for i, _ in ipairs(saveState.lastState) do
                saveState.lastState[i] = nil
            end
        end]]

        local newState = {}
        -- Save your players' gold values
        newState.gold = {}
        for id = 0, Wargroove.getNumPlayers(false)-1 do
            local realId = SaveState:getShiftedPlayerId(id, true)
            newState.gold[realId] = Wargroove.getMoney(id)
        end

        -- Save states of all units
        local saveUnits = {}
        for _, unit in ipairs(Wargroove.getUnitsAtLocation()) do
            -- Copy unit into saveUnits
            local copiedTable = utils:copyTable(unit)
            saveUnits[unit.id] = copiedTable
            copiedTable.playerId = SaveState:getShiftedPlayerId(unit.playerId, true)
        end
        newState.units = saveUnits

        -- Save map counters, flags, campaign flags, party and fired triggers
        newState.matchState = Events.getMatchState()
        
        newState.playerId = SaveState:getShiftedPlayerId(playerId, true)
        newState.turnNumber = SaveState:getShiftedTurnNumber(playerId, newState.playerId)

        local prevState = SaveState.lastState
        newState.prevState = prevState
        
        if (prevState and
            prevState.turnNumber == newState.turnNumber and
            prevState.playerId == newState.playerId
        ) then
            newState.turnStartState = prevState.turnStartState
            
        else -- this is a new state after "End Turn"
            newState.turnStartState = newState
        end

        return newState
    end

    --
    -- Functions to load states
    --

    function SaveState:getTurnStartState()
        return SaveState.lastState and SaveState.lastState.turnStartState
    end

    function SaveState:canLoad(playerId, state)
        
        if state == nil then
            state = SaveState.lastState
        end

        return state ~= nil
            --[[(saveState.lastState ~= nil and
            saveState.lastState[#saveState.lastState].playerId == playerId and
            saveState.lastState[#saveState.lastState].turnNumber == Wargroove.getTurnNumber())]]
    end

    function SaveState:canLoadTurn(playerId)
        local state = self:getTurnStartState()
        if state == nil then
            return false
        end

        local lastState = SaveState.lastState

        return lastState ~= state and
            lastState.playerId == state.playerId and
            lastState.turnNumber == state.turnNumber
    end

    function SaveState:canLoadSlot(playerId, index)
        index = tonumber(index)
        local state = SaveState.slots[index]
        if state == nil then
            return false
        end

        --[[if state.prevState == SaveState.lastState then
            return false
        end]]

        return true
    end

    function SaveState:load(playerId)
        local state = SaveState.lastState
        self:updateDeltaPlayer(playerId, state.playerId)
        self:updateDeltaTurn(state.playerId, state.turnNumber)

        --self:showCurrentStatus()

        -- Load gold
        for id = 0, Wargroove.getNumPlayers(false)-1 do
            local gameId = self:getShiftedPlayerId(id)
            Wargroove.setMoney(gameId, state.gold[id])
        end

        -- Load map counters
        local matchState = Events.getMatchState()
        matchState = state.matchState

        -- Reset Match State so triggers will now recognize changed counters and flags
        Events.startSession(matchState)

        -- Extensible section if this module is used in other mods
        self:modSpecificLoad(playerId)
    end

    function SaveState:loadTurn(playerId)
        SaveState.lastState = self:getTurnStartState()
        self:load(playerId)
    end

    function SaveState:loadSlot(playerId, index)
        SaveState.lastState = SaveState.slots[index]
        self:load(playerId)
    end

    function SaveState:loadOnPost(playerId)
        local state = SaveState.lastState

        local units = utils:copyTable(state.units)

        for _, unit in pairs(units) do
            unit.playerId = self:getShiftedPlayerId(unit.playerId)
        end

        for _, unit in ipairs(Wargroove.getUnitsAtLocation()) do
            if(units[unit.id] ~= nil) then
                -- We are copying over instead of changing the reference because we don't save unitClass
                unit = units[unit.id]
                Wargroove.updateUnit(unit)

                units[unit.id] = nil
            else
                -- This unit did not exist before. Kill it
                unit:setHealth(0, unit.id)
                Wargroove.updateUnit(unit)
            end
        end

        -- Bring units BACK
        for _, unit in pairs(units) do
            if unit.pos.x >= 0 and unit.pos.y >= 0 then
                self:spawnCopy(unit.id, units)
            end
        end

        -- Extensible section if this module is used in other mods
        self:modSpecificLoadOnPost(playerId)

        -- Change lastState to prevState so players can't undo into the same state multiple times
        --Wargroove.setTurnInfo(state.turnNumber, state.playerId)
        SaveState.lastState = state.prevState
    end


    -- Copies a unit description to spawn an exact copy of the unit at the same position and
    -- return that unit's table
    function SaveState:spawnCopy(unitId, allUnits)
        local unitInfo = allUnits[unitId]
        Wargroove.spawnUnit(unitInfo.playerId, unitInfo.pos, unitInfo.unitClassId, unitInfo.hadTurn)

        Wargroove.waitFrame()
        
        -- Health
        local unit = Wargroove.getUnitAt(unitInfo.pos)
        unit:setHealth(unitInfo.health, unit.id)

        -- Loaded units
        for _, id in ipairs(unitInfo.loadedUnits) do
            local transportedUnit = self:spawnCopy(id, allUnits)
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

    function SaveState:showCurrentStatus()
        Wargroove.showMessage(
            "Current turn: " .. self:getShiftedTurnNumber()
            -- .. ', Current Delta Turn: ' .. SaveState.deltaTurn ..
            .. ", Current player: " .. self:getShiftedPlayerId(Wargroove.getCurrentPlayerId())
            -- .. ', Current Delta Player: ' .. SaveState.deltaPlayer
        )
    end

end

return SaveState