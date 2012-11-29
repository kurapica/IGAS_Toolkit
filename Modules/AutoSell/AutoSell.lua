-------------------------------
-- AutoSell
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoSell"

ITEM_SOULBOUND = ITEM_SOULBOUND

ITEM_QUALITY0_DESC = ITEM_QUALITY0_DESC
ITEM_QUALITY1_DESC = ITEM_QUALITY1_DESC
ITEM_QUALITY2_DESC = ITEM_QUALITY2_DESC
ITEM_QUALITY3_DESC = ITEM_QUALITY3_DESC
ITEM_QUALITY4_DESC = ITEM_QUALITY4_DESC
ITEM_QUALITY5_DESC = ITEM_QUALITY5_DESC
ITEM_QUALITY6_DESC = ITEM_QUALITY6_DESC
ITEM_QUALITY7_DESC = ITEM_QUALITY7_DESC

Options = {
	AutoSellUncommonSoul = {
		L["Sell Uncommon Equipment(SouldBound)"],
		AutoSellUncommonAll = L["Sell Uncommon Equipment(Not SouldBound)"],
	},
	AutoSellRareSoul = {
		L["Sell Rare Equipment(SouldBound)"],
		AutoSellRareAll = L["Sell Rare Equipment(Not SouldBound)"],
	},
}

tonumber = tonumber
GetContainerNumSlots = GetContainerNumSlots
GetContainerItemID = GetContainerItemID
GetBuybackItemLink = GetBuybackItemLink
GetItemInfo = GetItemInfo
UseContainerItem = UseContainerItem
NUM_BAG_FRAMES = NUM_BAG_FRAMES

-- OnLoad
function OnLoad(self)
	-- SavedVariables
	_DBChar.NotSell = _DBChar.NotSell or {}
	_DBChar.WantSell = _DBChar.WantSell or {}

	_NotSell = _DBChar.NotSell
	_WantSell = _DBChar.WantSell

	-- Addon's enable state
	_Enabled = not _DisabledModule[_Name]

	-- Events
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil

	self:SecureHook("UseContainerItem", "Hook_UseContainerItem")
	self:SecureHook("ContainerFrameItemButton_OnClick")
	self:SecureHook("ContainerFrameItemButton_OnModifiedClick")
	self:SecureHook("BuybackItem")
	self:SecureHook("BuyMerchantItem")
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
end

-- MERCHANT_SHOW
function MERCHANT_SHOW(self)
	AutoSell()
	_MERCHANT_SHOW = true
end

-- MERCHANT_CLOSED
function MERCHANT_CLOSED(self)
	_MERCHANT_SHOW = false
end

-- Custom Functions
function SplitItems(strItems)
	if strItems == nil then
		strItems = ""
	end
	local i, j = strItems:find("|h|r")
	if i then
		return strItems:sub(1, j), SplitItems(strItems:sub(j+1, -1))
	else
		return strItems
	end
end

function GetItemId(link)
	local _, link = GetItemInfo(link)
	if link then
		return tonumber(link:match":(%d+):")
	end
end

