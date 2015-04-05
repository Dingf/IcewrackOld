--[[
    Icewrack Extended Entity
]]

if _VERSION < "Lua 5.2" then
    bit = require("numberlua")
    bit32 = bit.bit32
end

require("timer")
require("attributes")
require("damage_types")
require("status_effects")

IEE_UNIT_CLASS_NONE = 0
IEE_UNIT_CLASS_CRITTER = 1
IEE_UNIT_CLASS_NORMAL = 2
IEE_UNIT_CLASS_VETERAN = 3
IEE_UNIT_CLASS_ELITE = 4
IEE_UNIT_CLASS_BOSS = 5
IEE_UNIT_CLASS_ACT_BOSS = 6
IEE_UNIT_CLASS_HERO = 7

IEE_UNIT_TYPE_NONE = 0
IEE_UNIT_TYPE_MELEE = 1
IEE_UNIT_TYPE_RANGED = 2
IEE_UNIT_TYPE_MAGIC = 3

IEE_UNIT_SUBTYPE_NONE = 0
IEE_UNIT_SUBTYPE_BIOLOGICAL = 1
IEE_UNIT_SUBTYPE_MECHANICLAL = 2
IEE_UNIT_SUBTYPE_ETHEREAL = 3
IEE_UNIT_SUBTYPE_ELEMENTAL = 4
IEE_UNIT_SUBTYPE_UNDEAD = 5

