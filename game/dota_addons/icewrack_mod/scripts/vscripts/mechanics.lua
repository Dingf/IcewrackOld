--[[
    Game Mechanics
]]

require("timer")
require("attributes")
require("damage_types")
require("ext_entity")
require("party")

_shDodgeModifier = CreateItem("internal_dodge_invulnerability", nil, nil)
_shManaDrainModifier = CreateItem("internal_mana_drain_visual", nil, nil)

_stDamageVisualTable = 
{
	[IW_DAMAGE_TYPE_PURE]      = {6, Vector(255, 64, 255)},
	[IW_DAMAGE_TYPE_PHYSICAL]  = {8, Vector(255, 255, 255)},
	[IW_DAMAGE_TYPE_FIRE]      = {1, Vector(255, 48, 0)},
	[IW_DAMAGE_TYPE_ICE]       = {2, Vector(0, 128, 255)},
	[IW_DAMAGE_TYPE_LIGHTNING] = {4, Vector(255, 255, 0)},
	[IW_DAMAGE_TYPE_DEATH]     = {5, Vector(0, 64, 0)},
}

function DealDamage(args)
    if IsValidEntity(args.target) and IsValidEntity(args.caster) then
		local hVictim = LookupExtendedEntity(args.target)
		local hAttacker = LookupExtendedEntity(args.caster)
		
		--Ignore this function call if the attacker and/or victim isn't a valid extended entity
		if not IsValidExtendedEntity(hVictim) or not IsValidExtendedEntity(hAttacker) then
			return
		end
		
		--We can't damage dead units (also prevents multiple kill/damage procs on units that are already dead)
		if not hVictim:IsAlive() then
			return
		end
		
		--Ignore magic immune targets if we can't damage them
		if hVictim:IsMagicImmune() and (not args.IgnoreMagicImmunity or args.IgnoreMagicImmunity == "FALSE") then
			return
		end
		
		hAttacker._tAttacking[hVictim] = (hAttacker._tAttacking[hVictim] or 0) + 1
		hVictim._tAttackedBy[hAttacker] = (hVictim._tAttackedBy[hAttacker] or 0) + 1
			
		CTimer(function()
				hAttacker._tAttacking[hVictim] = hAttacker._tAttacking[hVictim] - 1
				if hAttacker._tAttacking[hVictim] <= 0 then hAttacker._tAttacking[hVictim] = nil end
				hVictim._tAttackedBy[hAttacker] = hVictim._tAttackedBy[hAttacker] - 1
				if hVictim._tAttackedBy[hAttacker] <= 0 then hVictim._tAttackedBy[hAttacker] = nil end
			end, 3.0)
		
		local nDamageType = _G[args.DamageType] or IW_DAMAGE_TYPE_PURE
		
		local fDamageBlock = hVictim:GetDamageBlock(nDamageType) or 0.0
		local fDamagePierce = hAttacker:GetDamagePierce(nDamageType) or 0.0
		local fResistance = (hVictim:GetResistance(nDamageType) or 0.0) - fDamagePierce

		
		local fDamageBase = RandomInt(args.MinDamage, args.MaxDamage)
		if not args.NoOutMultiplier or args.NoOutMultiplier == "FALSE" then
			fDamageBase = fDamageBase * hAttacker:GetOutgoingDamageMultiplier()
		end	
		
		if args.UseStrengthBonus and args.UseIntelligenceBonus ~= "FALSE" then
			fDamageBase = fDamageBase * (1.00 + (hAttacker:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 0.01))
		end
		
		if args.UseIntelligenceBonus and args.UseIntelligenceBonus ~= "FALSE" and nDamageType ~= IW_DAMAGE_TYPE_PHYSICAL and nDamageType ~= IW_DAMAGE_TYPE_PURE then
			fResistance = fResistance - (hAttacker:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 0.005)
		end
		
		fResistance = math.min(1.0, fResistance, hVictim:GetMaxResistance(nDamageType))
		local fDamage = (fDamageBase - fDamageBlock) * (1.0 - fResistance)
		if not args.NoInMultiplier or args.NoInMultiplier == "FALSE" then
			fDamage = fDamage * hVictim:GetIncomingDamageMultiplier()
		end
		
		if args.CanDodge and args.CanDodge ~= "FALSE" and not hVictim:IsHexed() then
			local fBonusAccuracy = args.BonusAccuracy or 0
			local fScoreDiff = hVictim:GetDodgeScore() - hAttacker:GetAccuracyScore() - fBonusAccuracy
			local fDodgeChance = (math.tanh(math.max(-2.0, math.min(2.0, (fScoreDiff/200.0)))) + 1.0)/2.0
			
			if RandomFloat(0.0, 1.0) <= fDodgeChance then
				local nParticleID = ParticleManager:CreateParticle("particles/msg_fx/msg_miss.vpcf", PATTACH_ABSORIGIN_FOLLOW, args.target)
				ParticleManager:SetParticleControl(nParticleID, 1, Vector(5, nil, nil))
				ParticleManager:SetParticleControl(nParticleID, 2, Vector(1.0, 1, 0))
				ParticleManager:SetParticleControl(nParticleID, 3, Vector(255, 255, 255))
				
				_shDodgeModifier:ApplyDataDrivenModifier(hVictim, hVictim, "modifier_internal_dodge_invulnerability", {})
				
				FireGameEvent('iw_damage_missed',
							  { attacker = args.caster:entindex(),
								victim = args.target:entindex(),
								damage = fDamage,
								damage_type = nDamageType })
				return
			end
		end
		
		local bCritFlag = false
		if args.CanCrit and args.CanCrit ~= "FALSE" then
			if RandomFloat(0.0, 1.0) <= hAttacker:GetCriticalStrikeChance() then
				bCritFlag = true
				fDamage = fDamage * hAttacker:GetCriticalStrikeMultiplier()
				
				local tDamageVisual = _stDamageVisualTable[nDamageType]
				local nParticleID = ParticleManager:CreateParticle("particles/msg_fx/msg_crit.vpcf", PATTACH_ABSORIGIN_FOLLOW, args.target)
				ParticleManager:SetParticleControl(nParticleID, 1, Vector(nil, tonumber(math.floor(fDamage)), tDamageVisual[1]))
				ParticleManager:SetParticleControl(nParticleID, 2, Vector(math.log10(fDamage), #tostring(math.floor(fDamage)) + 1, 0))
				ParticleManager:SetParticleControl(nParticleID, 3, tDamageVisual[2])
			end
		end
		
		local fDrainEffectiveness = hVictim:GetDrainEffectiveness()
		if args.CanLifesteal and args.CanLifesteal ~= "FALSE" and fDrainEffectiveness > 0 then
			local fLifestealAmount = fDamage * hAttacker:GetLifestealMultiplier() * fDrainEffectiveness
			if fLifestealAmount > 0 then
				hAttacker:AddLifesteal(fLifestealAmount)
				--ParticleManager:CreateParticle("particles/generic_gameplay/generic_lifesteal.vpcf", PATTACH_OVERHEAD_FOLLOW, hAttacker)
			end
		end
		
		if args.CanManasteal and args.CanManasteal ~= "FALSE" and fDrainEffectiveness > 0 then
			local fManastealAmount = fDamage * hAttacker:GetManastealMultiplier() * fDrainEffectiveness
			if fManastealAmount > 0 then
				hAttacker:AddManasteal(fManastealAmount)
				--_shManaDrainModifier:ApplyDataDrivenModifier(hAttacker, hAttacker, "modifier_internal_mana_drain_visual", {})
			end
		end
		
		local fCurrentHealth = hVictim:GetHealth()
		hVictim:ModifyHealth(fCurrentHealth - fDamage, hAttacker, true, 0)
		
		local tDamageInfoTable = 
		{
			attacker = args.caster:entindex(),
			victim = args.target:entindex(),
			damage = fDamage,
			damage_type = nDamageType,
			threat = args.ThreatMultiplier or 1.0,
			crit = bCritFlag
		}
		
		for k,v in pairs(hAttacker._tOnDealDamageList) do v(tDamageInfoTable) end
		for k,v in pairs(hVictim._tOnTakeDamageList) do v(tDamageInfoTable) end
		
		if fCurrentHealth <= math.ceil(fDamage) then
			for k,v in pairs(hAttacker._tOnKillEntityList) do v(tDamageInfoTable) end
			for k,v in pairs(hVictim._tOnSelfKilledList) do v(tDamageInfoTable) end
			if hVictim:GetTeamNumber() ~= PlayerResource:GetTeam(0) then
				local tActiveMemberList = CIcewrackParty:GetActiveMembers()
				for k,v in pairs(tActiveMemberList) do
					v:AddExperience(hVictim:GetDeathXP(), false, false)
				end
			end
		end
		
		FireGameEvent('iw_damage_taken', tDamageInfoTable)
	end
end

function DealWeaponDamage(args)
    if args.Percent and args.DamageType then
        args.MinDamage = args.caster:GetBaseDamageMin() * args.Percent/100
        args.MaxDamage = args.caster:GetBaseDamageMax() * args.Percent/100
        DealDamage(args)
    end
end

--Used by the dodge cleanup passive to remove the small invulnerability window if an autoattack misses (doesn't work for other dodgeable damage sources)
function RemoveDodgeInvulnerability(args)
    args.caster:RemoveModifierByName("modifier_internal_dodge_invulnerability")
end

function ScaleWithAttackSpeed(args)
    if args.BaseCastTime and IsValidEntity(args.caster) then
        local hEntity = LookupExtendedEntity(args.caster)
        local fOffset = 1.0 + (0.5 * hEntity:GetIncreasedAttackSpeed())
        
        args.ability:SetOverrideCastPoint(args.BaseCastTime/offset)
    end
end

function ScaleWithCastSpeed(args)
    if args.BaseCastTime and IsValidEntity(args.caster) then
        local hEntity = LookupExtendedEntity(args.caster)
        local fOffset = 1.0 + (0.5 * hEntity:GetIncreasedCastSpeed())
        
        args.ability:SetOverrideCastPoint(args.BaseCastTime/offset)
    end
end