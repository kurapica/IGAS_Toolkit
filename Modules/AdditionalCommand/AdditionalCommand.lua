-------------------------------
-- AdditionalCommand
-------------------------------
IGAS:NewAddon "IGAS_Toolkit.AdditionalCommand"

import "System.Threading"

Options = {
}

_WAIT_TIME = 1
_GLOBAL_COOLDOWN = 1.5

-- OnLoad
function OnLoad(self)
	_Enabled = not _DisabledModule[_Name]
	
	local i = 1
	
	while _G["ChatFrame"..i] do
		-- Well, use the last chatframe for command
		MyChatFrame = _G["ChatFrame"..i]
		i = i + 1
	end	
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true	
end

function DoTheCmd(info)
	if not info then return end

	if info:sub(1, 1) == "/" then
		MyChatFrame.editBox:SetText(info)
	else
		MyChatFrame.editBox:SetText("/"..info)
	end
	ChatEdit_SendText(MyChatFrame.editBox)
	MyChatFrame.editBox:SetText("")
end