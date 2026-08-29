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
	Limbs: Model,
	Animate: ModuleScript,
}

export type CharacterHandle = {
	Character: Model,
	RootPart: BasePart,
	Humanoid: Humanoid,
	ControllerManager: ControllerManager,
	GroundController: GroundController,
	AirController: AirController,
	SwimController: SwimController,
	ClimbController: ClimbController,
	GroundSensor: ControllerPartSensor,
	ClimbSensor: ControllerPartSensor,
	Animator: Animator,
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
		ZoomRate: InputAction,
		Pan: InputAction,
		LookVector: Scriptable,
		FirstPerson: Scriptable,
	},
	MovementContext: InputContext & {
		Walk: InputAction,
	},
}

return nil
