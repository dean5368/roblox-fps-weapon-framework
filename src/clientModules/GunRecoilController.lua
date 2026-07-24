--// GunRecoilController.lua
--// Put this ModuleScript in ReplicatedStorage.ClientModules
--// Owns recoil springs, camera recovery, and optional movement tilt.

local GunRecoilController = {}
GunRecoilController.__index = GunRecoilController

local function safeCall(fn, ...)
	if typeof(fn) ~= "function" then return nil end
	local ok, result = pcall(fn, ...)
	if ok then return result end
	warn("[GunRecoilController] callback error:", result)
	return nil
end

local function angleDiff(a, b)
	return math.atan2(math.sin(a - b), math.cos(a - b))
end

local function getCameraPitchYaw(cf)
	local look = cf.LookVector
	local pitch = math.asin(math.clamp(look.Y, -1, 1))
	local yaw = math.atan2(-look.X, -look.Z)
	return pitch, yaw
end

local function getAxisRecoilRecoveryAlpha(amount, dt, minSpeed, maxSpeed, fullDistanceDeg, curve)
	local dist = math.abs(amount)
	if dist <= math.rad(0.035) then
		return 1
	end

	local scale = math.clamp(dist / math.rad(fullDistanceDeg), 0, 1)
	local curved = scale ^ curve
	local speed = minSpeed + ((maxSpeed - minSpeed) * curved)
	return 1 - math.exp(-speed * dt)
end

function GunRecoilController.new(ctx)
	ctx = ctx or {}
	local self = setmetatable({}, GunRecoilController)

	self.Spring = ctx.Spring
	self.TweenService = ctx.TweenService
	self.SettingsModule = ctx.SettingsModule
	self.UpgradeController = ctx.UpgradeController
	self.CrouchController = ctx.CrouchController
	self.GetCamera = ctx.GetCamera
	self.GetHumanoid = ctx.GetHumanoid
	self.GetTool = ctx.GetTool

	self.RecoilSpring = self.Spring.new(Vector3.new())
	self.RecoilPosSpring = self.Spring.new(Vector3.new())
	self.LastRecoil = Vector3.new()
	self.LastPosKick = Vector3.new()
	self.Rng = Random.new()

	self.LastShotTime = 0
	self.BasePitch = nil
	self.BaseYaw = nil

	self.TiltSettings = {
		Enabled = false,
		MaxTiltDegrees = 10,
		TweenTime = 0.15,
		EasingStyle = Enum.EasingStyle.Quad,
		EasingDirection = Enum.EasingDirection.Out,
	}

	self.TiltValue = Instance.new("NumberValue")
	self.TiltValue.Value = 0
	self.TiltTween = nil
	self.TiltTarget = 0
	self.LastTiltRad = 0

	self:RefreshSettings()
	return self
end

function GunRecoilController:_settings()
	return require(self.SettingsModule)
end

function GunRecoilController:_camera()
	return safeCall(self.GetCamera) or workspace.CurrentCamera
end

function GunRecoilController:_humanoid()
	return safeCall(self.GetHumanoid)
end

function GunRecoilController:_tool()
	return safeCall(self.GetTool)
end

function GunRecoilController:_isVertGripEnabled()
	return self.UpgradeController and self.UpgradeController:IsVertGripEnabled()
end

function GunRecoilController:_isAngledGripEnabled()
	return self.UpgradeController and self.UpgradeController:IsAngledGripEnabled()
end

function GunRecoilController:_isCollapsedStockEnabled()
	return self.UpgradeController and self.UpgradeController:IsCollapsedStockEnabled()
end

function GunRecoilController:_getCollapsedStockSettings()
	return self.UpgradeController and self.UpgradeController:GetCollapsedStockSettings()
end

function GunRecoilController:_getCrouchMultiplier(name, defaultValue)
	if self.CrouchController and typeof(self.CrouchController.GetMultiplier) == "function" then
		return self.CrouchController:GetMultiplier(name, defaultValue)
	end
	return defaultValue or 1
end

