class_name TableroView
extends Control

signal game_started
signal game_won
signal game_lost
signal cell_revealed(pos: Vector2i, neighbor_mines: int)
signal cell_flagged(pos: Vector2i, is_flagged: bool)

@export var board_width: int = 8
@export var board_height: int = 8
@export var total_mines: int = 10
@export var ensure_no_guess: bool = true

@export_group("Visuals")
@export var cell_size: Vector2 = Vector2(44, 44)

@export_group("Animation")
@export var enable_sweep_animation: bool = true
@export var sweep_step_delay: float = 0.025
@export var sweep_cell_duration: float = 0.22
@export var enable_panel_resize_animation: bool = true
@export var panel_resize_duration: float = 0.24

enum GameState { SWEEP_ANIMATING, READY_FIRST_CLICK, PLAYING, WON, LOST }

var current_state: GameState = GameState.READY_FIRST_CLICK
var board_data: BoardData
var generator: BoardGenerator
var buttons_grid: Dictionary = {} # Vector2i -> Button
var active_sweep_tween: Tween
var active_panel_tween: Tween

var status_label: Label
var mine_count_label: Label
var flag_count_label: Label
var depth_label: Label
var grid_container: GridContainer
var console_panel: PanelContainer

# Paleta Analógica Fósforo Verde & Radar Táctico Submarino
const COLOR_BG_DARK: Color = Color(0.02, 0.05, 0.04, 1.0)          # Negro oceánico profundo
const COLOR_PANEL_BG: Color = Color(0.04, 0.09, 0.07, 0.95)       # Consola CRT
const COLOR_BORDER_TACTICAL: Color = Color(0.12, 0.28, 0.22, 1.0)  # Borde metálico
const COLOR_PHOSPHOR_BRIGHT: Color = Color(0.20, 1.00, 0.50, 1.0)  # Fósforo verde brillante
const COLOR_PHOSPHOR_DIM: Color = Color(0.10, 0.55, 0.32, 1.0)     # Fósforo verde tenue
const COLOR_AMBER_ALERT: Color = Color(1.00, 0.75, 0.15, 1.0)      # Ámbar baliza/alerta
const COLOR_TORPEDO_RED: Color = Color(1.00, 0.22, 0.25, 1.0)      # Rojo colisión/mina

# Colores tácticos para las señales acústicas de proximidad (números 1 al 8)
const FREQUENCY_COLORS: Dictionary = {
	1: Color(0.20, 1.00, 0.55), # Fósforo verde puro
	2: Color(0.15, 0.95, 0.90), # Cian sonar
	3: Color(0.95, 0.95, 0.30), # Amarillo detector
	4: Color(1.00, 0.65, 0.15), # Ámbar advertencia
	5: Color(1.00, 0.35, 0.20), # Naranja torpedo
	6: Color(1.00, 0.20, 0.45), # Magenta peligro
	7: Color(1.00, 0.15, 0.25), # Carmesí crítico
	8: Color(1.00, 0.05, 0.05)  # Rojo alarma máxima
}

# Estilos procedimentales reutilizables
var style_cell_hidden: StyleBoxFlat
var style_cell_hidden_hover: StyleBoxFlat
var style_cell_hidden_pressed: StyleBoxFlat
var style_cell_revealed: StyleBoxFlat
var style_cell_flagged: StyleBoxFlat
var style_cell_mine_exploded: StyleBoxFlat

func _ready() -> void:
	_init_procedural_styles()
	generator = BoardGenerator.new(board_width, board_height, total_mines, ensure_no_guess)
	_setup_tactical_console_ui()
	reset_game()

