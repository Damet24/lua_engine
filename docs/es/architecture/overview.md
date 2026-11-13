# Descripción general de la arquitectura

Astra 2D está organizado como un conjunto pequeño de módulos independientes que
se conectan mediante un único objeto `Engine`. El motor posee los mecanismos (el
bucle de frames, la pila de escenas, los recursos, la entrada, el audio, las
cámaras y el renderizado); tu juego posee las reglas y el contenido.

Esta página explica cómo se relacionan los módulos entre sí. Documenta lo que el
motor hace realmente hoy, para que la referencia de módulos y las guías se
construyan sobre un modelo mental compartido.

## El motor de un vistazo

En la parte superior, `main.lua` crea un `Engine` y le reenvía los callbacks de
LÖVE. El motor construye los servicios compartidos, carga las escenas a través
del gestor de escenas, y cada escena coordina su propio `World`, sus cámaras y su
renderizado.

```text
                          main.lua
        reenvía load / update / draw / quit / keypressed de LÖVE
                              │
                              ▼
┌───────────────────────────────────────────────────────────────────┐
│ Engine                                                             │
│   ciclo de frames · ventana · viewport (Shove)                     │
│                                                                    │
│   posee ──▶ ResourceManager   GameContext   SceneLoader            │
│             SceneManager      AudioManager  InputManager           │
└──────────────────────────────┬────────────────────────────────────┘
                               │ Engine:load() apila la escena inicial
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneManager              pila de { id, scene }                    │
│   push · pop · replace · clear · clearAndPush   (diferido)         │
└──────────────────────────────┬────────────────────────────────────┘
                               │ carga a través de
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ SceneLoader        scenesPath .. "." .. sceneName  →  Scene.new()  │
└──────────────────────────────┬────────────────────────────────────┘
                               │ construye
                               ▼
┌───────────────────────────────────────────────────────────────────┐
│ Scene                 ciclo de vida + una parte del juego          │
│   posee ──▶ World (ECS + física)   CameraManager                   │
│             RenderPipeline         TilemapRender                   │
└───────────────────────────────────────────────────────────────────┘

Servicios compartidos accesibles desde una escena mediante su GameContext:
  GameContext ──▶ resourceManager · audioManager · sceneManager
                  inputManager · viewport
  ResourceManager ── compartido por ──▶ AudioManager y Escenas (consumidores)
```

Dos ideas facilitan seguir el resto de la arquitectura:

- **El motor construye, el juego describe.** `Engine.new(config)` recibe
  descripciones (una escena inicial, definiciones de recursos, mapas de entrada,
  resoluciones) y las convierte en objetos vivos. Las escenas nunca construyen
  servicios del motor.
- **Las escenas ven un `GameContext`, no el motor.** Todo lo que una escena
  necesita se le entrega a través del contexto, lo que mantiene a las escenas
  desacopladas de cómo se ensambla el motor.

## El ciclo de vida de un frame

Astra 2D no reemplaza el bucle principal de LÖVE. `main.lua` reenvía los
callbacks que necesita, y cada uno se corresponde con un método del motor:

| Callback de LÖVE | Método del motor | Qué ocurre |
| --- | --- | --- |
| `love.load` | `Engine:load()` | Aplica la configuración de la ventana y el color de fondo, crea el viewport, apila `initialScene` y procesa la transición pendiente. |
| `love.update(dt)` | `Engine:update(dt)` | Actualiza la pila de escenas, luego el audio y por último limpia el estado de entrada. |
| `love.draw` | `Engine:draw()` | Dibuja la pila de escenas dentro del viewport de resolución virtual. |
| `love.keypressed(key)` | `Engine:keypressed(key)` | Reenvía la tecla al gestor de entrada. |
| `love.keyreleased(key)` | `Engine:keyreleased(key)` | Reenvía la tecla al gestor de entrada. |
| `love.quit` | `Engine:quit()` | Destruye la pila de escenas, detiene el audio y libera todos los recursos. |

El orden dentro de `Engine:update` es importante:

1. `SceneManager:update(dt)` actualiza las escenas activas y, al final, procesa
   las transiciones solicitadas durante el frame.
