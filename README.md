# Submarine Roguelike Minesweeper

Un videojuego táctico de supervivencia y lógica deductiva ambientado en una consola de sonar submarino retro CRT, desarrollado en **Godot 4**.

El juego cuenta con un generador **100% libre de adivinanzas (No-Guess)**: todos los tableros son resolubles mediante deducción lógica pura desde el primer clic, eliminando las situaciones 50/50 del buscaminas tradicional.

---

## Índice Rápido
- [Inicio Rápido](#inicio-rápido)
- [Controles Básicos](#controles-básicos)
- [Características Principales](#características-principales)
- [Centro de Documentación Técnica (`/docs`)](#centro-de-documentación-técnica-docs)
- [Pruebas Unitarias](#pruebas-unitarias)
- [Estructura del Repositorio](#estructura-del-repositorio)
- [Licencia](#licencia)

---

## Inicio Rápido

1. **Requisitos:** Godot Engine 4.3+ (renderizador *GL Compatibility* o *Forward+*).
2. **Importar:** Abre Godot Engine, selecciona *Importar* y elige el archivo de configuración [`project.godot`](project.godot).
3. **Jugar:** Presiona **F5** para ejecutar la escena principal [`res://scenes/game/tablero.tscn`](scenes/game/tablero.tscn).

> [!TIP]
> Si es tu primera vez con el proyecto, consulta el tutorial paso a paso: [Primeros Pasos con Submarine Roguelike Minesweeper](docs/tutorials/primeros-pasos.md).

---

## Controles Básicos

| Acción | Control | Descripción |
| :--- | :--- | :--- |
| **Ping Acústico** | `Clic Izquierdo` | Revela la celda objetivo o inicia la generación garantizada en el primer clic. |
| **Boya de Baliza** | `Clic Derecho` | Despliega o retira una boya baliza acústica para marcar una mina detectada. |
| **Chording Acústico** | `Clic Central` / `Clic Izq.` en número | Si el número coincide con las boyas marcadas, revela el resto de vecinas. |
| **Reiniciar Sonar** | Botón `[ REINICIAR SONAR ]` | Reinicia la cuadrícula y recalibra el sector del sonar. |

---

## Características Principales

- **Garantía No-Guess:** Apertura inicial garantizada (zona segura $3 \times 3$) y filtrado con solver multinivel. Ver [Explicación del Algoritmo No-Guess](docs/explanation/algoritmo-no-guess.md).
- **Consola Táctica CRT:** Estética analógica en fósforo verde, animaciones de barrido de radar y código de colores por frecuencias. Ver [Arquitectura Visual y Consola CRT](docs/explanation/arquitectura-visual-crt.md).
- **Suite de Pruebas Automatizadas:** Tests unitarios con el framework GUT cubriendo topología, solver determinista y transformaciones matriciales RREF. Ver [Cómo Ejecutar Pruebas con GUT](docs/how-to/ejecutar-pruebas-gut.md).

---

## Centro de Documentación Técnica (`/docs`)

La documentación técnica exhaustiva del proyecto está estructurada bajo el estándar **Diátaxis** en la carpeta [`docs/`](docs/README.md):

| Cuadrante Diátaxis | Documento | Descripción |
| :--- | :--- | :--- |
| **Tutorials** | [Primeros Pasos](docs/tutorials/primeros-pasos.md) | Guía paso a paso para configurar el entorno y jugar tu primera partida. |
| **How-To Guides** | [Configurar Parámetros del Tablero](docs/how-to/configurar-tablero.md) | Recetas para personalizar dimensiones, densidad de minas y animaciones. |
| | [Ejecutar y Crear Pruebas con GUT](docs/how-to/ejecutar-pruebas-gut.md) | Cómo correr la suite de tests unitarios desde GUI y CLI. |
| **Explanation** | [Algoritmo No-Guess y Solver Multinivel](docs/explanation/algoritmo-no-guess.md) | Fundamentos matemáticos: Gauss-Jordan RREF, grafos conexos y Tank Solver. |
| | [Arquitectura Visual y Consola CRT](docs/explanation/arquitectura-visual-crt.md) | Diseño de la consola táctica, `StyleBoxFlat` procedurales y Tweening. |
| **Reference** | [API Core de Generación de Tablero](docs/reference/api-core-tablero.md) | Referencia de clases `BoardData`, `CellData`, `BoardGenerator` y `MinesweeperSolver`. |
| | [API de TableroView y HUD](docs/reference/tablero-view.md) | Propiedades `@export`, señales y métodos de `TableroView`. |

---

## Pruebas Unitarias

Para ejecutar los tests desde el editor:
1. Habilita el plugin **GUT** en `Proyecto -> Configuración del Proyecto -> Plugins`.
2. En el panel inferior **GUT**, haz clic en **Run All**.
3. Consulta la guía detallada: [Cómo Ejecutar y Crear Pruebas con GUT](docs/how-to/ejecutar-pruebas-gut.md).

---

## Estructura del Repositorio

- [`scenes/game/tablero.tscn`](scenes/game/tablero.tscn): Escena principal jugable.
- [`scripts/ui/tablero_view.gd`](scripts/ui/tablero_view.gd): Controlador de interfaz y renderizado táctico CRT.
- [`scripts/core/generacion-tablero/`](scripts/core/generacion-tablero):
  - [`board_data.gd`](scripts/core/generacion-tablero/board_data.gd) | [`cell_data.gd`](scripts/core/generacion-tablero/cell_data.gd) | [`board_generator.gd`](scripts/core/generacion-tablero/board_generator.gd)
  - [`minesweeper_solver.gd`](scripts/core/generacion-tablero/minesweeper_solver.gd) | [`gauss_jordan.gd`](scripts/core/generacion-tablero/gauss_jordan.gd) | [`solver_result.gd`](scripts/core/generacion-tablero/solver_result.gd)
- [`test/unit/`](test/unit):
  - [`test_board_data.gd`](test/unit/test_board_data.gd) | [`test_board_generator.gd`](test/unit/test_board_generator.gd)
  - [`test_gauss_jordan.gd`](test/unit/test_gauss_jordan.gd) | [`test_solver.gd`](test/unit/test_solver.gd)
- [`docs/`](docs/README.md): Documentación completa estructurada.

---

## Licencia

Distribuido bajo licencia MIT. Consulta el archivo [LICENSE](LICENSE) para más detalles.
