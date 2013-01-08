-------------------------------
-- AuctionHelper Script
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AuctionHelper"

abs = math.abs
rep = string.rep

--------------------------
-- fake bit
--------------------------
function binit(pos)
	return "1"..rep("0", pos - 1)
end

function bor(b1, b2)
	if type(b1) ~= "string" or type(b2) ~= "string" then
		return 0
	end

	local maxS, minS
	if b1:len() < b2:len() then
		maxS, minS = b2, b1
	else
		maxS, minS = b1, b2
	end

	for i = 1, minS:len() do
		if minS:sub(-i, -i) == "1" and maxS:sub(-i, -i) == "0" then
			if i == 1 then
				maxS = maxS:sub(1, -i-1) .. "1"
			elseif i == maxS:len() then
				maxS = "1" .. maxS:sub(2, -1)
			else
				maxS = maxS:sub(1, -i-1) .. "1" .. maxS:sub(-i+1, -1)
			end
		end
	end

	return maxS
end

function band(b1, b2)
	if type(b1) ~= "string" or type(b2) ~= "string" then
		return 0
	end

	local maxS, minS
	if b1:len() < b2:len() then
		maxS, minS = b2, b1
	else
		maxS, minS = b1, b2
	end

	for i = 1, minS:len() do
		if minS:sub(-i, -i) ~= maxS:sub(-i, -i) then
			if i == 1 then
				minS = minS:sub(1, -i-1) .. "0"
			elseif i == minS:len() then
				for j = 2, minS:len() do
					if minS:sub(j, j) == "1" or j == minS:len() then
						minS = minS:sub(j, -1)
						break
					end
				end
			else
				minS = minS:sub(1, -i-1) .. "0" .. minS:sub(-i+1, -1)
			end
		end
	end

	return minS
end

RED_GEM = RED_GEM
BLUE_GEM = BLUE_GEM
YELLOW_GEM = YELLOW_GEM
META_GEM = META_GEM

RED_GEM_LOW = RED_GEM:lower()
BLUE_GEM_LOW = BLUE_GEM:lower()
YELLOW_GEM_LOW = YELLOW_GEM:lower()
META_GEM_LOW = META_GEM:lower()

BIT_RED = binit(1)
BIT_BLUE = binit(2)
BIT_YELLOW = binit(3)
BIT_META = binit(4)
BIT_GEM = "1111"

GLYPH_INDEX = 5
GEM_INDEX = 8
BATTLEPET_INDEX = 11

MAX_HISTORY = 20
DISPLAY_HISTORY = 10

NUM_AUCTION_ITEMS_PER_PAGE = _NUM_AUCTION_ITEMS_PER_PAGE

_GameTooltip = IGAS.GameTooltip

Options = {
	AuctionHelperHistory = L["Show Search History"],
	AuctionHelperGemHelper = L["Show Gem Helper"],
	AuctionHelperGlyphHelper = L["Show Glyph Helper"],
}

-- OnLoad
function OnLoad(self)
	_Enabled = not _DisabledModule[_Name]

	-- SavedVariables
	_DB.AuctionHelperHistory = _DB.AuctionHelperHistory or {}
	_Items = _DB.AuctionHelperHistory

	-- Gem Helper
	_DB.GemHelper_Gems = _DB.GemHelper_Gems or {}
	_DB.GemHelper_GemProps = _DB.GemHelper_GemProps or {
		RED_GEM,
		BLUE_GEM,
		YELLOW_GEM,
		META_GEM,
	}

	_DB.GlyphReminder = _DB.GlyphReminder or {}
	_DB.GlyphReminder[GetRealmName()] = _DB.GlyphReminder[GetRealmName()] or {}
	_Player = GetUnitName("player")

	_Gems = _DB.GemHelper_Gems
	_Props = _DB.GemHelper_GemProps
	_Glyph = _DB.GlyphReminder[GetRealmName()]

	_TempGlyph = _TempGlyph or {}

	for _, dt in pairs(_Glyph) do
		for name, id in pairs(dt) do
			_TempGlyph[name] = id
		end
	end

	_PropsIndex = {}

	for i, prop in ipairs(_Props) do
		_PropsIndex[prop] = binit(i)
	end

	_Data = {
		{}, -- RED
		{}, -- BLUE
		{}, -- YELLOW
		{} -- META
	}

	BuildData()

	self:RegisterEvent("ADDON_LOADED")
	self:RegisterEvent("USE_GLYPH")

	-- HistoryThread
	_ThreadHistory = System.Threading.Thread()

	_GameTooltip.OnShow = _GameTooltip.OnShow + GameTooltip_OnShow
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil

	if Initialization and _G.AuctionFrameFilter_OnClick then
		ADDON_LOADED(self, "Blizzard_AuctionUI")
	end

	USE_GLYPH(self)
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
end

