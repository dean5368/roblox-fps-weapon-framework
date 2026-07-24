--// GunReloadController.lua
--// Put in ReplicatedStorage.ClientModules
--// Handles reload cancellation, reload UI, mag-drop timeline,
--// shotgun reload flow, and pump/reload helper SFX.
--// This version uses normal Settings.ReloadTime and Settings.EquipTime behavior.

local GunReloadController = {}
GunReloadController.__index = GunReloadController

local function toBool(v)
	if typeof(v) == "boolean" then return v end
	if typeof(v) == "number" then return v ~= 0 end
	if typeof(v) == "string" then
		v = v:lower()
		return (v == "true" or v == "1" or v == "yes" or v == "on")
	end
	return false
end

local function safeCall(fn, ...)
	if typeof(fn) ~= "function" then return nil end
	local ok, result = pcall(fn, ...)
	if ok then
		return result
	end
	warn("[GunReloadController] callback error:", result)
	return nil
end

function GunReloadController.new(config)
	local self = setmetatable({}, GunReloadController)

	self.Player = config.Player
	self.Tool = config.Tool
	self.Events = config.Events
	self.Values = config.Values or {}
	self.Upgrades = config.Upgrades
	self.SettingsModule = config.SettingsModule
	self.LocalMagDrop = config.LocalMagDrop
	self.MagDrop = config.MagDrop
	self.ReloadCancelFireDelay = tonumber(config.ReloadCancelFireDelay) or 0.25

	self.GetState = config.GetState
	self.SetState = config.SetState
	self.AddExternalToken = config.AddExternalToken
	self.Actions = config.Actions or {}

	self.GetAnimationsClient = config.GetAnimationsClient
	self.GetAnimationsTable = config.GetAnimationsTable
	self.GetSprint = config.GetSprint
	self.GetGunGui = config.GetGunGui
	self.GetReloadUI = config.GetReloadUI

	self._shotgunReloadToken = 0
	self._magDropToken = 0
	self._pumpAfterReloadToken = 0
	self._reloadCancelDebounce = false
	self._wasReloadCancelled = false
	self._currentReloadIsShotgun = false
	self._currentReloadMagMax = 0
	self._lastSfxAt = {}
	self._reloadConn = nil

	return self
end

function GunReloadController:_settings()
	return require(self.SettingsModule)
end

function GunReloadController:_get(name)
	return safeCall(self.GetState, name)
end

function GunReloadController:_set(name, value)
	safeCall(self.SetState, name, value)
end

function GunReloadController:_action(name, ...)
	return safeCall(self.Actions[name], ...)
end

function GunReloadController:_animationsClient()
	return safeCall(self.GetAnimationsClient)
end

function GunReloadController:_animationsTable()
	return safeCall(self.GetAnimationsTable) or {}
end

function GunReloadController:_reloadUI()
	return safeCall(self.GetReloadUI)
end

function GunReloadController:_gunGui()
	return safeCall(self.GetGunGui)
end

function GunReloadController:_sprint()
	return safeCall(self.GetSprint)
end

function GunReloadController:GetReloadTime()
	local settings = self:_settings()
	return math.max(0, tonumber(settings.ReloadTime) or 1)
end

function GunReloadController:AddToken(name, amount)
	amount = tonumber(amount) or 1

	if name == "shotgunReloadToken" then
		self._shotgunReloadToken += amount
	elseif name == "magDropToken" then
		self._magDropToken += amount
	elseif name == "pumpAfterReloadToken" then
		self._pumpAfterReloadToken += amount
	elseif name == "pumpAnimToken" then
		safeCall(self.AddExternalToken, name, amount)
	end
end

function GunReloadController:CancelTimelines()
	self:AddToken("shotgunReloadToken", 1)
	self:AddToken("magDropToken", 1)
	self:AddToken("pumpAfterReloadToken", 1)
end

function GunReloadController:ClearReloadSlow()
	local character = self:_get("Character")
	if not character or not character.Parent then
		character = self.Player and self.Player.Character
		self:_set("Character", character)
	end
	if not character then return end

	local ps = character:FindFirstChild("PlayerStuff")
	local vals = ps and ps:FindFirstChild("Values")
	local reloadSlow = vals and vals:FindFirstChild("ReloadSlow")

	if reloadSlow and reloadSlow:IsA("NumberValue") then
		reloadSlow.Value = 0
	end
end

