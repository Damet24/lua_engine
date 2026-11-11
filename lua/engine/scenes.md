# Arquitectura del sistema de escenas

**Motor:** LÖVE2D  
**Lenguaje:** Lua  
**Estado:** Diseño conceptual

## 1. Objetivo

Diseñar un sistema de escenas modular que permita administrar diferentes contextos de ejecución dentro del juego.

El sistema debe permitir:

- Apilar, retirar y reemplazar escenas.
- Mantener escenas cargadas mientras otras están encima.
- Controlar el ciclo de vida de cada escena.
- Definir reglas de transición específicas para cada juego.
- Controlar independientemente la actualización y el renderizado.
- Compartir recursos sin cargarlos varias veces.
- Mantener las escenas desacopladas del funcionamiento interno del motor.

El motor proporciona los mecanismos; el desarrollador define el comportamiento particular de su juego.

---

## 2. Arquitectura general

| Módulo | Responsabilidad |
|---|---|
| `Scene` | Orquestar el contexto de ejecución de una escena. |
| `SceneManager` | Administrar la pila, las transiciones y el ciclo de vida. |
| `SceneRegistry` / `SceneFactory` | Resolver y construir escenas mediante identificadores. |
| `GameContext` | Proporcionar servicios y dependencias compartidas. |
| `GameState` | Mantener información compartida y persistente en memoria. |
| `ResourceManager` | Administrar la carga, reutilización y liberación de recursos. |
| `World` | Administrar entidades, componentes y sistemas ECS de una escena. |

### 2.1. Scene

Una escena representa un contexto de ejecución independiente.

Sus responsabilidades son:

- Coordinar su propio `World`.
- Configurar y organizar sus sistemas ECS.
- Administrar los elementos propios de su contexto.
- Coordinar sus recursos y renderizadores.
- Exponer callbacks de su ciclo de vida.

La escena no debe encargarse de administrar la pila ni de ejecutar las transiciones.

Cada escena puede definir su propio conjunto de sistemas y su orden de ejecución.

Por ejemplo:

**Level01**
- MovementSystem
- PhysicsSystem
- PhysicsSyncSystem
- CollisionSystem
- DamageSystem
- RenderSystem

**PauseMenu**
- UISystem
- MenuNavigationSystem
- UIRenderSystem

### 2.2. SceneManager

Es el responsable de administrar las escenas.

Sus responsabilidades son:

- Mantener la pila de escenas.
- Procesar las solicitudes de transición.
- Validar que las solicitudes sigan siendo válidas.
- Consultar las reglas de transición.
- Controlar el ciclo de vida.
- Determinar qué escenas se actualizan y cuáles se dibujan, de acuerdo con las políticas definidas por el juego.

El `SceneManager` no debe conocer la lógica interna de cada escena.

### 2.3. SceneRegistry / SceneFactory

Debe existir un mecanismo que relacione identificadores con la construcción de escenas.

Ejemplos:

- `main_menu`
- `level_01`
- `level_02`
- `pause_menu`
- `settings_menu`

El `SceneManager` solicita una escena mediante su identificador sin conocer cómo está construida.

### 2.4. GameContext

Es el intermediario mediante el cual las escenas pueden acceder a servicios y dependencias compartidas.

Su objetivo es evitar que cada escena tenga que conocer dónde se encuentran almacenadas o cómo se construyen esas dependencias.

No debe convertirse en un localizador global que exponga indiscriminadamente todos los módulos del motor.

### 2.5. GameState

Mantiene información compartida del juego.

Ejemplos:

- Inventario del jugador.
- Equipamiento.
- Vida y estadísticas.
- Misiones y progreso.
- Configuración de la partida.

Debe estar separado del estado temporal que pertenece exclusivamente a una escena.

El almacenamiento persistente en disco y la serialización de partidas se consideran responsabilidades independientes.

---

## 3. Pila de escenas

El sistema utilizará una pila para administrar los contextos activos y suspendidos.

Operaciones disponibles:

