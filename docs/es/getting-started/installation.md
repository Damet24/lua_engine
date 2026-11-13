# Instalación

Astra 2D se ejecuta sobre [LÖVE](https://love2d.org/) y no requiere un paso de
compilación aparte. Esta página cubre los requisitos, la ejecución del proyecto
de ejemplo y cómo añadir el motor a un proyecto nuevo.

## Requisitos

- **LÖVE 11.5.** El proyecto está probado con esta versión. Otras versiones no
  están verificadas.
- **Git** (opcional). Puedes descargar el repositorio como un archivo en lugar de
  clonarlo.
- **Los archivos del repositorio.** Conserva `engine/lib/` junto al resto del
  motor, porque el motor importa sus bibliotecas incluidas desde ahí.

Lua viene incluido con LÖVE. No se necesita ningún gestor de paquetes ni módulos
Lua adicionales.

## Ejecutar el proyecto de ejemplo

Clona el repositorio e inicia LÖVE desde la raíz del proyecto:

```sh
git clone https://github.com/Damet24/lua_engine.git
cd lua_engine
love .
```

En Windows, también puedes arrastrar la carpeta del proyecto sobre el ejecutable
de LÖVE, o añadir el directorio de instalación de LÖVE a tu `PATH` y ejecutar el
mismo comando.

El ejemplo comienza en el menú principal. Sus atajos se definen en
`game/inputMaps.lua`:

| Acción | Teclas por defecto |
| --- | --- |
| Aceptar | `Return` |
| Pausa / retroceder | `Escape` |
| Moverse a la izquierda | `Left`, `A` |
| Moverse a la derecha | `Right`, `E` |
| Saltar | `Space` |

Pulsa `Return` para entrar al nivel, `Escape` para abrir el menú de pausa y las
teclas de movimiento para controlar al jugador.

## Usar el motor en otro proyecto

1. Copia la carpeta `engine/` en la raíz de tu proyecto LÖVE. Conserva el nombre
   de la carpeta como `engine`, porque todos los módulos del motor se importan
   con el prefijo `engine.`.

   ```text
   my-game/
     engine/
       engine.lua
       lib/
       ...
     game/
       inputMaps.lua
       resources/
       scenes/
     main.lua
   ```

2. Crea los módulos de juego que el motor necesita. Como mínimo, proporciona una
   tabla de mapas de entrada, una tabla de definiciones de recursos y una escena
   inicial.

3. Crea `main.lua` y reenvía los callbacks de LÖVE al motor:

   ```lua
   local Engine = require("engine.engine")

   local engine = Engine.new({
       initialScene = "hello",
       scenesPath = "game.scenes",
       inputMaps = require("game.inputMaps"),
       resourceDefinitions = require("game.resources.definitions"),
       audio = {
           masterVolume = 0.1,
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
           backgroundColor = { 0.18, 0.25, 0.34 },
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

4. Ejecuta el proyecto desde su raíz:

   ```sh
   love .
   ```

Con `scenesPath = "game.scenes"` e `initialScene = "hello"`, el motor carga
`game/scenes/hello.lua`. Los identificadores de escena usan puntos en lugar de
barras, así que `levels.level01` se resuelve como
`game/scenes/levels/level01.lua`. La escena `hello` se crea en
[Tu primer proyecto](/es/getting-started/first-project); usa el identificador de
una escena que ya exista en tu proyecto.

### Configuración obligatoria

| Campo | Descripción |
| --- | --- |
| `initialScene` | Obligatorio. Identificador de la primera escena a cargar. |
| `inputMaps` | Obligatorio. Tabla de nombres de acción y sus teclas. Puede estar vacía, pero la tabla debe existir. |
| `audio` | Opcional. `masterVolume`, `musicVolume` y `sfxVolume` tienen como valor predeterminado `1.0`. |
| `scenesPath` | Prefijo usado para importar escenas. Por defecto: `game.scenes`. |
| `resourceDefinitions` | Tabla de identificadores de recursos a definiciones. Por defecto, una tabla vacía. |
| `resourceLoaders` | Tabla de cargadores. Por defecto, los cargadores integrados de imagen, sonido y fuente. |
| `window` | Opcional. Si se proporciona, `width` y `height` son obligatorios. Los valores por defecto son `fullscreen = false`, `resizable = true` y `vsync = true`. |
| `rendering` | Resolución lógica. Por defecto `1280 x 720`, `pixelPerfect = false` y fondo negro. |

`rendering.backgroundColor` acepta una tabla RGB o RGBA con componentes entre `0`
y `1`. El motor lo aplica cuando se ejecuta `Engine:load()`.

## Solución de problemas

### `module 'engine.engine' not found`

Ejecuta LÖVE desde la raíz del proyecto y asegúrate de que la carpeta del motor
se llame `engine` y esté junto a `main.lua`. Las bibliotecas incluidas deben
permanecer en `engine/lib/`.

### `Failed to load scene '...'`

El motor combina `scenesPath` y el identificador de la escena para construir la
ruta del módulo Lua. Revisa ambos valores y confirma que el archivo existe. Por
ejemplo, el identificador `levels.level01` se resuelve como
`game/scenes/levels/level01.lua` cuando `scenesPath` es `game.scenes`. El archivo
de la escena debe devolver una clase con una función `new`.

### `Resource '...' is not defined`

Añade el identificador del recurso a `game/resources/definitions.lua`, o a la
tabla que pases como `resourceDefinitions`. Los recursos se cargan cuando se
llama a `ResourceManager:get()`, normalmente desde el callback `onLoad` de una
escena.

### `No loader registered for resource type '...'`

El `type` de la definición debe coincidir con una clave de la tabla de
cargadores. Los cargadores integrados son `image`, `sound` y `font`.

### Se lanza un error de mapa de entrada

Cada acción debe ser un array de uno o más nombres de tecla únicos, sin huecos ni
atajos duplicados en la misma acción. Por ejemplo:

```lua
return {
    jump = { "space" },
    move_left = { "left", "a" },
    move_right = { "right", "d" },
}
```

### No se puede crear la ventana

`Engine:load()` llama a `love.window.setMode`. Si falla, comprueba que la
resolución solicitada sea compatible, que el modo de pantalla completa esté
disponible y que el entorno pueda crear una ventana gráfica. Los entornos sin
interfaz gráfica no pueden ejecutar una ventana de LÖVE.

## Siguientes pasos

Continúa con [Tu primer proyecto](/es/getting-started/first-project) para
construir una escena pequeña con entrada, movimiento y un recurso.
