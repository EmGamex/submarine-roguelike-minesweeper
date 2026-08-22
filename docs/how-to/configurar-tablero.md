# Cómo Configurar y Personalizar el Tablero

*Navegación:* [Documentación Principal](../README.md) > **How-To: Configurar Tablero**

Esta guía práctica contiene recetas paso a paso para ajustar el tamaño de la cuadrícula, la cantidad de minas, la garantía determinista (No-Guess) y las animaciones visuales del sonar en [`TableroView`](../../scripts/ui/tablero_view.gd).

---

## Índice de Recetas
- [Receta 1: Configurar Dificultades desde el Inspector](#receta-1-configurar-dificultades-desde-el-inspector)
- [Receta 2: Modificar Dimensiones por Código](#receta-2-modificar-dimensiones-por-código)
- [Receta 3: Ajustar Tiempos de Animación](#receta-3-ajustar-tiempos-de-animación)
- [Receta 4: Escuchar Señales en Otros Sistemas](#receta-4-escuchar-señales-en-otros-sistemas)
- [Navegación y Enlaces Relacionados](#navegación-y-enlaces-relacionados)

---

## Receta 1: Configurar Dificultades desde el Inspector

Para modificar el tablero directamente en el editor sin tocar código GDScript:

1. Abre la escena [`res://scenes/game/tablero.tscn`](../../scenes/game/tablero.tscn) en Godot.
2. Selecciona el nodo raíz **Tablero** en el árbol de escena.
3. En el panel **Inspector** (a la derecha), localiza las propiedades exportadas de [`TableroView`](../../scripts/ui/tablero_view.gd):
   - `Board Width`: Cantidad de columnas ($X$).
   - `Board Height`: Cantidad de filas ($Y$).
   - `Total Mines`: Cantidad de minas a colocar.
   - `Ensure No Guess`: Si está en `true`, garantiza deducción 100% libre de azar.

### Configuraciones Estándar Recomendadas

| Nivel de Dificultad | Ancho ($W$) | Alto ($H$) | Minas ($M$) | Densidad ($\%$) | Estado de Validación |
| :--- | :---: | :---: | :---: | :---: | :--- |
| **Fácil (Principiante)** | 8 | 8 | 10 | $15.6\%$ | Válida ($12\%-22\%$) |
| **Medio (Intermedio)** | 12 | 12 | 24 | $16.6\%$ | Válida ($12\%-22\%$) |
| **Avanzado (Experto)** | 16 | 16 | 45 | $17.5\%$ | Válida ($12\%-22\%$) |
| **Pesadilla Táctica** | 20 | 20 | 80 | $20.0\%$ | Válida ($12\%-22\%$) |

> [!WARNING]
> La regla del motor implementada en [`BoardGenerator.validate_density()`](../../scripts/core/generacion-tablero/board_generator.gd) requiere que la densidad de minas ($\frac{M}{W \times H}$) se mantenga estrictamente entre el **$12\%$** y el **$22\%$**. Para comprender los motivos matemáticos de esta cota, revisa la [Explicación del Algoritmo No-Guess](../explanation/algoritmo-no-guess.md).

---

## Receta 2: Modificar Dimensiones por Código

Si deseas instanciar o modificar dinámicamente el tablero durante el gameplay (por ejemplo, al cambiar de nivel en una partida roguelike):

```gdscript
extends Node

@onready var tablero_view: TableroView = $Tablero

func load_custom_level(width: int, height: int, mines: int) -> void:
    tablero_view.board_width = width
    tablero_view.board_height = height
    tablero_view.total_mines = mines
    tablero_view.ensure_no_guess = true
    
    # Reinicia la cuadrícula y recalibra el radar
    tablero_view.reset_game()
```

---

## Receta 3: Ajustar Tiempos de Animación

En el grupo **Animation** de [`TableroView`](../../scripts/ui/tablero_view.gd), puedes calibrar la sensación analógica de barrido del sonar:

```gdscript
@export_group("Animation")
@export var enable_sweep_animation: bool = true   # Activa/desactiva la animación al inicio
@export var sweep_step_delay: float = 0.025       # Segundos entre cada diagonal de escaneo (x + y)
@export var sweep_cell_duration: float = 0.22     # Duración del pulso de brillo de cada celda
@export var enable_panel_resize_animation: bool = true # Suaviza el cambio de tamaño del panel de estado
@export var panel_resize_duration: float = 0.24   # Tiempo del Tween de ajuste del panel
```

- **Para un arranque instantáneo:** Establece `enable_sweep_animation = false`.
- **Para un efecto de barrido más lento y dramático:** Incrementa `sweep_step_delay` a `0.05` y `sweep_cell_duration` a `0.4`.
- **Detalles de la animación:** Consulta la [Explicación de Arquitectura Visual y Consola CRT](../explanation/arquitectura-visual-crt.md).

---

## Receta 4: Escuchar Señales en Otros Sistemas

Puedes conectar las señales emitidas por [`TableroView`](../../scripts/ui/tablero_view.gd) para sincronizar efectos sonoros, música dinámica o progresión roguelike:

```gdscript
func _ready() -> void:
    var tablero: TableroView = $Tablero
    tablero.game_started.connect(_on_sonar_started)
    tablero.cell_revealed.connect(_on_sonar_ping)
    tablero.cell_flagged.connect(_on_buoy_toggled)
    tablero.game_won.connect(_on_sector_cleared)
    tablero.game_lost.connect(_on_hull_breached)

func _on_sonar_ping(pos: Vector2i, neighbor_mines: int) -> void:
    print("Ping acústico en ", pos, " - Señales de proximidad: ", neighbor_mines)

func _on_sector_cleared() -> void:
    print("Sector superado con éxito. Otorgando combustible y mejoras.")
```

---

## Navegación y Enlaces Relacionados

- **Especificación de propiedades y métodos:** [Referencia de API de TableroView](../reference/tablero-view.md)
- **Generador de tableros:** [Referencia de API Core de Generación](../reference/api-core-tablero.md)
- **Ejecutar tests automatizados:** [Cómo Ejecutar y Crear Pruebas con GUT](ejecutar-pruebas-gut.md)
- **Volver al índice:** [Centro de Documentación (`docs/README.md`)](../README.md)
