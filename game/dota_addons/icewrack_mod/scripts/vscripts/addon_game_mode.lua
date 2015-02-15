require("timer")
require("ext_entity")
require("spellbook")
require("inventory")

require("ui_hpbar")
require("ui_mainbar")

--TODO: DELETE ME
hTestSelectedEntity = nil

--KNOWN BUGS:
--  *When resizing the window (from 1280x720 to 1600x900 at least), the scaleform UI sometimes causes a CTD
--  *The HP bar sometimes sends a console command after the server has shutdown, resulting in a CTD

if CIcewrackGameMode == nil then
	CIcewrackGameMode = class({})
end

function Precache( context )
	PrecacheResource("particle", "particles/status_fx/status_effect_gush.vpcf", context)
	--[[
		Precache things we know we'll use.  Possible file types include (but not limited to):
			PrecacheResource( "model", "*.vmdl", context )
			PrecacheResource( "soundfile", "*.vsndevts", context )
			PrecacheResource( "particle", "*.vpcf", context )
			PrecacheResource( "particle_folder", "particles/folder", context )
	]]
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
	
	--No way to hide the killcam as of yet...
	
    GameRules:SetGoldTickTime(60.0)
    GameRules:SetGoldPerTick(0)
    GameRules:SetPreGameTime(10.0)
    GameRules:SetHeroSelectionTime(0.0)
    GameRules:SetHeroRespawnEnabled(false)
	GameRules:GetGameModeEntity():SetAnnouncerDisabled(true)
    GameRules:GetGameModeEntity():SetBuybackEnabled(false)
	
	--CIcewrackUIHPBar:RegisterHandler()
	CIcewrackUIMainBar:RegisterHandlers()
    
    ListenToGameEvent("npc_spawned", Dynamic_Wrap(CIcewrackGameMode, "OnSpawned"), self)
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CIcewrackGameMode, "OnEntityKilled"), self)
    ListenToGameEvent("dota_item_picked_up", Dynamic_Wrap(CIcewrackGameMode, "OnItemPickedUp"), self)
    ListenToGameEvent("dota_player_gained_level", Dynamic_Wrap(CIcewrackGameMode, "OnLevelUp"), self)
    ListenToGameEvent('player_connect_full', Dynamic_Wrap(CIcewrackGameMode, 'OnPlayerConnectFull'), self)
    
    GameRules:GetGameModeEntity():SetThink(ProcessTimers, "TimerThink", TIMER_THINK_INTERVAL)
	print( "Icewrack mod loaded." )
end


function CIcewrackGameMode:OnPlayerConnectFull(keys)
    --Load the previous save state if possible, otherwise go to hero selection or something
	
	--[[local hPlayerInstance = PlayerInstanceFromIndex(keys.index + 1)
    local hDummyHero = CreateHeroForPlayer("npc_dota_hero_base", hPlayerInstance)
	
	hDummyHero:AddAbility("iw_dummy_buff")
	hDummyHero:FindAbilityByName("iw_dummy_buff"):SetLevel(1)
	--hDummyHero:ForceKill(false)
	CTimer(function()
			--hDummyHero:SetControllableByPlayer(0, true)
            hDummyHero:SetPlayerID(keys.index)
		end, 1.0)
	hDummyHero:ModifyHealth(0, hDummyHero, true, 0)]]
end

function CIcewrackGameMode:OnSpawned(keys)
    local hEntity = EntIndexToHScript(keys.entindex)
	if string.find(hEntity:GetUnitName(), "dummy") == nil then
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
			hInventory = CIcewrackInventory(hExtEntity, 100)
		else
			hExtEntity._hInventory:RefreshInventory()
		end
		
		print("Extended entity spawned:", hEntity:GetUnitName())
		
		
		--TESTING CODE BELOW; DELETE SOON PLS
		hTestSelectedEntity = hExtEntity
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
					
					hCorpseDummy:AddAbility("iw_corpse_vision_buff")
					hCorpseDummy:FindAbilityByName("iw_corpse_vision_buff"):ApplyDataDrivenModifier(hCorpseDummy, hCorpseDummy, "modifier_iw_corpse_vision_buff", {})
					
					hEntity:SetModelScale(0.0)
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