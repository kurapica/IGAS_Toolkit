-------------------------------
-- AutoBuy Script
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoBuy"

-- OnLoad
function OnLoad(self)
	_Enabled = not _DisabledModule[_Name]

	-- SavedVariables
	_DBChar.AutoBuyList = _DBChar.AutoBuyList or {}
	_AutoBuyList = _DBChar.AutoBuyList

	if _DBChar.AutoBuyFormSize then
		frmAutoBuy.Size = _DBChar.AutoBuyFormSize
	end
	if _DBChar.AutoBuyFormPos then
		frmAutoBuy.Position = _DBChar.AutoBuyFormPos
	end

	-- Events
	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")

	self:SecureHook("BuyMerchantItem", "Hook_BuyMerchantItem")
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
	frmAutoBuy.Visible = false
end

-- MERCHANT_SHOW
function MERCHANT_SHOW(self)
	_MERCHANT_SHOW = true
	RefreshList()
end

-- MERCHANT_CLOSED
function MERCHANT_CLOSED(self)
	_MERCHANT_SHOW = false
	frmAutoBuy.Visible = false
end

-- Script Handlers
function frmAutoBuy:OnSizeChanged()
	_DBChar.AutoBuyFormSize = self.Size
end

function frmAutoBuy:OnPositionChanged()
	_DBChar.AutoBuyFormPos = self.Position
end

function frmAutoBuy:OnHide()
    lstBuy:Clear()
end

function btnOk:OnClick()
	_InAutoBuy = true
	AutoBuy()
	_InAutoBuy = nil
	frmAutoBuy.Visible = false
end

function btnCancel:OnClick()
	frmAutoBuy.Visible = false
end

function lstBuy:OnItemChoosed(key)
	self:RemoveItem(key)

	if _MERCHANT_SHOW then
		local link = GetMerchantItemLink(key)

		if link then
			local itemId = GetItemId(link)

			_AutoBuyList[itemId] = nil
		end
	end
end

function lstBuy:OnGameTooltipShow(GameTooltip, key)
	GameTooltip:SetMerchantItem(key)
end

-- GetItemId
function GetItemId(link)
	local _, link = GetItemInfo(link)
	if link then
		return tonumber(link:match":(%d+):")
	end
end

-- RefreshList
function RefreshList()
    lstBuy:Clear()

	local link, itemId, itemName, itemTexture

	for index = 1, GetMerchantNumItems() do
		link = GetMerchantItemLink(index)

		if link then
			itemId = GetItemId(link)

			if _AutoBuyList[itemId] and GetItemCount(itemId) < _AutoBuyList[itemId] then
				itemName, _, _, _, _, _, _, _, _, itemTexture = GetItemInfo(itemId)

				lstBuy:AddItem(index, ("%s * %d"):format(itemName, _AutoBuyList[itemId] - GetItemCount(itemId)), itemTexture)
			end
		end
	end

	if lstBuy.ItemCount > 0 then
		frmAutoBuy.Visible = true
	end
end

-- AutoBuy
function AutoBuy()
	local link, itemId, need, maxStack, count

	for _, index in ipairs(lstBuy.Keys) do
		link = GetMerchantItemLink(index)

		if link then
			itemId = GetItemId(link)

			need = _AutoBuyList[itemId] - GetItemCount(itemId)

			_, _, _, _, _, _, _, maxStack = GetItemInfo(itemId)

			while need > 0 do
				if maxStack >= need then
					BuyMerchantItem(index, need)
					need = need - need
				else
					BuyMerchantItem(index, maxStack)
					need = need - maxStack
				end
			end
		end
	end
end

-------------------------------
-- Buy Item
-------------------------------
function Hook_BuyMerchantItem(index, quantity)
	if _InAutoBuy then return end

	local link = GetMerchantItemLink(index)

	if link then
		local itemId = GetItemId(link)

		if itemId then
			local _, _, _, _, _, _, _, maxStack = GetItemInfo(itemId)
			if maxStack > 1 then
				if not quantity then
					_, _, _, quantity= GetMerchantItemInfo(index)
				end
				_AutoBuyList[itemId] = GetItemCount(itemId) + quantity or 1
				Log(1, "%s max %d", link, _AutoBuyList[itemId])
			end
		end
	end
end