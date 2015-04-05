--[[
    Non-Player Characters
]]

--NPCs are considered to be any non-player extended entities

require("timer")
require("ext_entity")
require("game_states")

--Things to add
--  Trade options (if friendly)
--  NPC Behaviors via AAM

IW_NPC_BEHAVIOR_AGGRESSIVE = 0
IW_NPC_BEHAVIOR_DEFENSIVE = 1
IW_NPC_BEHAVIOR_PASSIVE = 2

tDialogueNodeValues = nil

if CIcewrackNPC == nil then
    tDialogueNodeValues = LoadKeyValues("scripts/npc/iw_dialogue_nodes.txt")
    if not tDialogueNodeValues then
        error("Could not load key values from dialogue node data")
    end

    CIcewrackNPC = class({
		constructor = function(self, hExtEntity, nRefID)
			if not IsValidExtendedEntity(hExtEntity) then
				error("hEntity must be a valid hero entity")
			end
			
			if hExtEntity._hNPCEntity ~= nil then
				self = hExtEntity._hNPCEntity
				return self
			end
			
			self._bIsNPC = true
			self._hExtEntity = hExtEntity
			hExtEntity._hNPCEntity = self
			
			self._nRefID = nRefID	--This should be set when the unit is spawned
			CIcewrackNPC._stRefIDLookupTable[nRefID] = self
			
			setmetatable(self, {__index = function(self, k)
				return CIcewrackNPC[k] or self._hExtEntity[k]
			end})
			
			self._nBehavior = IW_NPC_BEHAVIOR_PASSIVE
			
			self._hLastAttackTarget = nil
			self._tThreatTable = {}
			self._fThreatRadius = 1200.0
			
			table.insert(hExtEntity._tOnTakeDamageList, function(keys) self:OnDamageTaken(keys) end)
			
			self._vOriginalLook = nil
			self._hLookTarget = nil
			
			self._tDialogueNodes = {}
			for k,v in pairs(tDialogueNodeValues) do
				if v["RefID"] == nRefID and v["Priority"] ~= 0 then
					self._tDialogueNodes[v] = tonumber(k)
				end
			end
			
			self._bWaypointActive = false
			self._nNextMoveTime = 0
			self._nLastWaypointID = -1
			self._nNextWaypointID = -1
			
			self._bStuckFlag = true
			self._vLastPosition = nil
			self._nStuckCounter = 0
			
			CTimer(function() return self:OnThink() end, 0, TIMER_THINK_INTERVAL)
		end},
		{ _stWaypointTable = {},
		  _stRefIDLookupTable = {} },
		nil)
end

function CIcewrackNPC:OnDamageTaken(keys)
    local hVictim = EntIndexToHScript(keys.victim)
    local hAttacker = EntIndexToHScript(keys.attacker)
    
    if IsValidEntity(hVictim) and IsValidEntity(hAttacker) then
        local fThreatMultiplier = keys.threat
        if keys.crit then
            fThreatMultiplier = fThreatMultiplier * 1.5
        end
        self:AddThreat(hAttacker, keys.damage * fThreatMultiplier)
    end
end

function CIcewrackNPC:GetThreat(hEntity)
    if IsValidEntity(hEntity) and self._tThreatTable ~= nil then
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
			if not IsValidEntity(k) or not k:IsAlive() or k:GetTeamNumber() == self:GetTeamNumber() then
				self._tThreatTable[k] = nil
			elseif v > fHighestThreat and self:CanEntityBeSeenByMyTeam(k) and not k:IsInvulnerable() then
				hHighestTarget = k
				fHighestThreat = v
			end
		end
		return hHighestTarget
	end
    return nil
end

