----------------------------------------------
-- Addon Initialize
----------------------------------------------
IGAS:NewAddon "IGAS_Toolkit"

import "System"
import "System.Widget"

----------------------------------------------
-- Localization
----------------------------------------------
L = IGAS:NewLocale("IGAS_Toolkit")

----------------------------------------------
-- Looger
----------------------------------------------
Log = IGAS:NewLogger("IGAS_Toolkit")

Log.LogLevel = 2

Log:SetPrefix(1, System.Widget.FontColor.GRAY .. _Name ..": ")
Log:SetPrefix(2, System.Widget.FontColor.HIGHLIGHT .. _Name ..": ")
Log:SetPrefix(3, System.Widget.FontColor.RED .. _Name ..": ")

Log:AddHandler(print)

----------------------------------------------
-- SavedVariables
----------------------------------------------
function OnLoad(self)
	_DB = self:AddSavedVariable("IGAS_Toolkit_DB")
	_DBChar = self:AddSavedVariable("IGAS_Toolkit_DB_Char")
	
	-- Module's enable settings
	_DBChar.DisabledModule = _DBChar.DisabledModule or {}
	_DBChar.DiscardModule = _DBChar.DiscardModule or {}
	_DisabledModule = _DBChar.DisabledModule
	_DiscardModule = _DBChar.DiscardModule
	
	-- Log Level
	if type(_DB.LogLevel) == "number" then
		Log.LogLevel = _DB.LogLevel
	end
	
	-- Slash command
	self:AddSlashCmd("/igastool", "/it")
end

_Addon.OnSlashCmd = _Addon.OnSlashCmd + function(self, option, info)
	if option and option:lower() == "log" and tonumber(info) then
		Log.LogLevel = tonumber(info)
		_DB.LogLevel = Log.LogLevel
		
		Log(3, "%s's LogLevel is switched to %d.", _Name, Log.LogLevel)
		
		return true
	end
end

function FormatMoney(money)
	if money > 10000 then
		return (GOLD_AMOUNT_TEXTURE.." "..SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE):format(math.floor(money / 10000), 0, 0, math.floor(money % 10000 / 100), 0, 0, money % 100, 0, 0)
	elseif money > 100 then
		return (SILVER_AMOUNT_TEXTURE.." "..COPPER_AMOUNT_TEXTURE):format(math.floor(money % 10000 / 100), 0, 0, money % 100, 0, 0)
	else
		return (COPPER_AMOUNT_TEXTURE):format(money % 100, 0, 0)
	end
end

function n2b(val)
	local str = ""

	while val > 0 do
		str = tostring(val % 2) .. str
		val = math.floor(val / 2)
	end

	return ("0"):rep(8 - str:len()) .. str
end

function b2n(str)
	local v = 0
	
	for i=1, str:len() do
		v = v * 2 + tonumber(str:sub(i,i))
	end
	
	return v
end