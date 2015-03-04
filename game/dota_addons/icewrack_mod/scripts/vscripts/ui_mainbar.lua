require("timer")
require("xp_values")
require("ext_entity")
require("spellbook")

if CIcewrackUIMainBar == nil then
	CIcewrackUIMainBar = { _shSelectedEntity = nil }
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
			FireGameEvent("iw_ui_spellbar_return_abilities",
						  { ability1 = hSpellbook:GetBoundAbilityName(0) or "empty",
							ability2 = hSpellbook:GetBoundAbilityName(1) or "empty",
							ability3 = hSpellbook:GetBoundAbilityName(2) or "empty",
							ability4 = hSpellbook:GetBoundAbilityName(3) or "empty",
							ability5 = hSpellbook:GetBoundAbilityName(4) or "empty",
							ability6 = hSpellbook:GetBoundAbilityName(5) or "empty"})
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

function CIcewrackUIMainBar:RegisterHandlers()
	Convars:RegisterCommand("iw_ui_mainbar_request_values",
		function(szCmdName, szArgs)
			if szArgs then
				local hEntity = EntIndexToHScript(tonumber(szArgs))
				if hEntity then
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
				if hEntity then
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
				if hEntity then
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
			if self._shSelectedEntity then
				local hSpellbook = self._shSelectedEntity._hSpellbook
				if hSpellbook and hSpellbook._bRefreshFlag then
					hSpellbook._bRefreshFlag = nil
					self:ReturnAbilities()
					self:ReturnKnownList()
				end
				if not self._shSelectedEntity:IsAlive() then
					self:ReturnValues()
					self._shSelectedEntity = nil
				end
			end
		end, 0, 0.1)
end