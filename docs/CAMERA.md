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
Same properties the official CameraModule would watch

## Addons
An addon can expose a Setup and a Teardown
Refer to Types.Addon