## Inicializa los estilos procedurales (StyleBoxFlat) para el look analógico retro
func _init_procedural_styles() -> void:
	# Celda Oculta (Módulo de radar sin escanear)
	style_cell_hidden = StyleBoxFlat.new()
	style_cell_hidden.bg_color = Color(0.06, 0.14, 0.11, 1.0)
	style_cell_hidden.border_color = Color(0.12, 0.30, 0.24, 1.0)
	style_cell_hidden.set_border_width_all(1)
	style_cell_hidden.set_corner_radius_all(3)
	
	# Celda Oculta con Cursor Encima (Barrido de radar iluminado)
	style_cell_hidden_hover = StyleBoxFlat.new()
	style_cell_hidden_hover.bg_color = Color(0.10, 0.24, 0.18, 1.0)
	style_cell_hidden_hover.border_color = COLOR_PHOSPHOR_BRIGHT
	style_cell_hidden_hover.set_border_width_all(1)
	style_cell_hidden_hover.set_corner_radius_all(3)
	style_cell_hidden_hover.shadow_color = Color(0.20, 1.00, 0.50, 0.25)
	style_cell_hidden_hover.shadow_size = 4
	
	# Celda Oculta Presionada (Ping acústico emitido)
	style_cell_hidden_pressed = StyleBoxFlat.new()
	style_cell_hidden_pressed.bg_color = Color(0.15, 0.35, 0.25, 1.0)
	style_cell_hidden_pressed.border_color = COLOR_PHOSPHOR_BRIGHT
	style_cell_hidden_pressed.set_border_width_all(2)
	style_cell_hidden_pressed.set_corner_radius_all(3)
	
	# Celda Revelada / Cavidad Acústica Despejada
	style_cell_revealed = StyleBoxFlat.new()
	style_cell_revealed.bg_color = Color(0.02, 0.06, 0.05, 1.0)
	style_cell_revealed.border_color = Color(0.07, 0.18, 0.14, 1.0)
	style_cell_revealed.set_border_width_all(1)
	style_cell_revealed.set_corner_radius_all(2)
	
	# Celda Marcada con Baliza (Bandera Sonar)
	style_cell_flagged = StyleBoxFlat.new()
	style_cell_flagged.bg_color = Color(0.16, 0.14, 0.04, 1.0)
	style_cell_flagged.border_color = COLOR_AMBER_ALERT
	style_cell_flagged.set_border_width_all(1)
	style_cell_flagged.set_corner_radius_all(3)
	style_cell_flagged.shadow_color = Color(1.00, 0.75, 0.15, 0.30)
	style_cell_flagged.shadow_size = 3
	
	# Celda con Mina Detonada
	style_cell_mine_exploded = StyleBoxFlat.new()
	style_cell_mine_exploded.bg_color = Color(0.25, 0.04, 0.06, 1.0)
	style_cell_mine_exploded.border_color = COLOR_TORPEDO_RED
	style_cell_mine_exploded.set_border_width_all(2)
	style_cell_mine_exploded.set_corner_radius_all(3)
	style_cell_mine_exploded.shadow_color = Color(1.00, 0.22, 0.25, 0.50)
	style_cell_mine_exploded.shadow_size = 6

