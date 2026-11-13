# Niveles

Los niveles del juego comparten `level.lua`: crea la camara, el mundo, las
paredes de la capa `walls`, el jugador, los sistemas y el pipeline. Cada
instancia mantiene su propio estado y libera sus recursos al destruirse.

Para crear un nivel, exporta su mapa desde Tiled como modulo Lua y crea una
escena que proporcione ese mapa y el punto inicial del jugador:

```lua
local Level = require("game.scenes.levels.level")
local map = require("game.maps.mi_mapa")

local MiNivel = {}

function MiNivel.new(context)
	return Level.new(context, {
		map = map,
		spawn = { x = 80, y = 32 },
	})
end

return MiNivel
```

La escena se selecciona con su identificador, por ejemplo `levels.mi_nivel`.
El jugador, la gravedad, los controles y la pausa son comunes a todos los
niveles. Por defecto se usa el recurso `terrain` para el tileset de nombre
`Terrain (16x16)`; para usar otros tilesets, proporciona una tabla `tilesets`:

```lua
tilesets = {
	["Nombre en Tiled"] = { resource = "mi_terreno", tilewidth = 16, tileheight = 16 },
}
```

El recurso debe estar registrado en `game.resources.definitions`. El mapa debe
ser rectangular y tener origen `(0, 0)`. Las paredes son objetos rectangulares
en una capa llamada `walls`. La camara sigue al jugador y se limita a ese mapa;
el calculo actual asume que no se rota la camara.