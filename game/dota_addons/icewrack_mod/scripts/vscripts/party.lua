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
    if IsValidEntity(hEntity) and hEntity:IsHero() then
        return self._tPartyRoster[hEntity]
    end
	return false
end

function CIcewrackParty:IsActivePartyMember(hEntity)
    if IsValidEntity(hEntity) and hEntity:IsHero() then
        return self._tActiveMembers[hEntity]
    end
	return false
end

function CIcewrackParty:UnassignMember(hEntity)
    for i=1,5 do
	    if self._tActiveMembers[i] == hEntity then
	        self._tActiveMembers[i] = nil
			self._nActiveMembersSize = self._nActiveMembersSize - 1
			return true
		end
	end
	return false
end

function CIcewrackParty:AssignMember(hEntity, nSlot)
    if self._tPartyRoster[hEntity] then
		if nSlot then
			if nSlot > 0 and nSlot <= 5 and not self._tActiveMembers[nSlot] then
				self._tActiveMembers[nSlot] = hEntity
				self._nActiveMembersSize = self._nActiveMembersSize + 1
				return true
			end
		else
			for i=1,5 do
				if not self._tActiveMembers[i] then
					self._tActiveMembers[i] = hEntity
					self._nActiveMembersSize = self._nActiveMembersSize + 1
					return true
				end
			end
		end
	end
	return false
end

--TODO: Handle having more than 5 party members (i.e. when a party member joins when you already have 5)
function CIcewrackParty:AddMember(hEntity)
    if not IsValidEntity(hEntity) or not hEntity:IsHero() then
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
		self:AssignMember(hEntity)
	end
end
