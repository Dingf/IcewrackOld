--[[
    Icewrack Inventory
]]

require("attributes")
require("ext_entity")
require("ext_item")

if CIcewrackInventory == nil then
    CIcewrackInventory = class({
		constructor = function(self, hEntity)
			if not hEntity or not hEntity._bIsExtendedEntity then
				error("hEntity must be a valid extended entity")
			end
			
			self._bIsInventory = true
			self._hEntity = hEntity
			hEntity._hInventory = self
		
			self._tItemList = {}
			self._tInventoryUnits = {}
			
			self._tEquippedItems = {[IEI_INVENTORY_SLOT_MAIN_HAND] = 0,
									[IEI_INVENTORY_SLOT_OFF_HAND]  = 0,
									[IEI_INVENTORY_SLOT_HEAD]      = 0,
									[IEI_INVENTORY_SLOT_BODY]      = 0,
									[IEI_INVENTORY_SLOT_HANDS]     = 0,
									[IEI_INVENTORY_SLOT_FEET]      = 0,
									[IEI_INVENTORY_SLOT_WAIST]     = 0,
									[IEI_INVENTORY_SLOT_LRING]     = 0,
									[IEI_INVENTORY_SLOT_RRING]     = 0,
									[IEI_INVENTORY_SLOT_NECK]      = 0}
		end},
		{}, nil)
end

function CIcewrackInventory:GetCurrentWeight()
    local fWeight = 0.0
    for k,v in pairs(self._tItemList) do
        local hExtItem = LookupExtendedItem(k)
        if hExtItem then
            fWeight = fWeight + (hExtItem:GetWeight() * hExtItem:GetStackCount())
        end
    end
    return fWeight
end

function CIcewrackInventory:CheckInventoryUnit(hInventoryUnit)
	for i=0,5 do
		if hInventoryUnit:GetItemInSlot(i) ~= nil then
			return
		end
	end

	for k,v in pairs(self._tInventoryUnits) do
		if v == hInventoryUnit then
			self._tInventoryUnits[k] = nil
			hInventoryUnit:RemoveSelf()
			return nil
		end
	end
end

function CIcewrackInventory:DeleteItem(hItem)
    local hInventoryUnit = self._tItemList[hItem]
    if hInventoryUnit then
		local hEntity = self._hEntity
		local hOwner = hEntity:GetOwner()
		CreateUnitByNameAsync("iw_npc_inventory_storage_dummy", hEntity:GetAbsOrigin(), false, hOwner, hOwner, hEntity:GetTeamNumber(),
			function(hCleanupDummy)
				if hCleanupDummy then
					hCleanupDummy:AddAbility("internal_dummy_buff")
					hCleanupDummy:FindAbilityByName("internal_dummy_buff"):SetLevel(1)
					
					hCleanupDummy:SetThink(function() hInventoryUnit:SetAbsOrigin(hEntity:GetAbsOrigin()) return 0.1 end, "InventoryDummyMove", 0.1)
					hCleanupDummy:SetThink(function() hCleanupDummy:RemoveSelf() return nil end, "InventoryDummyDelete", 1.0)
					
					hInventoryUnit:MoveToNPCToGiveItem(hCleanupDummy, hItem)
					hInventoryUnit:SetThink(function() self:CheckInventoryUnit(hInventoryUnit) end, 1.0)
					table.remove(self._tItemList, hItem)
				end
			end)
    end
end

function CIcewrackInventory:DropItem(szName, nCount)
    for k,v in pairs(self._tItemList) do
        local hStoredItem = LookupExtendedItem(k)
        if hStoredItem and hStoredItem:GetName() == szName then
			for k,v in pairs(self._tEquippedItems) do
				if v == hStoredItem then
					self:UnequipItem(k)
				end
			end
			
            local nStackCount = hStoredItem:GetStackCount()
            if nCount < nStackCount then
                hStoredItem:ModifyStackCount(-nCount)
                local hOwner = self._hEntity:GetOwner()
                local hNewItem = CreateItem(k:GetName(), hOwner, hOwner)
                local hNewExtItem = CIcewrackExtendedItem(hNewItem)
                local hItemDrop = CreateItemOnPositionSync(self._hEntity:GetAbsOrigin(), hNewItem)
                hNewExtItem:SetStackCount(nCount)
                return true
            else
                nCount = nCount - nStackCount
                v:DropItemAtPositionImmediate(k, v:GetAbsOrigin())
				v:SetThink(function() self:CheckInventoryUnit(v) end, 1.0)
                self._tItemList[k] = nil
                if nCount == 0 then
                    return true
                end
				
            end
        end
    end
    return false
end

function CIcewrackInventory:EquipItem(hItem, nSlot)
	local hEntity = self._hEntity
    if hEntity and hItem and hEntity._bIsExtendedEntity and hItem._bIsExtendedItem then
		if self._tEquippedItems[nSlot] ~= nil and bit32.band(hItem._nItemSlots, bit32.lshift(1, nSlot - 1)) ~= 0 then 
			if self._tEquippedItems[nSlot] ~= 0 then
				if not self:UnequipItem(nSlot) then
					return false
				end
			end
			if hItem._tProperties then
				hEntity:ApplyModifierProperties(hItem._tProperties)
			end
			local szModifierName = "modifier_" .. hItem:GetName()
			hItem:ApplyDataDrivenModifier(hEntity, hEntity, szModifierName, {})
			self._tEquippedItems[nSlot] = hItem
			return true
		end
	end
	return false