function GunReloadController:_fireMagDropAction(action, target)
	if typeof(action) ~= "string" or action == "" then return end

	if self.LocalMagDrop and self.LocalMagDrop:IsA("BindableEvent") then
		self.LocalMagDrop:Fire(self.Tool.Name, action, target)
	end

	if self.MagDrop and self.MagDrop:IsA("RemoteEvent") then
		self.MagDrop:FireServer(self.Tool.Name, action, target)
	end
end

function GunReloadController:StartMagDropTimeline()
	local settings = self:_settings()
	local magDropSettings = settings.MagDrop

	if not magDropSettings then
		warn("[MagDrop] No Settings.MagDrop table found for:", self.Tool.Name)
		return
	end

	if magDropSettings.Enabled ~= true then
		return
	end

	local timeline = magDropSettings.MagTimeLine or magDropSettings.MagTimeline
	if typeof(timeline) ~= "table" then
		warn("[MagDrop] Settings.MagDrop.MagTimeLine missing or invalid for:", self.Tool.Name)
		return
	end

	self:AddToken("magDropToken", 1)
	local myToken = self._magDropToken
	local startTime = os.clock()
	task.spawn(function()
		for _, step in ipairs(timeline) do
			if myToken ~= self._magDropToken then return end
			if not self:_get("equipped") then return end

			local t = tonumber(step.t) or 0
			local action = step.action or step.name

			if typeof(action) ~= "string" then
				warn("[MagDrop] Timeline step missing string action/name for:", self.Tool.Name)
				continue
			end

			local waitTime = t - (os.clock() - startTime)
			if waitTime > 0 then
				task.wait(waitTime)
			end

			if myToken ~= self._magDropToken then return end
			if not self:_get("equipped") then return end

			self:_fireMagDropAction(action, step.target)
		end
	end)
end

function GunReloadController:GetShotgunReloadSettings()
	local settings = self:_settings()
	local ss = settings.ShotgunSettings
	local rs = ss and ss.ShotgunReload
	if rs and rs.Enabled == true then
		return rs, true
	end
	return rs, false
end

function GunReloadController:GetShotgunPumpSettings()
	local settings = self:_settings()
	local ss = settings.ShotgunSettings
	local ps = ss and ss.ShotgunPump
	if ps and ps.Enabled == true then
		return ps, true
	end
	return ps, false
end

function GunReloadController:_getHeadSoundParent()
	local character = self.Tool.Parent
	if character and character:IsA("Model") then
		local head = character:FindFirstChild("Head")
		if head and head:IsA("BasePart") then
			return head
		end
	end
	return self.Tool:FindFirstChild("Handle")
end

function GunReloadController:_findTimelineSoundTemplate(soundsFolder, soundName)
	if not soundsFolder then return nil end

	local reloadFolder = soundsFolder:FindFirstChild("ReloadSounds")
	local equipFolder = soundsFolder:FindFirstChild("EquipSounds")

	return (reloadFolder and reloadFolder:FindFirstChild(soundName))
		or (equipFolder and equipFolder:FindFirstChild(soundName))
		or soundsFolder:FindFirstChild(soundName)
end

function GunReloadController:_isSameSoundAlreadyPlaying(parent, soundName)
	if not parent then return false end

	for _, child in ipairs(parent:GetChildren()) do
		if child:IsA("Sound") and child.Name == soundName and child.IsPlaying then
			return true
		end
	end

	return false
end

function GunReloadController:_playTimelineSound(soundName)
	if not self:_get("equipped") then return end

	soundName = tostring(soundName or "")
	if soundName == "" then return end

	local handle = self.Tool:FindFirstChild("Handle")
	local soundsFolder = handle and handle:FindFirstChild("Sounds")

	if not (handle and soundsFolder) then
		warn("[TimelineSFX] Missing Tool.Handle.Sounds")
		return
	end

	local template = self:_findTimelineSoundTemplate(soundsFolder, soundName)
	if not template or not template:IsA("Sound") then
		warn(("[TimelineSFX] Sound '%s' not found in ReloadSounds, EquipSounds, or Sounds"):format(soundName))
		return
	end

	local parent = self:_getHeadSoundParent()
	if not parent then return end

	-- Prevent doubled audio if another old reload/equip system already played it.
	if self:_isSameSoundAlreadyPlaying(parent, soundName) or self:_isSameSoundAlreadyPlaying(handle, soundName) then
		return
	end

	local s = template:Clone()
	s.Parent = parent

	s.PlaybackSpeed = template.PlaybackSpeed

	s:Play()
	s.Ended:Connect(function()
		if s then s:Destroy() end
	end)
end

