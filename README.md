# Usage

```lua
local Cast = require(game.ReplicatedStorage.Lunaris.Cast)

local Caster: Cast.Caster<{
	Hits: number
}> = Cast()

Caster.MaxDistance = 10000

Caster.Debug = {
	Enabled = true,
	Lines = {
		Enabled = true,
		Color = Color3.new(0, 0, 0),
		MatchVelocity = true
	},
	Chevrons = {
		Enabled = false,
		Scale = 1,
		Color = Color3.new(1, 0, 0)
	},
	HitMarkers = {
		Enabled = true,
		Scale = 1,
		Color = Color3.new(1, 1, 1)
	},
}

Caster.HitTest:Bind(function(CastData, RaycastResult)
	--EXAMPLE--
	
	--CastData.UserData.Hits += 1
	
	--if CastData.UserData.Hits > 3 then
	--	return false
	--else
	--	return true
	--end
	
	return false
end)

Caster.OnHit:Connect(function(CastData, RaycastResult)
	-- print(`Hit something! Hit count: {CastData.UserData.Hits}`)
	print("Hit something!")
end)

Caster.OnMoved:Connect(function(CastData, RaycastResult)
	print("Cast moved!")
	if CastData.Data.Origin.Y <= 0 then
		CastData:Terminate()
	end
end)

Caster:Fire(Vector3.zero, Vector3.new(0, 1, .45), {
	-- For a tennis ball
	Velocity = 55, -- m/s
	BallisticsCoefficient = 0.075,
	Diameter = 250, -- mm
	Mass = 864, -- grain
}, {
	-- Hits = 0
})
```

https://github.com/lilirulez1/Cast/assets/73417631/fa8eeb53-8213-4a84-9257-c7b2a8938027
