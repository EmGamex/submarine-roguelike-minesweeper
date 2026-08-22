# Centro de Documentación Técnica

*Ubicación:* [`README principal`](../README.md) > **docs/README.md**

Bienvenido a la documentación oficial de **Submarine Roguelike Minesweeper**.

Esta documentación está organizada bajo el marco metodológico **[Diátaxis](https://diataxis.fr/)**, dividida en cuatro cuadrantes para facilitar la navegación según tu necesidad actual:

```
                  APRENDIZAJE (Práctico)
                            │
               TUTORIALS    │    HOW-TO GUIDES
           (Primeros pasos) │ (Recetas y tareas)
                            │
──────── TRABAJO ───────────┼─────────── ENTENDIMIENTO ────────
                            │
               REFERENCE    │    EXPLANATION
           (APIs y firmas)  │  (Conceptos y mate)
                            │
                 INFORMACIÓN (Teórico)
```

---

## Mapa de Navegación por Cuadrantes

### 1. Tutoriales (Tutorials)
*Orientados al aprendizaje paso a paso para recién llegados.*
- [**Primeros Pasos**](tutorials/primeros-pasos.md): Descarga, importación del proyecto en Godot 4, apertura de la escena [`res://scenes/game/tablero.tscn`](../scenes/game/tablero.tscn) y recorrido guiado por las mecánicas del sonar.

### 2. Guías Prácticas (How-To Guides)
*Recetas concretas para resolver problemas específicos.*
- [**Configurar Parámetros del Tablero**](how-to/configurar-tablero.md): Personalización de tamaño ($W \times H$), cantidad de minas, validación de densidad y configuración de animaciones en [`TableroView`](../scripts/ui/tablero_view.gd).
- [**Ejecutar y Crear Pruebas con GUT**](how-to/ejecutar-pruebas-gut.md): Cómo correr la batería de tests unitarios desde la interfaz gráfica de Godot y en modo headless (CLI) para integración continua.

### 3. Explicaciones Teóricas (Explanation)
*Conceptos profundos, arquitectura de sistemas y fundamentos matemáticos.*
- [**Algoritmo No-Guess y Solver Multinivel**](explanation/algoritmo-no-guess.md): Fundamentos de la eliminación del azar: zona protegida $3 \times 3$, reducción Gauss-Jordan RREF en [`GaussJordanSolver`](../scripts/core/generacion-tablero/gauss_jordan.gd) y descomposición en componentes conexas con Tank Solver en [`MinesweeperSolver`](../scripts/core/generacion-tablero/minesweeper_solver.gd).
- [**Arquitectura Visual y Consola CRT**](explanation/arquitectura-visual-crt.md): Decisiones estéticas del sonar en fósforo verde, estilización procedural con `StyleBoxFlat` y curvas de animación con `Tween`.

### 4. Referencia Técnica (Reference)
*Especificaciones técnicas exactas, firmas de métodos, propiedades y contratos.*
- [**API Core de Generación de Tablero**](reference/api-core-tablero.md): Documentación de [`CellData`](../scripts/core/generacion-tablero/cell_data.gd), [`BoardData`](../scripts/core/generacion-tablero/board_data.gd), [`BoardGenerator`](../scripts/core/generacion-tablero/board_generator.gd), [`MinesweeperSolver`](../scripts/core/generacion-tablero/minesweeper_solver.gd), [`GaussJordanSolver`](../scripts/core/generacion-tablero/gauss_jordan.gd) y [`SolverResult`](../scripts/core/generacion-tablero/solver_result.gd).
- [**API de TableroView y HUD**](reference/tablero-view.md): Propiedades `@export`, señales de eventos, constantes de colores de frecuencias y métodos de la consola táctica en [`TableroView`](../scripts/ui/tablero_view.gd).

---

## Enlaces Rápidos al Código Fuente

- Escena de inicio: [`res://scenes/game/tablero.tscn`](../scenes/game/tablero.tscn)
- Controlador de UI: [`TableroView`](../scripts/ui/tablero_view.gd)
- Generador de tableros: [`BoardGenerator`](../scripts/core/generacion-tablero/board_generator.gd)
- Solver determinista: [`MinesweeperSolver`](../scripts/core/generacion-tablero/minesweeper_solver.gd)
- Suite de pruebas GUT: [`test/unit/`](../test/unit)
