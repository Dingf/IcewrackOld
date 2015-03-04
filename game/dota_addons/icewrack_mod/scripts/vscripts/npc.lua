--[[
    Non-Player Characters
]]

--NPCs are considered to be any non-player extended entities

require("timer")
require("ext_entity")


--Things to add
--  Talk/dialogue (if friendly)
--  Trade options (if friendly)
--  Threat System

if CIcewrackNPC == nil then
    CIcewrackNPC = class({
		constructor = function(self, hExtEntity)
			if not hExtEntity or not hExtEntity._bIsExtendedEntity then
				error("hEntity must be a valid hero entity")
			end
			
			if hExtEntity._hNPCEntity ~= nil then
				self = hExtEntity._hNPCEntity
				return self
			end
			
			self._bIsNPC = true
			self._hEntity = hExtEntity
			hExtEntity._hNPCEntity = self
			
			setmetatable(self, {__index = function(self, k)
				return CIcewrackNPC[k] or self._hEntity[k]
			end})
			
			self._tThreatTable = {}
			self._fThreatRadius = 1200.0
			self._hLastTarget = nil
			
			self._tPatrolList = {}
		
		end,
		{},
		nil})
end

--[[
function CIcewrackNPC:OnDamageTaken(keys)
    local hVictim = EntIndexToHScript(keys.victim)
    local hAttacker = EntIndexToHScript(keys.attacker)
    
    if hVictim and hVictim == thisEntity then
        if self._bIsThreatAI then
            local fThreatMultiplier = keys.threat
            if keys.crit then
                fThreatMultiplier = fThreatMultiplier * 1.5
            end
            self:AddThreat(hAttacker, keys.damage * fThreatMultiplier)
            print(self:GetThreat(hAttacker))
        end
    end
end]]

function CIcewrackNPC:GetThreat(hEntity)
    if hEntity and self._tThreatTable ~= nil then
        if self._tThreatTable[hEntity] ~= nil then
            return self._tThreatTable[hEntity]
        else
            return 0
        end
    end
    return nil
end

function CIcewrackNPC:GetHighestThreatTarget()
    if self._tThreatTable ~= nil then
        local hHighestTarget = nil
        local fHighestThreat = -1
        for k,v in pairs(self._tThreatTable) do
            if v then
                if not k:IsAlive() or k:GetTeamNumber() == self:GetTeamNumber() then
                    self._tThreatTable[k] = nil
                elseif v > fHighestThreat and self:CanEntityBeSeenByMyTeam(k) and not k:IsInvulnerable() then
                    hHighestTarget = k
                    fHighestThreat = v
                end
            end
        end
        return hHighestTarget
    end
    return nil
end

function CIcewrackNPC:AddThreat(hEntity, fAmount)
    if self._tThreatTable ~= nil then
        local fDistance = math.min((self:GetAbsOrigin() - hEntity:GetOrigin()):Length2D(), self._fThreatRadius)
        local fDistanceMultiplier = (0.5 * (1.0 - (fDistance/self._fThreatRadius))) + 0.5
        
        if self._tThreatTable[hEntity] ~= nil then
            self._tThreatTable[hEntity] = self._tThreatTable[hEntity] + (fAmount * fDistanceMultiplier)
        else
            self._tThreatTable[hEntity] = fAmount * fDistanceMultiplier
        end
    end
end

--[[
function CIcewrackDefaultAI:OnThink()
    local hEntity = CIcewrackExtendedEntity.LookupEntity(thisEntity)
    if hEntity and hEntity:IsAlive() then
        local hTarget = self:GetHighestThreatTarget() or GetNearestUnit(hEntity, DOTA_UNIT_TARGET_TEAM_ENEMY, 0.0, hEntity:GetCurrentVisionRange())
        if hTarget ~= nil then
            --Attack the highest threat target, if any (but only if we're not already attacking it)
            --Otherwise attack the nearest enemy unit in range
            if hTarget ~= self._hLastTarget or not hEntity:IsAttackingEntity(hTarget) then
                hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, nil)
                self._hLastTarget = hTarget
            end
        end
    end
    return 0.25
end
]]



function CIcewrackNPC:ClearPatrolList()
	for k,v in pairs(self._tPatrolList) do
		v:StopTimer()
	end
	self._tPatrolList = {}
end

function CIcewrackNPC:AddPatrolPoint(vPatrolPoint, fDuration, fDelay)
	local hPatrolTimer = CTimer(function()
			if self:IsAlive() and not self:GetAttackTarget() then
				self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vPatrolPoint, false)
			elseif not self:IsAlive() then
				return TIMER_STOP
			end
		end, 0, fDuration, fDelay)
	table.insert(self._tPatrolList, hPatrolTimer)
end