2. `AudioManager:update(dt)` libera los sonidos que terminaron de reproducirse.
3. `InputManager:update()` limpia el estado de "recién pulsado" y "recién
   soltado", para que las escenas puedan leerlo durante su propia actualización.

La entrada se limpia al final a propósito: una escena lee `isJustPressed` mientras
se ejecuta, y el flag se descarta solo después de que todas las escenas hayan
tenido la oportunidad de reaccionar.

## Responsabilidades de los módulos

### Engine

`engine/engine.lua` es la raíz de composición. Es el único módulo que sabe cómo
ensamblar el resto del motor.

**Responsabilidades**

- Normalizar y validar la configuración, completando valores predeterminados y
  rechazando valores inválidos de forma temprana.
- Crear la ventana (cuando se proporciona una tabla `window`), el color de fondo
  y el viewport.
- Construir los servicios compartidos e inyectar en el `GameContext` los que las
  escenas necesitan.
- Impulsar el frame: cargar, actualizar, dibujar, entrada y apagado.

**Relaciones**

- Posee `ResourceManager`, `GameContext`, `SceneLoader`, `SceneManager`,
  `AudioManager` e `InputManager`.
- Construye primero el contexto y luego se lo entrega al `SceneLoader`, que a su
  vez se lo entrega a cada escena que crea.
- Establece `context.audioManager`, `context.sceneManager`,
  `context.inputManager` y `context.viewport` a medida que esos servicios están
  disponibles.
- Envuelve `SceneManager:draw()` en el `beginDraw`/`endDraw` del viewport, de modo
  que todo el renderizado de escenas ocurre en la resolución lógica.

### GameContext

`engine/core/gameContext.lua` es un contenedor ligero de servicios. Es la
frontera entre el motor y el juego.

**Responsabilidades**

- Transportar los servicios compartidos que las escenas pueden usar.
- Evitar que las escenas accedan al interior del motor o construyan servicios
  por su cuenta.

**Relaciones**

- Lo crea `Engine` con el `resourceManager` y el `audioManager`; el motor luego
  añade `sceneManager`, `inputManager` y `viewport`.
- Se pasa por referencia al `SceneLoader`, que lo pasa a cada constructor de
  escena. Todas las escenas de un motor comparten el mismo contexto.
- Expone deliberadamente una superficie pequeña. No es un localizador global de
  servicios: añadir un campo nuevo es una decisión arquitectónica, no una
  comodidad.

### SceneManager y SceneLoader

Juntos convierten un *identificador* de escena en una escena en ejecución, y
administran la pila de escenas.

**SceneManager** (`engine/scene/sceneManager.lua`)

- Mantiene la pila de entradas `{ id, scene }`.
- Acepta solicitudes de transición: `push`, `pop`, `replace`, `clear` y
  `clearAndPush`.
- Aplica esas solicitudes en `processPendingOperations`, que se ejecuta al final
  de `SceneManager:update` (y de forma explícita durante `Engine:load` y
  `Engine:quit`).
- Ejecuta los callbacks del ciclo de vida en un orden definido.
- Decide qué escenas se actualizan y se dibujan, según los flags `updateBelow` y
  `drawBelow` de cada escena.

**SceneLoader** (`engine/scene/sceneLoader.lua`)

- Resuelve un nombre de escena a un módulo: `scenesPath .. "." .. sceneName`, de
  modo que `levels.level01` se convierte en `game/scenes/levels/level01.lua`.
- Hace `require` de ese módulo, comprueba que devuelva una clase con un
  constructor `new`, y llama a `SceneClass.new(context)`.

**Relaciones y comportamiento**

- `SceneManager` nunca sabe cómo se construye una escena; delega eso en el
  loader. `SceneLoader` nunca sabe nada de la pila.
- Las transiciones son **diferidas**. Llamar a `push`, `pop` o `replace` solo
  registra una solicitud. La pila cambia al final de la actualización, así que
  una escena nunca se destruye mientras todavía se está ejecutando. No esperes
  que la pila cambie a mitad de `update`.
- Las escenas solicitan transiciones a través de `context.sceneManager`, no
  mediante un campo en la escena. La dependencia `manager` que `SceneManager`
  adjunta a cada solicitud actualmente no la usa el loader.

