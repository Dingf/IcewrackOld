--[[
    Icewrack Extended Ability
]]

--It's technically more like an extended modifier than an extended ability, although that may change in the future
--		*Stamina cost for spells?

require("timer")
require("status_effects")
require("ext_entity")

if CIcewrackExtendedAbility == nil then
    tIcewrackExtendedAbilityTemplate = LoadKeyValues("scripts/npc/npc_abilities_extended.txt")
    if not tIcewrackExtendedAbilityTemplate then
        error("Could not load key values from extended ability data")
    end
    
    CIcewrackExtendedAbility = class({
		constructor = function(self, szAbilityName)
			tAbilityData = tIcewrackExtendedAbilityTemplate[szAbilityName]
			if not tAbilityData then
				error("Could not find extended ability named " .. szAbilityName)
			end
			
			local hBuffDummy = CreateUnitByName("iw_npc_generic_dummy", Vector(0, 0, 0), false, nil, nil, 0)
			hBuffDummy:AddAbility("internal_dummy_buff")
			hBuffDummy:FindAbilityByName("internal_dummy_buff"):SetLevel(1)
					
			hBuffDummy:AddAbility(szAbilityName)
			self._hBaseAbility = hBuffDummy:FindAbilityByName(szAbilityName)
					
			if not self._hBaseAbility then
				error("Could not create ability named " .. szAbilityName)
			end
					
			setmetatable(self, {__index = function(self, k)
				local v = CIcewrackExtendedAbility[k] or self._hBaseAbility[k] or nil
				if v then
					self[k] = v
					return v
				else
					return nil
				end
			end})
					
			self._bIsExtendedAbility = true
			self._bIsModifierActive = false
					
			self._hEntity = hBuffDummy
					
			self._szAbilityName = szAbilityName
					
			self._tProperties = tAbilityData.Properties
			self._nStatusEffect = _G[tAbilityData.StatusEffect] or IEA_STATUS_EFFECT_NONE
			self._fBaseDuration = tAbilityData.Duration
			self._fMinDuration = tAbilityData.MinDuration
			self._fMaxDuration = tAbilityData.MaxDuration
			if self._fMinDuration and self._fMaxDuration and self._fMinDuration > self._fMaxDuration then
				local fTemp = self._fMinDuration
				self._fMinDuration = self._fMaxDuration
				self._fMaxDuration = fTemp
			end
			if tAbilityData.IsDebuff and tAbilityData.IsDebuff ~= "FALSE" then
				self._bIsDebuff = true
			else
				self._bIsDebuff = false
			end
			
			if tAbilityData.ApplyOnInvulerable and tAbilityData.ApplyOnInvulerable ~= "FALSE" then
				self._bApplyOnInvulnerable = true
			else
				self._bApplyOnInvulnerable = false
			end
			
			self._fMaxStacks = tAbilityData.MaxStacks
			self._fMaxStacksPerCaster = tAbilityData.MaxStacksPerCaster
			
			return self
		end},
		{_stLookupTable = {}}, nil)
end

function CIcewrackExtendedAbility:GetClassname()
    return "iw_ext_ability"
end

function CIcewrackExtendedAbility:GetAbilityName()
	return self._szAbilityName
end

function CIcewrackExtendedAbility:GetSource()
	return self._hSource
end

function CIcewrackExtendedAbility:GetTarget()
	return self._hTarget
end

function CIcewrackExtendedAbility:GetStatusEffect()
	return self._nStatusEffect
end

function CIcewrackExtendedAbility:GetBaseDuration()
	return self._fBaseDuration or 0.0
end

function CIcewrackExtendedAbility:GetRealDuration()
	return self._fRealDuration or 0.0
end

function CIcewrackExtendedAbility:GetStartTime()
	return self._fStartTime or 0.0
end

function CIcewrackExtendedAbility:GetEndTime()
	return self._fEndTime or 0.0
end

function CIcewrackExtendedAbility:IsActive()
	return self._bIsModifierActive
end

function CIcewrackExtendedAbility:IsDebuff()
	return self._bIsDebuff
end

function CIcewrackExtendedAbility:RemoveExtendedModifier()
	if self._bIsModifierActive then
		local hTarget = self._hTarget
		local hExtTarget = LookupExtendedEntity(hTarget)
		if hExtTarget and hExtTarget._bIsExtendedEntity then
			hExtTarget:ApplyModifierProperties(self._tProperties, true)
			CIcewrackExtendedAbility._stLookupTable[hTarget][self] = nil
			if hTarget:IsAlive() then
				hTarget:RemoveModifierByNameAndCaster("modifier_" .. self:GetAbilityName(), self._hEntity)
			end
			self._hEntity:RemoveSelf()
			self._bIsModifierActive = false
		end
	end
