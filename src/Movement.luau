--!native

return function(Server: boolean): ((Player) -> ())?
	const RunService = game:GetService("RunService") :: RunService

	const create, magnitude, normalize, cross, dot =
		vector.create, vector.magnitude, vector.normalize, vector.cross, vector.dot
	const clamp = math.clamp
	const ZERO, YAXIS = vector.zero :: vector, create(0, 1, 0) :: vector
	const JUMP_SPEED, JUMP_DEBOUNCE = 50, 0.2

	const Types = require(script.Parent.Types)

	const function AlignToPlane(ToAlign: vector, PlaneNormal: vector): vector
		const Length = magnitude(ToAlign)
		if Length == 0 then
			return ToAlign
		end
		return normalize(ToAlign - PlaneNormal * dot(ToAlign, PlaneNormal)) * Length
	end

	const function Bind(Player: Player): ()
		const InputContexts = Player:WaitForChild("InputContexts") :: Types.InputContexts

		const CameraContext, MovementContext = InputContexts.CameraContext, InputContexts.MovementContext
		const LookVectorAction, AutoRotateAction, WalkAction, JumpAction =
			CameraContext.LookVector, CameraContext.AutoRotate, MovementContext.Walk, MovementContext.Jump

		local ControllerManager: ControllerManager
		local Humanoid: Humanoid?
		local GroundController: GroundController?
		local AirController: AirController?
		local GroundSensor: ControllerPartSensor?
		local SimulationStep: RBXScriptConnection?
		local JumpDebounce = 0

		local IsAutoRotate = AutoRotateAction:GetState() :: boolean
		AutoRotateAction.StateChanged:ConnectParallel(function(InputState: boolean): ()
			IsAutoRotate = InputState
		end)

		local IsJumpHeld = JumpAction:GetState() :: boolean
		JumpAction.StateChanged:Connect(function(InputState: boolean): ()
			IsJumpHeld = InputState
		end)

		local MoveVector = WalkAction:GetState() :: Vector2
		WalkAction.StateChanged:Connect(function(InputState: Vector2): ()
			MoveVector = InputState
		end)

		const function IsGrounded(): boolean
			const Sensor = GroundSensor
			return Sensor ~= nil and Sensor.SensedPart ~= nil
		end

		const function OnJump(): ()
			const Manager = ControllerManager
			const Air = AirController
			if Manager == nil or Air == nil then
				return
			end

			const Now = os.clock()
			if Now - JumpDebounce < JUMP_DEBOUNCE or IsGrounded() == false then
				return
			end

			JumpDebounce = Now

			const RootPart = Manager.RootPart
			if RootPart == nil then
				return
			end

			const Up = Manager.UpDirection :: any
			RootPart.AssemblyLinearVelocity = (RootPart.AssemblyLinearVelocity :: any)
				- Up * dot(RootPart.AssemblyLinearVelocity :: any, Up)
				+ Up * JUMP_SPEED
			Manager.ActiveController = Air
		end

		const function OnSimulationStep(): ()
			local LookVector = LookVectorAction:GetState() :: Vector3
			const UpDirection = ControllerManager.UpDirection :: any

			LookVector = AlignToPlane(LookVector, UpDirection)

			const HasLookDirection = magnitude(LookVector) > 0.001
			if HasLookDirection then
				LookVector = normalize(LookVector)
			end

			const RootPart = ControllerManager.RootPart :: BasePart

			local WorldMoveDirection = ZERO
			const CameraRightVector = cross(LookVector, YAXIS) :: any
			if MoveVector.Magnitude > 0.001 and HasLookDirection and magnitude(CameraRightVector) > 0.001 then
				WorldMoveDirection = LookVector * MoveVector.Y + normalize(CameraRightVector) * MoveVector.X
			end

			const MoveMagnitude = magnitude(WorldMoveDirection)
			const FlatMoveDirection = AlignToPlane(WorldMoveDirection, UpDirection)
			ControllerManager.MovingDirection = FlatMoveDirection

			const Ground, Air = GroundController, AirController
			if Ground and Air then
				const Grounded = IsGrounded()
				if Grounded and ControllerManager.ActiveController ~= Ground then
					if os.clock() - JumpDebounce >= JUMP_DEBOUNCE then
						ControllerManager.ActiveController = Ground
					end
				elseif Grounded == false and ControllerManager.ActiveController ~= Air then
					ControllerManager.ActiveController = Air
				end
			end

			if IsJumpHeld then
				OnJump()
			end

			const Current = Humanoid
			if Current == nil then
				return
			end

			Current:Move(WorldMoveDirection, false)

			if Current.AutoRotate == false then
				return
			end

			if IsAutoRotate and HasLookDirection then
				ControllerManager.FacingDirection = LookVector
			elseif MoveMagnitude >= 0.1 then
				if magnitude(FlatMoveDirection) > 0 then
					ControllerManager.FacingDirection = FlatMoveDirection
				end
			else
				ControllerManager.FacingDirection = RootPart.CFrame.LookVector
			end
		end

		const function CharacterAdded(Model: Model): ()
			if SimulationStep then
				SimulationStep:Disconnect()
				SimulationStep = nil
			end

			const ControllerManagerInstance = Model:WaitForChild("ControllerManager") :: ControllerManager

			ControllerManager = ControllerManagerInstance
			Humanoid = Model:FindFirstChildOfClass("Humanoid")
			GroundController = ControllerManagerInstance:FindFirstChildOfClass("GroundController")
			AirController = ControllerManagerInstance:FindFirstChildOfClass("AirController")
			GroundSensor = ControllerManagerInstance.GroundSensor :: ControllerPartSensor?
			JumpDebounce = 0

			SimulationStep = RunService:BindToSimulation(OnSimulationStep)
		end

		Player.CharacterAdded:Connect(CharacterAdded)

		const Existing = Player.Character
		if Existing then
			task.spawn(CharacterAdded, Existing)
		end
	end

	if Server then
		return Bind
	else
		const Player = game:GetService("Players").LocalPlayer :: Player

		Bind(Player)

		const UserInputService = game:GetService("UserInputService") :: UserInputService

		const InputContexts = Player:WaitForChild("InputContexts") :: Types.InputContexts
		const SendWalk: InputBinding = InputContexts.MovementContext.Walk.controller
		const JumpGui: InputBinding = InputContexts.MovementContext.Jump.GuiButton
		const AutoRotateAction = InputContexts.CameraContext.AutoRotate
		const AutoRotateGui: InputBinding = AutoRotateAction.GuiButton

		const newInstance = Instance.new
		const create2 = Vector2.new
		const fromScale, fromOffset = UDim2.fromScale, UDim2.fromOffset
		const insert = table.insert

		const DEADZONE = 0.1
		const JUMP_OFFSET, JUMP_HOVER = create2(1, 146), create2(145, 146)
		const ICON_IDLE, ICON_PRESSED = create2(0, 0), create2(0, 50)
		const STICK_SIZE = fromScale(0.4, 0.666)
		const STICK_POSITION = fromScale(0, 0.333)
		const STICK_TRAVEL = create2(STICK_SIZE.X.Scale * 0.5, STICK_SIZE.Y.Scale * 0.5)
		const FLAT = Vector2.zero :: Vector2

		local Gui: ScreenGui? = nil
		local Knob: Frame? = nil
		local LastSent = FLAT
		local DragOrigin = create2(STICK_POSITION.X.Scale, STICK_POSITION.Y.Scale)

		const Connections = table.create(4) :: { RBXScriptConnection }

		const function TrySend(Value: Vector2): ()
			if (Value - LastSent).Magnitude < 0.001 then
				return
			end

			LastSent = Value
			SendWalk:Fire(Value)
		end

		const function ToUnit(Position: UDim2): Vector2
			return create2(
				(Position.X.Scale - DragOrigin.X) / STICK_TRAVEL.X,
				(Position.Y.Scale - DragOrigin.Y) / STICK_TRAVEL.Y
			)
		end

		const function ReadKnob(): ()
			const Current = Knob
			if Current == nil then
				return
			end

			const Unit = ToUnit(Current.Position)
			const Raw = create2(Unit.X, -Unit.Y)

			const Length = Raw.Magnitude
			if Length <= DEADZONE then
				TrySend(FLAT)
				return
			end

			TrySend((Raw / Length) * clamp((Length - DEADZONE) / (1 - DEADZONE), 0, 1))
		end

		const function OnDragStart(): ()
			const Current = Knob
			if Current == nil then
				return
			end

			DragOrigin = create2(Current.Position.X.Scale, Current.Position.Y.Scale)
		end

		const function Recenter(): ()
			const Current = Knob
			if Current then
				Current.Position = STICK_POSITION
			end

			TrySend(FLAT)
		end

		const function Destroy(): ()
			for _, Connection in Connections do
				Connection:Disconnect()
			end

			table.clear(Connections)

			const Existing = Gui
			if Existing then
				Existing:Destroy()
			end

			Gui, Knob = nil, nil
			TrySend(FLAT)
		end

		const Prototype = newInstance("ScreenGui") :: ScreenGui
		Prototype.Name, Prototype.ResetOnSpawn, Prototype.ZIndexBehavior =
			"Movement", false, Enum.ZIndexBehavior.Sibling

		const ProtoStick = newInstance("Frame") :: Frame
		ProtoStick.Name, ProtoStick.Size, ProtoStick.Position, ProtoStick.BackgroundTransparency, ProtoStick.ZIndex, ProtoStick.Parent =
			"DynamicThumbstick", STICK_SIZE, STICK_POSITION, 1, 10, Prototype

		const ProtoDrag = newInstance("UIDragDetector") :: UIDragDetector
		ProtoDrag.ResponseStyle, ProtoDrag.Parent = Enum.UIDragDetectorResponseStyle.Scale, ProtoStick

		const ProtoJump = newInstance("ImageButton") :: ImageButton
		ProtoJump.Name, ProtoJump.Size, ProtoJump.Position, ProtoJump.BackgroundTransparency, ProtoJump.Image, ProtoJump.ImageRectOffset, ProtoJump.ImageRectSize, ProtoJump.ZIndex, ProtoJump.Parent =
			"JumpButton",
			fromOffset(70, 70),
			UDim2.new(1, -100, 1, -100),
			1,
			"rbxasset://textures/ui/Input/TouchControlsSheetV2.png",
			JUMP_OFFSET,
			create2(144, 144),
			10,
			Prototype

		const ProtoAutoRotate = newInstance("ImageButton") :: ImageButton
		ProtoAutoRotate.Name, ProtoAutoRotate.Size, ProtoAutoRotate.Position, ProtoAutoRotate.BackgroundTransparency, ProtoAutoRotate.Image, ProtoAutoRotate.ImageRectOffset, ProtoAutoRotate.ImageRectSize, ProtoAutoRotate.ZIndex, ProtoAutoRotate.Parent =
			"AutoRotateButton",
			fromOffset(50, 50),
			UDim2.new(1, -100, 1, -150),
			1,
			"rbxassetid://94508409872011",
			ICON_IDLE,
			create2(50, 50),
			10,
			Prototype

		const function Build(): ()
			Destroy()

			const Screen = Prototype:Clone()
			const Stick = Screen.DynamicThumbstick :: Frame
			const Drag = Stick.UIDragDetector :: UIDragDetector
			const JumpButton = Screen.JumpButton :: ImageButton
			const AutoRotateButton = Screen.AutoRotateButton :: ImageButton

			Screen.Parent = Player:WaitForChild("PlayerGui")

			JumpGui.UIButton, AutoRotateGui.UIButton = JumpButton, AutoRotateButton

			AutoRotateButton.ImageRectOffset = if AutoRotateAction:GetState() then ICON_PRESSED else ICON_IDLE

			insert(
				Connections,
				AutoRotateAction.StateChanged:Connect(function(InputState: boolean): ()
					AutoRotateButton.ImageRectOffset = if InputState then ICON_PRESSED else ICON_IDLE
				end)
			)

			insert(
				Connections,
				JumpButton.MouseEnter:Connect(function(): ()
					JumpButton.ImageRectOffset = JUMP_HOVER
				end)
			)
			insert(
				Connections,
				JumpButton.MouseLeave:Connect(function(): ()
					JumpButton.ImageRectOffset = JUMP_OFFSET
				end)
			)

			Gui, Knob = Screen, Stick

			insert(Connections, Drag.DragStart:Connect(OnDragStart))
			insert(Connections, Drag.DragContinue:Connect(ReadKnob))
			insert(Connections, Drag.DragEnd:Connect(Recenter))
		end

		const function UpdateInputType(): ()
			if UserInputService.PreferredInput == Enum.PreferredInput.Touch then
				if Gui == nil then
					Build()
				end
				return
			end

			Destroy()
		end

		UserInputService:GetPropertyChangedSignal("PreferredInput"):Connect(UpdateInputType)
		UpdateInputType()

		return
	end
end