Los callbacks del ciclo de vida se invocan en este orden:

| Operación | Orden de callbacks |
| --- | --- |
| `push` | `onLoad` de la nueva escena, `onExit` de la escena anterior, `onEnter` de la nueva escena |
| `pop` | `onExit` de la escena superior, `onDestroy` de la escena superior, `onEnter` de la escena anterior |
| `replace` | `onLoad` de la nueva escena, `onExit` de la escena anterior, `onDestroy` de la escena anterior, `onEnter` de la nueva escena |
| `clearAndPush` | `onLoad` de la nueva escena, `onExit` de todas las escenas anteriores, `onDestroy` de todas las escenas anteriores, `onEnter` de la nueva escena |

`onLoad` se ejecuta una vez por instancia de escena, `onEnter`/`onExit` se
ejecutan cada vez que una escena pasa a primer plano o lo abandona, y `onDestroy`
se ejecuta una vez cuando la instancia se descarta.

### Scene y World

Una `Scene` es una parte autocontenida del juego. Un `World` es el estado ECS que
le pertenece. La escena posee el mundo; el mundo no sabe nada de la escena.

**Scene** (`engine/scene/scene.lua`)

- Proporciona los callbacks del ciclo de vida: `onLoad`, `onEnter`, `onExit`,
  `onDestroy`.
- Proporciona los hooks por frame: `update(dt)` y `draw()`.
- Declara dos flags, `updateBelow` y `drawBelow` (ambos `false` por defecto), que
  indican al `SceneManager` si las escenas de debajo también deben actualizarse o
  dibujarse.

Las escenas del juego extienden `Scene` y actúan como coordinadoras. Un nivel,
por ejemplo, carga sus recursos, crea un `World`, registra sistemas, construye un
`CameraManager` y un `RenderPipeline`, y dibuja su tilemap y sus entidades. La
escena no administra la pila ni ejecuta transiciones.

**World** (`engine/ecs/world.lua`)

- Almacena las entidades como identificadores numéricos simples y los componentes
  como `components[name][entity] = data`.
- Mantiene una lista ordenada de sistemas. Cada sistema puede implementar
  `init(world)`, `update(world, dt)` y `draw(world)`.
- Posee un `EventManager` (`engine/core/events.lua`) para eventos diferidos, y un
  mundo físico (`engine/physics/physics_world.lua`, respaldado por
  `love.physics`).
- Ejecuta los sistemas en el orden en que se añadieron, despacha los eventos
  encolados y luego vacía las entidades marcadas para destrucción.

**Relaciones**

- Una escena crea exactamente un `World` para su propio estado; escenas distintas
  tienen mundos independientes.
- Los sistemas se comunican con el mundo mediante consultas como
  `world:query({ Components.Transform, Components.Velocity }, ...)`. Los nombres
  de los componentes viven en `engine/ecs/component.lua`.
- La física se integra a través de sistemas: `PhysicsFactory` construye cuerpos
  de LÖVE a partir de `Transform` + `RigidBody` + `Collider`, y `PhysicsSystem`,
  `PhysicsMovementSystem`, `PhysicsSyncSystem` y `CollisionSystem` conectan el
  ECS con el mundo físico. `CollisionSystem` traduce los contactos en eventos
  `collision_started` / `collision_ended` sobre `world.events`.

### ResourceManager

`engine/resources/resourceManager.lua` centraliza la carga, la reutilización y la
liberación de imágenes, sonidos y fuentes. Es independiente del sistema de
escenas y se puede usar desde cualquier módulo.

**Responsabilidades**

- Cargar un recurso la primera vez que se solicita y luego devolver la instancia
  en caché.
- Llevar un registro de qué **consumidores** dependen de cada recurso.
- Liberar un recurso automáticamente cuando su último consumidor lo libera.

**Relaciones**

- Las definiciones provienen de `resourceDefinitions`; cada definición tiene un
  `type` que selecciona un cargador de la tabla de cargadores (`image`, `sound` y
  `font` por defecto, en `engine/resources/loaders/`).
- `get(consumer, resourceId)` registra al consumidor y devuelve el valor cargado.
- `release(consumer, resourceId)` elimina un consumidor y libera el recurso
  cuando no queda ninguno. `releaseAll(consumer)` y `releaseAllResources()`
  cubren los casos masivos.
