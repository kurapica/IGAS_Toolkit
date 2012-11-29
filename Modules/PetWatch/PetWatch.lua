-------------------------------
-- PetWatch
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.PetWatch"

LE_PET_JOURNAL_FLAG_COLLECTED = LE_PET_JOURNAL_FLAG_COLLECTED
LE_PET_JOURNAL_FLAG_FAVORITES = LE_PET_JOURNAL_FLAG_FAVORITES
LE_PET_JOURNAL_FLAG_NOT_COLLECTED = LE_PET_JOURNAL_FLAG_NOT_COLLECTED
SEARCH = SEARCH

_PetList = {}
_Score = {}
_Health = {}
_Power = {}
_Speed = {}

_PetCount = 0

_PrevSettings = {}

Options = {
	PetWatchShowCollect = L["Show collected pet"],
	PetWatchShowNotCollect = L["Show not collected pet"],
}

_QualityColor = {
}

for i = -1, NUM_ITEM_QUALITIES do
    _QualityColor[i+1] = ITEM_QUALITY_COLORS[i].hex
end

-- OnLoad
function OnLoad(self)
	-- SavedVariables

	-- Addon's enable state
	_Enabled = not _DisabledModule[_Name]

	-- Events
	self:RegisterEvent("PET_JOURNAL_LIST_UPDATE")
	self:RegisterEvent("PET_JOURNAL_PET_DELETED")
	self:RegisterEvent("PLAYER_ENTERING_WORLD")
	self:RegisterEvent("ADDON_LOADED")
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil

	self:SecureHook("PetBattleUnitTooltip_UpdateForUnit")
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
end

function OnEvent(self, event, addon)
	if event == "ADDON_LOADED" then
		if addon == "Blizzard_PetJournal" then
			self:SecureHook("PetJournal_UpdatePetCard")

			function PetJournalParent:OnShow()
				_M._Block = true
				_M._NeedUpdate = false
			end

			function PetJournalParent:OnHide()
				_M._Block = false
				if _M._NeedUpdate then
					_M._NeedUpdate = false
					UpdatePetList()
				end
			end
		end
	elseif event == "PLAYER_ENTERING_WORLD" then
		if _M._BattlePetInfoLoaded then
			_M._NeedUpdateNeedList = false
			UpdateNeedList()
		else
			_M._NeedUpdateNeedList = true
		end
	else
		_M._BattlePetInfoLoaded = true
		UpdatePetList()
	end
end

function CalcPetScore(petID)
	local speciesID, _, level, _, _, _, _, _, _, _, _, _, _, canBattle = C_PetJournal.GetPetInfoByPetID(petID);
	if ( not speciesID ) then
		return
	end

	if not canBattle then
		return 0, 0, 0, 0
	end

	local health, maxHealth, power, speed = C_PetJournal.GetPetStats(petID);

	local lvlHealth = (maxHealth-100)/level
	local lvlPower = power/level
	local lvlSpeed = speed/level

	return lvlHealth/5 + lvlPower + lvlSpeed, lvlHealth, lvlPower, lvlSpeed
end

function GetColor(real, own)
	if real == own then
		return "|cffffffff"
	elseif real > own then
		return "|cffff2020"
	else
		return "|cff808080"
	end
end

function KeepConfig()
	_M:BlockScript("OnEvent")

	_PrevSettings[LE_PET_JOURNAL_FLAG_COLLECTED] = C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_COLLECTED)
	_PrevSettings[LE_PET_JOURNAL_FLAG_FAVORITES] = C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_FAVORITES)
	_PrevSettings[LE_PET_JOURNAL_FLAG_NOT_COLLECTED] = C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_NOT_COLLECTED)

	for i=1, C_PetJournal.GetNumPetTypes() do
		_PrevSettings["TYPE"..i] = not C_PetJournal.IsPetTypeFiltered(i)
	end

	for i = 1, C_PetJournal.GetNumPetSources() do
		_PrevSettings["SOURCE"..i] = not C_PetJournal.IsPetSourceFiltered(i)
	end

	if _G.PetJournalSearchBox then
		_PrevSettings["Search"] = _G.PetJournalSearchBox:GetText()
	end