IEE_MODIFIER_PROPERTY_STAMINA_REGEN = "StaminaRegen"
IEE_MODIFIER_PROPERTY_STAMINA_MAX = "StaminaMax"
IEE_MODIFIER_PROPERTY_HEALTH_REGEN = "HealthRegen"
IEE_MODIFIER_PROPERTY_MANA_REGEN = "ManaRegen"
IEE_MODIFIER_PROPERTY_CRIT_CHANCE = "CritChance" 
IEE_MODIFIER_PROPERTY_CRIT_MULTIPLIER = "CritMultiplier" 
IEE_MODIFIER_PROPERTY_ACCURACY_SCORE = "AccuracyScore" 
IEE_MODIFIER_PROPERTY_DODGE_SCORE = "DodgeScore" 
IEE_MODIFIER_PROPERTY_LIFESTEAL = "Lifesteal" 
IEE_MODIFIER_PROPERTY_LIFESTEAL_RATE = "LifestealRate" 
IEE_MODIFIER_PROPERTY_MANASTEAL = "Manasteal" 
IEE_MODIFIER_PROPERTY_MANASTEAL_RATE = "ManastealRate" 
IEE_MODIFIER_PROPERTY_CAST_SPEED = "CastSpeed" 
IEE_MODIFIER_PROPERTY_INC_DAMAGE = "IncomingDamage" 
IEE_MODIFIER_PROPERTY_OUT_DAMAGE = "OutgoingDamage" 
IEE_MODIFIER_PROPERTY_STRENGTH = "Strength"
IEE_MODIFIER_PROPERTY_VIGOR = "Vigor" 
IEE_MODIFIER_PROPERTY_AGILITY = "Agility" 
IEE_MODIFIER_PROPERTY_CUNNING = "Cunning" 
IEE_MODIFIER_PROPERTY_INTELLIGENCE = "Intelligence" 
IEE_MODIFIER_PROPERTY_WISDOM = "Wisdom"
IEE_MODIFIER_PROPERTY_RESIST_PHYSICAL = "ResistPhysical" 
IEE_MODIFIER_PROPERTY_RESIST_FIRE = "ResistFire" 
IEE_MODIFIER_PROPERTY_RESIST_ICE = "ResistIce" 
IEE_MODIFIER_PROPERTY_RESIST_LIGHTNING = "ResistLightning" 
IEE_MODIFIER_PROPERTY_RESIST_DEATH = "ResistDeath"
IEE_MODIFIER_PROPERTY_MAX_RESIST_PHYSICAL = "ResistPhysicalMax" 
IEE_MODIFIER_PROPERTY_MAX_RESIST_FIRE = "ResistFireMax" 
IEE_MODIFIER_PROPERTY_MAX_RESIST_ICE = "ResistIceMax" 
IEE_MODIFIER_PROPERTY_MAX_RESIST_LIGHTNING = "ResistLightningMax" 
IEE_MODIFIER_PROPERTY_MAX_RESIST_DEATH = "ResistDeathMax"
IEE_MODIFIER_PROPERTY_BLOCK_PHYSICAL = "BlockPhysical" 
IEE_MODIFIER_PROPERTY_BLOCK_FIRE = "BlockFire" 
IEE_MODIFIER_PROPERTY_BLOCK_ICE = "BlockIce" 
IEE_MODIFIER_PROPERTY_BLOCK_LIGHTNING = "BlockLightning" 
IEE_MODIFIER_PROPERTY_BLOCK_DEATH = "BlockDeath"
IEE_MODIFIER_PROPERTY_PIERCE_PHYSICAL = "PiercePhysical" 
IEE_MODIFIER_PROPERTY_PIERCE_FIRE = "PierceFire" 
IEE_MODIFIER_PROPERTY_PIERCE_ICE = "PierceIce" 
IEE_MODIFIER_PROPERTY_PIERCE_LIGHTNING = "PierceLightning"
IEE_MODIFIER_PROPERTY_PIERCE_DEATH = "PierceDeath"
IEE_MODIFIER_PROPERTY_DURATION_STUN = "DurationStun"
IEE_MODIFIER_PROPERTY_DURATION_SLOW = "DurationSlow"
IEE_MODIFIER_PROPERTY_DURATION_SILENCE = "DurationSilence"
IEE_MODIFIER_PROPERTY_DURATION_ROOT = "DurationRoot"
IEE_MODIFIER_PROPERTY_DURATION_HEX = "DurationHex"
IEE_MODIFIER_PROPERTY_DURATION_DISARM = "DurationDisarm"
IEE_MODIFIER_PROPERTY_DURATION_SLEEP = "DurationSleep"
IEE_MODIFIER_PROPERTY_DURATION_FROZEN = "DurationFrozen"
IEE_MODIFIER_PROPERTY_DURATION_CHILLED = "DurationChilled"
IEE_MODIFIER_PROPERTY_DURATION_WET = "DurationWet"
IEE_MODIFIER_PROPERTY_DURATION_BURNING = "DurationBurning"
IEE_MODIFIER_PROPERTY_DURATION_POISON = "DurationPoison"
IEE_MODIFIER_PROPERTY_DURATION_BLEED = "DurationBleed"
IEE_MODIFIER_PROPERTY_DURATION_BLIND = "DurationBlind"
IEE_MODIFIER_PROPERTY_DURATION_PETRIFY = "DurationPetrify"
IEE_MODIFIER_PROPERTY_PERCENT_STAMINA = "TotalStaminaPercent"
IEE_MODIFIER_PROPERTY_PERCENT_MANA = "TotalManaPercent"
IEE_MODIFIER_PROPERTY_PERCENT_HEALTH = "TotalHealthPercent"


--Flags
--   *Does not leave a corpse
--   *uh...


stIEEPropertiesTable = nil
stIEEPropertiesSet = nil

tBaseEntityTemplate = nil
tIcewrackExtendedEntityTemplate = nil


stIEEPropertiesTable =
{
	"Stamina",           "StaminaRegen",       "StaminaMax",         "HealthRegen",        "ManaRegen", 
	"CritChance",        "CritMultiplier",     "AccuracyScore",      "DodgeScore",         "Lifesteal", 
	"LifestealRate",     "Manasteal",          "ManastealRate",      "CastSpeed",          "IncomingDamage", 
	"OutgoingDamage",    "DrainEffectiveness", "Strength",           "Vigor",              "Agility",
	"Cunning",           "Intelligence",       "Wisdom",             "StrengthGrowth",     "VigorGrowth",
	"AgilityGrowth",     "CunningGrowth",      "IntelligenceGrowth", "WisdomGrowth",       "AttributePoints",
	"ResistPhysical",    "ResistFire",         "ResistIce",          "ResistLightning",    "ResistDeath",
	"ResistPhysicalMax", "ResistFireMax",      "ResistIceMax",       "ResistLightningMax", "ResistDeathMax",
	"BlockPhysical",     "BlockFire",          "BlockIce",           "BlockLightning",     "BlockDeath",
	"PiercePhysical",    "PierceFire",         "PierceIce",          "PierceLightning",    "PierceDeath",
	"DurationStun",      "DurationSlow",       "DurationSilence",    "DurationRoot",       "DurationHex",
	"DurationDisarm",    "DurationSleep",      "DurationFrozen",     "DurationChilled",    "DurationWet",
	"DurationBurning",   "DurationPoison",     "DurationBleed",      "DurationBlind",      "DurationPetrify",
	"MaxStaminaPercent", "MaxHealthPercent",   "MaxManaPercent",     "HealBonusPercent",   "StaminaDrainAttack",
	"StaminaDrainMove",  "CarryCapacity",      "LifestealDuration",  "ManastealDuration",
}

