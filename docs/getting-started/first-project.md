# Your First Project

This guide creates a minimal Astra 2D project: one scene, a few input actions, a
movable square, and an image resource. It is a good place to start before adding
levels, cameras, or a full ECS.

## Project structure

Create a folder for the game and copy the engine into it:

```text
my-game/
  engine/
  game/
    inputMaps.lua
    resources/
      definitions.lua
    scenes/
      hello.lua
  main.lua
```

The folder must be named `engine`, because the engine modules import each other
with the `engine.` prefix.

## 1. Configure the entry point

Create `main.lua`. It builds the engine once, then forwards the LÖVE callbacks:

```lua
local Engine = require("engine.engine")

local engine = Engine.new({
    initialScene = "hello",
    inputMaps = require("game.inputMaps"),
    resourceDefinitions = require("game.resources.definitions"),
    audio = {
        masterVolume = 1.0,
        musicVolume = 0.8,
        sfxVolume = 1.0,
    },
    window = {
        width = 960,
        height = 540,
        fullscreen = false,
        resizable = true,
        vsync = true,
    },
    rendering = {
        width = 320,
        height = 180,
        pixelPerfect = true,
        backgroundColor = { 0.10, 0.14, 0.20 },
    },
})

function love.load()
    engine:load()
end

function love.update(dt)
    engine:update(dt)
end

function love.draw()
    engine:draw()
end

function love.keypressed(key)
    engine:keypressed(key)
end

function love.keyreleased(key)
    engine:keyreleased(key)
end

function love.quit()
    engine:quit()
end
```

The logical resolution is `320 x 180`, while the window is `960 x 540`. With
`pixelPerfect = true`, the engine scales the game with nearest-neighbor filtering,
so your scene can use small coordinates such as `(8, 8)`.

## 2. Define input actions

Create `game/inputMaps.lua`. Actions are named arrays of LÖVE key names:

```lua
return {
    move_left = { "left", "a" },
    move_right = { "right", "d" },
    move_up = { "up", "w" },
    move_down = { "down", "s" },
}
```

Each action must have at least one binding, indices must be contiguous, and the
same action cannot list the same key twice.

## 3. Create the first scene

Create `game/scenes/hello.lua`. Scenes extend the engine's `Scene` class and
receive a `GameContext` in their constructor:

```lua
local Scene = require("engine.scene.scene")

local Hello = {}
Hello.__index = Hello

setmetatable(Hello, { __index = Scene })

function Hello.new(context)
    local self = Scene.new()
    setmetatable(self, Hello)

    self.context = context
    self.x = 160
    self.y = 90
    self.speed = 100

    return self
end

function Hello:onLoad()
    self.width, self.height = self.context.viewport.getViewportDimensions()
end

function Hello:update(dt)
    local input = self.context.inputManager
    local dx, dy = 0, 0

    if input:isDown("move_left") then dx = dx - 1 end
    if input:isDown("move_right") then dx = dx + 1 end
    if input:isDown("move_up") then dy = dy - 1 end
    if input:isDown("move_down") then dy = dy + 1 end

    -- Keep diagonal movement at the same speed.
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / length, dy / length
    end

    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt

    -- Keep the square inside the logical viewport.
    self.x = math.max(8, math.min(self.width - 8, self.x))
    self.y = math.max(8, math.min(self.height - 8, self.y))
end

function Hello:draw()
    love.graphics.push("all")

    love.graphics.setColor(1, 1, 1, 1)
    love.graphics.print("Move with the arrow keys or WASD", 8, 8)

    love.graphics.setColor(1, 0.7, 0.2, 1)
    love.graphics.rectangle("fill", self.x - 8, self.y - 8, 16, 16)

    love.graphics.pop()
end

function Hello:onDestroy()
    self.context.resourceManager:releaseAll(self)
end

return Hello
```

Create `game/resources/definitions.lua` with an empty table for now:

```lua
return {}
```

## 4. Run the game

From the project root:

```sh
love .
```

You should see a `320 x 180` scene with instructions and a square that moves
inside the screen.

## What just happened?

When LÖVE calls `love.load`, `Engine:load()`:

1. Applies the window settings and background color.
2. Creates the virtual-resolution viewport.
3. Pushes `initialScene` onto the scene stack.
4. Calls the scene's `onLoad` and `onEnter` callbacks.

On every frame, `Engine:update()` updates the scene, then audio, then input.
`InputManager:isDown(action)` checks the keys bound to that action. At the end of
the update, the manager clears its "just pressed" and "just released" state.

`Engine:draw()` draws the scene stack through the viewport, which scales the
logical resolution to the window.

Scene changes are queued. If a scene calls `sceneManager:replace(...)` or
`sceneManager:push(...)`, the transition is processed at the end of the scene
manager update, after the current scene has finished updating.

## Next steps

### Load an image resource

Add an asset at `game/assets/player.png`, then register it:

```lua
return {
    player = {
        type = "image",
        path = "game/assets/player.png",
    },
}
```

Load it in `onLoad` and draw it instead of the rectangle:

```lua
function Hello:onLoad()
    self.width, self.height = self.context.viewport.getViewportDimensions()
    self.image = self.context.resourceManager:get(self, "player")
end

function Hello:draw()
    love.graphics.push("all")
    love.graphics.draw(
        self.image,
        self.x - self.image:getWidth() / 2,
        self.y - self.image:getHeight() / 2
    )
    love.graphics.pop()
end
```

The scene is the consumer of the resource. `releaseAll(self)` in `onDestroy`
informs the resource manager that the scene no longer needs it, and the resource
is released when no other consumer needs it.

### Add another scene

Create `game/scenes/world.lua` with the same structure as `Hello`, then request
a transition from the first scene:

```lua
if self.context.inputManager:isJustPressed("move_up") then
    self.context.sceneManager:replace("world")
end
```

`world` resolves to `game/scenes/world.lua` because the default `scenesPath` is
`game.scenes`. Use `push` instead of `replace` when the current scene should stay
in memory, for example to open a pause menu.

### Explore the engine

- [Introduction](/getting-started/introduction) for the engine's core concepts.
- [Architecture overview](/architecture/overview) for how systems fit together.
- [API reference](/api/) for module-level details.

## Common pitfalls

- **The scene class has no `new` function.** Every scene module must return a table
  with a `new` constructor.
- **The scene is not found.** Check the `initialScene` identifier and the
  `scenesPath` prefix. Dots map to folder separators.
- **Resources are loaded in the constructor.** Load them in `onLoad`, where the
  scene is ready and failures are easier to diagnose.
- **Input does nothing.** Forward `love.keypressed` and `love.keyreleased` to the
  engine, and confirm the action name matches `game/inputMaps.lua`.
- **A transition happens immediately.** Scene transitions are deferred until the
  end of the scene manager update, which is intentional. Do not expect the scene
  stack to change halfway through `update`.
- **Resources stay loaded.** Release every consumer in `onDestroy` with
  `resourceManager:releaseAll(self)`.