## Construye la jerarquía visual de la consola de radar
func _setup_tactical_console_ui() -> void:
	for child in get_children():
		child.queue_free()
	
	# Fondo general del terminal
	var background := ColorRect.new()
	background.name = "ConsoleBackground"
	background.color = COLOR_BG_DARK
	background.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(background)
	
	# Centrador principal
	var center_root := CenterContainer.new()
	center_root.name = "CenterRoot"
	center_root.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(center_root)
	
	# Panel de marco de la consola
	console_panel = PanelContainer.new()
	console_panel.name = "RadarConsolePanel"
	var panel_style := StyleBoxFlat.new()
	panel_style.bg_color = COLOR_PANEL_BG
	panel_style.border_color = COLOR_BORDER_TACTICAL
	panel_style.set_border_width_all(2)
	panel_style.set_corner_radius_all(8)
	panel_style.content_margin_left = 20
	panel_style.content_margin_right = 20
	panel_style.content_margin_top = 16
	panel_style.content_margin_bottom = 16
	panel_style.shadow_color = Color(0.1, 0.8, 0.4, 0.08)
	panel_style.shadow_size = 12
	console_panel.add_theme_stylebox_override("panel", panel_style)
	center_root.add_child(console_panel)
	
	var v_layout := VBoxContainer.new()
	v_layout.name = "VerticalLayout"
	v_layout.add_theme_constant_override("separation", 12)
	console_panel.add_child(v_layout)
	
	# 1. Cabecera Táctica del Submarino
	var header_bar := HBoxContainer.new()
	header_bar.name = "HeaderBar"
	header_bar.alignment = BoxContainer.ALIGNMENT_CENTER
	v_layout.add_child(header_bar)
	
	var title_label := Label.new()
	title_label.text = "◈ U-SUB TACTICAL SONAR // PROTO-GRID ◈"
	title_label.add_theme_color_override("font_color", COLOR_PHOSPHOR_BRIGHT)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	header_bar.add_child(title_label)
	
	# 2. Barra de Telemetría (Minas detectadas, Boyas marcadas, Profundidad)
	var telemetry_box := HBoxContainer.new()
	telemetry_box.name = "TelemetryBox"
	telemetry_box.alignment = BoxContainer.ALIGNMENT_CENTER
	telemetry_box.add_theme_constant_override("separation", 24)
	v_layout.add_child(telemetry_box)
	
	mine_count_label = Label.new()
	mine_count_label.text = "[ MINAS: %02d ]" % total_mines
	mine_count_label.add_theme_color_override("font_color", COLOR_TORPEDO_RED)
	telemetry_box.add_child(mine_count_label)
	
	flag_count_label = Label.new()
	flag_count_label.text = "[ BOYAS: 00 ]"
	flag_count_label.add_theme_color_override("font_color", COLOR_AMBER_ALERT)
	telemetry_box.add_child(flag_count_label)
	
	depth_label = Label.new()
	depth_label.text = "[ SECTOR: 08-ALPHA // NO-GUESS ]"
	depth_label.add_theme_color_override("font_color", COLOR_PHOSPHOR_DIM)
	telemetry_box.add_child(depth_label)
	
	# 3. Visor de Estado del Sonar
	var status_panel := PanelContainer.new()
	var st_style := StyleBoxFlat.new()
	st_style.bg_color = Color(0.02, 0.06, 0.04, 0.8)
	st_style.border_color = Color(0.08, 0.22, 0.16, 1.0)
	st_style.set_border_width_all(1)
	st_style.set_corner_radius_all(4)
	st_style.content_margin_top = 4
	st_style.content_margin_bottom = 4
	st_style.content_margin_left = 8
	st_style.content_margin_right = 8
	status_panel.add_theme_stylebox_override("panel", st_style)
	v_layout.add_child(status_panel)
	
	status_label = Label.new()
	status_label.name = "StatusDisplay"
	status_label.text = ">> SONAR EN ESPERA: HAZ CLIC EN CUALQUIER COORDENADA PARA INICIAR BARRIDO <<"
	status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	status_label.clip_text = true
	status_label.add_theme_color_override("font_color", COLOR_PHOSPHOR_BRIGHT)
	status_panel.add_child(status_label)
	
	# 4. Marco de la Cuadrícula del Radar
	var radar_scope := CenterContainer.new()
	radar_scope.name = "RadarScope"
	v_layout.add_child(radar_scope)
	
	var grid_frame := PanelContainer.new()
	grid_frame.name = "GridFrame"
	var gf_style := StyleBoxFlat.new()
	gf_style.bg_color = Color(0.01, 0.04, 0.03, 1.0)
	gf_style.border_color = Color(0.15, 0.40, 0.30, 1.0)
	gf_style.set_border_width_all(2)
	gf_style.set_corner_radius_all(6)
	gf_style.content_margin_left = 8
	gf_style.content_margin_right = 8
	gf_style.content_margin_top = 8
	gf_style.content_margin_bottom = 8
	grid_frame.add_theme_stylebox_override("panel", gf_style)
	radar_scope.add_child(grid_frame)
	
	grid_container = GridContainer.new()
	grid_container.name = "GridContainer"
	grid_container.columns = board_width
	grid_container.add_theme_constant_override("h_separation", 4)
	grid_container.add_theme_constant_override("v_separation", 4)
	grid_frame.add_child(grid_container)
	
	# 5. Panel Inferior de Comandos y Leyenda Táctica
	var footer_box := HBoxContainer.new()
	footer_box.name = "FooterBox"
	v_layout.add_child(footer_box)
	
	var legend_label := Label.new()
	legend_label.text = "L-CLICK: PING ACÚSTICO | R-CLICK: MARCAR BOYAS (▲) | M-CLICK: CHORDING"
	legend_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	legend_label.add_theme_color_override("font_color", COLOR_PHOSPHOR_DIM)
	legend_label.add_theme_font_size_override("font_size", 11)
	footer_box.add_child(legend_label)
	
	var restart_btn := Button.new()
	restart_btn.name = "RestartButton"
	restart_btn.text = "[ REINICIAR SONAR ]"
	_style_tactical_button(restart_btn)
	restart_btn.pressed.connect(reset_game)
	footer_box.add_child(restart_btn)

