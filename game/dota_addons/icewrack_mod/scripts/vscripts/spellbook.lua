--[[
    Icewrack Spellbook
]]

require("timer")
require("ext_entity")

if CIcewrackSpellbook == nil then
	CIcewrackSpellbook = class({
		constructor = function(self, hExtEntity)
			if not IsValidExtendedEntity(hExtEntity) then
				error("hExtEntity must be a valid extended entity")
			end
			
			self._bIsSpellbook = true
			self._hExtEntity = hExtEntity
			hExtEntity._hSpellbook = self
			
			self._tCooldowns = {}
			self._tKnownAbilities = {}
			self._tBoundAbilities = {}
			for i=0,(hExtEntity:GetAbilityCount() - 1) do
				local hAbility = hExtEntity:GetAbilityByIndex(i)
				if hAbility then
					if string.find(hAbility:GetAbilityName(), "ui_spellbar_empty") == nil then
						self._tKnownAbilities[hAbility:GetAbilityName()] = hAbility:GetLevel()
					end
					self._tBoundAbilities[i] = hAbility:GetAbilityName()
				end
			end
			
			self._nCooldownListenerID = ListenToGameEvent("dota_player_used_ability", Dynamic_Wrap(CIcewrackSpellbook, "OnAbilityUsed"), self)
			self._nCooldownListenerID = ListenToGameEvent("dota_player_learned_ability", Dynamic_Wrap(CIcewrackSpellbook, "OnAbilityLearned"), self)
		end},
		--TODO: Change these to user-set binds instead
		{ _shActiveSpellbook = nil,
		  _stKeybindTable = {[0] = "1", [1] = "2", [2] = "3", [3] = "4", [4] = "5", [5] = "6"}}, nil)
end

function CIcewrackSpellbook:UnbindAbility(nSlot)
	if self._tBoundAbilities[nSlot] and string.find(self._tBoundAbilities[nSlot], "ui_spellbar_empty") == nil then
		local hExtEntity = self._hExtEntity
		local hAbility = hExtEntity:FindAbilityByName(self._tBoundAbilities[nSlot])
		if hAbility then
			local szAbilityName = hAbility:GetAbilityName()
			local szEmptySlotName = "ui_spellbar_empty" .. (nSlot + 1)
			hExtEntity:AddAbility(szEmptySlotName)
			hExtEntity:SwapAbilities(szEmptySlotName, szAbilityName, true, true)
			hExtEntity:RemoveAbility(szAbilityName)
			self._tBoundAbilities[nSlot] = szEmptySlotName
			FireGameEventLocal("iw_spellbook_refresh", {})
		end
	end
end

function CIcewrackSpellbook:BindAbility(szNewAbilityName, nSlot)
	nSlot = math.floor(nSlot)
	if nSlot < 0 or nSlot >= 6 then
		error("nSlot must be between an integer between [0, 5]")
	end
	
	local hEntity = self._hExtEntity._hBaseEntity
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
		FireGameEventLocal("iw_spellbook_refresh", {})
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

function CIcewrackSpellbook:GetBoundAbility(nSlot)
	local szAbilityName = self._tBoundAbilities[nSlot]
	if szAbilityName and string.find(szAbilityName, "ui_spellbar_empty") == nil then
		return self._hExtEntity:FindAbilityByName(szAbilityName)
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
			local hAbility = self._hExtEntity:FindAbilityByName(szAbilityName)
			if hAbility then
				SendToConsole("bind \"" .. CIcewrackSpellbook._stKeybindTable[i] .. "\" \"dota_ability_execute " .. hAbility:GetAbilityIndex() .. "\"")
			else
				--This shouldn't happen... print an error or something?
			end
		end
	end
end

function CIcewrackSpellbook:GetCooldown(szAbilityName)
	if self._tCooldowns[szAbilityName] then
		local tCooldownTime = self._tCooldowns[szAbilityName][1] + self._tCooldowns[szAbilityName][2]
		return tCooldownTime - GameRules:GetGameTime()
	else
		return 0
	end
end

function CIcewrackSpellbook:SetCooldown(szAbilityName, fDuration)
	if self._tKnownAbilities[szAbilityName] and not self._tCooldowns[sAbilityName] then
		self._tCooldowns[szAbilityName] = { GameRules:GetGameTime(), fDuration }
		CTimer(function()
				self._tCooldowns[szAbilityName] = nil
			end, fDuration)
	end
end

function CIcewrackSpellbook:OnAbilityLearned(args)
	if CIcewrackSpellbook._shActiveSpellbook == self then
		local hEntity = self._hExtEntity._hBaseEntity
		if IsValidEntity(hEntity) then
			local hOwner = hEntity:GetOwner()
			if IsValidEntity(hOwner) then
				local nPlayerID = hOwner:GetPlayerID()
				if args.player == (nPlayerID + 1) then
					FireGameEventLocal("iw_spellbook_refresh", {})
				end
			end
		else
			StopListeningToGameEvent(self._nCooldownListenerID)
		end
	end
end

function CIcewrackSpellbook:OnAbilityUsed(args)
	local hEntity = self._hExtEntity._hBaseEntity
	if IsValidEntity(hEntity) then
		local hOwner = hEntity:GetOwner()
		if IsValidEntity(hOwner) then
			local nPlayerID = hOwner:GetPlayerID()
			if args.PlayerID == (nPlayerID + 1) then
				if self._tKnownAbilities[args.abilityname] then
					local hAbility = hEntity:FindAbilityByName(args.abilityname)
					if hAbility then
						self:SetCooldown(args.abilityname, hAbility:GetCooldownTimeRemaining())
						if CIcewrackSpellbook._shActiveSpellbook == self then
							FireGameEventLocal("iw_spellbook_refresh", {})
						end
					end
				end
			end
		end
	else
		StopListeningToGameEvent(self._nCooldownListenerID)
	end
end

function SetActiveSpellbookEntity(hExtEntity)
	if IsValidExtendedEntity(hExtEntity) and hExtEntity._hSpellbook then
		CIcewrackSpellbook._shActiveSpellbook = hExtEntity._hSpellbook
		CIcewrackSpellbook._shActiveSpellbook:RefreshBinds()
	end
end