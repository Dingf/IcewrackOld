function GetNearestUnit(hSearcher, nTargetTeam, fMinRadius, fMaxRadius, nTargetFlags)
    if hSearcher and nTargetTeam then
        fMaxRadius = fMaxRadius or 1800.0
        fMinRadius = fMinRadius or 0.0
        nTargetFlags = nTargetFlags or 0
        
        local tUnitsList = FindUnitsInRadius(hSearcher:GetTeamNumber(), hSearcher:GetAbsOrigin(), nil, fMaxRadius, nTargetTeam, DOTA_UNIT_TARGET_ALL, nTargetFlags, 0, false)
        
        local hSelectedEntity = nil
        local fMinDistance = fMaxRadius + 1.0
        for k,v in pairs(tUnitsList) do
            local hEntity = v
            local fDistance = (hSearcher:GetAbsOrigin() - hEntity:GetAbsOrigin()):Length2D()
            if fDistance < fMinDistance and fDistance > fMinRadius then
                hSelectedEntity = hEntity
                fMinDistance = fDistance
            end
        end
        return hSelectedEntity
    else
        return nil
    end
end

function GetAllUnits(hSearcher, nTargetTeam, fMinRadius, fMaxRadius, nTargetFlags)
    if hSearcher and nTargetTeam then
        fMaxRadius = fMaxRadius or 1800.0
        fMinRadius = fMinRadius or 0.0
        nTargetFlags = nTargetFlags or 0
        
        local tUnitsList = FindUnitsInRadius(hSearcher:GetTeamNumber(), hSearcher:GetAbsOrigin(), nil, fMaxRadius, nTargetTeam, DOTA_UNIT_TARGET_ALL, nTargetFlags, 0, false)
        local tSelectedUnitsList = {}
        
        for k,v in pairs(tUnitsList) do
            local hEntity = v
            local fDistance = (hSearcher:GetAbsOrigin() - hEntity:GetAbsOrigin()):Length2D()
            if fDistance >= fMinRadius then
                table.insert(tSelectedUnitsList, hEntity)
            end
        end
        return tSelectedUnitsList
    else
        return nil
    end
end