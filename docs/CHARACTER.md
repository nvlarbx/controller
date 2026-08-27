On a *Client* RunContext,
```luau
require(controller.Character)(false)
```
hooks to CharacterAdded to create and fully setup a ControllerManager inside of the
LocalPlayer's Character, and enables character prediction
(`RunService:SetPredictionMode`) on each spawn

The Humanoid comes with the character and is never created here; only `HipHeight`
is read, and the Animator used for animations is the Humanoid's own

Everything it adds is guarded, so a rig that already ships its own
ControllerManager, sensors or Animator keeps them

There is nothing to do on a *Server* RunContext; `(true)` returns nil
