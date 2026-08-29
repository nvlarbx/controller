On a *Client* RunContext,
```luau
const SetAnimation = require(controller.Animations)(false) :: Animations.Set
```
hooks to CharacterAdded to reload the AnimationTrack
```luau
SetAnimation(Graph) -- Animations.Set, or (Graph: Animation?) -> ()
```
Sets the source and reloads the track

## Blending
The AnimationGraphDefinition is driven by two parameters, x (character's sides) and y (front and back)