--[[
    Automator Internal Actions
]]

require("ext_entity")
require("aam_search")

--Skips the current action; useful for things like saving targets without performing actions
function DoNothing(hEntity, hAutomator, hTarget)
	return false
end

function MoveAwayFromTarget(hEntity, hAutomator, hTarget)
    if IsValidEntity(hEntity) and hAutomator and hTarget then
        local vDirection = hEntity:GetAbsOrigin() - hTarget:GetAbsOrigin()
        local vPosition = hEntity:GetAbsOrigin() + (vDirection:Normalized() * 100.0)
        
        if GridNav:IsTraversable(vPosition) and vDirection:Length2D() > 128.0 then
            hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hEntity), hEntity:IsAttacking())
            return true
        else
            return false
        end
    end
    return false
end

function MoveTowardsTarget(hEntity, hAutomator, hTarget)
    if IsValidEntity(hEntity) and hAutomator and hTarget then
        local vDirection = hTarget:GetAbsOrigin() - hEntity:GetAbsOrigin()
        local vPosition = hEntity:GetAbsOrigin() + (vDirection:Normalized() * 100.0)
        
		--TODO: Make this based on the hull size, rather than some arbitrary value
        if GridNav:IsTraversable(vPosition) and vDirection:Length2D() > 128.0 then
            hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hEntity), hEntity:IsAttacking())
            return true
        else
            return false
        end
    end
end

function MoveAwayFromEnemies(hEntity, hAutomator)
    if IsValidEntity(hEntity) and hAutomator then
        local tEnemiesList = GetAllUnits(hEntity, DOTA_UNIT_TARGET_TEAM_ENEMY, 0.0, hEntity:GetCurrentVisionRange())
        
        local nCount = 0
        local vNetDirection = Vector(0, 0, 0)
        for k,v in pairs(tEnemiesList) do
            local vDirection = (hEntity:GetAbsOrigin() - v:GetAbsOrigin())
            vNetDirection = vNetDirection + vDirection:Normalized()/vDirection:Length2D()
            nCount = nCount + 1
        end
        
        if nCount > 0 then
            local vPosition = hEntity:GetAbsOrigin() + (vNetDirection:Normalized() * 100.0)
            if GridNav:IsTraversable(vPosition) then
                hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hEntity), hEntity:IsAttacking())
                return true
            else
                return false
            end
        end
    end
    return false
end

function MoveTowardsEnemies(hEntity, hAutomator)
    if IsValidEntity(hEntity) and hAutomator then
        local tEnemiesList = GetAllUnits(hEntity, DOTA_UNIT_TARGET_TEAM_ENEMY, 0.0, hEntity:GetCurrentVisionRange())
        
        local nCount = 0
        local vNetDirection = Vector(0, 0, 0)
        for k,v in pairs(tEnemiesList) do
            local vDirection = (v:GetAbsOrigin() - hEntity:GetAbsOrigin())
			--TODO: Make this based on the hull size, rather than some arbitrary value
            if vDirection:Length2D() < 128.0 then
                hAutomator:SkipAction()
                return false
            end
            vNetDirection = vNetDirection + vDirection:Normalized()/vDirection:Length2D()
            nCount = nCount + 1
        end
        
        if nCount > 0 then
            local vPosition = hEntity:GetAbsOrigin() + (vNetDirection:Normalized() * 100.0)
            if GridNav:IsTraversable(vPosition) then
                hEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, GetGroundPosition(vPosition, hEntity), hEntity:IsAttacking())
                return true
            else
                return false
            end
        end
    end
    return false
end

function AttackNearestEnemy(hEntity, hAutomator)
    if IsValidEntity(hEntity) and hAutomator then
        local hTarget = GetNearestUnit(hEntity, DOTA_UNIT_TARGET_TEAM_ENEMY, 0.0, hEntity:GetCurrentVisionRange())
        if hTarget and not hEntity:IsAttackingEntity(hTarget) then
            if hTarget:IsInvulnerable() or hTarget:IsAttackImmune() then 
                return false
            else
                hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, true)
				hEntity:SetAttacking(hTarget)
                return true
            end
        end
    end
    return false
end

function AttackTarget(hEntity, hAutomator, hTarget)
    if IsValidEntity(hEntity) and hAutomator and hTarget then
        if hTarget and not hEntity:IsAttackingEntity(hTarget) then
            if hTarget:IsInvulnerable() or hTarget:IsAttackImmune() then 
                return false
            else
				hEntity:IssueOrder(DOTA_UNIT_ORDER_ATTACK_TARGET, hTarget, nil, nil, true)
				hEntity:SetAttacking(hTarget)
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
