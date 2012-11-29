-------------------------------
-- WorldMapScale
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.WorldMapScale"

import "System"

_Scale = 1
_HiddenTime = 3

_Frame = {
	WorldMapFrameMiniBorderLeft,
	WorldMapFrameMiniBorderRight,
	WorldMapFrameTitle,
	WorldMapFrameSizeUpButton,
	WorldMapFrameCloseButton,
	WorldMapTrackQuest,
	WorldMapQuestShowObjectives,
	WorldMapShowDigSites,
}

_Timer = System.Widget.Timer("AlphaTimer", WorldMapFrame)
_Timer.Enabled = false
_Timer.Interval = 1

-- OnLoad
function OnLoad(self)
	-- SavedVariables
	_DBChar.WorldMapScale = _DBChar.WorldMapScale or {}
	_Scale = _DBChar.WorldMapScale.Scale or 1

	-- Addon's enable state
	_Enabled = not _DisabledModule[_Name]

	-- Event
	self:RegisterEvent"PLAYER_LOGOUT"
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil

	_Addon:SecureHook("WorldMap_ToggleSizeDown", function(self)
	    WorldMapFrame.Scale = _M._Scale
	end)
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
end

function PLAYER_LOGOUT(self)
	_DBChar.WorldMapScale.Scale = _M._Scale
end

_Addon:SecureHook("WorldMap_ToggleSizeDown", function(self)
    WorldMapFrame.Scale = _M._Scale
    _Timer.Enabled = true
end)

function IsMouseInWorldMap()
    local l, b, w, h = WorldMapFrame:GetRect()
    local e = WorldMapFrame:GetEffectiveScale()
    local x, y

    x, y = GetCursorPosition()
    x, y = x / e, y /e

    if x > l and x < l + w and y > b and y < b + h then
    	return true
    end
end

function WorldMapButton:OnEnter()
	for _, f in ipairs(_Frame) do
		f.Alpha = 1
	end
end

function WorldMapButton:OnLeave()
	if ( GetCVarBool("miniWorldMap") ) then
		_Timer.Enabled = true
	end
end

function _Timer:OnTimer()
	if IsMouseInWorldMap() then
		self._Final = self._Final and (self._Final + 1) or _HiddenTime
	else
		self._Final = self._Final and (self._Final - 1) or _HiddenTime
	end

	if self._Final < 0 then
		self._Final = nil
		for _, f in ipairs(_Frame) do
			f.Alpha = 0
		end
		self.Enabled = false
	end
end

function WorldMapButton:OnMouseDown()
	if not GetCVarBool("miniWorldMap") then return end
    if not InCombatLockdown() and IsAltKeyDown() then
        local l, b, w, h = self:GetRect()
        local e = self:GetEffectiveScale()
        local x, y


        x, y = GetCursorPosition()
        x, y = x / e, y /e

        if x > l + w * 9 / 10 and x < l + w and y > b and y < b + h * 1 / 10 then
            return WorldMapFrame:ThreadCall(function(self)
                local l, b, w, h = self:GetRect()
                local e = self:GetEffectiveScale()
                local x, y, rx, ry

                while IsMouseButtonDown("LeftButton") and not InCombatLockdown() do
                    Threading.Sleep(0.1)

                    x, y = GetCursorPosition()
                    x, y = x / e, y /e

                    rx = (x - l)/w
                    ry = (b + h - y)/h

                    self.Scale = max(rx, ry)
                    _M._Scale = self.Scale
                end
            end)
        end
    end
end