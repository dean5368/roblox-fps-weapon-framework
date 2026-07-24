local module = {} -- ScopeController.lua module
--// FOV note:
--// This script no longer tweens Camera.FieldOfView directly.
--// It asks ReplicatedStorage.ClientModules.FOVHandler to own the scope FOV layer.

local ReplicatedStorage = game:GetService("ReplicatedStorage")

local function getDefaultFOVHandler()
	local clientModules = ReplicatedStorage:FindFirstChild("ClientModules")
	local fovModule = clientModules and clientModules:FindFirstChild("FOVHandler")

	if fovModule and fovModule:IsA("ModuleScript") then
		local ok, result = pcall(require, fovModule)
		if ok then
			return result
		end
	end

	return nil
end

function module.new(config)
	local self = {}

	self.TweenService = config.TweenService or game:GetService("TweenService")
	self.UserInputService = config.UserInputService or game:GetService("UserInputService")

	self.Camera = config.Camera or workspace.CurrentCamera
	self.Mouse = config.Mouse
	self.Tool = config.Tool
	self.Spring = config.Spring

	self.SettingsModule = config.SettingsModule
	self.SettingsGetter = config.SettingsGetter
	self.GuiGetter = config.GuiGetter
	self.AimDownGetter = config.AimDownGetter
	self.DefaultSensitivityGetter = config.DefaultSensitivityGetter

	self.FOVHandler = config.FOVHandler or getDefaultFOVHandler()
	self.FOVSourceName = config.FOVSourceName or (self.Tool and ("Scope:" .. self.Tool.Name) or "Scope")
	self.FOVPriority = tonumber(config.FOVPriority) or 100

	self.SniperSettings = nil
	self.Enabled = false
	self.Scoping = false

	self.ScopeDelayTask = nil
	self.ScopeSpring = nil
	self.KnockbackSpring = nil

	function self:GetSettings()
		if self.SettingsGetter then
			local ok, result = pcall(self.SettingsGetter)
			if ok and result then
				return result
			end
		end

		if self.SettingsModule then
			local ok, result = pcall(require, self.SettingsModule)
			if ok and result then
				return result
			end
		end

		return {}
	end

	function self:GetSniperSettings()
		local settings = self:GetSettings()
		local sniperSettings = settings.SniperSettings

		if sniperSettings and sniperSettings.Enabled == true then
			return sniperSettings, true
		end

		return sniperSettings, false
	end

	function self:GetGui()
		if self.GuiGetter then
			local ok, result = pcall(self.GuiGetter)
			if ok then
				return result
			end
		end

		return nil
	end

	function self:IsAimDown()
		if self.AimDownGetter then
			local ok, result = pcall(self.AimDownGetter)
			if ok then
				return result == true
			end
		end

		return false
	end

	function self:GetDefaultSensitivity()
		if self.DefaultSensitivityGetter then
			local ok, result = pcall(self.DefaultSensitivityGetter)
			if ok and tonumber(result) then
				return tonumber(result)
			end
		end

		return self.UserInputService.MouseDeltaSensitivity
	end

	function self:GetScopedValue()
		if not self.Tool then return nil end

		local values = self.Tool:FindFirstChild("Values")
		if not values then return nil end

		local scopedVal = values:FindFirstChild("ScopedIn")
		if not scopedVal then
			scopedVal = Instance.new("BoolValue")
			scopedVal.Name = "ScopedIn"
			scopedVal.Value = false
			scopedVal.Parent = values
		end

		return scopedVal
	end

	function self:SetScopedValue(value)
		local scopedVal = self:GetScopedValue()
		if scopedVal then
			scopedVal.Value = value == true
		end
	end

	function self:CancelDelay()
		if self.ScopeDelayTask then
			task.cancel(self.ScopeDelayTask)
			self.ScopeDelayTask = nil
		end
	end

	function self:ApplyScopeFOV(enabled, sniperSettings, instant)
		if not self.FOVHandler then return end

		sniperSettings = sniperSettings or self.SniperSettings or {}

		local fovSpeed = tonumber(sniperSettings.FOVSpeed) or 0.15
		local easingStyle = sniperSettings.FOV_EasingStyle or Enum.EasingStyle.Quad
		local easingDirection = sniperSettings.FOV_EasingDirection or Enum.EasingDirection.Out

		local options = {
			Priority = self.FOVPriority,
			Duration = fovSpeed,
			EasingStyle = easingStyle,
			EasingDirection = easingDirection,
			Instant = instant == true,
		}

		if enabled then
			local targetFOV = tonumber(sniperSettings.FOV)

			if not targetFOV then
				if typeof(self.FOVHandler.GetBaseFOV) == "function" then
					targetFOV = self.FOVHandler:GetBaseFOV()
				else
					targetFOV = 70
				end
			end

			self.FOVHandler:SetOverride(self.FOVSourceName, targetFOV, options)
		else
			self.FOVHandler:Clear(self.FOVSourceName, options)
		end
	end

	function self:Init()
		self:CancelDelay()

		local sniperSettings, enabled = self:GetSniperSettings()

		self.SniperSettings = sniperSettings
		self.Enabled = enabled == true
		self.Scoping = false

		self:ApplyScopeFOV(false, sniperSettings, true)

		if not self.Enabled then
			self.ScopeSpring = nil
			self.KnockbackSpring = nil
			self:SetScopedValue(false)
			return false
		end

		if not self.Spring then
			warn("[ScopeController] Missing Spring module")
			return false
		end

		self.ScopeSpring = self.Spring.new(
			Vector3.new(),
			sniperSettings.ScopeSwayDamper,
			sniperSettings.ScopeSwaySpeed
		)

		self.KnockbackSpring = self.Spring.new(
			Vector3.new(),
			sniperSettings.ScopeKnockbackDamper,
			sniperSettings.ScopeKnockbackSpeed
		)

		self:SetScopedValue(false)

		return true
	end

	function self:IsEnabled()
		return self.Enabled == true
	end

	function self:IsScoping()
		return self.Scoping == true
	end

	function self:ShowScopeGui(visible)
		local gui = self:GetGui()
		if not gui then return end

		local scopeGui = gui:FindFirstChild("Scope")
		if not scopeGui then return end

		scopeGui.Visible = visible == true

		if visible and scopeGui:FindFirstChild("ZoomSound") then
			scopeGui.ZoomSound.TimePosition = 0
			scopeGui.ZoomSound:Play()
		end
	end

	function self:Enable()
		if not self.Enabled then return end
		if self.Scoping then return end

		local sniperSettings = self.SniperSettings
		if not sniperSettings then return end

		self:CancelDelay()

		local delayTime = tonumber(sniperSettings.ScopeDelay) or 0

		self.ScopeDelayTask = task.delay(delayTime, function()
			if not self:IsAimDown() then
				self.ScopeDelayTask = nil
				return
			end

			if not self.Enabled then
				self.ScopeDelayTask = nil
				return
			end

			self.Scoping = true
			self:SetScopedValue(true)

			self.UserInputService.MouseDeltaSensitivity = tonumber(sniperSettings.ScopeSensitive) or self.UserInputService.MouseDeltaSensitivity

			self:ApplyScopeFOV(true, sniperSettings, false)

			self:ShowScopeGui(true)

			if self.KnockbackSpring then
				self.KnockbackSpring:Impulse(Vector3.new(
					math.random(-4, 4),
					math.random(-4, 4),
					0
					))
			end

			self.ScopeDelayTask = nil
		end)
	end

	function self:Disable()
		self:CancelDelay()

		local sniperSettings = self.SniperSettings

		if not self.Scoping then
			self:SetScopedValue(false)
			self:ShowScopeGui(false)
			self:ApplyScopeFOV(false, sniperSettings, true)
			return
		end

		self.Scoping = false
		self:SetScopedValue(false)

		self.UserInputService.MouseDeltaSensitivity = self:GetDefaultSensitivity()

		self:ApplyScopeFOV(false, sniperSettings, false)

		self:ShowScopeGui(false)
	end

	function self:FireImpulse()
		if not self.Scoping then return end
		if not self.KnockbackSpring then return end

		self.KnockbackSpring:Impulse(Vector3.new(
			math.random(-2, 2),
			math.random(-2, 2),
			0
			))
	end

	function self:Step()
		if not self.Scoping then return end
		if not self.Enabled then return end
		if not self.SniperSettings then return end
		if not self.ScopeSpring then return end
		if not self.KnockbackSpring then return end
		if not self.Mouse then return end

		local gui = self:GetGui()
		if not gui then return end

		local scopeGui = gui:FindFirstChild("Scope")
		if not scopeGui then return end

		local scopeSensitive = tonumber(self.SniperSettings.ScopeSensitive) or 1
		local mouseDelta = self.UserInputService:GetMouseDelta() / math.max(scopeSensitive, 0.01)

		local scopeSize = scopeGui.AbsoluteSize.X
		local offset = scopeSize * 0.5

		self.ScopeSpring.t = Vector3.new(
			self.Mouse.X - offset - mouseDelta.X,
			self.Mouse.Y - offset - mouseDelta.Y,
			0
		)

		scopeGui.Position = UDim2.new(
			0,
			self.ScopeSpring.p.X + (self.KnockbackSpring.p.Y * 1000),
			0,
			self.ScopeSpring.p.Y + (self.KnockbackSpring.p.X * 200)
		)
	end

	function self:Destroy()
		self:CancelDelay()

		self.Scoping = false
		self.Enabled = false
		self.SniperSettings = nil

		self:SetScopedValue(false)
		self:ShowScopeGui(false)
		self:ApplyScopeFOV(false, nil, true)

		self.ScopeSpring = nil
		self.KnockbackSpring = nil
	end

	return self
end

return module