stIEEPropertiesSet = {}
for k,v in pairs(stIEEPropertiesTable) do
	stIEEPropertiesSet[v] = true
end

if CIcewrackExtendedEntity == nil then
	tBaseEntityTemplate = LoadKeyValues("scripts/npc/npc_units_custom.txt")
    tIcewrackExtendedEntityTemplate = LoadKeyValues("scripts/npc/npc_units_extended.txt")
    if not tBaseEntityTemplate or not tIcewrackExtendedEntityTemplate then
        error("Could not load key values from entity data")
    end
	
	tAddonLocaleTemplate = LoadKeyValues("resource/addon_english.txt")				--TODO: Add option to change to other languages?
	if not tAddonLocaleTemplate then
		error("Could not load locale file")
	end
    
    CIcewrackExtendedEntity = class({
		constructor = function(self, hEntity)
			if not IsValidEntity(hEntity) then
				error("Error creating extended entity: hEntity must be a valid entity")
			end
			
			if CIcewrackExtendedEntity._stLookupTable[hEntity] ~= nil then
				self = CIcewrackExtendedEntity._stLookupTable[hEntity]
				return self
			end
			
			local tBaseEntityData = tBaseEntityTemplate[hEntity:GetUnitName()] or {}
			local tExtEntityData = tIcewrackExtendedEntityTemplate[hEntity:GetUnitName()] or {}
			
			--Extended values
			self._bIsExtendedEntity = true
			self._hBaseEntity = hEntity
			
			setmetatable(self, {__index = function(t, k)
				if string.find(k, "Bonus") then
					local k2 = string.gsub(k, "Bonus", "", 1)
					if self._tPropertiesBonus[k2] then
						return self._tPropertiesBonus[k2]
					end
				end
				return self._tPropertiesBase[k] or CIcewrackExtendedEntity[k] or hEntity[k] or nil
			end})

			self._bDeletedFlag = false
			self._szDisplayName = tAddonLocaleTemplate.Tokens[hEntity:GetUnitName()] or hEntity:GetUnitName()

			self._nUnitClass = _G[tExtEntityData.UnitClass] or IEE_UNIT_CLASS_NONE
			self._nUnitType = _G[tExtEntityData.UnitType] or IEE_UNIT_TYPE_NONE
			self._nUnitSubtype = _G[tExtEntityData.UnitSubtype] or IEE_UNIT_SUBTYPE_NONE
			
			self._fModelScale = tBaseEntityData.ModelScale or 1.0
			self._fTurnRate = tBaseEntityData.MovementTurnRate or 0.5
			
			local tValuesList = { tExtEntityData,
								  tExtEntityData.Attributes or {},
								  tExtEntityData.AttributeGrowth or {},
								  tExtEntityData.BaseResistance or {}, 
								  tExtEntityData.MaxResistance or {}, 
								  tExtEntityData.DamageBlock or {},
								  tExtEntityData.DamagePierce or {},
								  tExtEntityData.EffectDuration or {} }
			
			--Non-zero default values
			self._tPropertiesBase = { CritChance = 0.05, 
								      CritMultiplier = 1.5, 
								      LifestealRate = 0.25, 
								      ManastealRate = 0.25, 
								      DrainEffectiveness = 1.0, 
								      IncomingDamage = 1.0, 
								      OutgoingDamage = 1.0,
									  StaminaDrainAttack = 1.0,
									  StaminaDrainMove = 1.0,
								      LifestealDuration = 4.0,
									  ManastealDuration = 4.0 }
								  
			for k,v in pairs(tValuesList) do
				for k2,v2 in pairs(v) do
					if stIEEPropertiesSet[k2] then
						self._tPropertiesBase[k2] = v2
					end
				end
			end
			
			self._tPropertiesBase = setmetatable(self._tPropertiesBase, {__index =
				function(t, k)
					if stIEEPropertiesSet[k] then
						self._tPropertiesBase[k] = 0.0
						return self._tPropertiesBase[k]
					end
					return nil
				end})
				
			self._tPropertiesBonus = setmetatable({LifestealRegen = 0.0, ManastealRegen = 0.0}, {__index = 
				function(t, k)
					if self._tPropertiesBase[k] then
						t[k] = 0.0
						return t[k]
					end
					return nil
				end})
			
			self._tAttacking = {}
			self._tAttackedBy = {}
			
			--TODO: Rework these?
			self._tOnDealDamageList = {}
			self._tOnTakeDamageList = {}
			self._tOnKillEntityList = {}
			self._tOnSelfKilledList = {}
			
			CIcewrackExtendedEntity._stLookupTable[hEntity] = self
			
			self:CalculateStatBonus()
			
			self.Stamina = self:GetMaxStamina()
			self._fStaminaRegenTime = 0
			
			CTimer(function()
					if IsValidExtendedEntity(self) then
						self:RegenerateStamina()
					else
						return TIMER_STOP
					end
				end, 0, TIMER_THINK_INTERVAL)
		
			return self
		end},
		{_stLookupTable = {},
		 _shHealthModifier = CreateItem("mod_health", nil, nil),
		 _shManaModifier = CreateItem("mod_mana", nil, nil),
		 _shIASModifier = CreateItem("mod_ias", nil, nil),
		 _shAttackConverter = CreateItem("internal_attack_converter", nil, nil),
		 _shDodgeCleanup = CreateItem("internal_dodge_cleanup", nil, nil),
		 _shStaminaDrain = CreateItem("internal_stamina_drain", nil, nil)},
		 nil)
