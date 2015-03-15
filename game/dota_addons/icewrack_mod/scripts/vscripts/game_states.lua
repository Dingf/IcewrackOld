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
	
	Convars:RegisterCommand("iw_ui_dialogue_postcondition",
		function(szCmdName, szArgs)
			local szName = nil
			local nValue = nil
			for k in string.gmatch(szArgs, "%g+") do
				if szName == nil then
					szName = k
				elseif nValue == nil then
					nValue = tonumber(k)
				else
					break
				end
			end
			if CIcewrackGameState._tValues[szName] then
				CIcewrackGameState._tValues[szName] = nValue
			end
		end, "", 0)
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

function EvaluatePrecondition(szName, szCondition)
	local tGameStateValues = CIcewrackGameState._tValues
	if tGameStateValues[szName] ~= nil then
		szOperator = nil
		nValue = nil
		for k in string.gmatch(szCondition, "%g+") do
			if szOperator == nil then
				szOperator = k
			elseif nValue == nil then
				nValue = tonumber(k)
			else
				break
			end
		end
		
		if szOperator and nValue then
			if szOperator == "==" then
				return tGameStateValues[szName] == nValue
			elseif szOperator == "!=" then
				return tGameStateValues[szName] ~= nValue
			elseif szOperator == ">" then
				return CIcewrackGameState._tValues[szName] > nValue
			elseif szOperator == ">=" then
				return CIcewrackGameState._tValues[szName] >= nValue
			elseif szOperator == "<" then
				return CIcewrackGameState._tValues[szName] < nValue
			elseif szOperator == "<=" then
				return CIcewrackGameState._tValues[szName] <= nValue
			else
				return false
			end
		end
	end
	return false
end