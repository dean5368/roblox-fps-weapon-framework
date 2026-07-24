local module = {
	
	WeaponName = "AK-12";
	
	FireMode = "[AUTO]";
	
	SlideLock = false;
	
	ShootWhileRunning = false;
	
	PenetrateHumanoids = true;
	
	Upgrades = {
	
		Enabled = true;
		
		Suppressor = {
			BulletName = "Suppressed";
			DamageChange = 0.8;
			AccuracyChange = 0.8;
			RecoilChange = 0.8;
			Range = 1900;
			VelocityChange = 0.8;
			
		};	
		
		CollapsedStock = {
			-- All values are multipliers
			AimSpeed = 1.3; -- FOV and Viewmodel

			RecoilMaxMultiplier = 1.5;
			SpeedMultiplier = 1.2;
			DamperMultiplier = 0.7;
			HorizontalMultiplier = 1.5;
			VerticalMultiplier = 1.5;

			ReloadWalkSpeedReduction = 0.65;
			GlobalAimWalkSpeedReduction = 0.25;


		};
		
		
		VertGrip = {

			RecoilMaxMultiplier = 0.65;
			SpeedMultiplier = 0.7;
			DamperMultiplier = 1.4;
			HorizontalMultiplier = 1;
			VerticalMultiplier = 0.65

		};

		AngledGrip = {

			RecoilMaxMultiplier = 0.65;
			SpeedMultiplier = 0.7;
			DamperMultiplier = 1.4;
			HorizontalMultiplier = 0.65;
			VerticalMultiplier = 1;

			AimSpeedMultiplier = 1.2;
			FOVSpeedMultiplier = 1.2;

		};
		
		KobraSight = {

			Position = CFrame.new(-0.946, 0.346, 0.45);
			Reticle = "rbxassetid://3284311474";
			Speed = 0.25;
			FOV = 55;
			FOVSpeed = 0.25;

			ReticleVisDelay = 0.2;
			UpdateSpeed = 0.01;
			--TimeToDisappear = 0.001;
			MaxOffset = UDim2.new(0.0025, 0, 0.0025, 0);


			EasingStyle = Enum.EasingStyle.Linear;
			EasingDirection = Enum.EasingDirection.Out;

			FOV_EasingStyle = Enum.EasingStyle.Linear;
			FOV_EasingDirection = Enum.EasingDirection.Out;

			SensMultiplier = 0.5,

		};
		
		
		
		ACOG = {

			Position = CFrame.new(-0.641, 0.174, 0);
			Speed = 0.4;
			FOV = 20;
			FOVSpeed = 0.4;


			EasingStyle = Enum.EasingStyle.Linear;
			EasingDirection = Enum.EasingDirection.Out;

			FOV_EasingStyle = Enum.EasingStyle.Linear;
			FOV_EasingDirection = Enum.EasingDirection.Out;

		};
		
		Holo = {
			
			Position = CFrame.new(-0.506, 0.075, 0.2);
			Reticle = "rbxassetid://11520527247";
			Speed = 0.35;
			FOV = 60;
			FOVSpeed = 0.35;
			
			ReticleVisDelay = 0.5;
			UpdateSpeed = 0.01;
			--TimeToDisappear = 0.001;
			MaxOffset = UDim2.new(0.0025, 0, 0.0025, 0);
			Size = UDim2.new(0, 75, 0, 75);

			EasingStyle = Enum.EasingStyle.Linear;
			EasingDirection = Enum.EasingDirection.Out;

			FOV_EasingStyle = Enum.EasingStyle.Linear;
			FOV_EasingDirection = Enum.EasingDirection.Out;
			
		};
		
		Reflex = {

			Position = CFrame.new(-0.649, 0.19, 0);
			Reticle = "rbxassetid://3284311474";
			Speed = 0.25;
			FOV = 45;
			FOVSpeed = 0.25;

			ReticleVisDelay = 0.2;
			UpdateSpeed = 0.01;
			--TimeToDisappear = 0.001;
			MaxOffset = UDim2.new(0.005, 0, 0.005, 0);


			EasingStyle = Enum.EasingStyle.Linear;
			EasingDirection = Enum.EasingDirection.Out;

			FOV_EasingStyle = Enum.EasingStyle.Linear;
			FOV_EasingDirection = Enum.EasingDirection.Out;

		};
		
		ReflexScope = {

			Position = CFrame.new(-0.968, 0.342, 0.75);
			Reticle = "rbxassetid://3284311474";
			Speed = 0.25;
			FOV = 55;
			FOVSpeed = 0.25;

			ReticleVisDelay = 0.2;
			UpdateSpeed = 0.01;
			--TimeToDisappear = 0.001;
			MaxOffset = UDim2.new(0.0025, 0, 0.0025, 0);


			EasingStyle = Enum.EasingStyle.Linear;
			EasingDirection = Enum.EasingDirection.Out;

			FOV_EasingStyle = Enum.EasingStyle.Linear;
			FOV_EasingDirection = Enum.EasingDirection.Out;
			
				SensMultiplier = 0.5,

		};
		
		OperatorSight = {

			Position = CFrame.new(-0.645, 0.21, 0);
			Reticle = "rbxassetid://125555081257636";
			Speed = 0.2;
			FOV = 45;
			FOVSpeed = 0.2;
			
			Size = UDim2.new(0, 15, 0, 15);

			ReticleVisDelay = 0.2;
			UpdateSpeed = 0.005;
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
		CrossSize = 30;
		CrossExpansion = 45;
		CrossSpeed = 39;
		CrossDamper	= 0.7;
		
	};
	
	CrouchReduction = {
		Enabled = true;

		CrosshairSizeReduction = 0.75; -- lower = smaller crosshair
		RecoilReduction = 0.8;        -- lower = less recoil
		AccuracyMultiplier = 0.7;     -- lower = tighter spread

		TweenSpeed = 12;              -- higher = faster crouch transition
	};
	
	DepthOfField = {
		Enabled = true;
		FarIntensity = 0;
		FocusDistance = 1;
		InFocusRadius = 0.55;
		NearIntensity = 0.45;

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
	
	Knockback = 0.3;
	
	EquipTime = 1.87;
	Auto = true;
	FireRate = 0.085;
	Range = 2500;

	DamageDropOff = {
		Enabled = true,
		FullDamageDistance = 35,
		ZeroDamageDistance = 250,
		MinimumMultiplier = 0.4, -- 0 = can reach 0 damage, 0.1 = always at least 10%
		Curve = "Linear", -- "Linear" or "SmoothStep"
	};


	DamageTable = {
		
		Head = 30;
		Torso = 20;
		Limbs = 16;
		
	};
	
	ReloadTime = 4.5;
	ReloadWalkSpeedReduction = 6;
	
	Ammo = {
		LowAmmoClicks = true;
		RaisePitch = true;
		LowAmmoPercent = 40;
		DefaultMag = 30;
		DefaultStored = 90;
		DefaultStoredMax = 90;
		
		Mag = 30;
		Stored = 90;
		StoredMax = 90;
		
	};
	
	ReloadTimeScale = 0.8;
	EquipTimeScale = 0.8;
	MagDrop = {
		Enabled = true;

		MagName = "Mag2";
		DestroyCloneDelay = 5;

		Velocity = 25;
		VelocityDirection = Vector3.new(0,0,-90);
		VelocitySpace = "Magazine";

		AngularVelocity = Vector3.new(0,0,0);
		CanCollide = true;

		MagTimeLine = {
			{ t = 0.00, action = "HideMag", target = "Magazine" };
			{ t = 0.00, action = "ShowMag", target = "Mag2" };

			{ t = 0.75, action = "ShowMag", target = "Magazine" };

			{ t = 1.23, action = "CloneMag", target = "Mag2" };
			{ t = 1.23, action = "HideMag", target = "Mag2" };

			{ t = 2.00, action = "ShowMag", target = "Magazine" };
			{ t = 2.00, action = "ShowMag", target = "Mag2" };
		};
	};
	
	
	
	ReloadSFX = {
		{ t = 0.30, name = "Move4" },
		{ t = 1.20, name = "MagOut" },
		{ t = 1.525, name = "MagDrop" },
		{ t = 1.70, name = "MagIn" },
		{ t = 2.20, name = "Move2" },
		{ t = 2.30, name = "BoltBack" },
		{ t = 2.40, name = "BoltForward" },
		{ t = 3.35, name = "Move3" },
	};
	
	
	
	EquipSFX = {
	--	{ t = 0, name = "Equip" },
		{ t = 0, name = "Equip2" },
		{ t = 0.15, name = "Move2" },
		{ t = 0.31, name = "BoltBack" },
		{ t = 0.58, name = "BoltForward" },
		{ t = 0.5, name = "Move3" },
	};
	
	ShellEjection = {

		Enabled = true;
		Delay = 0;
		ShellName = "762";
		Velocity = 30;

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
		
		Horizontal = 5;
		Vertical = 5;
		
		AimHorizontal = 0.05;
		AimVertical = 0.05;
		
	};
	
	GlobalAimWalkSpeedReduction = 6;
	
	Aiming = {
		
		
		--0.003, 0.01, 0.2
		Enabled = true;
		Position = CFrame.new(-0.946, 0.335, 0.45);
	--	Rotation = CFrame.new(-20,0,0);
		Speed = 0.65;
		FOV = 40;
		FOVSpeed = 0.75;
		
		EasingStyle = Enum.EasingStyle.Quint;
		EasingDirection = Enum.EasingDirection.In;
		
		FOV_EasingStyle = Enum.EasingStyle.Quint;
		FOV_EasingDirection = Enum.EasingDirection.Out;
		
		SensMultiplier = 0.5;
		
	};
	
	Recoil = {
		
		RecoilMax = {70, 100};
		Speed = 50;
		Damper = 0.6;
		EasingDirection = Enum.EasingDirection.Out;
		EasingStyle = Enum.EasingStyle.Quint;
		Horizontal = {-2,-2};
		Vertical = {5, 5};
			
	};
	
	BulletSettings = {
		BulletName = "Bullet";
	--	Visible = true;
		Velocity = 1500;
	};
	
	MuzzleEffects = {

		MuzzleFlash = true;
		MuzzleLightSettings = {
			Enabled = true;

			Range = 2;
			Brightness = 1.25;
			Shadows = false;
			Color = Color3.fromRGB(255, 211, 110);
			LightTime = 0.05;
		};


	};
	
}

return module