-- ADDON_LOADED
function ADDON_LOADED(self, name)
	if name == "Blizzard_AuctionUI" then
		Log(1, "[AuctionHelper] Loading")

		Initialization()

		-- Hook
		self:SecureHook("AuctionFrameFilter_OnClick")
		self:SecureHook("AuctionFrameBrowse_Search", "AuctionFrameBrowse_Search_Hook")

		self:ActiveThread("OnHook")

		Initialization = nil
	end
end

-- USE_GLYPH
function USE_GLYPH(self)
	-- Rescan player's glyph info
	_Glyph[_Player] = _Glyph[_Player] or {}

	local name, glyphType, isKnown, icon, glyphId, glyphLink

	for i = 1, GetNumGlyphs() do
		name, glyphType, isKnown, icon, glyphId, glyphLink = GetGlyphInfo(i)

		name = glyphLink and glyphLink:match("%[(.*)%]")

		if name then
			if not isKnown and not _Glyph[_Player][name] then
				_Glyph[_Player][name] = glyphId
				_TempGlyph[name] = glyphId
			elseif isKnown and _Glyph[_Player][name] then
				for n, id in pairs(_Glyph[_Player]) do
					if id == glyphId then
						_Glyph[_Player][n] = nil

						local chk = false

						for _, dt in pairs(_Glyph) do
							if dt[n] then
								chk = true
								break
							end
						end

						if not chk then
							_TempGlyph[n] = nil
						end
					end
				end
			end
		end
	end
end

-- GameTooltip_OnShow
function GameTooltip_OnShow(self)
	if not _Enabled or not _DBChar.AuctionHelperGlyphHelper then return end

	local name = self:GetLeftText(1)

	if name and _TempGlyph[name] then
		local found = false

		for player, dt in pairs(_Glyph) do
			if dt[name] then
				if not found then
					found = true
					self:AddLine(" ")
				end
				self:AddDoubleLine(L["Needed By"], player)
			end
		end
	end
end

-- Hook
function AuctionFrameFilter_OnClick(self, button)
	if _Enabled and _DBChar.AuctionHelperGemHelper and _G.AuctionFrameBrowse.selectedClassIndex == GEM_INDEX then
		frmGemHelper.Visible = true
		frmGlyphHelper.Visible = false
	elseif _Enabled and _DBChar.AuctionHelperGlyphHelper and _G.AuctionFrameBrowse.selectedClassIndex == GLYPH_INDEX then
		frmGemHelper.Visible = false
		frmGlyphHelper.Visible = true
	else
		frmGemHelper.Visible = false
		frmGlyphHelper.Visible = false
	end
end

function AuctionFrameBrowse_Search_Hook()
	local search = BrowseName:GetText()

	if search and strtrim(search) ~= "" then
		System.Threading.WaitEvent("AUCTION_ITEM_LIST_UPDATE")

		local numBatchAuctions, totalAuctions = GetNumAuctionItems("list")
		local cache = {}
		local name, link

		for i = 1, numBatchAuctions do
			name = GetAuctionItemInfo("list", i)

			if name == search then
				--[[_GameTooltip:SetOwner(IGAS.UIParent, "ANCHOR_TOPRIGHT")
				_GameTooltip:SetAuctionItem("list", i)
				name, link = _GameTooltip:GetItem()
				link = select(2, GetItemInfo(GetItemId(link)))

				_GameTooltip:Hide()--]]

				link = GetAuctionItemLink("list", i)

				-- Refresh _Items
				for i, v in ipairs(_Items) do
					if GetItemId(v) == GetItemId(link) then
						if i == 1 then
							return
						end
						tremove(_Items, i)
						tinsert(_Items, 1, link)
						return HistoryList:SelectItemByIndex(1)
					end
				end

				tinsert(_Items, 1, link)
				if _Items[MAX_HISTORY + 1] then
					tremove(_Items, MAX_HISTORY + 1)
				end

				HistoryList:SelectItemByIndex(1)
			end
		end
	end
