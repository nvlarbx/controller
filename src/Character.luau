--!native

return function(Server: boolean): ((Player) -> ())?
	if Server then
		const RunService = game:GetService("RunService") :: RunService

		game:GetService("Players").LocalPlayer.CharacterAdded:ConnectParallel(function(Character: Model): ()
			RunService:SetPredictionMode(Character, Enum.PredictionMode.On)
		end)

		return
	else
		const Types = require(script.Parent.Types)
		const newInstance = Instance.new

		const function Augment(Character: Model): Types.CharacterHandle?
			const RootPart = Character.PrimaryPart :: Part
			const Humanoid = Character:FindFirstChildOfClass("Humanoid") :: Humanoid

			local HipHeight = Humanoid.HipHeight :: number

			const GroundController = newInstance("GroundController")
			GroundController.GroundOffset = HipHeight

			const GroundSensor = newInstance("ControllerPartSensor") :: ControllerPartSensor
			GroundSensor.Name = "GroundSensor"
			GroundSensor.SensorMode = Enum.SensorMode.Floor
			GroundSensor.SearchDistance = HipHeight + 1.5
			GroundSensor.Parent = RootPart
			const ClimbSensor = newInstance("ControllerPartSensor") :: ControllerPartSensor
			ClimbSensor.Name = "ClimbSensor"
			ClimbSensor.SensorMode = Enum.SensorMode.Ladder
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

			const ControllerManager = newInstance("ControllerManager")
			ControllerManager.RootPart = RootPart
			ControllerManager.Parent = Character

			GroundController.Parent = ControllerManager
			ControllerManager.ActiveController = GroundController
			ControllerManager.GroundSensor = GroundSensor
			ControllerManager.ClimbSensor = ClimbSensor

			const AirController = newInstance("AirController")
			AirController.Parent = ControllerManager
			const SwimController = newInstance("SwimController")
			SwimController.Parent = ControllerManager
			const ClimbController = newInstance("ClimbController")
			ClimbController.Parent = ControllerManager

			const Animator = Humanoid:WaitForChild("Animator") :: Animator

			return {
				Character = Character,
				RootPart = RootPart,
				Humanoid = Humanoid,
				ControllerManager = ControllerManager,
				GroundController = GroundController,
				AirController = AirController,
				SwimController = SwimController,
				ClimbController = ClimbController,
				GroundSensor = GroundSensor,
				ClimbSensor = ClimbSensor,
				Animator = Animator,
			}
		end

		return function(Player: Player): ()
			const Existing = Player.Character :: Model?
			if Existing then
				Augment(Existing)
			end

			Player.CharacterAdded:Connect(Augment)
		end
	end
end
