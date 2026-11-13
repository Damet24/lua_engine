# Architecture Overview

Astra 2D is organized as a small set of independent modules that are wired
together by a single `Engine` object. The engine owns the mechanisms (the frame
loop, the scene stack, resources, input, audio, cameras, and rendering); your
game owns the rules and the content.

This page explains how the modules relate to each other. It documents what the
engine actually does today, so the module reference and the guides can build on a
shared mental model.

## The engine at a glance

At the top, `main.lua` creates one `Engine` and forwards LÖVE's callbacks to it.
The engine constructs the shared services, loads scenes through the scene
manager, and every scene coordinates its own `World`, cameras, and rendering.

```text
                          main.lua
        forwards LÖVE load / update / draw / quit / keypressed
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│ Engine                                                             │
│   frame lifecycle · window · viewport (Shove)                      │
│                                                                    │
│   owns ──▶ ResourceManager   GameContext   SceneLoader             │
│            SceneManager      AudioManager  InputManager            │
└──────────────────────────────┬────────────────────────────────────┘
                               │ Engine:load() pushes the initial scene
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneManager               stack of { id, scene }                  │
│   push · pop · replace · clear · clearAndPush   (deferred)         │
└──────────────────────────────┬────────────────────────────────────┘
                               │ loads through
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneLoader        scenesPath .. "." .. sceneName  →  Scene.new()  │
└──────────────────────────────┬────────────────────────────────────┘
                               │ builds
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ Scene                  lifecycle + one part of the game            │
│   owns ──▶ World (ECS + physics)   CameraManager                   │
│            RenderPipeline          TilemapRender                   │
└───────────────────────────────────────────────────────────────────┘

Shared services reachable from a scene through its GameContext:
  GameContext ──▶ resourceManager · audioManager · sceneManager
                  inputManager · viewport
  ResourceManager ── shared by ──▶ AudioManager and Scenes (consumers)
```

Two ideas make the rest of the architecture easier to follow:

- **The engine builds, the game describes.** `Engine.new(config)` receives
  descriptions (an initial scene, resource definitions, input maps, resolutions)
  and turns them into live objects. Scenes never construct engine services.
- **Scenes see a `GameContext`, not the engine.** Everything a scene needs is
  handed to it through the context, which keeps scenes decoupled from how the
  engine is assembled.

## The frame lifecycle

Astra 2D does not replace LÖVE's main loop. `main.lua` forwards the callbacks it
needs, and each one maps to an engine method:

| LÖVE callback | Engine method | What happens |
| --- | --- | --- |
| `love.load` | `Engine:load()` | Applies window settings and the background color, creates the viewport, pushes `initialScene`, and processes the pending transition. |
| `love.update(dt)` | `Engine:update(dt)` | Updates the scene stack, then audio, then clears input state. |
| `love.draw` | `Engine:draw()` | Draws the scene stack inside the virtual-resolution viewport. |
| `love.keypressed(key)` | `Engine:keypressed(key)` | Forwards the key to the input manager. |
| `love.keyreleased(key)` | `Engine:keyreleased(key)` | Forwards the key to the input manager. |
| `love.quit` | `Engine:quit()` | Destroys the scene stack, stops audio, and releases all resources. |

The order inside `Engine:update` is significant:

1. `SceneManager:update(dt)` updates the active scenes and, at the end,
   processes the transitions requested during the frame.
2. `AudioManager:update(dt)` releases sounds that finished playing.
3. `InputManager:update()` clears the "just pressed" and "just released" state,
   so scenes can read it during their own update.

Input is cleared last on purpose: a scene reads `isJustPressed` while it runs,
and the flag is discarded only after every scene has had the chance to react.

## Module responsibilities

### Engine

`engine/engine.lua` is the composition root. It is the only module that knows how
to assemble the rest of the engine.

**Responsibilities**

- Normalize and validate the configuration, filling in defaults and rejecting
  invalid values early.
- Create the window (when a `window` table is given), the background color, and
  the viewport.
- Construct the shared services and inject the ones scenes need into the
  `GameContext`.
- Drive the frame: load, update, draw, input, and shutdown.

**Relationships**

- It owns `ResourceManager`, `GameContext`, `SceneLoader`, `SceneManager`,
  `AudioManager`, and `InputManager`.