function CIcewrackNPC:AddThreat(hEntity, fAmount)
    if IsValidEntity(hEntity) and self._tThreatTable ~= nil and fAmount > 0 then
        local fDistance = math.min((self:GetAbsOrigin() - hEntity:GetOrigin()):Length2D(), self._fThreatRadius)
        local fDistanceMultiplier = (0.5 * (1.0 - (fDistance/self._fThreatRadius))) + 0.5
        
        if self._tThreatTable[hEntity] ~= nil then
            self._tThreatTable[hEntity] = self._tThreatTable[hEntity] + (fAmount * fDistanceMultiplier)
        else
            self._tThreatTable[hEntity] = fAmount * fDistanceMultiplier
        end
    end
end

function CIcewrackNPC:OnThink()
	--Stop thinking if we're already dead/deleted
	if not IsValidExtendedEntity(self._hExtEntity) then
		return TIMER_STOP
	end
	
	local nCurrentTime = GameRules:GetGameTime()
	local hExtEntity = self._hExtEntity
    local hTarget = self:GetHighestThreatTarget()

	--Attack the highest threat target, if it exists
	if hTarget and self:GetAttackCapability() ~= DOTA_UNIT_CAP_NO_ATTACK then
		if hTarget ~= self._hLastAttackTarget or not self:IsAttackingEntity(hTarget) then
			self:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, nil)
			self._hLastAttackTarget = hTarget
		end
	--Turn to face the player, if the player interacts with the NPC
	elseif self._vOriginalLook then
		local vNewLook = self._vOriginalLook
		local vOldLook = self:GetForwardVector():Normalized()
		if IsValidEntity(self._hLookTarget) then
			if CalcDistanceBetweenEntityOBB(self, self._hLookTarget) > 250 then
				self._hLookTarget = nil
			else
				vNewLook = (self._hLookTarget:GetAbsOrigin() - self:GetAbsOrigin()):Normalized()
			end
		else
	        self._hLookTarget = nil
		end
		
		if not self:IsIdle() then
			self:Hold()
		end
		local fCosTheta = math.min(1, math.max(-1, vNewLook:Dot(vOldLook)))
		--Note: cos(theta) should never be outside the range [-1, 1]. However, due to floating-point imprecision,
		--it happens sometimes (which produces a NaN result when we try to math.acos it)
		if math.acos(fCosTheta) < self._fTurnRate then
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
							
			local v1 = Vector(fX * hCos(fTheta) + fY * hSin(fTheta), fY * hCos(fTheta) - fX * hSin(fTheta), fZ)
			if v1:Dot(vNewLook) > vOldLook:Dot(vNewLook) then
				self:SetForwardVector(v1)
			else
				self:SetForwardVector(Vector(fX * hCos(fTheta) - fY * hSin(fTheta), fY * hCos(fTheta) + fX * hSin(fTheta), fZ))
			end
		end
	--Otherwise, move to the next waypoint, if it exists
	elseif self._bWaypointActive and self:HasMovementCapability() and nCurrentTime >= self._nNextMoveTime then
		--TODO: Handle relative waypoints as well
		local tNextWaypoint = CIcewrackNPC._stWaypointTable[self._nNextWaypointID]
		local vNextPosition = tNextWaypoint["Position"]
		
		if self:GetAbsOrigin() == self._vLastPosition and not self._bStuckFlag then
			self._nStuckCounter = self._nStuckCounter + 1
		else
			self._nStuckCounter = 0
			self._vLastPosition = self:GetAbsOrigin()
		end
		
		local fNextDistance = (self:GetAbsOrigin() - vNextPosition):Length2D()
		if fNextDistance < 16 or self._nStuckCounter >= 30 or tNextWaypoint._bIsOccupied then
			self:Stop()
			if self._nStuckCounter >= 30 then
				self._bStuckFlag = true
				self._nStuckCounter = 0
			else
				self._bStuckFlag = false
			end
			local fRand = RandomFloat(0.0, 1.0)
			local tNewWaypoint = tNextWaypoint["Next"][self._nLastWaypointID]
			for k,v in pairs(tNewWaypoint) do
				if fRand <= v then
					self._nLastWaypointID = self._nNextWaypointID
					self._nNextWaypointID = k
					if fNextDistance < 16.0 then
						local nLingerMin = tNextWaypoint["LingerMin"]
						local nLingerMax = tNextWaypoint["LingerMax"]
						if nLingerMin and nLingerMax then
							local nLingerTime = RandomFloat(nLingerMin, nLingerMax)
							if nLingerTime > 0 then
								self._nNextMoveTime = nCurrentTime + nLingerTime
								tNextWaypoint._bIsOccupied = true
								CTimer(function() tNextWaypoint._bIsOccupied = false end, nLingerTime)
							end
						end
					end
					break
				else
					fRand = fRand - v
				end
			end
		end
        self:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, vNextPosition, true)
	end
	return true
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

