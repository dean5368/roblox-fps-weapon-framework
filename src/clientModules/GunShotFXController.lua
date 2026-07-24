local GunShotFXController = {}
GunShotFXController.__index = GunShotFXController

function GunShotFXController.new(ctx)
	ctx = ctx or {}
	local self = setmetatable({}, GunShotFXController)
	self.Player = ctx.Player
	self.Tool = ctx.Tool
	self.SettingsModule = ctx.SettingsModule
	self.Upgrades = ctx.Upgrades
	self.UpgradeController = ctx.UpgradeController
	self.MagValue = ctx.MagValue
	self.LocalMuzzleFX = ctx.LocalMuzzleFX
	self.LocalFireFX = ctx.LocalFireFX
	return self
end

function GunShotFXController:_settings()
	return require(self.SettingsModule)
end

function GunShotFXController:_isUpgradeEnabled(name)
	if self.UpgradeController and typeof(self.UpgradeController.IsEnabled) == "function" then
		return self.UpgradeController:IsEnabled(name)
	end
	return false
end

function GunShotFXController:_getLowAmmoPercent()
	local settings = self:_settings()
	if not settings.Ammo then
		return 0
	end

	if typeof(settings.Ammo.LowAmmo) == "table" then
		local p = tonumber(settings.Ammo.LowAmmo.Percent)
		if p then
			return p
		end
	end

	return tonumber(settings.Ammo.LowAmmoPercent) or 0
end

-- Kept separate from the above so old Studio autocomplete doesn't get confused by a multiline clamp.
function GunShotFXController:_computePitchExtra(magAfterShot, magMax)
	local settings = self:_settings()
	if not settings.Ammo or settings.Ammo.RaisePitch ~= true then
		return 0
	end

	local percent = self:_getLowAmmoPercent()
	if percent <= 0 then return 0 end
	if magMax <= 0 then return 0 end

	local thresholdAmmo = magMax * (percent / 100)
	if magAfterShot > thresholdAmmo then
		return 0
	end

	local maxExtra = tonumber(settings.Ammo.RaisePitchMaxExtra)
		or tonumber(settings.Ammo.MaxPitchExtra)
		or 0.3

	maxExtra = math.clamp(maxExtra, 0, 3)
	local alpha = math.clamp((thresholdAmmo - magAfterShot) / math.max(thresholdAmmo, 1), 0, 1)
	return maxExtra * alpha
end

function GunShotFXController:IsRPGWeapon()
	local settings = self:_settings()
	return settings.RPG_ENABLED == true and typeof(settings.RPG_SETTINGS) == "table"
end

function GunShotFXController:Play(grenadeLauncherEnabled)
	local isRPG = self:IsRPGWeapon()
	local isGL = (not isRPG) and (grenadeLauncherEnabled == true)
	local isExplosive = isRPG or isGL

	local suppressed = self:_isUpgradeEnabled("Suppressor")
	local hollowpoints = self:_isUpgradeEnabled("HollowPoints")
	local incendiary = self:_isUpgradeEnabled("Incendiary")
	local fmj = self:_isUpgradeEnabled("FMJ")

	local currentMag = self.MagValue and tonumber(self.MagValue.Value) or 0
	local magAfterShot = math.max(currentMag - 1, 0)
	local magMax = 0

	if self.UpgradeController and typeof(self.UpgradeController.GetPredictedMagMax) == "function" then
		magMax = self.UpgradeController:GetPredictedMagMax(grenadeLauncherEnabled)
	end

	local firePitchExtra = self:_computePitchExtra(magAfterShot, magMax)

	if self.LocalMuzzleFX and not isExplosive then
		self.LocalMuzzleFX:Fire(self.Player, self.Tool.Name, suppressed)
	end

	if self.LocalFireFX then
		self.LocalFireFX:Fire(
			self.Player,
			self.Tool.Name,
			suppressed,
			hollowpoints,
			incendiary,
			fmj,
			isExplosive,
			firePitchExtra
		)
	end
end

return GunShotFXController