## Aplica estilos tácticos a un botón de control
func _style_tactical_button(btn: Button) -> void:
	var normal_style := StyleBoxFlat.new()
	normal_style.bg_color = Color(0.06, 0.16, 0.12, 1.0)
	normal_style.border_color = Color(0.18, 0.45, 0.35, 1.0)
	normal_style.set_border_width_all(1)
	normal_style.set_corner_radius_all(4)
	normal_style.content_margin_left = 10
	normal_style.content_margin_right = 10
	normal_style.content_margin_top = 4
	normal_style.content_margin_bottom = 4
	
	var hover_style := StyleBoxFlat.new()
	hover_style.bg_color = Color(0.10, 0.28, 0.20, 1.0)
	hover_style.border_color = COLOR_PHOSPHOR_BRIGHT
	hover_style.set_border_width_all(1)
	hover_style.set_corner_radius_all(4)
	hover_style.content_margin_left = 10
	hover_style.content_margin_right = 10
	hover_style.content_margin_top = 4
	hover_style.content_margin_bottom = 4
	
	btn.add_theme_stylebox_override("normal", normal_style)
	btn.add_theme_stylebox_override("hover", hover_style)
	btn.add_theme_stylebox_override("pressed", hover_style)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", COLOR_PHOSPHOR_BRIGHT)
	btn.add_theme_color_override("font_hover_color", Color.WHITE)

## Actualiza el texto de estado del sonar sin provocar sacudidas en el marco de la consola
func _set_status_text(new_text: String, text_color: Color = COLOR_PHOSPHOR_BRIGHT) -> void:
	if status_label == null:
		return
	status_label.text = new_text
	status_label.add_theme_color_override("font_color", text_color)

## Calcula el tamaño óptimo de la consola basándose en la cuadrícula y las barras tácticas
func _calculate_console_target_size() -> Vector2:
	var grid_w := float(board_width * int(cell_size.x) + max(board_width - 1, 0) * 4 + 16)
	var grid_h := float(board_height * int(cell_size.y) + max(board_height - 1, 0) * 4 + 16)
	
	# Ancho mínimo para alojar cómodamente la barra de cabecera, telemetría y controles inferiores
	var min_ui_width := 560.0
	var target_w := maxf(grid_w + 40.0, min_ui_width)
	
	# Altura total estimada: cuadrícula + cabecera, telemetría, status, footer y márgenes
	var target_h := grid_h + 200.0
	
	return Vector2(target_w, target_h)

