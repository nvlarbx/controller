--!native

return function(Server: boolean): ((Player) -> ())?
	const RunService = game:GetService("RunService") :: RunService

	if Server == false then
		const LocalPlayer = game:GetService("Players").LocalPlayer :: Player

		const function Predict(Character: Model): ()
			const Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
			const Animator = Humanoid:WaitForChild("Animator") :: Animator
			RunService:SetPredictionMode(Animator, Enum.PredictionMode.On)
		end

		LocalPlayer.CharacterAdded:Connect(Predict)

		const Existing = LocalPlayer.Character
		if Existing then
			task.spawn(Predict, Existing)
		end

		return
	end

	const FadeSignal = RunService.PostSimulation

	const magnitude, normalize, cross, dot = vector.magnitude, vector.normalize, vector.cross, vector.dot
	const min = math.min
	const DIRECTION_EPSILON = 0.001
	const R6_BLEND_FADE_TIME = 0.1
	const R15_BLEND_FADE_TIME = 0.2
	const GRAPH_ID = "rbxassetid://97691881768110"
	const newInstance = Instance.new

	const Source = newInstance("Animation") :: Animation
	Source.AnimationId = GRAPH_ID

	const function CreateRig(): (Model) -> ()
		local Animator: Animator? = nil
		local ControllerManager: ControllerManager? = nil
		local Track: AnimationTrack? = nil
		local BlendFadeTime = R6_BLEND_FADE_TIME
		local BlendX, BlendY = 0, 0
		local TargetBlendX, TargetBlendY = 0, 0
		local FadeConnection: RBXScriptConnection? = nil
		const Connections = table.create(2) :: { RBXScriptConnection }

		const function StopFade(): ()
			const Connection = FadeConnection
			if Connection then
				Connection:Disconnect()
				FadeConnection = nil
			end
		end

		const function ApplyBlend(): ()
			const Current = Track
			if Current then
				Current:SetParameter("x", BlendX)
				Current:SetParameter("y", BlendY)
			end
		end

		const function ResetBlend(): ()
			StopFade()
			BlendX, BlendY = 0, 0
			TargetBlendX, TargetBlendY = 0, 0
		end

		const function FadeBlend(X: number, Y: number): ()
			if FadeConnection and X == TargetBlendX and Y == TargetBlendY then
				return
			end

			StopFade()
			TargetBlendX, TargetBlendY = X, Y

			const StartX, StartY = BlendX, BlendY
			if StartX == X and StartY == Y then
				ApplyBlend()
				return
			end

			local Elapsed = 0
			const FadeTime = BlendFadeTime
			FadeConnection = FadeSignal:Connect(function(DeltaTime: number): ()
				Elapsed += DeltaTime
				const Alpha = min(Elapsed / FadeTime, 1)
				BlendX = StartX + (X - StartX) * Alpha
				BlendY = StartY + (Y - StartY) * Alpha
				ApplyBlend()

				if Alpha >= 1 then
					StopFade()
				end
			end)
		end

		const function StopTrack(): ()
			ResetBlend()

			const Current = Track
			if Current then
				Current:Stop()
				Current:Destroy()
				Track = nil
			end
		end

		const function LoadTrack(): ()
			StopTrack()

			const Target, Graph = Animator, Source
			if Target == nil or Graph == nil then
				return
			end

			const Loaded = Target:LoadAnimation(Graph :: any)
			Loaded:Play()
			Track = Loaded
			ApplyBlend()
		end

		const function UpdateBlend(): ()
			const Manager, Current = ControllerManager, Track
			if Manager == nil or Current == nil then
				return
			end

			const Moving = Manager.MovingDirection :: any
			const Speed = magnitude(Moving)
			if Speed < DIRECTION_EPSILON then
				FadeBlend(0, 0)
				return
			end

			const Up = Manager.UpDirection :: any
			local Facing = Manager.FacingDirection :: any
			Facing = Facing - Up * dot(Facing, Up)
			if magnitude(Facing) < DIRECTION_EPSILON then
				return
			end
			Facing = normalize(Facing)

			const Right = normalize(cross(Facing, Up)) :: any

			FadeBlend(dot(Moving, Right), dot(Moving, Facing))
		end

		const function Bind(Character: Model): ()
			for _, Connection in Connections do
				Connection:Disconnect()
			end
			table.clear(Connections)

			StopTrack()

			const Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
			BlendFadeTime =
				if Humanoid.RigType == Enum.HumanoidRigType.R6 then R6_BLEND_FADE_TIME else R15_BLEND_FADE_TIME
			Animator = Humanoid:WaitForChild("Animator") :: Animator
			ControllerManager = Character:WaitForChild("ControllerManager") :: ControllerManager

			LoadTrack()

			const Manager = ControllerManager
			if Manager then
				table.insert(Connections, Manager:GetPropertyChangedSignal("MovingDirection"):Connect(UpdateBlend))
				table.insert(Connections, Manager:GetPropertyChangedSignal("FacingDirection"):Connect(UpdateBlend))
				UpdateBlend()
			end
		end

		return Bind
	end

	const function Setup(Player: Player): ()
		const Bind = CreateRig()

		Player.CharacterAdded:Connect(Bind)

		const Existing = Player.Character
		if Existing then
			task.spawn(Bind, Existing)
		end
	end

	return Setup
end
