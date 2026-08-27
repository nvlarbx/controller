On a *Server* RunContext,
```luau
require(controller.InputContexts)(true)(Player)
```
builds a folder of InputContexts in code inside Player  
  
Walk, LookVector and FirstPerson must be seen by Movement, which runs on the *Server* RunContext  
  
On a *Client* RunContext,
```luau
require(controller.InputContexts)(false)
```
locally merges additionnal InputActions inside the LocalPlayer's InputContexts
  
Rotate, Pan, Zoom and ZoomRate are only needed locally; there is no need for them to replicate