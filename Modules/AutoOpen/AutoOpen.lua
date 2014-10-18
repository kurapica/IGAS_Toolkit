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
	self:RegisterEvent("BAG_NEW_ITEMS_UPDATED")

	-- Hook
	self:SecureHook("ContainerFrameItemButton_OnModifiedClick")

	_Thread = System.Threading.Thread()
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
end

function BAG_NEW_ITEMS_UPDATED(self)
	if InCombatLockdown() then
		return
	end

	if not _Thread:IsDead() then
		return
	end

	_Thread.Thread = AutoOpenBag

	return _Thread()
end

function ContainerFrameItemButton_OnModifiedClick(self, button)
	if button == "RightButton" and IsModifiedClick("Alt") then
		local itemId = GetContainerItemID(self:GetParent():GetID(), self:GetID())

		if not itemId then return end

		local _, count, locked, _, _, lootable, link = GetContainerItemInfo(self:GetParent():GetID(), self:GetID())

		if lootable then
			Log(1, "[AutoOpen] Add item %s : %s", itemId, link)

			_AutoOpenList[itemId] = true

			BAG_NEW_ITEMS_UPDATED()
		end
	end
end

function AutoOpenBag()
	local _, itemId, locked, lootable

	local lootUnderMouse = GetCVar("lootUnderMouse")

	SetCVar("lootUnderMouse", "0")
	LootFrame:SetAlpha(0)

	for bag = NUM_BAG_FRAMES, 0, -1 do
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