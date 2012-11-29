-------------------------------
-- AutoRepair
-------------------------------

IGAS:NewAddon "IGAS_Toolkit.AutoRepair"

COPPER_PER_SILVER = COPPER_PER_SILVER
SILVER_PER_GOLD = SILVER_PER_GOLD

Options = {
	AutoRepairNeedReputation = L["Check Reputation"],
}

_Rep = nil

-- OnLoad
function OnLoad(self)
	_Enabled = not _DisabledModule[_Name]
	self:RegisterEvent("MERCHANT_SHOW")
end

-- OnEnable
function OnEnable(self)
	_DisabledModule[_Name] = nil	
end

-- OnDisable
function OnDisable(self)
	_DisabledModule[_Name] = true
end	

-- MERCHANT_SHOW
function MERCHANT_SHOW(self)
	if _DBChar.AutoRepairNeedReputation and UnitReaction("target", "player") < 8 then
		return Log(1, "[AutoRepair] Reputation check failed.")			
	end
	
	local repairByGuild = false
	
	if not CanMerchantRepair() then return end

	repairAllCost, canRepair = GetRepairAllCost()

	if repairAllCost == 0 or not canRepair then return end
	
	--See if can guildbank repair
	if CanGuildBankRepair() then

		guildName, _, guildRankIndex = GetGuildInfo("player")

		GuildControlSetRank(guildRankIndex)
		
		if GetGuildBankWithdrawGoldLimit()*10000 >= repairAllCost then
			repairByGuild = true
			RepairAllItems(1)
		else
			if repairAllCost > GetMoney() then
				return Log(3, L["[AutoRepair] No enough money to repair."])
			end
		
			RepairAllItems()
		end
		PlaySound("ITEM_REPAIR")
	else
		if repairAllCost > GetMoney() then
			return Log(3, L["[AutoRepair] No enough money to repair."])
		end
			
		RepairAllItems()
		PlaySound("ITEM_REPAIR")
	end
	
	Log(2, "-----------------------------")
	if repairByGuild then
		Log(2, L["[AutoRepair] Cost [Guild] %s."], FormatMoney(repairAllCost))
	else
		Log(2, L["[AutoRepair] Cost %s."], FormatMoney(repairAllCost))
	end
end
