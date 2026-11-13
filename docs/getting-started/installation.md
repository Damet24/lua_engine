# Installation

Astra 2D runs on [LÖVE](https://love2d.org/) and does not require a separate build
step. This page covers the requirements, running the sample project, and adding
the engine to a new project.

## Requirements

- **LÖVE 11.5.** The project is tested with this version. Other versions are not
  verified.
- **Git** (optional). You can download the repository as an archive instead of
  cloning it.
- **The repository files.** Keep `engine/lib/` with the rest of the engine,
  because the engine imports its bundled libraries from there.

Lua itself is included with LÖVE. No external package manager or additional Lua
modules are required.

## Run the sample project

Clone the repository and start LÖVE from the project root:

```sh
git clone https://github.com/Damet24/lua_engine.git
cd lua_engine
love .
```

On Windows, you can also drag the project folder onto the LÖVE executable, or add
the LÖVE installation directory to your `PATH` and run the same command.

The sample starts at the main menu. Its bindings are defined in
`game/inputMaps.lua`:

| Action | Default keys |
| --- | --- |
| Accept | `Return` |
| Pause / back | `Escape` |
| Move left | `Left`, `A` |
| Move right | `Right`, `E` |
| Jump | `Space` |

Press `Return` to enter the level, `Escape` to open the pause menu, and the
movement keys to control the player.

## Use the engine in another project

1. Copy the `engine/` folder into the root of your LÖVE project. Keep the folder
   name as `engine`, because every engine module is imported with the `engine.`
   prefix.

   ```text
   my-game/
     engine/
       engine.lua
       lib/
       ...
     game/
       inputMaps.lua
       resources/
       scenes/
     main.lua
   ```

2. Create the game modules the engine needs. At minimum, provide an input map
   table, a resource definitions table, and an initial scene.

3. Create `main.lua` and forward the LÖVE callbacks to the engine:

   ```lua
   local Engine = require("engine.engine")

   local engine = Engine.new({
       initialScene = "hello",
       scenesPath = "game.scenes",
       inputMaps = require("game.inputMaps"),
       resourceDefinitions = require("game.resources.definitions"),
       audio = {
           masterVolume = 0.1,
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
           backgroundColor = { 0.18, 0.25, 0.34 },
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

4. Run the project from its root:

   ```sh
   love .
   ```

With `scenesPath = "game.scenes"` and `initialScene = "hello"`, the engine loads
`game/scenes/hello.lua`. Scene identifiers use dots instead of slashes, so
`levels.level01` resolves to `game/scenes/levels/level01.lua`. The `hello` scene
is created in [Your First Project](/getting-started/first-project); use the
identifier of a scene that already exists in your project.

### Required configuration

| Field | Description |
| --- | --- |
| `initialScene` | Required. Identifier of the first scene to load. |
| `inputMaps` | Required. Table of action names and their key bindings. It may be empty, but the table must exist. |
| `audio` | Optional. `masterVolume`, `musicVolume`, and `sfxVolume` each default to `1.0`. |
| `scenesPath` | Prefix used to import scenes. Defaults to `game.scenes`. |
| `resourceDefinitions` | Resource id-to-definition table. Defaults to an empty table. |
| `resourceLoaders` | Loader table. Defaults to the built-in image, sound, and font loaders. |
| `window` | Optional. When provided, `width` and `height` are required. Defaults are `fullscreen = false`, `resizable = true`, and `vsync = true`. |
| `rendering` | Logical resolution. Defaults to `1280 x 720`, `pixelPerfect = false`, and a black background. |

`rendering.backgroundColor` accepts an RGB or RGBA table with components between
`0` and `1`. The engine applies it when `Engine:load()` runs.

## Troubleshooting

### `module 'engine.engine' not found`

Run LÖVE from the project root, and make sure the engine folder is named
`engine` and sits next to `main.lua`. The bundled libraries must remain in
`engine/lib/`.

### `Failed to load scene '...'`

The engine combines `scenesPath` and the scene identifier to build a Lua module
path. Check both values and confirm the file exists. For example, the identifier
`levels.level01` resolves to `game/scenes/levels/level01.lua` when `scenesPath`
is `game.scenes`. The scene file must return a class with a `new` function.

### `Resource '...' is not defined`

Add the resource id to `game/resources/definitions.lua`, or to the table passed as
`resourceDefinitions`. Resources are loaded when `ResourceManager:get()` is called,
usually from a scene's `onLoad` callback.

### `No loader registered for resource type '...'`

The definition's `type` must match a key in the loader table. The built-in loaders
are `image`, `sound`, and `font`.

### An input map error is raised

Each action must be an array of one or more unique key names, without gaps or
duplicate bindings in the same action. For example:

```lua
return {
    jump = { "space" },
    move_left = { "left", "a" },
    move_right = { "right", "d" },
}
```

### The window cannot be created

`Engine:load()` calls `love.window.setMode`. If it fails, check that the requested
resolution is supported, that fullscreen mode is available, and that the
environment can create a graphical window. Headless environments cannot run a
LÖVE window.

## Next steps

Continue with [Your First Project](/getting-started/first-project) to build a
small scene with input, movement, and a resource.
