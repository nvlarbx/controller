--!native

export type Character = Model & {
	HumanoidRootPart: BasePart & {
		GroundSensor: ControllerPartSensor,
		ClimbSensor: ControllerPartSensor,
	},
	ControllerManager: ControllerManager & {
		GroundController: GroundController,
		AirController: AirController,
		SwimController: SwimController,
		ClimbController: ClimbController,
	},
	Humanoid: Humanoid & {
		Animator: Animator,
	},
}

export type InputContexts = Folder & {
	CameraContext: InputContext & {
		Rotate: InputAction & {
			MouseDelta: InputBinding,
			TouchDelta: InputBinding,
			Thumbstick2: InputBinding,
			Keybinds: InputBinding,
		},
		Zoom: InputAction & {
			MouseWheel: InputBinding,
			Keybinds: InputBinding,
			ThumbsticksClicks: InputBinding,
		},
		Precise: InputAction & {
			LeftControl: InputBinding,
			ButtonL1: InputBinding,
		},
		Pan: InputAction,
		LookVector: InputAction & {
			controller: InputBinding,
		},
		AutoRotate: InputAction & {
			LeftShift: InputBinding,
			ButtonY: InputBinding,
			GuiButton: InputBinding,
			controller: InputBinding,
		},
	},
	MovementContext: InputContext & {
		Walk: InputAction & {
			Keybinds: InputBinding,
			Thumbstick1: InputBinding,
			controller: InputBinding,
		},
		Jump: InputAction & {
			Space: InputBinding,
			ButtonA: InputBinding,
			GuiButton: InputBinding,
		},
	},
}

return nil