end

function Filter(collected, noneCollected)
	if _PrevSettings[LE_PET_JOURNAL_FLAG_COLLECTED] ~= collected then
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED, collected)
	end

	if _PrevSettings[LE_PET_JOURNAL_FLAG_FAVORITES] then
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES, false)
	end

	if _PrevSettings[LE_PET_JOURNAL_FLAG_NOT_COLLECTED] ~= noneCollected then
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED, noneCollected)
	end

	for i=1, C_PetJournal.GetNumPetTypes() do
		if not _PrevSettings["TYPE"..i] then
	    	C_PetJournal.SetPetTypeFilter(i, true)
	    end
	end

	for i = 1, C_PetJournal.GetNumPetSources() do
		if _PrevSettings["SOURCE"..i] ~= (i==5) then
	   		C_PetJournal.SetPetSourceFilter(i, i==5)
	   	end
	end

	C_PetJournal.ClearSearchFilter()
end

function RestoreConfig()
	if _PrevSettings[LE_PET_JOURNAL_FLAG_COLLECTED] ~= C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_COLLECTED) then
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_COLLECTED, _PrevSettings[LE_PET_JOURNAL_FLAG_COLLECTED])
	end

	if _PrevSettings[LE_PET_JOURNAL_FLAG_FAVORITES] ~= C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_FAVORITES) then
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_FAVORITES, _PrevSettings[LE_PET_JOURNAL_FLAG_FAVORITES])
	end

	if _PrevSettings[LE_PET_JOURNAL_FLAG_NOT_COLLECTED] ~= C_PetJournal.IsFlagFiltered(LE_PET_JOURNAL_FLAG_NOT_COLLECTED) then
		C_PetJournal.SetFlagFilter(LE_PET_JOURNAL_FLAG_NOT_COLLECTED, _PrevSettings[LE_PET_JOURNAL_FLAG_NOT_COLLECTED])
	end

	for i=1, C_PetJournal.GetNumPetTypes() do
		if _PrevSettings["TYPE"..i] ~= not C_PetJournal.IsPetTypeFiltered(i) then
	    	C_PetJournal.SetPetTypeFilter(i, _PrevSettings["TYPE"..i])
	    end
	end

	for i = 1, C_PetJournal.GetNumPetSources() do
		if _PrevSettings["SOURCE"..i] ~= not C_PetJournal.IsPetSourceFiltered(i) then
	    	C_PetJournal.SetPetSourceFilter(i, _PrevSettings["SOURCE"..i])
	    end
	end

	if _G.PetJournalSearchBox then
		_G.PetJournalSearchBox:SetText(_PrevSettings["Search"])
		if _PrevSettings["Search"] and _PrevSettings["Search"] ~= "" and _PrevSettings["Search"] ~= SEARCH then
			PetJournal_OnSearchTextChanged(_G.PetJournalSearchBox)
		end
	end

	_M:UnBlockScript("OnEvent")
end

