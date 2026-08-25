--!native

const Types = require(script.Parent.Types)

const Player = game:GetService("Players").LocalPlayer :: Player
const InputContexts = Player:WaitForChild("InputContexts") :: Types.InputContexts
const CameraContext = InputContexts.CameraContext

const Rotate: InputAction, Zoom: InputAction, Pan: InputAction =
	CameraContext.Rotate, CameraContext.Zoom, CameraContext.Pan

return {
	Setup = function(): ()
		Rotate.Enabled, Zoom.Enabled, Pan.Enabled = false, false, false
	end,
} :: Types.Addon
