--[[
	Icewrack Save Manager
]]

require("ext_entity")
require("ext_item")
require("ext_ability")
require("inventory")
require("spellbook")
require("npc")
require("party")
require("game_states")


local function StringToVector(szString)
	local tVectorData = {}
	local i = 0
	for s in string.gmatch(szString, "[%d%.%-]+") do
		tVectorData[i] = s
		i = i + 1
		if i >= 3 then break end
	end
	return Vector(tVectorData[0], tVectorData[1], tVectorData[2])
end

if CIcewrackSaveManager == nil then
    CIcewrackSaveManager = { _szSaveDirectory = nil }
end

function CIcewrackSaveManager:InitSaveManager()
	if not self._szSaveDirectory then
		for k in string.gmatch(package.path, "[%w/\\.: _?()]+") do
			if string.find(k, "game\\bin\\win64\\lua\\%?.lua") ~= nil then
				self._szSaveDirectory = string.gsub(k, "game\\bin\\win64\\lua\\%?.lua", "save\\icewrack\\")
				break
			end
		end
		
		if self._szSaveDirectory then
			local tSaveListInfo = LoadKeyValues(self._szSaveDirectory .. "savelist.txt")
			if tSaveListInfo then
				self._szSelectedSave = tSaveListInfo.SelectedSave
				self._szTempsaveFilename = tSaveListInfo.Tempsave
				self._szQuicksaveFilename = tSaveListInfo.Quicksave
				self._tSaveList = {}
				if tSaveListInfo.Saves then
					for k,v in pairs(tSaveListInfo.Saves) do
						self._tSaveList[k] = v
					end
				end
			end
		else
			error("Could not locate default save directory.")
		end
		
		self._szSaveVersion = "0.1.0"
		self._tEquipPrintTable = 
		{
			"IEI_INVENTORY_SLOT_MAIN_HAND",
			"IEI_INVENTORY_SLOT_OFF_HAND",
			"IEI_INVENTORY_SLOT_HEAD",
			"IEI_INVENTORY_SLOT_BODY",
			"IEI_INVENTORY_SLOT_HANDS",
			"IEI_INVENTORY_SLOT_FEET",
			"IEI_INVENTORY_SLOT_WAIST",
			"IEI_INVENTORY_SLOT_LRING",
			"IEI_INVENTORY_SLOT_RRING",
			"IEI_INVENTORY_SLOT_NECK"
		}
	end
end

function CIcewrackSaveManager:TempsaveGame()
	if self._szTempsaveFilename then
		self:SaveGame(self._szTempsaveFilename)
	end
end

function CIcewrackSaveManager:QuicksaveGame()
	if self._szQuicksaveFilename then
		self:SaveGame(self._szQuicksaveFilename)
	end
end