function UpdateNeedList(noFilter)
	if not _DBChar.PetWatchShowCollect and not _DBChar.PetWatchShowNotCollect then return end

	if not noFilter then
		KeepConfig()
		Filter(_DBChar.PetWatchShowCollect, _DBChar.PetWatchShowNotCollect)
	end

	local area = GetZoneText()
	local collected = ""
	local noneCollected = ""
	local temp = {}

	if area then
		local petID, speciesID, owned, name, sourceText, isWildPet, _

		for i = 1, C_PetJournal.GetNumPets(false) do
			petID, speciesID, owned, _, _, _, _, name, _, _, _, sourceText, _, isWildPet = C_PetJournal.GetPetInfoByIndex(i)
			if isWildPet and sourceText and not temp[speciesID] and sourceText:find(area) then
				temp[speciesID] = true
				if owned then
					collected = collected .. (C_PetJournal.GetBattlePetLink(petID) or "")
				else
					noneCollected = noneCollected .. "[" .. name .. "]"
				end
			end
		end
		Log(3, L"[PetWatch][%s]:", area)
		if _DBChar.PetWatchShowCollect then
			Log(2, L"[Collected]%s", collected)
		end
		if _DBChar.PetWatchShowNotCollect then
			Log(2, L"[Not Collected]%s", noneCollected)
		end
	end

	if not noFilter then
		RestoreConfig()
	end
end

function UpdatePetList()
	if _M._Block then
		_M._NeedUpdate = true
		return
	end

	if C_PetJournal.GetNumPets(false) == _PetCount then
		return
	end
	_PetCount = C_PetJournal.GetNumPets(false)

	KeepConfig()
	if _M._NeedUpdateNeedList then
		Filter(true, _DBChar.PetWatchShowNotCollect)
	else
		Filter(true)
	end

	local petScore, lvlHealth, lvlPower, lvlSpeed
	local petID, speciesID, owned, name, sourceText, isWildPet, _

	wipe(_PetList)
	wipe(_Score)
	wipe(_Health)
	wipe(_Power)
	wipe(_Speed)
	for i = 1, _PetCount do
		petID, speciesID, owned, _, _, _, _, name, _, _, _, sourceText, _, isWildPet = C_PetJournal.GetPetInfoByIndex(i)
		if isWildPet then
			if owned then
				_PetList[speciesID] = true

				petScore, lvlHealth, lvlPower, lvlSpeed = CalcPetScore(petID)

				if not _Score[speciesID] or petScore > _Score[speciesID] then
					Log(1, "Register battlepet %s", name)
					_Score[speciesID] = petScore
					_Health[speciesID] = lvlHealth
					_Power[speciesID] = lvlPower
					_Speed[speciesID] = lvlSpeed
				end
			end
		end
	end

	if _M._NeedUpdateNeedList then
		_M._NeedUpdateNeedList = false
		UpdateNeedList(true)
	end

	RestoreConfig()
end

function SetupCard(self)
	local petScore = FontString("Score", self, "ARTWORK", "GameFontNormalSmall")
	petScore:SetPoint("LEFT", self.QualityFrame.quality, "RIGHT")
	self.petScore = petScore

	local lvlHealth = FontString("lvlHealth", self, "ARTWORK", "GameFontNormalSmall")
	lvlHealth:SetPoint("LEFT", self.HealthFrame.health, "RIGHT")
	self.lvlHealth = lvlHealth

	local lvlPower = FontString("lvlPower", self, "ARTWORK", "GameFontNormalSmallLeft")
	lvlPower:SetPoint("LEFT", self.PowerFrame.power, "RIGHT")
	self.lvlPower = lvlPower

	local lvlSpeed = FontString("lvlSpeed", self, "ARTWORK", "GameFontNormalSmallLeft")
	lvlSpeed:SetPoint("LEFT", self.SpeedFrame.speed, "RIGHT")
	self.lvlSpeed = lvlSpeed
end