| Operación | Comportamiento |
|---|---|
| `push(scene)` | Agrega una escena encima de la actual. |
| `pop()` | Retira la escena superior. |
| `replace(scene)` | Reemplaza la escena superior. |
| `clearAndPush(scene)` | Destruye todas las escenas y agrega una nueva. |

### Comportamiento esperado

**Push**

Ejemplo:

`Level01 → PauseMenu`

`Level01` permanece cargada y conserva su estado mientras `PauseMenu` está encima.

**Pop**

Ejemplo:

`Level01 → PauseMenu → pop()`

Se destruye `PauseMenu` y `Level01` vuelve a primer plano.

**Replace**

Ejemplo:

`Level01 → replace(Level02)`

Se prepara `Level02`, se destruye `Level01` y se activa `Level02`.

**ClearAndPush**

Ejemplo:

`Level01 → PauseMenu → clearAndPush(MainMenu)`

Se destruyen las escenas anteriores y se deja únicamente `MainMenu`.

---

## 4. Solicitudes de transición

Las escenas no deben modificar directamente la pila.

En su lugar, solicitan transiciones que el `SceneManager` procesa posteriormente.

### 4.1. Procesamiento diferido

Las solicitudes se registran en una cola y se procesan en un punto seguro del ciclo de ejecución.

Esto evita modificar o destruir una escena mientras todavía se está ejecutando su lógica.

### 4.2. Contexto de origen

Cada solicitud debe identificar la escena o contexto que la generó.

Antes de ejecutar una solicitud, el `SceneManager` comprueba que su contexto de origen siga siendo válido.

Una solicitud generada por una escena que dejó de ser válida puede descartarse.

### 4.3. Orden y conflictos

Las solicitudes se procesan siguiendo un orden determinista.

No existe una política universal que limite a una transición por escena o por tick.

El comportamiento ante solicitudes incompatibles depende de las reglas del juego.

### 4.4. Reglas de transición

Las reglas pertenecen al desarrollador del juego.

Pueden determinar:

- Qué operaciones están permitidas.
- Qué escenas pueden coexistir.
- Qué transiciones están prohibidas.
- Si se pueden abrir múltiples overlays.
- Si una transición depende de la escena actual.
- Si depende de toda la pila o del contexto desde el que se llegó.

El `SceneManager` proporciona los mecanismos para consultar y aplicar estas reglas, pero no las define.

---

## 5. Ciclo de vida de las escenas

El `SceneManager` controla el ciclo de vida y garantiza el orden de ejecución de sus callbacks.

El desarrollador implementa la lógica que necesite en cada callback.

### 5.1. Callbacks

| Callback | Responsabilidad |
|---|---|
| `onLoad` | Preparar la escena y sus recursos. |
| `onEnter` | Ejecutar lógica al pasar a primer plano. |
| `onExit` | Ejecutar lógica al abandonar el primer plano. |
| `onDestroy` | Liberar los recursos y el estado propios de la escena. |

### 5.2. Reglas

- `onLoad` se ejecuta una vez por instancia de escena.
- `onEnter` se ejecuta cada vez que la escena pasa a primer plano.
- `onExit` se ejecuta cada vez que abandona el primer plano.
- `onDestroy` se ejecuta una vez cuando la instancia deja de existir.
- Una escena que permanece en la pila conserva su estado.
- Volver a una escena suspendida ejecuta `onEnter`, no `onLoad`.

### 5.3. Secuencias de ejemplo

**Push**

1. Preparar la escena entrante mediante `onLoad`.
2. Ejecutar `onExit` en la escena anterior.
3. Ejecutar `onEnter` en la nueva escena.

**Pop**

1. Ejecutar `onExit` en la escena superior.
2. Ejecutar `onDestroy` en la escena retirada.
3. Ejecutar `onEnter` en la escena que queda arriba.

**Replace**

1. Preparar la nueva escena mediante `onLoad`.
2. Ejecutar `onExit` en la escena anterior.
3. Ejecutar `onDestroy` en la escena anterior.
4. Ejecutar `onEnter` en la nueva escena.

**ClearAndPush**

1. Preparar la nueva escena.
2. Ejecutar `onExit` y `onDestroy` en las escenas anteriores.
3. Ejecutar `onEnter` en la nueva escena.