function GunReloadController:_safePlayTimelineSound(soundName, token)
	soundName = tostring(soundName or "")
	if soundName == "" then return end

	token = tostring(token or "nil")

	local DUP_WINDOW = 0.12
	local now = os.clock()

	local tokenKey = token .. "|" .. soundName
	local globalKey = "GLOBAL|" .. soundName

	local lastToken = self._lastSfxAt[tokenKey]
	local lastGlobal = self._lastSfxAt[globalKey]

	if lastToken and (now - lastToken) < DUP_WINDOW then
		return
	end

	if lastGlobal and (now - lastGlobal) < DUP_WINDOW then
		return
	end

	self._lastSfxAt[tokenKey] = now
	self._lastSfxAt[globalKey] = now

	self:_playTimelineSound(soundName)
end

function GunReloadController:_playTimelineSFX(timeline, stillValidCallback, token)
	if typeof(timeline) ~= "table" then return end

	local start = os.clock()

	for _, step in ipairs(timeline) do
		if stillValidCallback and not stillValidCallback() then return end

		local targetTime = tonumber(step.t) or 0
		local soundName = tostring(step.name or "")

		local waitTime = targetTime - (os.clock() - start)
		if waitTime > 0 then
			task.wait(waitTime)
		end

		if stillValidCallback and not stillValidCallback() then return end
		self:_safePlayTimelineSound(soundName, token)
	end
end

function GunReloadController:_getClientMagMax()
	local settings = self:_settings()
	local magMax = settings.Ammo and settings.Ammo.Mag or 0

	local ext = self.Upgrades and self.Upgrades:FindFirstChild("ExtendedMag")
	if ext and ext:IsA("ValueBase") and toBool(ext.Value) then
		local extSettings = settings.Upgrades and settings.Upgrades.ExtendedMag
		if extSettings and extSettings.Mag then
			magMax = extSettings.Mag
		end
	end

	return math.max(0, tonumber(magMax) or 0)
end

function GunReloadController:_stopReloadTracks()
	local animationsTable = self:_animationsTable()

	if animationsTable.Reload then pcall(function() animationsTable.Reload:Stop(0.05) end) end
	if animationsTable.PreShotgunReload then pcall(function() animationsTable.PreShotgunReload:Stop(0.05) end) end
	if animationsTable.ShotgunShell then pcall(function() animationsTable.ShotgunShell:Stop(0.05) end) end
end

function GunReloadController:_doPumpAfterReload()
	if not self:_get("equipped") then return end

	local pumpSettings, pumpEnabled = self:GetShotgunPumpSettings()
	if not pumpEnabled then
		self:_set("CanFire", true)
		return
	end

	self:AddToken("pumpAfterReloadToken", 1)
	local myToken = self._pumpAfterReloadToken

	local pumpDelay = tonumber(pumpSettings.PumpDelay) or 0
	local pumpTime = tonumber(pumpSettings.PumpTime) or 0
	local timeline = pumpSettings.PumpSFX

	self:_set("CanFire", false)

	local now = os.clock()
	local nextLocalFireTime = math.max(self:_get("nextLocalFireTime") or 0, now + pumpDelay + pumpTime)
	self:_set("nextLocalFireTime", nextLocalFireTime)
	self:_set("reloadLockedUntil", now + pumpDelay + pumpTime)

	task.spawn(function()
		if pumpDelay > 0 then
			local t0 = os.clock()
			while self:_get("equipped") and self._pumpAfterReloadToken == myToken and (os.clock() - t0) < pumpDelay do
				task.wait()
			end
		end

		if not self:_get("equipped") or self._pumpAfterReloadToken ~= myToken then return end

		local animationsTable = self:_animationsTable()
		if animationsTable.ShotgunShell then pcall(function() animationsTable.ShotgunShell:Stop(0.05) end) end
		if animationsTable.PreShotgunReload then pcall(function() animationsTable.PreShotgunReload:Stop(0.05) end) end

		if animationsTable.ShotgunPump then
			pcall(function()
				animationsTable.ShotgunPump:Stop(0)
				animationsTable.ShotgunPump:Play(0.05)
			end)
		end

		self:_playTimelineSFX(
			timeline,
			function()
				return self:_get("equipped") and self._pumpAfterReloadToken == myToken
			end,
			"PumpAfterReload|" .. tostring(myToken)
		)

		task.delay(pumpTime, function()
			if self:_get("equipped") and self._pumpAfterReloadToken == myToken and not self:_get("isReloading") then
				self:_set("CanFire", true)
			end
		end)
	end)
end

