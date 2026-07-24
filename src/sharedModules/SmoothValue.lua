
local v1 = {};
v1.__index = v1;
local u1 = require(script:WaitForChild("SmoothDamp"));
function v1.new(p1, p2)
	assert(typeof(p1) == "Vector3", "initialValue should be Vector3");
	assert(typeof(p2) == "number", "smoothTime should be a number");
	assert(p2 >= 0, "smoothTime must be a positive number");
	local v2 = setmetatable({
		Value = p1, 
		Goal = p1, 
		SmoothTime = p2
	}, v1);
	v2._smoothDamp = u1.new();
	return v2;
end;
function v1.Update(p3, p4)
	if p4 then
		p3.Goal = p4;
	else
		p4 = p3.Goal;
	end;
	local v3 = p3._smoothDamp:Update(p3.Value, p4, p3.SmoothTime);
	p3.Value = v3;
	return v3;
end;
function v1.UpdateAngle(p5, p6)
	if p6 then
		p5.Goal = p6;
	else
		p6 = p5.Goal;
	end;
	local v4 = p5._smoothDamp:UpdateAngle(p5.Value, p6, p5.SmoothTime);
	p5.Value = v4;
	return v4;
end;
function v1.SetMaxSpeed(p7, p8)
	p7._smoothDamp.MaxSpeed = p8;
end;
function v1.GetMaxSpeed(p9)
	return p9._smoothDamp.MaxSpeed;
end;
return v1;
