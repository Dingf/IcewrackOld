if _VERSION < "Lua 5.2" then
    bit = require("numberlua")
    bit32 = bit.bit32
end

require("ext_entity")
require("ext_ability")
require("party")
require("aam_search")

--AAM Definitions are stored in two 32-bit integer values:
--First int:
--  Target relationship (2 bits, 4 values)
--  Target selector (4 bits, 15 values)
--  HP < comparisons (3 bits, 7 values)
--  HP >= comparisons (3 bits, 7 values)
--  MP < comparisons (3 bits, 7 values)
--  MP >= comparisons (3 bits, 7 values)
--  SP < comparisons (3 bits, 7 values)
--  SP >= comparisons (3 bits, 7 values)
--  Unit class (3 bits, 7 values)
--  Unit Type (2 bits, 3 values)
--  Unit Subtype (3 bits, 5 values)

--Second int:
--  Unit is dead (1 bit)
--  Unit is a hero/party member (1 bit)
--  Unit is not already affected (1 bit)
--  Unit is not self (1 bit)
--  Unit armor class (2 bits, 3 values)
--  Unit move speed class (2 bits, 3 values)
--  Unit status effects (5 bits, 21 values)
--  Number of other units near the unit (8 bits)
--      Relationship flag (2 bits)
--      Range flag (3 bits)
--      Number of units (3 bits)
--  Save current targets for later conditions (1 bit)
--  Target is attacking <previously saved targets> (1 bit)
--  Target is attacked by <previously saved targets> (1 bit)
--  Target is casting a spell on <previously saved targets> (1 bit)
--  Target has been casted on by <previously saved targets> (1 bit)
--  Number of wounded party members (3 bits, 6 values)
--  Number of other dead party members (3 bits, 5 values)

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
AAM_TARGET_SELECTOR_RANDOM = 14

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

AAM_DESCRIPTOR_ARMOR_LIGHT = 1        --0-10 Armor
AAM_DESCRIPTOR_ARMOR_MEDIUM = 2        --11-30 Armor
AAM_DESCRIPTOR_ARMOR_HEAVY = 3        --31+ Armor

