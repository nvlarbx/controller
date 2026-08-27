--!native

export type Set = (Graph: (Animation | KeyframeSequenceProvider)?) -> ()

return function(): Set?
	const Player = game:GetService("Players").LocalPlayer :: Player

	const magnitude, normalize, cross, dot = vector.magnitude, vector.normalize, vector.cross, vector.dot
	const DIRECTION_EPSILON = 0.001

	local Animator: Animator? = nil
	local ControllerManager: ControllerManager? = nil
	local Source: (Animation | KeyframeSequenceProvider)? = nil
	local Track: AnimationTrack? = nil
	const Connections = table.create(2) :: { RBXScriptConnection }

	const function StopTrack(): ()
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
	end

	const function UpdateBlend(): ()
		const Manager, Current = ControllerManager, Track
		if Manager == nil or Current == nil then
			return
		end

		const Moving = Manager.MovingDirection :: any
		const Speed = magnitude(Moving)
		if Speed < DIRECTION_EPSILON then
			Current:SetParameter("x", 0)
			Current:SetParameter("y", 0)
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

		Current:SetParameter("x", dot(Moving, Right))
		Current:SetParameter("y", dot(Moving, Facing))
	end

	const function Bind(Character: Model): ()
		for _, Connection in Connections do
			Connection:Disconnect()
		end
		table.clear(Connections)

		StopTrack()

		const Humanoid = Character:WaitForChild("Humanoid") :: Humanoid
		Animator = Humanoid:WaitForChild("Animator") :: Animator
		ControllerManager = Character:FindFirstChildOfClass("ControllerManager")

		LoadTrack()

		const Manager = ControllerManager
		if Manager then
			table.insert(Connections, Manager:GetPropertyChangedSignal("MovingDirection"):Connect(UpdateBlend))
			table.insert(Connections, Manager:GetPropertyChangedSignal("FacingDirection"):Connect(UpdateBlend))
			UpdateBlend()
		end
	end

	Player.CharacterAdded:Connect(Bind)

	const Existing = Player.Character
	if Existing then
		task.spawn(Bind, Existing)
	end

	return function(Graph: (Animation | KeyframeSequenceProvider)?): ()
		Source = Graph
		LoadTrack()
		UpdateBlend()
	end
end