- It builds the context first, then hands it to the `SceneLoader`, which hands it
  to every scene it creates.
- It sets `context.audioManager`, `context.sceneManager`, `context.inputManager`,
  and `context.viewport` as those services become available.
- It wraps `SceneManager:draw()` in the viewport's `beginDraw`/`endDraw`, so all
  scene rendering happens at the logical resolution.

### GameContext

`engine/core/gameContext.lua` is a thin service container. It is the boundary
between the engine and the game.

**Responsibilities**

- Carry the shared services that scenes are allowed to use.
- Keep scenes from reaching into the engine or constructing services themselves.

**Relationships**

- Created by `Engine` with the `resourceManager` and `audioManager`; the engine
  then adds `sceneManager`, `inputManager`, and `viewport`.
- Passed by reference to `SceneLoader`, which passes it to every scene
  constructor. All scenes of one engine share the same context.
- It deliberately exposes a small surface. It is not a global service locator:
  adding a new field is an architectural decision, not a convenience.

### SceneManager and SceneLoader

Together they turn a scene *identifier* into a running scene, and manage the
scene stack.

**SceneManager** (`engine/scene/sceneManager.lua`)

- Maintains the stack of `{ id, scene }` entries.
- Accepts transition requests: `push`, `pop`, `replace`, `clear`, and
  `clearAndPush`.
- Applies those requests in `processPendingOperations`, which runs at the end of
  `SceneManager:update` (and explicitly during `Engine:load` and
  `Engine:quit`).
- Drives the lifecycle callbacks in a defined order.
- Decides which scenes update and draw, based on each scene's `updateBelow` and
  `drawBelow` flags.

**SceneLoader** (`engine/scene/sceneLoader.lua`)

- Resolves a scene name to a module: `scenesPath .. "." .. sceneName`, so
  `levels.level01` becomes `game/scenes/levels/level01.lua`.
- `require`s that module, checks that it returns a class with a `new`
  constructor, and calls `SceneClass.new(context)`.

**Relationships and behavior**

- `SceneManager` never knows how a scene is built; it delegates that to the
  loader. `SceneLoader` never knows about the stack.
- Transitions are **deferred**. Calling `push`, `pop`, or `replace` only records
  a request. The stack changes at the end of the update, so a scene is never
  destroyed while it is still executing. Do not expect the stack to change
  halfway through `update`.
- Scenes request transitions through `context.sceneManager`, not through a field
  on the scene. The `manager` dependency that `SceneManager` attaches to each
  request is currently unused by the loader.

Lifecycle callbacks are invoked in this order:

| Operation | Callback order |
| --- | --- |
| `push` | new scene `onLoad`, previous scene `onExit`, new scene `onEnter` |
| `pop` | top scene `onExit`, top scene `onDestroy`, previous scene `onEnter` |
| `replace` | new scene `onLoad`, previous scene `onExit`, previous scene `onDestroy`, new scene `onEnter` |
| `clearAndPush` | new scene `onLoad`, all previous scenes `onExit`, all previous scenes `onDestroy`, new scene `onEnter` |

`onLoad` runs once per scene instance, `onEnter`/`onExit` run each time a scene
moves to or from the foreground, and `onDestroy` runs once when the instance is
discarded.

### Scene and World

A `Scene` is a self-contained part of the game. A `World` is the ECS state that
belongs to it. The scene owns the world; the world knows nothing about the scene.

**Scene** (`engine/scene/scene.lua`)

- Provides the lifecycle callbacks: `onLoad`, `onEnter`, `onExit`, `onDestroy`.
- Provides the per-frame hooks: `update(dt)` and `draw()`.
- Declares two flags, `updateBelow` and `drawBelow` (both `false` by default),
  which tell the `SceneManager` whether the scenes underneath should also update
  or draw.

Game scenes extend `Scene` and act as coordinators. A level, for example, loads
its resources, creates a `World`, registers systems, builds a `CameraManager`
and a `RenderPipeline`, and draws its tilemap and entities. The scene does not
manage the stack or run transitions.

**World** (`engine/ecs/world.lua`)

- Stores entities as plain numeric identifiers and components as
  `components[name][entity] = data`.
- Holds an ordered list of systems. Each system may implement `init(world)`,
  `update(world, dt)`, and `draw(world)`.
