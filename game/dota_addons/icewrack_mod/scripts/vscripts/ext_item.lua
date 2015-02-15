--[[
    Icewrack Extended Item
]]
if _VERSION < "Lua 5.2" then
    bit = require("numberlua")
    bit32 = bit.bit32
end

IEI_TYPE_NONE = 0
IEI_TYPE_WEAPON = 1
IEI_TYPE_ARMOR = 2
IEI_TYPE_JEWLERY = 3
IEI_TYPE_CONSUMABLE = 4
IEI_TYPE_REAGENT = 5
IEI_TYPE_QUEST = 6
IEI_TYPE_MISCELLANEOUS = 7

IEI_SUBTYPE_NONE = 0

IEI_SUBTYPE_WEAPON_1H_SWORD = 1
IEI_SUBTYPE_WEAPON_2H_SWORD = 2
IEI_SUBTYPE_WEAPON_1H_MACE = 3
IEI_SUBTYPE_WEAPON_2H_MACE = 4
IEI_SUBTYPE_WEAPON_1H_AXE = 5
IEI_SUBTYPE_WEAPON_2H_AXE = 6
IEI_SUBTYPE_WEAPON_POLEARM = 7
IEI_SUBTYPE_WEAPON_BOW = 8
IEI_SUBTYPE_WEAPON_THROWN = 9
IEI_SUBTYPE_WEAPON_STAFF = 10

IEI_SUBTYPE_ARMOR_MAIL_BODY = 1
IEI_SUBTYPE_ARMOR_MAIL_HEAD = 2
IEI_SUBTYPE_ARMOR_MAIL_HANDS = 3
IEI_SUBTYPE_ARMOR_MAIL_FEET = 4
IEI_SUBTYPE_ARMOR_LEATHER_BODY = 5
IEI_SUBTYPE_ARMOR_LEATHER_HEAD = 6
IEI_SUBTYPE_ARMOR_LEATHER_HANDS = 7
IEI_SUBTYPE_ARMOR_LEATHER_FEET = 8
IEI_SUBTYPE_ARMOR_CLOTH_BODY = 9
IEI_SUBTYPE_ARMOR_CLOTH_HEAD = 10
IEI_SUBTYPE_ARMOR_CLOTH_HANDS = 11
IEI_SUBTYPE_ARMOR_CLOTH_FEET = 12
IEI_SUBTYPE_ARMOR_SHIELD = 13

IEI_SUBTYPE_JEWLERY_AMULET = 1
IEI_SUBTYPE_JEWLERY_RING = 2

IEI_SUBTYPE_CONSUMABLE_HEALTH_POTION = 1
IEI_SUBTYPE_CONSUMABLE_MANA_POTION = 2
IEI_SUBTYPE_CONSUMABLE_STAMINA_POTION = 3
IEI_SUBTYPE_CONSUMABLE_OTHER_POTION = 4
IEI_SUBTYPE_CONSUMABLE_POISON = 5
IEI_SUBTYPE_CONSUMABLE_SCROLL = 6
IEI_SUBTYPE_CONSUMABLE_SPELL_TOME = 7
IEI_SUBTYPE_CONSUMABLE_FOOD = 8
IEI_SUBTYPE_CONSUMABLE_DRINK = 9

IEI_INVENTORY_SLOT_NONE = 0
IEI_INVENTORY_SLOT_MAIN_HAND = 1
IEI_INVENTORY_SLOT_OFF_HAND = 2
IEI_INVENTORY_SLOT_HEAD = 3
IEI_INVENTORY_SLOT_BODY = 4
IEI_INVENTORY_SLOT_HANDS = 5
IEI_INVENTORY_SLOT_FEET = 6
IEI_INVENTORY_SLOT_WAIST = 7
IEI_INVENTORY_SLOT_LRING = 8
IEI_INVENTORY_SLOT_RRING = 9
IEI_INVENTORY_SLOT_NECK = 10

