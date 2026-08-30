--!native

const Types = require(script.Parent.Types)

const RunService, UserInputService =
	game:GetService("RunService") :: RunService, game:GetService("UserInputService") :: UserInputService
const UserGameSettings = UserSettings():GetService("UserGameSettings") :: UserGameSettings
const Camera = workspace.CurrentCamera :: Camera

const Player = game:GetService("Players").LocalPlayer :: Player
const InputContexts = Player:WaitForChild("InputContexts") :: Types.InputContexts
const CameraContext = InputContexts.CameraContext
const Rotate, Zoom, Pan, Precise = CameraContext.Rotate, CameraContext.Zoom, CameraContext.Pan, CameraContext.Precise
const MouseDelta, TouchDelta, Thumbstick2 = Rotate.MouseDelta, Rotate.TouchDelta, Rotate.Thumbstick2
const MouseWheel = Zoom.MouseWheel
const SendLookVector: InputBinding, SendAutoRotate: InputBinding =
	CameraContext.LookVector.controller, CameraContext.AutoRotate.controller

const clamp, rad, exp, abs = math.clamp, math.rad, math.exp, math.abs
const create, create2, magnitude, ZERO = vector.create, Vector2.new, vector.magnitude, vector.zero :: vector
const lookAlong, fromEulerAnglesYXZ = CFrame.lookAlong, CFrame.fromEulerAnglesYXZ
const insert = table.insert

const FIRST_PERSON_RADIUS = 1.2 :: number
const WHEEL_SCALE, WHEEL_PRECISE_SCALE = -0.2 :: number, -0.01 :: number
const PRECISE_FACTOR = 0.05 :: number
const MOUSE_CURVE, MOUSE_CURVE_ANCHOR = 0.4 :: number, 0.01 :: number
const PI, TAU, PITCH_LIMIT = math.pi :: number, (math.pi * 2) :: number, rad(80) :: number
const MOUSE_SCALE, GAMEPAD_SCALE, TOUCH_SCALE =
	create2(0.0025, 0.0025 * 0.77, 0) :: Vector2,
	(create2(1, 0.77, 0) * rad(240)) :: Vector2,
	(create2(0.0035, 0.0035 * 0.66, 0)) :: Vector2

local RotateSmooth = 30 :: number
local ZoomSmooth = 10 :: number
local ZoomRate = 0.06 :: number
local ZoomCurvature = 0.5 :: number
local KeyboardRate = 60 :: number
local ZoomKeyboardRate = 40 :: number
local MouseSensitivity = 1 :: number
local GamepadSensitivity = 1 :: number
local TouchSensitivity = 1 :: number
local TouchRotateScale = 0.2 :: number
local MinRadius, MaxRadius = Player.CameraMinZoomDistance, Player.CameraMaxZoomDistance
local Radius = clamp(12.5, MinRadius, MaxRadius) :: number
local TargetRadius = Radius
local IsFirstPerson = (Radius <= FIRST_PERSON_RADIUS) :: boolean
local Offset = ZERO :: Vector3

const SubjectGetters = {
	BasePart = function(Instance: any): Vector3
		return Instance.Position
	end,
	Model = function(Instance: any): Vector3
		return Instance:GetPivot().Position
	end,
	Attachment = function(Instance: any): Vector3
		return Instance.WorldPosition
	end,
} :: { [string]: (any) -> Vector3 }

const SubjectFrames = {
	BasePart = function(Instance: any): CFrame
		return Instance.CFrame
	end,
	Model = function(Instance: any): CFrame
		return Instance:GetPivot()
	end,
	Attachment = function(Instance: any): CFrame
		return Instance.WorldCFrame
	end,
} :: { [string]: (any) -> CFrame }

local Subject: (BasePart | Model | Attachment)? = nil
local HiddenSubject: Instance? = nil
local GetSubjectPosition: ((any) -> Vector3)? = nil
local GetSubjectFrame: ((any) -> CFrame)? = nil
local WarnedSubject = false
local Humanoid: Humanoid? = nil
local OffsetConnection: RBXScriptConnection? = nil
local HumanoidConnection: RBXScriptConnection? = nil
local SubjectConnection: RBXScriptConnection? = nil
local Yaw, Pitch = 0, rad(-15) :: number
local TargetYaw, TargetPitch = Yaw, Pitch
local LookVector = fromEulerAnglesYXZ(Pitch, Yaw, 0).LookVector :: vector
local LastSentLookVector = ZERO :: vector
local IsGamepad = false
local IsTouch = false
local IsPrecise = false
local PreciseRate = 1 :: number

local State = ZERO :: vector
local KeyboardState = ZERO :: vector
local HeldZoom = 0 :: number

const Connections = table.create(8) :: { RBXScriptConnection }