end

-- Scripts
function GetItemId(link)
	local _, link = GetItemInfo(link)
	if link then
		return tonumber(link:match":(%d+):")
	end
end

function ScanGem()
	local page
	local total
	local name, link, itemId
	local itemCnt = 0
	local numBatchAuctions, totalAuctions
	local cache = {}
	local bonus
	local prop, sprop
	local split = _Gems[0]
	local unHandle = {}
	local handled
	local text, lowtext
	local maxS, start

	for colorIndex = 1, 7 do
		page = 0
		total = 0

		if colorIndex == 7 and not split then
			if next(unHandle) then
				-- compare to get the split
				if not split or split == "" then
					maxS = nil

					for _, p in pairs(unHandle) do
						if not maxS then
							maxS = p
						else
							-- compare
							start = -1

							while abs(start) <= maxS:len() and abs(start) <= p:len() and maxS:sub(start, -1) == p:sub(start, -1) do
								start = start - 1
							end

							if start < -1 then
								start = start + 1
								maxS = maxS:sub(start, -1)
							else
								-- well this can't happen.
								return IGAS:MsgBox(L["Scan abort! please try later."])
							end
						end
					end

					split = maxS and strtrim(maxS) or ""
				end

				if split ~= "" then
					_Gems[0] = split
					Log(1, "[AuctionHelper] found the split : %s.", split)

					-- do the unhandle things
					for gem, p in pairs(unHandle) do
						p = p:match("(.*)" .. split .. "$")
						p = p and strtrim(p) or ""

						if p ~= "" then
							if not _PropsIndex[p] then
								tinsert(_Props, p)
								Log(1, "[AuctionHelper] Property '%s' added.", p)
								_PropsIndex[p] = binit(#_Props)
							end
							_Gems[gem] = bor(_Gems[gem], _PropsIndex[p])
						end
					end

					wipe(unHandle)
				else
					split = nil
				end
			end

			-- well, this case make all difficult
			while not split or split == "" do
				split = IGAS:MsgBox(L["Please input the split characters for gem property."], "i")

				split = split and strtrim(split) or ""

				if split ~= "" and next(unHandle) then
					-- do the unhandle things
					for gem, p in pairs(unHandle) do
						p = p:match("(.*)" .. split .. "$")
						p = p and strtrim(p) or ""

						if p == "" then
							split = nil
							break
						end
					end

					if split and split ~= "" then
						for gem, p in pairs(unHandle) do
							p = p:match("(.*)" .. split .. "$")
							p = p and strtrim(p) or ""

							if p ~= "" then
								if not _PropsIndex[p] then
									tinsert(_Props, p)
									Log(1, "[AuctionHelper] Property '%s' added.", p)
									_PropsIndex[p] = binit(#_Props)
								end
								_Gems[gem] = bor(_Gems[gem], _PropsIndex[p])
							else
								break
							end
						end

						wipe(unHandle)
					end
				end
			end

			wipe(unHandle)

			if not _Gems[0] and split then
				_Gems[0] = split
				Log(1, "[AuctionHelper] found the split : %s.", split)
			end
		end

		while true do
			while not CanSendAuctionQuery("list") do
				System.Threading.Sleep(0.1)
			end

			QueryAuctionItems("", "", "", nil, GEM_INDEX, colorIndex, page, nil, -1)

			System.Threading.WaitEvent("AUCTION_ITEM_LIST_UPDATE")

			numBatchAuctions, totalAuctions = GetNumAuctionItems("list")

			for i = 1, numBatchAuctions do
				name = GetAuctionItemInfo("list", i)

				if name and not cache[name] then
					cache[name] = true
					_GameTooltip:SetOwner(IGAS.UIParent, "ANCHOR_TOPRIGHT")
					_GameTooltip:SetAuctionItem("list", i)
					name, link = _GameTooltip:GetItem()
					itemId = GetItemId(link)

					if _GameTooltip:NumLines() > 1 then
						bonus = "0"
						handled = false
						maxS = nil

						for i = _GameTooltip:NumLines(), 2, -1 do
							text = _G["GameTooltipTextLeft"..i]:GetText()
							lowtext = text:lower()

							if lowtext:find(META_GEM_LOW) then
								bonus = bor(bonus, BIT_META)
							end

							if band(bonus, BIT_META) ~= BIT_META then
								if lowtext:find(RED_GEM_LOW) then
									bonus = bor(bonus, BIT_RED)
								end
								if lowtext:find(BLUE_GEM_LOW) then
									bonus = bor(bonus, BIT_BLUE)
								end
								if lowtext:find(YELLOW_GEM_LOW) then
									bonus = bor(bonus, BIT_YELLOW)
								end
							end

							if bonus ~= "0" then
								if colorIndex < 4 then
									-- simple gem
									if text:find("+") then
										prop = text:match("+%d+%s*(.*)$")

										prop = prop and strtrim(prop) or ""

										if prop ~= "" then
											if not _PropsIndex[prop] then
												tinsert(_Props, prop)
												Log(1, "[AuctionHelper] Property '%s' added.", prop)
												_PropsIndex[prop] = binit(#_Props)
											end
											bonus = bor(bonus, _PropsIndex[prop])
										end
									end
								elseif colorIndex < 7 then
									-- mixed gem
									if text:find("+") then
										prop, sprop = text:match("+%d+%s*([^%+]*)+%d+%s*(.*)$")

										prop = prop and strtrim(prop) or ""
										sprop = sprop and strtrim(sprop) or ""

										if sprop ~= "" then
											if not _PropsIndex[sprop] then
												tinsert(_Props, sprop)
												Log(1, "[AuctionHelper] Property '%s' added.", sprop)
												_PropsIndex[sprop] = binit(#_Props)
											end
											bonus = bor(bonus, _PropsIndex[sprop])
										end

										if prop ~= "" then
											if not split then
												-- Check _Props
												for _, pr in ipairs(_Props) do
													if prop:find(pr) then
														split = prop:sub(select(2, prop:find(pr)) + 1, -1)

														split = split and strtrim(split) or ""

														if split ~= "" then
															_Gems[0] = split
															Log(1, "[AuctionHelper] found the split : %s.", split)

															-- do the unhandle things
															for gem, p in pairs(unHandle) do
																p = p:match("(.*)" .. split .. "$")
																p = p and strtrim(p) or ""

																if p ~= "" then
																	if not _PropsIndex[p] then
																		tinsert(_Props, p)
																		Log(1, "[AuctionHelper] Property '%s' added.", p)
																		_PropsIndex[p] = binit(#_Props)
																	end
																	_Gems[gem] = bor(_Gems[gem], _PropsIndex[p])
																end
															end

															wipe(unHandle)

															break
														else
															split = nil
														end
													end
												end
											end

											if not split then
												unHandle[itemId] = prop
											else
												prop = prop:match("(.*)" .. split .. "$")
												prop = prop and strtrim(prop) or ""

												if prop ~= "" then
													if not _PropsIndex[prop] then
														tinsert(_Props, prop)
														Log(1, "[AuctionHelper] Property '%s' added.", prop)
														_PropsIndex[prop] = binit(#_Props)
													end
													bonus = bor(bonus, _PropsIndex[prop])
												end
											end
										end
									end
								else
									if not maxS then
										maxS = text
									elseif maxS:len() <= text:len() then
										maxS = text
									end

									-- Meta
									if text:find("+") then
										handled = true

										prop, sprop = text:match("+%d+%s*(.*)".. split .."(.*)$")

										prop = prop and strtrim(prop) or ""
										sprop = sprop and strtrim(sprop) or ""

										if prop ~= "" then
											if not _PropsIndex[prop] then
												tinsert(_Props, prop)
												Log(1, "[AuctionHelper] Property '%s' added.", prop)
												_PropsIndex[prop] = binit(#_Props)
											end
											bonus = bor(bonus, _PropsIndex[prop])
										end

										if sprop ~= "" then
											sprop = sprop:gsub("%d+", "x")

											if not _PropsIndex[sprop] then
												tinsert(_Props, sprop)
												Log(1, "[AuctionHelper] Property '%s' added.", sprop)
												_PropsIndex[sprop] = binit(#_Props)
											end
											bonus = bor(bonus, _PropsIndex[sprop])
										end
									end
								end
							end
						end

						if colorIndex == 7 and not handled and maxS and band(bonus, BIT_META) == BIT_META then
							-- some special meta gem, well use the longest line as the property
							sprop = maxS and strtrim(maxS) or ""

							if sprop ~= "" then
								sprop = sprop:gsub("%d+", "x")

								if not _PropsIndex[sprop] then
									tinsert(_Props, sprop)
									Log(1, "[AuctionHelper] Property '%s' added.", sprop)
									_PropsIndex[sprop] = binit(#_Props)
								end
								bonus = bor(bonus, _PropsIndex[sprop])
							end
						end

						if bonus ~= "0" then
							_Gems[itemId] = bonus
						end
					end

					_GameTooltip:Hide()

					itemCnt = itemCnt + 1
				end
			end

			total = total + numBatchAuctions

			if numBatchAuctions < NUM_AUCTION_ITEMS_PER_PAGE or total >= totalAuctions then
				break
			end

			page = page + 1
		end
	end

	BuildData()

	return IGAS:MsgBox(L["Gem scan finished, thanks for waiting."])
end

function BuildData()
	for i, dt in ipairs(_Data) do
		for j = 1, #_Props do
			dt[j] = "0"
		end
	end

	local _mask = {}
	for i = 1, 4 do
		_mask[i] = binit(i)
	end

	local name

	for gem, bonus in pairs(_Gems) do
		if gem ~= 0 then
			name = GetItemInfo(gem) -- don't remove this
			for i = 1, 4 do
				if band(bonus, _mask[i]) == _mask[i] then
					for j, prop in ipairs(_Props) do
						if band(bonus, _PropsIndex[prop]) == _PropsIndex[prop] then
							_Data[i][j] = bor(_Data[i][j], bonus)
						end
					end
				end
			end
		end
	end
end

function BuildProp()
	local dt = _Data[cboColor.Value]

	cboMainProp:Clear()

	cboMainProp:AddItem(0, " ")
	cboMainProp.Value = 0

	if dt then
		for i = 5, #_Props do
			if dt[i] ~= "0" then
				cboMainProp:AddItem(i, _Props[i])
			end
		end
	end
end

function BuildSecProp()
	local dt = _Data[cboColor.Value]

	cboSecProp:Clear()
	cboSecProp:AddItem(0, " ")
	cboSecProp.Value = 0

	if not dt then return end

	local main = cboMainProp.Value
	local value = dt[main]

	if not value or value == "0" then return end

	local prop

	for i = 5, #_Props do
		if i ~= main then
			prop = _Props[i]

			if band(value, _PropsIndex[prop]) == _PropsIndex[prop] then
				cboSecProp:AddItem(i, prop)
			end
		end
	end
end

_FilterBonus = nil

function BuildGemList()
	local color = cboColor.Value
	local main = cboMainProp.Value
	local sec = cboSecProp.Value
	local chkColor
	local go = false

	local bonus = "0"

	local name, link

	if color and color > 0 and color < 5 then
		bonus = bor(bonus, binit(color))
		chkColor = bonus
	end

	if main and main > 4 then
		bonus = bor(bonus, _PropsIndex[_Props[main]])
	else
		return
	end

	if sec and sec > 4 then
		chkColor = nil
		bonus = bor(bonus, _PropsIndex[_Props[sec]])
	end

	if _FilterBonus == bonus then
		return
	end

	lstGem:SuspendLayout()
	lstGem:Clear()

	_FilterBonus = bonus

	for gem, v in pairs(_Gems) do
		if gem ~= 0 then
			go = true

			if chkColor then
				if band(v, BIT_GEM) ~= chkColor then
					go = false
				end
			end

			if go and band(v, bonus) == bonus then
				name, link = GetItemInfo(gem)

				lstGem:AddItem(name, link)
			end
		end
	end
	lstGem:ResumeLayout()
end

function ClearGemData()
	wipe(_Gems)
	wipe(_Props)
	tinsert(_Props, RED_GEM)
	tinsert(_Props, BLUE_GEM)
	tinsert(_Props, YELLOW_GEM)
	tinsert(_Props, META_GEM)

	wipe(_PropsIndex)

	for i, prop in ipairs(_Props) do
		_PropsIndex[prop] = binit(i)
	end

	BuildData()
	cboColor.Text = ""
	cboMainProp:Clear()
	cboSecProp:Clear()
	lstGem:Clear()
end

function BuildGlyphList()
	local player = cboPlayer.Value

	if not player then
		lstGlyph:Clear()
		return
	end

	lstGlyph:SuspendLayout()
	lstGlyph:Clear()

	for name, id in pairs(_Glyph[player]) do
		lstGlyph:AddItem(id, name)
	end

	_GameTooltip:Hide()
	lstGlyph:ResumeLayout()
end