La preparación de la nueva escena antes de destruir la anterior permite evitar que un fallo durante `onLoad` deje la pila sin una escena válida.

---

## 6. Actualización y renderizado

La existencia, actualización y renderizado de una escena son conceptos independientes.

Una escena puede:

- Permanecer cargada sin actualizarse.
- Permanecer cargada y seguir actualizándose.
- Seguir dibujándose aunque no se actualice.
- Actualizarse sin dibujarse.

El desarrollador del juego define estas políticas.

Ejemplos:

**Shovel Knight**

Al abrir el inventario, el mundo puede detener su simulación.

**Dark Souls**

Al abrir el inventario, el mundo puede continuar ejecutándose.

El motor no debe imponer uno de estos comportamientos.

El `SceneManager` conoce la pila y coordina qué escenas participan en cada ciclo.

---

## 7. Gestión de recursos

El `ResourceManager` es un módulo independiente del sistema de escenas.

Debe poder utilizarse desde cualquier módulo del motor.

### 7.1. Carga bajo demanda

Los consumidores solicitan recursos mediante una operación como:

`get("player.png")`

El administrador comprueba si el recurso ya está cargado:

- Si existe, devuelve la referencia existente.
- Si no existe, lo carga y devuelve la referencia.

### 7.2. Consumidores y dependencias

El administrador mantiene un registro de qué consumidores necesitan cada recurso.

Ejemplo:

| Recurso | Consumidores |
|---|---|
| `player.png` | Level01, Level02 |
| `tileset.png` | Level01, Level02 |
| `boss.png` | Level02 |
| `background_music.ogg` | AudioSystem |
| `menu_font.ttf` | UIManager |

Los consumidores no tienen que ser necesariamente escenas.

Pueden ser sistemas, gestores u otros módulos del motor.

### 7.3. Liberación

Cuando un consumidor deja de necesitar un recurso, informa al administrador.

El `ResourceManager` puede liberar un recurso cuando ya no tiene consumidores que dependan de él.

Esto permite:

- Reutilizar recursos entre escenas.
- Evitar cargas duplicadas.
- Liberar recursos que ya no son necesarios.
- Mantener el administrador desacoplado de las escenas.

---

## 8. Gestión de errores

Los errores críticos durante la inicialización deben detener el proceso de transición.

Ejemplo:

Si `Level02:onLoad()` falla:

- No se ejecuta `onEnter`.
- No se destruye `Level01`.
- Se informa el error con su contexto.
- La ejecución del juego se detiene de forma controlada.

No se plantea implementar reintentos automáticos ni mecanismos complejos de recuperación.

El manejo general de errores deberá ser compartido por los módulos del motor, no una responsabilidad exclusiva del `SceneManager`.

---

## 9. Decisiones pendientes

Estos puntos todavía necesitan diseño antes de implementar el sistema:

1. **Política exacta de solicitudes pendientes:** definir cómo se determina que un contexto de origen sigue siendo válido cuando ya se procesó otra transición.
2. **Reglas de transición:** definir cómo se representan y consultan las políticas que configura cada juego.
3. **Actualización y renderizado:** definir cómo se expresan las políticas de cada escena y cómo se coordinan con la pila.
4. **Preparación de escenas:** precisar qué operaciones forman parte de `onLoad` y cuáles deben esperar hasta `onEnter`.
5. **Gestión de dependencias:** definir cómo los consumidores registran y liberan sus dependencias en `ResourceManager`.
6. **Errores:** definir el mecanismo común para informar y propagar errores entre módulos.

---

## 10. Principios arquitectónicos

El diseño debe respetar los siguientes principios:

- Separación de responsabilidades.
- Bajo acoplamiento entre módulos.
- Escenas independientes de la implementación del `SceneManager`.
- Reglas de juego fuera del núcleo del motor.
- Recursos administrados de forma centralizada.
- Ciclo de vida controlado por el motor.
- Extensibilidad sin introducir complejidad innecesaria.
- No anticipar características que todavía no necesita el motor.