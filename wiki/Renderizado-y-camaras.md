# Renderizado y cámaras

## Resolución lógica

El motor usa Shove para dibujar escenas en `rendering.width` y
`rendering.height`, independientemente del tamaño de la ventana. Con
`pixelPerfect = false` escala proporcionalmente; con `true` usa escalado entero
y filtrado nearest. Shove es un módulo compartido: solo un motor debería
renderizar a la vez.

Para convertir una posición de ventana a coordenadas lógicas:

```lua
local inside, x, y = self.context.viewport.screenToViewport(mouseX, mouseY)
if inside then
    -- x, y están dentro del viewport lógico.
end
```

## Pipeline y mapas

`RenderPipeline` ordena elementos por capa numérica y conserva el orden de
inserción para capas iguales. El nivel prepara el pipeline en cada dibujo:

```lua
self.pipeline:clear()
self.tilemapRender:submit(self.pipeline)
RenderSystem.submit(self.world, self.pipeline)
self.pipeline:draw()
```

`TilemapRender` dibuja capas `tilelayer` de los mapas exportados como módulos
Lua. `game/scenes/levels/level01.lua` muestra cómo crear el renderer con los
tilesets y procesar manualmente los objetos de la capa `walls` como colisiones
rectangulares. El renderer no convierte automáticamente todos los objetos de
Tiled en cuerpos físicos.

## Cámaras por escena

Una escena crea y gestiona su propio `CameraManager`:

```lua
local CameraManager = require("lua.engine.camera.cameraManager")

function MiEscena:onLoad()
    local width, height = self.context.viewport.getViewportDimensions()
    self.cameraManager = CameraManager.new()
    self.cameraManager:add("mundo", {
        x = width / 2, y = height / 2,
        viewport = { width = width, height = height },
    })
    self.cameraManager:setActive("mundo")
end

function MiEscena:draw()
    self.cameraManager:getActive():draw(function()
        self.pipeline:draw()
    end)
    -- Dibuja aquí la interfaz, fuera de la transformación de cámara.
end
```

`add(id, config)` crea una cámara, `get(id)` la recupera y `setActive(id)` la
selecciona. No hay selección automática; `getActive()` devuelve `nil` hasta
seleccionar una cámara y también después de eliminar la activa con `remove(id)`.
Los IDs duplicados o inexistentes producen errores. Una segunda cámara puede
usarse explícitamente con `get(id):draw(...)`, sin cambiar la activa.

La posición es el centro de la cámara en el mundo. Su API incluye
`setPosition`, `getPosition`, `move`, `setZoom`, `getZoom`, `setRotation`,
`getRotation`, `setViewport`, `worldCoords` y `cameraCoords`. Los valores
iniciales son `(0, 0)`, zoom `1` y rotación `0`; el zoom debe ser positivo.
El nivel de ejemplo mueve su cámara para seguir la posición del cuerpo del
jugador; el gestor no proporciona seguimiento automático.

Un viewport especifica `x`, `y`, `width` y `height` en coordenadas lógicas;
`clip = true` limita el dibujo a ese rectángulo, intersectando el recorte
existente. Para recortar, la transformación exterior debe estar alineada con los
ejes. Configura explícitamente el viewport con una resolución virtual.

Las conversiones de cámara usan coordenadas **lógicas**, no píxeles físicos de
la ventana. Convierte primero la posición de pantalla con `screenToViewport` y,
si está dentro, usa `camera:worldCoords(x, y)`. `camera:draw(callback)` restaura
el estado gráfico incluso si el callback falla; el callback no debe retirar la
pila gráfica de la cámara. También existen `attach()` y `detach()` para gestionar
manualmente la transformación.