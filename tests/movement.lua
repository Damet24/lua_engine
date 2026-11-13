local MovementSystem = require("engine.ecs.systems.movementSystem")
local Components = require("engine.ecs.component")

local entities = {
	[1] = { Transform = { x = 0, y = 0 }, Velocity = { x = 30, y = 40 }, Movement = { maxSpeed = 25 } },
	[2] = { Transform = { x = 10, y = 20 }, Velocity = { x = 30, y = 40 }, RigidBody = {} },
}
local world = {}
function world:query(_, callback)
	for entity, components in pairs(entities) do callback(entity, components) end
end
function world:getComponent(entity, component) return entities[entity][component] end
function world:hasComponent(entity, component) return self:getComponent(entity, component) ~= nil end

MovementSystem.update(world, 2)
assert(entities[1].Transform.x == 30 and entities[1].Transform.y == 40)
assert(entities[2].Transform.x == 10 and entities[2].Transform.y == 20)
assert(Components.Movement == "Movement")
print("movement tests passed")