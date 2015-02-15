if _VERSION < "Lua 5.2" then
    bit = require("numberlua")
    bit32 = bit.bit32
end

require("ext_entity")
require("ext_ability")
require("aam_search")

--2 bits
AAM_TARGET_RELATION_SELF = 0
AAM_TARGET_RELATION_FRIENDLY = 1
AAM_TARGET_RELATION_ENEMY = 2
AAM_TARGET_RELATION_ANY = 3

--4 bits
AAM_TARGET_SELECTOR_NEAREST = 0
AAM_TARGET_SELECTOR_FARTHEST = 1
AAM_TARGET_SELECTOR_HIGHEST_ABS_HP = 2
AAM_TARGET_SELECTOR_LOWEST_ABS_HP = 3
AAM_TARGET_SELECTOR_HIGHEST_PCT_HP = 4
AAM_TARGET_SELECTOR_LOWEST_PCT_HP = 5
AAM_TARGET_SELECTOR_HIGHEST_ABS_MP = 6
AAM_TARGET_SELECTOR_LOWEST_ABS_MP = 7
AAM_TARGET_SELECTOR_HIGHEST_PCT_MP = 8
AAM_TARGET_SELECTOR_LOWEST_PCT_MP = 9
AAM_TARGET_SELECTOR_HIGHEST_ABS_SP = 10
AAM_TARGET_SELECTOR_LOWEST_ABS_SP = 11
AAM_TARGET_SELECTOR_HIGHEST_PCT_SP = 12
AAM_TARGET_SELECTOR_LOWEST_PCT_SP = 13

--Min Distance (3 bits, 7 values)
stAAMDistanceLookupTable =
{
    [1] = 300.0,
    [2] = 450.0,
    [3] = 600.0,
    [4] = 750.0,
    [5] = 900.0,
    [6] = 1200.0,
    [7] = 1800.0,
}

--Max Distance (3 bits, 7 values)
--HP < comparisons (3 bits, 7 values)
stAAMThresholdLookupTable =
{
    [1] = 1.00,
    [2] = 0.90,
    [3] = 0.75,
    [4] = 0.50,
    [5] = 0.35,
    [6] = 0.25,
    [7] = 0.10,
    [8] = 0.0000001,
}
--HP >= comparisons (3 bits, 7 values)
--MP < comparisons (3 bits, 7 values)
--MP >= comparisons (3 bits, 7 values)
--SP < comparisons (3 bits, 7 values)
--SP >= comparisons (3 bits, 7 values)
--Unit class (3 bits, 7 values)
--Unit Type (2 bits, 3 values)
--Unit Subtype (3 bits, 5 values)

--Unit is dead (1 bit)
AAM_DESCRIPTOR_UNIT_STATUS_DEAD = 1
--Unit is casting/channeling (1 bit)
AAM_DESCRIPTOR_UNIT_STATUS_CASTING = 1
--Unit is not already affected (1 bit)
AAM_DESCRIPTOR_UNIT_STATUS_NOT_ALREADY_AFFECTED = 1
--Unit is not self (1 bit)
AAM_DESCRIPTOR_UNIT_NOT_SELF = 1
--Unit armor type (2 bits, 3 values)
AAM_DESCRIPTOR_ARMOR_LIGHT = 1        --0-10 Armor
AAM_DESCRIPTOR_ARMOR_MEDIUM = 2        --11-30 Armor
AAM_DESCRIPTOR_ARMOR_HEAVY = 3        --31+ Armor
--Unit speed (2 bits, 3 values)
AAM_DESCRIPTOR_BASE_MSPEED_SLOW = 1        --100-300 Movespeed
AAM_DESCRIPTOR_BASE_MSPEED_MEDIUM = 2    --301-420 Movespeed
AAM_DESCRIPTOR_BASE_MSPEED_FAST = 3        --421-522 Movespeed
--Unit status effects (5 bits, 21 values)
--Unit being attacked by (3 bits, 7 values)
AAM_DESCRIPTOR_ATTACKED_BY_MELEE = 1
AAM_DESCRIPTOR_ATTACKED_BY_RANGED = 2
AAM_DESCRIPTOR_ATTACKED_BY_MAGIC = 4
--Number of units near the unit (8 bits)
    --Relationship flag (2 bits)
    --Range flag (3 bits)
    --Number of units (3 bits)
