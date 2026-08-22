# Cómo Ejecutar y Crear Pruebas Unitarias con GUT

*Navegación:* [Documentación Principal](../README.md) > **How-To: Ejecutar Pruebas GUT**

Esta guía explica cómo ejecutar la suite automatizada de pruebas unitarias con el addon **[GUT (Godot Unit Test)](https://github.com/bitwes/Gut)** y cómo agregar nuevos casos de prueba para validar el motor de resolución lógica o la cuadrícula.

---

## Índice de Secciones
- [1. Ejecutar Pruebas desde la GUI de Godot](#1-ejecutar-pruebas-desde-la-interfaz-gráfica-de-godot)
- [2. Ejecutar Pruebas desde Línea de Comandos (CLI / Headless)](#2-ejecutar-pruebas-desde-línea-de-comandos-cli--headless)
- [3. Estructura de la Suite de Pruebas](#3-estructura-de-la-suite-de-pruebas)
- [4. Receta: Crear un Nuevo Test Unitario](#4-receta-crear-un-nuevo-test-unitario)
- [Navegación y Enlaces Relacionados](#navegación-y-enlaces-relacionados)

---

## 1. Ejecutar Pruebas desde la Interfaz Gráfica de Godot

1. Abre el proyecto en **Godot Engine** con el archivo [`project.godot`](../../project.godot).
2. Verifica que el plugin esté activo en `Proyecto -> Configuración del Proyecto -> Plugins -> GUT` (debe tener el estado **Activo**).
3. En la parte inferior del editor, haz clic en la pestaña **GUT**.
4. Haz clic en el botón verde **Run All** (o **Run** con los scripts seleccionados).
5. Observa el informe de resultados en el visor integrado:
   - Los tests aprobados se marcarán con una marca de verificación.
   - Las aserciones fallidas detallarán la línea exacta, valor esperado y valor obtenido.

---

## 2. Ejecutar Pruebas desde Línea de Comandos (CLI / Headless)

Para integrar las pruebas unitarias en pipelines de CI/CD (como GitHub Actions) o ejecutarlas desde la consola:

### En Windows (PowerShell / CMD)
```powershell
godot.exe --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

### En Linux / macOS
```bash
godot --headless -s addons/gut/gut_cmdln.gd -gdir=res://test/unit -gexit
```

### Parámetros CLI Clave de GUT:
- `-gdir=res://test/unit`: Especifica el directorio de tests a ejecutar ([`test/unit/`](../../test/unit)).
- `-gscript=test_solver.gd`: Ejecuta únicamente un archivo de test específico (ej. [`test_solver.gd`](../../test/unit/test_solver.gd)).
- `-gselect=test_gauss_jordan_rref_basic`: Ejecuta una sola función de prueba por nombre.
- `-gexit`: Cierra Godot automáticamente al finalizar los tests con código de salida `0` (éxito) o `1` (fallo).

---

## 3. Estructura de la Suite de Pruebas

Los archivos de prueba se ubican en [`test/unit/`](../../test/unit):

| Archivo de Prueba | Componente Evaluado | Casos de Prueba Principales |
| :--- | :--- | :--- |
| [`test_board_data.gd`](../../test/unit/test_board_data.gd) | [`BoardData`](../../scripts/core/generacion-tablero/board_data.gd) y [`CellData`](../../scripts/core/generacion-tablero/cell_data.gd) | Dimensiones, índices fuera de límite, conteo de vecinos de 8 direcciones, flood-fill en cascada y banderas. |
| [`test_board_generator.gd`](../../test/unit/test_board_generator.gd) | [`BoardGenerator`](../../scripts/core/generacion-tablero/board_generator.gd) | Validación de densidad ($12\%-22\%$), tamaño de zona protegida en esquinas/bordes/centro, y garantía de partida resoluble. |
| [`test_gauss_jordan.gd`](../../test/unit/test_gauss_jordan.gd) | [`GaussJordanSolver`](../../scripts/core/generacion-tablero/gauss_jordan.gd) | Reducción a RREF, detección de variables inequívocas (0 = segura, 1 = mina) y resta de subconjuntos. |
| [`test_solver.gd`](../../test/unit/test_solver.gd) | [`MinesweeperSolver`](../../scripts/core/generacion-tablero/minesweeper_solver.gd) | Deducciones de nivel 1 (triviales), nivel 2 (Gauss-Jordan) y nivel 3 (tank solver con backtracking). |

---

## 4. Receta: Crear un Nuevo Test Unitario

Para añadir un nuevo archivo de pruebas en [`test/unit/`](../../test/unit):

1. Crea un nuevo script GDScript que herede de `GutTest` (ejemplo: `test/unit/test_nueva_mecanica.gd`):

```gdscript
extends GutTest

func before_each() -> void:
    # Código que se ejecuta antes de cada función de prueba
    pass

func after_each() -> void:
    # Código de limpieza posterior a cada prueba
    pass

func test_mi_nueva_funcionalidad() -> void:
    var board := BoardData.new(4, 4)
    assert_eq(board.width, 4, "El ancho del tablero debe ser 4")
    assert_eq(board.height, 4, "La altura del tablero debe ser 4")
    
    var celda := board.get_cell(Vector2i(0, 0))
    assert_not_null(celda, "La celda (0,0) debe existir")
    assert_true(celda.is_hidden(), "La celda debe inicializarse en estado HIDDEN")
```

2. Guarda el archivo y pulsa **Run All** en el panel GUT para verificar su ejecución inmediata.

---

## Navegación y Enlaces Relacionados

- **Fundamentos del solver probado:** [Explicación del Algoritmo No-Guess](../explanation/algoritmo-no-guess.md)
- **Documentación de clases testeadas:** [Referencia de API Core de Generación](../reference/api-core-tablero.md)
- **Configurar tablero:** [Cómo Configurar Parámetros del Tablero](configurar-tablero.md)
- **Volver al índice:** [Centro de Documentación (`docs/README.md`)](../README.md)
