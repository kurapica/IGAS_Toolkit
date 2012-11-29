-------------------------------
-- HightLightItem
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.HightLightItem"

ITEM_QUALITY_COLORS = ITEM_QUALITY_COLORS

_Mask = setmetatable({}, {__mode = "k"})

-- OnLoad
function OnLoad(self)
	-- SavedVariables
	
	-- Addon's enable state
	_Enabled = not _DisabledModule[_Name]
	
	-- Events
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil
	
	self:SecureHook("ContainerFrame_Update")
	self:SecureHook("PaperDollItemSlotButton_Update")
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
	
	for _, fr in pairs(_Mask) do
		fr.Visible = false
	end
end

-------------------------------
-- ContainerFrame_Update
-------------------------------
function ContainerFrame_Update(frame)	
	local id = frame:GetID();
	local name = frame:GetName();
	local itemButton;
	local questTexture;
	local itemId;
	local _, itemRarity;
	
	for i=1, frame.size, 1 do
		itemButton = _G[name.."Item"..i];
		
		questTexture = _G[name.."Item"..i.."IconQuestTexture"];
		
		if not questTexture:IsShown() then			
			itemId = GetContainerItemID(id, itemButton:GetID())
			if itemId then
				_, _, itemRarity = GetItemInfo(itemId)
				
				if itemRarity ~= 1 then
					questTexture:SetTexture(ITEM_QUALITY_COLORS[itemRarity].r, ITEM_QUALITY_COLORS[itemRarity].g, ITEM_QUALITY_COLORS[itemRarity].b, 0.2)
					questTexture:Show()
				end
			end
		end
	end
end

-------------------------------
-- PaperDollItemSlotButton_Update
-------------------------------
function PaperDollItemSlotButton_Update(self)
	_Mask[self] = _Mask[self] or Texture("Mask", self)
	
	local mask = _Mask[self]
	mask:SetAllPoints(self)
	
	local itemId = GetInventoryItemID("player", self:GetID());
	if itemId then
		local _, _, itemRarity = GetItemInfo(itemId)
		
		if itemRarity ~= 1 then
			mask:SetTexture(ITEM_QUALITY_COLORS[itemRarity].r, ITEM_QUALITY_COLORS[itemRarity].g, ITEM_QUALITY_COLORS[itemRarity].b, 0.3)
			mask.Visible = true
		else
			mask.Visible = false
		end
	end
end