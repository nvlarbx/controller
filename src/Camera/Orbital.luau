--!native

const Types = require(script.Parent.Types)

const RunService, UserInputService =
	game:GetService("RunService") :: RunService, game:GetService("UserInputService") :: UserInputService
const UserGameSettings = UserSettings():GetService("UserGameSettings") :: UserGameSettings
const Camera = workspace.CurrentCamera :: Camera

const Player = game:GetService("Players").LocalPlayer :: Player
const InputContexts = Player:WaitForChild("InputContexts") :: Types.InputContexts
const CameraContext = InputContexts.CameraContext
const Rotate, Zoom, ZoomRate, Pan = CameraContext.Rotate, CameraContext.Zoom, CameraContext.ZoomRate, CameraContext.Pan
const MouseDelta, TouchDelta, Thumbstick1 = Rotate.MouseDelta, Rotate.TouchDelta, Rotate.Thumbstick1
const SendLookVector: InputBinding, SendFirstPerson: InputBinding =
	CameraContext.LookVector.controller, CameraContext.FirstPerson.controller

const clamp, rad, exp = math.clamp, math.rad, math.exp
const create, create2, magnitude, ZERO = vector.create, Vector2.new, vector.magnitude, vector.zero :: vector
const lookAlong, fromEulerAnglesYXZ = CFrame.lookAlong, CFrame.fromEulerAnglesYXZ
const insert = table.insert

const RENDER_STEP_NAME = "OrbitalCamera"
const ZOOM_STEP = 0.2
const ZOOM_RATE = 1 / 3
const TAU, PITCH_LIMIT = (math.pi * 2) :: number, rad(80) :: number
const MOUSE_SCALE, GAMEPAD_SCALE, TOUCH_SCALE =
	create2(0.0025, 0.0025 * 0.77, 0) :: Vector2,
	(create2(1, 0.77, 0) * rad(240)) :: Vector2,
	(create2(1, 0.66, 0) * rad(1)) :: Vector2

local MinRadius, MaxRadius = Player.CameraMinZoomDistance, Player.CameraMaxZoomDistance
local Radius = clamp(12.5, MinRadius, MaxRadius) :: number
local IsFirstPerson = (Radius <= 0.5) :: boolean
local Offset = ZERO :: Vector3

const SubjectGetters = {
	BasePart = function(Instance: any): Vector3
		return Instance.Position
	end,
	Model = function(Instance: any): Vector3
		return Instance:GetPivot().Position
	end,
} :: { [string]: (any) -> Vector3 }

local Subject: (BasePart | Model)? = nil
local GetSubjectPosition: ((any) -> Vector3)? = nil
local WarnedSubject = false
local Humanoid: Humanoid? = nil
local OffsetConnection: RBXScriptConnection? = nil
local SubjectConnection: RBXScriptConnection? = nil
local Yaw, Pitch = 0, rad(-15) :: number
local LookVector = fromEulerAnglesYXZ(Pitch, Yaw, 0).LookVector :: Vector3
local LastSentLookVector = ZERO :: Vector3
local LastSentFirstPerson = false
local IsGamepad = false

local State = ZERO :: Vector3
local ZoomRateState = 0

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

const function UpdateSubjectVisibility(): ()
	const Current = Subject
	if Current == nil then
		return
	end

	const Transparency = if IsFirstPerson then 1 else 0
	local Root: Instance = Current

	if Current:IsA("BasePart") then
		const Owner = Current.Parent
		if Owner and Owner:IsA("Model") then
			Root = Owner
		else
			Current.LocalTransparencyModifier = Transparency
			return
		end
	end

	for _, Descendant in Root:GetDescendants() do
		if Descendant:IsA("BasePart") or Descendant:IsA("Decal") then
			Descendant.LocalTransparencyModifier = Transparency
		end
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
	UpdateSubjectVisibility()
	UpdateMouseModifier()
	UpdateMouseBehavior()
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
	ZoomRateState = 0

	for _, Connection in Connections do
		Connection:Disconnect()
	end

	table.clear(Connections)

	const Offsets = OffsetConnection
	if Offsets then
		Offsets:Disconnect()
		OffsetConnection = nil
	end

	const Subjects = SubjectConnection
	if Subjects then
		Subjects:Disconnect()
		SubjectConnection = nil
	end

	Humanoid = nil
end

const function UpdateOffset(): ()
	const Current = Humanoid
	Offset = if Current then Current.CameraOffset else ZERO
end

