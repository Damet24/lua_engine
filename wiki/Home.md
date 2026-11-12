# Documentación del motor

Este motor 2D, en desarrollo, utiliza Lua y [LÖVE](https://love2d.org/). El
repositorio incluye un juego de ejemplo que combina escenas, entrada, recursos,
entidades, física, mapas y cámaras.

Esta wiki describe la implementación actual, no una API estable: las interfaces
pueden cambiar mientras evoluciona el motor.

## Primeros pasos

- [Inicio rápido](Inicio-rapido): requisitos, ejecución y configuración.
- [Escenas](Escenas): ciclo de vida, pila y contexto.
- [Entrada y recursos](Entrada-y-recursos): acciones y gestion de recursos.

## Desarrollo de juegos

- [ECS y física](ECS-y-fisica): entidades, componentes, sistemas y colisiones.
- [Renderizado y cámaras](Renderizado-y-camaras): resolución, mapas, capas y cámaras.

## Publicar esta wiki

Los archivos de esta carpeta están preparados como páginas Markdown de una wiki
de GitHub. No se publican automáticamente al subir el repositorio principal:
habilita la wiki del repositorio y copia los archivos al repositorio Git de la
wiki. `Home.md` será la página principal. La URL de clonación aparece en la
propia pestaña **Wiki** de GitHub; es posible que primero tengas que crear su
primera página desde la interfaz.