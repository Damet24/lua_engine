# Inicio rápido

## Requisitos

- [LÖVE 11.5](https://love2d.org/). El proyecto se ha probado con esa versión;
  otras versiones no están verificadas.
- Los archivos del repositorio, incluidos `game/assets` y `lua/lib`.

Desde la raíz del proyecto, ejecuta:

```sh
love .
```

El proyecto de ejemplo inicia en el menú principal. Las acciones configuradas
incluyen `return` para aceptar, `escape` para pausar, flechas o `a`/`d` para
moverse y `space` para saltar.

## Punto de entrada

El archivo `main.lua` crea el motor con la configuración del juego y reenvía
los callbacks de LÖVE:

```lua
local Engine = require("lua.engine.engine")

local engine = Engine.new({
    initialScene = "mainMenu",
    resourceDefinitions = require("game.resources.definitions"),
    resourceLoaders = require("game.resources.loaders"),
    inputMaps = require("game.inputMaps"),
    window = { width = 1280, height = 720, fullscreen = false,
               resizable = false, vsync = true },
    rendering = { width = 640, height = 360, pixelPerfect = true },
})

function love.load() engine:load() end
function love.update(dt) engine:update(dt) end
function love.draw() engine:draw() end
function love.keypressed(key) engine:keypressed(key) end
function love.keyreleased(key) engine:keyreleased(key) end
function love.quit() engine:quit() end
```

El proyecto actual no registra `love.quit`; el ejemplo lo incluye para ejecutar
la limpieza explícita del motor al salir. Consulta [Escenas](Escenas) para
crear una escena inicial.

## Configuración

| Campo | Descripción |
| --- | --- |
| `initialScene` | Obligatorio. Identificador de la primera escena, por ejemplo `mainMenu` o `levels.level01`. |
| `inputMaps` | Obligatorio. Tabla de acciones y sus teclas; puede estar vacía. |
| `scenesPath` | Prefijo de módulos de escena. Predeterminado: `game.scenes`. |
| `resourceDefinitions`, `resourceLoaders` | Tablas de recursos y cargadores. Por defecto son tablas vacías. |
| `window` | Opcional. Si se proporciona, `width` y `height` son obligatorios; `fullscreen`, `resizable` y `vsync` son booleanos. |
| `rendering` | Resolución lógica. Por defecto: `1280 x 720`, con `pixelPerfect = false`. |

Cuando se proporciona `window`, sus valores predeterminados son
`fullscreen = false`, `resizable = true` y `vsync = true`. Si se omite,
el motor no cambia el modo de ventana. Con `pixelPerfect = true`, Shove utiliza
escalado entero y filtrado nearest; si la ventana es menor que la resolución
lógica, el viewport se recorta.

`Engine:load()` debe llamarse una vez. `update`, `draw` y los eventos de teclado
se delegan al motor; `Engine:quit()` destruye escenas y libera recursos.
La resolución y las cámaras se describen en
[Renderizado y cámaras](Renderizado-y-camaras).