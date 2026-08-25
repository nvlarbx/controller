--!native

const Types = require(script.Types)

const Registry = {} :: { [number]: Types.Addon }
local CurrentAddonIndex: number? = nil
local CurrentAddon: Types.Addon? = nil

const function Change(): ()
	const AddonIndex = script:GetAttribute("Addon") :: number?

	if AddonIndex == nil or AddonIndex == CurrentAddonIndex then
		return
	end

	const Addon: Types.Addon? = Registry[AddonIndex]

	if Addon == nil then
		warn(`Invalid addon index {AddonIndex}`)
		if CurrentAddonIndex then
			script:SetAttribute("Addon", CurrentAddonIndex)
		end
		return
	end

	const Old = CurrentAddon
	if Old then
		const Teardown = Old.Teardown
		if Teardown then
			Teardown()
		end
	end

	CurrentAddon, CurrentAddonIndex = Addon, AddonIndex

	const Setup = Addon.Setup
	if Setup then
		Setup()
	end
end

script:GetAttributeChangedSignal("Addon"):Connect(Change)
task.defer(Change)

return function(Type: number, Addon: Types.Addon): ()
	Registry[Type] = Addon
end