end

function CIcewrackExtendedEntity:GetClassname()
    return "iw_ext_entity"
end

function CIcewrackExtendedEntity:GetDisplayName()
	return self._szDisplayName
end

function CIcewrackExtendedEntity:GetUnitClass()
    return self._nUnitClass
end

function CIcewrackExtendedEntity:GetUnitType()
    return self._nUnitType
end

function CIcewrackExtendedEntity:GetUnitSubtype()
    return self._nUnitSubtype
end

function CIcewrackExtendedEntity:GetRefID()
	return self._nRefID
end

function CIcewrackExtendedEntity:GetModelScale()
	return self._fModelScale
end

function CIcewrackExtendedEntity:GetCarryCapacity()
	return self.CarryCapacity + self.CarryCapacityBonus + (self:GetAttributeValue(IW_ATTRIBUTE_STRENGTH) * 0.2)
end

function CIcewrackExtendedEntity:GetCriticalStrikeChance()
	return self.CritChance * (1.00 + (self:GetAttributeValue(IW_ATTRIBUTE_CUNNING) * 0.02) + self.CritChanceBonus)
end

function CIcewrackExtendedEntity:GetCriticalStrikeMultiplier()
    return RandomFloat(self.CritMultiplier, self.CritMultiplier * (1.00 + (self:GetAttributeValue(IW_ATTRIBUTE_CUNNING) * 0.02)) + self.CritMultiplierBonus)
end

function CIcewrackExtendedEntity:GetAccuracyScore()
    return self.AccuracyScore + self.AccuracyScoreBonus + (self:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.00)
end

function CIcewrackExtendedEntity:GetDodgeScore()
    return self.DodgeScore + self.DodgeScoreBonus + (self:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.00)
end

