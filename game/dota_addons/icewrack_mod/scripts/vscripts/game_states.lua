--[[
	Icewrack Game States
]]

--Game states are variables used to keep track of quests and dialogue

if CIcewrackGameState == nil then
	CIcewrackGameState = {}
	CIcewrackGameState._tValues = LoadKeyValues("scripts/npc/iw_game_states.txt")
	
    if not CIcewrackGameState._tValues then
        error("Could not load key values from game state data")
    end
end

function GetGameStateValue(szName)
	return CIcewrackGameState._tValues[szName]
end

function SetGameStateValue(szName, nValue)
	if CIcewrackGameState._tValues[szName] then
		CIcewrackGameState._tValues[szName] = nValue
		FireGameEvent("iw_ui_gamestate_update", { state_name = szName, state_value = nValue })
	end
end