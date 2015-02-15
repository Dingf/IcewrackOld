--[[
    Ability Automator Module
]]

--TODO:
--Enable rearranging of actions (since the order determines the priority of execution)
--Finish the other evaluators

if _VERSION < "Lua 5.2" then
    bit = require("numberlua")
    bit32 = bit.bit32
end
require("search")
require("aam_evaluators")
require("aam_internal")

if CActionAutomatorModule == nil then
    CActionAutomatorModule = class({constructor = function(self, hEntity)
        if not hEntity or not hEntity._bIsExtendedEntity then
            error("hEntity must be a valid extended entity")
        end
        if hEntity._hActionAutomatorModule then
            error("hEntity already has an AAM attached to it")
        end
        
        hEntity._hActionAutomatorModule = self
        
        self._bEnabled = true
        self._hEntity = hEntity
        self._tActionList = {}
        
        self._nCurrentStep = 0
        self._nMaxSteps = 0
        
        --This is kind of messy... maybe there's a better way to do these things?
        self._bSkipFlag = false
        self._bStopFlag = false
        
        hEntity:SetThink("OnThink", self, "AAMThink", 0.1)
    end},
    {}, nil)
end

function CActionAutomatorModule:PerformAction(tActionDef)
    if tActionDef then
        local hEntity           = self._hEntity
        local nTargetFlags    = tActionDef.TargetFlags
        local tConditionFlags = {tActionDef.ConditionFlags1 or 0, tActionDef.ConditionFlags2 or 0}
        local hAction         = tActionDef.Action
        
        if not nTargetFlags or not hAction then
            return false
        end
        
        local tTargetList = nil
        local nTargetTeam = bit32.extract(nTargetFlags, 0, 2)
        local nTargetSelector = bit32.extract(nTargetFlags, 2, 6)
        local fMinDistance = stDistanceLookupTable[bit32.extract(tConditionFlags[1], 0, 3)] or 0.0
        local fMaxDistance = stDistanceLookupTable[bit32.extract(tConditionFlags[1], 3, 3)] or 1800.0
        local bDeadFlag = (bit32.extract(tConditionFlags[2], 0, 1) == 1)
        
        if nTargetTeam == TARGET_RELATION_SELF then
            tTargetList = {self._hEntity}
        else
            tTargetList = GetAllUnits(self._hEntity, nTargetTeam, fMinDistance, fMaxDistance, bDeadFlag and DOTA_UNIT_TARGET_FLAG_DEAD or 0)
        end
        
        if tTargetList == nil or next(tTargetList) == nil then
            return false
        end
        
        local nFlagOffset = 0
        local nFlagNumber = 1
        for k,v in ipairs(stConditionTable) do
            local pEvaluatorFunction = v[1]
            local nValue = bit32.extract(tConditionFlags[nFlagNumber], nFlagOffset, v[2])
            
            if nValue ~= 0 then
                tTargetList = pEvaluatorFunction(nValue, tTargetList, tActionDef, hEntity)
                if next(tTargetList) == nil then
                    return false
                end
            end
            
            nFlagOffset = nFlagOffset + v[2]
            if nFlagOffset >= 32 then
                nFlagOffset = 0
                nFlagNumber = nFlagNumber + 1
            end
        end
        
        for k,v in pairs(tTargetList) do
            if not (v:IsAlive() or bDeadFlag) or v:IsInvulnerable() or not hEntity:CanEntityBeSeenByMyTeam(v) then
                tTargetList[k] = nil
            end
        end
        
        local hSelectorFunction = stSelectorTable[nTargetSelector]
        local hTarget = hSelectorFunction(self._hEntity, tTargetList)
        if not hTarget then
            return false
        end
        
		--For internal actions, hAction is a string that we use to lookup the correct function to use
        local hInternalAction = stInternalAbilityLookupTable[hAction]
        if hInternalAction then
            return hInternalAction(hEntity, self, hTarget)
        elseif hAction:IsFullyCastable() and not hEntity:IsSilenced() then
            local nActionBehavior = hAction:GetBehavior()
            local nTargetTeam = hAction:GetAbilityTargetTeam()
            
            if nTargetTeam == DOTA_UNIT_TARGET_TEAM_ENEMY and hTarget:GetTeamNumber() == hEntity:GetTeamNumber() then
                return false
            elseif nTargetTeam == DOTA_UNIT_TARGET_TEAM_FRIENDLY and hTarget:GetTeamNumber() ~= hEntity:GetTeamNumber() then
                return false
            end
            
            local nPlayerIndex = hEntity:GetPlayerOwnerID()
            if (bit32.btest(nActionBehavior, DOTA_ABILITY_BEHAVIOR_NO_TARGET)) then
                hEntity:CastAbilityNoTarget(hAction, nPlayerIndex)
            elseif (bit32.btest(nActionBehavior, DOTA_ABILITY_BEHAVIOR_POINT) or bit32.btest(nActionBehavior, DOTA_ABILITY_BEHAVIOR_AOE)) then
                hEntity:CastAbilityOnPosition(hTarget:GetAbsOrigin(), hAction, nPlayerIndex)
            elseif (bit32.btest(nActionBehavior, DOTA_ABILITY_BEHAVIOR_UNIT_TARGET)) then
                hEntity:CastAbilityOnTarget(hTarget, hAction, nPlayerIndex)
            end
            return true and not self._bSkipFlag
        end
    end
    return false
end

function CActionAutomatorModule:Step()
    local tActionDef = self._tActionList[self._nCurrentStep]
    if tActionDef then
        self._bSkipFlag = false
        if self:PerformAction(tActionDef) == false then
            self._nCurrentStep = self._nCurrentStep + 1
            self:Step()
        end
    end
end

function CActionAutomatorModule:OnThink()
    local hEntity = self._hEntity
    if self._bEnabled and hEntity then
        if hEntity:IsAlive() and hEntity:GetCurrentActiveAbility() == nil then
            --Stop auto attacking and enable automation
            if hEntity:IsAttacking() then
                if not hEntity:AttackReady() and not self._bStopFlag then
                    hEntity:Stop()
                    self._bStopFlag = true
                elseif hEntity:AttackReady() then
                    self._bStopFlag = false
                end
            end
            
            self._nCurrentStep = 1
            self:Step()
        end
    end
    return 0.1
end

function CActionAutomatorModule:SkipAction(nNextStep)
    if not nNextStep then
        nNextStep = self._nCurrentStep
    end
    if nNextStep >= self._nCurrentStep and nNextStep <= self._nMaxSteps then
        self._bSkipFlag = true
        self._nCurrentStep = nNextStep
    end
end

function CActionAutomatorModule:Insert(hAction, nTargetFlags, nConditionFlags1, nConditionFlags2)
    if not hAction then
        error("hAction must be defined")
    end
    
    local tActionDef =
    {
        Action = hAction,
        TargetFlags = nTargetFlags or 0,
        ConditionFlags1 = nConditionFlags1 or 0,
        ConditionFlags2 = nConditionFlags2 or 0,
    }
    
    table.insert(self._tActionList, tActionDef)
    self._nMaxSteps = self._nMaxSteps + 1
end
