--[[
	Icewrack Game States
]]

--Game states are variables used to keep track of quests and dialogue

if tIcewrackGameStates == nil then
	tIcewrackGameStates = LoadKeyValues("scripts/npc/iw_game_states.txt")
	--tIcewrackGameStates = LoadKeyValues("scripts/npc/npc_abilities_extended.txt")
	
    if not tIcewrackGameStates then
        error("Could not load key values from game state data")
    end
end