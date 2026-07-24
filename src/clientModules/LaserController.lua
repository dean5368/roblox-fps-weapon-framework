
local LaserController = {}
LaserController.__index = LaserController

local LASER_PRIORITY = {
	"HP_Laser", -- replicated/high powered priority
	"LP_Laser", -- local-only handled by Client WeaponFX/server relay rules
}

local function toBool(v)
	if typeof(v) == "boolean" then return v end
	if typeof(v) == "number" then return v ~= 0 end
	if typeof(v) == "string" then
		v = v:lower()
		return v == "true" or v == "1" or v == "yes" or v == "on"
	end
	return false
end

function LaserController.new(config)
	local self = setmetatable({}, LaserController)

	self.Tool = config.Tool
	self.Upgrades = config.Upgrades
	self.SettingsModule = config.SettingsModule
	self.ToggleLaser = config.ToggleLaser

	self.Enabled = false
	self.ActiveType = nil

	return self
end

function LaserController:IsUpgradeEnabled(laserType)
	local upgrades = self.Upgrades
	local v = upgrades and upgrades:FindFirstChild(laserType)

	if v and v:IsA("ValueBase") then
		return toBool(v.Value)
	end

	return false
end

function LaserController:GetActiveType()
	local settings = require(self.SettingsModule)
	local upgradeSettings = settings.Upgrades

	if not upgradeSettings then
		return nil
	end

	for _, laserType in ipairs(LASER_PRIORITY) do
		if self:IsUpgradeEnabled(laserType) and upgradeSettings[laserType] then
			return laserType
		end
	end

	return nil
end

function LaserController:GetSettings(laserType)
	local settings = require(self.SettingsModule)
	laserType = laserType or self:GetActiveType()

	if settings.Upgrades and laserType then
		return settings.Upgrades[laserType]
	end

	return nil
end

function LaserController:GetToggleKey(laserType)
	local laserSettings = self:GetSettings(laserType)

	if laserSettings and laserSettings.ToggleKey then
		return laserSettings.ToggleKey
	end

	return Enum.KeyCode.X
end

function LaserController:SetEnabled(state, laserType)
	state = state == true

	if state then
		laserType = laserType or self:GetActiveType()
		if not laserType then
			self.Enabled = false
			self.ActiveType = nil
			return false, nil
		end

		self.Enabled = true
		self.ActiveType = laserType
	else
		laserType = laserType or self.ActiveType or self:GetActiveType()
		self.Enabled = false
		self.ActiveType = nil
	end

	pcall(function()
		self.ToggleLaser:FireServer(self.Tool, self.Enabled, laserType)
	end)

	return self.Enabled, laserType
end

function LaserController:HandleInput(keyCode, equipped)
	local activeType = self:GetActiveType()
	local laserSettings = self:GetSettings(activeType)

	if not laserSettings then
		return false, self.Enabled, activeType
	end

	if keyCode ~= self:GetToggleKey(activeType) then
		return false, self.Enabled, activeType
	end

	if not equipped then
		return true, self.Enabled, activeType
	end

	if not activeType then
		self:SetEnabled(false)
		return true, false, nil
	end

	local enabled, laserType = self:SetEnabled(not self.Enabled, activeType)
	return true, enabled, laserType
end

function LaserController:Disable()
	return self:SetEnabled(false)
end

function LaserController:Destroy()
	return self:SetEnabled(false)
end

return LaserController
