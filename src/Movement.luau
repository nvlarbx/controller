--!native

return function(Server: boolean): ((Player) -> ())?
	const RunService = game:GetService("RunService") :: RunService

	if Server then
		const create, magnitude, normalize, cross, dot =
			vector.create, vector.magnitude, vector.normalize, vector.cross, vector.dot
		const clamp, acos, cos, sin = math.clamp, math.acos, math.cos, math.sin
		const ZERO, YAXIS = vector.zero :: vector, create(0, 1, 0) :: vector
		const MOVEMENT_THRESHOLD, DIRECTION_EPSILON = 0.1, 0.001

		const function AlignToPlane(ToAlign: vector, PlaneNormal: vector): vector
			const Length = magnitude(ToAlign)
			if Length == 0 then
				return ToAlign
			end
			return normalize(ToAlign - PlaneNormal * dot(ToAlign, PlaneNormal)) * Length
		end

		const function RotateTowards(From: vector, To: vector, MaxAngle: number, PlaneNormal: vector): vector
			const Cosine = clamp(dot(From, To), -1, 1)
			if acos(Cosine) <= MaxAngle then
				return To
			end

			local Perpendicular = To - From * Cosine
			if magnitude(Perpendicular) < DIRECTION_EPSILON then
				Perpendicular = cross(PlaneNormal, From)
				if magnitude(Perpendicular) < DIRECTION_EPSILON then
					return To
				end
			end

			return From * cos(MaxAngle) + normalize(Perpendicular) * sin(MaxAngle)
		end

		return function(Player: Player): ()
			const Types = require(script.Parent.Types)
			const InputContexts = Player:WaitForChild("InputContexts") :: Types.InputContexts

			const CameraContext, MovementContext = InputContexts.CameraContext, InputContexts.MovementContext
			const LookVectorAction, FirstPersonAction, WalkAction =
				CameraContext.LookVector, CameraContext.FirstPerson, MovementContext.Walk

			local ControllerManager: ControllerManager
			local SimulationStep: RBXScriptConnection?
			local SmoothMoveDirection = ZERO

			local IsFirstPerson = FirstPersonAction:GetState() :: boolean
			FirstPersonAction.StateChanged:Connect(function(InputState: boolean): ()
				IsFirstPerson = InputState
			end)

			local MoveVector = WalkAction:GetState() :: Vector2
			WalkAction.StateChanged:Connect(function(InputState: Vector2): ()
				MoveVector = InputState
			end)

			const function OnSimulationStep(DeltaTime: number): ()
				local LookVector = LookVectorAction:GetState() :: Vector3
				const UpDirection = ControllerManager.UpDirection :: any

				LookVector = AlignToPlane(LookVector, UpDirection)

				const HasLookDirection = magnitude(LookVector) > DIRECTION_EPSILON
				if HasLookDirection then
					LookVector = normalize(LookVector)
				end

				const RootPart = ControllerManager.RootPart :: BasePart

				local WorldMoveDirection = ZERO
				const CameraRightVector = cross(LookVector, YAXIS) :: any
				if
					MoveVector.Magnitude > DIRECTION_EPSILON
					and HasLookDirection
					and magnitude(CameraRightVector) > DIRECTION_EPSILON
				then
					WorldMoveDirection = LookVector * MoveVector.Y + normalize(CameraRightVector) * MoveVector.X
				end

				const MoveMagnitude = magnitude(WorldMoveDirection)
				if MoveMagnitude < DIRECTION_EPSILON then
					SmoothMoveDirection = ZERO
				elseif IsFirstPerson or magnitude(SmoothMoveDirection) < DIRECTION_EPSILON then
					SmoothMoveDirection = WorldMoveDirection
				else
					SmoothMoveDirection = RotateTowards(
						normalize(SmoothMoveDirection),
						WorldMoveDirection / MoveMagnitude,
						ControllerManager.BaseTurnSpeed * DeltaTime,
						UpDirection
					) * MoveMagnitude
				end

				ControllerManager.MovingDirection = SmoothMoveDirection
				if IsFirstPerson and HasLookDirection then
					ControllerManager.FacingDirection = LookVector
				elseif MoveMagnitude >= MOVEMENT_THRESHOLD then
					const FlatDirection = AlignToPlane(SmoothMoveDirection, UpDirection)
					if magnitude(FlatDirection) > 0 then
						ControllerManager.FacingDirection = FlatDirection
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

				const ControllerManagerInstance = Model:FindFirstChildOfClass("ControllerManager")
				if ControllerManagerInstance == nil then
					return
				end

				ControllerManager = ControllerManagerInstance
				SmoothMoveDirection = ZERO

				SimulationStep = RunService:BindToSimulation(OnSimulationStep)
			end

			Player.CharacterAdded:Connect(CharacterAdded)
			if Player.Character then
				CharacterAdded(Player.Character)
			end
		end
	else
		return
	end
end