- Owns an `EventManager` (`engine/core/events.lua`) for deferred events, and a
  physics world (`engine/physics/physics_world.lua`, backed by `love.physics`).
- Runs systems in the order they were added, dispatches queued events, and then
  flushes entities that were marked for destruction.

**Relationships**

- A scene creates exactly one `World` for its own state; different scenes have
  independent worlds.
- Systems communicate with the world through queries such as
  `world:query({ Components.Transform, Components.Velocity }, ...)`. The
  component names live in `engine/ecs/component.lua`.
- Physics is integrated through systems: `PhysicsFactory` builds LÖVE bodies
  from `Transform` + `RigidBody` + `Collider`, and `PhysicsSystem`,
  `PhysicsMovementSystem`, `PhysicsSyncSystem`, and `CollisionSystem` connect
  the ECS to the physics world. `CollisionSystem` translates contacts into
  `collision_started` / `collision_ended` events on `world.events`.

### ResourceManager

`engine/resources/resourceManager.lua` centralizes loading, reuse, and release of
images, sounds, and fonts. It is independent of the scene system and can be used
from any module.

**Responsibilities**

- Load a resource the first time it is requested, then return the cached
  instance.
- Track which **consumers** depend on each resource.
- Release a resource automatically when its last consumer releases it.

**Relationships**

- Definitions come from `resourceDefinitions`; each definition has a `type`
  that selects a loader from the loader table (`image`, `sound`, and `font` by
  default, in `engine/resources/loaders/`).
- `get(consumer, resourceId)` records the consumer and returns the loaded value.
- `release(consumer, resourceId)` removes one consumer and frees the resource
  when none remain. `releaseAll(consumer)` and `releaseAllResources()` cover the
  bulk cases.
- Consumers are arbitrary keys, usually the object itself. Scenes pass `self` and
  call `resourceManager:releaseAll(self)` in `onDestroy`; `AudioManager` is also
  a consumer and releases its sources in `shutdown`.
- Because the manager is shared, the same image or sound is never loaded twice,
  even when two scenes use it at the same time.

### InputManager and AudioManager

These are the two services that scenes query every frame. Both are reachable from
the `GameContext`.

**InputManager** (`engine/input/inputManager.lua`)

- Turns named actions into key bindings. An action such as `move_left` maps to
  one or more LÖVE key names.
- Tracks three key states: `pressed`, `justPressed`, and `justReleased`.
- Exposes `isDown(action)`, `isJustPressed(action)`, and `isJustReleased(action)`.

Relationships: `Engine` forwards `love.keypressed` / `love.keyreleased` to it,
and `Engine:update` clears the transient states at the end of the frame. Scenes
and systems read actions through `context.inputManager`; a game system such as
`PlayerSystem` receives the manager directly when it is constructed. Input maps
are validated at construction: each action needs at least one unique binding,
with contiguous indices.

**AudioManager** (`engine/audio/audioManager.lua`)

- Plays music and sound effects, with separate master, music, and sound-effect
  volumes.
- Keeps one current music track and a set of active sound effects.
- Releases finished effects during `update` and everything during `shutdown`.

Relationships: it depends on the `ResourceManager` and is itself a resource
consumer. `playMusic` uses the shared music source; `playSound` clones the
source so several effects can overlap. `Engine:update` calls its `update`, and
`Engine:quit` calls `shutdown`.

### CameraManager and cameras

`engine/camera/cameraManager.lua` and `engine/camera/camera.lua` give a scene a
world-space view of its content.

**Responsibilities**

- `CameraManager` holds named cameras and selects the active one. `add`, `get`,
  `setActive`, `getActive`, and `remove` manage the set; duplicate or missing
  identifiers raise errors.
- `Camera` exposes position, zoom, rotation, viewport, coordinate conversion, and
  drawing. It wraps an adapter around the vendored `hump.camera`
  (`engine/camera/adapters/humpCamera.lua`).

**Relationships**

- Cameras are **per scene**. A scene creates its `CameraManager` in `onLoad` and
  drops it in `onDestroy`. Nothing is selected automatically.
- `camera:draw(function)` attaches the camera, runs the callback, and detaches
  again, restoring the graphics stack and scissor even if the callback fails.
  Scenes pass the render pipeline's `draw` as that callback.
