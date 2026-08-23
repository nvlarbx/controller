const Parent = script.Parent
const Types = require(Parent.Types)

const RunService, UserInputService =
	game:GetService("RunService") :: RunService, game:GetService("UserInputService") :: UserInputService
const UserGameSettings = UserSettings():GetService("UserGameSettings") :: UserGameSettings
const Camera = workspace.CurrentCamera :: Camera

const InputContexts = game:GetService("Players").LocalPlayer:WaitForChild("InputContexts") :: Types.InputContexts
const CameraContext = InputContexts.CameraContext
const Rotate, Zoom, Pan = CameraContext.Rotate, CameraContext.Zoom, CameraContext.Pan
const MouseDelta, TouchDelta, Thumbstick1 = Rotate.MouseDelta, Rotate.TouchDelta, Rotate.Thumbstick1
const SendLookVector: InputBinding, SendFirstPerson: InputBinding =
	CameraContext.LookVector.controller, CameraContext.FirstPerson.controller

const clamp, rad, exp = math.clamp, math.rad, math.exp
const create, create2, magnitude, ZERO = vector.create, Vector2.new, vector.magnitude, vector.zero :: any
const lookAlong, fromEulerAnglesYXZ = CFrame.lookAlong, CFrame.fromEulerAnglesYXZ
const insert = table.insert

const RENDER_STEP_NAME = "OrbitalCamera"
const ZOOM_RATE = 4
const TAU, PITCH_LIMIT = (math.pi * 2) :: number, rad(80) :: number
const MOUSE_SCALE, GAMEPAD_SCALE, TOUCH_SCALE =
	create2(0.0025, 0.0025 * 0.77, 0) :: Vector2,
	(create2(1, 0.77, 0) * rad(240)) :: Vector2,
	(create2(1, 0.66, 0) * rad(1)) :: Vector2

local MinRadius, MaxRadius =
	(Parent:GetAttribute("MinRadius") or 0.5) :: number, (Parent:GetAttribute("MaxRadius") or 128) :: number
local Radius = clamp((Parent:GetAttribute("Radius") or 12.5) :: number, MinRadius, MaxRadius) :: number
local IsFirstPerson = (Radius <= 0.5) :: boolean
local Offset = (Parent:GetAttribute("Offset") or ZERO) :: Vector3

local Subject: (BasePart | Model)? = nil
local WarnedSubject = false
local Yaw, Pitch = 0, rad(-15) :: number
local LookVector = fromEulerAnglesYXZ(Pitch, Yaw, 0).LookVector :: Vector3
local LastSentLookVector = ZERO :: Vector3
local LastSentFirstPerson = false
local IsGamepad = false

local State = ZERO :: Vector3
local ZoomState = 0

const Connections = table.create(8) :: { RBXScriptConnection }

@native
const function TrySendLookVector(): ()
	if magnitude(LookVector - LastSentLookVector) > 0.001 then
		LastSentLookVector = LookVector
		SendLookVector:Fire(LookVector)
	end
end

const function TrySendFirstPerson(Value: boolean): ()
	if LastSentFirstPerson ~= Value then
		LastSentFirstPerson = Value
		SendFirstPerson:Fire(Value)
	end
end

const function UpdateMouseModifier(): ()
	MouseDelta.PrimaryModifier = if IsFirstPerson then Enum.KeyCode.None else Enum.KeyCode.MouseRightButton
end

const function UpdateMouseBehavior(): ()
	UserInputService.MouseBehavior = if IsFirstPerson or UserGameSettings:InFullScreen()
		then Enum.MouseBehavior.LockCenter
		elseif Pan:GetState() :: boolean then Enum.MouseBehavior.LockCurrentPosition
		else Enum.MouseBehavior.Default
end

@native
const function UpdateRadius(NewRadius: number): ()
	Radius = clamp(NewRadius, MinRadius, MaxRadius)
	IsFirstPerson = Radius <= 0.5
	TrySendFirstPerson(IsFirstPerson)
	UpdateMouseModifier()
	UpdateMouseBehavior()
	Parent:SetAttribute("Radius", Radius)
end

@native
const function RotateCamera(Delta: Vector3, Scale: number): ()
	Yaw = (Yaw - (Delta.X * Scale)) % TAU
	Pitch = clamp(Pitch - (Delta.Y * Scale), -PITCH_LIMIT, PITCH_LIMIT)
	LookVector = fromEulerAnglesYXZ(Pitch, Yaw, 0).LookVector
	TrySendLookVector()
end

const function Teardown(): ()
	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	RunService:UnbindFromRenderStep(RENDER_STEP_NAME)

	for _, Connection in Connections do
		Connection:Disconnect()
	end

	table.clear(Connections)
end