IEI_ITEM_FLAG_NONE = 0
IEI_ITEM_FLAG_QUEST_ITEM = 1
IEI_ITEM_FLAG_CANNOT_BE_UNEQUIPPED = 2
IEI_ITEM_FLAG_UNIQUE = 3

tIcewrackExtendedItemTemplate = nil

if CIcewrackExtendedItem == nil then
    tIcewrackExtendedItemTemplate = LoadKeyValues("scripts/npc/npc_items_extended.txt")
    if not tIcewrackExtendedItemTemplate then
        error("Could not load key values from extended item data")
    end
    
    CIcewrackExtendedItem = class({
		constructor = function(self, hItem)
			if not hItem or not hItem:IsItem() then
				error("hItem must be a valid item")
			end
			
			if CIcewrackExtendedItem._stLookupTable[hItem] ~= nil then
				self = setmetatable({}, {__index = CIcewrackExtendedItem._stLookupTable[hItem]})
				return self
			end
			
			setmetatable(self, {__index = function(self, k)
				local v = CIcewrackExtendedItem[k] or hItem[k] or nil
				if v then
					self[k] = v
					return v
				else
					return nil
				end
			end})
			
			tItemData = tIcewrackExtendedItemTemplate[hItem:GetName()] or {}
			
			self._bIsExtendedItem = true
			self._hBaseItem = hItem
			
			self._nItemType = _G[tItemData.ItemType] or IEI_TYPE_NONE
			self._nItemSubtype = _G[tItemData.ItemSubtype] or IEI_SUBTYPE_NONE
			
			self._nItemSlots = 0
			for k in string.gmatch(tItemData.Slots or "", "[%w_]+") do
				local nSlot = _G[k] or IEI_INVENTORY_SLOT_NONE
				if nSlot ~= IEI_INVENTORY_SLOT_NONE then
					self._nItemSlots = self._nItemSlots + bit32.lshift(1, nSlot - 1)
				end
			end
			
			self._nItemFlags =  0
			for k in string.gmatch(tItemData.Flags or "", "%a+") do
				self._nItemFlags = self._nItemFlags + (_G[k] or 0)
			end
			
			self._nStackCount = 1
			self._nMaxStacks = tItemData.MaxStacks or 1
		
			self._fWeight = tItemData.Weight or 0.0
			
			self._szDescription = tItemData.Description or nil
			
			self._tProperties = tItemData.Properties
			
			CIcewrackExtendedItem._stLookupTable[hItem] = self
		end},
		{_stLookupTable = {}}, nil)
end

function CIcewrackExtendedItem:GetClassname()
    return "iw_ext_item"
end

function CIcewrackExtendedItem:GetWeight()
    return self._fWeight
end

function CIcewrackExtendedItem:GetStackCount()
    return self._nStackCount
end

function CIcewrackExtendedItem:GetMaxStacks()
    return self._nMaxStacks
end

function CIcewrackExtendedItem:SetStackCount(nStackCount)
    if type(nStackCount) == "number" then
        self._nStackCount = math.max(0, math.min(self._nMaxStacks, nStackCount))
		return nStackCount - self._nStackCount
    else
        error("nStackCount must be a number")
    end
end

function CIcewrackExtendedItem:ModifyStackCount(nStackCount)
    if type(nStackCount) == "number" then
        local nNewStackCount = self._nStackCount + nStackCount
        if nNewStackCount > self._nMaxStacks then
            self._nStackCount = self._nMaxStacks
            return nNewStackCount - self._nMaxStacks
        elseif nNewStackCount < 0 then
            self._nStackCount = 0
            return nNewStackCount
        else
            self._nStackCount = nNewStackCount
            return 0
        end
    else
        error("nStackCount must be a number")
    end
end

function LookupExtendedItem(hItem)
    if hItem then
        return CIcewrackExtendedItem._stLookupTable[hItem]
    else
        return nil
    end
end