function GetSellLvl(itemId, bag, slot, chkLvl)
	local _, link, itemRarity, _, _, _, _, _,equipLoc = GetItemInfo(itemId)

	if _NotSell[itemId] then
		return -10
	end

	if _WantSell[itemId] then
		return 10
	end

	if chkLvl and chkLvl == 10 then	return - itemRarity	end

	if itemRarity == 0 then
		return 0
	end

	if chkLvl and chkLvl == 0 then	return - itemRarity	end

	if itemRarity == 1 then
		if equipLoc ~= "" and equipLoc ~= "INVTYPE_BODY" and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BAG" then
			return 1
		else
			return -1
		end
	end

	if chkLvl and chkLvl == 1 then	return - itemRarity	end

	if _DBChar.AutoSellUncommonSoul and itemRarity == 2 then
		if equipLoc ~= "" and equipLoc ~= "INVTYPE_BODY" and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BAG" then
			if _DBChar.AutoSellUncommonAll then
				return 2
			else
				local soulBounded = false

				IGAS.GameTooltip:SetOwner(IGAS.UIParent)
				IGAS.GameTooltip:SetAnchorType("ANCHOR_TOPRIGHT")

				if bag >= 0 then
					IGAS.GameTooltip:SetBagItem(bag, slot)
				elseif bag == -1 then
					IGAS.GameTooltip:SetBuybackItem(slot)
				elseif bag == -2 then
					IGAS.GameTooltip:SetMerchantItem(slot)
				end

				for i = 1, 5 do
					if _G["GameTooltipTextLeft"..i] and _G["GameTooltipTextLeft"..i]:GetText() == ITEM_SOULBOUND then
						soulBounded = true
						break
					end
				end
				IGAS.GameTooltip:Hide()

				if soulBounded then
					return 2
				else
					return -2
				end
			end
		else
			return -2
		end
	end

	if chkLvl and chkLvl == 2 then	return - itemRarity	end

	if _DBChar.AutoSellRareSoul and itemRarity == 3 then
		if equipLoc ~= "" and equipLoc ~= "INVTYPE_BODY" and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BAG" then
			if _DBChar.AutoSellRareAll then
				return 3
			else
				local soulBounded = false

				IGAS.GameTooltip:SetOwner(IGAS.UIParent)
				IGAS.GameTooltip:SetAnchorType("ANCHOR_TOPRIGHT")

				if bag >= 0 then
					IGAS.GameTooltip:SetBagItem(bag, slot)
				elseif bag == -1 then
					IGAS.GameTooltip:SetBuybackItem(slot)
				elseif bag == -2 then
					IGAS.GameTooltip:SetMerchantItem(slot)
				end

				for i = 1, 5 do
					if _G["GameTooltipTextLeft"..i] and _G["GameTooltipTextLeft"..i]:GetText() == ITEM_SOULBOUND then
						soulBounded = true
						break
					end
				end
				IGAS.GameTooltip:Hide()

				if soulBounded then
					return 3
				else
					return -3
				end
			end
		else
			return -3
		end
	end

	return - itemRarity
end

-------------------------------
-- Auto Sell Item
-------------------------------
_SelledList = {}
_SelledCount = {}
_SelledMoney = {}

function Add2List(link, count, money)
	count = count or 1
	money = money * count

	if _SelledCount[link] then
		_SelledCount[link] = _SelledCount[link] + (count or 1)
		_SelledMoney[link] = _SelledMoney[link] + money
	else
		tinsert(_SelledList, link)
		_SelledCount[link] = count or 1
		_SelledMoney[link] = money
	end
end

function AutoSell()
	local count, link, itemId, selled, money, icon

	wipe(_SelledList)
	wipe(_SelledCount)

	-- Sell Wantsell
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			itemId = GetContainerItemID(bag,slot)
			if itemId then
				money = select(11, GetItemInfo(itemId))

				if money and money > 0 and GetSellLvl(itemId, bag, slot, 10) == 10 then
					_, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
					UseContainerItem(bag,slot)
					selled = true
					Add2List(link, count, money)
				end
			end
		end
	end
	-- Sell poor
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			itemId = GetContainerItemID(bag,slot)
			if itemId then
				money = select(11, GetItemInfo(itemId))

				if money > 0 and GetSellLvl(itemId, bag, slot, 0) == 0 then
					_, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
					UseContainerItem(bag,slot)
					selled = true
					Add2List(link, count, money)
				end
			end
		end
	end
	-- Sell common
	for bag = 0, NUM_BAG_FRAMES do
		for slot = 1, GetContainerNumSlots(bag) do
			itemId = GetContainerItemID(bag,slot)
			if itemId then
				money = select(11, GetItemInfo(itemId))

				if money > 0 and GetSellLvl(itemId, bag, slot, 1) == 1 then
					_, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
					UseContainerItem(bag,slot)
					selled = true
					Add2List(link, count, money)
				end
			end
		end
	end

	if _DBChar.AutoSellUncommonSoul then
		for bag = 0, NUM_BAG_FRAMES do
			for slot = 1, GetContainerNumSlots(bag) do
				if not GetContainerItemEquipmentSetInfo(bag, slot) then
					itemId = GetContainerItemID(bag,slot)
					if itemId then
						money = select(11, GetItemInfo(itemId))

						if money > 0 and GetSellLvl(itemId, bag, slot) == 2 then
							_, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
							UseContainerItem(bag,slot)
							selled = true
							Add2List(link, count, money)
						end
					end
				end
			end
		end
	end

	if _DBChar.AutoSellRareSoul then
		for bag = 0, NUM_BAG_FRAMES do
			for slot = 1, GetContainerNumSlots(bag) do
				if not GetContainerItemEquipmentSetInfo(bag, slot) then
					itemId = GetContainerItemID(bag,slot)
					if itemId then
						money = select(11, GetItemInfo(itemId))

						if money > 0 and GetSellLvl(itemId, bag, slot) == 3 then
							_, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)
							UseContainerItem(bag,slot)
							selled = true
							Add2List(link, count, money)
						end
					end
				end
			end
		end
	end

	if selled then
		Log(2, L["[AutoSell] Sell Item List:"])
		Log(2, "-----------------------------")
		money = 0
		for _, link in ipairs(_SelledList) do
			money = money + _SelledMoney[link]
			icon = select(10, GetItemInfo(link)) or ""
			if _SelledCount[link] > 1 then
				Log(2, L["\124T%s:0\124t %s * %d for %s."], icon, link, _SelledCount[link], FormatMoney(_SelledMoney[link]))
			else
				Log(2, L["\124T%s:0\124t %s for %s."], icon, link, FormatMoney(_SelledMoney[link]))
			end
		end
		Log(2, L["[AutoSell] Total : %s."], FormatMoney(money))
		Log(3, L["[AutoSell] Buy back item if you don't want auto sell it next time."])
	end
