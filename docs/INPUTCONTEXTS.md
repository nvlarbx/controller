On a *Server* RunContext,
```luau
require(controller.InputContexts)(true)(Player)
```
clones InputContexts inside a Player
It also creates the client InputActions, disabled

On a *Client* RunContext,
```luau
require(controller.InputContexts)(false)
```
reenables disabled InputActions  
  
## To Roblox engineers:
We wanted to create what's server authorative on server, and what's client only on client, but that didn't work. Indeed, server authority requires the server to have all inputs to match client's  
  
What we want is some compromise: allow us to have SOME inputs server-authorative, and some inputs not. Of course, these are determined by server. This could save bandwidth, memory and clutter