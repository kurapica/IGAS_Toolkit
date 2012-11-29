-------------------------------
-- AutoBuy Designer
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoBuy"

-------------------------------
-- frmAutoBuy
-------------------------------
frmAutoBuy = Form("IGAS_Toolkit_AutoBuy")
frmAutoBuy.Visible = false
frmAutoBuy.Resizable = true
frmAutoBuy.Caption = L["Buy Item"]
frmAutoBuy.Width = 180
frmAutoBuy.Height = 200
frmAutoBuy.ShowCloseButton = false
frmAutoBuy.TitleBarColor = ColorType(1, 0, 0, 1)
frmAutoBuy.Message = L["Click to remove"]
frmAutoBuy.MinResize = Size(180, 200)

-------------------------------
-- lstBuy
-------------------------------
lstBuy = List("BuyList", frmAutoBuy)
lstBuy:SetPoint("TOPLEFT", frmAutoBuy, "TOPLEFT", 0, -22)
lstBuy:SetPoint("BOTTOMRIGHT", frmAutoBuy, "BOTTOMRIGHT", 0, 50)
lstBuy.ShowTootip = true

-------------------------------
-- btnOk
-------------------------------
btnOk = NormalButton("OkBtn", frmAutoBuy)
btnOk:SetPoint("TOPLEFT", lstBuy, "BOTTOMLEFT")
btnOk:SetPoint("BOTTOMLEFT", frmAutoBuy, "BOTTOMLEFT", 0, 25)
btnOk:SetPoint("RIGHT", frmAutoBuy, "CENTER")
btnOk.Style = "CLASSIC"
btnOk.Text = L["Okay"]

-------------------------------
-- btnCancel
-------------------------------
btnCancel = NormalButton("CancelBtn", frmAutoBuy)
btnCancel:SetPoint("TOPRIGHT", lstBuy, "BOTTOMRIGHT")
btnCancel:SetPoint("BOTTOMRIGHT", frmAutoBuy, "BOTTOMRIGHT", 0, 25)
btnCancel:SetPoint("LEFT", frmAutoBuy, "CENTER")
btnCancel.Style = "CLASSIC"
btnCancel.Text = L["Cancel"]