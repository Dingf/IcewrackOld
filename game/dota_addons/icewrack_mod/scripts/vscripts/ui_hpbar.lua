--[[
    UI - HP Bar
]]

require("timer")
require("ext_entity")
require("ext_ability")

if CIcewrackUIHPBar == nil then
    CIcewrackUIHPBar = { _bRefreshFlag = false,
						 _hSelectedEntity = nil,
						 _nParticleID = -1,
						 _nCurrentCount = 0,
						 _nLastActiveCount = 0 }
end

function CIcewrackUIHPBar:AttachEntityHook(hEntity)
	if hEntity then
		hEntity.HPBarHookFunction = 
			function()
				if CIcewrackUIHPBar._nLastActiveCount ~= (CIcewrackUIHPBar._nCurrentCount - 1) then
					CIcewrackUIHPBar._bRefreshFlag = true
				end
				CIcewrackUIHPBar._hSelectedEntity = hEntity
				CIcewrackUIHPBar._nLastActiveCount = CIcewrackUIHPBar._nCurrentCount
			end
	end
end

function CIcewrackUIHPBar:RegisterHandler()
	Convars:RegisterCommand("iw_stop_ui", function() self._bStop = true end, "stop", 0)
	CTimer(function()
			if self._nCurrentCount == self._nLastActiveCount then
				local hExtEntity = LookupExtendedEntity(self._hSelectedEntity)
				if hExtEntity and hExtEntity._bIsExtendedEntity then
					FireGameEvent("iw_ui_hpbar_return_values", 
						{ name = hExtEntity:GetDisplayName(),
						  current_hp = hExtEntity:GetHealth(),
						  maximum_hp = hExtEntity:GetMaxHealth(),
						  game_time = GameRules:GetGameTime() })
					if self._bRefreshFlag or self._hSelectedEntity._bModifierUpdateFlag then
						if self._bRefreshFlag and self._nParticleID == -1 then
							self._nParticleID = ParticleManager:CreateParticle("particles/hp_bar/hpbar_frost.vpcf", PATTACH_ABSORIGIN, self._hSelectedEntity)
						end
						FireGameEvent("iw_ui_hpbar_start_modifiers", {})
						local hModList = LookupExtendedModifierList(self._hSelectedEntity)
						if hModList then
							for k,v in pairs(hModList) do
								FireGameEvent("iw_ui_hpbar_return_modifier",
									{ name = k:GetAbilityName(),
									  debuff = k:IsDebuff(),
									  start_time = k:GetStartTime(),
									  end_time = k:GetEndTime() })
							end
						end
						self._hSelectedEntity._bModifierUpdateFlag = nil
						FireGameEvent("iw_ui_hpbar_finished_modifiers", {})
					end
				else
					FireGameEvent("iw_ui_hpbar_hide", {})
				end
			else
				FireGameEvent("iw_ui_hpbar_hide", {})
				if self._nParticleID ~= -1 then
					ParticleManager:DestroyParticle(self._nParticleID, true)
					self._nParticleID = -1
				end
			end
			self._bRefreshFlag = false
			self._nCurrentCount = self._nCurrentCount + 1
			--if not self._bStop then
			--SendToConsole("ent_call HPBarHookFunction") end
			--This sort of crashes the game sometimes because we try to call a console command after the server shuts down
		end, 0, TIMER_THINK_INTERVAL)
end