const function TrySendLookVector(): ()
	if magnitude(LookVector - LastSentLookVector) > 0.001 then
		LastSentLookVector = LookVector
		SendLookVector:Fire(LookVector)
	end
end

const function ApplyVisibility(Target: Instance?, Transparency: number): ()
	if Target == nil then
		return
	end

	if Target:IsA("BasePart") then
		Target.LocalTransparencyModifier = Transparency
	end

	for _, Descendant: Instance in Target:GetDescendants() do
		if Descendant:IsA("Decal") then
			Descendant.LocalTransparencyModifier = Transparency
		end
	end
end

const function UpdateSubjectVisibility(): ()
	const Target: Instance? = if Subject and Subject:IsA("Attachment") then Subject.Parent else Subject

	if HiddenSubject ~= Target then
		ApplyVisibility(HiddenSubject, 0)
		HiddenSubject = Target
	end

	ApplyVisibility(Target, if IsFirstPerson then 1 else 0)
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

const function ApplyRadius(NewRadius: number): ()
	Radius = NewRadius
	const NowFirstPerson = Radius <= FIRST_PERSON_RADIUS
	if NowFirstPerson ~= IsFirstPerson then
		IsFirstPerson = NowFirstPerson
		SendAutoRotate:Fire(IsFirstPerson)
		UpdateSubjectVisibility()
		UpdateMouseModifier()
		UpdateMouseBehavior()
	end
end

const function UpdateRadius(NewRadius: number): ()
	const Clamped = clamp(NewRadius, MinRadius, MaxRadius)
	if Clamped >= FIRST_PERSON_RADIUS then
		TargetRadius = Clamped
		return
	end

	TargetRadius = if NewRadius > TargetRadius then FIRST_PERSON_RADIUS else MinRadius
end

const function SnapRadius(NewRadius: number): ()
	TargetRadius = clamp(NewRadius, MinRadius, MaxRadius)
	ApplyRadius(TargetRadius)
end

const function RotateCamera(Delta: Vector3, Scale: number): ()
	TargetYaw = (TargetYaw - (Delta.X * Scale)) % TAU
	TargetPitch = clamp(TargetPitch - (Delta.Y * Scale), -PITCH_LIMIT, PITCH_LIMIT)
end

const function StepRotation(dt: number): ()
	const DeltaYaw = (((TargetYaw - Yaw) + PI) % TAU) - PI
	const DeltaPitch = TargetPitch - Pitch

	if abs(DeltaYaw) < 0.001 and abs(DeltaPitch) < 0.001 then
		if Yaw ~= TargetYaw or Pitch ~= TargetPitch then
			Yaw, Pitch = TargetYaw, TargetPitch
			LookVector = fromEulerAnglesYXZ(Pitch, Yaw, 0).LookVector
			TrySendLookVector()
		end
		return
	end

	const Alpha = 1 - exp(-RotateSmooth * dt)
	Yaw = (Yaw + (DeltaYaw * Alpha)) % TAU
	Pitch = Pitch + (DeltaPitch * Alpha)
	LookVector = fromEulerAnglesYXZ(Pitch, Yaw, 0).LookVector
	TrySendLookVector()
end

const function Teardown(): ()
	if IsFirstPerson then
		SendAutoRotate:Fire(false)
	end

	UserInputService.MouseBehavior = Enum.MouseBehavior.Default
	RunService:UnbindFromRenderStep("OrbitalCamera")
	TargetRadius = Radius

	for _, Connection in Connections do
		Connection:Disconnect()
	end

	table.clear(Connections)

	const Offsets = OffsetConnection
	if Offsets then
		Offsets:Disconnect()
		OffsetConnection = nil
	end

	const Humanoids = HumanoidConnection
	if Humanoids then
		Humanoids:Disconnect()
		HumanoidConnection = nil
	end

	const Subjects = SubjectConnection
	if Subjects then
		Subjects:Disconnect()
		SubjectConnection = nil
	end

	Humanoid = nil
end

local UpdateSubject: () -> ()

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

	const Humanoids = HumanoidConnection
	if Humanoids then
		Humanoids:Disconnect()
		HumanoidConnection = nil
	end

	const Current = Humanoid
	if Current then
		OffsetConnection = Current:GetPropertyChangedSignal("CameraOffset"):Connect(UpdateOffset)
		HumanoidConnection = Current.AncestryChanged:Connect(UpdateSubject)
	end

	UpdateOffset()
