On a *Server* RunContext,
```luau
require(controller.Character)(true)(Player)
```
hooks to CharacterAdded to create and fully setup a ControllerManager inside of
that Player's Character

On a *Client* RunContext,
```luau
require(controller.Character)(false)
```
hooks to CharacterAdded to enable character prediction