function CIcewrackNPC:Talk()
	local tAvailableNodes = {}
	for k,v in pairs(self._tDialogueNodes) do
		local tDialogueNode = k
		if tDialogueNode and tDialogueNode["Preconditions"] and tDialogueNode["Priority"] then
			local bAddFlag = true
			for k2,v2 in pairs(tDialogueNode["Preconditions"]) do
				if not EvaluatePrecondition(k2,v2) then
					bAddFlag = false
					break
				end
			end
			if bAddFlag then
				tAvailableNodes[v] = tDialogueNode["Priority"]
			end
		end
	end
	if tAvailableNodes and next(tAvailableNodes) then
		local nBestPriority = 0
		local nBestNodeID = nil
		for k,v in pairs(tAvailableNodes) do
			if v > nBestPriority then
				nBestPriority = v
				nBestNodeID = k
			end
		end
		if nBestNodeID then
			FireGameEvent("iw_ui_dialogue_set_node", { unit_name = self:GetDisplayName(), node = nBestNodeID });
		end
	end
end

function OnNPCClicked(args)
	if IsValidEntity(args.target) and IsValidEntity(args.unit) and args.target:GetTeamNumber() == args.unit:GetTeamNumber() then
		local hExtTarget = LookupExtendedEntity(args.target)
		local hNPCEntity = hExtTarget._hNPCEntity
		if IsValidExtendedEntity(hExtTarget) then
			local hExtEntity = LookupExtendedEntity(args.unit)
			if IsValidExtendedEntity(hExtEntity) then
				local fDistance = CalcDistanceBetweenEntityOBB(args.target, args.unit)
				if fDistance <= 128 then
					if hExtEntity._hLastLookTarget then
						hExtEntity._hLastLookTarget:ClearLookTarget()
					end
					if hNPCEntity then
						hExtEntity:Hold()
						hNPCEntity:SetLookTarget(args.unit)
						hExtEntity._hLastLookTarget = hNPCEntity
						hNPCEntity:Talk()
					end
				else
					hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_TARGET, args.target, nil, nil, true)
					if hNPCEntity then
						if hExtEntity._hMoveToNPCTimer then
							hExtEntity._hMoveToNPCTimer:StopTimer()
						end
						if hExtEntity._hLastLookTarget then
							hExtEntity._hLastLookTarget:ClearLookTarget()
						end
						hExtEntity._hLastLookTarget = hNPCEntity
						hExtEntity._hMoveToNPCTimer = CTimer(function()
								if hExtEntity._hLastLookTarget ~= hNPCEntity then
									return TIMER_STOP
								elseif CalcDistanceBetweenEntityOBB(args.target, args.unit) <= 150 then
									hExtEntity:Hold()
									hNPCEntity:SetLookTarget(args.unit)
									hNPCEntity:Talk()
									return TIMER_STOP
								end
							end, 0, TIMER_THINK_INTERVAL)
					end
				end
			end
		end
	else
		local hExtEntity = LookupExtendedEntity(args.unit)
		if hExtEntity._hMoveToNPCTimer then
			hExtEntity._hMoveToNPCTimer:StopTimer()
		end
		if hExtEntity._hLastLookTarget then
			hExtEntity._hLastLookTarget:ClearLookTarget()
		end
	end
end

function LookupNPC(nRefID)
	return CIcewrackNPC._stRefIDLookupTable[nRefID]
end
