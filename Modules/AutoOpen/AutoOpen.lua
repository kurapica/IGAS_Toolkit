-------------------------------
-- AutoOpen Script
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoOpen"

import "System.Threading"

Options = {
}

-- OnLoad
function OnLoad(self)
	_Enabled = not _DisabledModule[_Name]

	-- SavedVariables
	_DBChar.AutoOpenList = _DBChar.AutoOpenList or {}

	_AutoOpenList = _DBChar.AutoOpenList

	-- Events
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("BAG_OPEN")
	self:RegisterEvent("BAG_CLOSED")

	-- Hook
	self:SecureHook("ContainerFrameItemButton_OnModifiedClick")

	_Thread = System.Threading.Thread()

	self:ActiveThread("OnEnable")
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil
	System.Threading.Sleep(3)
	self:RegisterEvent("BAG_UPDATE")
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
end

function MERCHANT_SHOW(self)
	self:UnregisterEvent("BAG_UPDATE")
end

function MERCHANT_CLOSED(self)
	self:RegisterEvent("BAG_UPDATE")
end

function BAG_OPEN(self)
	self:UnregisterEvent("BAG_UPDATE")
end

function BAG_CLOSED(self)
	self:RegisterEvent("BAG_UPDATE")
end

function BAG_UPDATE(self, bag)
	if InCombatLockdown() then
		return
	end

	if not _Thread:IsDead() then
		return
	end

	_Thread.Thread = AutoOpenBag

	return _Thread(bag)
end

function ContainerFrameItemButton_OnModifiedClick(self, button)
	if button == "RightButton" and IsModifiedClick("Alt") then
		local itemId = GetContainerItemID(self:GetParent():GetID(), self:GetID())

		if not itemId then return end

		local _, count, locked, _, _, lootable, link = GetContainerItemInfo(self:GetParent():GetID(), self:GetID())

		if lootable then
			Log(1, "[AutoOpen] Add item %s : %s", itemId, link)

			_AutoOpenList[itemId] = true

			BAG_UPDATE()
		end
	end
end

function AutoOpenBag(target)
	local _, itemId, locked, lootable

	local lootUnderMouse = GetCVar("lootUnderMouse")

	_Thread:Sleep(0.1)

	SetCVar("lootUnderMouse", "0")
	LootFrame:SetAlpha(0)

	for bag = target or NUM_BAG_FRAMES, target or 0, -1 do
		for slot = GetContainerNumSlots(bag), 1, -1 do
			itemId = GetContainerItemID(bag, slot)
			_, _, locked, _, _, lootable = GetContainerItemInfo(bag, slot)

			if lootable and itemId and _AutoOpenList[itemId] and not locked then
				Log(1, "[AutoOpen] Open bag %d slot %d ", bag, slot)

				UseContainerItem(bag,slot)

				_Thread:WaitEvent("LOOT_OPENED")

				if not _Thread:Wait("LOOT_CLOSED", 3) then
					Log(1, "[AutoOpen] Unable to loot.")

					CloseLoot()

					LootFrame:SetAlpha(1)
					SetCVar("lootUnderMouse", lootUnderMouse)

					return
				end
			end
		end
	end

	LootFrame:SetAlpha(1)
	SetCVar("lootUnderMouse", lootUnderMouse)
end