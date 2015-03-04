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
	local newItem = CreateItem( "item_quelling_blade", nil, nil )
	newItem:SetPurchaseTime( 0 )
	newItem:SetCurrentCharges( 1 )
	local spawnPoint = tTriggerInfo.activator:GetAbsOrigin();
	local drop = CreateItemOnPositionSync( Vector(1040, 990, 128), newItem )
	newItem:LaunchLoot( false, 300, 0.75, spawnPoint)
end

function Precache(context)
	PrecacheResource("particle", "particles/rain_fx/econ_snowstorm_med.vpcf", context)
	PrecacheUnitByNameSync("npc_dota_hero_legion_commander", context)
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
	CIcewrackMap1:InitMap()
end

function CIcewrackMap1:InitMap()
	Convars:SetInt("dota_camera_pitch_max", 60)
	
	CIcewrackSaveManager:InitSaveManager()
	local tSpawnList = CIcewrackSaveManager:LoadSpawnsFromFile("/scripts/npc/spawns_map01.txt")
	
	--[[local tPatrolList1 = { tSpawnList[52], tSpawnList[53], tSpawnList[54], tSpawnList[55], tSpawnList[56], tSpawnList[57] }
	for k,v in pairs(tPatrolList1) do
		local hExtEntity = LookupExtendedEntity(v)
		if hExtEntity then
			hExtEntity:AddPatrolPoint(hExtEntity:GetAbsOrigin() + Vector(30, 128, 0), 10, 0)
			hExtEntity:AddPatrolPoint(hExtEntity:GetAbsOrigin() - Vector(30, 128, 0), 10, 5)
		end
	end
	
	local hEntity = tSpawnList[58]
	local hExtEntity = LookupExtendedEntity(hEntity)
	hExtEntity:AddPatrolPoint(Vector(-736, 862, 128), 40, -39)
	hExtEntity:AddPatrolPoint(Vector(500, 1115, 128), 40, -31)
	hExtEntity:AddPatrolPoint(Vector(852, 300, 128), 40, -23)
	hExtEntity:AddPatrolPoint(Vector(-224, -286, 128), 40, -15)
	hExtEntity:AddPatrolPoint(Vector(-1088, -96, 128), 40, -7)]]
	
	
	ListenToGameEvent("player_connect_full", Dynamic_Wrap(CIcewrackMap1, "OnPlayerConnectFull"), self)
    self._nDelayedInitID = ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrackMap1, "DelayedInit"), self)
end

function CIcewrackMap1:OnPlayerConnectFull(keys)
	local tSaveData = CIcewrackSaveManager:LoadSelectedSave()
	
	GameRules:SetTimeOfDay(tSaveData.TimeOfDay)
	
	SendToConsole("jointeam good");
	
	local hHeroEntities = {}
	local hPlayerInstance = PlayerInstanceFromIndex(keys.index + 1)
	CTimer(function()
			for k,v in pairs(tSaveData.Party) do
				local hHeroEntity = CreateHeroForPlayer(k, hPlayerInstance)
				table.insert(hHeroEntities, hHeroEntity)
			end
		end, 0.1)
	--hHeroEntity = CreateHeroForPlayer("npc_dota_hero_sven", hPlayerInstance) end, 0.1)
	CTimer(function()
			for k,v in pairs(hHeroEntities) do
				CIcewrackParty:AddMember(v)
				v:SetControllableByPlayer(keys.index, true)
				v:SetPlayerID(keys.index)
			end
		end, 1.0)

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
				ParticleManager:CreateParticle("particles/rain_fx/econ_snowstorm_med.vpcf", PATTACH_EYES_FOLLOW, hEntity)
				StopListeningToGameEvent(self._nDelayedInitID)
			end, 1.0)
	end
end