function CIcewrackExtendedEntity:GetIncreasedCastSpeed()
    return self.CastSpeed + self.CastSpeedBonus + (self:GetAttributeValue(IW_ATTRIBUTE_INTELLIGENCE) * 1.00)
end

function CIcewrackExtendedEntity:GetLifestealMultiplier()
    return self.Lifesteal + self.LifestealBonus
end

function CIcewrackExtendedEntity:GetLifestealRate()
	return self.LifestealRate
end

function CIcewrackExtendedEntity:GetManastealMultiplier()
    return self.Manasteal + self.ManastealBonus
end

function CIcewrackExtendedEntity:GetManastealRate()
	return self.ManastealRate
end

function CIcewrackExtendedEntity:GetIncomingDamageMultiplier()
	return math.max(self.IncomingDamage + self.IncomingDamageBonus, 0.0)
end

function CIcewrackExtendedEntity:GetOutgoingDamageMultiplier()
	return math.max(self.OutgoingDamage + self.OutgoingDamageBonus, 0.0)
end

function CIcewrackExtendedEntity:GetAttributeValue(nAttribute)
	if nAttribute >= IW_ATTRIBUTE_STRENGTH and nAttribute <= IW_ATTRIBUTE_WISDOM then
		local szValueName = stIEEPropertiesTable[nAttribute + 17]
		local fValueBase = self._tPropertiesBase[szValueName]
		local fValueBonus = self._tPropertiesBonus[szValueName]
		if fValueBase and fValueBonus then
			return fValueBase + fValueBonus
		end
	end
    return nil
end

function CIcewrackExtendedEntity:GetAttributeGrowth(nAttribute)
	if nAttribute >= IW_ATTRIBUTE_STRENGTH and nAttribute <= IW_ATTRIBUTE_WISDOM then
		local szValueName = stIEEPropertiesTable[nAttribute + 23]
		return self._tPropertiesBase[szValueName]
	end
	return nil
end

function CIcewrackExtendedEntity:GetMaxResistance(nDamageType)
	if nDamageType >= IW_DAMAGE_TYPE_PHYSICAL and nDamageType <= IW_DAMAGE_TYPE_DEATH then
		local szValueName = stIEEPropertiesTable[nDamageType + 35]
		local fValueBase = self._tPropertiesBase[szValueName]
		local fValueBonus = self._tPropertiesBonus[szValueName]
		if fValueBase and fValueBonus then
			return fValueBase + fValueBonus
		end
	end
end

function CIcewrackExtendedEntity:GetResistance(nDamageType)
	if nDamageType >= IW_DAMAGE_TYPE_PHYSICAL and nDamageType <= IW_DAMAGE_TYPE_DEATH then
		local szValueName = stIEEPropertiesTable[nDamageType + 30]
		local fValueBase = self._tPropertiesBase[szValueName]
		local fValueBonus = self._tPropertiesBonus[szValueName]
		if fValueBase and fValueBonus then
			return fValueBase + fValueBonus + (self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 0.002)
		end
	end
    return nil
end

function CIcewrackExtendedEntity:GetDamageBlock(nDamageType)
	if nDamageType >= IW_DAMAGE_TYPE_PHYSICAL and nDamageType <= IW_DAMAGE_TYPE_DEATH then
		local szValueName = stIEEPropertiesTable[nDamageType + 40]
		local fValueBase = self._tPropertiesBase[szValueName]
		local fValueBonus = self._tPropertiesBonus[szValueName]
		if fValueBase and fValueBonus then
			return fValueBase + fValueBonus
		end
	end
    return nil
end

function CIcewrackExtendedEntity:GetDamagePierce(nDamageType)
	if nDamageType >= IW_DAMAGE_TYPE_PHYSICAL and nDamageType <= IW_DAMAGE_TYPE_DEATH then
		local szValueName = stIEEPropertiesTable[nDamageType + 45]
		local fValueBase = self._tPropertiesBase[szValueName]
		local fValueBonus = self._tPropertiesBonus[szValueName]
		if fValueBase and fValueBonus then
			return fValueBase + fValueBonus
		end
	end
    return nil
end

