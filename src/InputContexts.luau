--!native

const newInstance = Instance.new
const InputActionType, KeyCode = Enum.InputActionType :: Enum, Enum.KeyCode :: Enum

return function(Server: boolean): ((Player) -> ())?
	if Server then
		const InputContextsTemplate = newInstance("Folder") :: Folder
		InputContextsTemplate.Name = "InputContexts"
		const MovementContext, CameraContext =
			newInstance("InputContext") :: InputContext, newInstance("InputContext") :: InputContext
		MovementContext.Name, CameraContext.Name, MovementContext.Parent, CameraContext.Parent =
			"MovementContext", "CameraContext", InputContextsTemplate, InputContextsTemplate

		const Walk, LookVector, AutoRotate =
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction
		Walk.Name, LookVector.Name, AutoRotate.Name, Walk.Parent, LookVector.Parent, AutoRotate.Parent, Walk.Type, LookVector.Type =
			"Walk",
			"LookVector",
			"AutoRotate",
			MovementContext,
			CameraContext,
			CameraContext,
			InputActionType.Direction2D,
			InputActionType.Direction3D

		const Scriptable, Keybinds =
			newInstance("InputBinding") :: InputBinding, newInstance("InputBinding") :: InputBinding
		Scriptable.Name, Scriptable.Type, Keybinds.Name, Scriptable.Parent, Keybinds.Parent, Keybinds.Up, Keybinds.Left, Keybinds.Down, Keybinds.Right =
			"controller",
			Enum.InputBindingType.Scriptable,
			"Keybinds",
			LookVector,
			Walk,
			KeyCode.W,
			KeyCode.A,
			KeyCode.S,
			KeyCode.D

		const LeftShift, ButtonY, AutoRotateGui =
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding
		LeftShift.Name, ButtonY.Name, AutoRotateGui.Name, LeftShift.Parent, ButtonY.Parent, AutoRotateGui.Parent, LeftShift.KeyCode, ButtonY.KeyCode =
			"LeftShift",
			"ButtonY",
			"GuiButton",
			AutoRotate,
			AutoRotate,
			AutoRotate,
			KeyCode.LeftShift,
			KeyCode.ButtonY

		Scriptable:Clone().Parent = AutoRotate

		const WalkThumbstick = newInstance("InputBinding") :: InputBinding
		WalkThumbstick.Name, WalkThumbstick.Parent, WalkThumbstick.KeyCode = "Thumbstick1", Walk, KeyCode.Thumbstick1

		Scriptable:Clone().Parent = Walk

		const Jump = newInstance("InputAction") :: InputAction
		Jump.Name, Jump.Type, Jump.Parent = "Jump", InputActionType.Bool, MovementContext

		const Space, ButtonA, JumpGui =
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding
		Space.Name, ButtonA.Name, JumpGui.Name, Space.Parent, ButtonA.Parent, JumpGui.Parent, Space.KeyCode, ButtonA.KeyCode =
			"Space", "ButtonA", "GuiButton", Jump, Jump, Jump, KeyCode.Space, KeyCode.ButtonA

		const Rotate, Pan, Zoom =
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction,
			newInstance("InputAction") :: InputAction
		Rotate.Name, Pan.Name, Zoom.Name, Rotate.Type, Pan.Type, Zoom.Type, Rotate.Enabled, Pan.Enabled, Zoom.Enabled, Rotate.Parent, Pan.Parent, Zoom.Parent =
			"Rotate",
			"Pan",
			"Zoom",
			InputActionType.Direction2D,
			InputActionType.Bool,
			InputActionType.Direction1D,
			false,
			false,
			false,
			CameraContext,
			CameraContext,
			CameraContext

		const MouseDelta, TouchDelta, RotateThumbstick, RotateKeybinds =
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding,
			newInstance("InputBinding") :: InputBinding
		MouseDelta.Name, TouchDelta.Name, RotateThumbstick.Name, RotateKeybinds.Name, MouseDelta.Parent, TouchDelta.Parent, RotateThumbstick.Parent, RotateKeybinds.Parent, MouseDelta.KeyCode, TouchDelta.KeyCode, RotateThumbstick.KeyCode, RotateKeybinds.Scale, RotateKeybinds.Left, RotateKeybinds.Right =
			"MouseDelta",
			"TouchDelta",
			"Thumbstick2",
			"Keybinds",
			Rotate,
			Rotate,
			Rotate,
			Rotate,
			KeyCode.MouseDelta,
			KeyCode.TouchDelta,
			KeyCode.Thumbstick2,
			0.05,
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
			Zoom,
			Zoom,
			-1,
			-1,
			KeyCode.O,
			KeyCode.I,
			KeyCode.ButtonR3,
			KeyCode.ButtonL3

		const Precise = newInstance("InputAction") :: InputAction
		Precise.Name, Precise.Type, Precise.Enabled, Precise.Parent =
			"Precise", InputActionType.Bool, false, CameraContext

		const LeftControl, ButtonL1 =
			newInstance("InputBinding") :: InputBinding, newInstance("InputBinding") :: InputBinding
		LeftControl.Name, ButtonL1.Name, LeftControl.Parent, ButtonL1.Parent, LeftControl.KeyCode, ButtonL1.KeyCode =
			"LeftControl", "ButtonL1", Precise, Precise, KeyCode.LeftControl, KeyCode.ButtonL1

		return function(Player: Player): ()
			InputContextsTemplate:Clone().Parent = Player
		end
	else
		const InputContexts = game:GetService("Players").LocalPlayer:WaitForChild("InputContexts")
		const CameraContext = InputContexts:WaitForChild("CameraContext") :: any

		const Rotate, Pan, Zoom, Precise =
			CameraContext:WaitForChild("Rotate") :: InputAction,
			CameraContext:WaitForChild("Pan") :: InputAction,
			CameraContext:WaitForChild("Zoom") :: InputAction,
			CameraContext:WaitForChild("Precise") :: InputAction

		Rotate.Enabled, Pan.Enabled, Zoom.Enabled, Precise.Enabled = true, true, true, true
	end

	return
end