end

--Culls either a stack owned by the source or the oldest stack, based on
--the specified max stacks / max stacks per caster. If the cap has not been
--reached, no stack is culled.
function CIcewrackExtendedAbility:CullMaxStacks()
	if self._fMaxStacksPerCaster or self._fMaxStacks then
		local nTotalCount = 0
		local nSourceCount = 0
		local nLowestTotalTime = nil
		local hLowestTotal = nil
		local nLowestSourceTime = nil
		local hLowestSource = nil
		
		local bCullFlag = false
		local tExtModifierList = LookupExtendedModifierList(self._hTarget) or {}
		for k,v in pairs(tExtModifierList) do
			if k._szAbilityName == self._szAbilityName then
				local nEndTime = k._fEndTime or 0
				nTotalCount = nTotalCount + 1
				if not nLowestTotalTime or nEndTime < nLowestTotalTime then
					nLowestTotalTime = nEndTime
					hLowestTotal = k
				end
				local bSourceFlag = self._fMaxStacksPerCaster and k._hSource == self._hSource
				if bSourceFlag then
					nSourceCount = nSourceCount + 1
					if not nLowestSourceTime or nEndTime < nLowestSourceTime then
						nLowestSourceTime = nEndTime
						hLowestSource = k
					end
				end
				if (bSourceFlag and nSourceCount >= self._fMaxStacksPerCaster) or (self._fMaxStacks and nTotalCount >= self._fMaxStacks) then
					bCullFlag = true
				end
			end
		end
		if bCullFlag then
			if hLowestSource and nSourceCount >= self._fMaxStacksPerCaster then
				hLowestSource:RemoveExtendedModifier()
			elseif hLowestTotal then
				hLowestTotal:RemoveExtendedModifier()
			end
		end
	end
end

function CIcewrackExtendedAbility:ApplyExtendedAbility(hSource, hTarget)
	if not self._bIsModifierActive then
		local hExtTarget = LookupExtendedEntity(hTarget)
		if hExtTarget and hExtTarget._bIsExtendedEntity then
			self._hSource = hSource
			self._hTarget = hTarget
			
			--Prevent missed attacks/abilities from clearing or refreshing previous buffs
			if hTarget:IsInvulnerable() and not self._bApplyOnInvulnerable then
				return
			end
			
			self:CullMaxStacks()
			hExtTarget:ApplyModifierProperties(self._tProperties)
			self._bIsModifierActive = true
			if not CIcewrackExtendedAbility._stLookupTable[hTarget] then
				CIcewrackExtendedAbility._stLookupTable[hTarget] = {}
			end
			CIcewrackExtendedAbility._stLookupTable[hTarget][self] = true
			if self._fBaseDuration then
				if self._fMinDuration and self._fMaxDuration then
					self._fRealDuration = RandomFloat(self._fMinDuration, self._fMaxDuration) * (hExtTarget:GetEffectDurationMultiplier(self._nStatusEffect) or 1.0)
				else
					self._fRealDuration = self._fBaseDuration * (hExtTarget:GetEffectDurationMultiplier(self._nStatusEffect) or 1.0)
				end
				if self._fRealDuration > 0 then
					self._hBaseAbility:ApplyDataDrivenModifier(self._hEntity, hTarget, "modifier_" .. self:GetAbilityName(), { duration = self._fRealDuration })
					self._fStartTime = GameRules:GetGameTime()
					self._fEndTime = self._fStartTime + self._fRealDuration
					CTimer(function()
							if self._bIsModifierActive and (not hTarget:IsAlive() or GameRules:GetGameTime() > self._fEndTime) then
								self:RemoveExtendedModifier()
								--hTarget._bModifierUpdateFlag = true
								return TIMER_STOP
							end
						end, 0, 0.1)
				end
			else
				self._hBaseAbility:ApplyDataDrivenModifier(self._hEntity, hTarget, "modifier_" .. self:GetAbilityName(), {})
			end
			--hTarget._bModifierUpdateFlag = true
		end
	end
end

function LookupExtendedModifierList(hEntity)
    if hEntity then
        return CIcewrackExtendedAbility._stLookupTable[hEntity]
    else
        return nil
    end
end

function DataDrivenApplyExtendedModifier(args)
	local hSource = args.caster
	local hTarget = args.target or hSource
	local szAbilityName = args.ModifierName
	
	if not szAbilityName then
		error("Missing parameter \"ModifierName\" in key values")
	elseif hSource and hTarget then
		local hExtAbility = CIcewrackExtendedAbility(szAbilityName)
		hExtAbility:ApplyExtendedAbility(hSource, hTarget)
	end
end