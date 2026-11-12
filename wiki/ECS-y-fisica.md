# ECS y física

El ECS organiza entidades como identificadores numéricos, componentes como
tablas y sistemas que procesan el mundo. Cada escena decide qué mundo y qué
sistemas utilizar.

## Entidades y componentes

```lua
local World = require("lua.engine.ecs.world")
local Components = require("lua.engine.ecs.component")

local world = World.new(0, 640, true)
local entity = world:createEntity()
world:addComponent(entity, Components.Transform, { x = 100, y = 100 })
world:addComponent(entity, Components.Velocity, { x = 50, y = 0 })

world:query({ Components.Transform, Components.Velocity }, function(id, components)
    print(id, components.Transform.x, components.Velocity.x)
end)
```

`World.new(gravedadX, gravedadY, sleep)` crea también un mundo físico de LÖVE.
Usa `getComponent`, `hasComponent` y `removeComponent` para acceder a los
componentes. `destroyEntity(id)` programa su destrucción; `world:update(dt)`
elimina las entidades pendientes al final de la actualización, incluyendo su
cuerpo físico si existe.

## Sistemas

Registra los sistemas con `world:addSystem(system)`. Si existe `system.init`,
se ejecuta al registrarlo; `system.update(world, dt)` se ejecuta en el orden de
registro. Después de los sistemas se entregan los eventos y se procesan las
destrucciones. `world:draw()` ejecuta los métodos `draw` de los sistemas que
los definan; el nivel de ejemplo usa en cambio `RenderSystem.submit`.

Para movimiento y física, el proyecto emplea este orden:

```lua
world:addSystem(require("lua.engine.ecs.systems.movementSystem"))
world:addSystem(require("lua.engine.ecs.systems.physicsMovementSystem"))
world:addSystem(require("lua.engine.ecs.systems.physicsSystem"))
world:addSystem(require("lua.engine.ecs.systems.physicsSyncSystem"))
world:addSystem(require("lua.engine.ecs.systems.collisionSystem"))
```

## Cuerpo físico

```lua
local PhysicsFactory = require("lua.engine.physics.physics_factory")
local entity = world:createEntity()
world:addComponent(entity, Components.Transform, { x = 100, y = 100 })
world:addComponent(entity, Components.RigidBody, { type = "dynamic" })
world:addComponent(entity, Components.Collider, {
    shape = "rectangle", width = 32, height = 32,
})
local body, fixture = PhysicsFactory.create(world, entity)
```

La fábrica admite un collider rectangular por entidad, cuerpos `static`,
`dynamic` o `kinematic` y sensores. La posición es el centro del cuerpo y la
rotación se expresa en radianes. Las coordenadas se usan en píxeles: LÖVE
configura internamente la escala de Box2D, por lo que no hay que dividirlas.
La física avanza en pasos fijos de 1/60 s, sin interpolación visual.

Para entidades sin cuerpo, `MovementSystem` integra `Velocity` en `Transform`.
Para cuerpos físicos, `PhysicsMovementSystem` trata `Velocity` como orden de
movimiento, no como lectura continua del cuerpo; usa
`body:getLinearVelocity()` para conocer la velocidad física actual.

## Colisiones

Con `CollisionSystem` registrado, puedes escuchar los identificadores de las
entidades en contacto:

```lua
world.events:on("collision_started", function(contact)
    print(contact.entityA, contact.entityB)
end)
world.events:on("collision_ended", function(contact)
    print(contact.entityA, contact.entityB)
end)
```

Los eventos se entregan al terminar los sistemas. No se conserva el objeto
`Contact` de Box2D fuera de sus callbacks. Los eventos generados por destruir
un cuerpo al final del ciclo se entregan en la siguiente actualización.