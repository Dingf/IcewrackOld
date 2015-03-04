require("timer")
require("xp_values")
require("ext_entity")
require("spellbook")
require("inventory")
require("party")

require("ui_hpbar")
require("ui_mainbar")

--KNOWN BUGS:
--  *When resizing the window (from 1280x720 to 1600x900 at least), the scaleform UI sometimes causes a CTD
--  *The HP bar sometimes sends a console command after the server has shutdown, resulting in a CTD (temporarily disabled)

--TODO:
--	*Make a NPC class, extends from extended entity
--		*Can talk, give quests, and trade
--	*Add cooldowns to spellbook class
--  *IEE units Stamina drain on attack
--      *50% IAS slow as well if no stamina
--  *Carry capacity based on IEE values/strength

if CIcewrackGameMode == nil then
	CIcewrackGameMode = class({})
end

function Precache(context)
	PrecacheUnitByNameSync("npc_dota_hero_sven", context)
	PrecacheResource("particle", "particles/status_fx/status_effect_gush.vpcf", context)
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
end

function Test(args)
	print("tewoijqwore")
	for k,v in pairs(args) do
		print(k,v)
	end
	if args.target then
		print(args.target:GetUnitName())
		if (args.target:GetTeamNumber() == args.unit:GetTeamNumber()) then
			print(CalcDistanceBetweenEntityOBB(args.target, args.unit))
			if CalcDistanceBetweenEntityOBB(args.target, args.unit) < 150 then
				local asdf = LookupExtendedEntity(args.target)
				if asdf then
					--asdf._hLookTarget = args.unit
				end
				--[[args.target._vOriginalLook = args.target:GetForwardVector()
				
				local vNewLook = (args.unit:GetAbsOrigin() - args.target:GetAbsOrigin()):Normalized()
				local vOldLook = args.target._vOriginalLook:Normalized()
				local vDeltaLook = (vNewLook - vOldLook) * 0.2
				CTimer(function()
						args.target:SetForwardVector(args.target:GetForwardVector() + vDeltaLook)
					end, 0.15, 0.03)]]
					
				--CTimer(function()
					--args.target:SetForwardVector(args.target:GetForwardVector() + vDeltaLook)
					--end, 0.15, 0.03)
				--args.target:SetForwardVector(vDirection)
				
			end
		end
	end
end

-- Create the game mode when we activate
function Activate()
    GameRules.AddonTemplate = CIcewrackGameMode()
    GameRules.AddonTemplate:InitGameMode()
end

function CIcewrackGameMode:InitGameMode()
	print( "Loading Icewrack mod..." )
	
	Convars:SetInt("scaleform_spew", 1)
	
    --Hide all of the default UI elements
	Convars:SetInt("dota_sf_hud_actionpanel", 0)
    Convars:SetInt("dota_sf_hud_inventory", 0)
    Convars:SetInt("dota_sf_hud_top", 0)
    Convars:SetInt("dota_hud_healthbars", 0)
    Convars:SetInt("dota_draw_portrait", 0)
    Convars:SetInt("dota_no_minimap", 1)
    Convars:SetInt("dota_render_crop_height", 0)
    Convars:SetInt("dota_render_y_inset", 0)
	
	
	--Set day cycle to 1 hour instead of 8 mins
	--Convars:SetFloat("dota_time_of_day_rate", 0.000278)
	
    GameRules:SetGoldTickTime(60.0)
    GameRules:SetGoldPerTick(0)
    GameRules:SetPreGameTime(0.0)
    GameRules:SetHeroSelectionTime(0.0)
    GameRules:SetHeroRespawnEnabled(false)
	
    GameRules:GetGameModeEntity():SetCustomXPRequiredToReachNextLevel(stIcewrackXPTable)
    GameRules:GetGameModeEntity():SetUseCustomHeroLevels(true)
	GameRules:GetGameModeEntity():SetAnnouncerDisabled(true)
    GameRules:GetGameModeEntity():SetBuybackEnabled(false)
	
	--CIcewrackUIHPBar:RegisterHandler()
	CIcewrackUIMainBar:RegisterHandlers()
    
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(CIcewrackGameMode, "OnSpawned"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CIcewrackGameMode, "OnEntityKilled"), self)
    ListenToGameEvent("dota_item_picked_up", Dynamic_Wrap(CIcewrackGameMode, "OnItemPickedUp"), self)
    ListenToGameEvent("dota_player_gained_level", Dynamic_Wrap(CIcewrackGameMode, "OnLevelUp"), self)
    --ListenToGameEvent("player_connect_full", Dynamic_Wrap(CIcewrackGameMode, "OnPlayerConnectFull"), self)
    
    GameRules:GetGameModeEntity():SetThink(ProcessTimers, "TimerThink", TIMER_THINK_INTERVAL)
	print( "Icewrack mod loaded." )