function GunReloadController:CancelReloadLocal(alsoTellServer)
	if self._reloadCancelDebounce then return end
	self._reloadCancelDebounce = true

	local hadReload = self:_get("isReloading") == true

	self:_set("isReloading", false)
	self:_set("firing", false)
	self:_set("isPumping", false)

	local cancelDelay = hadReload and self.ReloadCancelFireDelay or 0.15
	local now = os.clock()
	self:_set("suppressFireUntil", now + cancelDelay)
	self:_set("nextLocalFireTime", math.max(self:_get("nextLocalFireTime") or 0, now + cancelDelay))

	self:_action("ShowToolbarIfSafe")
	self:ClearReloadSlow()

	self:AddToken("shotgunReloadToken", 1)
	self:AddToken("pumpAnimToken", 1)
	self:AddToken("magDropToken", 1)
	self:AddToken("pumpAfterReloadToken", 1)
	self:_fireMagDropAction("ShowMag")

	local animationsClient = self:_animationsClient()
	if animationsClient and typeof(animationsClient.StopReloadTracks) == "function" then
		animationsClient:StopReloadTracks(0.05)
	else
		self:_stopReloadTracks()
	end

	local humanoid = self:_get("Humanoid")
	local alive = true
	if humanoid and humanoid.Parent then
		alive = humanoid.Health > 0
	end

	self:_set("CanFire", self:_get("equipped") and alive)

	local reloadUI = self:_reloadUI()
	if self._currentReloadIsShotgun and reloadUI then
		reloadUI:SetAmmoProgress(self.Values.MagValue.Value, self._currentReloadMagMax, true)
	end

	self._currentReloadIsShotgun = false
	self._currentReloadMagMax = 0
	self._wasReloadCancelled = true

	if reloadUI then
		reloadUI:CancelOut()
	end

	local gunGui = self:_gunGui()
	if gunGui then
		pcall(function()
			gunGui:Update(self:_settings(), self.Values.MagValue.Value, self.Values.StoredAmmoValue.Value)
		end)
	end

	if alsoTellServer and hadReload then
		pcall(function()
			local reloadEvent = self.Events and self.Events:FindFirstChild("Reload")
			if reloadEvent then
				reloadEvent:FireServer("Cancel")
			end
		end)
	end

	task.delay(0.05, function()
		self._reloadCancelDebounce = false
	end)
end

function GunReloadController:OnMagChanged()
	local reloadUI = self:_reloadUI()
	if self._currentReloadIsShotgun and self:_get("isReloading") and reloadUI then
		reloadUI:SetAmmoProgress(self.Values.MagValue.Value, self._currentReloadMagMax, true)
	end
end

