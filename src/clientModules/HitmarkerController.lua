local module = {}

function module.new(config)
	local self = {}

	self.SoundService = config.SoundService
	self.ToolEvents = config.ToolEvents
	self.ReplicatedEvents = config.ReplicatedEvents
	self.GuiGetter = config.GuiGetter
	self.Rng = Random.new()
	self.ConnectedRemotes = {}
	self.ContainerConns = {}
	
	
	self.TweenService = config.TweenService or game:GetService("TweenService")
	self.GuiGetter = config.GuiGetter

	self.HitmarkerTween = nil
	self.HitmarkerToken = 0

	function self:GetRandomHitSound(folder)
		if not folder then
			return nil
		end

		local sounds = {}

		for _, obj in ipairs(folder:GetChildren()) do
			if obj:IsA("Sound") then
				table.insert(sounds, obj)
			end
		end

		if #sounds <= 0 then
			return nil
		end

		return sounds[self.Rng:NextInteger(1, #sounds)]
	end

	function self:IsHeadshotHit(...)
		local args = { ... }

		for _, value in ipairs(args) do
			local valueType = typeof(value)

			if valueType == "boolean" then
				if value == true then
					return true
				end

			elseif valueType == "string" then
				local lowered = string.lower(value)
				if lowered == "head" or lowered == "headshot" or lowered == "head2" or string.find(lowered, "head", 1, true) then
					return true
				end

			elseif valueType == "Instance" then
				local loweredName = string.lower(value.Name)
				if loweredName == "head" or loweredName == "head2" or string.find(loweredName, "head", 1, true) then
					return true
				end

			elseif valueType == "table" then
				if value.Headshot == true or value.HeadShot == true or value.IsHeadshot == true or value.IsHeadShot == true then
					return true
				end

				if typeof(value.HitPart) == "Instance" then
					local loweredName = string.lower(value.HitPart.Name)
					if loweredName == "head" or loweredName == "head2" or string.find(loweredName, "head", 1, true) then
						return true
					end
				end

				if typeof(value.HitPartName) == "string" then
					local loweredName = string.lower(value.HitPartName)
					if loweredName == "head" or loweredName == "head2" or string.find(loweredName, "head", 1, true) then
						return true
					end
				end
			end
		end

		return false
	end
	
	function self:PlayGuiHitmarker(isHeadshot)
		if not self.GuiGetter then return end

		local gui = self.GuiGetter()
		if not gui then return end

		local crosshair = gui:FindFirstChild("Crosshair")
		if not crosshair then return end

		local hitmarkerImage = crosshair:FindFirstChild("Hitmarker")
		if not hitmarkerImage or not hitmarkerImage:IsA("ImageLabel") then
			return
		end

		self.HitmarkerToken += 1
		local token = self.HitmarkerToken

		if self.HitmarkerTween then
			self.HitmarkerTween:Cancel()
			self.HitmarkerTween = nil
		end

		-- color
		if isHeadshot then
			hitmarkerImage.ImageColor3 = Color3.fromRGB(171, 0, 0)
		else
			hitmarkerImage.ImageColor3 = Color3.fromRGB(255, 255, 255)
		end

		-- starting visual state
		hitmarkerImage.Visible = true
		hitmarkerImage.ImageTransparency = 0
		hitmarkerImage.Size = UDim2.new(0, 45, 0, 45)
		hitmarkerImage.Rotation = math.random(-5, 5)

		-- first tween: shrink + unrotate, no fade yet
		local popTween = self.TweenService:Create(
			hitmarkerImage,
			TweenInfo.new(
				0.1,
				Enum.EasingStyle.Linear,
				Enum.EasingDirection.Out
			),
			{
				Size = UDim2.new(0, 30, 0, 30),
				Rotation = 0
			}
		)

		popTween:Play()

		popTween.Completed:Once(function()
			if token ~= self.HitmarkerToken then return end

			-- second tween: fade away after the 0.1 second pop
			self.HitmarkerTween = self.TweenService:Create(
				hitmarkerImage,
				TweenInfo.new(
					0.35,
					Enum.EasingStyle.Linear,
					Enum.EasingDirection.Out
				),
				{
					ImageTransparency = 1
				}
			)

			self.HitmarkerTween:Play()

			self.HitmarkerTween.Completed:Once(function()
				if token ~= self.HitmarkerToken then return end

				hitmarkerImage.Visible = false
				hitmarkerImage.ImageTransparency = 1
				hitmarkerImage.Size = UDim2.new(0, 30, 0, 30)
				hitmarkerImage.Rotation = 0
			end)
		end)
	end
	
	function self:PlayGuiMarkerSound()
		if not self.GuiGetter then return end

		local gui = self.GuiGetter()
		if not gui then return end

		local crosshair = gui:FindFirstChild("Crosshair")
		if not crosshair then return end

		local markerSound = crosshair:FindFirstChild("MarkerSound")
		if not markerSound or not markerSound:IsA("Sound") then
			return
		end

		local sound = markerSound:Clone()
		sound.Name = "MarkerSound_Playing"
		sound.Parent = crosshair
		sound.TimePosition = 0

		local destroyed = false

		local function cleanup()
			if destroyed then return end
			destroyed = true

			if sound and sound.Parent then
				sound:Destroy()
			end
		end

		sound.Ended:Once(cleanup)
		sound:Play()

		task.delay(math.max((tonumber(sound.TimeLength) or 0) + 1, 2), cleanup)
	end

	function self:PlaySound(isHeadshot)
		local hitSoundsFolder = self.SoundService:FindFirstChild("HitSounds")
		if not hitSoundsFolder then
			warn("[HitmarkerSFX] Missing SoundService.HitSounds folder")
			return
		end

		local normalFolder = hitSoundsFolder:FindFirstChild("Normal")
		local headFolder = hitSoundsFolder:FindFirstChild("Head")
		local playingFolder = hitSoundsFolder:FindFirstChild("Playing")

		if not playingFolder then
			playingFolder = Instance.new("Folder")
			playingFolder.Name = "Playing"
			playingFolder.Parent = hitSoundsFolder
		end

		local chosenFolder = isHeadshot and headFolder or normalFolder
		local template = self:GetRandomHitSound(chosenFolder)

		if not template and isHeadshot then
			template = self:GetRandomHitSound(normalFolder)
		end

		if not template then
			warn("[HitmarkerSFX] No hitmarker sounds found in " .. (isHeadshot and "Head" or "Normal"))
			return
		end

		local sound = template:Clone()
		sound.Name = template.Name .. "_Playing"
		sound.Parent = playingFolder
		sound.TimePosition = 0

		local destroyed = false

		local function cleanup()
			if destroyed then return end
			destroyed = true

			if sound and sound.Parent then
				sound:Destroy()
			end
		end

		sound.Ended:Once(cleanup)
		sound:Play()

		local cleanupTime = tonumber(sound.TimeLength) or 0
		task.delay(math.max(cleanupTime + 2, 4), cleanup)
	end

	function self:ConnectRemote(remote)
		if not remote then return end

		if not remote:IsA("RemoteEvent") then
			warn("[HitmarkerSFX] Hitmarker is not a RemoteEvent:", remote.ClassName)
			return
		end

		if self.ConnectedRemotes[remote] then
			return
		end

		self.ConnectedRemotes[remote] = true

		remote.OnClientEvent:Connect(function(...)
			local isHeadshot = self:IsHeadshotHit(...)

			self:PlayGuiMarkerSound()
			self:PlayGuiHitmarker(isHeadshot)
			self:PlaySound(isHeadshot)
		end)
	end

	function self:TryConnectContainer(container)
		if not container then return end

		self:ConnectRemote(container:FindFirstChild("Hitmarker"))
		self:ConnectRemote(container:FindFirstChild("HitMarker"))
		self:ConnectRemote(container:FindFirstChild("HitmarkerSound"))
		self:ConnectRemote(container:FindFirstChild("HitSound"))
	end

	function self:Init()
		self:TryConnectContainer(self.ToolEvents)
		self:TryConnectContainer(self.ReplicatedEvents)

		if self.ToolEvents then
			table.insert(self.ContainerConns, self.ToolEvents.ChildAdded:Connect(function(child)
				if child.Name == "Hitmarker" or child.Name == "HitMarker" or child.Name == "HitmarkerSound" or child.Name == "HitSound" then
					self:ConnectRemote(child)
				end
			end))
		end

		if self.ReplicatedEvents then
			table.insert(self.ContainerConns, self.ReplicatedEvents.ChildAdded:Connect(function(child)
				if child.Name == "Hitmarker" or child.Name == "HitMarker" or child.Name == "HitmarkerSound" or child.Name == "HitSound" then
					self:ConnectRemote(child)
				end
			end))
		end
	end

	function self:Destroy()
		for _, conn in ipairs(self.ContainerConns) do
			if conn then
				conn:Disconnect()
			end
		end

		table.clear(self.ContainerConns)
		table.clear(self.ConnectedRemotes)
	end

	return self
end

return module