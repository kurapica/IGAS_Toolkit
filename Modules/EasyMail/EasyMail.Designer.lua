-------------------------------
-- EasyMail Designer
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.EasyMail"

_MaxRecent = 10

-- Build MailList
btnDropdown = Button("IGAS_Toolkit_EasyMail_DropdownBtn", SendMailNameEditBox)
btnDropdown:SetWidth(32)
btnDropdown:SetHeight(32)
btnDropdown:SetPoint("LEFT", SendMailNameEditBox, "RIGHT", -6, 0)
btnDropdown:SetNormalTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up.blp")
btnDropdown:SetPushedTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Down.blp")
btnDropdown:SetDisabledTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Disabled.blp")
btnDropdown:SetHighlightTexture("Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Highlight.blp", "ADD")
btnDropdown:SetHitRectInsets(6, 7, 7, 8)
btnDropdown.Visible = false

MailList = DropDownList("IGAS_Toolkit_EasyMail_MailList", btnDropdown)
MailList:SetPoint("TOPLEFT", SendMailNameEditBox, "BOTTOMLEFT", 0, -10)
MailList:SetPoint("TOPRIGHT", SendMailNameEditBox, "BOTTOMRIGHT", 0, -10)
MailList.ShowOnCursor = false

mnuRecent = MailList:AddMenuButton(L["Recent"])
mnuChar = MailList:AddMenuButton(L["Character"])
mnuFriend = MailList:AddMenuButton(L["Friend"])
mnuGuild = MailList:AddMenuButton(L["Guild"])

lstRecent = List("List", mnuRecent)
lstChar = List("List", mnuChar)
lstFriend = List("List", mnuFriend)

lstRecent.Width = 150
lstChar.Width = 150
lstFriend.Width = 150

lstRecent.DisplayItemCount = _MaxRecent
lstChar.DisplayItemCount = _MaxRecent
lstFriend.DisplayItemCount = _MaxRecent

mnuRecent.DropDownList = lstRecent
mnuChar.DropDownList = lstChar
mnuFriend.DropDownList = lstFriend