--!native

const newInstance = Instance.new
const InputActionType, KeyCode = Enum.InputActionType, Enum.KeyCode

return function(Server: boolean): ((Player) -> ())?
	if Server then
		const InputContextsTemplate = newInstance("Folder") :: Folder
		InputContextsTemplate.Name = "InputContexts"
		const MovementContext, CameraContext =
			newInstance("InputContext") :: InputContext, newInstance("InputContext") :: InputContext
		MovementContext.Name, CameraContext.Name, MovementContext.Parent, CameraContext.Parent =
			"MovementContext", "CameraContext", InputContextsTemplate, InputContextsTemplate
		const Walk, LookVector, FirstPerson =
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction
		Walk.Name, LookVector.Name, FirstPerson.Name, Walk.Parent, LookVector.Parent, FirstPerson.Parent, Walk.Type, LookVector.Type =
			"Walk",
			"LookVector",
			"FirstPerson",
			MovementContext,
			CameraContext,
			CameraContext,
			Enum.InputActionType.Direction2D,
			Enum.InputActionType.Direction3D
		const Scriptable, Keybinds =
			newInstance("InputBinding") :: InputBinding, newInstance("InputBinding") :: InputBinding
		Scriptable.Name, Keybinds.Name, Scriptable.Parent, Keybinds.Parent, Keybinds.Up, Keybinds.Left, Keybinds.Down, Keybinds.Right =
			"controller", "Keybinds", LookVector, Walk, Enum.KeyCode.W, Enum.KeyCode.A, Enum.KeyCode.S, Enum.KeyCode.D
		Scriptable:Clone().Parent = FirstPerson

		return function(Player: Player): ()
			InputContextsTemplate:Clone().Parent = Player
		end
	else
		const Types = require(script.Parent.Types)

		const CameraContext = (
			game:GetService("Players").LocalPlayer:WaitForChild("InputContexts") :: Types.InputContexts
		).CameraContext

		const Rotate, Pan, Zoom, ZoomRate =
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction
		Rotate.Name, Pan.Name, Zoom.Name, ZoomRate.Name, Rotate.Type, Pan.Type, Zoom.Type, ZoomRate.Type, Rotate.Enabled, Pan.Enabled, Zoom.Enabled, ZoomRate.Enabled =
			"Rotate",
			"Pan",
			"Zoom",
			"ZoomRate",
			InputActionType.Direction2D,
			InputActionType.Bool,
			InputActionType.Direction1D,
			InputActionType.Direction1D,
			false,
			false,
			false,
			false

		const MouseDelta, TouchDelta, Thumbstick1, RotateKeybinds =
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding
		MouseDelta.Name, TouchDelta.Name, Thumbstick1.Name, RotateKeybinds.Name, MouseDelta.Parent, TouchDelta.Parent, Thumbstick1.Parent, RotateKeybinds.Parent, MouseDelta.KeyCode, TouchDelta.KeyCode, Thumbstick1.KeyCode, RotateKeybinds.Scale, RotateKeybinds.Left, RotateKeybinds.Right =
			"MouseDelta",
			"TouchDelta",
			"Thumbstick1",
			"Keybinds",
			Rotate,
			Rotate,
			Rotate,
			Rotate,
			KeyCode.MouseDelta,
			KeyCode.TouchDelta,
			KeyCode.Thumbstick1,
			2,
			KeyCode.Left,
			KeyCode.Right

		const MouseRightButton, TouchPosition =
			newInstance("InputBinding") :: InputBinding, newInstance("InputBinding") :: InputBinding
		MouseRightButton.Name, TouchPosition.Name, MouseRightButton.Parent, TouchPosition.Parent, MouseRightButton.KeyCode, TouchPosition.KeyCode =
			"MouseRightButton", "TouchPosition", Pan, Pan, KeyCode.MouseRightButton, KeyCode.TouchPosition

		const MouseWheel, TrackpadPinch, TouchPinch =
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding
		MouseWheel.Name, TrackpadPinch.Name, TouchPinch.Name, MouseWheel.Parent, TrackpadPinch.Parent, TouchPinch.Parent, MouseWheel.KeyCode, TrackpadPinch.KeyCode, TouchPinch.KeyCode, MouseWheel.Scale, TrackpadPinch.Scale, TouchPinch.Scale =
			"MouseWheel",
			"TrackpadPinch",
			"TouchPinch",
			Zoom,
			Zoom,
			Zoom,
			KeyCode.MouseWheel,
			KeyCode.TrackpadPinch,
			KeyCode.TouchPinch,
			-1,
			-1,
			-0.04

		const ZoomKeybinds, ThumbsticksClicks =
			newInstance("InputBinding") :: InputBinding, newInstance("InputBinding") :: InputBinding
		ZoomKeybinds.Name, ThumbsticksClicks.Name, ZoomKeybinds.Parent, ThumbsticksClicks.Parent, ZoomKeybinds.Scale, ThumbsticksClicks.Scale, ZoomKeybinds.Up, ZoomKeybinds.Down, ThumbsticksClicks.Up, ThumbsticksClicks.Down =
			"Keybinds",
			"ThumbsticksClicks",
			ZoomRate,
			ZoomRate,
			6,
			6,
			KeyCode.O,
			KeyCode.I,
			KeyCode.ButtonR3,
			KeyCode.ButtonL3

		Rotate.Parent, Pan.Parent, Zoom.Parent, ZoomRate.Parent =
			CameraContext, CameraContext, CameraContext, CameraContext
	end

	return
end