AAM_DESCRIPTOR_BASE_MSPEED_SLOW = 1        --100-300 Movespeed
AAM_DESCRIPTOR_BASE_MSPEED_MEDIUM = 2    --301-420 Movespeed
AAM_DESCRIPTOR_BASE_MSPEED_FAST = 3        --421-522 Movespeed

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
        if IsValidExtendedEntity(hExtEntity) and hExtEntity:GetUnitClass() == nValue then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetUnitType(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
        if IsValidExtendedEntity(hExtEntity) and hExtEntity:GetUnitType() == nValue then
            table.insert(tNewTargetList, v)
        end
    end
    return tNewTargetList
end

function TargetUnitSubtype(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
		local hExtEntity = LookupExtendedEntity(v)
        if IsValidExtendedEntity(hExtEntity) and hExtEntity:GetUnitSubtype() == nValue then
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

function TargetIsHero(nValue, tTargetList)
    local tNewTargetList = {}
    for k,v in pairs(tTargetList) do
        if not v:IsHero() then
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
	local hExtEntity = hAutomator:GetEntity()
	if IsValidExtendedEntity(hExtEntity) then
        local hEntity = hExtEntity._hBaseEntity
        if IsValidEntity(hEntity) then
            for k,v in pairs(tTargetList) do
                if v ~= hEntity then
                    table.insert(tNewTargetList, v)
                end
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
		if IsValidExtendedEntity(hExtEntity) then
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
		if IsValidExtendedEntity(hExtEntity) then
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
		if IsValidExtendedEntity(hExtEntity) then
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

--NYI
function TargetCasting(nValue, tTargetList, hAutomator)
	return tNewTargetList
end

--NYI
function TargetCastedOn(nValue, tTargetList, hAutomator)
	return tNewTargetList
end

function NumberDeadParty(nValue, tTargetList)
	local nCount = 0
    local hActiveMemeberList = CIcewrackParty:GetActiveMembers()
	for k,v in pairs(hActiveMemberList) do
		if IsValidEntity(v) and v:IsAlive() then
			nCount = nCount + 1
		end
	end
	if nCount >= (nValue - 1) then
		return tTargetList
	else
		return {}
	end
end

function NumberWoundedParty(nValue, tTargetList)
	local nCount = 0
    local hActiveMemeberList = CIcewrackParty:GetActiveMembers()
	for k,v in pairs(hActiveMemberList) do
		if IsValidEntity(v) and k:GetHealth() <= (0.5 * v:GetMaxHealth()) then
			nCount = nCount + 1
		end
	end
	if nCount >= (nValue - 1) then
		return tTargetList
	else
		return {}
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
	{TargetIsHero,                 1},
    {TargetNotAlreadyAffected,     1},
	{TargetNotSelf,                1},
    {TargetArmorType,              2},
    {TargetMoveSpeed,              2},
    {TargetHasStatusEffect,        5},
    {TargetNearUnits,              8},
	{SaveTargets,                  1},
	{TargetAttacking,              1},
    {TargetAttackedBy,             1},
	{TargetCasting,                1},        --NYI
	{TargetCastedOn,               1},        --NYI
    {NumberDeadParty,              3},
    {NumberWoundedParty,           3},
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

function SelectByValue(tTargetList, nValueType, bComparison, bPercent)
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

--TODO: Test this function
function SelectByRandom(tTargetList)
	local nRandomIndex = RandomInt(1, #tTableList)
	return tTargetList[nRandomIndex]
end

stAAMSelectorTable =
{
    [AAM_TARGET_SELECTOR_NEAREST]          = function(hEntity, tTargetList) return SelectByDistance(hEntity, tTargetList, false) end,
    [AAM_TARGET_SELECTOR_FARTHEST]         = function(hEntity, tTargetList) return SelectByDistance(hEntity, tTargetList, true) end,
    [AAM_TARGET_SELECTOR_HIGHEST_ABS_HP]   = function(hEntity, tTargetList) return SelectByValue(tTargetList, 0, true,  false) end,
    [AAM_TARGET_SELECTOR_LOWEST_ABS_HP]    = function(hEntity, tTargetList) return SelectByValue(tTargetList, 0, false, false) end,
    [AAM_TARGET_SELECTOR_HIGHEST_PCT_HP]   = function(hEntity, tTargetList) return SelectByValue(tTargetList, 0, true,  true)  end,
    [AAM_TARGET_SELECTOR_LOWEST_PCT_HP]    = function(hEntity, tTargetList) return SelectByValue(tTargetList, 0, false, true)  end,
    [AAM_TARGET_SELECTOR_HIGHEST_ABS_MP]   = function(hEntity, tTargetList) return SelectByValue(tTargetList, 1, true,  false) end,
    [AAM_TARGET_SELECTOR_LOWEST_ABS_MP]    = function(hEntity, tTargetList) return SelectByValue(tTargetList, 1, false, false) end,
    [AAM_TARGET_SELECTOR_HIGHEST_PCT_MP]   = function(hEntity, tTargetList) return SelectByValue(tTargetList, 1, true,  true)  end,
    [AAM_TARGET_SELECTOR_LOWEST_PCT_MP]    = function(hEntity, tTargetList) return SelectByValue(tTargetList, 1, false, true)  end,
    [AAM_TARGET_SELECTOR_HIGHEST_ABS_SP]   = function(hEntity, tTargetList) return SelectByValue(tTargetList, 2, true,  false) end,
    [AAM_TARGET_SELECTOR_LOWEST_ABS_SP]    = function(hEntity, tTargetList) return SelectByValue(tTargetList, 2, false, false) end,
    [AAM_TARGET_SELECTOR_HIGHEST_PCT_SP]   = function(hEntity, tTargetList) return SelectByValue(tTargetList, 2, true,  true)  end,
    [AAM_TARGET_SELECTOR_LOWEST_PCT_SP]    = function(hEntity, tTargetList) return SelectByValue(tTargetList, 2, false, true)  end,
	[AAM_TARGET_SELECTOR_RANDOM]           = function(hEntity, tTargetList) return SelectByRandom(tTargetList) end,
}

