###### Dotted = optional; solid = required

```mermaid
---
config:
  theme: neutral
  layout: dagre
---
flowchart TB
 subgraph s1["Camera"]
        n4["Fixed"]
        n6["Orbital"]
        n2["Register"]
  end
 subgraph s2["Character"]
        n8["Setup"]
        n9["Movement"]
        n10["Animations"]
  end
    n8 -.-> n9
    n2 -.-> n4 & n6
    n1["Your implementation"] -.-> n7["InputContexts"] & s1 & s2
    n7 --> n6 & n9
    n7 -.-> n4
    n6 -.-> n9
    n9 --> n10
    n8 --> n10

    n1@{ shape: rect}
    n7@{ shape: rect}
```

To fully implement, all you need is:
- [workspace.AuthorityMode = Enum.AuthorityMode.Server](https://tenebrisnoctua.github.io/ServerAuthority/)
- the following on *both* RunContexts:
```luau
const controller = game:GetService("ReplicatedFirst").controller
```
- the following on a *Server* RunContext:
```luau
const CreateInputContexts = require(controller.InputContexts)(true)
const Movement = require(controller.Movement)(true)

game:GetService("Players").PlayerAdded:Connect(function(Player: Player): ()
  CreateInputContexts(Player)
  Movement(Player)
end)
```
> [!IMPORTANT]
> Call the factories once, outside `PlayerAdded` — calling `(true)` per player
> rebuilds the layout every time

- the following on a *Client* RunContext:
```luau
require(controller.InputContexts)(false)
require(controller.Character)(false)

const SetAnimation = require(controller.Animations)(false)
SetAnimation(YourAnimationOrKeyframeSequenceProvider)

const CameraModule = controller.Camera
const Types = require(CameraModule.Types)
const Camera = require(CameraModule) :: Types.Registry

Camera.Register(1, require(CameraModule.Fixed))
Camera.Register(2, require(CameraModule.Orbital))
Camera.Setup(2)
```
`SetAnimation` reloads the track each time it is called, so pass a new
`Animation` or `KeyframeSequenceProvider` to swap animations at runtime