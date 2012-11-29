-------------------------------
-- EasyMail Script
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.EasyMail"

import "System.Threading"

Options = {
	EasyMailSendSameType = L["Send same type material"],
}

_ThreadFriend = Threading.Thread()
_ThreadGuild = Threading.Thread()
_UpdateInterval = 0.1
_CheckCount = 10
_GuildMembers = 0

ITEM_SOULBOUND = ITEM_SOULBOUND

-- OnLoad
function OnLoad(self)
	_Enabled = not _DisabledModule[_Name]

	-- SavedVariables
	_DBChar.EasyMailRecent = _DBChar.EasyMailRecent or {}
	_DB.EasyMailChar = _DB.EasyMailChar or {}
	_DB.EasyMailChar[GetRealmName()] = _DB.EasyMailChar[GetRealmName()] or {}
	local _EasyMailChar = _DB.EasyMailChar[GetRealmName()]
	
	if #_EasyMailChar == 0 then
		tinsert(_EasyMailChar, GetUnitName("player"))
	end
	
	for i, name in ipairs(_EasyMailChar) do
		if name == GetUnitName("player") then
			break
		end
		if i == #_EasyMailChar then
			tinsert(_EasyMailChar, GetUnitName("player"))
		end
	end
	
	_EasyMailRecent = _DBChar.EasyMailRecent
	_EasyMailFriend = {}
	_EasyMailGuild = {}

	lstRecent.Items = _EasyMailRecent
	lstChar.Items = _EasyMailChar
	lstFriend.Items = _EasyMailFriend
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil

	if btnDropdown then
		btnDropdown.Visible = true
	end

	LoadFriend()
	LoadGuild()

	self:RegisterEvent("FRIENDLIST_UPDATE")
	self:RegisterEvent("PLAYER_GUILD_UPDATE")
	self:RegisterEvent("GUILD_ROSTER_UPDATE")
	
	self:SecureHook("SendMailFrame_SendMail", "AddtoRecent")
	self:SecureHook("ContainerFrameItemButton_OnModifiedClick")
end

-- FRIENDLIST_UPDATE
function FRIENDLIST_UPDATE(self)
	LoadFriend()
end

-- PLAYER_GUILD_UPDATE
function PLAYER_GUILD_UPDATE(self)
	LoadGuild()
end

-- GUILD_ROSTER_UPDATE
function GUILD_ROSTER_UPDATE(self)
	LoadGuild()
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true

	if btnDropdown then
		btnDropdown.Visible = false
	end
end

-- Script Handlers
function btnDropdown:OnHide()
	MailList.Visible = false
end

function btnDropdown:OnClick()
	MailList.Visible = not MailList.Visible
end

function lstRecent:OnItemChoosed(key, item)
	SendMailNameEditBox.Text = item or ""
	SendMailNameEditBox.Focused = false
	lstRecent.SelectedIndex = nil
	MailList:Hide()
	--AddtoRecent()
end

function lstChar:OnItemChoosed(key, item)
	SendMailNameEditBox.Text = item or ""
	SendMailNameEditBox.Focused = false
	MailList:Hide()
	--AddtoRecent()
end

function lstFriend:OnItemChoosed(key, item)
	SendMailNameEditBox.Text = item or ""
	SendMailNameEditBox.Focused = false
	MailList:Hide()
	--AddtoRecent()
end

function lstGuild_OnItemChoosed(self, key, item)
	SendMailNameEditBox.Text = item or ""
	SendMailNameEditBox.Focused = false
	MailList:Hide()
	--AddtoRecent()
end

-- Functions
function AddtoRecent()
	local name = SendMailNameEditBox.Text

	if not name or strtrim(name) == "" then
		return
	end

	-- Refresh _EasyMailRecent
	for i, v in ipairs(_EasyMailRecent) do
		if v == name then
			if i == 1 then
				return
			end
			tremove(_EasyMailRecent, i)
			tinsert(_EasyMailRecent, 1, name)
			return
		end
	end

	tinsert(_EasyMailRecent, 1, name)
	if _EasyMailRecent[_MaxRecent + 1] then
		tremove(_EasyMailRecent, _MaxRecent + 1)
	end
end

function LoadFriendThread()	
	local name

	wipe(_EasyMailFriend)
	
	for index = 1, GetNumFriends() do
		name = GetFriendInfo(index)
		tinsert(_EasyMailFriend, name)

		if index % _CheckCount == 0 then
			_ThreadFriend:Sleep(_UpdateInterval)
		end
	end
end

function LoadFriend()
	if not _ThreadFriend:IsDead() then
		return
	end

	Log(1, "Loading friend info for easymail.")

	if #_EasyMailFriend == GetNumFriends() then
		return
	end

	_ThreadFriend.Thread = LoadFriendThread
	
	return _ThreadFriend()
end

