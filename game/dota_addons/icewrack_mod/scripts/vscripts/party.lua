--[[
    Party System
]]

require("ext_entity")

if CIcewrackParty == nil then
    CIcewrackParty = { _tPartyRoster = {},   _nPartyRosterSize = 0,
                       _tActiveMembers = {}, _nActiveMembersSize = 0 }
end

function CIcewrackParty:GetActiveMembers()
    return self._tActiveMembers
end

function CIcewrackParty:GetAllMembers()
	return self._tPartyRoster
end

function CIcewrackParty:GetActiveSize()
	return self._nActiveMembersSize
end

function CIcewrackParty:GetRosterSize()
	return self._nPartyRosterSize
end

function CIcewrackParty:IsPartyMember(hEntity)
    if hEntity and hEntity:IsHero() then
        return self._tPartyRoster[hEntity]
    end
	return false
end

function CIcewrackParty:IsActivePartyMember(hEntity)
    if hEntity and hEntity:IsHero() then
        return self._tActiveMembers[hEntity]
    end
	return false
end

function CIcewrackParty:SetMemberState(hEntity, bState)
    if self._tPartyRoster[hEntity] ~= nil then
		if bState == true and self._nActiveMembersSize >= 5 then
			return
		end
        self._tPartyRoster[hEntity] = bState
		if bState == false then
			table.remove(self._tActiveMembers, hEntity)
			self._nActiveMembersSize = self._nActiveMembersSize - 1
		else
			table.insert(self._tActiveMembers, hEntity)
			self._nActiveMembersSize = self._nActiveMembersSize + 1
		end
    end
end

--Note: This allows you to have more than 5 heroes active at any one time, but you can only have 5 heroes when you leave camp.
function CIcewrackParty:AddMember(hEntity)
    if not hEntity or not hEntity:IsHero() then
        error("hEntity must be a valid hero entity")
    end
	
	--This allows party members to interact with NPCs
	if not hEntity:HasModifier("internal_npc_interact") then
		hEntity:AddAbility("internal_npc_interact")
		hEntity:FindAbilityByName("internal_npc_interact"):ApplyDataDrivenModifier(hEntity, hEntity, "modifier_internal_npc_interact", {})
		hEntity:RemoveAbility("internal_npc_interact")
	end
	
	if self._tPartyRoster[hEntity] == nil then
		self._tPartyRoster[hEntity] = true
		self._nPartyRosterSize = self._nPartyRosterSize + 1
		table.insert(self._tActiveMembers, hEntity)
		self._nActiveMembersSize = self._nActiveMembersSize + 1
	end
end
