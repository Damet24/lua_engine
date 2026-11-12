# Entrada y recursos

## Acciones de entrada

`game/inputMaps.lua` relaciona acciones con una o varias teclas de LÖVE:

```lua
return {
    move_left = { "left", "a" },
    move_right = { "right", "d" },
    jump = { "space" },
}
```

Las escenas acceden al gestor desde el contexto:

```lua
local input = self.context.inputManager
if input:isDown("move_right") then
    -- Movimiento mientras se mantiene alguna tecla asociada.
end
if input:isJustPressed("jump") then
    -- Una pulsación desde la última actualización.
end
if input:isJustReleased("jump") then
    -- Una liberación desde la última actualización.
end
```

Los callbacks `love.keypressed` y `love.keyreleased` deben reenviarse al motor,
como se muestra en [Inicio rápido](Inicio-rapido). El motor limpia los estados
transitorios **después** de actualizar las escenas. Al usar `InputManager`
por separado, llama a `input:update()` después de consultar esos estados. Una
acción desconocida devuelve `false`. La implementación actual gestiona teclas;
no documentamos entrada de mando o ratón como acciones disponibles.

## Definiciones y cargadores

Los recursos del juego se definen en `game/resources/definitions.lua` y sus
cargadores en `game/resources/loaders.lua`. Una definición identifica un tipo y
los datos necesarios para cargarlo:

```lua
return {
    personaje = { type = "image", path = "game/assets/personaje.png" },
    fuente_menu = { type = "font", size = 18 },
}
```

La ruta del ejemplo es ilustrativa: debe apuntar a un archivo existente. Cada
tipo necesita un cargador con funciones `load(definition)` y
`release(resource)`; el proyecto proporciona cargadores de imagen y fuente.

## Uso desde una escena

```lua
function MiEscena:onLoad()
    self.imagen = self.context.resourceManager:get(self, "personaje")
end

function MiEscena:onDestroy()
    self.context.resourceManager:releaseAll(self)
end
```

`get(consumidor, id)` carga el recurso la primera vez y lo comparte entre
consumidores. La misma escena puede pedirlo varias veces sin acumular referencias
adicionales. `release(consumidor, id)` libera un recurso para ese consumidor;
`releaseAll(consumidor)` libera todos los suyos. El recurso subyacente se libera
cuando deja de haber consumidores. El identificador y el tipo deben estar
definidos, o `get` genera un error.