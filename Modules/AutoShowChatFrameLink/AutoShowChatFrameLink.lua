-------------------------------
-- AutoShowChatFrameLink
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoShowChatFrameLink"

import "System.Threading"

GameTooltip = IGAS.GameTooltip

Options = {
	AutoShowChatFrameLink_item = L["Show item"],
	AutoShowChatFrameLink_spell = L["Show spell"],
	AutoShowChatFrameLink_enchant = L["Show enchant"],
	AutoShowChatFrameLink_quest = L["Show quest"],
	AutoShowChatFrameLink_talent = L["Show talent"],
	AutoShowChatFrameLink_glyph = L["Show glyph"],
	AutoShowChatFrameLink_achievement = L["Show achievement"],
}

_Thread = Thread()

_CheckCompare = false
_CheckType = nil
_CheckAchievement = nil

-- OnLoad
function OnLoad(self)
	_Enabled = not _DisabledModule[_Name]
	
	for i = 1, NUM_CHAT_WINDOWS do
		IGAS["ChatFrame"..i].OnHyperlinkEnter = OnHyperlinkEnter
		IGAS["ChatFrame"..i].OnHyperlinkLeave = OnHyperlinkLeave
	end
	_Thread.Thread = AutoCheckCompare
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
	
	_CheckCompare = false
	_CheckAchievement = nil
	_CheckType = nil
end

-- OnHyperlinkEnter
function OnHyperlinkEnter(self, linkData)
	local linkType, id = strsplit(":", linkData, 3)

	if _Enabled and _DBChar["AutoShowChatFrameLink_"..linkType] then
		GameTooltip:SetOwner(self, "ANCHOR_CURSOR")
		GameTooltip:SetHyperlink(linkData)
		GameTooltip:Show()
		
		if linkType == "item" then
			_CheckCompare = true
			_CheckType = "item"

			return _Thread()
		elseif linkType == "achievement" and id then
			local selfLink = GetAchievementLink(id)
			
			if selfLink then
				_CheckCompare = true
				_CheckType = "achievement"
				_CheckAchievement = selfLink
				
				return _Thread()
			end
		end
	end
end

-- OnHyperlinkLeave
function OnHyperlinkLeave(self, linkData)
	if _Enabled then
		_CheckCompare = false
		_CheckAchievement = nil
		_CheckType = nil
		GameTooltip:Hide()
		if ( _G.GameTooltip.shoppingTooltips ) then
			for _, frame in pairs(_G.GameTooltip.shoppingTooltips) do
				frame:Hide();
			end
		end
	end
end

-- AutoCheckCompareAchievement
function AutoCheckCompare()
	local inCompare = false
	
	while true do
		if not _CheckCompare then
			inCompare = false
			_Thread:Yield()
		end
		
		Threading.Sleep(0.1)
		
		if _CheckType == "item" then
			if GameTooltip.Visible and IsModifiedClick("COMPAREITEMS") then
				if not inCompare then
					inCompare = true
					GameTooltip_ShowCompareItem()
				end
			elseif inCompare then
				inCompare = false
				if ( _G.GameTooltip.shoppingTooltips ) then
					for _, frame in pairs(_G.GameTooltip.shoppingTooltips) do
						frame:Hide();
					end
				end
			end
		elseif _CheckType == "achievement" then		
			if GameTooltip.Visible and IsModifiedClick("COMPAREITEMS") then
				if not inCompare then
					inCompare = true
					
					-- find correct side
					local rightDist = 0;
					local leftPos = GameTooltip:GetLeft();
					local rightPos = GameTooltip:GetRight();
					if ( not rightPos ) then
						rightPos = 0;
					end
					if ( not leftPos ) then
						leftPos = 0;
					end

					rightDist = GetScreenWidth() - rightPos;

					if (leftPos and (rightDist < leftPos)) then
						_G.GameTooltip.shoppingTooltips[1]:SetOwner(_G.GameTooltip, "ANCHOR_NONE")
						_G.GameTooltip.shoppingTooltips[1]:SetPoint("TOPRIGHT", _G.GameTooltip, "TOPLEFT")
					else
						_G.GameTooltip.shoppingTooltips[1]:SetOwner(_G.GameTooltip, "ANCHOR_NONE")
						_G.GameTooltip.shoppingTooltips[1]:SetPoint("TOPLEFT", _G.GameTooltip, "TOPRIGHT")
					end
					
					_G.GameTooltip.shoppingTooltips[1]:SetHyperlink(_CheckAchievement)
					_G.GameTooltip.shoppingTooltips[1]:Show()
				end
			elseif inCompare then
				inCompare = false
				if ( _G.GameTooltip.shoppingTooltips ) then
					for _, frame in pairs(_G.GameTooltip.shoppingTooltips) do
						frame:Hide();
					end
				end
			end
		end
	end
end