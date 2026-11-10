# Movimiento y fisica

El ECS usa pixeles y pixeles por segundo. `love.physics` tambien recibe estas
unidades en su API: `PhysicsWorld` configura `love.physics.setMeter(64)` para
que LÖVE convierta internamente a las unidades de Box2D. La escala es global y
debe configurarse antes de crear cuerpos; no dividas las posiciones por 64.
El angulo de `Transform.rotation` se expresa en radianes.

Registra los sistemas en este orden:

```lua
world:addSystem(require("lua.engine.ecs.systems.movementSystem"))
world:addSystem(require("lua.engine.ecs.systems.physicsMovementSystem"))
world:addSystem(require("lua.engine.ecs.systems.physicsSystem"))
world:addSystem(require("lua.engine.ecs.systems.physicsSyncSystem"))
world:addSystem(require("lua.engine.ecs.systems.collisionSystem"))
```

`world:update(dt)` actualiza los sistemas, entrega los eventos y finalmente
destruye las entidades pendientes. La fisica avanza en pasos de 1/60 s; no hay
interpolacion ni limite de pasos acumulados. Los listeners de eventos se ejecutan
al final de la actualizacion, despues de los sistemas registrados.

Para crear un cuerpo, agrega los componentes y llama a la fabrica:

```lua
local Components = require("lua.engine.ecs.component")
local PhysicsFactory = require("lua.engine.physics.physics_factory")
local entity = world:createEntity()
world:addComponent(entity, Components.Transform, { x = 100, y = 100, rotation = 0 })
world:addComponent(entity, Components.Velocity, { x = 100, y = 0 })
world:addComponent(entity, Components.Movement, { maxSpeed = 200 })
world:addComponent(entity, Components.RigidBody, { type = "dynamic" })
world:addComponent(entity, Components.Collider, {
    shape = "rectangle", width = 32, height = 32,
    offsetX = 0, offsetY = 0, sensor = false,
})
local body, fixture = PhysicsFactory.create(world, entity)
```

El cuerpo se centra en `Transform.x, y`; `offsetX, offsetY` desplazan el
rectangulo con respecto al cuerpo. Para centrar un sprite de 32x32 sobre el
cuerpo, usa `Sprite.origin = { x = 16, y = 16 }`. La fabrica admite cuerpos
`static`, `dynamic` y `kinematic`, un rectangulo por entidad y sensores.

Para una entidad sin `RigidBody`, `MovementSystem` integra `Velocity` sobre el
`Transform`. Para una entidad fisica, `PhysicsMovementSystem` trata `Velocity`
como una orden: establece ambas componentes de la velocidad al crearse o cuando
cambia la orden efectiva, pero no vuelve a imponerla cada fotograma. Asi la
gravedad y las colisiones pueden modificar la velocidad del cuerpo. Consulta
`body:getLinearVelocity()` para obtener la velocidad fisica actual. Cambiar una
componente de la orden vuelve a aplicar ambas. `Movement.maxSpeed` limita la
orden de movimiento, no la velocidad alcanzada por gravedad o impulsos.

`CollisionSystem` instala los callbacks del mundo fisico y encola los IDs de las
entidades durante los contactos. Suscribete antes de actualizar:

```lua
world.events:on("collision_started", function(contact)
    print(contact.entityA, contact.entityB)
end)
world.events:on("collision_ended", function(contact)
    print(contact.entityA, contact.entityB)
end)
```

No se conserva el objeto `Contact`, que solo es valido durante el callback.
Destruir una entidad con `world:destroyEntity(entity)` destruye su cuerpo al
final de la actualizacion. Los contactos que Box2D genere durante esa destruccion
se entregan en la siguiente actualizacion. `PhysicsDebugSystem.draw(world)`
puede llamarse manualmente desde `love.draw()` para ver los fixtures.

La integracion de colisiones de Tiled, los filtros, multiples fixtures por
entidad y la interpolacion visual quedan para una etapa posterior.