end

function CIcewrackInventory:UnequipItem(nSlot)
	local hEntity = self._hEntity
    local hItem = self._tEquippedItems[nSlot]
	if hEntity and hItem and hEntity._bIsExtendedEntity and hItem._bIsExtendedItem then
		if bit32.band(hItem._nItemFlags, IEI_ITEM_FLAG_CANNOT_BE_UNEQUIPPED) ~= 0 then
			return false
		end
		if hItem._tProperties then
			hEntity:ApplyModifierProperties(hItem._tProperties, true)
		end
		local szModifierName = "modifier_" .. hItem:GetName()
		hEntity:RemoveModifierByName(szModifierName)
		self._tEquippedItems[nSlot] = 0
		return true
	end
	return false
end

function CIcewrackInventory:RefreshInventory()
	for k,v in pairs(self._tEquippedItems) do
		local hItem = self._tEquippedItems[k]
		if hItem ~= 0 then
			self:UnequipItem(k)
			self:EquipItem(hItem, k)
		end
	end
end

function CIcewrackInventory:PickupItem(hInventoryUnit, hItem)
	self._hEntity:MoveToNPCToGiveItem(hInventoryUnit, hItem)
	for k,v in pairs(self._tEquippedItems) do
		if v == 0 and bit32.band(hItem._nItemSlots, bit32.lshift(1, k - 1)) ~= 0 then
			if self:EquipItem(hItem, k) then
				break
			end
		end
	end
end

function CIcewrackInventory:AddItem(hItem)
    local hExtItem = LookupExtendedItem(hItem) or CIcewrackExtendedItem(hItem)
    if hExtItem and hExtItem._bIsExtendedItem then
        local nStackCount = hExtItem:GetStackCount()
        if self:GetCurrentWeight() + (hExtItem:GetWeight() * nStackCount) > self._hEntity:GetCarryCapacity() then
            --Trigger over carry capacity message in the UI (TODO)
            print("DEBUG: Unit is carrying too much!")
            return false
        end
		
        --First try to stack the item if it is stackable
        if hExtItem:GetMaxStacks() > 1 then
            for k,v in pairs(self._tItemList) do
                local hStoredItem = LookupExtendedItem(k)
                if hStoredItem and hStoredItem:GetName() == hItem:GetName() and hStoredItem:GetStackCount() < hStoredItem:GetMaxStacks() then
                    local nOverflow = hStoredItem:ModifyStackCount(nStackCount)
                    if nOverflow > 0 then
                        nStackCount = nOverflow
                        hExtItem:SetStackCount(nStackCount)
                    else
                        self:DeleteItem(hItem)
                        return true
                    end
                end
            end
        end
        
        --Else check if one of the existing dummies has room for the item
        for k,v in pairs(self._tInventoryUnits) do
            for i=0,5 do
                if not v:GetItemInSlot(i) then
                    v:SetThink(function() self:PickupItem(v, hExtItem) return nil end, DoUniqueString("InventoryDummyPickup"), 0.1)
                    self._tItemList[hItem] = v
                    bItemAdded = true
                    return true
                end
            end
        end
        
        --If not, make a new dummy unit and add it to the list of dummy units
		local hEntity = self._hEntity
		local hOwner = hEntity:GetOwner()
		CreateUnitByNameAsync("iw_npc_inventory_storage_dummy", hEntity:GetAbsOrigin(), false, hOwner, hOwner, hEntity:GetTeamNumber(),
			function(hInventoryUnit)
				if hInventoryUnit then
					hInventoryUnit:AddAbility("internal_dummy_buff")
					hInventoryUnit:FindAbilityByName("internal_dummy_buff"):SetLevel(1)
						
					hInventoryUnit:SetThink(function() hInventoryUnit:SetAbsOrigin(hEntity:GetAbsOrigin()) return 0.1 end, "InventoryDummyMove", 0.1)
					hInventoryUnit:SetThink(function() self:PickupItem(hInventoryUnit, hExtItem) return nil end, DoUniqueString("InventoryDummyPickup"), 0.1)
							
					table.insert(self._tInventoryUnits, hInventoryUnit)
					self._tItemList[hItem] = hInventoryUnit
				end
			end)
    end
    return false
end

function CIcewrackInventory:GetEquippedItems()
	return self._tEquippedItems
end

function CIcewrackInventory:GetItemList()
	return self._tItemList
end

function CIcewrackInventory:DebugPrint()
    print("DEBUG: Printing items in inventory")
    print("DEBUG: Carry capacity = " .. self:GetCurrentWeight() .. "/" .. self._hEntity:GetCarryCapacity())
    --Note: If you call DebugPrint() immediately after picking up an item, it won't show up below (since there is a 0.1s delay between the item pickup)
    for k,v in pairs(self._tInventoryUnits) do
        for i=0,5 do
            local item = v:GetItemInSlot(i)
            if item then print(item:GetName()) end
        end
    end
    print("DEBUG: Printing items in item list")
    for k,v in pairs(self._tItemList) do
        print(k:GetName(),v)
    end
	
	local tDebugEquipPrintTable = {"main hand", "off hand", "head", "body", "hands", "feet", "waist", "left ring", "right ring", "neck"}
	print("DEBUG: Printing equipped items")
	for k,v in ipairs(self._tEquippedItems) do
		if v ~= 0 then
			print(tDebugEquipPrintTable[k] or "unknown", v:GetName())
		end
	end
end


