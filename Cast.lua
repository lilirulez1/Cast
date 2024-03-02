local RunService = game:GetService("RunService")

local Lunaris = game.ReplicatedStorage.Lunaris
local Signal = require(Lunaris.Utils.Signal)
local Bind = require(Lunaris.Utils.Bind)

local DebugContainer = Instance.new("Part", workspace)
DebugContainer.Name = "Debug Container"
DebugContainer.Anchored = true
DebugContainer.CanCollide = false
DebugContainer.CanQuery = false
DebugContainer.CanTouch = false
DebugContainer.Position = Vector3.zero
DebugContainer.Transparency = 1
DebugContainer.Size = Vector3.one

type RaycastResult = {
	Position: Vector3,
	Instance: Instance,
	Distance: number,
	Normal: Vector3,
	Material: Enum.Material
}

type Segment = {
	StartTime: number,
	EndTime: number,
	Origin: Vector3,
	Direction: Vector3,
	InitialVelocity: Vector3,
	Acceleration: Vector3,
}

export type Data = {
	Velocity: number,
	Diameter: number,
	BallisticsCoefficient: number,
	Mass: number
}

type Cast<UserData = {any}> = {
	IsSimulating: boolean,
	IsPaused: boolean,
	
	Info: {
		TotalRuntime: number,
		Distance: number,
		Drop: number,
	},
	
	Projectile: {
		InitialVelocity: number,
		Mass: number,
		Diameter: number,
		BallisticsCoefficient: number
	},
	
	Data: {
		Origin: Vector3,
		Direction: Vector3,
		Velocity: Vector3
	},
	
	UserData: UserData,
	
	Event: RBXScriptConnection,
	
	SetPosition: (self: Cast<UserData>, Position: Vector3) -> (),
	SetVelocity: (self: Cast<UserData>, Velocity: number) -> (),
	
	Terminate: (self: Cast<UserData>) -> (),
}
local _Cast: Cast = {}

function NewCast(): Cast
	return setmetatable({
		IsSimulating = false,
		IsPaused = false,
		
		Info = {
			TotalRuntime = 0,
			Distance = 0,
			Drop = 0,
		},
		
		Projectile = {
			InitialVelocity = 0,
			Mass = 0,
			Diameter = 0,
			BallisticsCoefficient = 0
		},

		Data = {
			Origin = Vector3.zero,
			Direction = Vector3.zero,
			Velocity = Vector3.zero
		},
		
		UserData = {},
	}:: Cast, {
		__index = _Cast
	})
end

function _Cast:SetVelocity(Velocity: number)
	self.Data.Velocity = Velocity
end

function _Cast:SetPosition(Position: Vector3)
	self.Data.Origin = Position
end

function _Cast:Terminate()
	self.IsSimulating = false
	self.Event:Disconnect()
end

type Debug = {
	Enabled: boolean,
	Lines: {
		Enabled: boolean,
		Color: Color3,
		MatchVelocity: boolean
	},
	Chevrons: {
		Enabled: boolean,
		Scale: number,
		Color: Color3
	},
	HitMarkers: {
		Enabled: boolean,
		Scale: number,
		Color: Color3
	}
}

export type Caster<UserData> = {
	Gravity: number,
	MaxDistance: number,
	RaycastParams: RaycastParams,
	
	HitTest: Bind.Bind<(Cast<UserData>, RaycastResult), (boolean)>,
	
	OnHit: Signal.Signal<(Cast<UserData>, RaycastResult)>,
	OnMoved: Signal.Signal<(Cast<UserData>, RaycastResult)>,
	
	Debug: Debug,
	
	Wireframes: {
		Lines: WireframeHandleAdornment,
		Chevrons: WireframeHandleAdornment,
		HitMarkers: WireframeHandleAdornment,
		
		LinesRed: WireframeHandleAdornment,
		LinesYellow: WireframeHandleAdornment,
		LinesGreen: WireframeHandleAdornment,
		LinesBlue: WireframeHandleAdornment,
		LinesWhite: WireframeHandleAdornment,
	},
	
	Fire: (self: Caster<UserData>, Origin: Vector3, Direction: Vector3, Velocity: number, UserData: UserData) -> ()
}
local Caster: Caster<{}> = {}

