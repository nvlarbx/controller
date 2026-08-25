--!native

const Root = require(script.Parent.Parent.Types)

export type Addon = {
	Setup: (() -> ())?,
	Teardown: (() -> ())?,
}

export type Character = Root.Character
export type InputContexts = Root.InputContexts

return true