## Ajusta suavemente las dimensiones del marco de la consola mediante Tween (en X e Y)
func _update_console_size(animate: bool = true) -> void:
	if console_panel == null or not is_inside_tree():
		return
	
	if active_panel_tween and active_panel_tween.is_valid():
		active_panel_tween.kill()
	
	var target_size := _calculate_console_target_size()
	var current_size := console_panel.custom_minimum_size
	
	if current_size == Vector2.ZERO:
		current_size = console_panel.size if console_panel.size != Vector2.ZERO else target_size
	
	if enable_panel_resize_animation and animate and current_size != target_size:
		console_panel.custom_minimum_size = current_size
		active_panel_tween = create_tween().set_parallel(true)
		active_panel_tween.tween_property(console_panel, "custom_minimum_size:x", target_size.x, panel_resize_duration)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
		active_panel_tween.tween_property(console_panel, "custom_minimum_size:y", target_size.y, panel_resize_duration)\
			.set_trans(Tween.TRANS_CUBIC)\
			.set_ease(Tween.EASE_OUT)
	else:
		console_panel.custom_minimum_size = target_size

## Modifica las dimensiones del tablero dinámicamente y recalibra la consola
func set_board_dimensions(new_width: int, new_height: int, new_mines: int = -1, no_guess: bool = true) -> void:
	board_width = new_width
	board_height = new_height
	if new_mines > 0:
		total_mines = new_mines
	ensure_no_guess = no_guess
	reset_game()

func reset_game() -> void:
	if active_sweep_tween and active_sweep_tween.is_valid():
		active_sweep_tween.kill()
		
	generator = BoardGenerator.new(board_width, board_height, total_mines, ensure_no_guess)
	board_data = generator.create_empty_board()
	
	buttons_grid.clear()
	for child in grid_container.get_children():
		grid_container.remove_child(child)
		child.queue_free()
	
	grid_container.columns = board_width
	
	for y in range(board_height):
		for x in range(board_width):
			var pos := Vector2i(x, y)
			var btn := Button.new()
			btn.custom_minimum_size = cell_size
			btn.pivot_offset = cell_size * 0.5
			btn.text = "·" # Indicador de retícula analógica
			btn.focus_mode = Control.FOCUS_NONE
			
			_apply_hidden_style(btn)
			btn.gui_input.connect(_on_cell_gui_input.bind(pos))
			
			grid_container.add_child(btn)
			buttons_grid[pos] = btn
	
	_update_telemetry()
	_update_console_size(enable_panel_resize_animation)
	
	if enable_sweep_animation:
		play_sonar_sweep_animation()
	else:
		current_state = GameState.READY_FIRST_CLICK
		_set_status_text(">> SONAR EN ESPERA: HAZ CLIC EN CUALQUIER COORDENADA PARA INICIAR BARRIDO <<", COLOR_PHOSPHOR_BRIGHT)

