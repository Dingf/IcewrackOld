--[[
	Map 1
]]
require("timer")
require("ext_entity")
require("save_manager")

if CIcewrackMap1 == nil then
	CIcewrackMap1 = class({})
end

--TODO: Make the launch loot more accurate
function WoodcutterAxeTrigger(tTriggerInfo)
	local hItem = CreateItem( "item_quelling_blade", nil, nil )
	hItem:SetPurchaseTime(0)
	hItem:SetCurrentCharges(1)
	local vSpawnPoint = tTriggerInfo.activator:GetAbsOrigin();
	local hItemDrop = CreateItemOnPositionSync(Vector(1040, 990, 128), hItem)
	hItem:LaunchLoot(false, 300, 0.75, vSpawnPoint)
end

function Precache(context)
	PrecacheResource("particle", "particles/rain_fx/econ_snow_heavy.vpcf", context)
	PrecacheUnitByNameSync("npc_dota_hero_legion_commander", context)
	PrecacheUnitByNameSync("iw_npc_training_dummy", context)
	PrecacheUnitByNameSync("iw_npc_expedition_merc_1", context)
	PrecacheUnitByNameSync("iw_npc_expedition_merc_2", context)
	PrecacheUnitByNameSync("npc_dota_hero_sven", context)
	PrecacheUnitByNameSync("npc_dota_hero_dragon_knight", context)
	PrecacheUnitByNameSync("npc_dota_hero_drow_ranger", context)
	PrecacheUnitByNameSync("npc_dota_hero_bounty_hunter", context)
	PrecacheUnitByNameSync("npc_dota_hero_lina", context)
	PrecacheUnitByNameSync("npc_dota_hero_warlock", context)
end

function Activate()
	CIcewrackSaveManager:InitSaveManager()
	CIcewrackMap1:InitMap()
end

function CIcewrackMap1:InitMap()
	CIcewrackSaveManager:LoadMapSpawns()

	Convars:SetInt("dota_camera_pitch_max", 60)

	ListenToGameEvent("player_connect_full", Dynamic_Wrap(CIcewrackMap1, "OnPlayerConnectFull"), self)
    self._nDelayedInitID = ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrackMap1, "DelayedInit"), self)
end

function CIcewrackMap1:OnPlayerConnectFull(keys)
	local tSaveData = CIcewrackSaveManager:LoadSelectedSave()
	SendToConsole("jointeam good");
end

function CIcewrackMap1:DelayedInit(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_PRE_GAME then
		SendToConsole("custom_ui_unload characterselectlistener")
		SendToConsole("custom_ui_unload characterselectmenu")
		SendToConsole("dota_center_message 5 \"Expedition Base Camp\"")
		CTimer(function()
				local hEntity = Entities:FindByName(nil, "npc_dota_hero_legion_commander")
				hEntity:AddAbility("internal_loadout_stance")
				hEntity:FindAbilityByName("internal_loadout_stance"):ApplyDataDrivenModifier(hEntity, hEntity, "modifier_internal_loadout_stance", {})
				hEntity:RemoveAbility("internal_loadout_stance")
				ParticleManager:CreateParticle("particles/rain_fx/econ_snow_heavy.vpcf", PATTACH_EYES_FOLLOW, hEntity)
				StopListeningToGameEvent(self._nDelayedInitID)
			end, 1.0)
	end
end