function GunRecoilController:RefreshSettings()
	local settings = self:_settings()
	local r = settings.Recoil
	if not r then return end

	local speed = r.Speed or 1
	local damper = r.Damper or 0.78

	if self:_isVertGripEnabled() then
		local vg = settings.Upgrades and settings.Upgrades.VertGrip
		if vg then
			speed *= (vg.SpeedMultiplier or 1)
			damper *= (vg.DamperMultiplier or 1)
		end
	end

	if self:_isAngledGripEnabled() then
		local ag = settings.Upgrades and settings.Upgrades.AngledGrip
		if ag then
			speed *= (ag.SpeedMultiplier or 1)
			damper *= (ag.DamperMultiplier or 1)
		end
	end

	if self:_isCollapsedStockEnabled() then
		local cs = self:_getCollapsedStockSettings()
		if cs then
			speed *= (cs.SpeedMultiplier or 1)
			damper *= (cs.DamperMultiplier or 1)
		end
	end

	self.RecoilSpring.Speed = speed
	self.RecoilSpring.Damping = damper
	self.RecoilSpring.Target = self.RecoilSpring.Target or Vector3.new()

	self.RecoilPosSpring.Speed = speed * 1.15
	self.RecoilPosSpring.Damping = math.min(0.9, damper + 0.06)
	self.RecoilPosSpring.Target = self.RecoilPosSpring.Target or Vector3.new()
end

function GunRecoilController:SetTiltTarget(deg)
	if deg == self.TiltTarget then return end
	self.TiltTarget = deg

	if self.TiltTween then
		self.TiltTween:Cancel()
		self.TiltTween = nil
	end

	self.TiltTween = self.TweenService:Create(
		self.TiltValue,
		TweenInfo.new(self.TiltSettings.TweenTime, self.TiltSettings.EasingStyle, self.TiltSettings.EasingDirection),
		{ Value = deg }
	)
	self.TiltTween:Play()
end

function GunRecoilController:Apply()
	local settings = self:_settings()
	local r = settings.Recoil
	if not r then return end

	local camera = self:_camera()
	if not camera then return end

	local now = os.clock()
	if now - self.LastShotTime > 0.28 or not self.BasePitch or not self.BaseYaw then
		self.BasePitch, self.BaseYaw = getCameraPitchYaw(camera.CFrame)
	end
	self.LastShotTime = now

	local vMin, vMax = r.Vertical[1], r.Vertical[2]
	local hMin, hMax = r.Horizontal[1], r.Horizontal[2]
	local vMul, hMul = 1, 1
	local maxMul = 1

	if self:_isVertGripEnabled() then
		local vg = settings.Upgrades and settings.Upgrades.VertGrip
		if vg then
			vMul *= (vg.VerticalMultiplier or 1)
			hMul *= (vg.HorizontalMultiplier or 1)
			maxMul *= (vg.RecoilMaxMultiplier or 1)
		end
	end

	if self:_isAngledGripEnabled() then
		local ag = settings.Upgrades and settings.Upgrades.AngledGrip
		if ag then
			vMul *= (ag.VerticalMultiplier or 1)
			hMul *= (ag.HorizontalMultiplier or 1)
			maxMul *= (ag.RecoilMaxMultiplier or 1)
		end
	end

	if self:_isCollapsedStockEnabled() then
		local cs = self:_getCollapsedStockSettings()
		if cs then
			vMul *= (cs.VerticalMultiplier or 1)
			hMul *= (cs.HorizontalMultiplier or 1)
			maxMul *= (cs.RecoilMaxMultiplier or 1)
		end
	end

	local crouchRecoilMul = self:_getCrouchMultiplier("RecoilReduction", 1)
	vMul *= crouchRecoilMul
	hMul *= crouchRecoilMul
	maxMul *= crouchRecoilMul

	vMin *= vMul
	vMax *= vMul
	hMin *= hMul
	hMax *= hMul

	local up = math.rad(self.Rng:NextNumber(vMin, vMax))
	local side = math.rad(self.Rng:NextNumber(hMin, hMax))

	local maxV = math.rad(r.RecoilMax[1]) * maxMul
	local maxH = math.rad(r.RecoilMax[2]) * maxMul

	local vRatio = math.clamp(math.abs(self.RecoilSpring.Target.X) / math.max(maxV, 0.001), 0, 1)
	local hRatio = math.clamp(math.abs(self.RecoilSpring.Target.Y) / math.max(maxH, 0.001), 0, 1)

	local vStrength = math.clamp(1 - (vRatio ^ 2), 0.15, 1)
	local hStrength = math.clamp(1 - (hRatio ^ 2), 0.15, 1)

	self.RecoilSpring.Target = Vector3.new(
		math.clamp(self.RecoilSpring.Target.X + (up * vStrength), 0, maxV),
		math.clamp(self.RecoilSpring.Target.Y + (side * hStrength), -maxH, maxH),
		0
	)
end