- Los consumidores son claves arbitrarias, normalmente el propio objeto. Las
  escenas pasan `self` y llaman a `resourceManager:releaseAll(self)` en
  `onDestroy`; `AudioManager` también es un consumidor y libera sus fuentes en
  `shutdown`.
- Como el gestor es compartido, la misma imagen o sonido nunca se carga dos
  veces, incluso cuando dos escenas lo usan al mismo tiempo.

### InputManager y AudioManager

Estos son los dos servicios que las escenas consultan en cada frame. Ambos son
accesibles desde el `GameContext`.

**InputManager** (`engine/input/inputManager.lua`)

- Convierte acciones con nombre en atajos de teclado. Una acción como `move_left`
  se asigna a uno o más nombres de tecla de LÖVE.
- Lleva tres estados de tecla: `pressed`, `justPressed` y `justReleased`.
- Expone `isDown(action)`, `isJustPressed(action)` e `isJustReleased(action)`.

Relaciones: `Engine` le reenvía `love.keypressed` / `love.keyreleased`, y
`Engine:update` limpia los estados transitorios al final del frame. Las escenas y
los sistemas leen las acciones a través de `context.inputManager`; un sistema de
juego como `PlayerSystem` recibe el gestor directamente cuando se construye. Los
mapas de entrada se validan en la construcción: cada acción necesita al menos un
atajo único, con índices contiguos.

**AudioManager** (`engine/audio/audioManager.lua`)

- Reproduce música y efectos de sonido, con volúmenes independientes de master,
  música y efectos.
- Mantiene una pista de música actual y un conjunto de efectos de sonido activos.
- Libera los efectos terminados durante `update` y todo durante `shutdown`.

Relaciones: depende del `ResourceManager` y es él mismo un consumidor de
recursos. `playMusic` usa la fuente de música compartida; `playSound` clona la
fuente para que varios efectos puedan solaparse. `Engine:update` llama a su
`update`, y `Engine:quit` llama a `shutdown`.

### CameraManager y cámaras

`engine/camera/cameraManager.lua` y `engine/camera/camera.lua` dan a una escena
una vista de su contenido en coordenadas de mundo.

**Responsabilidades**

- `CameraManager` mantiene cámaras con nombre y selecciona la activa. `add`,
  `get`, `setActive`, `getActive` y `remove` gestionan el conjunto; los
  identificadores duplicados o inexistentes lanzan errores.
- `Camera` expone posición, zoom, rotación, viewport, conversión de coordenadas y
  dibujado. Envuelve un adaptador sobre el `hump.camera` incluido
  (`engine/camera/adapters/humpCamera.lua`).

**Relaciones**

- Las cámaras son **por escena**. Una escena crea su `CameraManager` en `onLoad`
  y lo descarta en `onDestroy`. No se selecciona nada automáticamente.
- `camera:draw(function)` adjunta la cámara, ejecuta el callback y la vuelve a
  separar, restaurando la pila de gráficos y el scissor incluso si el callback
  falla. Las escenas pasan el `draw` del pipeline de render como ese callback.
- Los viewports de las cámaras usan coordenadas **lógicas**. Para convertir una
  posición del ratón, primero llama a
  `context.viewport.screenToViewport(x, y)` y luego a
  `camera:worldCoords(x, y)`.

### Renderizado y el viewport

El renderizado se reparte entre el viewport (resolución lógica), la cámara
(transformación de mundo) y el pipeline de render (orden de capas). Cada capa
escala a la que contiene:

```text
Ventana de LÖVE (píxeles físicos)
  └─ viewport / Shove          resolución lógica: rendering.width x rendering.height
       └─ Camera               transformación de mundo: posición, zoom, rotación
            └─ RenderPipeline   orden de dibujo: capas de tilemap y entidades por capa
```

**Viewport** (`engine/lib/shove/shove.lua`, creado por `Engine:load`)

- Escala la resolución lógica configurada por `rendering.width` /
  `rendering.height` a la ventana física. `pixelPerfect = true` usa escalado
  entero y filtrado nearest-neighbor.
