To implement, all you ***really*** need is:
- [Server Authority](https://tenebrisnoctua.github.io/ServerAuthority/)
- [InputContexts](src/InputContexts.rbxm) under Player;
- A fully wired ControllerManager under Player.Character;
- the following on *both* RunContexts:
```luau
const controller = game:GetService("ReplicatedFirst").controller
```
- the following on a *Server* RunContext:
```luau
game:GetService("Players").PlayerAdded:Connect(function(Player: Player): ()
  require(controller.Movement)(true)(Player)
end)
```
- the following on a *Client* RunContext:
```luau
require(controller.Movement)(false)

const CameraModule = controller.Camera
const Types = require(CameraModule.Types)
const RegisterCameraAddons = require(CameraModule) :: (any, Types.Addon) -> ()

RegisterCameraAddons(1, require(CameraModule.Fixed)) -- You don't even need this
```
To implement in a playable[^1] manner, head to [EXAMPLE.md](EXAMPLE.md)

[^1]: Movement prediction, an Orbital camera, animations, automatic character loading