function GunRecoilController:Step(dt)
	local camera = self:_camera()
	if not camera then return end

	local posKick = self.RecoilPosSpring.Position
	local deltaPos = posKick - self.LastPosKick
	self.LastPosKick = posKick

	local humanoid = self:_humanoid()
	local tool = self:_tool()

	local shouldTilt = false
	if self.TiltSettings.Enabled and humanoid and tool and tool:FindFirstChild("IsGun") then
		local moving = humanoid.MoveDirection.Magnitude > 0.05
		local grounded = humanoid.FloorMaterial ~= Enum.Material.Air
		shouldTilt = moving and grounded
	end

	if shouldTilt then
		self:SetTiltTarget(-self.TiltSettings.MaxTiltDegrees)
	else
		self:SetTiltTarget(0)
	end

	local tiltRad = math.rad(self.TiltValue.Value)
	local deltaTilt = tiltRad - self.LastTiltRad
	self.LastTiltRad = tiltRad

	local now = os.clock()
	local canRecover = (now - self.LastShotTime) >= 0.075
	if canRecover then
		local verticalAlpha = getAxisRecoilRecoveryAlpha(self.RecoilSpring.Target.X, dt, 0.75, 5.25, 10, 1.35)
		local horizontalAlpha = getAxisRecoilRecoveryAlpha(self.RecoilSpring.Target.Y, dt, 0.25, 2.15, 10, 1.85)

		self.RecoilSpring.Target = Vector3.new(
			self.RecoilSpring.Target.X + (0 - self.RecoilSpring.Target.X) * verticalAlpha,
			self.RecoilSpring.Target.Y + (0 - self.RecoilSpring.Target.Y) * horizontalAlpha,
			0
		)

		if math.abs(self.RecoilSpring.Target.X) <= math.rad(0.035) then
			self.RecoilSpring.Target = Vector3.new(0, self.RecoilSpring.Target.Y, 0)
		end

		if math.abs(self.RecoilSpring.Target.Y) <= math.rad(0.035) then
			self.RecoilSpring.Target = Vector3.new(self.RecoilSpring.Target.X, 0, 0)
		end

		if self.RecoilSpring.Target.Magnitude <= math.rad(0.035) then
			self.RecoilSpring.Target = Vector3.new()
			self.RecoilSpring.Velocity = Vector3.new()
		end
	end

	local recoil = self.RecoilSpring.Position
	local deltaRecoil = recoil - self.LastRecoil
	self.LastRecoil = recoil

	local pitchDelta = deltaRecoil.X
	local yawDelta = deltaRecoil.Y

	if canRecover and self.BasePitch and self.BaseYaw then
		local currentPitch, currentYaw = getCameraPitchYaw(camera.CFrame)
		local pitchDeadzone = math.rad(0.08)
		local yawDeadzone = math.rad(0.08)

		if pitchDelta < 0 then
			local pitchFromBase = currentPitch - self.BasePitch
			if pitchFromBase <= pitchDeadzone then
				pitchDelta = 0
			else
				pitchDelta = math.max(pitchDelta, -pitchFromBase)
			end
		end

		local yawFromBase = angleDiff(currentYaw, self.BaseYaw)
		if math.abs(yawFromBase) <= yawDeadzone then
			yawDelta = 0
		else
			if yawFromBase > 0 then
				if yawDelta < 0 then
					yawDelta = math.max(yawDelta, -yawFromBase)
				else
					yawDelta = 0
				end
			elseif yawFromBase < 0 then
				if yawDelta > 0 then
					yawDelta = math.min(yawDelta, -yawFromBase)
				else
					yawDelta = 0
				end
			end
		end
	end

	if math.abs(pitchDelta) <= math.rad(0.002) then
		pitchDelta = 0
	end
	if math.abs(yawDelta) <= math.rad(0.002) then
		yawDelta = 0
	end

	camera.CFrame = camera.CFrame * CFrame.new(deltaPos) * CFrame.Angles(pitchDelta + deltaTilt, yawDelta, 0)
end

function GunRecoilController:ResetTilt()
	self:SetTiltTarget(0)
	self.LastTiltRad = 0
end

function GunRecoilController:Reset()
	self.RecoilSpring.Velocity = Vector3.new()
	self.RecoilSpring.Target = Vector3.new()
	self.RecoilPosSpring.Velocity = Vector3.new()
	self.RecoilPosSpring.Target = Vector3.new()
	self.LastRecoil = Vector3.new()
	self.LastPosKick = Vector3.new()
	self.LastShotTime = 0
	self.BasePitch = nil
	self.BaseYaw = nil
	self:ResetTilt()
end

return GunRecoilController