function SetupTooltip(self)
	self.AbilitiesLabel:ClearAllPoints()
	self.AbilitiesLabel:SetPoint("TOPLEFT", self.Delimiter, "BOTTOMLEFT", 150, -8)

	self.HealthText:ClearAllPoints()
	self.HealthText:SetPoint("LEFT", self.ActualHealthBar, "LEFT")

	local petScore = FontString("Score", self, "ARTWORK", "GameFontNormalSmall")
	petScore:SetPoint("LEFT", self.StatsLabel, "RIGHT")
	self.petScore = petScore

	local lvlHealth = FontString("lvlHealth", self, "ARTWORK", "GameFontNormalSmall")
	lvlHealth:SetPoint("RIGHT", self.HealthBG, "RIGHT")
	self.lvlHealth = lvlHealth

	local lvlPower = FontString("lvlPower", self, "ARTWORK", "GameFontNormalSmallLeft")
	lvlPower:SetPoint("LEFT", self.AttackAmount, "RIGHT")
	self.lvlPower = lvlPower

	local lvlSpeed = FontString("lvlSpeed", self, "ARTWORK", "GameFontNormalSmallLeft")
	lvlSpeed:SetPoint("LEFT", self.SpeedAmount, "RIGHT")
	self.lvlSpeed = lvlSpeed
end

function PetJournal_UpdatePetCard(self)
	if not self.lvlHealth then SetupCard(self) end

	if self.petID then
		local petScore, lvlHealth, lvlPower, lvlSpeed = CalcPetScore(self.petID)

		if petScore and petScore > 0 then
			self.petScore.Text = ("(%.2f)"):format(petScore)
			self.lvlHealth.Text = ("(+%.2f)"):format(lvlHealth)
			self.lvlPower.Text = ("(+%.1f)"):format(lvlPower)
			self.lvlSpeed.Text = ("(+%.1f)"):format(lvlSpeed)
		else
			self.petScore.Text = ""
			self.lvlHealth.Text = ""
			self.lvlPower.Text = ""
			self.lvlSpeed.Text = ""
		end
	else
		self.petScore.Text = ""
		self.lvlHealth.Text = ""
		self.lvlPower.Text = ""
		self.lvlSpeed.Text = ""
	end
end

function PetBattleUnitTooltip_UpdateForUnit(self, petOwner, petIndex)
	if not self.lvlHealth then SetupTooltip(self) end

	local hpfactor = C_PetBattles.IsWildBattle() and C_PetBattles.IsPlayerNPC(petOwner) and 1.20 or 1
	local quality = C_PetBattles.GetBreedQuality(petOwner, petIndex)
	local level = C_PetBattles.GetLevel(petOwner, petIndex)
	local lvlHealth = (C_PetBattles.GetMaxHealth(petOwner, petIndex) * hpfactor - 100)/level
	local lvlPower = C_PetBattles.GetPower(petOwner, petIndex)/level
	local lvlSpeed = C_PetBattles.GetSpeed(petOwner, petIndex)/level
	local score = lvlHealth/5 + lvlPower + lvlSpeed

	self.Name:SetText((_QualityColor[quality] or "")..self.Name:GetText())

	self.petScore.Text = ("(%.2f)"):format(score)
	self.lvlHealth.Text = ("(+%.2f)"):format(lvlHealth)
	self.lvlPower.Text = ("(+%.1f)"):format(lvlPower)
	self.lvlSpeed.Text = ("(+%.1f)"):format(lvlSpeed)

    if C_PetBattles.IsWildBattle() and C_PetBattles.IsPlayerNPC(petOwner) then
    	local speciesID = C_PetBattles.GetPetSpeciesID(petOwner, petIndex)

        if _PetList[speciesID] then
			self.petScore.Text = self.petScore.Text .. GetColor(score, _Score[speciesID]) .. ("(%+.2f)"):format(score - _Score[speciesID])
			self.lvlHealth.Text = self.lvlHealth.Text .. GetColor(lvlHealth, _Health[speciesID]) .. ("(%+.2f)"):format(lvlHealth - _Health[speciesID])
			self.lvlPower.Text = self.lvlPower.Text .. GetColor(lvlPower, _Power[speciesID]) .. ("(%+.1f)"):format(lvlPower - _Power[speciesID])
			self.lvlSpeed.Text = self.lvlSpeed.Text .. GetColor(lvlSpeed, _Speed[speciesID]) .. ("(%+.1f)"):format(lvlSpeed - _Speed[speciesID])
        end
    end
end
