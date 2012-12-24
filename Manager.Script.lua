-------------------------------
-- Manager
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.Manager"

_Addon.OnSlashCmd = _Addon.OnSlashCmd + function(self, ...)
	frmManager.Visible = true
end

function OnLoad(self)
	-- SavedVariables
	if _DBChar.ManagerPosition then
		frmManager.Position = _DBChar.ManagerPosition
	end

	if _DBChar.ManagerSize then
		frmManager.Size = _DBChar.ManagerSize
	end

	_DBChar.ManagerMdlSort = _DBChar.ManagerMdlSort or {}
	_DBChar.ManagerOptionToggle = _DBChar.ManagerOptionToggle or {}

	_ManagerMdlSort = _DBChar.ManagerMdlSort
	_ManagerOptionToggle = _DBChar.ManagerOptionToggle

	-- events
	self:RegisterEvent("PLAYER_REGEN_DISABLED")
	self:RegisterEvent("PLAYER_REGEN_ENABLED")
end

_IsInCombat = false

function PLAYER_REGEN_DISABLED(self)
	_IsInCombat = true
end

function PLAYER_REGEN_ENABLED(self)
	_IsInCombat = false
end

function LoadOption(node, opt, txt)
	if type(txt) == "string" then
		node = node:AddNode{
			Text = _DBChar[opt] and txt or txt..L[" - Stoped"],
			TrueText = txt,
			Option = opt,
			FunctionName = _DBChar[opt] and L["Disable"] or L["Enable"],
		}
	elseif type(txt) == "table" then
		local subNode = node:AddNode{
			Text = _DBChar[opt] and txt[1] or txt[1]..L[" - Stoped"],
			TrueText = txt[1],
			Option = opt,
			FunctionName = _DBChar[opt] and L["Disable"] or L["Enable"],
		}
		for option, text in pairs(txt) do
			if type(option) == "string" then
				LoadOption(subNode, option, text)
			end
		end
		subNode.ToggleState = _ManagerOptionToggle[subNode.MetaData.Option]
	end
end

function frmManager:OnPositionChanged()
	_DBChar.ManagerPosition = self.Position
end

function frmManager:OnSizeChanged()
	_DBChar.ManagerSize = self.Size
end

function frmManager:OnShow()
	tabManager:SelectWidget(1)

	if mdlTree.ChildNodeCount == 0 and disTree.ChildNodeCount == 0 then
		local lst = _Addon:GetModules()
		local mdl

		mdlTree:SuspendLayout()
		disTree:SuspendLayout()

		for i = 1, #lst do
			if lst[i] ~= _M then
				lst[lst[i]._Name] = true
			end
			lst[i] = nil
		end

		for i = #_ManagerMdlSort, 1, -1 do
			if not lst[_ManagerMdlSort[i]] then
				tremove(_ManagerMdlSort, i)
			else
				lst[_ManagerMdlSort[i]] = nil
			end
		end

		for name in pairs(lst) do
			if not _DiscardModule[name] then
				tinsert(_ManagerMdlSort, name)
				lst[name] = nil
			end
		end

		for _, name in ipairs(_ManagerMdlSort) do
			mdl = _Addon:GetModule(name)

			local node = mdlTree:AddNode{
				Text =  _DisabledModule[name] and L[name]..L[" - Stoped"] or L[name],
				TrueText = L[name],
				Module = mdl,
				FunctionName = (_DisabledModule[name] and L["Enable"] or L["Disable"]) .. "," .. L["Discard"],
			}

			if type(mdl.Options) == "table" then
				for opt, txt in pairs(mdl.Options) do
					LoadOption(node, opt, txt)
				end
			end

			node.ToggleState = _ManagerOptionToggle[name]
		end

		for name in pairs(lst) do
			mdl = _Addon:GetModule(name)

			local node = disTree:AddNode{
				Text =  L[name],
				Module = mdl,
				FunctionName = L["Enable"],
			}
		end

		mdlTree:ResumeLayout()
		disTree:ResumeLayout()

		wipe(_ManagerMdlSort)

		for i = 1, mdlTree.ChildNodeCount do
			_ManagerMdlSort[i] = mdlTree:GetNode(i).MetaData.Module._Name
		end
	end
end

function mdlTree:OnNodeFunctionClick(func, node)
	if func == L["Enable"] then
		if node.Level == 1 then
			node.MetaData.Module._Enabled = true
			node.Text = node.MetaData.TrueText
			node.FunctionName = L["Disable"] .. "," .. L["Discard"]
		else
			_DBChar[node.MetaData.Option] = true
			node.Text = node.MetaData.TrueText
			node.FunctionName = L["Disable"]
		end
	elseif func == L["Disable"] then
		if node.Level == 1 then
			node.MetaData.Module._Enabled = false
			node.Text = node.MetaData.TrueText .. L[" - Stoped"]
			node.FunctionName = L["Enable"] .. "," .. L["Discard"]
		else
			_DBChar[node.MetaData.Option] = false
			node.Text = node.MetaData.TrueText .. L[" - Stoped"]
			node.FunctionName = L["Enable"]
		end
	elseif func == L["Discard"] then
		local mdl = node.MetaData.Module
		mdl._Enabled = false
		node:Dispose()

		wipe(_ManagerMdlSort)

		for i = 1, mdlTree.ChildNodeCount do
			_ManagerMdlSort[i] = mdlTree:GetNode(i).MetaData.Module._Name
		end

		_DiscardModule[mdl._Name] = true

		-- add to disTree
		disTree:AddNode{
			Text =  L[mdl._Name],
			Module = mdl,
			FunctionName = L["Enable"],
		}
	end
end

function disTree:OnNodeFunctionClick(func, node)
	if func == L["Enable"] then
		local mdl = node.MetaData.Module
		local name = mdl._Name
		mdl._Enabled = true

		node:Dispose()
		_DiscardModule[name] = nil

		node = mdlTree:AddNode{
			Text =  _DisabledModule[name] and L[name]..L[" - Stoped"] or L[name],
			TrueText = L[name],
			Module = mdl,
			FunctionName = (_DisabledModule[name] and L["Enable"] or L["Disable"]) .. "," .. L["Discard"],
		}

		if type(mdl.Options) == "table" then
			for opt, txt in pairs(mdl.Options) do
				LoadOption(node, opt, txt)
			end
		end

		node.ToggleState = _ManagerOptionToggle[name]


		wipe(_ManagerMdlSort)

		for i = 1, mdlTree.ChildNodeCount do
			_ManagerMdlSort[i] = mdlTree:GetNode(i).MetaData.Module._Name
		end
	end
end

function mdlTree:OnNodeToggle(node)
	if node.Level == 1 then
		_ManagerOptionToggle[node.MetaData.Module._Name] = node.ToggleState or nil
	else
		_ManagerOptionToggle[node.MetaData.Option] = node.ToggleState or nil
	end
end

function mdlTree:OnNodeIndexChanged(node)
	_ManagerMdlSort[node.Index] = node.MetaData.Module._Name
end
