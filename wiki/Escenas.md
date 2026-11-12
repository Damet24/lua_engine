# Escenas

Una escena organiza su propio estado, sus recursos y, si los necesita, su mundo
ECS y sus cámaras. El motor las carga como módulos Lua bajo `scenesPath`: con el
valor predeterminado, `levels.level01` corresponde a
`game/scenes/levels/level01.lua`.

## Crear una escena

Por ejemplo, guarda este módulo como `game/scenes/ejemplo.lua` y selecciona
`initialScene = "ejemplo"` en la configuración:

```lua
local Scene = require("lua.engine.scene.scene")

local Ejemplo = {}
Ejemplo.__index = Ejemplo
setmetatable(Ejemplo, { __index = Scene })

function Ejemplo.new(context)
    local self = setmetatable(Scene.new(), Ejemplo)
    self.context = context
    return self
end

function Ejemplo:onLoad()
    self.x = 100
end

function Ejemplo:update(dt)
    if self.context.inputManager:isDown("move_right") then
        self.x = self.x + 100 * dt
    end
end

function Ejemplo:draw()
    love.graphics.rectangle("fill", self.x, 100, 16, 16)
end

function Ejemplo:onDestroy()
    self.context.resourceManager:releaseAll(self)
end

return Ejemplo
```

## Ciclo de vida

| Método | Momento |
| --- | --- |
| `onLoad()` | Una vez al crear la escena, antes de añadirla a la pila. |
| `onEnter()` | Cuando pasa a primer plano, incluida la vuelta desde otra escena. |
| `onExit()` | Cuando deja de estar en primer plano. |
| `update(dt)` | Actualización de la escena, si la política de la pila lo permite. |
| `draw()` | Dibujo de la escena, si la política de la pila lo permite. |
| `onDestroy()` | Al eliminar la escena de la pila; libera aquí sus recursos. |

`Scene.new()` proporciona implementaciones vacías de estos métodos. No es
necesario redefinir todos en cada escena.

## Pila y transiciones

Solicita cambios mediante `self.context.sceneManager`:

```lua
self.context.sceneManager:push("pause")
self.context.sceneManager:pop()
self.context.sceneManager:replace("levels.level01")
self.context.sceneManager:clearAndPush("mainMenu")
```

`push` conserva la escena anterior; `pop` destruye la superior y reactiva la
anterior. `replace` sustituye la superior; `clearAndPush` destruye toda la
pila y añade una escena. También existe `clear()` para vaciarla. Las solicitudes
se encolan y se procesan después de actualizar las escenas, no inmediatamente.

Por defecto, solo se actualiza y dibuja la escena superior. Al establecer
`self.updateBelow = true` o `self.drawBelow = true`, una escena permite que se
actualicen o dibujen las inferiores, respectivamente. Las escenas seleccionadas
se procesan de abajo hacia arriba. El menú de pausa de ejemplo activa
`drawBelow`, pero no `updateBelow`.

## Contexto

Las escenas cargadas por el motor reciben el mismo `context`, con
`resourceManager`, `sceneManager`, `inputManager` y `viewport`. Los recursos
se comparten por consumidor; las cámaras pertenecen a cada escena, no al
contexto. Consulta [Entrada y recursos](Entrada-y-recursos) y
[Renderizado y cámaras](Renderizado-y-camaras).