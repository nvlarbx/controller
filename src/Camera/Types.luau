--!native

const Root = require(script.Parent.Parent.Types)

export type Addon = {
	Setup: (() -> ())?,
	Teardown: (() -> ())?,
}

export type Registry = {
	Register: (Index: any, Addon: Addon?) -> (),
	Setup: (Index: any) -> (),
	Teardown: () -> (),
	Current: any?,
}

export type Character = Root.Character
export type InputContexts = Root.InputContexts

return true