function Caster:Fire(Origin: Vector3, Direction: Vector3, Data: Data, UserData)
	local Velocity = Direction.Unit * Data.Velocity
	local CrossSectionalArea = math.pi * (Data.Diameter / 2)^2 / 1000000
	local BallisticsCoefficient = Data.BallisticsCoefficient
	local Mass = Data.Mass / 15430
	local ConversionFactor = 3.517

	local Cast = NewCast()
	
	Cast.Info.InitialVelocity = Velocity
	
	Cast.Data.Velocity = Velocity
	Cast.Data.Origin = Origin
	
	Cast.UserData = UserData
	
	local Event = (RunService:IsClient()) and RunService.RenderStepped or RunService.Heartbeat
	
	local Lines      = self.Wireframes.Lines
	local Chevrons   = self.Wireframes.Chevrons
	local HitMarkers = self.Wireframes.HitMarkers
	
	Lines.Color3      = self.Debug.Lines.Color
	Chevrons.Color3   = self.Debug.Chevrons.Color
	HitMarkers.Color3 = self.Debug.HitMarkers.Color
	
	local function DrawCross(Raycast: RaycastResult)
		if not self.Debug.HitMarkers.Enabled then return end
		local Scale = self.Debug.HitMarkers.Scale
		
		local WidthVector = Raycast.Normal:Cross(Vector3.new(1, 0, 0))
		local HeightVector = Raycast.Normal:Cross(Vector3.new(0, 1, 0))
		local DepthVector = Raycast.Normal:Cross(Vector3.new(0, 0, 1))

		if WidthVector.Magnitude > 0 then
			local Point1 = Raycast.Position + WidthVector * Scale
			local Point2 = Raycast.Position - WidthVector * Scale
			HitMarkers:AddLine(Point1, Point2)
		end

		if HeightVector.Magnitude > 0 then
			local Point1 = Raycast.Position + HeightVector * Scale
			local Point2 = Raycast.Position - HeightVector * Scale
			HitMarkers:AddLine(Point1, Point2)
		end

		if DepthVector.Magnitude > 0 then
			local Point1 = Raycast.Position + DepthVector * Scale
			local Point2 = Raycast.Position - DepthVector * Scale
			HitMarkers:AddLine(Point1, Point2)
		end
	end

	local function DrawChevron(Origin: Vector3, Direction: Vector3)
		if not self.Debug.Chevrons.Enabled then return end
		local Scale = self.Debug.Chevrons.Scale

		local PerpendicularDirection = Vector3.new(-Direction.Z, 0, Direction.X).Unit * Scale

		local Point1 = Origin + PerpendicularDirection
		local Point2 = Origin - PerpendicularDirection
		local Point3 = Origin - (Direction * Scale)

		Chevrons:AddLine(Point1, Point3)
		Chevrons:AddLine(Point2, Point3)
	end

	local function VisualizeRaycast(Origin: Vector3, EndOrigin: Vector3)
		local Direction = (Origin - EndOrigin).Unit
		DrawChevron(Origin, Direction)
		
		if self.Debug.Lines.Enabled == false then return end
		
		if self.Debug.Lines.MatchVelocity then
			local CurrentVelocity = Cast.Data.Velocity.Magnitude
			local InitialVelocity = Velocity.Magnitude
			
			local Percentage = math.clamp((CurrentVelocity / InitialVelocity), 0, 1)
			
			if Percentage < .1 then
				self.Wireframes.LinesWhite:AddLine(Origin, EndOrigin)
			elseif Percentage < .25 then
				self.Wireframes.LinesBlue:AddLine(Origin, EndOrigin)
			elseif Percentage < .5 then
				self.Wireframes.LinesGreen:AddLine(Origin, EndOrigin)
			elseif Percentage < .75 then
				self.Wireframes.LinesYellow:AddLine(Origin, EndOrigin)
			elseif Percentage <= 1 then
				self.Wireframes.LinesRed:AddLine(Origin, EndOrigin)
			end
		else
			Lines:AddLine(Origin, EndOrigin)
		end
	end
	
	local function CalculateConstantDrag()
		local DragCoefficient = BallisticsCoefficient / (2 * Mass)
		return .5 * DragCoefficient * CrossSectionalArea * 1.29
	end

	local ConstantDrag = CalculateConstantDrag()

	Cast.Event = Event:Connect(function(DeltaTime)
		if Cast.IsSimulating or Cast.IsPaused then return end
		Cast.IsSimulating = true
		local CurrentVelocity = Cast.Data.Velocity
		local CurrentOrigin = Cast.Data.Origin
		local Speed = CurrentVelocity.Magnitude
		
		local Drag = Vector3.new(
			-ConstantDrag * Velocity.X * Speed,
			-ConstantDrag * Velocity.Y * Speed,
			-ConstantDrag * Velocity.Z * Speed
		)
		
		local NetForce = Drag + Vector3.new(0, self.Gravity, 0)
		
		local Acceleration = NetForce --/ Mass

		local NewVelocity = CurrentVelocity + DeltaTime * Acceleration
		local NewOrigin = CurrentOrigin + (NewVelocity * ConversionFactor * DeltaTime)
		
		local DropInStuds = (NewOrigin.Y - CurrentOrigin.Y)
		local DropInMeters = DropInStuds / ConversionFactor

		local Distance = (NewOrigin - CurrentOrigin).Magnitude
		local DistanceInMeters = Distance / ConversionFactor

		local RayDirection = (NewOrigin - CurrentOrigin).Unit * Distance

		local Raycast = workspace:Raycast(CurrentOrigin, RayDirection, self.RaycastParams)

		Cast.Info.TotalRuntime += DeltaTime
		Cast.Info.Distance += DistanceInMeters
		Cast.Info.Drop += DropInMeters
		
		Cast.Data.Direction = RayDirection
		Cast.Data.Velocity = NewVelocity
		Cast.Data.Origin = NewOrigin
		
		if Cast.Info.Distance > self.MaxDistance then
			Cast:Terminate()
		end
		
		self.OnMoved:Fire(Cast, Raycast)

		if Raycast then
			if self.Debug.Enabled then
				VisualizeRaycast(CurrentOrigin, Raycast.Position)
				DrawCross(Raycast)
			end
			
			if self.HitTest:Fire(Cast, Raycast) == true then
				self.OnHit:Fire(Cast, Raycast)
			else
				self.OnHit:Fire(Cast, Raycast)
				Cast:Terminate()
				return
			end
		elseif self.Debug.Enabled then
			VisualizeRaycast(CurrentOrigin, NewOrigin)
		end

		Cast.IsSimulating = false
	end)
