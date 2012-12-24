-------------------------------
-- AutoSplit
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoSplit"

Options = {
}

NUM_BAG_FRAMES = _G.NUM_BAG_FRAMES

StackSplitFrame = _G.StackSplitFrame
StackSplitOkayButton = _G.StackSplitOkayButton
StackSplitCancelButton = _G.StackSplitCancelButton

StackSplitAllButton = CreateFrame("Button", "StackSplitAllButton", StackSplitFrame, "UIPanelButtonTemplate")
StackSplitAllButton:SetWidth(42)
StackSplitAllButton:SetHeight(24)
StackSplitAllButton:Hide()
StackSplitAllButton:SetPoint("CENTER", StackSplitFrame, "BOTTOM", 0, 32)
StackSplitAllButton:SetText(L"Auto")
StackSplitAllButton:SetScript("OnClick", function()
	local item = StackSplitFrame.owner

    StackSplitFrame:Hide()

    if item then
        return _M:ThreadCall(SplitItem, item:GetParent():GetID(), item:GetID(), StackSplitFrame.split)
    end
end)

_ShowSplit = false

StackSplitFrame:HookScript("OnShow", function(self)
	local needShow = false

	if _M._Enabled and self.owner and self.owner:GetName() and self.owner:GetName():match("^ContainerFrame%d") then
		needShow = true
	end

	if _ShowSplit ~= needShow then
		_ShowSplit = needShow
		if _ShowSplit then
			StackSplitOkayButton:SetWidth(40)
			StackSplitOkayButton:SetPoint("RIGHT", StackSplitFrame, "BOTTOM", -23, 32)
			StackSplitCancelButton:SetWidth(40)
			StackSplitCancelButton:SetPoint("LEFT", StackSplitFrame, "BOTTOM", 23, 32)

			StackSplitAllButton:Show()
		else
			StackSplitOkayButton:SetWidth(64)
			StackSplitOkayButton:SetPoint("RIGHT", StackSplitFrame, "BOTTOM", -3, 32)
			StackSplitCancelButton:SetWidth(64)
			StackSplitCancelButton:SetPoint("LEFT", StackSplitFrame, "BOTTOM", 5, 32)

			StackSplitAllButton:Hide()
		end
	end
end)

-- OnLoad
function OnLoad(self)
	-- Addon's enable state
	_Enabled = not _DisabledModule[_Name]

	self:SecureHook("ContainerFrameItemButton_OnModifiedClick")
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil

end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true

end

function ContainerFrameItemButton_OnModifiedClick(self, button)
	if IsAltKeyDown() and button and button:upper() == "LEFTBUTTON" then
		local itemLink = GetContainerItemLink(self:GetParent():GetID(), self:GetID())
		if itemLink then
			local _, _, _, _, _, _, _, itemStackCount = GetItemInfo(itemLink)
			if itemStackCount > 1 then
				return _M:ThreadCall(StackItem, tonumber(itemLink:match":(%d+):"), itemStackCount)
			end
		end
	end
end

----------------------------------------
-- Stack
----------------------------------------
StackLoc = {}

function StackItem(self, itemId, itemStackCount)
	GetLocForStack(itemId, itemStackCount)

	if ceil(StackLoc.Sum / itemStackCount) < StackLoc["Cnt"] then
		while StackItemOnce(itemStackCount) do
			Threading.Sleep(1)
		end
	end
end

