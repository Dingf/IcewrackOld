require("ext_entity")
require("mechanics")

function BurningDamage(args)
	args.caster = args.target
	args.NoOutMultiplier = "TRUE"
    args.MinDamage = args.target:GetMaxHealth() * 0.01
    args.MaxDamage = args.target:GetMaxHealth() * 0.01
	args.DamageType = "IW_DAMAGE_TYPE_FIRE"
    DealDamage(args)
end

function WetOnHit(tDamageInfoTable)
	--Freeze the target when hit with ice damage
end

function WetOnApply(args)
	local hTarget = LookupExtendedEntity(args.target)
	if hTarget then
		local hExtModList = hTarget:GetExtendedModifierList() or {}
		for k,v in pairs(hExtModList) do
			if k:GetStatusEffect() == IEA_STATUS_EFFECT_BURNING then
				k:RemoveExtendedModifier()
			end
		end
	end
	table.insert(hTarget._tOnTakeDamageList, WetOnHit)
end

function WetOnRemove(args)
	local hTarget = LookupExtendedEntity(args.target)
	if hTarget then
		for k,v in pairs(hTarget._tOnTakeDamageList) do
			if v == WetOnHit then
				hTarget._tOnTakeDamageList[k] = nil
				break
			end
		end
	end
end