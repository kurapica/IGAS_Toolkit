-------------------------------
-- AutoQuest
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoQuest"

Options = {
	AutoQuestAcceptAll = L["Accept All"],
	--AutoQuestCanNotReturn = L["Not auto return special quest"],
}

_AcceptedQeust = {}

_WaitTime = 0.3

-- OnLoad
function OnLoad(self)
	--[[ Init
	btnUnReturn = NormalButton("IGAS_Toolkit_AutoQuest_UnReturn", QuestLogFrame)

	btnUnReturn.Style = "Classic"
	btnUnReturn.Width = 120
	btnUnReturn.Height = 24
	btnUnReturn:SetPoint("RIGHT", QuestLogFrameCancelButton, "LEFT")
	btnUnReturn:ActiveThread("OnClick")
	btnUnReturn.OnClick = btnUnReturn_OnClick --]]

	-- SavedVariables
	_DB.AutoQuest = _DB.AutoQuest or {}
	_DBChar.AbandonQuest = _DBChar.AbandonQuest or {}
	_DBChar.UnReturnQuest = _DBChar.UnReturnQuest or {}

	_AutoQuest = _DB.AutoQuest
	_AbandonQuest = _DBChar.AbandonQuest
	UnReturnQuest = _DBChar.UnReturnQuest

	-- Addon's enable state
	_Enabled = not _DisabledModule[_Name]

	-- Events
	self:RegisterEvent("GOSSIP_SHOW")
	self:RegisterEvent("QUEST_DETAIL")
	self:RegisterEvent("QUEST_ACCEPTED")

	self:RegisterEvent("MERCHANT_SHOW")
	self:RegisterEvent("MERCHANT_CLOSED")
	self:RegisterEvent("BAG_OPEN")
	self:RegisterEvent("BAG_CLOSED")

	self:SecureHook("AbandonQuest")
	_DBChar.AutoQuestCanNotReturn = nil
	--self:SecureHook("QuestLog_SetSelection")

	self:ActiveThread("OnEnable")
end

-- OnEvent

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil
	System.Threading.Sleep(3)
	self:RegisterEvent("BAG_UPDATE")
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
	--btnUnReturn.Visible = false
end

-- Events
function QUEST_ACCEPTED(self, questIndex)
	local questName = GetQuestLogTitle(questIndex)
	Log(1, "[QUEST_ACCEPTED] %s", questName)
	_AbandonQuest[questName] = nil
	UnReturnQuest[questName] = nil
end

function GOSSIP_SHOW(self)
	if GetNumGossipActiveQuests() > 0 then
		if SelectActiveQuest(1, GetGossipActiveQuests()) then
			return
		end
	end

	if GetNumGossipAvailableQuests() > 0 then
		if SelectAvailableQuest(1, GetGossipAvailableQuests()) then
			return
		end
	end
end

_AcceptCount = 0

function QUEST_DETAIL(self)
	Log(1, "[AutoQuest] QUEST_DETAIL triggered with count %d.", _AcceptCount)

	local questName = GetTitleText()

	if _AbandonQuest[questName] then
		Log(1, "[AutoQuest] not accept %s.", questName)
	elseif _DBChar.AutoQuestAcceptAll then
		AcceptQuest()
		Log(1, "[AutoQuest] accept %s.", questName)
	elseif _AcceptCount > 0 then
		AcceptQuest()
		Log(1, "[AutoQuest] accept %s.", questName)
	end

	if _AcceptCount > 0 then
		_AcceptCount = _AcceptCount - 1
	end
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
	local isQuest, questId, isActive

	for slot = GetContainerNumSlots(bag),1,-1 do
		isQuest, questId, isActive = GetContainerItemQuestInfo(bag, slot)

		if questId and (not isActive) then
			Log(1, "[AutoQuest] Item Quest Get %s.", questId)
			UseContainerItem(bag,slot)
		end
	end
end

function SelectActiveQuest(index, name, level, isTrivial, isFinished, ...)
	if not name then
		return false
	end

	if isFinished and (not _DBChar.AutoQuestCanNotReturn or not UnReturnQuest[name]) then
		SelectGossipActiveQuest(index)

		return true
	end

	return SelectActiveQuest(index + 1, ...)
end

