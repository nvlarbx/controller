const Types = require(script.Parent.Types)

return function(Server: boolean): boolean | (Player) -> ()
	const RunService = game:GetService("RunService") :: RunService

	if Server then
		const create, create2, magnitude, normalize, cross, dot =
			vector.create, Vector2.new, vector.magnitude, vector.normalize, vector.cross, vector.dot
		const ZERO, YAXIS = vector.zero :: vector, create(0, 1, 0) :: vector
		const MOVEMENT_THRESHOLD = 0.1

		@native
		const function AlignToPlane(ToAlign: vector, PlaneNormal: vector): vector
			const Length = magnitude(ToAlign)
			if Length == 0 then
				return ToAlign
			end
			return normalize(ToAlign - PlaneNormal * dot(ToAlign, PlaneNormal)) * Length
		end

		return function(Player: Player): ()
			const InputContexts = Player:FindFirstChild("InputContexts") :: Types.InputContexts
			const CameraContext, MovementContext = InputContexts.CameraContext, InputContexts.MovementContext
			const LookVectorAction, FirstPersonAction, WalkAction =
				CameraContext.LookVector, CameraContext.FirstPerson, MovementContext.Walk

			local ControllerManager: ControllerManager, GroundController: GroundController, AirController: AirController, SwimController: SwimController, ClimbController: ClimbController, ActiveController: ControllerBase
			local GroundSensor: ControllerPartSensor, ClimbSensor: ControllerPartSensor
			local SimulationStep: RBXScriptConnection?

			local IsFirstPerson = FirstPersonAction:GetState() :: boolean
			FirstPersonAction.StateChanged:Connect(function(InputState: boolean): ()
				IsFirstPerson = InputState
			end)

			@native
			const function OnSimulationStep(): ()
				local LookVector = LookVectorAction:GetState() :: Vector3
				const MoveVector = WalkAction:GetState() :: Vector2

				if ActiveController ~= SwimController then
					LookVector = AlignToPlane(LookVector, ControllerManager.UpDirection :: any)
				end

				const HasLookDirection = magnitude(LookVector) > 0.001
				if HasLookDirection then
					LookVector = normalize(LookVector)
				end

				const RootPart = ControllerManager.RootPart :: BasePart
				const IsGrounded, IsClimbing, IsSwimming =
					GroundSensor.SensedPart ~= nil,
					ClimbSensor.SensedPart ~= nil,
					RootPart.Material == Enum.Material.Water

				local WorldMoveDirection = ZERO
				const CameraRightVector = cross(LookVector, YAXIS) :: any
				if MoveVector.Magnitude > 0.001 and HasLookDirection and magnitude(CameraRightVector) > 0.001 then
					WorldMoveDirection = LookVector * MoveVector.Y + normalize(CameraRightVector) * MoveVector.X
				end

				ControllerManager.MovingDirection = WorldMoveDirection
				if IsFirstPerson and HasLookDirection then
					ControllerManager.FacingDirection = LookVector
				elseif magnitude(WorldMoveDirection) >= MOVEMENT_THRESHOLD then
					const FlatDirection = AlignToPlane(WorldMoveDirection, ControllerManager.UpDirection :: any)
					if magnitude(FlatDirection) > 0 then
						ControllerManager.FacingDirection = FlatDirection
					end
				else
					ControllerManager.FacingDirection = RootPart.CFrame.LookVector
				end

				const LocalMoveDirection = RootPart.CFrame:VectorToObjectSpace(WorldMoveDirection) :: Vector3
				ControllerManager:SetAttribute("Move", create2(LocalMoveDirection.X, -LocalMoveDirection.Z))

				const NextController: ControllerBase = if IsSwimming
					then SwimController
					elseif IsClimbing then ClimbController
					elseif IsGrounded then GroundController
					else AirController

				if ActiveController ~= NextController then
					ActiveController = NextController
					ControllerManager.ActiveController = NextController
				end
			end

			const function CharacterAdded(Model: Model): ()
				if SimulationStep then
					SimulationStep:Disconnect()
					SimulationStep = nil
				end

				const ControllerManagerInstance = (Model :: Types.Character).ControllerManager

				ControllerManager = ControllerManagerInstance
				GroundSensor, ClimbSensor =
					ControllerManager.GroundSensor :: ControllerPartSensor,
					ControllerManager.ClimbSensor :: ControllerPartSensor
				GroundController, AirController, SwimController, ClimbController =
					ControllerManagerInstance.GroundController,
					ControllerManagerInstance.AirController,
					ControllerManagerInstance.SwimController,
					ControllerManagerInstance.ClimbController
				ActiveController = ControllerManager.ActiveController :: ControllerBase

				SimulationStep = RunService:BindToSimulation(OnSimulationStep)
			end

			Player.CharacterAdded:Connect(CharacterAdded)
			if Player.Character then
				CharacterAdded(Player.Character)
			end
		end
	else
		const Player = game:GetService("Players").LocalPlayer :: Player

		Player.CharacterAdded:Connect(function(Model: Model): ()
			const Character = Model :: Types.Character
			RunService:SetPredictionMode(Character.ControllerManager, Enum.PredictionMode.On)
		end)

		return true
	end
end
