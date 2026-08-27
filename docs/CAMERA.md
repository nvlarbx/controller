```luau
Camera.Register(Index, Addon) -- (Index: any, Addon: Types.Addon?) -> ()
```
Sets any value to any index in Camera's addon registry
If you replaced the current addon, you must Setup again to apply change
> [!TIP]
> Register an existing Index with value nil to clean

```luau
Camera.Setup(Index) -- (Index: any) -> ()
```
Switches camera addon, implied teardown of the previous one

```luau
Camera.Teardown()
```
Teardown of current addon; cleanup

```luau
Camera.Current -- any?
```
Current addon index

## Configuration

There is no settings layer; addons read live Roblox properties, so anything that
already drives the default camera drives this one:

| what | source |
| --- | --- |
| subject | `workspace.CurrentCamera.CameraSubject` |
| zoom limits | `Player.CameraMinZoomDistance` / `CameraMaxZoomDistance` |
| offset | `Humanoid.CameraOffset` |
| sensitivity, invert | `UserGameSettings` |

All are watched live — assign to any of them and the camera follows.
When `CameraSubject` is a `Humanoid`, its parent model is framed and that
Humanoid supplies `CameraOffset`.