function SelectAvailableQuest(index, name, level, isTrivial, isDaily, isRepeatable, ...)
	if not name then
		return false
	end

	if _AbandonQuest[name] then
		Log(1, "[SelectAvailableQuest] not select %s.", name)
	elseif _DBChar.AutoQuestAcceptAll then
		SelectGossipAvailableQuest(index)
	elseif _AutoQuest[name] or isDaily or isRepeatable then
		_AcceptCount = _AcceptCount + 1
		SelectGossipAvailableQuest(index)
	elseif _AcceptedQeust[name] then
		_AutoQuest[name] = true
		_AcceptCount = _AcceptCount + 1
		SelectGossipAvailableQuest(index)
	end

	if select('#', ...) == 0 then
		return true
	else
		return SelectAvailableQuest(index + 1, ...)
	end
end

-- Blz Frames hook
QuestFrameAcceptButton:ActiveThread("OnShow")
function QuestFrameAcceptButton:OnShow()
	if not _Enabled then return end

	System.Threading.Sleep(_WaitTime)

	if QuestFrameAcceptButton.Visible and QuestFrameAcceptButton.Enabled then
		local questText = GetTitleText()

		if not _AutoQuest[questText] then
			return
		end

		if ( QuestFlagsPVP() ) then
			return
		else
			if QuestGetAutoAccept() and QuestIsFromAreaTrigger() then
				CloseQuest()
			else
				AcceptQuest()
			end
		end
	end
end

QuestFrameCompleteButton:ActiveThread("OnShow")
function QuestFrameCompleteButton:OnShow()
	if not _Enabled then return end

	System.Threading.Sleep(_WaitTime)

	if QuestFrameCompleteButton.Enabled then
		local questText = GetTitleText()

		if not UnReturnQuest[questText] then
			CompleteQuest()
		end
	end
end

QuestFrameCompleteQuestButton:ActiveThread("OnShow")
function QuestFrameCompleteQuestButton:OnShow()
	if not _Enabled then return end

	System.Threading.Sleep(_WaitTime)

	if QuestFrameCompleteQuestButton.Enabled then
		local questText = GetTitleText()

		_AcceptedQeust[questText] = true

		if ( _G.QuestInfoFrame.itemChoice == 0 and GetNumQuestChoices() > 0 ) then
			local index, maxV = 0, 0

			for i = 1, GetNumQuestChoices() do
				IGAS.GameTooltip:SetOwner(UIParent)
				IGAS.GameTooltip:SetAnchorType("ANCHOR_TOPRIGHT")

				IGAS.GameTooltip:SetQuestItem("choice", i)

				if IGAS.GameTooltip:GetMoney() > maxV then
					maxV = IGAS.GameTooltip:GetMoney()
					index = i
				end
			end

			if index > 0 then
				QuestInfoItem_OnClick(_G["QuestInfoRewardsFrameQuestInfoItem"..index])
			end

			return
		end

		local money = GetQuestMoneyToGet()
		if ( money and money > 0 ) then
			return
		else
			GetQuestReward(_G.QuestInfoFrame.itemChoice)
		end
	end
end
--[[
function btnUnReturn_OnClick()
	local index = GetQuestLogSelection()

	if not index then return end

	local questText = GetQuestLogTitle(index)

	if UnReturnQuest[questText] then
		if IGAS:MsgBox(L["Are you sure to autoreturn this quest - %s ?"]:format(GetQuestLink(index)), "n") then
			Log(1, "Autoreturn quest %s", questText)
			UnReturnQuest[questText] = nil
		end
	else
		if IGAS:MsgBox(L["Are you sure to un-autoreturn this quest - %s ?"]:format(GetQuestLink(index)), "n") then
			Log(1, "Un-Autoreturn quest %s", questText)
			UnReturnQuest[questText] = true
		end
	end

	if UnReturnQuest[questText] then
		btnUnReturn.Text = L["AutoReturn"]
	else
		btnUnReturn.Text = L["Un-AutoReturn"]
	end
end]]

function AbandonQuest()
	local questText = GetAbandonQuestName()

	Log(1, "[QUEST_ABANDONED] %s.", questText)

	_AbandonQuest[questText] = true
	_AcceptedQeust[questText] = nil
	_AutoQuest[questText] = nil
end
--[[
function QuestLog_SetSelection(questIndex)
	if not _DBChar.AutoQuestCanNotReturn then
		btnUnReturn.Visible = false
		return
	end

	local index = GetQuestLogSelection()

	if not index then return end

	local questText = GetQuestLogTitle(index)

	if UnReturnQuest[questText] then
		btnUnReturn.Text = L["AutoReturn"]
	else
		btnUnReturn.Text = L["Un-AutoReturn"]
	end

	btnUnReturn.Visible = true
end]]