const function UpdateSubject(): ()
	const Handle = Parent:GetAttribute("Subject") :: { Get: (any) -> Instance? }?
	const TempSubject = if Handle then Handle:Get() else nil

	if TempSubject then
		if TempSubject:IsA("BasePart") or TempSubject:IsA("Model") then
			Subject, WarnedSubject = TempSubject, false
			return
		elseif WarnedSubject == false then
			WarnedSubject = true
			warn(`Subject {TempSubject.Name} of class {TempSubject.ClassName} is not treated`)
		end
	elseif WarnedSubject == false then
		WarnedSubject = true
		warn("Missing subject")
	end

	Subject = nil
end

const function UpdateOffset(): ()
	Offset = (Parent:GetAttribute("Offset") or ZERO) :: Vector3
end

const function UpdateSensitivities(): ()
	const Invert = UserGameSettings:GetCameraYInvertValue() :: number
	MouseDelta.Vector2Scale = create2(MOUSE_SCALE.X, MOUSE_SCALE.Y * Invert)
	MouseDelta.Scale = UserGameSettings.MouseSensitivity
	Thumbstick1.Vector2Scale = create2(GAMEPAD_SCALE.X, GAMEPAD_SCALE.Y * Invert)
	Thumbstick1.Scale = UserGameSettings.GamepadCameraSensitivity
	TouchDelta.Vector2Scale = create2(TOUCH_SCALE.X, TOUCH_SCALE.Y * Invert)
end

const function UpdateInputType(): ()
	const PreferredInput = UserInputService.PreferredInput :: Enum.PreferredInput
	IsGamepad = PreferredInput == Enum.PreferredInput.Gamepad or PreferredInput == Enum.PreferredInput.MicroGamepad
	if IsGamepad == false then
		State = ZERO
	end
end

const function OnRotateStateChanged(InputState: Vector2): ()
	State = create(InputState.X, InputState.Y, 0) :: any
	if IsGamepad == false and magnitude(State) > 0 then
		RotateCamera(State, 1)
	end
end

const function OnZoomStateChanged(InputState: number): ()
	ZoomState = InputState
end

const function OnAttributeChanged(Attr: string): ()
	if Attr == "Subject" then
		UpdateSubject()
	elseif Attr == "Radius" then
		const R = Parent:GetAttribute("Radius") :: number?
		if R and R ~= Radius then
			UpdateRadius(R)
		end
	elseif Attr == "MinRadius" then
		MinRadius = (Parent:GetAttribute("MinRadius") or MinRadius) :: number
		UpdateRadius(Radius)
	elseif Attr == "MaxRadius" then
		MaxRadius = (Parent:GetAttribute("MaxRadius") or MaxRadius) :: number
		UpdateRadius(Radius)
	elseif Attr == "Offset" then
		UpdateOffset()
	end
end

@native
const function Update(dt: number): ()
	if IsGamepad and magnitude(State) > 0.001 then
		RotateCamera(State, dt)
	end

	if ZoomState ~= 0 then
		UpdateRadius(Radius * exp(-ZoomState * ZOOM_RATE * dt))
	end

	if Subject == nil or Subject.Parent == nil then
		UpdateSubject()
		if Subject == nil then
			return
		end
	end

	const Current = Subject :: BasePart | Model
	const SubjectPosition: Vector3 = if Current:IsA("BasePart")
		then Current.Position
		else Current:GetBoundingBox().Position

	local Focus = lookAlong(SubjectPosition, LookVector)
	if Offset ~= ZERO then
		Focus += Focus:VectorToWorldSpace(Offset)
	end

	Camera.CFrame = if IsFirstPerson then Focus else Focus - (LookVector * Radius)
	Camera.Focus = Focus
end

const Orbital = {} :: Types.Addon

function Orbital.Setup(): ()
	Camera.CameraType = Enum.CameraType.Scriptable

	Rotate.Enabled, Zoom.Enabled, Pan.Enabled = true, true, true

	insert(Connections, Rotate.StateChanged:Connect(OnRotateStateChanged))
	insert(Connections, Zoom.StateChanged:Connect(OnZoomStateChanged))
	insert(Connections, Parent.AttributeChanged:Connect(OnAttributeChanged))
	insert(Connections, UserInputService:GetPropertyChangedSignal("PreferredInput"):ConnectParallel(UpdateInputType))
	insert(Connections, UserGameSettings.Changed:Connect(UpdateSensitivities))
	insert(Connections, UserGameSettings.FullscreenChanged:Connect(UpdateMouseBehavior))
	insert(Connections, Pan.StateChanged:Connect(UpdateMouseBehavior))
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value, Update)

	UpdateSubject()
	UpdateOffset()
	UpdateRadius((Parent:GetAttribute("Radius") or Radius) :: number)
	UpdateInputType()
	UpdateSensitivities()
	UpdateMouseModifier()
	UpdateMouseBehavior()
	TrySendFirstPerson(IsFirstPerson)
	TrySendLookVector()
end

Orbital.Teardown = Teardown
return Orbital
