require("timer")
require("xp_values")
require("ext_entity")
require("spellbook")

if CIcewrackUIMainBar == nil then
	CIcewrackUIMainBar = { _shSelectedEntity = nil }
	ListenToGameEvent("entity_killed", Dynamic_Wrap(CIcewrackUIMainBar, "OnEntityKilled"), CIcewrackUIMainBar)
	ListenToGameEvent("iw_spellbook_refresh", Dynamic_Wrap(CIcewrackUIMainBar, "OnSpellbookRefresh"), CIcewrackUIMainBar)
end

function CIcewrackUIMainBar:ReturnValues()
	local hExtEntity = self._shSelectedEntity
	if hExtEntity then
		local nCurrentXP = nil
		local nMaximumXP = nil
		local bAliveFlag = hExtEntity:IsAlive()
		if bAliveFlag and hExtEntity:IsHero() then
			local nLevel = hExtEntity:GetLevel()
			if nLevel == IW_MAXIMUM_LEVEL then
				nCurrentXP = hExtEntity:GetCurrentXP()
				nMaximumXP = hExtEntity:GetCurrentXP()
			else
				nCurrentXP = hExtEntity:GetCurrentXP() - stIcewrackXPTable[nLevel]
				nMaximumXP = stIcewrackXPTable[nLevel + 1] - stIcewrackXPTable[nLevel]
			end
		end
		
		FireGameEvent("iw_ui_mainbar_return_values",
                      { current_hp = bAliveFlag and hExtEntity:GetHealth() or 0.0,
                        maximum_hp = bAliveFlag and hExtEntity:GetMaxHealth() or 0.0,
                        current_mp = bAliveFlag and hExtEntity:GetMana() or 0.0,
                        maximum_mp = bAliveFlag and hExtEntity:GetMaxMana() or 0.0,
                        current_sp = bAliveFlag and hExtEntity:GetStamina() or 0.0,
                        maximum_sp = bAliveFlag and hExtEntity:GetMaxStamina() or 0.0,
						current_xp = nCurrentXP or 0.0,
						maximum_xp = nMaximumXP or 0.0})
	end
end

function CIcewrackUIMainBar:ReturnAbilities()
	local hExtEntity = self._shSelectedEntity
	if hExtEntity then
		local hSpellbook = hExtEntity._hSpellbook
		if hSpellbook then
			SetActiveSpellbookEntity(hExtEntity)
			for i=0,5 do
				local hAbility = hSpellbook:GetBoundAbility(i)
				local tCooldown = nil
				if hAbility then
					tCooldown = hSpellbook._tCooldowns[hAbility:GetAbilityName()]
				end
				local tCurrentTime = GameRules:GetGameTime()
				FireGameEvent("iw_ui_spellbar_return_ability",
							  { slot = i,
								level = hAbility and hAbility:GetLevel() or 0,
								ability_name = hAbility and hAbility:GetAbilityName() or "empty",
								mana_cost = hAbility and hAbility:GetManaCost(hAbility:GetLevel()-1) or 0,
								stamina_cost = 0,		--TODO: Implement stamina cost for spells
								cd_start = tCooldown and tCooldown[1] - tCurrentTime or nil,
								cd_end = tCooldown and tCooldown[1] - tCurrentTime + tCooldown[2] or nil })
			end
		end
	end
end

function CIcewrackUIMainBar:ReturnKnownList()
	local hExtEntity = self._shSelectedEntity
	if hExtEntity then
		local hSpellbook = hExtEntity._hSpellbook
		if hSpellbook then
			SetActiveSpellbookEntity(hExtEntity)
			local tKnownList = hSpellbook:GetAvailableAbilities()
			local szKnownList = "ui_spellbar_cancel"
			for k,v in pairs(tKnownList) do
				szKnownList = szKnownList .. " " .. k
			end
			FireGameEvent("iw_ui_spellbar_send_known_list", { ability_list = szKnownList })
		end
	end
end

function CIcewrackUIMainBar:OnEntityKilled(keys)
    local hEntity = EntIndexToHScript(keys.entindex_killed)
	if IsValidEntity(hEntity) and self._shSelectedEntity and self._shSelectedEntity._hBaseEntity == hEntity then
	    self:ReturnValues()
		self._shSelectedEntity = nil
	end
end

function CIcewrackUIMainBar:OnSpellbookRefresh()
    if self._shSelectedEntity then
		local hSpellbook = self._shSelectedEntity._hSpellbook
		if hSpellbook then
			self:ReturnAbilities()
			self:ReturnKnownList()
		end
	end
end

function CIcewrackUIMainBar:RegisterHandlers()
	Convars:RegisterCommand("iw_ui_mainbar_request_values",
		function(szCmdName, szArgs)
			if szArgs then
				local hEntity = EntIndexToHScript(tonumber(szArgs))
				if IsValidEntity(hEntity) then
					local hExtEntity = LookupExtendedEntity(hEntity)
					if hExtEntity then
						local nTeam = PlayerResource:GetTeam(0)
						if hEntity:GetTeamNumber() == nTeam then
							self._shSelectedEntity = hExtEntity
						end
						self:ReturnValues()
					end
				end
			end
		end, "Returns the requested unit's values (hp, mp, sp) to the mainbar UI.", 0)

	Convars:RegisterCommand("iw_ui_mainbar_request_abilities",
		function(szCmdName, szArgs)
			if szArgs then
				local hEntity = EntIndexToHScript(tonumber(szArgs))
				if IsValidEntity(hEntity) then
					local hExtEntity = LookupExtendedEntity(hEntity)
					if hExtEntity then
						local nTeam = PlayerResource:GetTeam(0)
						if hEntity:GetTeamNumber() == nTeam then
							self._shSelectedEntity = hExtEntity
						end
						self:ReturnAbilities()
					end
				end
			end
		end, "Returns the requested unit's abilities to the mainbar UI.", 0)

	Convars:RegisterCommand("iw_ui_mainbar_request_known_list",
		function(szCmdName, szArgs)
			if szArgs then
				local hEntity = EntIndexToHScript(tonumber(szArgs))
				if IsValidEntity(hEntity) then
					local hExtEntity = LookupExtendedEntity(hEntity)
					if hExtEntity then
						local nTeam = PlayerResource:GetTeam(0)
						if hEntity:GetTeamNumber() == nTeam then
							self._shSelectedEntity = hExtEntity
						end
						self:ReturnKnownList()
					end
				end
			end
		end, "Returns the requested unit's known abilities to the mainbar UI.", 0)
		
	Convars:RegisterCommand("iw_ui_spellbar_rebind",
		function(szCmdName, szArgs)
			local hSpellbook = self._shSelectedEntity._hSpellbook
			if szArgs and hSpellbook then
				local nSlot = nil
				for k in string.gmatch(szArgs, "[%w_]+") do
					if nSlot == nil then
						nSlot = tonumber(k)
					else
						if k == "ui_spellbar_cancel" then
							hSpellbook:UnbindAbility(nSlot)
						else
							hSpellbook:BindAbility(k, nSlot)
						end
						break
					end
				end
			end
		end, "Returns the requested unit's known abilities to the mainbar UI.", 0)
	
	CTimer(function()
			SendToConsole("alias iw_pause \"host_timescale 1; bind SPACE iw_unpause\"")
			SendToConsole("alias iw_unpause \"host_timescale 0; bind SPACE iw_pause\"")
			SendToConsole("bind SPACE iw_pause")
		end, 0.1)
end