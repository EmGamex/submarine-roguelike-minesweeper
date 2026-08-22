# Explicación: Arquitectura Visual y Consola CRT

*Navegación:* [Documentación Principal](../README.md) > **Explanation: Arquitectura Visual CRT**

La interfaz de usuario de **Submarine Roguelike Minesweeper** no utiliza sprites de mapa de bits estáticos tradicionales. En su lugar, está construida completamente con **recursos vectoriales procedimentales (`StyleBoxFlat`)** y el sistema de animación fluido de **Godot (`Tween`)** en [`TableroView`](../../scripts/ui/tablero_view.gd), simulando la experiencia visual de un terminal táctico de sonar submarino en fósforo verde (P31).

---

## Índice de Contenidos
- [1. Decisiones de Diseño Estético](#1-decisiones-de-diseño-estético)
  - [Paleta Analógica Fósforo Verde](#paleta-analógica-fósforo-verde)
  - [Codificación Acústica por Frecuencias](#codificación-acústica-por-frecuencias-1-8)
- [2. Estilización Procedimental Vectorial (StyleBoxFlat)](#2-estilización-procedimental-vectorial-styleboxflat)
- [3. Coreografía de Animaciones con Tween](#3-coreografía-de-animaciones-con-tween)
- [Navegación y Enlaces Relacionados](#navegación-y-enlaces-relacionados)

---

## 1. Decisiones de Diseño Estético

### Paleta Analógica Fósforo Verde

La paleta cromática definida en [`TableroView`](../../scripts/ui/tablero_view.gd) se inspira en pantallas monocromáticas de tubos de rayos catódicos (CRT) y consolas militares de radar:

| Identificador | Color Hex / RGBA | Uso Táctico |
| :--- | :--- | :--- |
| `COLOR_BG_DARK` | `#050D0A` | Fondo oceánico profundo |
| `COLOR_PANEL_BG` | `#0A1712` | Cuerpo de la consola CRT del radar |
| `COLOR_BORDER_TACTICAL` | `#1F4738` | Marco metálico y biseles de aislamiento |
| `COLOR_PHOSPHOR_BRIGHT` | `#33FF80` | Fósforo verde activo, retículas de selección y victoria |
| `COLOR_PHOSPHOR_DIM` | `#1A8C52` | Retícula inactiva y leyendas secundarias |
| `COLOR_AMBER_ALERT` | `#FFBF26` | Balizas sonares desplegadas y avisos de calibración |
| `COLOR_TORPEDO_RED` | `#FF3840` | Minas detonadas, alarmas críticas y colisión |

### Codificación Acústica por Frecuencias ($1-8$)

En lugar de números multicolores genéricos, cada señal de proximidad se asocia en el diccionario `TableroView.FREQUENCY_COLORS` a una frecuencia visual que escala el nivel de peligro percibido:
- **1:** Fósforo verde puro (`#33FF8C`) — Baja proximidad.
- **2:** Cian sonar (`#26F2E6`) — Eco confirmado.
- **3:** Amarillo detector (`#F2F24D`) — Advertencia moderada.
- **4-5:** Ámbar a Naranja torpedo — Peligro cercano inminente.
- **6-8:** Magenta a Rojo de alarma máxima — Múltiples torpedos en sector adyacente.

---

## 2. Estilización Procedimental Vectorial (`StyleBoxFlat`)

En la función [`TableroView._init_procedural_styles()`](../../scripts/ui/tablero_view.gd), el script inicializa y cachea instancias de `StyleBoxFlat` para cada uno de los estados posibles de las celdas representadas por [`CellData.State`](../../scripts/core/generacion-tablero/cell_data.gd):

```
[ Celda Oculta ]        --> Fondo oscuro tenue + borde verde sutil
[ Celda Hover/Cursor ]  --> Iluminación fosforescente + sombra suave (Glow)
[ Celda Presionada ]    --> Borde engrosado (Ping acústico emitido)
[ Celda Baliza (Flag) ] --> Fondo ámbar oscuro + borde dorado + icono ▲
[ Celda Revelada ]      --> Cavidad acústica despejada (bajo contraste)
[ Mina Detonada ]       --> Fondo carmesí + sombra de alarma + icono ☢
```

### Ventajas de este Enfoque:
1. **Escalabilidad Vectorial Perfecta:** El tablero se renderiza nítido en cualquier resolución o proporción de ventana sin pixelación ni artefactos de compresión.
2. **Cero Dependencia de Texturas Externas:** Carga instantánea y reducción drástica del peso del paquete de distribución.
3. **Control Dinámico de Sombreado y Resplandor:** Permite manipular `shadow_size`, `shadow_color` y `border_width` en tiempo real.

---

## 3. Coreografía de Animaciones con `Tween`

### Animación de Barrido de Sonar Diagonal (`play_sonar_sweep_animation`)
Al iniciar o reiniciar una partida mediante [`TableroView.reset_game()`](../../scripts/ui/tablero_view.gd), el radar emite un barrido visual acústico en [`TableroView.play_sonar_sweep_animation()`](../../scripts/ui/tablero_view.gd) que recorre el tablero de forma diagonal:

$$\text{Retardo de la Celda }(x, y) = (x + y) \times \text{sweep\_step\_delay}$$

1. Todas las celdas inician con opacidad reducida y escala $0.8$.
2. Cada celda se ilumina a fósforo brillante (`COLOR_PHOSPHOR_BRIGHT * 1.4`) y escala a $1.12$ con una curva `TRANS_BACK / EASE_OUT`.
3. Posteriormente, transiciona suavemente a escala $1.0$ y color normal con `TRANS_SINE / EASE_IN_OUT`.
4. Al finalizar la última celda, el estado del juego cambia automáticamente a `TableroView.GameState.READY_FIRST_CLICK`.

### Redimensionamiento Dinámico del Marco Táctico (`_update_console_size`)
Cuando las dimensiones del tablero (`board_width`, `board_height`) cambian o se invoca [`TableroView.set_board_dimensions()`](../../scripts/ui/tablero_view.gd), el tamaño mínimo requerido del panel se anima suavemente en dos dimensiones ($X$ e $Y$) mediante un `Tween` interpolando `custom_minimum_size` con una curva `TRANS_CUBIC / EASE_OUT`. Esto previene saltos bruscos en el layout y proporciona una transición elástica fluida sin desajustar el texto de estado.

---

## Navegación y Enlaces Relacionados

- **Especificación de TableroView:** [Referencia de API de TableroView](../reference/tablero-view.md)
- **Aprender a personalizar animaciones:** [Cómo Configurar Parámetros del Tablero](../how-to/configurar-tablero.md)
- **Generador matemático:** [Explicación del Algoritmo No-Guess](algoritmo-no-guess.md)
- **Volver al índice:** [Centro de Documentación (`docs/README.md`)](../README.md)