function CIcewrackExtendedEntity:GetEffectDurationMultiplier(nEffectType)
	if nEffectType and nEffectType >= IW_STATUS_EFFECT_STUN and nEffectType <= IW_STATUS_EFFECT_PETRIFY then
		local szValueName = stIEEPropertiesTable[nEffectType + 50]
		local fValueBase = self._tPropertiesBase[szValueName] + 1.0
		local fValueBonus = self._tPropertiesBonus[szValueName]
		if fValueBase and fValueBonus then
			return fValueBase + fValueBonus
		end
	end
	return nil
end

function CIcewrackExtendedEntity:GetStamina()
    return self.Stamina
end

function CIcewrackExtendedEntity:GetMaxStamina()
    return (self.StaminaMax + self.StaminaMaxBonus + (self:GetAttributeValue(IW_ATTRIBUTE_VIGOR) * 0.25)) * (1.0 + self.MaxStaminaPercentBonus)
end

function CIcewrackExtendedEntity:GetDrainEffectiveness()
	return self.DrainEffectiveness
end

function CIcewrackExtendedEntity:GetAttackingList()
	return self._tAttacking
end

function CIcewrackExtendedEntity:GetAttackedByList()
	return self._tAttackedBy
end

function CIcewrackExtendedEntity:RefreshHealthRegen()
	local fMaxLifestealPerSec = self:GetMaxHealth() * self.LifestealRate
	self:SetBaseHealthRegen(self.HealthRegen + self.HealthRegenBonus + self:GetAttributeValue(IW_ATTRIBUTE_VIGOR) * 0.05 + math.min(self.LifestealRegenBonus, fMaxLifestealPerSec))
end

function CIcewrackExtendedEntity:AddLifesteal(fAmount)
	local fLifestealDuration = self.LifestealDuration * math.max(0, 1.0 + self.LifestealDurationBonus)
	if fLifestealDuration == 0 then
		self:ModifyHealth(self:GetHealth() + math.min(fAmount, self:GetMaxHealth() * self.LifestealRate), self, true, 0)
	else
		local fLifestealPerSec = fAmount/fLifestealDuration
		self.LifestealRegenBonus = self.LifestealRegenBonus + fLifestealPerSec
		self:RefreshHealthRegen()
		
		CTimer(function()
				self.LifestealRegenBonus = self.LifestealRegenBonus - fLifestealPerSec
				self:RefreshHealthRegen()
			end, fLifestealDuration)
	end
end

function CIcewrackExtendedEntity:RefreshManaRegen()
	local fMaxManastealPerSec = self:GetMaxMana() * self.ManastealRate
	self:SetBaseManaRegen(self.ManaRegen + self.ManaRegenBonus + self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 0.05 + math.min(self.ManastealRegenBonus, fMaxManastealPerSec))
end

function CIcewrackExtendedEntity:AddManasteal(fAmount)
	local fManastealDuration = self.ManastealDuration * math.max(0, 1.0 + self.ManastealDurationBonus)
	if fManastealDuration == 0 then
		self:GiveMana(math.min(fAmount, self:GetMaxMana() * self.ManastealRate))
	else
		local fManastealPerSec = fAmount/fManastealDuration
		self.ManastealRegenBonus = self.ManastealRegenBonus + fManastealPerSec
		self:RefreshManaRegen()
		
		CTimer(function()
				self.ManastealRegenBonus = self.ManastealRegenBonus - fManastealPerSec
				self:RefreshManaRegen()
			end, fManastealDuration)
	end
end

function CIcewrackExtendedEntity:RegenerateStamina()
	local fStamina = self.Stamina
	local fMaxStamina = self:GetMaxStamina()
	if fStamina < fMaxStamina and GameRules:GetGameTime() > self._fStaminaRegenTime then
		if fStamina == 0 then
			self:RemoveModifierByName("modifier_internal_stamina_drain_slow")
		end
		local fStaminaRegen = self.StaminaRegen + self.StaminaRegenBonus + (self:GetAttributeValue(IW_ATTRIBUTE_VIGOR) * 0.05)
		if self:HasModifier("modifier_internal_walk_buff") then
			fStaminaRegen = fStaminaRegen * 0.2
		end
		self.Stamina = math.max(0.0, math.min(fMaxStamina, fStamina + fStaminaRegen/30.0))
	elseif fStamina > fMaxStamina then
		self.Stamina = fMaxStamina
	end
