-------------------------------
-- AuctionHelper Designer
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AuctionHelper"

function Initialization()
	-- History List
	btnDropdown = Button("IGAS_Toolkit_AuctionHelper_DropdownBtn", BrowseName)
	btnDropdown:SetWidth(32)
	btnDropdown:SetHeight(32)
	btnDropdown:SetPoint("RIGHT", BrowseName, "RIGHT", 6, -1)
	btnDropdown:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up.blp")
	btnDropdown:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down.blp")
	btnDropdown:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled.blp")
	btnDropdown:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight.blp", "ADD")
	btnDropdown:SetHitRectInsets(6, 7, 7, 8)

	HistoryList = List("lstHistory", btnDropdown)
	HistoryList:SetPoint("TOPLEFT", BrowseName, "BOTTOMLEFT", 0, -2)
	HistoryList:SetPoint("TOPRIGHT", BrowseName, "BOTTOMRIGHT", 0, -2)
	HistoryList.Visible = false
	HistoryList.ShowTootip = true
	HistoryList.DisplayItemCount = DISPLAY_HISTORY
	HistoryList.Items = _Items

	HideTimer = Timer("CheckHide", HistoryList)
	HideTimer.Enabled = false
	HideTimer.Interval = 2

	-- Gem Helper
	frmGemHelper = Form("IGAS_Toolkit_AuctionHelper_GemHelper", AuctionFrame)

	frmGemHelper:SetPoint("TOPLEFT", frmGemHelper.Parent, "TOPRIGHT", 0, -10)
	frmGemHelper.Caption = L["Gem Helper"]
	frmGemHelper.MinResize = System.Widget.Size(200, 350)
	frmGemHelper.Resizable = true
	frmGemHelper.Width = 200
	frmGemHelper.Height = 350
	frmGemHelper.Visible = false
	frmGemHelper.ShowCloseButton = false
	frmGemHelper:ActiveThread("OnShow")

	btnClear = NormalButton("Clear", frmGemHelper)
	btnClear:SetPoint("BOTTOMLEFT", 30, 10)
	btnClear:SetPoint("RIGHT", -30, 0)
	btnClear.Height = 24
	btnClear.Style = "Classic"
	btnClear.Text = L["Clear"]

	btnScan = NormalButton("Scan", frmGemHelper)
	btnScan:SetPoint("BOTTOMLEFT", btnClear, "TOPLEFT", 0, 0)
	btnScan:SetPoint("RIGHT", -30, 0)
	btnScan.Height = 24
	btnScan.Style = "Classic"
	btnScan.Text = L["Scan"]
	btnScan:ActiveThread("OnClick")

	cboColor = ComboBox("Color", frmGemHelper)
	cboColor:SetPoint("TOPLEFT", 10, -36)
	cboColor:SetPoint("RIGHT", -10, 0)
	cboColor.Editable = false
	cboColor:SetList{
		RED_GEM,
		BLUE_GEM,
		YELLOW_GEM,
		META_GEM
	}

	cboMainProp = ComboBox("MainProp", frmGemHelper)
	cboMainProp:SetPoint("TOPLEFT", cboColor, "BOTTOMLEFT", 0, -4)
	cboMainProp:SetPoint("RIGHT", -10, 0)
	cboMainProp.Editable = false

	cboSecProp = ComboBox("SecProp", frmGemHelper)
	cboSecProp:SetPoint("TOPLEFT", cboMainProp, "BOTTOMLEFT", 0, -4)
	cboSecProp:SetPoint("RIGHT", -10, 0)
	cboSecProp.Editable = false

	lstGem = List("Gems", frmGemHelper)
	lstGem:SetPoint("TOPLEFT", cboSecProp, "BOTTOMLEFT", 0, -4)
	lstGem:SetPoint("RIGHT", -10, 0)
	lstGem:SetPoint("BOTTOM", btnScan, "TOP", 0, 8)
	lstGem.ShowTootip = true

	-- Glyph Helper
	frmGlyphHelper = Form("IGAS_Toolkit_AuctionHelper_GlyphHelper", AuctionFrame)

	frmGlyphHelper:SetPoint("TOPLEFT", frmGlyphHelper.Parent, "TOPRIGHT", 0, -10)
	frmGlyphHelper.Caption = L["Glyph Helper"]
	frmGlyphHelper.MinResize = System.Widget.Size(200, 350)
	frmGlyphHelper.Resizable = true
	frmGlyphHelper.Width = 200
	frmGlyphHelper.Height = 350
	frmGlyphHelper.Visible = false
	frmGlyphHelper.ShowCloseButton = false
	frmGlyphHelper:ActiveThread("OnShow")

	btnReset = NormalButton("btnReset", frmGlyphHelper)
	btnReset:SetPoint("BOTTOMLEFT", 30, 10)
	btnReset:SetPoint("RIGHT", -30, 0)
	btnReset.Height = 24
	btnReset.Style = "Classic"
	btnReset.Text = L["Reset"]

	cboPlayer = ComboBox("Player", frmGlyphHelper)
	cboPlayer:SetPoint("TOPLEFT", 10, -36)
	cboPlayer:SetPoint("RIGHT", -10, 0)
	cboPlayer.Editable = false
	for player, dt in pairs(_Glyph) do
		if next(dt) then
			cboPlayer:AddItem(player, player)
		end
	end

	lstGlyph = List("Glyphs", frmGlyphHelper)
	lstGlyph:SetPoint("TOPLEFT", cboPlayer, "BOTTOMLEFT", 0, -4)
	lstGlyph:SetPoint("RIGHT", -10, 0)
	lstGlyph:SetPoint("BOTTOM", btnReset, "TOP", 0, 8)
	lstGlyph.ShowTootip = true

	-- Script Handlers
	function frmGemHelper:OnShow()
		if not next(_Gems) then
			if IGAS:MsgBox(L["It's the first time you using the gem helper, \n do you want to scan now?"], "c") then
				return btnScan:OnClick()
			end
		end
	end

	function btnDropdown:OnHide()
		HistoryList.Visible = false
	end

	function btnDropdown:OnClick()
		HistoryList.Visible = not HistoryList.Visible
	end

	function AuctionFrame:OnShow()
		if _Enabled and _DBChar.AuctionHelperHistory then
			btnDropdown.Visible = true
		else
			btnDropdown.Visible = false
		end
	end

	function btnScan:OnClick()
		return ScanGem()
	end

	function btnClear:OnClick()
		return ClearGemData()
	end

	function cboColor:OnValueChanged(value)
		BuildProp()
		BuildGemList()
	end

	function cboMainProp:OnValueChanged(value)
		BuildSecProp()
		BuildGemList()
	end

	function cboSecProp:OnValueChanged(value)
		BuildGemList()
	end

	function lstGem:OnItemChoosed(key, text)
		AuctionFrameBrowse_Reset(BrowseResetButton)
		BrowseName:SetText(key)
		AuctionFrameBrowse_Search()
	end

	function lstGem:OnGameTooltipShow(GameTooltip, key, text)
		GameTooltip:ClearLines()
		GameTooltip:SetHyperlink(text)
	end

	function HistoryList:OnItemChoosed(key, text)
		AuctionFrameBrowse_Reset(BrowseResetButton)
		BrowseName:SetText(GetItemInfo(text))
		AuctionFrameBrowse_Search()
		HistoryList:Hide()
	end

	function HistoryList:OnGameTooltipShow(GameTooltip, key, text)
		GameTooltip:ClearLines()
		GameTooltip:SetHyperlink(text)
	end

	function HistoryList:OnShow()
		HideTimer.Enabled = true
	end

	function HistoryList:OnHide()
		HideTimer.Enabled = false
	end

	function HistoryList:OnEnter()
		HideTimer.Enabled = false
	end

	function HistoryList:OnLeave()
		HideTimer.Enabled = true
	end

	function HideTimer:OnTimer()
		HistoryList:Hide()
	end

	function frmGlyphHelper:OnShow()
		BuildGlyphList()
	end

	function btnReset:OnClick()
		if not _Glyph[_Player] then return end

		wipe(_Glyph[_Player])

		USE_GLYPH(self)

		wipe(_TempGlyph)

		for _, dt in pairs(_Glyph) do
			for name, id in pairs(dt) do
				_TempGlyph[name] = id
			end
		end

		BuildGlyphList()
	end

	function cboPlayer:OnValueChanged(value)
		BuildGlyphList()
	end

	function lstGlyph:OnItemChoosed(key, text)
		AuctionFrameBrowse_Reset(BrowseResetButton)
		BrowseName:SetText(text)
		AuctionFrameBrowse_Search()
	end

	function lstGlyph:OnGameTooltipShow(GameTooltip, key, text)
		GameTooltip:ClearLines()
		GameTooltip:SetGlyphByID(key)
	end

	-- Init
	cboPlayer.Value = _Player
end