--TODO:
--  *Use RefIDs instead of entindexes
--  *Save AAM sequences
--  *Save entities on a per-map basis (and their orientation, position, modifiers, etc.)
function CIcewrackSaveManager:SaveGame(szSaveName)
	local tSaveTable = {}
	tSaveTable[#tSaveTable+1] = "SaveVersion\t"
	tSaveTable[#tSaveTable+1] = self._szSaveVersion
	tSaveTable[#tSaveTable+1] = "\tCurrentMap\t"
	tSaveTable[#tSaveTable+1] = GetMapName()
	tSaveTable[#tSaveTable+1] = string.format("\tTimeOfDay\t%f", GameRules:GetTimeOfDay())
	tSaveTable[#tSaveTable+1] = "\tGameStates\t{"
	for k,v in pairs(tIcewrackGameStates) do
		tSaveTable[#tSaveTable+1] = string.format("\t%s\t%d", k, v)
	end
	tSaveTable[#tSaveTable+1] = "\t}"
	tSaveTable[#tSaveTable+1] = "\tParty\t{"
	for k,v in pairs(CIcewrackParty:GetAllMembers()) do
		tSaveTable[#tSaveTable+1] = "\t"
		tSaveTable[#tSaveTable+1] = k:GetUnitName()
		tSaveTable[#tSaveTable+1] = "\t{"
		local hExtEntity = LookupExtendedEntity(k)
		local vPosition = hExtEntity:GetAbsOrigin()
		local vOrientation = hExtEntity:GetForwardVector()
		tSaveTable[#tSaveTable+1] = string.format("\tEntindex\t%d", k:entindex())
		tSaveTable[#tSaveTable+1] = string.format("\tPosition\t%f %f %f", vPosition.x, vPosition.y, vPosition.z)
		tSaveTable[#tSaveTable+1] = string.format("\tOrientation\t%f %f %f", vOrientation.x, vOrientation.y, vOrientation.z)
		tSaveTable[#tSaveTable+1] = string.format("\tCurrentHP\t%f", k:GetHealth())
		tSaveTable[#tSaveTable+1] = string.format("\tCurrentMP\t%f", k:GetMana())
		tSaveTable[#tSaveTable+1] = string.format("\tCurrentSP\t%f", hExtEntity:GetStamina())
		tSaveTable[#tSaveTable+1] = "\tProperties\t{"
		for k2,v2 in pairs(stIEEPropertiesSet) do
			tSaveTable[#tSaveTable+1] = string.format("\t%s\t%s", k2, hExtEntity._tPropertiesBase[k2])
		end
		tSaveTable[#tSaveTable+1] = "\t}"
		tSaveTable[#tSaveTable+1] = "\tSpells\t{"
		local hSpellbook = hExtEntity._hSpellbook
		if hSpellbook then
			local tSpellList = hSpellbook:GetKnownAbilities()
			for k2,v2 in pairs(tSpellList) do
				tSaveTable[#tSaveTable+1] = "\t"
				tSaveTable[#tSaveTable+1] = k2
				tSaveTable[#tSaveTable+1] = "\t{"
				tSaveTable[#tSaveTable+1] = string.format("\tLevel\t%s", v2)
				tSaveTable[#tSaveTable+1] = string.format("\tCooldown\t%s", 0)		--TODO: Add cooldown tracking to the spellbook
				tSaveTable[#tSaveTable+1] = "\t}"
			end
		end
		tSaveTable[#tSaveTable+1] = "\t}"
		tSaveTable[#tSaveTable+1] = "\tInventory\t{"
		local hInventory = hExtEntity._hInventory
		if hInventory then
			local tEquippedList = hInventory:GetEquippedItems()
			local tReverseEquippedList = {}
			for k,v in pairs(tEquippedList) do
				if v ~= 0 then
					tReverseEquippedList[v._hBaseItem] = k
				end
			end
			local tItemList = hInventory:GetItemList()
			for k2,v2 in pairs(tItemList) do
				tSaveTable[#tSaveTable+1] = "\t"
				tSaveTable[#tSaveTable+1] = k2:GetName()
				tSaveTable[#tSaveTable+1] = "\t{"
				if tReverseEquippedList[k2] then
					tSaveTable[#tSaveTable+1] = "\tEquipped\t"
					tSaveTable[#tSaveTable+1] = self._tEquipPrintTable[tReverseEquippedList[k2]]
				end
				local hExtendedItem = LookupExtendedItem(k2)
				tSaveTable[#tSaveTable+1] = string.format("\tStackCount\t%d", hExtendedItem:GetStackCount())
				tSaveTable[#tSaveTable+1] = "\tProperties\t{"
				for k3,v3 in pairs(hExtendedItem._tProperties) do
					tSaveTable[#tSaveTable+1] = string.format("\t%s\t%f", k3, v3)
				end
				tSaveTable[#tSaveTable+1] = "\t}\t}"
			end
		end
		tSaveTable[#tSaveTable+1] = "\t}"
		tSaveTable[#tSaveTable+1] = "\tModifiers\t{"
		local nCurrentTime = GameRules:GetGameTime()
		local tExtModifierList = LookupExtendedModifierList(k)
		if tExtModifierList then
			for k2,v2 in pairs(tExtModifierList) do
				tSaveTable[#tSaveTable+1] = "\t"
				tSaveTable[#tSaveTable+1] = k2:GetAbilityName()
				tSaveTable[#tSaveTable+1] = "\t{"
				local hSource = k2:GetSource()
				if hSource then
					tSaveTable[#tSaveTable+1] = string.format("\tSource\t%d", hSource:entindex())
				end
				tSaveTable[#tSaveTable+1] = string.format("\tStartTime\t%f", k2:GetStartTime())
				tSaveTable[#tSaveTable+1] = string.format("\tRemainingTime\t%f", k2:GetEndTime() - nCurrentTime)
				tSaveTable[#tSaveTable+1] = string.format("\tEndTime\t%f", k2:GetEndTime())
				tSaveTable[#tSaveTable+1] = "\t}"
			end
		
		end
		tSaveTable[#tSaveTable+1] = "\t}\t}"
	end
	tSaveTable[#tSaveTable+1] = "\t}"
	
	local nOffset = 1
	local szSaveString = table.concat(tSaveTable)
	while true do
		local szSaveChunk = string.sub(szSaveString, nOffset, nOffset + 799)
		nOffset = nOffset + 800
		if string.len(szSaveChunk) ~= 800 then
			FireGameEvent("iw_ui_sfs_save_game", { is_last = true, filename = self._szSaveDirectory .. szSaveName, save_data = szSaveChunk })
			break
		else
			FireGameEvent("iw_ui_sfs_save_game", { is_last = false, filename = self._szSaveDirectory .. szSaveName, save_data = szSaveChunk })
		end
	end
end

function CIcewrackSaveManager:AddSaveToSaveList(szSaveName)
end

function CIcewrackSaveManager:DeleteSave(szSaveName)

end

function CIcewrackSaveManager:WriteSaveList()
	local tSaveTable = {}
	tSaveTable[#tSaveTable+1] = "SelectedSave\t"
	tSaveTable[#tSaveTable+1] = self._szSelectedSave
	tSaveTable[#tSaveTable+1] = "\tTempsave\t"
	tSaveTable[#tSaveTable+1] = self._szTempsaveFilename
	tSaveTable[#tSaveTable+1] = "\tQuicksave\t"
	tSaveTable[#tSaveTable+1] = self._szQuicksaveFilename
	tSaveTable[#tSaveTable+1] = "\tSaves\t{"
	for k,v in pairs(self._tSaveList) do
		tSaveTable[#tSaveTable+1] = string.format("\t%d\t%s", k, v)
	end
	tSaveTable[#tSaveTable+1] = "\t}"
	
	local szSaveString = table.concat(tSaveTable)
	FireGameEvent("iw_ui_sfs_make_save_list", { filename = self._szSaveDirectory .. "savelist.txt", save_data = szSaveString })
end

function CIcewrackSaveManager:SelectSave(szSaveName)
	if szSaveName == self._szTempsaveFilename or szSaveName == self._szQuicksaveFilename then
		self._szSelectedSave = szSaveName
	else
		for k,v in pairs(self._tSaveList) do
			if v == szSaveName then
				self._szSelectedSave = szSaveName
				break
			end
		end
	end
	
	if self._szSelectedSave then
		self:WriteSaveList()
	end
end

--TODO: Check if loaded map == current map. If not tempsave and not equals, then return false
--TODO: Actually load the fucking save, instead of doing it on a per-map basis
function CIcewrackSaveManager:LoadSelectedSave()
	if self._szSelectedSave then
		return LoadKeyValues(self._szSaveDirectory .. self._szSelectedSave)
	else
		return nil
	end
end

function CIcewrackSaveManager:GetSaveList()
	--TODO
end

function CIcewrackSaveManager:LoadSpawnsFromFile(szFilename)
	local tSpawnList = LoadKeyValues(szFilename)
	if tSpawnList then
		local tSpawnedUnits = {}
		for k,v in pairs(tSpawnList) do
			local bFindClearSpace = (not v.FindClearSpace) or (v.FindClearSpace == "TRUE")
			local hEntity = nil
			if bFindClearSpace then
				hEntity = CreateUnitByName(v.Name, StringToVector(v.Position), true, nil, nil, _G[v.Team])
				hEntity:SetForwardVector(StringToVector(v.Orientation))
			else
				hEntity = CreateUnitByName(v.Name, Vector(0, 0, 0), false, nil, nil, _G[v.Team])
				hEntity:SetForwardVector(StringToVector(v.Orientation))
				hEntity:SetAbsOrigin(StringToVector(v.Position))
			end
			
			if hEntity then 
				local hExtEntity = CIcewrackExtendedEntity(hEntity)
				hExtEntity:SetRefID(tonumber(k))
				
				CIcewrackNPC(hExtEntity)
				CIcewrackSpellbook(hExtEntity)
				CIcewrackInventory(hExtEntity)
				
				tSpawnedUnits[tonumber(k)] = hEntity
			end
		end
		
		for k,v in pairs(tSpawnList) do
			if v.Modifiers then
				local hTarget = LookupExtendedEntityByRefID(tonumber(k))
				for k2,v2 in pairs(v.Modifiers) do
					local hSource = LookupExtendedEntityByRefID(v2)
					hSource:AddAbility(k2)
					local hAbility = hSource:FindAbilityByName(k2)
					if hAbility then
						hAbility:ApplyDataDrivenModifier(hSource._hBaseEntity, hTarget._hBaseEntity, "modifier_" .. k2, {})
						hSource:RemoveAbility(k2)
					end
				end
			end
		end
		return tSpawnedUnits
	end
	return nil
end