## Ejecuta la animación de barrido de sonar con un Tween paralelo escalonado por diagonales (x + y)
func play_sonar_sweep_animation(on_complete: Callable = Callable()) -> void:
	current_state = GameState.SWEEP_ANIMATING
	_set_status_text(">> CALIBRANDO BARRIDO ACÚSTICO DEL SECTOR... <<", COLOR_AMBER_ALERT)
	
	if active_sweep_tween and active_sweep_tween.is_valid():
		active_sweep_tween.kill()
	
	active_sweep_tween = create_tween().set_parallel(true)
	
	for y in range(board_height):
		for x in range(board_width):
			var pos := Vector2i(x, y)
			var btn: Button = buttons_grid.get(pos, null)
			if btn == null:
				continue
			
			btn.modulate = Color(0.1, 0.4, 0.2, 0.2)
			btn.scale = Vector2(0.8, 0.8)
			
			var delay: float = float(x + y) * sweep_step_delay
			
			active_sweep_tween.tween_property(btn, "modulate", COLOR_PHOSPHOR_BRIGHT * 1.4, sweep_cell_duration * 0.4)\
				.set_delay(delay)\
				.set_trans(Tween.TRANS_QUAD)\
				.set_ease(Tween.EASE_OUT)
			
			active_sweep_tween.tween_property(btn, "scale", Vector2(1.12, 1.12), sweep_cell_duration * 0.4)\
				.set_delay(delay)\
				.set_trans(Tween.TRANS_BACK)\
				.set_ease(Tween.EASE_OUT)
			
			active_sweep_tween.tween_property(btn, "modulate", Color.WHITE, sweep_cell_duration * 0.6)\
				.set_delay(delay + sweep_cell_duration * 0.4)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
			
			active_sweep_tween.tween_property(btn, "scale", Vector2.ONE, sweep_cell_duration * 0.6)\
				.set_delay(delay + sweep_cell_duration * 0.4)\
				.set_trans(Tween.TRANS_SINE)\
				.set_ease(Tween.EASE_IN_OUT)
	
	active_sweep_tween.chain().tween_callback(func() -> void:
		current_state = GameState.READY_FIRST_CLICK
		_set_status_text(">> SONAR EN ESPERA: HAZ CLIC EN CUALQUIER COORDENADA PARA INICIAR BARRIDO <<", COLOR_PHOSPHOR_BRIGHT)
		if on_complete.is_valid():
			on_complete.call()
	)

func _apply_hidden_style(btn: Button) -> void:
	btn.disabled = false
	btn.text = "·"
	btn.add_theme_stylebox_override("normal", style_cell_hidden)
	btn.add_theme_stylebox_override("hover", style_cell_hidden_hover)
	btn.add_theme_stylebox_override("pressed", style_cell_hidden_pressed)
	btn.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	btn.add_theme_color_override("font_color", COLOR_PHOSPHOR_DIM)
	btn.add_theme_color_override("font_hover_color", COLOR_PHOSPHOR_BRIGHT)

func _on_cell_gui_input(event: InputEvent, pos: Vector2i) -> void:
	if current_state == GameState.SWEEP_ANIMATING or current_state == GameState.WON or current_state == GameState.LOST:
		return
	
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_LEFT:
			_handle_left_click(pos)
		elif event.button_index == MOUSE_BUTTON_RIGHT:
			_handle_right_click(pos)
		elif event.button_index == MOUSE_BUTTON_MIDDLE:
			_try_chord(pos)

func _handle_left_click(pos: Vector2i) -> void:
	var cell := board_data.get_cell(pos)
	if cell == null:
		return
	
	# Primer click: generar tablero garantizado No-Guess
	if current_state == GameState.READY_FIRST_CLICK:
		_set_status_text(">> CALCULANDO MATRICES GAUSS-JORDAN... GENERANDO TABLERO SIN 50/50 <<", COLOR_AMBER_ALERT)
		
		board_data = generator.generate_board(pos)
		current_state = GameState.PLAYING
		
		_set_status_text(">> SONAR ACTIVO // SECTOR 100% RESOLUBLE POR DEDUCCIÓN LÓGICA <<", COLOR_PHOSPHOR_BRIGHT)
		game_started.emit()
	
	if cell.is_flagged():
		return
	
	if cell.is_revealed():
		_try_chord(pos)
		return
	
	if cell.is_mine:
		_game_over(false, pos)
		return
	
	var revealed_positions := board_data.reveal(pos)
	for r_pos in revealed_positions:
		_update_cell_visual(r_pos)
		var r_cell := board_data.get_cell(r_pos)
		cell_revealed.emit(r_pos, r_cell.neighbor_mines)
	
	_update_telemetry()
	_check_win_condition()

func _handle_right_click(pos: Vector2i) -> void:
	if current_state == GameState.READY_FIRST_CLICK or current_state == GameState.SWEEP_ANIMATING:
		return
	
	var cell := board_data.get_cell(pos)
	if cell == null or cell.is_revealed():
		return
	
	board_data.toggle_flag(pos)
	_update_cell_visual(pos)
	_update_telemetry()
	cell_flagged.emit(pos, cell.is_flagged())