- Camera viewports use **logical** coordinates. To convert a mouse position,
  first call `context.viewport.screenToViewport(x, y)`, then
  `camera:worldCoords(x, y)`.

### Rendering and the viewport

Rendering is split between the viewport (logical resolution), the camera (world
transform), and the render pipeline (layer order). Each layer scales the one
inside it:

```text
LÖVE window (physical pixels)
  └─ viewport / Shove          logical resolution: rendering.width x rendering.height
       └─ Camera               world transform: position, zoom, rotation
            └─ RenderPipeline   draw order: tilemap layers and entities by layer
```

**Viewport** (`engine/lib/shove/shove.lua`, created by `Engine:load`)

- Scales the logical resolution configured by `rendering.width` / `rendering.height`
  to the physical window. `pixelPerfect = true` uses integer scaling and
  nearest-neighbor filtering.
- Exposes `getViewportDimensions()` and `screenToViewport(x, y)`.
- `Engine:draw` calls `viewport.beginDraw()` / `viewport.endDraw()` around the
  scene stack, so every scene draws in logical coordinates.

**RenderPipeline** (`engine/graphics/render_pipeline.lua`)

- Collects draw callbacks tagged with a numeric layer.
- `draw()` sorts them by layer and then by insertion order, giving a
  deterministic result, and calls each callback.

**Renderers**

- `TilemapRender` (`engine/tilemap/tilemaprender.lua`) turns a Tiled map and its
  tilesets into pipeline items, one per visible tile layer.
- `RenderSystem` (`engine/ecs/systems/renderSystem.lua`) submits every entity
  with a `Transform` and `Sprite`, using `sprite.layer` for ordering.

A scene typically clears the pipeline, submits the tilemap and the entities, and
then draws the pipeline inside the active camera. Screen-space UI is drawn after
the camera, directly in logical coordinates.

## How the modules work together

- **Deferred transitions.** Scenes never mutate the stack directly. They call
  `sceneManager:push/pop/replace/...`, and the `SceneManager` applies the
  requests at the end of the scene update. This keeps the running scene intact
  while it finishes its frame.
- **Consumers share resources.** `ResourceManager` is the only place resources
  are loaded. Scenes and the `AudioManager` are consumers; a resource stays
  loaded while any consumer needs it and is released when the last one lets go.
- **Update and draw are separate policies.** `updateBelow` and `drawBelow`
  decide, per scene, whether the scenes underneath keep simulating or keep
  rendering. A pause menu can draw the level beneath it while stopping its
  simulation, and a scene can be updated without being drawn.
- **One coordinate chain.** Physical window → logical viewport → camera world →
  pipeline. Conversions happen only at the boundaries:
  `screenToViewport` (physical → logical) and `worldCoords` (logical → world).

## Where the game plugs in

Your game provides descriptions and content; the engine provides the mechanisms.

| Your game provides | The engine turns it into |
| --- | --- |
| `initialScene` | The first scene pushed onto the stack. |
| `scenesPath` | The module prefix used to load scenes (default `game.scenes`). |
| `resourceDefinitions` / `resourceLoaders` | The definitions and loaders used by the `ResourceManager`. |
| `inputMaps` | The action table used by the `InputManager`. |
| `window` / `rendering` / `audio` | Window mode, logical resolution, background, and volumes. |
| Scene modules | Instances created by the `SceneLoader` and driven by the `SceneManager`. |
| Worlds, systems, cameras, pipelines | Built inside each scene's `onLoad`. |

## Design notes

`engine/scenes.md` is a design document that describes the intended direction of
the scene system. Some of its ideas are not implemented yet, including a
`SceneRegistry`/`SceneFactory`, transition rules owned by the game, source-context
validation for pending requests, and a `GameState`. Where this page and that
document disagree, this page describes the current implementation.

The `GameContext` lives in `engine/core/gameContext.lua`. It requires a
`resourceManager` and an `audioManager` at construction and treats `sceneManager`
as optional, because the scene manager is built after the context (it needs the
`SceneLoader`, which needs the context). `inputManager` and `viewport` are added
by `Engine` once they exist.

## Next steps

- [Introduction](/getting-started/introduction) for the core concepts.
- [Your First Project](/getting-started/first-project) to build a scene with
  input, movement, and a resource.
- The API reference for module-level details.
