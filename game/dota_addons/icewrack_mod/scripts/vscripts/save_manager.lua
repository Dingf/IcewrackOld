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
    CIcewrackSaveManager = { _szSaveDirectory }
end

function CIcewrackSaveManager:InitSaveManager()
	for k in string.gmatch(package.path, "[%w/\\.: _?()]+") do
		if string.find(k, "game\\bin\\win64\\lua\\%?.lua") ~= nil then
			self._szSaveDirectory = string.gsub(k, "game\\bin\\win64\\lua\\%?.lua", "save\\icewrack\\")
			break
		end
	end
	
	if self._szSaveDirectory then
		local hSaveList = io.open(self._szSaveDirectory .. "savelist.txt", "r")
		if not hSaveList then
			error("Could not access default save directory " .. self._szSaveDirectory .. ".")
		else
			io.close(hSaveList)
			local tSaveListInfo = LoadKeyValues(self._szSaveDirectory .. "savelist.txt")
			if tSaveListInfo then
				self._szSelectedSave = tSaveListInfo.SelectedSave
				self._szTempsaveFilename = tSaveListInfo.Tempsave
				self._szQuicksaveFilename = tSaveListInfo.Quicksave
				self._tSaveList = {}
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
--  *Use GUIDs instead of entindexes
--  *Save AAM sequences
--  *Save entities on a per-map basis (and their orientation, position, modifiers, etc.)
function CIcewrackSaveManager:SaveGame(szSaveName)
	local hSaveFile = io.open(self._szSaveDirectory .. szSaveName, "w")
	if hSaveFile then
		hSaveFile:write("\"IcewrackSaveFile\"\n{\n")
		hSaveFile:write("\t\"SaveVersion\"\t\"", self._szSaveVersion, "\"\n")
		hSaveFile:write("\t\"CurrentMap\"\t\"", GetMapName(), "\"\n")
		hSaveFile:write(string.format("\t\"TimeOfDay\"\t\"%f\"\n", GameRules:GetTimeOfDay()))
		hSaveFile:write("\t\"GameStates\"\n\t{\n")
		for k,v in pairs(tIcewrackGameStates) do
			print(k,v)
			hSaveFile:write(string.format("\t\t\"%s\"\t\"%d\"\n", k, v))
		end
		hSaveFile:write("\t}\n")
		hSaveFile:write("\t\"Party\"\n\t{\n")
		for k,v in pairs(CIcewrackParty:GetAllMembers()) do
			hSaveFile:write("\t\t\"", k:GetUnitName(), "\"\n\t\t{\n")
			local hExtEntity = LookupExtendedEntity(k)
			local vPosition = hExtEntity:GetAbsOrigin()
			local vOrientation = hExtEntity:GetForwardVector()
			hSaveFile:write(string.format("\t\t\t\"Entindex\"\t\"%d\"\n", k:entindex()))
			hSaveFile:write(string.format("\t\t\t\"Position\"\t\"%f %f %f\"\n", vPosition.x, vPosition.y, vPosition.z))
			hSaveFile:write(string.format("\t\t\t\"Orientation\"\t\"%f %f %f\"\n", vOrientation.x, vOrientation.y, vOrientation.z))
			hSaveFile:write(string.format("\t\t\t\"CurrentHP\"\t\"%f\"\n", k:GetHealth()))
			hSaveFile:write(string.format("\t\t\t\"CurrentMP\"\t\"%f\"\n", k:GetMana()))
			hSaveFile:write(string.format("\t\t\t\"CurrentSP\"\t\"%f\"\n", hExtEntity:GetStamina()))
			hSaveFile:write("\t\t\t\"Properties\"\n\t\t\t{\n")
			for k2,v2 in pairs(stIEEPropertiesSet) do
				hSaveFile:write(string.format("\t\t\t\t\"%s\"\t\"%s\"\n", k2, hExtEntity._tPropertiesBase[k2]))
			end
			hSaveFile:write("\t\t\t}\n")
			hSaveFile:write("\t\t\t\"Spells\"\n\t\t\t{\n")
			local hSpellbook = hExtEntity._hSpellbook
			if hSpellbook then
				local tSpellList = hSpellbook:GetKnownAbilities()
				for k2,v2 in pairs(tSpellList) do
					hSaveFile:write("\t\t\t\t\"", k2, "\"\n\t\t\t\t{\n")
					hSaveFile:write(string.format("\t\t\t\t\t\"Level\"\t\"%s\"\n", v2))
					hSaveFile:write(string.format("\t\t\t\t\t\"Cooldown\"\t\"%s\"\n", 0))		--TODO: Add cooldown tracking to the spellbook
					hSaveFile:write("\t\t\t\t}\n")
				end
			end
			hSaveFile:write("\t\t\t}\n")
			hSaveFile:write("\t\t\t\"Inventory\"\n\t\t\t{\n")
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
					hSaveFile:write("\t\t\t\t\"", k2:GetName(), "\"\n\t\t\t\t{\n")
					if tReverseEquippedList[k2] then
						hSaveFile:write("\t\t\t\t\t\"Equipped\"\t\"", self._tEquipPrintTable[tReverseEquippedList[k2]], "\"\n")
					end
					local hExtendedItem = LookupExtendedItem(k2)
					hSaveFile:write(string.format("\t\t\t\t\t\"StackCount\"\t\"%d\"\n", hExtendedItem:GetStackCount()))
					hSaveFile:write("\t\t\t\t\t\"Properties\"\n\t\t\t\t\t{\n")
					for k3,v3 in pairs(hExtendedItem._tProperties) do
						hSaveFile:write(string.format("\t\t\t\t\t\t\"%s\"\t\"%f\"\n", k3, v3))
					end
					hSaveFile:write("\t\t\t\t\t}\n")
					hSaveFile:write("\t\t\t\t}\n")
				end
			end
			hSaveFile:write("\t\t\t}\n")
			hSaveFile:write("\t\t\t\"Modifiers\"\n\t\t\t{\n")
			local nCurrentTime = GameRules:GetGameTime()
			local tExtModifierList = LookupExtendedModifierList(k)
			print(tExtModifierList)
			if tExtModifierList then
				for k2,v2 in pairs(tExtModifierList) do
					hSaveFile:write("\t\t\t\t\"", k2:GetAbilityName(), "\"\n\t\t\t\t{\n")
					local hSource = k2:GetSource()
					if hSource then
						hSaveFile:write(string.format("\t\t\t\t\t\"Source\"\t\"%d\"\n", hSource:entindex()))
					end
					hSaveFile:write(string.format("\t\t\t\t\t\"StartTime\"\t\"%f\"\n", k2:GetStartTime()))
					hSaveFile:write(string.format("\t\t\t\t\t\"RemainingTime\"\t\"%f\"\n", k2:GetEndTime() - nCurrentTime))
					hSaveFile:write(string.format("\t\t\t\t\t\"EndTime\"\t\"%f\"\n", k2:GetEndTime()))
					hSaveFile:write("\t\t\t\t}\n")
				end
			
			end
			hSaveFile:write("\t\t\t}\n")
			
			hSaveFile:write("\t\t}\n")
		end
		hSaveFile:write("\t}\n")
		hSaveFile:write("}")
		hSaveFile:flush()
		io.close(hSaveFile)
	end
end

function CIcewrackSaveManager:AddSaveToSaveList(szSaveName)
end

function CIcewrackSaveManager:DeleteSave(szSaveName)

end

function CIcewrackSaveManager:WriteSaveList()
	local hSaveList = io.open(self._szSaveDirectory .. "savelist.txt", "w")
	if hSaveList then
		hSaveList:write("\"IcewrackSaveList\"\n{\n")
		hSaveList:write("\t\"SelectedSave\"\t\"", self._szSelectedSave, "\"\n")
		hSaveList:write("\t\"Tempsave\"\t\"", self._szTempsaveFilename, "\"\n")
		hSaveList:write("\t\"Quicksave\"\t\"", self._szQuicksaveFilename, "\"\n")
		hSaveList:write("\t\"Saves\"\n\t{\n")
		for k,v in pairs(self._tSaveList) do
			hSaveList:write(string.format("\t\t\"%d\"\t\"%s\"\n", k, v))
		end
		hSaveList:write("\t}\n")
		hSaveList:write("}")
		hSaveList:flush()
		io.close(hSaveList)
	end
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
