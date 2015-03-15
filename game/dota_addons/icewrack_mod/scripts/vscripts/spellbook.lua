--[[
    Icewrack Spellbook
]]

require("ext_entity")

if CIcewrackSpellbook == nil then
	CIcewrackSpellbook = class({
		constructor = function(self, hEntity)
			if not hEntity or not hEntity._bIsExtendedEntity then
				error("hEntity must be a valid extended entity")
			end
			
			self._bIsSpellbook = true
			self._hEntity = hEntity
			hEntity._hSpellbook = self
			
			self._tKnownAbilities = {}
			self._tBoundAbilities = {}
			for i=0,(hEntity:GetAbilityCount() - 1) do
				local hAbility = hEntity:GetAbilityByIndex(i)
				if hAbility then
					if string.find(hAbility:GetAbilityName(), "ui_spellbar_empty") == nil then
						self._tKnownAbilities[hAbility:GetAbilityName()] = hAbility:GetLevel()
					end
					self._tBoundAbilities[i] = hAbility:GetAbilityName()
				end
			end
		end},
		--TODO: Change these to user-set binds instead
		{ _shActiveSpellbook = nil,
		  _stKeybindTable = {[0] = "1", [1] = "2", [2] = "3", [3] = "4", [4] = "5", [5] = "6"}}, nil)
end

function CIcewrackSpellbook:UnbindAbility(nSlot)
	if self._tBoundAbilities[nSlot] and string.find(self._tBoundAbilities[nSlot], "ui_spellbar_empty") == nil then
		local hEntity = self._hEntity
		local hAbility = hEntity:FindAbilityByName(self._tBoundAbilities[nSlot])
		if hAbility then
			local szAbilityName = hAbility:GetAbilityName()
			local szEmptySlotName = "ui_spellbar_empty" .. (nSlot + 1)
			hEntity:AddAbility(szEmptySlotName)
			hEntity:SwapAbilities(szEmptySlotName, szAbilityName, true, true)
			hEntity:RemoveAbility(szAbilityName)
			self._tBoundAbilities[nSlot] = szEmptySlotName
			self._bRefreshFlag = true
		end
	end
end

function CIcewrackSpellbook:BindAbility(szNewAbilityName, nSlot)
	nSlot = math.floor(nSlot)
	if nSlot < 0 or nSlot >= 6 then
		error("nSlot must be between an integer between [0, 5]")
	end
	
	local hEntity = self._hEntity
	local nAbilityLevel = self._tKnownAbilities[szNewAbilityName]
	if nAbilityLevel then
		if not self._tBoundAbilities[nSlot] then
			local hNewAbility = hEntity:FindAbilityByName(szNewAbilityName)
			if not hNewAbility then
				hEntity:AddAbility(szNewAbilityName)
				hNewAbility = hEntity:FindAbilityByName(szNewAbilityName)
				hNewAbility:SetLevel(nAbilityLevel)
				if hNewAbility:IsPassive() then
					if hNewAbility:GetClassname() == "ability_datadriven" then
						--TODO: Apply datadriven modifiers here
					else
						hEntity:AddNewModifier(hEntity._hBaseEntity, hNewAbility, "modifier_" .. hNewAbility:GetAbilityName(), {})
					end
				end
			end
			self._tBoundAbilities[nSlot] = szNewAbilityName
			SendToConsole("bind \"" .. CIcewrackSpellbook._stKeybindTable[nSlot] .. "\" \"dota_ability_execute " .. hNewAbility:GetAbilityIndex() .. "\"")
		else
			local szOldAbilityName = self._tBoundAbilities[nSlot]
			if szOldAbilityName == szNewAbilityName then
				return
			end
			
			local hOldAbility = hEntity:FindAbilityByName(szOldAbilityName)
			local hNewAbility = hEntity:FindAbilityByName(szNewAbilityName)
			print(hNewAbility)
			if not hNewAbility then
				hEntity:AddAbility(szNewAbilityName)
				hNewAbility = hEntity:FindAbilityByName(szNewAbilityName)
				hNewAbility:SetLevel(nAbilityLevel)
				
				hEntity:SwapAbilities(szOldAbilityName, szNewAbilityName, true, true)
				
				if hOldAbility:IsPassive() then
					hEntity:RemoveModifierByNameAndCaster("modifier_" .. hOldAbility:GetAbilityName(), hEntity._hBaseEntity)
				end
				hEntity:RemoveAbility(szOldAbilityName)
				
				if hNewAbility:IsPassive() then
					if hNewAbility:GetClassname() == "ability_datadriven" then
						--TODO: Apply datadriven modifiers here
					else
						hEntity:AddNewModifier(hEntity._hBaseEntity, hNewAbility, "modifier_" .. hNewAbility:GetAbilityName(), {})
					end
				end
			end
			
			self._tBoundAbilities[nSlot] = szNewAbilityName
			SendToConsole("bind \"" .. CIcewrackSpellbook._stKeybindTable[nSlot] .. "\" \"dota_ability_execute " .. hNewAbility:GetAbilityIndex() .. "\"")
		end
		self._bRefreshFlag = true
	end
end

--Technically, this is never used in-game. But we'll keep it here just in case
function CIcewrackSpellbook:UnlearnAbility(szAbilityName)
	if self._tKnownAbilities[szAbilityName] then
		self._tKnownAbilities[szAbilityName] = nil
	end
	--TODO: Also unbind the ability, if it's currently bound
end

function CIcewrackSpellbook:LearnAbility(szAbilityName, nLevel)
	if szAbilityName and nLevel then
		self._tKnownAbilities[szAbilityName] = nLevel
	end
end

function CIcewrackSpellbook:GetBoundAbilityName(nSlot)
	local szAbilityName = self._tBoundAbilities[nSlot]
	if szAbilityName and string.find(szAbilityName, "ui_spellbar_empty") == nil then
		return szAbilityName
	end
	return nil
end

function CIcewrackSpellbook:GetKnownAbilities()
	return self._tKnownAbilities
end

function CIcewrackSpellbook:GetAvailableAbilities()
	local tAvailableAbilities = {}
	for k,v in pairs(self._tKnownAbilities) do
		tAvailableAbilities[k] = v
	end
	for k,v in pairs(self._tBoundAbilities) do
		tAvailableAbilities[v] = nil
	end
	return tAvailableAbilities
end

function CIcewrackSpellbook:RefreshBinds()
	for i=0,5 do
		SendToConsole("unbind \"" .. CIcewrackSpellbook._stKeybindTable[i])
		local szAbilityName = self._tBoundAbilities[i]
		if szAbilityName then
			local hAbility = self._hEntity:FindAbilityByName(szAbilityName)
			if hAbility then
				SendToConsole("bind \"" .. CIcewrackSpellbook._stKeybindTable[i] .. "\" \"dota_ability_execute " .. hAbility:GetAbilityIndex() .. "\"")
			else
				--This shouldn't happen... print an error or something?
			end
		end
	end
end

function SetActiveSpellbookEntity(hEntity)
	if hEntity and hEntity._hSpellbook then
		CIcewrackSpellbook._shActiveSpellbook = hEntity._hSpellbook
		CIcewrackSpellbook._shActiveSpellbook:RefreshBinds()
	end
end