function StackItemOnce(itemStackCount)
	local start, last, chg = 1, StackLoc["Cnt"], false
	local _, esLink

	-- ReCount
	for i, v in ipairs(StackLoc) do
		esLink = GetContainerItemLink(v["bag"], v["slot"])
		if esLink then
			_, v["cnt"] = GetContainerItemInfo(v["bag"], v["slot"])
		else
			v["cnt"] = 0
		end
	end

	-- Stack main
	while start < last do
		if StackLoc[start]["cnt"] < itemStackCount then
			if StackLoc[last]["cnt"] > 0 then
				if StackLoc[last]["cnt"] + StackLoc[start]["cnt"] <= itemStackCount then
					PickupContainerItem(StackLoc[last]["bag"], StackLoc[last]["slot"])
					PickupContainerItem(StackLoc[start]["bag"], StackLoc[start]["slot"])
				else
					SplitContainerItem(StackLoc[last]["bag"], StackLoc[last]["slot"], itemStackCount - StackLoc[start]["cnt"])
					PickupContainerItem(StackLoc[start]["bag"], StackLoc[start]["slot"])
				end
				chg = true
				start = start + 1
				last = last - 1
			else
				last = last - 1
			end
		else
			start = start + 1
		end
	end

	return chg
end

function GetLocForStack(itemId, itemStackCount)
    local shdCnt = 0
    StackLoc.Sum = 0

	for bag = NUM_BAG_FRAMES,0,-1 do
		for slot = GetContainerNumSlots(bag),1,-1 do
			local esLink = GetContainerItemLink(bag, slot)

			if esLink then
				if tonumber(esLink:match":(%d+):") == itemId then
					local _, itemCount = GetContainerItemInfo(bag, slot)
					if itemCount < itemStackCount then
						shdCnt = shdCnt + 1
						if not StackLoc[shdCnt] then
							StackLoc[shdCnt]= {}
						end
						StackLoc[shdCnt]["bag"] = bag
						StackLoc[shdCnt]["slot"] = slot
						StackLoc[shdCnt]["cnt"] = itemCount

						StackLoc.Sum = StackLoc.Sum + itemCount
					end
				end
			end
		end
	end

    StackLoc["Cnt"] = shdCnt
    shdCnt = shdCnt + 1
    StackLoc[shdCnt] = nil

	-- Sort
	SortStack()
end

function SortStack()
	local chg = false

	for i, v in ipairs(StackLoc) do
		if StackLoc[i+1] then
			if StackLoc[i]["cnt"] < StackLoc[i+1]["cnt"] then
				chg = true
				StackLoc[i+1], StackLoc[i] = StackLoc[i], StackLoc[i+1]
			end
		end
	end

	if chg then
		return SortStack()
	end
end

----------------------------------------
-- Split
----------------------------------------
FreeLoc = {}

function GetFreeLocForSplit(Cnt)
    local shdCnt = 0

	for bag = NUM_BAG_FRAMES,0,-1 do
		for slot = GetContainerNumSlots(bag),1,-1 do
			if shdCnt >= Cnt then
				break
			end

			esLink = GetContainerItemLink(bag,slot)
			if not esLink then
				shdCnt = shdCnt + 1
				if not FreeLoc[shdCnt] then
					FreeLoc[shdCnt]= {}
				end
				FreeLoc[shdCnt]["bag"] = bag
				FreeLoc[shdCnt]["slot"] = slot
				FreeLoc[shdCnt]["used"] = false
			end
		end
	end

    FreeLoc["Cnt"] = shdCnt
    shdCnt = shdCnt + 1
    FreeLoc[shdCnt] = nil
end

function GetFree()
    for _, loc in ipairs(FreeLoc) do
        if not loc["used"] then
            loc["used"] = true
            return loc
        end
    end
    return nil
end

function SplitItem(self, bag, slot, num)
    local _, itemCount = GetContainerItemInfo(bag, slot)
    local loc

    if itemCount > num and num > 0 then
        GetFreeLocForSplit(math.ceil(itemCount/num))

        while itemCount > num do
        	loc = GetFree()

        	if not loc then return end

			SplitContainerItem(bag, slot, num)
			PickupContainerItem(loc["bag"], loc["slot"])

        	Threading.Sleep(1)	-- Seep safe, wait for 1 sec

        	_, itemCount = GetContainerItemInfo(bag, slot)
        end
    end
end