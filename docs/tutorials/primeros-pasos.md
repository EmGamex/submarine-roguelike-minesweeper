# Tutorial: Primeros Pasos con Submarine Roguelike Minesweeper

*Navegación:* [Documentación Principal](../README.md) > **Tutorials: Primeros Pasos**

Este tutorial te guiará paso a paso desde la descarga del repositorio hasta la ejecución de tu primera partida táctica en Godot 4. Al finalizar, tendrás el entorno listo y comprenderás el ciclo de juego y los controles básicos del radar sonar.

---

## Índice de Secciones
- [Objetivo de Aprendizaje](#objetivo-de-aprendizaje)
- [1. Requisitos Previos](#1-requisitos-previos)
- [2. Clonar y Abrir el Proyecto](#2-clonar-y-abrir-el-proyecto)
- [3. Ejecutar la Escena Principal](#3-ejecutar-la-escena-principal)
- [4. Recorrido Guiado por tu Primera Partida](#4-recorrido-guiado-por-tu-primera-partida)
- [Navegación y Enlaces Relacionados](#navegación-y-enlaces-relacionados)

---

## Objetivo de Aprendizaje
- Configurar el entorno de desarrollo con Godot 4.
- Abrir e importar el archivo [`project.godot`](../../project.godot) correctamente.
- Ejecutar la escena principal del tablero táctico ([`res://scenes/game/tablero.tscn`](../../scenes/game/tablero.tscn)).
- Realizar una partida completa comprendiendo la emisión de pings acústicos, el marcado de boyas sonares y el chording.

---

## 1. Requisitos Previos

Asegúrate de contar con:
- **[Godot Engine 4.3+](https://godotengine.org/download)** (versión estándar con soporte para GDScript).
- **Git** instalado en tu sistema operativo.
- Tarjeta gráfica con soporte para **Vulkan** o **OpenGL 3.3 / OpenGL ES 3.0** (el proyecto usa el renderizador *GL Compatibility* configurado en [`project.godot`](../../project.godot)).

---

## 2. Clonar y Abrir el Proyecto

1. Abre tu terminal de comandos preferida y clona el repositorio:
   ```bash
   git clone https://github.com/EmGamex/submarine-roguelike-minesweeper.git
   cd submarine-roguelike-minesweeper
   ```

2. Abre **Godot Engine**.
3. En el Administrador de Proyectos de Godot, haz clic en el botón **Importar** (Import).
4. Navega hasta la carpeta descargada y selecciona el archivo [`project.godot`](../../project.godot).
5. Haz clic en **Importar y Editar** (Import & Edit).

> [!NOTE]
> La primera vez que abras el proyecto, Godot importará los recursos y registrará automáticamente las clases globales (`class_name`) del sistema de generación como [`BoardData`](../../scripts/core/generacion-tablero/board_data.gd), [`BoardGenerator`](../../scripts/core/generacion-tablero/board_generator.gd) y [`TableroView`](../../scripts/ui/tablero_view.gd).

---

## 3. Ejecutar la Escena Principal

1. En la esquina superior derecha del editor de Godot, haz clic en el botón **Play** (o presiona la tecla `F5`).
2. El juego abrirá la escena [`tablero.tscn`](../../scenes/game/tablero.tscn) con la consola táctica CRT de color verde fósforo:
   - Verás el encabezado: `◈ U-SUB TACTICAL SONAR // PROTO-GRID ◈`.
   - La telemetría indicará `[ MINAS: 10 ]`, `[ BOYAS: 00 ]` y `[ SECTOR: 08-ALPHA // NO-GUESS ]`.
   - El monitor de estado mostrará una animación de barrido diagonal por el radar.

---

## 4. Recorrido Guiado por tu Primera Partida

### Paso A: Emitir el Primer Ping Acústico
- Pasa el cursor por encima de cualquier casilla de la cuadrícula. Notarás un sutil brillo verde de escaneo implementado mediante estilos vectoriales en [`TableroView._init_procedural_styles()`](../../scripts/ui/tablero_view.gd).
- Haz **clic izquierdo** en cualquier casilla (por ejemplo, en el centro).

> [!IMPORTANT]
> El primer clic **nunca detonará una mina**. La función [`BoardGenerator.get_protected_zone()`](../../scripts/core/generacion-tablero/board_generator.gd) garantiza una zona protegida $3 \times 3$ donde la casilla seleccionada siempre tendrá valor $0$, provocando una cascada automática que despeja un sector inicial seguro. Para conocer el algoritmo completo, consulta la [Explicación del Algoritmo No-Guess](../explanation/algoritmo-no-guess.md).

### Paso B: Interpretar las Señales de Proximidad
- Tras la apertura en cascada generada por [`BoardData.reveal()`](../../scripts/core/generacion-tablero/board_data.gd), observarás números con distintos colores de frecuencia acústica definidos en `TableroView.FREQUENCY_COLORS`:
  - **1 (Verde)**: $1$ mina adyacente.
  - **2 (Cian)**: $2$ minas adyacentes.
  - **3 (Amarillo)**: $3$ minas adyacentes.
  - **4 (Ámbar) o superior**: Zona de alta densidad de torpedos/minas.

### Paso C: Desplegar Boyas Sonares (Marcar Minas)
- Identifica una casilla que lógicamente contenga una mina.
- Haz **clic derecho** sobre ella: aparecerá una boya baliza dorada (`▲`), cambiando el estado en [`CellData.toggle_flag()`](../../scripts/core/generacion-tablero/cell_data.gd).
- Observa cómo la telemetría actualiza el indicador `[ MINAS REST.: XX ]` y `[ BOYAS: 01 ]`.

### Paso D: Ejecutar un Chording Acústico
- Cuando hayas marcado todas las minas que rodean a un número revelado:
  - Haz **clic central** sobre el número, o simplemente haz **clic izquierdo** nuevamente sobre él (ejecuta `TableroView._try_chord()`).
  - Si las boyas coinciden con el número requerido, todas las celdas adyacentes restantes se revelarán instantáneamente.

> [!WARNING]
> Si colocas una boya en una celda incorrecta y realizas un chording, se revelará una casilla con mina y el casco sufrirá una colisión subacuática crítica (`TableroView._game_over(false)`).

### Paso E: Victoria o Reinicio
- Si logras revelar todas las casillas libres de minas, el monitor anunciará:
  `✔ ¡SECTOR ASEGURADO! CASCO ÍNTEGRO // RUTA SUBMARINA DESPEJADA` y emitirá la señal `TableroView.game_won`.
- Para iniciar una nueva partida en cualquier momento, presiona el botón inferior `[ REINICIAR SONAR ]` (invoca `TableroView.reset_game()`).

---

## Navegación y Enlaces Relacionados

- **Siguiente paso práctico:** [Cómo Configurar Parámetros del Tablero](../how-to/configurar-tablero.md)
- **Aprender a testear:** [Cómo Ejecutar y Crear Pruebas con GUT](../how-to/ejecutar-pruebas-gut.md)
- **Fundamentos teóricos:** [Explicación del Algoritmo No-Guess](../explanation/algoritmo-no-guess.md)
- **Referencia de API:** [API de TableroView](../reference/tablero-view.md) | [API Core de Generación](../reference/api-core-tablero.md)
- **Volver al índice:** [Centro de Documentación (`docs/README.md`)](../README.md)
