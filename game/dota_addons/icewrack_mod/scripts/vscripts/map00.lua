--[[
	Map 0 (Character select screen)
]]

require("timer")
require("ext_entity")
require("game_states")
require("save_manager")

if CIcewrackMap0 == nil then
	CIcewrackMap0 = class({})
end

function Precache(context)
	print("Precaching stuff")
	PrecacheResource("particle", "particles/rain_fx/econ_snow_light.vpcf", context)
	PrecacheUnitByNameSync("npc_dota_hero_sven", context)
	PrecacheUnitByNameSync("npc_dota_hero_dragon_knight", context)
	PrecacheUnitByNameSync("npc_dota_hero_drow_ranger", context)
	PrecacheUnitByNameSync("npc_dota_hero_bounty_hunter", context)
	PrecacheUnitByNameSync("npc_dota_hero_lina", context)
	PrecacheUnitByNameSync("npc_dota_hero_warlock", context)
end

function Activate()
	CIcewrackSaveManager:InitSaveManager()
	CIcewrackMap0:InitMap()
end

function CIcewrackMap0:AcceptCharacterSelect(szHeroName)
	local hEntity = Entities:FindByClassname(nil, szHeroName)
	CIcewrackParty:AddMember(hEntity)
	
	if szHeroName == "npc_dota_hero_sven" then
		SetGameStateValue("IWGS_GLOBAL_PICKED_HERO", 1)
		SetGameStateValue("IWGS_M01_TALKED_TO_SVEN", 1)
		SetGameStateValue("IWGS_M01_RECRUITED_SVEN", 1)
	elseif szHeroName == "npc_dota_hero_dragon_knight" then
		SetGameStateValue("IWGS_GLOBAL_PICKED_HERO", 2)
		SetGameStateValue("IWGS_M01_TALKED_TO_DK", 1)
		SetGameStateValue("IWGS_M01_RECRUITED_DK", 1)
	elseif szHeroName == "npc_dota_hero_drow_ranger" then
		SetGameStateValue("IWGS_GLOBAL_PICKED_HERO", 3)
		SetGameStateValue("IWGS_M01_TALKED_TO_DROW", 1)
		SetGameStateValue("IWGS_M01_RECRUITED_DROW", 1)
	elseif szHeroName == "npc_dota_hero_bounty_hunter" then
		SetGameStateValue("IWGS_GLOBAL_PICKED_HERO", 4)
		SetGameStateValue("IWGS_M01_TALKED_TO_BH", 1)
		SetGameStateValue("IWGS_M01_RECRUITED_BH", 1)
	elseif szHeroName == "npc_dota_hero_lina" then
		SetGameStateValue("IWGS_GLOBAL_PICKED_HERO", 5)
		SetGameStateValue("IWGS_M01_TALKED_TO_LINA", 1)
		SetGameStateValue("IWGS_M01_RECRUITED_LINA", 1)
	elseif szHeroName == "npc_dota_hero_warlock" then
		SetGameStateValue("IWGS_GLOBAL_PICKED_HERO", 6)
		SetGameStateValue("IWGS_M01_TALKED_TO_WL", 1)
		SetGameStateValue("IWGS_M01_RECRUITED_WL", 1)
	end
	
	CIcewrackSaveManager:TempsaveGame()
	CIcewrackSaveManager:SelectSave(CIcewrackSaveManager._szTempsaveFilename)
end

function CIcewrackMap0:InitMap()
	CIcewrackSaveManager:LoadMapSpawns()
	
	Convars:SetInt("dota_camera_pitch_max", 20)
	
	for k,v in pairs(CIcewrackNPC._stRefIDLookupTable) do
		local hExtEntity = v._hExtEntity
		if hExtEntity then
			hExtEntity._vOriginalPosition = v:GetAbsOrigin()
			hExtEntity._vReturnPosition = v:GetAbsOrigin() - (v:GetForwardVector() * 32.0)
		end
	end
	
	Convars:RegisterCommand("iw_ui_character_select_accept",
		function(szCmdName, szArgs)
			self:AcceptCharacterSelect(szArgs)
		end, "", 0)
		
	Convars:RegisterCommand("iw_ui_save_complete",
		function(szCmdName, szArgs)
				SendToConsole("dota_launch_custom_game icewrack_mod map01")
			end, "", 0)
	
	Convars:RegisterCommand("iw_ui_character_select_update",
		function(szCmdName, szArgs)
			if szArgs == "clear" and self._hSelectedCharacter then
				self._hSelectedCharacter:Stop()
				self._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, self._hSelectedCharacter._vReturnPosition, false)
				self._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, self._hSelectedCharacter._vOriginalPosition, true)
				self._hSelectedCharacter = nil
			else
				local hEntity = Entities:FindByClassname(nil, szArgs)
				local hExtEntity = LookupExtendedEntity(hEntity)
				if hExtEntity then
					if self._hSelectedCharacter then
						self._hSelectedCharacter:Stop()
						self._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, self._hSelectedCharacter._vReturnPosition, false)
						self._hSelectedCharacter:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, self._hSelectedCharacter._vOriginalPosition, true)
					end
					hExtEntity:Stop()
					hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, Vector(-64, -384, 128), false)
					hExtEntity:IssueOrder(DOTA_UNIT_ORDER_MOVE_TO_POSITION, nil, nil, Vector(-64, -400, 128), true)
					self._hSelectedCharacter = hExtEntity
				end
			end
		end, "", 0)
	
	ListenToGameEvent("player_connect_full", Dynamic_Wrap(CIcewrackMap0, "OnPlayerConnectFull"), self)
    self._nDelayedInitID = ListenToGameEvent("game_rules_state_change", Dynamic_Wrap(CIcewrackMap0, "DelayedInit"), self)
	
	--shWalkBuffPlacer:RemoveSelf()
end

function CIcewrackMap0:OnPlayerConnectFull(keys)
	local hPlayerInstance = PlayerInstanceFromIndex(keys.index + 1)
    local hLookDummy = CreateHeroForPlayer("npc_dota_hero_base", hPlayerInstance)
	hLookDummy:ModifyHealth(0, hLookDummy, true, 0)
	self._hLookDummy = hLookDummy
	PlayerResource:SetCameraTarget(keys.index, hLookDummy)
end

function CIcewrackMap0:DelayedInit(keys)
	local nGameState = GameRules:State_Get()
	if nGameState == DOTA_GAMERULES_STATE_PRE_GAME then
		--Can't use iw_ui_mainbar_set_visible here for some reason; oh well...
		SendToConsole("custom_ui_unload icewrackmainbar")
		SendToConsole("custom_ui_unload icewrackspellbar")
		SendToConsole("custom_ui_unload snowoverlay")
		SendToConsole("custom_ui_unload xpoverlay")
		SendToConsole("custom_ui_unload bgshadow")
		SendToConsole("dota_center_message 1000000 \"Select Your Hero\"")
		CTimer(function()
				ParticleManager:CreateParticle("particles/rain_fx/econ_snow_light.vpcf", PATTACH_EYES_FOLLOW, self._hLookDummy)
				
				GameRules:SendCustomMessage("Hint: If you're having trouble selecting a hero, try dragging a box around them.", 2, 0);
				StopListeningToGameEvent(self._nDelayedInitID)
			end, 1.0)
	end
end