function GunReloadController:_onReloadEvent(status)
	self:_action("RefreshSettings")

	if os.clock() < (self:_get("reloadLockedUntil") or 0) then return end
	if self:_get("isPumping") then return end

	local character = self:_get("Character")
	if not character or not character.Parent then
		character = self.Player and self.Player.Character
		self:_set("Character", character)
	end

	local humanoid = self:_get("Humanoid")
	if (not humanoid or not humanoid.Parent) and character then
		humanoid = character:FindFirstChildOfClass("Humanoid")
		self:_set("Humanoid", humanoid)
	end
	if not humanoid then return end

	local shotgunReloadSettings, shotgunReloadEnabled = self:GetShotgunReloadSettings()
	local animationsClient = self:_animationsClient()
	local animationsTable = self:_animationsTable()
	local reloadUI = self:_reloadUI()
	local gunGui = self:_gunGui()
	local sprint = self:_sprint()

	if animationsClient and typeof(animationsClient.EnsureReloadTracks) == "function" then
		animationsClient:EnsureReloadTracks(humanoid, shotgunReloadEnabled)
	end

	local ps = character and character:FindFirstChild("PlayerStuff")
	local vals = ps and ps:FindFirstChild("Values")
	local reloadSlow = vals and vals:FindFirstChild("ReloadSlow")

	if status == "Start" then
		if os.clock() < (self:_get("reloadLockedUntil") or 0) then
			return
		end

		self:_set("isReloading", true)
		self._wasReloadCancelled = false
		self:_action("SetToolbarEnabled", false)
		self:StartMagDropTimeline()

		self._currentReloadIsShotgun = shotgunReloadEnabled == true
		self._currentReloadMagMax = self:_getClientMagMax()

		if reloadUI then
			if self._currentReloadIsShotgun then
				reloadUI:ShowShotgunReloading(self.Values.MagValue.Value, self._currentReloadMagMax)
			else
				reloadUI:ShowReloading(self:GetReloadTime())
			end
		end

		self:_set("CanFire", false)
		if sprint then sprint:Update() end
		self:_action("SetAiming", false)

		if reloadSlow and reloadSlow:IsA("NumberValue") then
			local settings = self:_settings()
			reloadSlow.Value = math.max(0, tonumber(settings.ReloadWalkSpeedReduction) or 0)
		end

		if animationsTable.SlideLock then
			pcall(function() animationsTable.SlideLock:Stop() end)
		end

		if shotgunReloadEnabled then
			self:AddToken("shotgunReloadToken", 1)
			local myToken = self._shotgunReloadToken

			local usePre = shotgunReloadSettings.PreShotgunReload == true
			local preDelay = tonumber(shotgunReloadSettings.PreShotgunReloadDelay) or 0
			local timePerShell = math.max(0.05, tonumber(shotgunReloadSettings.TimePerShell) or 0.5)

			if usePre and animationsTable.PreShotgunReload then
				pcall(function()
					animationsTable.PreShotgunReload:Stop(0)
					animationsTable.PreShotgunReload:Play(0.05)
				end)
			end

			task.spawn(function()
				if preDelay > 0 then
					local t0 = os.clock()
					while self:_get("equipped") and self:_get("isReloading") and self._shotgunReloadToken == myToken and (os.clock() - t0) < preDelay do
						task.wait()
					end
				end

				while self:_get("equipped") and self:_get("isReloading") and self._shotgunReloadToken == myToken do
					local magMax = self:_getClientMagMax()
					if self.Values.MagValue.Value >= magMax then break end
					if self.Values.StoredAmmoValue.Value <= 0 then break end

					if animationsTable.ShotgunShell then
						pcall(function()
							animationsTable.ShotgunShell:Stop(0)
							animationsTable.ShotgunShell:Play(0.05)
						end)

						self:_safePlayTimelineSound("Shotgun_Shell", myToken)
					end

					local t1 = os.clock()
					while self:_get("equipped") and self:_get("isReloading") and self._shotgunReloadToken == myToken and (os.clock() - t1) < timePerShell do
						task.wait()
					end

					if self._currentReloadIsShotgun and reloadUI then
						reloadUI:SetAmmoProgress(self.Values.MagValue.Value, self._currentReloadMagMax, true)
					end
				end
			end)
		else
			local reloadTrack
			if self:_get("GrenadeLauncherEnabled") and animationsTable.GL_Reload then
				reloadTrack = animationsTable.GL_Reload
			else
				reloadTrack = animationsTable.Reload
			end

			if reloadTrack then
				pcall(function()
					reloadTrack:Play(0.05)
				end)
			end
		end

		if gunGui then
			gunGui:Update(self:_settings(), self.Values.MagValue.Value, self.Values.StoredAmmoValue.Value)
		end
		return
	end

	if status == "End" then
		self:AddToken("shotgunReloadToken", 1)
		self:AddToken("pumpAfterReloadToken", 1)
		self:_set("isReloading", false)
		self:_action("ShowToolbarIfSafe")

		if self._wasReloadCancelled then
			return
		end

		if reloadSlow and reloadSlow:IsA("NumberValue") then
			reloadSlow.Value = 0
		end

		self:_stopReloadTracks()

		if gunGui then
			gunGui:Update(self:_settings(), self.Values.MagValue.Value, self.Values.StoredAmmoValue.Value)
		end

		if shotgunReloadEnabled and shotgunReloadSettings and shotgunReloadSettings.PumpAfter == true then
			self:_set("CanFire", false)
			self:_doPumpAfterReload()
		else
			self:_set("CanFire", true)
		end

		if reloadUI then
			reloadUI:ShowReloaded()
			reloadUI:HideAfter(0.5, false)
		end
		return
	end
end

function GunReloadController:BindReloadEvent()
	if self._reloadConn then
		self._reloadConn:Disconnect()
		self._reloadConn = nil
	end

	local reloadEvent = self.Events and self.Events:FindFirstChild("Reload")
	if not reloadEvent then
		warn("[GunReloadController] Missing Events.Reload for:", self.Tool and self.Tool.Name)
		return
	end

	self._reloadConn = reloadEvent.OnClientEvent:Connect(function(status)
		self:_onReloadEvent(status)
	end)
end

function GunReloadController:Destroy()
	if self._reloadConn then
		self._reloadConn:Disconnect()
		self._reloadConn = nil
	end
	self:CancelTimelines()
end

return GunReloadController
