# Referencia de API: Core de Generación de Tablero

*Navegación:* [Documentación Principal](../README.md) > **Reference: API Core de Tablero**

Esta referencia documenta las clases, constantes, propiedades y métodos del motor matemático y de generación de tableros ubicado en [`scripts/core/generacion-tablero/`](../../scripts/core/generacion-tablero).

---

## Índice de Clases
- [1. CellData](#1-celldata)
- [2. BoardData](#2-boarddata)
- [3. GaussJordanSolver](#3-gaussjordansolver)
- [4. MinesweeperSolver](#4-minesweepersolver)
- [5. SolverResult](#5-solverresult)
- [6. BoardGenerator](#6-boardgenerator)
- [Navegación y Enlaces Relacionados](#navegación-y-enlaces-relacionados)

---

## 1. `CellData`
**Herencia:** `RefCounted`  
**Archivo:** [`scripts/core/generacion-tablero/cell_data.gd`](../../scripts/core/generacion-tablero/cell_data.gd)  
**Tests Unitarios:** [`test/unit/test_board_data.gd`](../../test/unit/test_board_data.gd)

Representa el estado y propiedades individuales de una celda en la cuadrícula.

### Enums
- `State`:
  - `HIDDEN = 0`: Celda cubierta / no escaneada.
  - `REVEALED = 1`: Celda descubierta y visible.
  - `FLAGGED = 2`: Celda marcada con una boya de baliza.

### Propiedades
- `var pos: Vector2i`: Coordenada $(X, Y)$ de la celda en el tablero.
- `var is_mine: bool`: `true` si la celda contiene una mina submarina.
- `var neighbor_mines: int`: Cantidad de minas en las 8 casillas adyacentes ($0-8$).
- `var state: State`: Estado actual de visibilidad / marcado.

### Métodos
- `func _init(p_pos: Vector2i = Vector2i.ZERO, p_is_mine: bool = false) -> void`
- `func is_hidden() -> bool`: Retorna `true` si `state == State.HIDDEN`.
- `func is_revealed() -> bool`: Retorna `true` si `state == State.REVEALED`.
- `func is_flagged() -> bool`: Retorna `true` si `state == State.FLAGGED`.
- `func reveal() -> void`: Cambia el estado a `State.REVEALED`.
- `func toggle_flag() -> bool`: Alterna entre `State.HIDDEN` y `State.FLAGGED`. Retorna `true` si el estado cambió.
- `func clone() -> CellData`: Crea y retorna una copia profunda de la celda.

---

## 2. `BoardData`
**Herencia:** `RefCounted`  
**Archivo:** [`scripts/core/generacion-tablero/board_data.gd`](../../scripts/core/generacion-tablero/board_data.gd)  
**Tests Unitarios:** [`test/unit/test_board_data.gd`](../../test/unit/test_board_data.gd)

Almacena la topología de la cuadrícula, ejecuta aperturas en cascada (*flood-fill*) y computa estadísticas de juego.

### Constantes
- `DIRECTIONS_8: Array[Vector2i]`: Vector con los 8 desplazamientos adyacentes (incluyendo diagonales).

### Propiedades
- `var width: int`: Ancho de la cuadrícula en celdas.
- `var height: int`: Altura de la cuadrícula en celdas.
- `var total_mines: int`: Cantidad total de minas colocadas.
- `var cells: Dictionary`: Diccionario que mapea `Vector2i -> CellData`.

### Métodos
- `func _init(p_width: int = 8, p_height: int = 8) -> void`
- `func is_valid_coord(pos: Vector2i) -> bool`: Verifica si la coordenada está dentro de $[0, \text{width}) \times [0, \text{height})$.
- `func get_cell(pos: Vector2i) -> CellData`: Retorna la instancia de [`CellData`](#1-celldata) o `null`.
- `func get_neighbors(pos: Vector2i, include_diagonals: bool = true) -> Array[Vector2i]`: Retorna las coordenadas válidas de las casillas adyacentes.
- `func calculate_neighbor_numbers() -> void`: Recalcula el total de minas y el número `neighbor_mines` de cada celda libre.
- `func reveal(pos: Vector2i) -> Array[Vector2i]`: Revela la casilla. Si su valor es $0$, ejecuta un *flood fill* en cascada sobre todas las celdas adyacentes conectadas. Retorna un array con todas las posiciones recién reveladas.
- `func toggle_flag(pos: Vector2i) -> bool`: Alterna la bandera en la celda indicada.
- `func get_revealed_count() -> int`: Retorna la cantidad de celdas reveladas.
- `func get_flagged_count() -> int`: Retorna la cantidad de celdas con boya.
- `func get_hidden_count() -> int`: Retorna la cantidad de celdas ocultas.
- `func is_solved() -> bool`: Retorna `true` si todas las celdas sin mina han sido reveladas.
- `func clone() -> BoardData`: Retorna un duplicado profundo e independiente del tablero.

---

## 3. `GaussJordanSolver`
**Herencia:** `RefCounted`  
**Archivo:** [`scripts/core/generacion-tablero/gauss_jordan.gd`](../../scripts/core/generacion-tablero/gauss_jordan.gd)  
**Tests Unitarios:** [`test/unit/test_gauss_jordan.gd`](../../test/unit/test_gauss_jordan.gd)  
**Explicación Teórica:** [Algoritmo No-Guess: Nivel 2](../explanation/algoritmo-no-guess.md#nivel-2-álgebra-lineal-y-reducción-gauss-jordan-rref)

Módulo estático de álgebra lineal para reducción matricial binaria.

### Constantes
- `EPSILON: float = 1e-5`: Tolerancia numérica para comparaciones de punto flotante.

### Métodos Estáticos
- `static func to_rref(matrix: Array, num_vars: int) -> Array`:  
  Aplica el algoritmo de eliminación de Gauss-Jordan con pivoteo parcial sobre la matriz aumentada $[A \mid \mathbf{b}]$.
- `static func find_certainties(rref_matrix: Array, num_vars: int) -> Dictionary`:  
  Analiza las filas en RREF y deduce variables binarias inequívocas.  
  **Retorna:** `Dictionary` con las claves:
  - `"safe_vars": Array[int]` (índices de variables deducidas como 0/seguras).
  - `"mine_vars": Array[int]` (índices de variables deducidas como 1/minas).

---

## 4. `MinesweeperSolver`
**Herencia:** `RefCounted`  
**Archivo:** [`scripts/core/generacion-tablero/minesweeper_solver.gd`](../../scripts/core/generacion-tablero/minesweeper_solver.gd)  
**Tests Unitarios:** [`test/unit/test_solver.gd`](../../test/unit/test_solver.gd)  
**Explicación Teórica:** [Algoritmo No-Guess: Motor Multinivel](../explanation/algoritmo-no-guess.md#2-el-motor-de-resolución-multinivel-minesweepersolver)

Motor deductivo multinivel para simular y validar la resolubilidad determinista de una partida.

### Clases Internas de Soporte
- `FrontierConstraint`:
  - `var cell_pos: Vector2i`: Posición del número que impone la restricción.
  - `var var_indices: Array[int]`: Índices de las celdas ocultas involucradas.
  - `var mines_needed: int`: Cantidad de minas requeridas restantes.
- `FrontierData`:
  - `var cells: Array[Vector2i]`: Lista de celdas ocultas que componen la frontera actual.
  - `var map: Dictionary`: Mapeo `Vector2i -> int` al índice de variable.
  - `var constraints: Array[FrontierConstraint]`: Conjunto de restricciones activas.
  - `func is_empty() -> bool`: Verifica si no hay frontera activa.
  - `func get_num_vars() -> int`: Retorna la cantidad de variables en la frontera.

### Constantes
- `MAX_COMPONENT_BACKTRACK_VARS: int = 18`: Límite máximo de variables en una componente conexa para evaluar por backtracking sin degradar rendimiento.

### Métodos
- `func solve(board: BoardData, start_pos: Vector2i) -> SolverResult`:  
  Ejecuta la simulación completa desde `start_pos` aplicando de forma iterativa heurísticas triviales, Gauss-Jordan RREF y backtracking de componentes conexas mediante un pipeline modular. Retorna una instancia de [`SolverResult`](#5-solverresult).

---

## 5. `SolverResult`
**Herencia:** `RefCounted`  
**Archivo:** [`scripts/core/generacion-tablero/solver_result.gd`](../../scripts/core/generacion-tablero/solver_result.gd)

Objeto de transferencia de datos con las métricas del análisis lógico del solver.

### Propiedades
- `var is_solvable: bool`: `true` si el tablero se resolvió al $100\%$ sin necesidad de adivinar.
- `var steps: int`: Total de iteraciones de simulación ejecutadas.
- `var revealed_count: int`: Celdas reveladas durante la simulación.
- `var flagged_count: int`: Celdas marcadas como mina.
- `var unsolved_reason: String`: Explicación textual en caso de fallo (ej. `"Bloqueo lógico: Situación de adivinanza o 50/50 detectada"`).
- `var trivial_deductions_count: int`: Movimientos resueltos por heurísticas de nivel 1.
- `var gauss_deductions_count: int`: Movimientos resueltos por álgebra lineal de nivel 2.
- `var backtracking_deductions_count: int`: Movimientos resueltos por Tank Solver de nivel 3.

---

## 6. `BoardGenerator`
**Herencia:** `RefCounted`  
**Archivo:** [`scripts/core/generacion-tablero/board_generator.gd`](../../scripts/core/generacion-tablero/board_generator.gd)  
**Tests Unitarios:** [`test/unit/test_board_generator.gd`](../../test/unit/test_board_generator.gd)  
**Explicación Teórica:** [Algoritmo No-Guess: Pipeline de Generación](../explanation/algoritmo-no-guess.md#1-pipeline-de-generación-por-muestreo-y-rechazo)

Generador de partidas asistido por muestreo por rechazo.

### Constantes
- `MIN_RECOMMENDED_DENSITY: float = 0.12`: $12\%$ densidad mínima recomendada.
- `MAX_RECOMMENDED_DENSITY: float = 0.22`: $22\%$ densidad máxima recomendada.

### Propiedades
- `var width: int`: Ancho de la cuadrícula.
- `var height: int`: Alto de la cuadrícula.
- `var total_mines: int`: Cantidad de minas.
- `var ensure_solvable: bool`: Activa o desactiva la validación con [`MinesweeperSolver`](#4-minesweepersolver).
- `var max_attempts: int = 300`: Límite máximo de intentos de muestreo.

### Métodos
- `func _init(p_width: int = 8, p_height: int = 8, p_total_mines: int = 10, p_ensure_solvable: bool = true) -> void`
- `func validate_density(p_mines: int, p_width: int, p_height: int) -> bool`: Comprueba si la densidad está dentro del rango seguro.
- `func create_empty_board() -> BoardData`: Instancia un [`BoardData`](#2-boarddata) en blanco.
- `func get_protected_zone(first_click: Vector2i, p_width: int, p_height: int) -> Array[Vector2i]`: Retorna las coordenadas de la ventana $3 \times 3$ alrededor del primer clic.
- `func populate_mines(board: BoardData, first_click: Vector2i, p_rng: RandomNumberGenerator = null) -> bool`: Distribuye aleatoriamente las minas fuera de la zona protegida.
- `func generate_board(first_click: Vector2i, p_rng: RandomNumberGenerator = null) -> BoardData`: Genera y valida iterativamente un tablero garantizado hasta encontrar una configuración 100% resoluble.

---

## Navegación y Enlaces Relacionados

- **Capa visual y HUD:** [Referencia de API de TableroView](tablero-view.md)
- **Explicación matemática del solver:** [Explicación del Algoritmo No-Guess](../explanation/algoritmo-no-guess.md)
- **Guía de configuración:** [Cómo Configurar Parámetros del Tablero](../how-to/configurar-tablero.md)
- **Volver al índice:** [Centro de Documentación (`docs/README.md`)](../README.md)
