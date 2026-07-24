local module = {
	
	WeaponName = "G17";
	
	FireMode = "[SEMI]";
	
	SlideLock = true;
	
	ShootWhileRunning = false;
	
	PenetrateHumanoids = false;
	
	Upgrades = {
	
		Enabled = true;
		
		Suppressor = {
			BulletName = "Suppressed";
			DamageChange = 0.9;
			AccuracyChange = 0.75;
			RecoilChange = 0.85;
			Range = 900;
			VelocityChange = 0.9;

		};		
		
		ExtendedMag = {
		
			Mag = 30;
			Stored = 90;
			StoredMax = 90;
			
		};
		
		Auto_Upgrade = {
			
			Auto = true;
			FireRate = 0.1;	
			
		};
		
		HollowPoints = {

			HeadShotMultiplier = 1.5;
			AccuracyChange = 0.9;
			RecoilChange = 1.3;
			Range = 0.95;
			VelocityChange = 0.75;
		};
		
		Reflex = {

			Position = CFrame.new(-0.535, 0.245, 0.4);
			Reticle = "rbxassetid://3284311474";
			Speed = 0.25;
			FOV = 50;
			FOVSpeed = 0.25;

			ReticleVisDelay = 0.2;
			UpdateSpeed = 0.01;
			--TimeToDisappear = 0.001;
			MaxOffset = UDim2.new(0.0025, 0, 0.0025, 0);


			EasingStyle = Enum.EasingStyle.Linear;
			EasingDirection = Enum.EasingDirection.Out;

			FOV_EasingStyle = Enum.EasingStyle.Linear;
			FOV_EasingDirection = Enum.EasingDirection.Out;

		};
		
	};
	
	Crosshair = {

		Enabled = true;
		CrossSize = 7;
		CrossExpansion = 100;
		CrossSpeed = 15;
		CrossDamper	= 0.8;

	};
	
	DepthOfField = {
		Enabled = true;
		FarIntensity = 0.03;
		FocusDistance = 0.7;
		InFocusRadius = 0.35;
		NearIntensity = 0.25;

		TweenTime = 0.75;
		EasingStyle = Enum.EasingStyle.Back;
		EasingDirection = Enum.EasingDirection.Out;
	};

	AimVignette = {
		Enabled = true;
		ImageTransparency = 0.0;

		TweenTime = 1;
		EasingStyle = Enum.EasingStyle.Linear;
		EasingDirection = Enum.EasingDirection.Out;
	};
	
	Knockback = 0.5;
	
	EquipTime = 1;
	Auto = false;
	FireRate = 0.05;
	Range = 1100;

	DamageDropOff = {
		Enabled = true,
		FullDamageDistance = 50,
		ZeroDamageDistance = 1100,
		MinimumMultiplier = 0.25, -- 0 = can reach 0 damage, 0.1 = always at least 10%
		Curve = "Linear", -- "Linear" or "SmoothStep"
	};

	DamageTable = {
		
		Head = 31;
		Torso = 19;
		Limbs = 15;
		
	};
	
	ReloadTime = 3.27;
	ReloadWalkSpeedReduction = 4;
	
	Ammo = {
		LowAmmoClicks = true;
		RaisePitch = true;
		LowAmmoPercent = 36;
		DefaultMag = 17;
		DefaultStored = 34;
		DefaultStoredMax = 34;
		
		Mag = 17;
		Stored = 34;
		StoredMax = 34;
		
	};
	
	ReloadSFX = {
		{ t = 0.20, name = "MagOut" },
		{ t = 0.75, name = "Pouch" },
		{ t = 1.25, name = "MagIn" },
		{ t = 1.5, name = "Move" },
		{ t = 1.75, name = "BoltBack2" },
		{ t = 2.075, name = "BoltForward" },
	};
	
	EquipSFX = {
		{ t = 0, name = "Equip" },
		{ t = 0.25, name = "BoltBack2" },
		{ t = 0.35, name = "BoltForward" },
	};
	
	ShellEjection = {
	
		Enabled = true;
		Delay = 0;
		ShellName = "9mm";
		Velocity = 20
		
	};
	
	ShotgunSettings = {

		Enabled = false;
		Bullets = 8;

		ShotgunPump = {

			Enabled = false;
			PumpDelay = 0.6;-- Until the animation starts
			PumpTime = 1.1; -- Delay until you can fre (After pump animation starts to play)
			PumpSFX = {
				{ t = 0.10, name = "BoltBack" },
				{ t = 0.2, name = "BoltForward" },
			};

		};

		ShotgunReload = {

			Enabled = false;
			TimePerShell = 0.8;
			PreShotgunReload = false;
			PreShotgunReloadDelay = 0.38;
		};

	};
	
	Accuracy = {
		
		Horizontal = 3;
		Vertical = 3;
		
		AimHorizontal = 0;
		AimVertical = 0;
		
	};
	
	GlobalAimWalkSpeedReduction = 3;
	
	Aiming = {
		
		Enabled = true;
		Position = CFrame.new(-0.535, 0.325, 0.4);
		Speed = 0.15;
		FOV = 50;
		FOVSpeed = 0.25;
		
		
		EasingStyle = Enum.EasingStyle.Quint;
		EasingDirection = Enum.EasingDirection.Out;
		
		FOV_EasingStyle = Enum.EasingStyle.Quint;
		FOV_EasingDirection = Enum.EasingDirection.Out;
		
		SensMultiplier = 0.8;
		
	};
	
	Recoil = {
		
		RecoilMax = {65,35}; 
		Speed = 27;
		Damper = 0.5;
		EasingDirection = Enum.EasingDirection.Out;
		EasingStyle = Enum.EasingStyle.Linear;
		Horizontal = {-5, 5};
		Vertical = {15, 15};
			
	};
	
	BulletSettings = {
		BulletName = "Bullet";
	--	Visible = true;
		Velocity = 1100;
	};
	
	MuzzleEffects = {
		
		MuzzleFlash = true;
		MuzzleLightSettings = {
			Enabled = true;

			Range = 4;
			Brightness = 2;
			Shadows = false;
			Color = Color3.fromRGB(255, 207, 85);
			LightTime = 0.05;
		};

		
	};
	
}

return module
