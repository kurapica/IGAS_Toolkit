IGAS:NewAddon "CVar"

import "System.Widget"

form = Form(_Name)
form:SetSize(400, 460)
form.Caption = "CVar配置"
form.Visible = true

local index = 0

for k, v in pairs(_G.UVARINFO) do
    local chk = CheckBox(k, form)
    if index % 2 ==0 then
        chk:SetPoint("LEFT", 4, 0)
        chk:SetPoint("TOP", 0, -24  - floor(index/2) * 24)
    else
        chk:SetPoint("LEFT", form, "CENTER")
        chk:SetPoint("TOP", 0, -24  - floor(index/2) * 24)
    end

    chk.Text = _G[v.event]
    chk.CVar = v.cvar
    local now = GetCVar(v.cvar)
    chk.Checked = tonumber(now) == 1

    function chk:OnValueChanged()
        SetCVar(self.CVar, chk.Checked and 1 or 0)
    end

    index = index + 1
end