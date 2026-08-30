--!native

return function(Server: boolean): ((Player) -> ())?
	if Server then
		const newInstance = Instance.new

		const BASE_TURN_SPEED = 16

		const Prototype = newInstance("ControllerManager")
		Prototype.BaseTurnSpeed = BASE_TURN_SPEED

		const ProtoGround = newInstance("GroundController")
		ProtoGround.Parent = Prototype
		Prototype.ActiveController = ProtoGround
		const ProtoAir = newInstance("AirController")
		ProtoAir.MoveMaxForce = 8181.376
		ProtoAir.Parent = Prototype
		const ProtoSwim = newInstance("SwimController")
		ProtoSwim.Parent = Prototype
		const ProtoClimb = newInstance("ClimbController")
		ProtoClimb.Parent = Prototype

		const ProtoGroundSensor = newInstance("ControllerPartSensor") :: ControllerPartSensor
		ProtoGroundSensor.Name = "GroundSensor"
		ProtoGroundSensor.SensorMode = Enum.SensorMode.Floor
		ProtoGroundSensor.Parent = Prototype
		const ProtoClimbSensor = newInstance("ControllerPartSensor") :: ControllerPartSensor
		ProtoClimbSensor.Name = "ClimbSensor"
		ProtoClimbSensor.SensorMode = Enum.SensorMode.Ladder
		ProtoClimbSensor.Parent = Prototype

		const function Augment(Character: Model): ()
			const RootPart = Character.PrimaryPart :: Part
			const Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid

			local HipHeight = Humanoid.HipHeight :: number

			const ControllerManager = Prototype:Clone()
			const GroundController = ControllerManager:FindFirstChildOfClass("GroundController") :: GroundController
			const GroundSensor = ControllerManager.GroundSensor :: ControllerPartSensor
			const ClimbSensor = ControllerManager.ClimbSensor :: ControllerPartSensor

			GroundController.GroundOffset = HipHeight
			GroundSensor.SearchDistance = HipHeight + 1.5
			GroundSensor.Parent = RootPart
			ClimbSensor.SearchDistance = 1.5 * Character:GetScale()
			ClimbSensor.Parent = RootPart

			HipHeight = nil -- TIL https://create.roblox.com/docs/luau/nil

			Humanoid:GetPropertyChangedSignal("HipHeight"):ConnectParallel(function(): ()
				HipHeight = Humanoid.HipHeight :: number
				GroundSensor.SearchDistance = HipHeight + 1.5
				GroundController.GroundOffset = HipHeight
				HipHeight = nil
			end)

			RootPart:GetPropertyChangedSignal("Size"):ConnectParallel(function(): () -- Big hax
				ClimbSensor.SearchDistance = 1.5 * Character:GetScale()
			end)

			ControllerManager.RootPart = RootPart
			ControllerManager.Parent = Character

			Humanoid.EvaluateStateMachine = false
		end

		return function(Player: Player): ()
			const Existing = Player.Character :: Model?
			if Existing then
				Augment(Existing)
			end

			Player.CharacterAdded:Connect(Augment)
		end
	else
		return
	end
end
