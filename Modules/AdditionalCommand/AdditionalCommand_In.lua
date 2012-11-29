-------------------------------
-- AdditionalCommand_In
-------------------------------
IGAS:NewAddon "IGAS_Toolkit.AdditionalCommand.In"

Options.AdditionalCommandIn = L["/in(after) x cmd"]

-- OnLoad
function OnLoad(self)
	self:AddSlashCmd("/in", "/after")
	self:ActiveThread("OnSlashCmd")
end

function OnSlashCmd(self, option, info)
	if not _Parent._Enabled or not _DBChar.AdditionalCommandIn then return end

	option = tonumber(option)
	if not option or option < 0.1 then return end

    if not info or strtrim(info) == "" then return end

	if info:find("%%t") then
		local name = GetUnitName("target") or TARGET_TOKEN_NOT_FOUND

		info = info:gsub("%%t", name)
	end

	if info:find("%%f") then
		local name = GetUnitName("focus") or TARGET_TOKEN_NOT_FOUND

		info = info:gsub("%%f", name)
	end

	Log(1, "[AdditionalCommand]Call '%s' after %f sec.", info, option)

    Threading.Sleep(tonumber(option))

	return DoTheCmd(info)
end
