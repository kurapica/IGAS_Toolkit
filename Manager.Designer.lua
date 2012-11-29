-------------------------------
-- Manager
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.Manager"

import "System.Widget"

frmManager = Form("IGAS_Toolkit_Manager")

frmManager.Height = 300
frmManager.Width = 400
frmManager.Caption = L["Toolkit Manager"]
frmManager.Visible = false
frmManager.MinResize = Size(200, 300)
frmManager.DockMode = true

tabManager = TabLayoutPanel("TabManager", frmManager)
tabManager:SetPoint("TOPLEFT", 4, -23)
tabManager:SetPoint("BOTTOMRIGHT", -4, 23)

mdlTree = TreeView("ModuleTree", tabManager)
tabManager:AddWidget(mdlTree, L["Using"])
mdlTree.Style = "SMOOTH"
mdlTree.ChildOrderChangable = true

disTree = TreeView("DiscardTree", tabManager)
tabManager:AddWidget(disTree, L["Discard"])
disTree.Style = "SMOOTH"