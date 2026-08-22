# Referencia de API: TableroView y Consola Táctica

*Navegación:* [Documentación Principal](../README.md) > **Reference: API TableroView**

Esta referencia documenta las señales, propiedades exportadas, estados y métodos del controlador de interfaz de usuario de la consola de sonar submarino en [`scripts/ui/tablero_view.gd`](../../scripts/ui/tablero_view.gd).

---

## `TableroView`
**Herencia:** `Control` $\to$ `CanvasItem` $\to$ `Node` $\to$ `Object`  
**Archivo:** [`scripts/ui/tablero_view.gd`](../../scripts/ui/tablero_view.gd)  
**Escena Asociada:** [`scenes/game/tablero.tscn`](../../scenes/game/tablero.tscn)  
**Explicación Visual:** [Arquitectura Visual y Consola CRT](../explanation/arquitectura-visual-crt.md)

---

## Índice de Secciones
- [1. Señales (Signals)](#1-señales-signals)
- [2. Enums](#2-enums)
- [3. Propiedades Exportadas (@export)](#3-propiedades-exportadas-export)
- [4. Constantes de Color Táctico](#4-constantes-de-color-táctico)
- [5. Métodos Públicos](#5-métodos-públicos)
- [Navegación y Enlaces Relacionados](#navegación-y-enlaces-relacionados)

---

## 1. Señales (Signals)

- `signal game_started`: Emitida cuando el jugador realiza el primer clic y el tablero ha sido generado y validado con éxito mediante [`BoardGenerator.generate_board()`](../../scripts/core/generacion-tablero/board_generator.gd).
- `signal game_won`: Emitida cuando se revelan todas las celdas seguras y [`BoardData.is_solved()`](../../scripts/core/generacion-tablero/board_data.gd) retorna `true`.
- `signal game_lost`: Emitida cuando se detona una mina submarina.
- `signal cell_revealed(pos: Vector2i, neighbor_mines: int)`: Emitida cada vez que una celda individual pasa a estado visible mediante [`BoardData.reveal()`](../../scripts/core/generacion-tablero/board_data.gd).
- `signal cell_flagged(pos: Vector2i, is_flagged: bool)`: Emitida cuando se coloca o retira una boya de baliza con [`CellData.toggle_flag()`](../../scripts/core/generacion-tablero/cell_data.gd).

---

## 2. Enums

### `GameState`
- `SWEEP_ANIMATING = 0`: Bloqueo de entrada mientras se reproduce la animación diagonal de barrido del sonar.
- `READY_FIRST_CLICK = 1`: Sonar listo esperando el primer clic para generar el tablero protegido.
- `PLAYING = 2`: Partida activa en curso.
- `WON = 3`: Partida ganada (casco intacto).
- `LOST = 4`: Partida perdida (mina detonada).

---

## 3. Propiedades Exportadas (`@export`)

### Dimensiones y Reglas
| Propiedad | Tipo | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `board_width` | `int` | `8` | Número de columnas de la cuadrícula. |
| `board_height` | `int` | `8` | Número de filas de la cuadrícula. |
| `total_mines` | `int` | `10` | Cantidad total de minas submarinas. |
| `ensure_no_guess` | `bool` | `true` | Si es `true`, garantiza resolubilidad 100% lógica. |

### Visuales
| Propiedad | Tipo | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `cell_size` | `Vector2` | `Vector2(44, 44)` | Dimensiones en píxeles de cada botón/celda. |

### Animación
| Propiedad | Tipo | Valor por Defecto | Descripción |
| :--- | :--- | :--- | :--- |
| `enable_sweep_animation` | `bool` | `true` | Activa la animación diagonal de sonar al reiniciar. |
| `sweep_step_delay` | `float` | `0.025` | Retardo en segundos entre diagonales consecutivas $(x+y)$. |
| `sweep_cell_duration` | `float` | `0.22` | Duración del pulso de brillo individual por celda. |
| `enable_panel_resize_animation` | `bool` | `true` | Suaviza el cambio de tamaño del marco de la consola con `Tween` (en 2D) al redimensionar la cuadrícula. |
| `panel_resize_duration` | `float` | `0.24` | Duración en segundos del Tween de redimensionado. |

---

## 4. Constantes de Color Táctico

- `COLOR_BG_DARK`: `Color(0.02, 0.05, 0.04)` (Negro oceánico).
- `COLOR_PANEL_BG`: `Color(0.04, 0.09, 0.07, 0.95)` (Consola CRT).
- `COLOR_BORDER_TACTICAL`: `Color(0.12, 0.28, 0.22)` (Borde metálico).
- `COLOR_PHOSPHOR_BRIGHT`: `Color(0.20, 1.00, 0.50)` (Fósforo verde brillante).
- `COLOR_PHOSPHOR_DIM`: `Color(0.10, 0.55, 0.32)` (Fósforo verde tenue).
- `COLOR_AMBER_ALERT`: `Color(1.00, 0.75, 0.15)` (Ámbar baliza/alerta).
- `COLOR_TORPEDO_RED`: `Color(1.00, 0.22, 0.25)` (Rojo colisión/mina).
- `FREQUENCY_COLORS: Dictionary`: Mapeo del número de proximidad ($1-8$) al color de frecuencia acústica correspondiente.

---

## 5. Métodos Públicos

### `func reset_game() -> void`
Limpia los botones de la cuadrícula, crea un nuevo [`BoardData`](../../scripts/core/generacion-tablero/board_data.gd) en blanco, reinicia la telemetría, actualiza el tamaño de la consola y dispara la animación de barrido acústico (o pone el sonar inmediatamente en `READY_FIRST_CLICK`).

### `func set_board_dimensions(new_width: int, new_height: int, new_mines: int = -1, no_guess: bool = true) -> void`
Modifica las dimensiones del tablero y/o cantidad de minas en tiempo de ejecución, actualizando y animando suavemente las dimensiones del marco de la consola con `Tween` si `enable_panel_resize_animation` está activo.

### `func play_sonar_sweep_animation(on_complete: Callable = Callable()) -> void`
Ejecuta la animación diagonal paralela y escalonada por $(x + y)$ con curvas `TRANS_BACK` y `TRANS_SINE`. Al finalizar, invoca el callback opcional `on_complete` y habilita la interacción del jugador. Consulta los detalles matemáticos en [Explicación de Arquitectura Visual](../explanation/arquitectura-visual-crt.md#3-coreografía-de-animaciones-con-tween).

---

## Navegación y Enlaces Relacionados

- **Motor matemático:** [Referencia de API Core de Generación](api-core-tablero.md)
- **Recetas de configuración:** [Cómo Configurar Parámetros del Tablero](../how-to/configurar-tablero.md)
- **Explicación estética:** [Arquitectura Visual y Consola CRT](../explanation/arquitectura-visual-crt.md)
- **Volver al índice:** [Centro de Documentación (`docs/README.md`)](../README.md)
