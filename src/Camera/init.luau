--!native

const Types = require(script.Types)

const Registry = {} :: { [any]: Types.Addon }

const Camera = {} :: Types.Registry

local CurrentAddon: Types.Addon? = nil

function Camera.Teardown(): ()
	const Old = CurrentAddon
	if Old == nil then
		return
	end

	const Teardown = Old.Teardown
	if Teardown then
		Teardown()
	end

	CurrentAddon, Camera.Current = nil, nil
end

function Camera.Setup(Index: any): ()
	if Index == Camera.Current then
		return
	end

	const Addon = Registry[Index]
	if Addon == nil then
		warn(`Invalid addon index {Index}`)
		return
	end

	Camera.Teardown()

	CurrentAddon, Camera.Current = Addon, Index

	const Setup = Addon.Setup
	if Setup then
		Setup()
	end
end

function Camera.Register(Index: any, Addon: Types.Addon?): ()
	Registry[Index] = Addon
end

return Camera
