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
	AnimationController: AnimationController & {
		Animator: Animator,
	},
	Limbs: Model,
}

type Scriptable = InputAction & {
	controller: InputBinding,
}

export type InputContexts = Folder & {
	CameraContext: InputContext & {
		Rotate: InputAction & {
			MouseDelta: InputBinding,
			TouchDelta: InputBinding,
			Thumbstick1: InputBinding,
		},
		Zoom: InputAction,
		Pan: InputAction,
		LookVector: Scriptable,
		FirstPerson: Scriptable,
	},
	MovementContext: InputContext & {
		Walk: InputAction,
	},
}

return true