--Number of wounded party members (3 bits, 6 values)
--Number of other dead party members (3 bits, 5 values)

function DoNothing(nValue, tTargetList)
    return tTargetList
end

function TargetHPLessThan(nValue, tTargetList)
    local fThreshold = stAAMThresholdLookupTable[nValue]
    if not fThreshold then
        return tTargetList
    end
    
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local fPercentHP = v:GetHealth()/v:GetMaxHealth()
        if fPercentHP < fThreshold then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetHPGreqThan(nValue, tTargetList)
    local fThreshold = stAAMThresholdLookupTable[nValue + 1]
    if not fThreshold then
        return tTargetList
    end
    
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local fPercentHP = v:GetHealth()/v:GetMaxHealth()
        if fPercentHP >= fThreshold then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetMPLessThan(nValue, tTargetList)
    local fThreshold = stAAMThresholdLookupTable[nValue]
    if not fThreshold then
        return tTargetList
    end
    
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local fPercentMP = v:GetMana()/v:GetMaxMana()
        if fPercentMP < fThreshold then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetMPGreqThan(nValue, tTargetList)
    local fThreshold = stAAMThresholdLookupTable[nValue + 1]
    if not fThreshold then
        return tTargetList
    end
    
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local fPercentMP = v:GetMana()/v:GetMaxMana()
        if fPercentMP >= fThreshold then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetSPLessThan(nValue, tTargetList)
    local fThreshold = stAAMThresholdLookupTable[nValue]
    if not fThreshold then
        return tTargetList
    end
    
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local hExtEntity = CIcewrackExtendedEntity(v)
        if hExtEntity then
            local fPercentSP = hExtEntity:GetStamina()/hExtEntity:GetMaxStamina()
            if fPercentSP < fThreshold then
                table.insert(tNewTargetList, v)
            end
        end
    end
    return tNewTargetList
end

function TargetSPGreqThan(nValue, tTargetList)
    local fThreshold = stAAMThresholdLookupTable[nValue + 1]
    if not fThreshold then
        return tTargetList
    end
    
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local hExtEntity = LookupExtendedEntity(v)
        if hExtEntity then
            local fPercentSP = hExtEntity:GetStamina()/hExtEntity:GetMaxStamina()
            if fPercentSP >= fThreshold then
                table.insert(tNewTargetList, v)
            end
        end
    end
    return tNewTargetList
end

