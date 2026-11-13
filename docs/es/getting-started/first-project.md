# Tu primer proyecto

Esta guía crea un proyecto mínimo de Astra 2D: una escena, unas pocas acciones de
entrada, un cuadrado que se mueve y un recurso de imagen. Es un buen punto de
partida antes de añadir niveles, cámaras o un ECS completo.

## Estructura del proyecto

Crea una carpeta para el juego y copia el motor dentro:

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

La carpeta debe llamarse `engine`, porque los módulos del motor se importan entre
sí con el prefijo `engine.`.

## 1. Configurar el punto de entrada

Crea `main.lua`. Construye el motor una vez y luego reenvía los callbacks de
LÖVE:

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

La resolución lógica es `320 x 180`, mientras que la ventana es `960 x 540`. Con
`pixelPerfect = true`, el motor escala el juego con filtrado nearest-neighbor,
así que tu escena puede usar coordenadas pequeñas como `(8, 8)`.

## 2. Definir las acciones de entrada

Crea `game/inputMaps.lua`. Las acciones son arrays con nombre de teclas de LÖVE:

```lua
return {
    move_left = { "left", "a" },
    move_right = { "right", "d" },
    move_up = { "up", "w" },
    move_down = { "down", "s" },
}
```

Cada acción debe tener al menos un atajo, los índices deben ser contiguos y una
misma acción no puede listar la misma tecla dos veces.

## 3. Crear la primera escena

Crea `game/scenes/hello.lua`. Las escenas extienden la clase `Scene` del motor y
reciben un `GameContext` en su constructor:

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

    -- Mantiene la velocidad del movimiento diagonal.
    if dx ~= 0 and dy ~= 0 then
        local length = math.sqrt(dx * dx + dy * dy)
        dx, dy = dx / length, dy / length
    end

    self.x = self.x + dx * self.speed * dt
    self.y = self.y + dy * self.speed * dt

    -- Mantiene el cuadrado dentro del viewport lógico.
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

Crea `game/resources/definitions.lua` con una tabla vacía por ahora:

```lua
return {}
```

## 4. Ejecutar el juego

Desde la raíz del proyecto:

```sh
love .
```

Deberías ver una escena de `320 x 180` con instrucciones y un cuadrado que se
mueve dentro de la pantalla.

## ¿Qué acaba de pasar?

Cuando LÖVE llama a `love.load`, `Engine:load()`:

1. Aplica la configuración de la ventana y el color de fondo.
2. Crea el viewport de resolución virtual.
3. Apila `initialScene` en la pila de escenas.
4. Llama a los callbacks `onLoad` y `onEnter` de la escena.

En cada frame, `Engine:update()` actualiza la escena, luego el audio y por último
la entrada. `InputManager:isDown(action)` comprueba las teclas asignadas a esa
acción. Al final de la actualización, el gestor borra su estado de "recién
pulsado" y "recién soltado".

`Engine:draw()` dibuja la pila de escenas a través del viewport, que escala la
resolución lógica a la ventana.

Los cambios de escena se encolan. Si una escena llama a
`sceneManager:replace(...)` o `sceneManager:push(...)`, la transición se procesa
al final de la actualización del gestor de escenas, después de que la escena
actual haya terminado de actualizarse.

## Siguientes pasos

### Cargar un recurso de imagen

Añade un asset en `game/assets/player.png` y luego regístralo:

```lua
return {
    player = {
        type = "image",
        path = "game/assets/player.png",
    },
}
```

Cárgalo en `onLoad` y dibújalo en lugar del rectángulo:

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

La escena es el consumidor del recurso. `releaseAll(self)` en `onDestroy` informa
al gestor de recursos de que la escena ya no lo necesita, y el recurso se libera
cuando ningún otro consumidor lo necesita.

### Añadir otra escena

Crea `game/scenes/world.lua` con la misma estructura que `Hello` y luego solicita
una transición desde la primera escena:

```lua
if self.context.inputManager:isJustPressed("move_up") then
    self.context.sceneManager:replace("world")
end
```

`world` se resuelve como `game/scenes/world.lua` porque el `scenesPath`
predeterminado es `game.scenes`. Usa `push` en lugar de `replace` cuando la
escena actual deba permanecer en memoria, por ejemplo para abrir un menú de
pausa.

### Explorar el motor

- [Introducción](/es/getting-started/introduction) para conocer los conceptos
  clave del motor.
- [Descripción general de la arquitectura](/es/architecture/overview) para saber
  cómo encajan los sistemas.
- [Referencia de API](/es/api/) para detalles a nivel de módulo.

## Errores comunes

- **La clase de escena no tiene una función `new`.** Cada módulo de escena debe
  devolver una tabla con un constructor `new`.
- **No se encuentra la escena.** Revisa el identificador `initialScene` y el
  prefijo `scenesPath`. Los puntos se traducen a separadores de carpeta.
- **Los recursos se cargan en el constructor.** Cárgalos en `onLoad`, donde la
  escena está lista y los fallos son más fáciles de diagnosticar.
- **La entrada no hace nada.** Reenvía `love.keypressed` y `love.keyreleased` al
  motor, y confirma que el nombre de la acción coincide con
  `game/inputMaps.lua`.
- **Una transición ocurre de inmediato.** Las transiciones de escena se difieren
  hasta el final de la actualización del gestor de escenas, lo cual es
  intencional. No esperes que la pila de escenas cambie a mitad de `update`.
- **Los recursos permanecen cargados.** Libera cada consumidor en `onDestroy` con
  `resourceManager:releaseAll(self)`.
