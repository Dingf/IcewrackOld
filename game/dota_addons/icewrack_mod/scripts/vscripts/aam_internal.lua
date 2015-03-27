--[[
    Automator Internal Actions
]]

require("ext_entity")
require("aam_search")

--Skips the current action; useful for things like saving targets without performing actions
function DoNothing(hExtEntity, hAutomator, hTarget)
	return false
end

function MoveAwayFromTarget(hExtEntity, hAutomator, hTarget)
    if IsValidExtendedEntity(hExtEntity) and hAutomator and hTarget then
        local vDirection = hExtEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()
        local vPosition = hExtEntity:GetAbsOrigin() + (vDirection:Normalized() * 100.0)
        
        if GridNav:IsTraversable(vPosition) and vDirection:Length2D() > 128.0 then
            hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hExtEntity._hBaseEntity), hExtEntity:IsAttacking())
            return true
        else
            return false
        end
    end
    return false
end

function MoveTowardsTarget(hExtEntity, hAutomator, hTarget)
    if IsValidExtendedEntity(hExtEntity) and hAutomator and hTarget then
        local vDirection = hTarget:GetAbsOrigin() - hExtEntity:GetAbsOrigin()
        local vPosition = hExtEntity:GetAbsOrigin() + (vDirection:Normalized() * 100.0)
        
		--TODO: Make this based on the hull size, rather than some arbitrary value
        if GridNav:IsTraversable(vPosition) and vDirection:Length2D() > 128.0 then
            hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hExtEntity._hBaseEntity), hExtEntity:IsAttacking())
            return true
        else
            return false
        end
    end
end

function MoveAwayFromEnemies(hExtEntity, hAutomator)
    if IsValidExtendedEntity(hExtEntity) and hAutomator then
        local tEnemiesList = GetAllUnits(hExtEntity, DOTA_UNIT_TARGET_TEAM_ENEMY, 0.0, hExtEntity:GetCurrentVisionRange())
        
        local nCount = 0
        local vNetDirection = Vector(0, 0, 0)
        for k,v in pairs(tEnemiesList) do
            local vDirection = (hExtEntity:GetAbsOrigin() - v:GetAbsOrigin())
            vNetDirection = vNetDirection + vDirection:Normalized()/vDirection:Length2D()
            nCount = nCount + 1
        end
        
        if nCount > 0 then
            local vPosition = hExtEntity:GetAbsOrigin() + (vNetDirection:Normalized() * 100.0)
            if GridNav:IsTraversable(vPosition) then
                hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hExtEntity._hBaseEntity), hExtEntity:IsAttacking())
                return true
            else
                return false
            end
        end
    end
    return false
end

function MoveTowardsEnemies(hExtEntity, hAutomator)
    if IsValidExtendedEntity(hExtEntity) and hAutomator then
        local tEnemiesList = GetAllUnits(hExtEntity, DOTA_UNIT_TARGET_TEAM_ENEMY, 0.0, hExtEntity:GetCurrentVisionRange())
        
        local nCount = 0
        local vNetDirection = Vector(0, 0, 0)
        for k,v in pairs(tEnemiesList) do
            local vDirection = (v:GetAbsOrigin() - hExtEntity:GetAbsOrigin())
			--TODO: Make this based on the hull size, rather than some arbitrary value
            if vDirection:Length2D() < 128.0 then
                hAutomator:SkipAction()
                return false
            end
            vNetDirection = vNetDirection + vDirection:Normalized()/vDirection:Length2D()
            nCount = nCount + 1
        end
        
        if nCount > 0 then
            local vPosition = hExtEntity:GetAbsOrigin() + (vNetDirection:Normalized() * 100.0)
            if GridNav:IsTraversable(vPosition) then
                hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hExtEntity._hBaseEntity), hExtEntity:IsAttacking())
                return true
            else
                return false
            end
        end
    end
    return false
end

function AttackNearestEnemy(hExtEntity, hAutomator)
    if IsValidExtendedEntity(hExtEntity) and hAutomator then
        local hTarget = GetNearestUnit(hExtEntity, DOTA_UNIT_TARGET_TEAM_ENEMY, 0.0, hExtEntity:GetCurrentVisionRange())
        if hTarget and not hExtEntity:IsAttackingEntity(hTarget) then
            if hTarget:IsInvulnerable() or hTarget:IsAttackImmune() then 
                return false
            else
                hExtEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, true)
				hExtEntity:SetAttacking(hTarget)
                return true
            end
        end
    end
    return false
end

function AttackTarget(hExtEntity, hAutomator, hTarget)
    if IsValidExtendedEntity(hExtEntity) and hAutomator and hTarget then
        if hTarget and not hExtEntity:IsAttackingEntity(hTarget) then
            if hTarget:IsInvulnerable() or hTarget:IsAttackImmune() then 
                return false
            else
				hExtEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, true)
				hExtEntity:SetAttacking(hTarget)
                return true
            end
        end
    end
    return false
end

stInternalAbilityLookupTable = 
{
	["aam_do_nothing"]             = DoNothing,
    ["aam_move_away_from_enemies"] = MoveAwayFromEnemies,
    ["aam_move_towards_enemies"]   = MoveTowardsEnemies,
    ["aam_attack_nearest_enemy"]   = AttackNearestEnemy,
    ["aam_attack_target"]          = AttackTarget,
}