- Expone `getViewportDimensions()` y `screenToViewport(x, y)`.
- `Engine:draw` llama a `viewport.beginDraw()` / `viewport.endDraw()` alrededor de
  la pila de escenas, de modo que cada escena dibuja en coordenadas lógicas.

**RenderPipeline** (`engine/graphics/render_pipeline.lua`)

- Reúne callbacks de dibujo etiquetados con una capa numérica.
- `draw()` los ordena por capa y luego por orden de inserción, lo que da un
  resultado determinista, y llama a cada callback.

**Renderizadores**

- `TilemapRender` (`engine/tilemap/tilemaprender.lua`) convierte un mapa de Tiled
  y sus tilesets en elementos del pipeline, uno por capa de tiles visible.
- `RenderSystem` (`engine/ecs/systems/renderSystem.lua`) envía cada entidad con
  `Transform` y `Sprite`, usando `sprite.layer` para el orden.

Una escena normalmente limpia el pipeline, envía el tilemap y las entidades, y
luego dibuja el pipeline dentro de la cámara activa. La interfaz en espacio de
pantalla se dibuja después de la cámara, directamente en coordenadas lógicas.

## Cómo trabajan juntos los módulos

- **Transiciones diferidas.** Las escenas nunca modifican la pila directamente.
  Llaman a `sceneManager:push/pop/replace/...`, y el `SceneManager` aplica las
  solicitudes al final de la actualización de escenas. Esto mantiene intacta la
  escena en ejecución mientras termina su frame.
- **Los consumidores comparten recursos.** El `ResourceManager` es el único lugar
  donde se cargan recursos. Las escenas y el `AudioManager` son consumidores; un
  recurso permanece cargado mientras algún consumidor lo necesite y se libera
  cuando el último lo suelta.
- **Actualización y dibujo son políticas separadas.** `updateBelow` y
  `drawBelow` deciden, por escena, si las escenas de debajo siguen simulándose o
  siguen dibujándose. Un menú de pausa puede dibujar el nivel que tiene debajo
  mientras detiene su simulación, y una escena puede actualizarse sin dibujarse.
- **Una única cadena de coordenadas.** Ventana física → viewport lógico → mundo
  de la cámara → pipeline. Las conversiones ocurren solo en las fronteras:
  `screenToViewport` (física → lógica) y `worldCoords` (lógica → mundo).

## Dónde encaja el juego

Tu juego proporciona descripciones y contenido; el motor proporciona los
mecanismos.

| Tu juego proporciona | El motor lo convierte en |
| --- | --- |
| `initialScene` | La primera escena apilada en la pila. |
| `scenesPath` | El prefijo de módulo usado para cargar escenas (por defecto `game.scenes`). |
| `resourceDefinitions` / `resourceLoaders` | Las definiciones y los cargadores usados por el `ResourceManager`. |
| `inputMaps` | La tabla de acciones usada por el `InputManager`. |
| `window` / `rendering` / `audio` | Modo de ventana, resolución lógica, fondo y volúmenes. |
| Módulos de escena | Instancias creadas por el `SceneLoader` y dirigidas por el `SceneManager`. |
| Mundos, sistemas, cámaras, pipelines | Construidos dentro del `onLoad` de cada escena. |

## Notas de diseño

`engine/scenes.md` es un documento de diseño que describe la dirección prevista
del sistema de escenas. Algunas de sus ideas aún no están implementadas, entre
ellas un `SceneRegistry`/`SceneFactory`, reglas de transición definidas por el
juego, validación del contexto de origen para solicitudes pendientes y un
`GameState`. Donde esta página y ese documento no coincidan, esta página describe
la implementación actual.

El `GameContext` vive en `engine/core/gameContext.lua`. Requiere un
`resourceManager` y un `audioManager` en la construcción y trata `sceneManager`
como opcional, porque el gestor de escenas se construye después del contexto
(necesita el `SceneLoader`, que necesita el contexto). `inputManager` y
`viewport` los añade `Engine` una vez que existen.

## Siguientes pasos

- [Introducción](/es/getting-started/introduction) para los conceptos clave.
- [Tu primer proyecto](/es/getting-started/first-project) para construir una
  escena con entrada, movimiento y un recurso.
- La referencia de API para detalles a nivel de módulo.