const function BindOffset(): ()
	const Existing = OffsetConnection
	if Existing then
		Existing:Disconnect()
		OffsetConnection = nil
	end

	const Current = Humanoid
	if Current then
		OffsetConnection = Current:GetPropertyChangedSignal("CameraOffset"):Connect(UpdateOffset)
	end

	UpdateOffset()
end

local UpdateSubject: () -> ()

-- Watches the resolved subject, and keeps watching it once it goes away: a
-- streamed-out or destroyed instance is re-parented, not changed on the Camera,
-- so this connection is the only thing that can bring it back.
const function BindSubject(Watched: Instance?): ()
	const Existing = SubjectConnection
	if Existing then
		Existing:Disconnect()
		SubjectConnection = nil
	end

	if Watched then
		SubjectConnection = Watched:GetPropertyChangedSignal("Parent"):Connect(UpdateSubject)
	end
end

function UpdateSubject(): ()
	const Resolved: Instance? = Camera.CameraSubject
	local TempSubject: Instance? = Resolved

	if Resolved and Resolved:IsA("Humanoid") then
		Humanoid = Resolved
		TempSubject = Resolved.Parent
	else
		Humanoid = nil
	end

	BindOffset()

	if TempSubject then
		const Getter = if TempSubject:IsA("BasePart")
			then SubjectGetters.BasePart
			elseif TempSubject:IsA("Model") then SubjectGetters.Model
			else nil

		if Getter and TempSubject.Parent then
			Subject, GetSubjectPosition, WarnedSubject = TempSubject :: any, Getter, false
			BindSubject(TempSubject)
			UpdateSubjectVisibility()
			return
		elseif Getter == nil and WarnedSubject == false then
			WarnedSubject = true
			warn(`Subject {TempSubject.Name} of class {TempSubject.ClassName} is not treated`)
		end
	elseif WarnedSubject == false then
		WarnedSubject = true
		warn("Missing subject")
	end

	Subject, GetSubjectPosition = nil, nil
	BindSubject(TempSubject or Resolved)
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
	State = create(InputState.X, InputState.Y, 0) :: vector
	if IsGamepad == false and magnitude(State) > 0 then
		RotateCamera(State, 1)
	end
end

const function OnZoomStateChanged(InputState: number): ()
	if InputState ~= 0 then
		UpdateRadius(Radius * exp(InputState * ZOOM_STEP))
	end
end

const function OnZoomRateStateChanged(InputState: number): ()
	ZoomRateState = InputState
end

const function UpdateZoomLimits(): ()
	MinRadius, MaxRadius = Player.CameraMinZoomDistance, Player.CameraMaxZoomDistance
	UpdateRadius(Radius)
end

@native
const function Update(dt: number): ()
	if IsGamepad and magnitude(State) > 0.001 then
		RotateCamera(State, dt)
	end

	if ZoomRateState ~= 0 then
		UpdateRadius(Radius * exp(ZoomRateState * ZOOM_RATE * dt))
	end

	if Subject == nil then
		return
	end

	const SubjectPosition = (GetSubjectPosition :: (any) -> Vector3)(Subject)

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

	Rotate.Enabled, Zoom.Enabled, ZoomRate.Enabled, Pan.Enabled = true, true, true, true

	insert(Connections, Rotate.StateChanged:Connect(OnRotateStateChanged))
	insert(Connections, Zoom.StateChanged:Connect(OnZoomStateChanged))
	insert(Connections, ZoomRate.StateChanged:Connect(OnZoomRateStateChanged))
	insert(Connections, UserInputService:GetPropertyChangedSignal("PreferredInput"):ConnectParallel(UpdateInputType))
	insert(Connections, UserGameSettings.Changed:Connect(UpdateSensitivities))
	insert(Connections, UserGameSettings.FullscreenChanged:Connect(UpdateMouseBehavior))
	insert(Connections, Pan.StateChanged:Connect(UpdateMouseBehavior))
	insert(Connections, Camera:GetPropertyChangedSignal("CameraSubject"):Connect(UpdateSubject))
	insert(Connections, Player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(UpdateZoomLimits))
	insert(Connections, Player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(UpdateZoomLimits))
	RunService:BindToRenderStep(RENDER_STEP_NAME, Enum.RenderPriority.Camera.Value, Update)

	UpdateSubject()
	UpdateZoomLimits()
	UpdateInputType()
	UpdateSensitivities()
	UpdateMouseModifier()
	UpdateMouseBehavior()
	TrySendFirstPerson(IsFirstPerson)
	TrySendLookVector()
end

Orbital.Teardown = Teardown
return Orbital