end

function CIcewrackGameMode:OnPlayerConnectFull(keys)
    --Load the previous save state if possible, otherwise go to hero selection or something
	local hPlayerInstance = PlayerInstanceFromIndex(keys.index + 1)
    local hHeroEntity = CreateHeroForPlayer("npc_dota_hero_sven", hPlayerInstance)
	--hHeroEntity:AddAbility("internal_conversation_starter")
	--hHeroEntity:FindAbilityByName("internal_conversation_starter"):ApplyDataDrivenModifier(hHeroEntity, hHeroEntity, "modifier_internal_conversation_starter", {})
	--hHeroEntity:RemoveAbility("internal_conversation_starter")
	CTimer(function()
			CIcewrackParty:AddMember(hHeroEntity)
			hHeroEntity:SetControllableByPlayer(keys.index, true)
			hHeroEntity:SetPlayerID(keys.index)
		end, 1.0)
	
	--[[hDummyHero:AddAbility("internal_dummy_buff")
	hDummyHero:FindAbilityByName("internal_dummy_buff"):SetLevel(1)
	--hDummyHero:ForceKill(false)
	CTimer(function()
			--hDummyHero:SetControllableByPlayer(0, true)
            hDummyHero:SetPlayerID(keys.index)
		end, 1.0)
	hDummyHero:ModifyHealth(0, hDummyHero, true, 0)]]
end

function CIcewrackGameMode:OnSpawned(keys)
    local hEntity = EntIndexToHScript(keys.entindex)
	if string.find(hEntity:GetUnitName(), "dummy") == nil and string.find(hEntity:GetUnitName(), "thinker") == nil then
		--if not hEntity.HPBarHookFunction then
		--	CIcewrackUIHPBar:AttachEntityHook(hEntity)
		--end
		local hExtEntity = LookupExtendedEntity(hEntity)
		if not hExtEntity then
			hExtEntity = CIcewrackExtendedEntity(hEntity)
		else
			hExtEntity:CalculateStatBonus()
		end
		
		if not hExtEntity._hSpellbook then
			hSpellbook = CIcewrackSpellbook(hExtEntity)
		end
		
		--TODO: Change the carry capacity to not be a fixed number
		if not hExtEntity._hInventory then
			hInventory = CIcewrackInventory(hExtEntity)
		else
			hExtEntity._hInventory:RefreshInventory()
		end
		
		print("Extended entity spawned:", hEntity:GetName())
		
		
		--TESTING CODE BELOW; DELETE SOON PLS
		hSpellbook:LearnAbility("omniknight_purification", 1)
		hSpellbook:LearnAbility("abaddon_aphotic_shield", 1)
		hSpellbook:LearnAbility("abaddon_borrowed_time", 1)
		hSpellbook:LearnAbility("abaddon_death_coil", 1)
		hSpellbook:LearnAbility("abaddon_frostmourne", 1)
		hSpellbook:LearnAbility("shadow_demon_demonic_purge", 1)
		hSpellbook:LearnAbility("shadow_demon_disruption", 1)
		hSpellbook:LearnAbility("shadow_demon_soul_catcher", 1)
		hSpellbook:LearnAbility("bounty_hunter_jinada", 1)
		hSpellbook:LearnAbility("life_stealer_rage", 1)
		hSpellbook:LearnAbility("crystal_maiden_brilliance_aura", 1)
		hSpellbook:LearnAbility("drow_ranger_marksmanship", 1)
		hSpellbook:LearnAbility("lich_chain_frost", 1)
		hSpellbook:LearnAbility("lich_dark_ritual", 1)
		hSpellbook:LearnAbility("lich_frost_armor", 1)
		hSpellbook:LearnAbility("lich_frost_nova", 1)
	end
