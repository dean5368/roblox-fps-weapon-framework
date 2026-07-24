--// GunUpgradeController.lua
--// Put this ModuleScript in ReplicatedStorage.ClientModules
--// Centralizes upgrade/value checks and aiming profile selection for GunClient.

local GunUpgradeController = {}
GunUpgradeController.__index = GunUpgradeController

function GunUpgradeController.new(ctx)
	ctx = ctx or {}
	local self = setmetatable({}, GunUpgradeController)
	self.SettingsModule = ctx.SettingsModule
	self.Upgrades = ctx.Upgrades
	return self
end

function GunUpgradeController:_settings()
	return require(self.SettingsModule)
end

function GunUpgradeController:ToBool(v)
	if typeof(v) == "boolean" then return v end
	if typeof(v) == "number" then return v ~= 0 end
	if typeof(v) == "string" then
		v = v:lower()
		return (v == "true" or v == "1" or v == "yes" or v == "on")
	end
	return false
end

function GunUpgradeController:IsEnabled(name)
	if not self.Upgrades then return false end
	local v = self.Upgrades:FindFirstChild(name)
	if v and v:IsA("ValueBase") then
		return self:ToBool(v.Value)
	end
	return false
end

function GunUpgradeController:IsHoloEnabled()
	return self:IsEnabled("Holo")
end

function GunUpgradeController:IsOperatorSightEnabled()
	return self:IsEnabled("OperatorSight")
end

function GunUpgradeController:IsReflexEnabled()
	return self:IsEnabled("Reflex")
end

function GunUpgradeController:IsKobraSightEnabled()
	return self:IsEnabled("KobraSight")
end

function GunUpgradeController:IsReflexScopeEnabled()
	return self:IsEnabled("ReflexScope")
end

function GunUpgradeController:IsVertGripEnabled()
	return self:IsEnabled("VertGrip")
end

function GunUpgradeController:IsAngledGripEnabled()
	return self:IsEnabled("AngledGrip")
end

function GunUpgradeController:IsCollapsedStockEnabled()
	return self:IsEnabled("CollapsedStock")
end

function GunUpgradeController:IsACOGEnabled()
	return self:IsEnabled("ACOG")
end

function GunUpgradeController:IsGrenadeLauncherEnabled()
	return self:IsEnabled("GrenadeLauncher")
end

function GunUpgradeController:GetCollapsedStockSettings()
	if not self:IsCollapsedStockEnabled() then
		return nil
	end

	local settings = self:_settings()
	return settings.Upgrades and settings.Upgrades.CollapsedStock
end

function GunUpgradeController:GetActiveAimingProfile()
	local settings = self:_settings()
	local baseAiming = settings.Aiming or {}
	local basePos = baseAiming.Position or CFrame.new()
	local upgradesSettings = settings.Upgrades or {}

	-- Priority: ReflexScope > Reflex > KobraSight > Holo > OperatorSight > ACOG > Default
	local candidates = {
		{ key = "ReflexScope", label = "REFLEX_SCOPE", enabled = self:IsReflexScopeEnabled() },
		{ key = "Reflex", label = "REFLEX", enabled = self:IsReflexEnabled() },
		{ key = "KobraSight", label = "KOBRA", enabled = self:IsKobraSightEnabled() },
		{ key = "Holo", label = "HOLO", enabled = self:IsHoloEnabled() and not self:IsReflexEnabled() and not self:IsKobraSightEnabled() },
		{ key = "OperatorSight", label = "OPERATOR", enabled = self:IsOperatorSightEnabled() },
		{ key = "ACOG", label = "ACOG", enabled = self:IsACOGEnabled() },
	}

	for _, candidate in ipairs(candidates) do
		local upgradeProfile = upgradesSettings[candidate.key]
		if candidate.enabled and typeof(upgradeProfile) == "table" then
			local merged = {}
			for k, v in pairs(baseAiming) do merged[k] = v end
			for k, v in pairs(upgradeProfile) do merged[k] = v end

			if merged.Enabled == nil then
				merged.Enabled = (baseAiming.Enabled ~= false)
			end

			return merged, (merged.Position or basePos), candidate.label
		end
	end

	if baseAiming.Enabled == nil then
		baseAiming.Enabled = true
	end

	return baseAiming, basePos, "DEFAULT"
end

function GunUpgradeController:IsAutoUpgradeEnabled()
	if not self.Upgrades then return false end

	local autoObj = self.Upgrades:FindFirstChild("Auto") or self.Upgrades:FindFirstChild("AUTO")
	if not autoObj then
		return false
	end

	if autoObj:IsA("ValueBase") then
		return self:ToBool(autoObj.Value)
	end

	if autoObj:IsA("Folder") then
		local enabled = autoObj:FindFirstChild("Enabled")
		if enabled and enabled:IsA("ValueBase") then
			return self:ToBool(enabled.Value)
		end

		local anyValue = autoObj:FindFirstChildWhichIsA("ValueBase")
		if anyValue then
			return self:ToBool(anyValue.Value)
		end
	end

	return false
end

function GunUpgradeController:GetEffectiveFireRate()
	local settings = self:_settings()
	local base = math.max(0, tonumber(settings.FireRate) or 0)

	if self:IsAutoUpgradeEnabled() then
		local up = settings.Upgrades and settings.Upgrades.Auto
		local upgraded = up and up.FireRate
		if upgraded ~= nil then
			local n = tonumber(upgraded)
			if n and n >= 0 then
				return n
			end
		end
	end

	return base
end

function GunUpgradeController:GetCurrentMagSize(grenadeLauncherEnabled)
	local settings = self:_settings()
	if grenadeLauncherEnabled and settings.Upgrades and settings.Upgrades.GrenadeLauncher then
		return settings.Upgrades.GrenadeLauncher.Ammo.Mag
	end
	return settings.Ammo.Mag
end

function GunUpgradeController:GetPredictedMagMax(grenadeLauncherEnabled)
	local settings = self:_settings()

	if grenadeLauncherEnabled then
		local gl = settings.Upgrades and settings.Upgrades.GrenadeLauncher
		local ammo = gl and gl.Ammo
		return math.max(0, tonumber(ammo and ammo.Mag) or 1)
	end

	local magMax = settings.Ammo and settings.Ammo.Mag or 0
	if self:IsEnabled("ExtendedMag") then
		local ext = settings.Upgrades and settings.Upgrades.ExtendedMag
		if ext and ext.Mag ~= nil then
			magMax = ext.Mag
		end
	end

	return math.max(0, tonumber(magMax) or 0)
end

return GunUpgradeController
