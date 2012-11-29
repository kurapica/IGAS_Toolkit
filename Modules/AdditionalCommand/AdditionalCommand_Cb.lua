-------------------------------
-- AdditionalCommand_Cb
-------------------------------
IGAS:NewAddon "IGAS_Toolkit.AdditionalCommand.Cb"

Options.AdditionalCommandCb = L["/cb(cbegin) skill cmd"]

-- OnLoad
function OnLoad(self)
	self:AddSlashCmd("/cb", "/cbegin")
	self:ActiveThread("OnSlashCmd")
end

function OnSlashCmd(self, option, info)
	if not _Parent._Enabled or not _DBChar.AdditionalCommandCb then return end

	if not option or not info or not GetSpellInfo(option) then return end

	local _, event, unitID, spell, target, slineID, elineID, castingTime, prevSpell, endTime, plineID
	local targetName = GetUnitName("target")
	local focusName = GetUnitName("focus")

	_, _, _, _, _, _, castingTime = GetSpellInfo(option)
	castingTime = castingTime or 0
	
	if castingTime <= 0 then return end

	local startTime = GetTime() + _WAIT_TIME

	prevSpell, _, _, _, _, endTime, _, plineID = UnitCastingInfo("player")

	-- Another spell is casting
	if prevSpell then
		Log(1, "[AdditionalCommand_Cs] %s will end at %.1f.", prevSpell, endTime / 1000)
		startTime = endTime / 1000 + _WAIT_TIME
	end

	-- Wait start casting the spell
	while true do
		-- non-instant spell
		event, unitID, spell, _, slineID = Threading.Wait(startTime - GetTime(), "UNIT_SPELLCAST_START")

		if not event then
			-- meet the end time
			if SpellIsTargeting() and IsCurrentSpell(option) then
				-- the spell is waiting select an area, continue wait
				startTime = GetTime() + _WAIT_TIME
			else
				return
			end
		elseif unitID ~= "player" then
			-- continue wait, do nothing
		elseif event == "UNIT_SPELLCAST_START" then
			if spell == option then
				-- okay, go on
				break
			else
				-- we got another spell casted
				return
			end
		end
	end

	-- replace %t, %f to the true target
	if info:find("%%t") then
		local name = target or targetName or TARGET_TOKEN_NOT_FOUND

		info = info:gsub("%%t", name)
	end

	if info:find("%%f") then
		local name = target or focusName or TARGET_TOKEN_NOT_FOUND

		info = info:gsub("%%f", name)
	end

	-- do the cmd
	return DoTheCmd(info)
end