end

function CIcewrackGameMode:OnEntityKilled(keys)
    local hEntity = EntIndexToHScript(keys.entindex_killed)
	if hEntity and not hEntity:IsHero() then
		if string.find(hEntity:GetUnitName(), "dummy") == nil then
			local hExtEntity = LookupExtendedEntity(hEntity)
			if hExtEntity and hExtEntity._bIsExtendedEntity then
				CIcewrackExtendedEntity._stLookupTable[hEntity] = nil
				local hCorpseDummy = CreateUnitByName("iw_npc_corpse_dummy", hEntity:GetAbsOrigin(), false, nil, nil, PlayerResource:GetTeam(0))
				if hCorpseDummy then
					hCorpseDummy:SetForwardVector(hEntity:GetForwardVector())
					hCorpseDummy:SetModel(hEntity:GetModelName())
					hCorpseDummy:SetOriginalModel(hEntity:GetModelName())
					hCorpseDummy:SetModelScale(hExtEntity:GetModelScale())
					hCorpseDummy:ModifyHealth(0, hCorpseDummy, true, 0)
					
					hCorpseDummy._szCorpseName = hEntity:GetUnitName()
					hCorpseDummy._fCorpseMaxHP = hExtEntity:GetMaxHealth()
					
					hCorpseDummy:AddAbility("internal_corpse_vision_buff")
					hCorpseDummy:FindAbilityByName("internal_corpse_vision_buff"):ApplyDataDrivenModifier(hCorpseDummy, hCorpseDummy, "modifier_internal_corpse_vision_buff", {})
					
					hEntity:SetModelScale(0.0)
					CTimer(function()
							hExtEntity:DeleteEntity()
						end, 1.0)
				end
			end
		end
	end
end

function CIcewrackGameMode:OnLevelUp(keys)
    local hPlayer = PlayerResource:GetPlayer(keys.player - 1)
    local hEntity = PlayerResource:GetSelectedHeroEntity(keys.player - 1)
    if hEntity then
        local hExtEntity = LookupExtendedEntity(hEntity)
        if hExtEntity and hExtEntity._bIsExtendedEntity then
			--Give 7 attribute points for the player to spend
            hExtEntity._tPropertiesBase["AttributePoints"] = hExtEntity.AttributePoints + 7
			--Apply attribute growth to the hero
			for i=IW_ATTRIBUTE_STRENGTH,IW_ATTRIBUTE_WISDOM do
				local szAttribName = stIEEPropertiesTable[i + 17]
				local szAttribGrowthName = stIEEPropertiesTable[i + 23]
				hExtEntity._tPropertiesBase[szAttribName] = hExtEntity._tPropertiesBase[szAttribName] + hExtEntity._tPropertiesBase[szAttribGrowthName]
			end
            hExtEntity:CalculateStatBonus()
        end
    end
end

function CIcewrackGameMode:OnItemPickedUp(keys)
    local hEntity = EntIndexToHScript(keys.HeroEntityIndex)
    local hItem = EntIndexToHScript(keys.ItemEntityIndex)
    if hEntity and hItem then
        local hExtEntity = LookupExtendedEntity(hEntity)
        if hExtEntity and hExtEntity._bIsExtendedEntity then
            local hInventory = hExtEntity._hInventory
			if hInventory then
				hInventory:AddItem(hItem)
			end
        end
    end
end