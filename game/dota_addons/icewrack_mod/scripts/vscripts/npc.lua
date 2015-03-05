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
			
			table.insert(hExtEntity._tOnTakeDamageList, function(keys) self:OnDamageTaken(keys) end)
			
			self._vOriginalLook = nil
			self._hLookTarget = nil
			CTimer(function()
					if not self:IsAlive() then
						return TIMER_STOP
					elseif self._vOriginalLook then
						local vNewLook = self._vOriginalLook
						local vOldLook = self:GetForwardVector():Normalized()
						if self._hLookTarget then
							if CalcDistanceBetweenEntityOBB(self, self._hLookTarget) > 250 then
								self._hLookTarget = nil
							else
								vNewLook = (self._hLookTarget:GetAbsOrigin() - self:GetAbsOrigin()):Normalized()
							end
						end
						
						local fCosTheta = vNewLook:Dot(vOldLook)
						--Note: cos(theta) should never be outside the range [-1, 1]. However, due to floating-point imprecision,
						--it happens sometimes (which produces a NaN result when we try to math.acos it)
						if math.abs(fCosTheta) > 1 or math.acos(fCosTheta) < self._fTurnRate then
							self:SetForwardVector(vNewLook)
							if self._hLookTarget == nil then
								self._vOriginalLook = nil
							end
						else
							local hCos = math.cos
							local hSin = math.sin
							local fTheta = self._fTurnRate
							local fX = vOldLook.x
							local fY = vOldLook.y
							local fZ = vOldLook.z
							
							local vLook1 = Vector(fX * hCos(fTheta) + fY * hSin(fTheta), fY * hCos(fTheta) - fX * hSin(fTheta), fZ)
							if vLook1:Dot(vNewLook) > vOldLook:Dot(vNewLook) then
								self:SetForwardVector(vLook1)
							else
								self:SetForwardVector(Vector(fX * hCos(fTheta) - fY * hSin(fTheta), fY * hCos(fTheta) + fX * hSin(fTheta), fZ))
							end
						end
					end
				end, 0, TIMER_THINK_INTERVAL)
			
			self._tPatrolList = {}
			
		
		end,
		{},
		nil})
end

function CIcewrackNPC:OnDamageTaken(keys)
    local hVictim = EntIndexToHScript(keys.victim)
    local hAttacker = EntIndexToHScript(keys.attacker)
    
    if hVictim and hAttacker then
        if self._bIsThreatAI then
            local fThreatMultiplier = keys.threat
            if keys.crit then
                fThreatMultiplier = fThreatMultiplier * 1.5
            end
            self:AddThreat(hAttacker, keys.damage * fThreatMultiplier)
        end
    end
end

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

function CIcewrackNPC:SetOriginalLook(vPoint)

end

function CIcewrackNPC:ClearLookTarget()
	self._hLookTarget = nil
end

function CIcewrackNPC:SetLookTarget(hEntity)
	if not self._vOriginalLook then
		self._vOriginalLook = self:GetForwardVector()
	end
	self._hLookTarget = hEntity
end

function NPCInteract(args)
	if args.target and args.unit and args.target:GetTeamNumber() == args.unit:GetTeamNumber() then
		local hExtTarget = LookupExtendedEntity(args.target)
		local hNPCEntity = hExtTarget._hNPCEntity
		if hExtTarget and hExtTarget._bIsExtendedEntity then
			local hExtEntity = LookupExtendedEntity(args.unit)
			if hExtEntity and hExtEntity._bIsExtendedEntity then
				local fDistance = CalcDistanceBetweenEntityOBB(args.target, args.unit)
				if fDistance <= 150 then
					if hExtEntity._hLastLookTarget then
						hExtEntity._hLastLookTarget:ClearLookTarget()
					end
					if hNPCEntity then
						hNPCEntity:SetLookTarget(args.unit)
						hExtEntity._hLastLookTarget = hNPCEntity
						--TODO: Interaction code here (dialogue, trade menus, etc.)
					end
				else
					hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, args.target, nil, nil, true)
					if hNPCEntity then
						if hExtEntity._hMoveToTalkTimer then
							hExtEntity._hMoveToTalkTimer:StopTimer()
						end
						if hExtEntity._hLastLookTarget then
							hExtEntity._hLastLookTarget:ClearLookTarget()
						end
						hExtEntity._hLastLookTarget = hNPCEntity
						hExtEntity._hMoveToTalkTimer = CTimer(function()
								if hExtEntity._hLastLookTarget ~= hNPCEntity then
									return TIMER_STOP
								elseif CalcDistanceBetweenEntityOBB(args.target, args.unit) <= 150 then
									hExtEntity:Stop()
									hNPCEntity:SetLookTarget(args.unit)
									--TODO: Interaction code here (dialogue, trade menus, etc.)
									return TIMER_STOP
								end
							end, 0, TIMER_THINK_INTERVAL)
					end
				end
			end
		end
	end
end