function LoadGuildThread()
	local name, rank, rankIndex, maxRank
	local rankName = {}
	local recordName = {}

	for _, data in ipairs(_EasyMailGuild) do
		wipe(data)
	end
	
	maxRank = 0
	
	for index = 1, GetNumGuildMembers(1) do
		name, rank, rankIndex = GetGuildRosterInfo(index)

		rankIndex = rankIndex + 1
		maxRank = maxRank > rankIndex and maxRank or rankIndex

		if rankIndex > #_EasyMailGuild then
			-- create new list for these ranks
			for level = #_EasyMailGuild + 1, rankIndex do
				local mnuRank = mnuGuild:AddMenuButton(("Rank %d"):format(level))

				local lstRank = List("List", mnuRank)

				lstRank.Width = 150
				lstRank.DisplayItemCount = _MaxRecent
				mnuRank.DropDownList = lstRank

				_EasyMailGuild[level] = {}
				lstRank.Items = _EasyMailGuild[level]
				
				lstRank.OnItemChoosed = lstGuild_OnItemChoosed
				_ThreadGuild:Sleep(_UpdateInterval)
			end
		end

		tinsert(_EasyMailGuild[rankIndex], name)
		
		if not rankName[rankIndex] then
			rankName[rankIndex] = rank
		end

		if index % _CheckCount == 0 then
			_ThreadGuild:Sleep(_UpdateInterval)
		end
	end
	
	if maxRank < #_EasyMailGuild then
		for level = #_EasyMailGuild, maxRank + 1, -1 do
			_EasyMailGuild[level] = nil
			mnuGuild:RemoveMenuButton(("Rank %d"):format(level))
		end
	end
	
	_GuildMembers = GetNumGuildMembers(1)
	
	for level = 1, #_EasyMailGuild do
		mnuGuild:GetMenuButton(("Rank %d"):format(level)).Text = rankName[level] or "UnCertain"
	end
end

function LoadGuild()
	if not _ThreadGuild:IsDead() then
		return
	end

	if _GuildMembers == GetNumGuildMembers(1) then return end
	
	Log(1, "Loading guild info for easymail.")

	_ThreadGuild.Thread = LoadGuildThread
	
	return _ThreadGuild()
end

function IsSoulBounded(bag, slot)
	local soulBounded = false

	IGAS.GameTooltip:SetOwner(IGAS.UIParent)
	IGAS.GameTooltip:SetAnchorType("ANCHOR_TOPRIGHT")
	
	IGAS.GameTooltip:SetBagItem(bag, slot)
	
	for i = 1, 5 do
		if _G["GameTooltipTextLeft"..i] and _G["GameTooltipTextLeft"..i]:GetText() == ITEM_SOULBOUND then
			soulBounded = true
			break
		end
	end
	IGAS.GameTooltip:Hide()
	
	return soulBounded
end

function ContainerFrameItemButton_OnModifiedClick(self, button)
	if btnDropdown.Visible and button == "RightButton" and IsModifiedClick("Alt") then
		local itemId = GetContainerItemID(self:GetParent():GetID(), self:GetID())
		
		if not itemId then return end
		
		local _, _, itemRarity, _, _, _, _, _,equipLoc = GetItemInfo(itemId)
		local locked
		local rarity
		
		local emptyCnt = ATTACHMENTS_MAX_SEND
		
		for i=1, ATTACHMENTS_MAX_SEND do
			-- get info about the attachment
			if GetSendMailItem(i) then
				emptyCnt = emptyCnt - 1
			end
		end
		
		if emptyCnt == 0 then return end

		if equipLoc ~= "" and equipLoc ~= "INVTYPE_BODY" and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BAG" and not IsSoulBounded(self:GetParent():GetID(), self:GetID()) then
			for bag = NUM_BAG_FRAMES,0,-1 do
				for slot = GetContainerNumSlots(bag),1,-1 do
					if emptyCnt == 0 then return end
					
					itemId = GetContainerItemID(bag,slot)
					if itemId then
						_, _, locked = GetContainerItemInfo(bag,slot)
						_, _, rarity, _, _, _, _, _,equipLoc = GetItemInfo(itemId)
						
						if not locked and rarity == itemRarity and equipLoc ~= "" and equipLoc ~= "INVTYPE_BODY" and equipLoc ~= "INVTYPE_TABARD" and equipLoc ~= "INVTYPE_BAG" and not IsSoulBounded(bag,slot) then
							emptyCnt = emptyCnt - 1
							UseContainerItem(bag,slot)
						end
					end
				end
			end
		elseif not IsSoulBounded(self:GetParent():GetID(), self:GetID()) then
			local family = GetItemFamily(itemId)
	
			for bag = NUM_BAG_FRAMES,0,-1 do
				for slot = GetContainerNumSlots(bag),1,-1 do
					if emptyCnt == 0 then return end
					
					if itemId == GetContainerItemID(bag,slot) then
						_, _, locked = GetContainerItemInfo(bag,slot)
						
						if not locked then
							emptyCnt = emptyCnt - 1
							UseContainerItem(bag,slot)
						end
					end
				end
			end
			
			if _DBChar.EasyMailSendSameType and family > 0 then
				for bag = NUM_BAG_FRAMES,0,-1 do
					for slot = GetContainerNumSlots(bag),1,-1 do
						if emptyCnt == 0 then return end
						
						if GetContainerItemID(bag,slot) and GetItemFamily(GetContainerItemID(bag,slot)) == family then
							_, _, locked = GetContainerItemInfo(bag,slot)
							
							if not locked then
								emptyCnt = emptyCnt - 1
								UseContainerItem(bag,slot)
							end
						end
					end
				end
			end
		end
	end
end