end

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

		const Character = Resolved.Parent
		const Head = if Character then Character:FindFirstChild("Head") else nil
		const Face = if Head then Head:FindFirstChild("FaceFrontAttachment") else nil

		TempSubject = if Face and Face:IsA("Attachment") then Face else Head or Character
	elseif Resolved then
		const Owner = Resolved.Parent
		Humanoid = if Owner then Owner:FindFirstChildOfClass("Humanoid") else nil
	else
		Humanoid = nil
	end

	if TempSubject then
		const Key = if TempSubject:IsA("Attachment")
			then "Attachment"
			elseif TempSubject:IsA("BasePart") then "BasePart"
			elseif TempSubject:IsA("Model") then "Model"
			else nil
		const Getter = if Key then SubjectGetters[Key] else nil

		if Getter and Key and TempSubject.Parent then
			Subject, GetSubjectPosition, GetSubjectFrame, WarnedSubject =
				TempSubject :: any, Getter, SubjectFrames[Key], false
			BindSubject(TempSubject)
			BindOffset()
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

	Subject, GetSubjectPosition, GetSubjectFrame = nil, nil, nil
	BindSubject(TempSubject or Resolved)
	BindOffset()
	UpdateSubjectVisibility()
end

const function UpdateSensitivities(): ()
	const Invert = UserGameSettings:GetCameraYInvertValue() :: number
	MouseDelta.Vector2Scale = create2(MOUSE_SCALE.X, MOUSE_SCALE.Y * Invert)
	const Fine = if IsPrecise then PRECISE_FACTOR else 1
	MouseDelta.Scale = MOUSE_CURVE_ANCHOR
		* (UserGameSettings.MouseSensitivity ^ MOUSE_CURVE)
		* MouseSensitivity
		* Fine
	Thumbstick2.Vector2Scale = create2(GAMEPAD_SCALE.X, GAMEPAD_SCALE.Y * Invert)
	Thumbstick2.Scale = UserGameSettings.GamepadCameraSensitivity * GamepadSensitivity * Fine
	MouseWheel.Scale = (if IsPrecise then WHEEL_PRECISE_SCALE else WHEEL_SCALE) * MouseSensitivity
	TouchDelta.Vector2Scale = create2(TOUCH_SCALE.X, TOUCH_SCALE.Y * Invert)
	TouchDelta.Scale = TouchRotateScale * TouchSensitivity
	PreciseRate = Fine
end

const function ReadNumber(Key: string, Default: number): number
	const Value = Camera:GetAttribute(Key)
	return if type(Value) == "number" then Value else Default
end

const function ReadSettings(): ()
	RotateSmooth = ReadNumber("RotateSmooth", 30)
	ZoomSmooth = ReadNumber("ZoomSmooth", 10)
	ZoomRate = ReadNumber("ZoomRate", 0.06)
	ZoomCurvature = ReadNumber("ZoomCurvature", 0.5)
	KeyboardRate = ReadNumber("KeyboardRate", 60)
	ZoomKeyboardRate = ReadNumber("ZoomKeyboardRate", 40)
	MouseSensitivity = ReadNumber("MouseSensitivity", 1)
	GamepadSensitivity = ReadNumber("GamepadSensitivity", 1)
	TouchSensitivity = ReadNumber("TouchSensitivity", 1)
	TouchRotateScale = ReadNumber("TouchRotateScale", 0.2)
end

const RATE_KEYS = {
	"RotateSmooth",
	"ZoomSmooth",
	"ZoomRate",
	"ZoomCurvature",
	"KeyboardRate",
	"ZoomKeyboardRate",
} :: { string }

const SENSITIVITY_KEYS = {
	"MouseSensitivity",
	"GamepadSensitivity",
	"TouchSensitivity",
	"TouchRotateScale",
} :: { string }

const function OnSensitivityChanged(): ()
	ReadSettings()
	UpdateSensitivities()
end

const function OnRadiusChanged(): ()
	const Value = Camera:GetAttribute("Radius")
	if type(Value) == "number" then
		SnapRadius(Value)
	end
end

const function OnPreciseStateChanged(InputState: boolean): ()
	IsPrecise = InputState
	UpdateSensitivities()
end

const function UpdateInputType(): ()
	const PreferredInput = UserInputService.PreferredInput :: Enum.PreferredInput
	IsGamepad = PreferredInput == Enum.PreferredInput.Gamepad or PreferredInput == Enum.PreferredInput.MicroGamepad
	IsTouch = PreferredInput == Enum.PreferredInput.Touch
	if IsGamepad == false then
		State = ZERO
	end
	if IsGamepad or IsTouch then
		KeyboardState = ZERO
		HeldZoom = 0
	end
end

const function OnRotateStateChanged(InputState: Vector2): ()
	State = create(InputState.X, InputState.Y, 0) :: vector
	if IsGamepad then
		return
	end

	const Preferred = Rotate.PreferredBinding
	if Preferred == MouseDelta or Preferred == TouchDelta then
		KeyboardState = ZERO

		if magnitude(State) > 0 then
			RotateCamera(State, 1)
		end
		return
	end

	KeyboardState = State