end

-------------------------------
-- Sell Item
-------------------------------
function Hook_UseContainerItem(bag, slot)
	if _MERCHANT_SHOW then
		local itemId = GetContainerItemID(bag,slot)

		if itemId then
			_NotSell[itemId] = nil

			if GetSellLvl(itemId, bag, slot, 1) == -1 then
				local _, count, _, _, _, _, link = GetContainerItemInfo(bag, slot)

				if count ~= GetItemCount(itemId) then
					return
				end

				Log(1, ("Add Auto sell %s."):format(link))
				_WantSell[itemId] = true
			end
		end
	end
end

-------------------------------
-- Auto Sell All Item by Alt-right click item
-------------------------------
function ContainerFrameItemButton_OnClick(self, button)
	if _MERCHANT_SHOW and button == "RightButton" and IsModifiedClick("Alt") then
		local itemId = GetContainerItemID(self:GetParent():GetID(), self:GetID())

		if itemId then
			_NotSell[itemId] = nil

			if GetSellLvl(itemId, self:GetParent():GetID(), self:GetID(), 1) == -1 then
				local _, count, _, _, _, _, link = GetContainerItemInfo(self:GetParent():GetID(), self:GetID())

				Log(1, ("Add Auto sell %s."):format(link))

				_WantSell[itemId] = true
				AutoSell()
			end
		end
	end
end

function ContainerFrameItemButton_OnModifiedClick(self, button)
	if _MERCHANT_SHOW and button == "RightButton" and IsModifiedClick("Alt") then
		local itemId = GetContainerItemID(self:GetParent():GetID(), self:GetID())

		if itemId then
			_NotSell[itemId] = nil

			if GetSellLvl(itemId, self:GetParent():GetID(), self:GetID(), 1) == -1 then
				local _, count, _, _, _, _, link = GetContainerItemInfo(self:GetParent():GetID(), self:GetID())

				Log(1, ("Add Auto sell %s."):format(link))

				_WantSell[itemId] = true
				AutoSell()
			end
		end
	end
end

-------------------------------
-- Buy Back Item
-------------------------------
function BuybackItem(index)
	local link = GetBuybackItemLink(index)

	if link then
		local itemId = GetItemId(link)

		if itemId then
			_WantSell[itemId] = nil

			if GetSellLvl(itemId, -1, index) >= 0 then
				_NotSell[itemId] = true
			end
		end
	end
end

-------------------------------
-- Buy Item
-------------------------------
function BuyMerchantItem(index, quantity)
	local link = GetMerchantItemLink(index)

	if link then
		local itemId = GetItemId(link)

		if itemId then
			_WantSell[itemId] = nil

			if GetSellLvl(itemId, -2, index) >= 0 then
				_NotSell[itemId] = true
			end
		end
	end
end