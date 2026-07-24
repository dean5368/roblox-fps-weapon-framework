local module = {}

function module.new(config)
	local self = {}

	self.SettingsModule = config.SettingsModule
	self.UserInputService = config.UserInputService
	self.TweenService = config.TweenService
	self.Mouse = config.Mouse

	self.Gui = nil
	self.CrosshairGui = nil
	self.CrosshairMain = nil
	self.CrossParts = nil
	self.AllFrames = nil

	self.Current = 0
	self.Target = 0
	self.Velocity = 0

	self.ScopingGetter = config.ScopingGetter
	self.EquippedGetter = config.EquippedGetter
	self.CanFireGetter = config.CanFireGetter
	self.SprintGetter = config.SprintGetter
	self.LastCanFire = nil
	self.ReadyTweenToken = 0
	self.ReadyTransparency = 0.5
	self.FrameTransparencyTweens = {}
	function self:GetSettings()
		local settings = require(self.SettingsModule)
		local ch = settings.Crosshair or {}

		return {
			Enabled = ch.Enabled == true,
			CrossSize = tonumber(ch.CrossSize) or 7,
			CrossExpansion = tonumber(ch.CrossExpansion) or 100,
			CrossSpeed = tonumber(ch.CrossSpeed) or 15,
			CrossDamper = tonumber(ch.CrossDamper) or 0.8,
		}
	end

	function self:SetVisible(visible)
		if self.CrosshairGui then
			self.CrosshairGui.Visible = visible == true
		end

		if self.CrosshairMain then
			self.CrosshairMain.Visible = visible == true
		end
	end
	
	function self:SetCrosshairFramesVisible(visible)
		visible = visible == true

		if self.CrossParts then
			for _, frame in pairs(self.CrossParts) do
				if frame and frame.Parent and frame:IsA("GuiObject") then
					frame.Visible = visible
				end
			end
		end

		-- optional safety: hide any extra frames inside Main too
		if self.CrosshairMain then
			for _, obj in ipairs(self.CrosshairMain:GetDescendants()) do
				if obj:IsA("GuiObject") then
					obj.Visible = visible
				end
			end
		end
	end
	
	function self:CancelFrameTransparencyTweens()
		if not self.FrameTransparencyTweens then
			self.FrameTransparencyTweens = {}
			return
		end

		for frame, tween in pairs(self.FrameTransparencyTweens) do
			if tween then
				pcall(function()
					tween:Cancel()
				end)

				pcall(function()
					tween:Destroy()
				end)
			end

			self.FrameTransparencyTweens[frame] = nil
		end
	end

	function self:SetFrameTransparency(value)
		if not self.AllFrames then return end

		self:CancelFrameTransparencyTweens()

		value = math.clamp(tonumber(value) or 0, 0, 1)
		self.ReadyTransparency = value

		for _, frame in ipairs(self.AllFrames) do
			if frame and frame.Parent and frame:IsA("GuiObject") then
				frame.BackgroundTransparency = value
			end
		end
	end

	function self:TweenFrameTransparency(targetValue, tweenTime)
		if not self.AllFrames then return end

		if not self.TweenService then
			self:SetFrameTransparency(targetValue)
			return
		end

		self:CancelFrameTransparencyTweens()

		self.ReadyTweenToken += 1
		local token = self.ReadyTweenToken

		targetValue = math.clamp(tonumber(targetValue) or 0, 0, 1)
		tweenTime = tonumber(tweenTime) or 0.5

		for _, frame in ipairs(self.AllFrames) do
			if frame and frame.Parent and frame:IsA("GuiObject") then
				local tween = self.TweenService:Create(
					frame,
					TweenInfo.new(
						tweenTime,
						Enum.EasingStyle.Quint,
						Enum.EasingDirection.Out
					),
					{
						BackgroundTransparency = targetValue
					}
				)

				self.FrameTransparencyTweens[frame] = tween

				tween:Play()

				tween.Completed:Once(function()
					if token ~= self.ReadyTweenToken then return end

					if self.FrameTransparencyTweens then
						self.FrameTransparencyTweens[frame] = nil
					end

					self.ReadyTransparency = targetValue
				end)
			end
		end
	end

	function self:UpdateCanFireVisual(force)
		if not self.CrosshairMain then return end

		local canFire = true
		if self.CanFireGetter then
			canFire = self.CanFireGetter() == true
		end

		local sprinting = false
		if self.SprintGetter then
			sprinting = self.SprintGetter() == true
		end

		-- Treat sprinting like CanFire = false.
		local ready = canFire and not sprinting

		if force ~= true and self.LastCanFire == ready then
			return
		end

		self.LastCanFire = ready

		if ready then
			self:TweenFrameTransparency(0, 0.5)
		else
			self.ReadyTweenToken += 1
			self:SetFrameTransparency(0.5)
		end
	end

	function self:Reset()
		self:CancelFrameTransparencyTweens()
		
		self.Gui = nil
		self.CrosshairGui = nil
		self.CrosshairMain = nil
		self.CrossParts = nil
		self.AllFrames = nil

		self.Current = 0
		self.Target = 0
		self.Velocity = 0

		self.LastCanFire = nil
		self.ReadyTweenToken += 1
		self.ReadyTransparency = 0.5
	end

	function self:Cache(gui)
		self:Reset()

		self.Gui = gui
		if not self.Gui then return end

		self.CrosshairGui = self.Gui:FindFirstChild("Crosshair")
		if not self.CrosshairGui then return end

		self.CrosshairMain = self.CrosshairGui:FindFirstChild("Main")
		if not self.CrosshairMain then return end

		local hr = self.CrosshairMain:FindFirstChild("HR")
		local hl = self.CrosshairMain:FindFirstChild("HL")
		local vd = self.CrosshairMain:FindFirstChild("VD")
		local vu = self.CrosshairMain:FindFirstChild("VU")

		if not (hr and hl and vd and vu) then
			warn("[Crosshair] Missing HR, HL, VD, or VU inside GunGUI.Crosshair.Main")
			return
		end

		self.CrossParts = {
			HR = hr,
			HL = hl,
			VD = vd,
			VU = vu,
		}

		self.AllFrames = {}

		for _, obj in ipairs(self.CrosshairMain:GetDescendants()) do
			if obj:IsA("Frame") then
				table.insert(self.AllFrames, obj)
			end
		end

		for _, obj in ipairs(self.CrosshairMain:GetChildren()) do
			if obj:IsA("Frame") and not table.find(self.AllFrames, obj) then
				table.insert(self.AllFrames, obj)
			end
		end

		local ch = self:GetSettings()

		self.Current = ch.CrossSize
		self.Target = ch.CrossSize
		self.Velocity = 0

		self:SetVisible(ch.Enabled)
		self:UpdateCanFireVisual(true)
	end

	function self:Bump()
		local ch = self:GetSettings()
		if not ch.Enabled then return end

		self.Target = ch.CrossSize + ch.CrossExpansion
		self.Velocity += ch.CrossExpansion * 12

		task.delay(0.035, function()
			local latest = self:GetSettings()
			self.Target = latest.CrossSize
		end)
	end

	function self:Step(dt)
		if not self.EquippedGetter() then return end
		if not self.Gui then return end
		if not self.CrosshairMain or not self.CrossParts then return end

		local ch = self:GetSettings()

		if not ch.Enabled then
			self:SetVisible(false)
			return
		end

		self:SetVisible(true)

		if self.ScopingGetter and self.ScopingGetter() then
			self:SetCrosshairFramesVisible(false)
			return
		end

		self:SetCrosshairFramesVisible(true)
		self:UpdateCanFireVisual(false)

		if self.UserInputService.MouseEnabled and self.UserInputService.KeyboardEnabled then
			self.CrosshairGui.Position = UDim2.new(0, self.Mouse.X, 0, self.Mouse.Y)
		else
			self.CrosshairGui.Position = UDim2.new(0.5, 0, 0.5, 0)
		end

		local speed = math.max(ch.CrossSpeed, 0.01)
		local damper = math.clamp(ch.CrossDamper, 0.01, 5)

		local displacement = self.Target - self.Current
		local accel = (displacement * speed * speed) - (self.Velocity * 2 * damper * speed)

		self.Velocity += accel * dt
		self.Current += self.Velocity * dt

		if math.abs(self.Current - ch.CrossSize) < 0.02 and math.abs(self.Velocity) < 0.02 then
			self.Current = ch.CrossSize
			self.Velocity = 0
		end

		local spacing = math.max(0, self.Current)

		local leftWidth = self.CrossParts.HL.AbsoluteSize.X
		local upHeight = self.CrossParts.VU.AbsoluteSize.Y

		if leftWidth <= 0 then
			leftWidth = self.CrossParts.HL.Size.X.Offset
		end

		if upHeight <= 0 then
			upHeight = self.CrossParts.VU.Size.Y.Offset
		end

		self.CrossParts.HR.Position = UDim2.new(0, spacing, 0, 0)
		self.CrossParts.HL.Position = UDim2.new(0, -spacing - leftWidth, 0, 0)

		self.CrossParts.VD.Position = UDim2.new(0, 0, 0, spacing)
		self.CrossParts.VU.Position = UDim2.new(0, 0, 0, -spacing - upHeight)
	end

	return self
end

return module