end

function CIcewrackExtendedEntity:ApplyModifierProperties(tProperties, bRemove)
	if tProperties then
		for k,v in pairs(tProperties) do
			local szValueName = _G[k]
			if szValueName and self._tPropertiesBonus[szValueName] then
				self._tPropertiesBonus[szValueName] = self._tPropertiesBonus[szValueName] + (bRemove and -v or v)
			end
		end
		self:CalculateStatBonus()
	end
end

function CIcewrackExtendedEntity:CanCastAbility(szAbilityName, hTarget)
	if not self:IsSilenced() then
		local hAbility = self:FindAbilityByName(szAbilityName)
		if hAbility and hAbility:GetCooldownTimeRemaining() == 0 and hAbility:IsFullyCastable() then
			if IsValidEntity(hTarget) then
				local nActionBehavior = hAbility:GetBehavior()
				if bit32.btest(nActionBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET) then
					local nTargetTeam = hAbility:GetAbilityTargetTeam()
					if nTargetTeam == DOTA_UNIT_TARGET_TEAM_ENEMY and hTarget:GetTeamNumber() == hEntity:GetTeamNumber() then
						return false
					elseif nTargetTeam == DOTA_UNIT_TARGET_TEAM_FRIENDLY and hTarget:GetTeamNumber() ~= hEntity:GetTeamNumber() then
						return false
					end
				end
			end
			return true
		end
	end
	return false
end

function CIcewrackExtendedEntity:IssueOrder(nOrder, hTarget, hAbility, vPosition, bQueue)
    local nTargetIndex = nil
    if IsValidEntity(hTarget) then
        nTargetIndex = hTarget:entindex()
    end
    
    local nAbilityIndex = nil
    if IsValidEntity(hAbility) then
        nAbilityIndex = hAbility:entindex()
    end
    
    local tNextOrder =
    {
        UnitIndex = self:entindex(),
        OrderType = nOrder,
        TargetIndex = nTargetIndex,
        AbilityIndex = nAbilityIndex,
        Position = vPosition,
        Queue = bQueue
    }
    
    ExecuteOrderFromTable(tNextOrder)
end

function CIcewrackExtendedEntity:CalculateStatBonus()
    --Based off of bitfield technique from
    --https://developer.valvesoftware.com/wiki/Dota_2_Workshop_Tools/Scripting/Using_Bitfields_To_Adjust_Stat_Value_Bonuses
    
    local tBitTable = { 32768, 16384, 8192, 4096, 2048, 1024, 512, 256, 128, 64, 32, 16, 8, 4, 2, 1 }
    
    --Vigor health regen bonus (0.03 HP/sec per point)
    self:RefreshHealthRegen()
    
    --Vigor health bonus (2.50 HP per point)
    local fHealthBonus = self:GetAttributeValue(IW_ATTRIBUTE_VIGOR) * 2.50 * (1.0 + self.MaxHealthPercentBonus)
    for k,v in ipairs(tBitTable) do
        local szModifierName = "modifier_mod_health_" .. v
        if v <= fHealthBonus then
            if not self:HasModifier(szModifierName) then
                CIcewrackExtendedEntity._shHealthModifier:ApplyDataDrivenModifier(self, self, "modifier_mod_health_" .. v, {})
            end
            fHealthBonus = fHealthBonus - v
        else
            self:RemoveModifierByName(szModifierName)
        end
    end
    
    --Wisdom mana regen bonus (0.05 MP/sec per point)
    self:RefreshManaRegen()
	
    --Wisdom mana bonus (1.00 MP per point)
    local fManaBonus = self:GetAttributeValue(IW_ATTRIBUTE_WISDOM) * 1.0 * (1.0 + self.MaxManaPercentBonus)
    local _shManaModifier = CreateItem("mod_mana", nil, nil) 
    for k,v in ipairs(tBitTable) do
        local szModifierName = "modifier_mod_mana_" .. v
        if v <= fManaBonus then
            if not self:HasModifier(szModifierName) then
                CIcewrackExtendedEntity._shManaModifier:ApplyDataDrivenModifier(self, self, "modifier_mod_mana_" .. v, {})
            end
            fManaBonus = fManaBonus - v
        else
            self:RemoveModifierByName(szModifierName)
        end
    end
    
    --Agility attack speed bonus (1.00% per point)
    local fIASBonus = self:GetAttributeValue(IW_ATTRIBUTE_AGILITY) * 1.00
    local _shIASModifier = CreateItem("mod_ias", nil, nil) 
    for k,v in ipairs(tBitTable) do
        local szModifierName = "modifier_mod_ias_" .. v
        if v <= fIASBonus then
            if not self:HasModifier(szModifierName) then
                CIcewrackExtendedEntity._shIASModifier:ApplyDataDrivenModifier(self, self, "modifier_mod_ias_" .. v, {})
            end
            fIASBonus = fIASBonus - v
        else
            self:RemoveModifierByName(szModifierName)
        end
    end
	
	if not self:HasModifier("modifier_internal_attack_converter") then
		CIcewrackExtendedEntity._shAttackConverter:ApplyDataDrivenModifier(self, self, "modifier_internal_attack_converter", {})
	end
	if not self:HasModifier("modifier_internal_dodge_cleanup") then
		CIcewrackExtendedEntity._shDodgeCleanup:ApplyDataDrivenModifier(self, self, "modifier_internal_dodge_cleanup", {})
	end
	if not self:HasModifier("modifier_internal_stamina_drain") then
		CIcewrackExtendedEntity._shStaminaDrain:ApplyDataDrivenModifier(self, self, "modifier_internal_stamina_drain", {})
	end