func _try_chord(pos: Vector2i) -> void:
	var cell := board_data.get_cell(pos)
	if cell == null or not cell.is_revealed() or cell.neighbor_mines == 0:
		return
	
	var neighbors := board_data.get_neighbors(pos)
	var flag_count := 0
	for n_pos in neighbors:
		var n_cell := board_data.get_cell(n_pos)
		if n_cell.is_flagged():
			flag_count += 1
	
	if flag_count == cell.neighbor_mines:
		for n_pos in neighbors:
			var n_cell := board_data.get_cell(n_pos)
			if n_cell.is_hidden() and not n_cell.is_flagged():
				if n_cell.is_mine:
					_game_over(false, n_pos)
					return
				else:
					var newly_revealed := board_data.reveal(n_pos)
					for r_pos in newly_revealed:
						_update_cell_visual(r_pos)
		_update_telemetry()
		_check_win_condition()

func _update_cell_visual(pos: Vector2i) -> void:
	var btn: Button = buttons_grid.get(pos, null)
	var cell := board_data.get_cell(pos)
	if btn == null or cell == null:
		return
	
	if cell.is_revealed():
		btn.disabled = true
		btn.add_theme_stylebox_override("disabled", style_cell_revealed)
		
		if cell.is_mine:
			btn.text = "☢"
			btn.add_theme_stylebox_override("disabled", style_cell_mine_exploded)
			btn.add_theme_color_override("font_disabled_color", COLOR_TORPEDO_RED)
		elif cell.neighbor_mines > 0:
			btn.text = str(cell.neighbor_mines)
			var freq_color: Color = FREQUENCY_COLORS.get(cell.neighbor_mines, COLOR_PHOSPHOR_BRIGHT)
			btn.add_theme_color_override("font_disabled_color", freq_color)
		else:
			btn.text = ""
			btn.add_theme_color_override("font_disabled_color", COLOR_PHOSPHOR_DIM)
	elif cell.is_flagged():
		btn.disabled = false
		btn.text = "▲" # Baliza acústica de sonar
		btn.add_theme_stylebox_override("normal", style_cell_flagged)
		btn.add_theme_stylebox_override("hover", style_cell_flagged)
		btn.add_theme_color_override("font_color", COLOR_AMBER_ALERT)
		btn.add_theme_color_override("font_hover_color", Color.WHITE)
	else:
		_apply_hidden_style(btn)

func _update_telemetry() -> void:
	if mine_count_label and board_data:
		var remaining := maxi(board_data.total_mines - board_data.get_flagged_count(), 0)
		mine_count_label.text = "[ MINAS REST.: %02d ]" % remaining
	if flag_count_label and board_data:
		flag_count_label.text = "[ BOYAS: %02d ]" % board_data.get_flagged_count()

func _check_win_condition() -> void:
	if board_data.is_solved():
		current_state = GameState.WON
		_set_status_text("✔ ¡SECTOR ASEGURADO! CASCO ÍNTEGRO // RUTA SUBMARINA DESPEJADA", COLOR_PHOSPHOR_BRIGHT)
		game_won.emit()

func _game_over(won: bool, _hit_pos: Vector2i = Vector2i(-1, -1)) -> void:
	current_state = GameState.LOST if not won else GameState.WON
	if not won:
		_set_status_text("⚠ ¡COLISIÓN SUBACUÁTICA! MINA DETONADA // CASCO COMPROMETIDO", COLOR_TORPEDO_RED)
		
		# Revelar todas las minas en la consola
		for pos: Vector2i in board_data.cells.keys():
			var cell := board_data.get_cell(pos)
			if cell.is_mine:
				cell.reveal()
				_update_cell_visual(pos)
		game_lost.emit()