end

function CreateWireframe(Color: Color3)
	local Wireframe = Instance.new("WireframeHandleAdornment", DebugContainer)
	Wireframe.Adornee = DebugContainer
	Wireframe.Color3 = Color
	Wireframe.AlwaysOnTop = true

	return Wireframe
end

return function(): Caster
	local self = setmetatable({}, {
		__index = Caster
	})
	
	self.Gravity = -9.81 * 3.571
	self.MaxDistance = 2000
	
	local Params = RaycastParams.new()
	Params.IgnoreWater = true
	Params.FilterType = Enum.RaycastFilterType.Exclude
	Params.FilterDescendantsInstances = {}
	
	self.RaycastParams = Params
	
	self.HitTest = Bind()
	
	self.OnHit = Signal()
	self.OnMoved = Signal()
	
	local Debug: Debug = {
		Enabled = false,
		Lines = {
			Enabled = true,
			Color = Color3.new(1, 0, 0)
		},
		Chevrons = {
			Enabled = true,
			Scale = .5,
			Color = Color3.new(1, 1, 0)
		},
		HitMarkers = {
			Enabled = true,
			Scale = .5,
			Color = Color3.new(0, 1, 0)
		}
	}
	
	self.Debug = Debug

	self.Wireframes = {
		Lines = CreateWireframe(Debug.Lines.Color),
		Chevrons     = CreateWireframe(Debug.Chevrons.Color),
		HitMarkers   = CreateWireframe(Debug.HitMarkers.Color),
		
		LinesRed     = CreateWireframe(Color3.new(1, 0, 0)),
		LinesYellow  = CreateWireframe(Color3.new(1, 1, 0)),
		LinesGreen   = CreateWireframe(Color3.new(0, 1, 0)),
		LinesBlue    = CreateWireframe(Color3.new(0, 0, 1)),
		LinesWhite   = CreateWireframe(Color3.new(1, 1, 1)),
	}
	
	return self
end