function TargetUnitClass(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
        if hExtEntity and hExtEntity._bIsExtendedEntity and hExtEntity:GetUnitClass() == nValue then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetUnitType(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
        if hExtEntity and hExtEntity._bIsExtendedEntity and hExtEntity:GetUnitType() == nValue then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetUnitSubtype(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
        if hExtEntity and hExtEntity._bIsExtendedEntity and hExtEntity:GetUnitSubtype() == nValue then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetIsDead(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        if not v:IsAlive() then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetIsAttacking(nValue, tTargetList)
	local tNewTargetList = {}
	for k,v in pairs(tTargetList) do
		local tAttackingList = v:GetAttackingList() or {}
		if v:GetAttackTarget() ~= nil or next(tAttackingList) ~= nil then
			table.insert(tNewTargetList, v)
		end
	end
end

function TargetIsCasting(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        if v:GetCurrentActiveAbility() ~= nil then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

--Note: In order for this evaluator to work, all modifiers must follow the dota naming convention
--i.e. modifier_<ability_name>, where "ability_name" is the name of the parent ability
function TargetNotAlreadyAffected(nValue, tTargetList, hAutomator)
    local hAction = hAutomator:GetCurrentAction()
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        if not v:HasModifier("modifier_" .. hAction:GetName()) then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetNotSelf(nValue, tTargetList, hAutomator)
    local tNewTargetList = {}
	local hEntity = hAutomator:GetEntity()
    local hBaseEntity = hEntity._hBaseEntity
    if hEntity._bIsExtendedEntity and hBaseEntity then
        for k,v in pairs(tTargetList) do
            if v ~= hBaseEntity then
                table.insert(tNewTargetList, v)
            end
        end
    end
    return tNewTargetList
end

function TargetArmorType(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local fArmorValue = v:GetPhysicalArmorValue()
        if nValue == AAM_DESCRIPTOR_ARMOR_LIGHT and fArmorValue < 10.0 then
            table.insert(tNewTargetList, v)
        elseif nValue == AAM_DESCRIPTOR_ARMOR_MEDIUM and fArmorValue >= 10.0 and fArmorValue < 30.0 then
            table.insert(tNewTargetList, v)
        elseif nValue == AAM_DESCRIPTOR_ARMOR_HEAVY and fArmorValue >= 30.0 then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetMoveSpeed(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local fMoveSpeed = v:GetMoveSpeedModifier(v:GetBaseMoveSpeed())
        if nValue == AAM_DESCRIPTOR_BASE_MSPEED_SLOW and fMoveSpeed < 250.0 then
            table.insert(tNewTargetList, v)
        elseif nValue == AAM_DESCRIPTOR_BASE_MSPEED_MEDIUM and fMoveSpeed >= 250.0 and fMoveSpeed < 400.0 then
            table.insert(tNewTargetList, v)
        elseif nValue == AAM_DESCRIPTOR_BASE_MSPEED_FAST and fMoveSpeed >= 400.0 then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end


function TargetHasStatusEffect(nValue, tTargetList)
	local tNewTargetList = {}
	for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
		if hExtEntity and hExtEntity._bIsExtendedEntity then
			local tModifierList = hExtEntity:GetExtendedModifierList()
			for k2,v2 in pairs(tModifierList) do
				local nStatusEffect = k2:GetStatusEffect()
				if nStatusEffect == nValue or (nValue == IEA_STATUS_EFFECT_ANY and nStatusEffect ~= IEA_STATUS_EFFECT_NONE) then
					table.insert(tNewTargetList, v)
					break
				end
			end
		end
	end
	return tNewTargetList
end

function SaveTargets(nValue, tTargetList, hAutomator)
	local tNewTargetList = {}
	for k,v in pairs(tTargetList) do
		tNewTargetList[v] = true
	end
	
	hAutomator._tSavedTargets = tNewTargetList
	return tTargetList
end

function TargetAttacking(nValue, tTargetList, hAutomator)
	local tNewTargetList = {}
	for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
		if hExtEntity and hExtEntity._bIsExtendedEntity then
			local tAttackingList = hExtEntity:GetAttackingList()
			local tSavedTargets = hAutomator._tSavedTargets
			if tAttackingList and tSavedTargets and next(tSavedTargets) then
				for k2,v2 in pairs(tAttackingList) do
					if tSavedTargets[k2._hBaseEntity] then
						table.insert(tNewTargetList, v)
						break
					end
				end
				return tNewTargetList
			end
		end
	end
	return tNewTargetList
end

function TargetAttackedBy(nValue, tTargetList, hAutomator)
    local tNewTargetList = {}
	for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
		if hExtEntity and hExtEntity._bIsExtendedEntity then
			local tAttackedByList = hExtEntity:GetAttackedByList()
			local tSavedTargets = hAutomator._tSavedTargets
			if tAttackedByList and tSavedTargets and next(tSavedTargets) then
				for k2,v2 in pairs(tAttackedByList) do
					if tSavedTargets[k2] then
						table.insert(tNewTargetList, v)
						break
					end
				end
				return tNewTargetList
			end
		end
	end
	return tNewTargetList
end

function TargetNearUnits(nValue, tTargetList, hAutomator)
	local hEntity = hAutomator:GetEntity()
    local nRelationship = bit32.extract(nValue, 0, 2)
    local fRange = stAAMDistanceLookupTable[bit32.extract(nValue, 2, 3)]
    local nAmount = bit32.extract(nValue, 5, 3)

    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        local tUnitsList = FindUnitsInRadius(hEntity:GetTeamNumber(), v:GetAbsOrigin(), nil, fRange, nRelationship, DOTA_UNIT_TARGET_ALL, 0, 0, false)
        local nCount = 0
        for k2,v2 in pairs(tUnitsList) do
            if v2 ~= v then                --Ignore self when counting
                nCount = nCount + 1
            end
        end
        if nCount >= nAmount then 
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function NumberDeadParty(nValue, tTargetList)
    if nValue ~= 0 then
        for k,v in pairs(tTargetList) do
        
        end
        return tTargetList
    else
        return tTargetList
    end
end

function NumberWoundedParty(nValue, tTargetList)
    if nValue ~= 0 then
        --Not yet implemented
        return tTargetList
    else
        return tTargetList
    end
end

stConditionTable = 
{
    {DoNothing,                    6},
    {TargetHPLessThan,             3},
    {TargetHPGreqThan,             3},
    {TargetMPLessThan,             3},
    {TargetMPGreqThan,             3},
    {TargetSPLessThan,             3},
    {TargetSPGreqThan,             3},
    {TargetUnitClass,              3},
    {TargetUnitType,               2},
    {TargetUnitSubtype,            3},
    
    {TargetIsDead,                 1},
	{TargetIsAttacking,            1},
    {TargetIsCasting,              1},
    {TargetNotAlreadyAffected,     1},
	{TargetNotSelf,                1},
    {TargetArmorType,              2},
    {TargetMoveSpeed,              2},
    {TargetHasStatusEffect,        5},
    {TargetNearUnits,              8},
    {NumberDeadParty,              3},        --NYI
    {NumberWoundedParty,           3},        --NYI
	{SaveTargets,                  1},
	{TargetAttacking,              1},
    {TargetAttackedBy,             1},
	{TargetCastingOn,              1},        --NYI
}

function SelectByDistance(hEntity, tTargetList, bComparison)
    local hSelectedEntity = nil
    local fBestDistance = nil
    for k,v in pairs(tTargetList) do
        if v then
            local fDistance = (hEntity:GetAbsOrigin() - v:GetAbsOrigin()):Length2D()
            if not fBestDistance or ((bComparison and fDistance > fBestDistance) or (not bComparison and fDistance < fBestDistance)) then
                hSelectedEntity = v
                fBestDistance = fDistance
            end
        end
    end
    return hSelectedEntity
end

function SelectByValue(hEntity, tTargetList, nValueType, bComparison, bPercent)
    local hSelectedEntity = nil
    local fBestValue = nil
    for k,v in pairs(tTargetList) do
        if v then
            local fValue = nil
            if nValueType == 0 then            --Health
                fValue = bPercent and v:GetHealth()/v:GetMaxHealth() or v:GetHealth()
            elseif nValueType == 1 then        --Mana
                fValue = bPercent and v:GetMana()/v:GetMaxMana() or v:GetMana()
            elseif nValueType == 2 then        --Stamina
                fValue = bPercent and v:GetStamina()/v:GetMaxStamina() or v:GetStamina()
            end
            if fValue then
                if fValue == fBestValue and hSelectedEntity and v:entindex() < hSelectedEntity:entindex()then
                    hSelectedEntity = v
                elseif not fBestValue or (bComparison and fValue > fBestValue) or (not bComparison and fValue < fBestValue) then
                    hSelectedEntity = v
                    fBestValue = fValue
                end
            end
        end
    end
    return hSelectedEntity
end


stAAMSelectorTable =
{
    [AAM_TARGET_SELECTOR_NEAREST]          = function(hEntity, tTargetList) return SelectByDistance(hEntity, tTargetList, false) end,
    [AAM_TARGET_SELECTOR_FARTHEST]         = function(hEntity, tTargetList) return SelectByDistance(hEntity, tTargetList, true) end,
    [AAM_TARGET_SELECTOR_HIGHEST_ABS_HP]   = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 0, true,  false) end,
    [AAM_TARGET_SELECTOR_LOWEST_ABS_HP]    = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 0, false, false) end,
    [AAM_TARGET_SELECTOR_HIGHEST_PCT_HP]   = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 0, true,  true)  end,
    [AAM_TARGET_SELECTOR_LOWEST_PCT_HP]    = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 0, false, true)  end,
    [AAM_TARGET_SELECTOR_HIGHEST_ABS_MP]   = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 1, true,  false) end,
    [AAM_TARGET_SELECTOR_LOWEST_ABS_MP]    = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 1, false, false) end,
    [AAM_TARGET_SELECTOR_HIGHEST_PCT_MP]   = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 1, true,  true)  end,
    [AAM_TARGET_SELECTOR_LOWEST_PCT_MP]    = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 1, false, true)  end,
    [AAM_TARGET_SELECTOR_HIGHEST_ABS_SP]   = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 2, true,  false) end,
    [AAM_TARGET_SELECTOR_LOWEST_ABS_SP]    = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 2, false, false) end,
    [AAM_TARGET_SELECTOR_HIGHEST_PCT_SP]   = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 2, true,  true)  end,
    [AAM_TARGET_SELECTOR_LOWEST_PCT_SP]    = function(hEntity, tTargetList) return SelectByValue(hEntity, tTargetList, 2, false, true)  end,
}