end

function CIcewrackExtendedEntity:DeleteEntity()
	CIcewrackExtendedEntity._stLookupTable[self._hBaseEntity] = nil
	self:RemoveSelf()
end

function OnStaminaDrainMove(args)
	local hEntity = args.caster
	if IsValidEntity(hEntity) and not hEntity:HasModifier("modifier_internal_walk_buff") then
		local hExtEntity = LookupExtendedEntity(hEntity)
		if IsValidExtendedEntity(hExtEntity) then
			hExtEntity._fStaminaRegenTime = GameRules:GetGameTime() + 3.0
			--TODO: Make inventory factor into stamina drain?
			if hExtEntity.Stamina > 0 then
				hExtEntity.Stamina = hExtEntity.Stamina - math.max(0, (0.1 * (hExtEntity.StaminaDrainMove + hExtEntity.StaminaDrainMoveBonus)))
				if hExtEntity.Stamina <= 0 then
					hExtEntity.Stamina = 0
					CIcewrackExtendedEntity._shStaminaDrain:ApplyDataDrivenModifier(hExtEntity, hExtEntity, "modifier_internal_stamina_drain_slow", {})
				end
			end
		end
	end
end

function OnStaminaDrainAttack(args)
	local hEntity = args.caster
	if IsValidEntity(hEntity) then
		local hExtEntity = LookupExtendedEntity(hEntity)
		if IsValidExtendedEntity(hExtEntity) then
			hExtEntity._fStaminaRegenTime = GameRules:GetGameTime() + 3.0
			if hExtEntity.Stamina > 0 then
				hExtEntity.Stamina = hExtEntity.Stamina - math.max(0, (args.Amount * (hExtEntity.StaminaDrainAttack + hExtEntity.StaminaDrainAttackBonus)))
				if hExtEntity.Stamina <= 0 then
					hExtEntity.Stamina = 0
					CIcewrackExtendedEntity._shStaminaDrain:ApplyDataDrivenModifier(hExtEntity, hExtEntity, "modifier_internal_stamina_drain_slow", {})
				end
			end
		end
	end
end

function IsValidExtendedEntity(hExtEntity)
    return (hExtEntity and IsValidEntity(hExtEntity._hBaseEntity) and hExtEntity._bIsExtendedEntity)
end

function LookupExtendedEntity(hEntity)
    if IsValidEntity(hEntity) then
        return CIcewrackExtendedEntity._stLookupTable[hEntity]
    else
        return nil
    end
end