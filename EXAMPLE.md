> [!IMPORTANT]
> Before this, you must have followed all steps in [README.md](README.md)
>
> Also...
>
> Client checks are pointless. If you write good code, your implementation will not fail, and if someone is running exploits, checks offer zero real protection because they can be bypassed instantly. Stripping them away improves performance. The Script assumes correct usage, and if something is modified incorrectly, it simply errors out immediately
>
> Server side, checks are equally unnecessary because the client should never communicate with the server regarding controller (except the Enabled InputActions through [the Server Authoritative Input Action System](https://create.roblox.com/docs/projects/server-authority#input-actions)). The server trusts this blindly because the only other entity feeding input is the developer (you) behind the file, completely eliminating the need for defensive boilerplate

# Example

## 1 continuous *Client* RunContext Script
- Register [Orbital](src/Camera/Orbital.luau) and [Fixed](src/Camera/Fixed.luau)
```luau
local controller = game:GetService("ReplicatedFirst").controller

local CameraModule = controller.Camera
local Types = require(CameraModule.Types)
local RegisterCameraAddons = require(CameraModule) :: (any, Types.Addon) -> ()

RegisterCameraAddons(1, require(CameraModule.Fixed))
RegisterCameraAddons(2, require(CameraModule.Orbital))
```
- Implement automatic subject switching to Character, in this example we'll do that through attributes
```luau
...

local Player = game:GetService("Players").LocalPlayer :: Player

local CharacterAdded: RBXScriptConnection?
local CharacterCameraOffset = vector.create(0, 1.875, 0) :: any
local function OnCharacterAdded(Character: Model): ()
	CameraModule:SetAttribute("Subject", Character.Limbs)
	CameraModule:SetAttribute("Addon", 2)
	CameraModule:SetAttribute("Offset", CharacterCameraOffset)
end

local function CheckSwitchCameraToCharacter(): ()
	if controller:GetAttribute("AutoSwitchCameraToCharacter") then
		if CharacterAdded == nil then
			CharacterAdded = Player.CharacterAdded:Connect(OnCharacterAdded)

			local Character = Player.Character
			if Character then
				OnCharacterAdded(Character)
			end
		end
	elseif CharacterAdded then
		CharacterAdded:Disconnect()
		CharacterAdded = nil
	end
end

controller:GetAttributeChangedSignal("AutoSwitchCameraToCharacter"):Connect(CheckSwitchCameraToCharacter)
CheckSwitchCameraToCharacter()
```
- Start movement prediction
```luau
...

require(controller.Movement)(false)
```

## 1 *Server* RunContext Script
- Load the character

> [!NOTE]
> You can do this however you want; you can use Players' properties and let Roblox do it for you, and then remove Humanoid and create the required instances eventually

> In this example, we will use AssetService to load [a prepackaged rig](https://create.roblox.com/store/asset/103206220877141) and use attributes instead of relying on Players for maximum control  
Here will also detail how to implement animations, specifically [a directional AnimationGraphDefinition](https://create.roblox.com/store/asset/121607651640032), which looks like this

https://github.com/user-attachments/assets/8367f3a9-e2fa-4417-aa20-1bf1c5d22356

> [!TIP]
> If you set Player.Character manually, it won't come with junk. We also profit from the fact that the model comes prepackaged with the necessities. Of course, you can use it.

```luau
local Players = game:GetService("Players") :: Players
assert(Players.CharacterAutoLoads == false) -- Otherwise it would render the entire Script useless

local AssetService = game:GetService("AssetService") :: AssetService

local controller = game:GetService("ReplicatedFirst").controller
local InputContextsTemplate = controller.InputContexts :: Folder
local Types = require(controller:FindFirstChild("Types"))

local create = vector.create
local delay = task.delay

local StarterCharacter: Model
local DefaultSpawnPosition, SpawnPositionOffset = create(0, 100, 0) :: vector, create(0, 3, 0) :: vector
local RESPAWN_TIME, CHARACTER_AUTO_LOADS = controller:GetAttribute("RespawnTime") or Players.RespawnTime, controller:GetAttribute("CharacterAutoLoads") or true -- We cannot use Players.CharacterAutoLoads as it would render this entire script useless

local Asset = AssetService:LoadAssetAsync(103206220877141) :: Model
StarterCharacter = assert(Asset:FindFirstChild("StarterCharacter")) :: Model
StarterCharacter.Parent = script
Asset:Destroy()

controller:GetAttributeChangedSignal("RespawnTime"):Connect(function(): ()
	RESPAWN_TIME = controller:GetAttribute("RespawnTime")
end)

controller:GetAttributeChangedSignal("CharacterAutoLoads"):Connect(function(): ()
	CHARACTER_AUTO_LOADS = controller:GetAttribute("CharacterAutoLoads")
end)

local Animation = Instance.new("Animation") :: Animation
Animation.AnimationId = "rbxassetid://97691881768110"

Players.PlayerAdded:Connect(function(Player: Player): ()
	InputContextsTemplate:Clone().Parent = Player

	require(controller.Movement)(true)(Player)

	local RespawnPosition = DefaultSpawnPosition :: Vector3

	local function UpdateRespawnPosition(): ()
		local RespawnLocation = Player.RespawnLocation
		RespawnPosition = if RespawnLocation
			then RespawnLocation.Position + SpawnPositionOffset
			else DefaultSpawnPosition
	end

	local LoadCharacter: () -> ()

	local function Respawn(): ()
		if Player.Parent and CHARACTER_AUTO_LOADS then
			delay(RESPAWN_TIME, LoadCharacter)
		end
	end

	LoadCharacter = function(): ()
		if Player.Parent then
			local Character = StarterCharacter:Clone() :: Types.Character
			Character.Parent = workspace
			Character:MoveTo(RespawnPosition)
			Character.Name = Player.Name
			Player.Character = Character

			local Animator = Character.AnimationController.Animator
			local DirectionalTrack = Animator:LoadAnimation(Animation)
			DirectionalTrack:Play()

			local ControllerManager = Character.ControllerManager
			ControllerManager:GetAttributeChangedSignal("Move"):Connect(function(): ()
        local Move = ControllerManager:GetAttribute("Move") :: Vector2
				DirectionalTrack:SetParameter("x", Move.X)
				DirectionalTrack:SetParameter("y", Move.Y)
			end)

			if CHARACTER_AUTO_LOADS then
				Player.CharacterRemoving:Once(Respawn)
			end
		end
	end

	UpdateRespawnPosition()
	Player:GetPropertyChangedSignal("RespawnLocation"):Connect(UpdateRespawnPosition)

	if CHARACTER_AUTO_LOADS then
		LoadCharacter()
	end
end)
```

> [!TIP]
> A bonus would be to expose LoadCharacter, so that you decide when to
