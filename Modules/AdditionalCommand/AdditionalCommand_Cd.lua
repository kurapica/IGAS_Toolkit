-------------------------------
-- AdditionalCommand_Cd
-------------------------------
IGAS:NewAddon "IGAS_Toolkit.AdditionalCommand.Cd"

Options.AdditionalCommandCd = L["/cd(cooldown) skill cmd"]

-- OnLoad
function OnLoad(self)	
	self:AddSlashCmd("/cd", "/cooldown")
	self:ActiveThread("OnSlashCmd")
end

function OnSlashCmd(self, option, info)
	if not _Parent._Enabled or not _DBChar.AdditionalCommandCd then return end

	if not option or not info or not GetSpellInfo(option) then return end

	local _, event, unitID, spell, target, slineID, elineID, castingTime, prevSpell, endTime, casted, plineID
	local targetName = GetUnitName("target")
	local focusName = GetUnitName("focus")

	_, _, _, _, _, _, castingTime = GetSpellInfo(option)
	castingTime = castingTime or 0
	casted = false

	local startTime = GetTime() + _WAIT_TIME

	prevSpell, _, _, _, _, endTime, _, plineID = UnitCastingInfo("player")

	-- Another spell is casting
	if prevSpell then
		Log(1, "[AdditionalCommand_Cs] %s will end at %.1f.", prevSpell, endTime / 1000)
		startTime = endTime / 1000 + _WAIT_TIME
	end

	-- Wait start casting the spell
	while true do
		if castingTime > 0 then
			-- non-instant spell
			event, unitID, spell, _, target, slineID = Threading.Wait(startTime - GetTime(), "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_START")

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
			elseif event == "UNIT_SPELLCAST_SENT" then
				if spell == option then
					-- okay, go on
					break
				else
					-- we got another spell casted
					return
				end
			elseif event == "UNIT_SPELLCAST_START" then
				if spell == option then
					-- okay, go on
					target, slineID = nil, target
					break
				else
					-- we got another spell casted
					return
				end
			end
		else
			-- instant spell
			event, unitID, spell, _, target, slineID = Threading.Wait(startTime - GetTime(), "UNIT_SPELLCAST_SENT", "UNIT_SPELLCAST_SUCCEEDED")

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
			elseif event == "UNIT_SPELLCAST_SENT" then
				if spell == option then
					-- okay, go on
					break
				else
					-- we got another spell casted
					return
				end
			elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
				if spell == prevSpell then
					-- well the prev spell is done, continue wait, do nothing
					-- since the prev spell must have cast time, so can't be the option spell
				elseif spell == option then
					-- okay, go on
					target, slineID = nil, target
					casted = true
					break
				else
					-- we got another spell casted
					return
				end
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
	
	if not casted then
		startTime = GetTime() + _WAIT_TIME + castingTime

		while GetTime() < startTime do
			event, unitID, spell, _, elineID = Threading.Wait(startTime - GetTime(), "UNIT_SPELLCAST_SUCCEEDED")

			if not event then
				if UnitCastingInfo("player") == option then
					-- no matter the spell is prev or now, just continue to wait
					startTime = GetTime() + _WAIT_TIME
				else
					return
				end
			elseif unitID ~= "player" then
				-- do nothing, continue wait
			elseif spell == prevSpell and elineID == plineID then
				-- do nothing continue wait
			elseif spell == option and slineID == elineID then
				casted = true
				break
			else
				return
			end
		end
	end
	
	if not casted then return end
	
	Threading.WaitEvent("SPELL_UPDATE_COOLDOWN")	
	
	local start, duration = GetSpellCooldown(option)

	if start > 0 and duration > _GLOBAL_COOLDOWN then
		local orinDura = duration
		
		Log(1, "[AdditionalCommand]Call '%s' after %f.", info, duration)
	
		while GetTime() < start + duration do	
			Threading.Wait(start + duration - GetTime(), "SPELL_UPDATE_COOLDOWN")
			
			start, duration = GetSpellCooldown(option)
			
			if duration < orinDura then			
				-- do the cmd
				return DoTheCmd(info)
			end
		end
		
		while true do
			Threading.Sleep(0.1)			
			
			start, duration = GetSpellCooldown(option)
			
			if duration < orinDura then			
				-- do the cmd
				return DoTheCmd(info)
			end		
		end
	end
end