end

const function StepZoom(InputState: number): ()
	if IsTouch then
		UpdateRadius(TargetRadius + InputState)
		return
	end

	const Step = InputState * ZoomRate
	UpdateRadius(
		if Step > 0
			then TargetRadius + Step * (1 + TargetRadius * ZoomCurvature)
			else (TargetRadius + Step) / (1 - Step * ZoomCurvature)
	)
end

const function OnZoomStateChanged(InputState: number): ()
	if Zoom.PreferredBinding == MouseWheel then
		HeldZoom = 0

		if InputState ~= 0 then
			StepZoom(InputState)
		end
		return
	end

	HeldZoom = if InputState > 0 then 1 elseif InputState < 0 then -1 else 0
end

const function UpdateZoomLimits(): ()
	MinRadius = Player.CameraMinZoomDistance
	MaxRadius = Player.CameraMaxZoomDistance
	SnapRadius(Radius)
end

const function Update(dt: number): ()
	if IsGamepad and magnitude(State) > 0.001 then
		RotateCamera(State, dt)
	end

	if magnitude(KeyboardState) > 0.001 then
		RotateCamera(KeyboardState, KeyboardRate * PreciseRate * dt)
	end

	if HeldZoom ~= 0 then
		StepZoom(HeldZoom * ZoomKeyboardRate * PreciseRate * dt)
	end

	StepRotation(dt)

	if Radius ~= TargetRadius then
		const Alpha = 1 - exp(-ZoomSmooth * dt)
		const Next = Radius + ((TargetRadius - Radius) * Alpha)
		ApplyRadius(if abs(TargetRadius - Next) <= 0.001 then TargetRadius else Next)
	end

	if Subject == nil then
		return
	end

	const SubjectPosition = (GetSubjectPosition :: (any) -> Vector3)(Subject)

	local Focus = lookAlong(SubjectPosition, LookVector)
	if Offset ~= ZERO then
		const Frame = if Humanoid and Humanoid.RootPart
			then Humanoid.RootPart.CFrame
			elseif GetSubjectFrame then (GetSubjectFrame :: (any) -> CFrame)(Subject)
			else nil

		Focus += if Frame then Frame:VectorToWorldSpace(Offset) else Offset
	end
	Camera.CFrame = if IsFirstPerson then Focus else Focus - (LookVector * Radius)
	Camera.Focus = Focus
end

const Orbital = {} :: Types.Addon

function Orbital.Setup(): ()
	Camera.CameraType = Enum.CameraType.Scriptable

	Rotate.Enabled, Zoom.Enabled, Pan.Enabled, Precise.Enabled = true, true, true, true

	insert(Connections, Rotate.StateChanged:Connect(OnRotateStateChanged))
	insert(Connections, Zoom.StateChanged:Connect(OnZoomStateChanged))
	insert(Connections, Precise.StateChanged:Connect(OnPreciseStateChanged))
	insert(Connections, UserInputService:GetPropertyChangedSignal("PreferredInput"):ConnectParallel(UpdateInputType))
	insert(Connections, UserGameSettings.Changed:Connect(UpdateSensitivities))
	insert(Connections, UserGameSettings.FullscreenChanged:Connect(UpdateMouseBehavior))
	insert(Connections, Pan.StateChanged:Connect(UpdateMouseBehavior))
	insert(Connections, Camera:GetPropertyChangedSignal("CameraSubject"):Connect(UpdateSubject))
	insert(Connections, Player:GetPropertyChangedSignal("CameraMinZoomDistance"):Connect(UpdateZoomLimits))
	insert(Connections, Player:GetPropertyChangedSignal("CameraMaxZoomDistance"):Connect(UpdateZoomLimits))
	insert(Connections, Camera:GetAttributeChangedSignal("Radius"):Connect(OnRadiusChanged))

	for _, Key in RATE_KEYS do
		insert(Connections, Camera:GetAttributeChangedSignal(Key):Connect(ReadSettings))
	end

	for _, Key in SENSITIVITY_KEYS do
		insert(Connections, Camera:GetAttributeChangedSignal(Key):Connect(OnSensitivityChanged))
	end

	RunService:BindToRenderStep("OrbitalCamera", Enum.RenderPriority.Camera.Value, Update)

	IsPrecise = Precise:GetState() :: boolean
	ReadSettings()

	UpdateSubject()
	UpdateZoomLimits()
	UpdateInputType()
	UpdateSensitivities()
	UpdateMouseModifier()
	UpdateMouseBehavior()
	SendAutoRotate:Fire(IsFirstPerson)
	TrySendLookVector()
end

Orbital.Teardown = Teardown
return Orbital
