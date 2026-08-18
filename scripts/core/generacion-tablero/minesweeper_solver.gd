class_name MinesweeperSolver
extends RefCounted

const MAX_COMPONENT_BACKTRACK_VARS: int = 18

## Resuelve una partida simulada a partir del primer click utilizando deducción lógica 100% segura.
## Retorna un SolverResult indicando si el tablero es completamente solucionable sin adivinar.
func solve(board: BoardData, start_pos: Vector2i) -> SolverResult:
	var result := SolverResult.new()
	var sim_board := board.clone()
	
	# Primer paso: Abrir la casilla inicial (cascada)
	var opened := sim_board.reveal(start_pos)
	if opened.is_empty():
		result.is_solvable = false
		result.unsolved_reason = "No se pudo revelar la celda inicial"
		return result
	
	result.steps += 1
	
	var max_iterations := sim_board.width * sim_board.height * 2
	var iteration := 0
	
	while not sim_board.is_solved() and iteration < max_iterations:
		iteration += 1
		result.steps += 1
		
		# 1. Deducciones Triviales
		var trivial_progress := _apply_trivial_logic(sim_board, result)
		if trivial_progress:
			continue
		
		# 2. Álgebra Lineal (Gauss-Jordan RREF)
		var gauss_progress := _apply_gauss_jordan(sim_board, result)
		if gauss_progress:
			continue
		
		# 3. Componentes Conexas y Backtracking Local (Tank Solver)
		var tank_progress := _apply_connected_components_backtracking(sim_board, result)
		if tank_progress:
			continue
		
		# Si ninguna técnica logró deducir un movimiento 100% seguro:
		result.is_solvable = false
		result.unsolved_reason = "Bloqueo lógico: Situación de adivinanza o 50/50 detectada"
		result.revealed_count = sim_board.get_revealed_count()
		result.flagged_count = sim_board.get_flagged_count()
		return result
	
	result.is_solvable = sim_board.is_solved()
	result.revealed_count = sim_board.get_revealed_count()
	result.flagged_count = sim_board.get_flagged_count()
	if not result.is_solvable:
		result.unsolved_reason = "Límite de iteraciones alcanzado"
	
	return result

## Nivel 1: Deducciones Triviales inmediatas
func _apply_trivial_logic(board: BoardData, result: SolverResult) -> bool:
	var progress := false
	var revealed_positions: Array[Vector2i] = []
	
	for pos: Vector2i in board.cells.keys():
		var cell: CellData = board.cells[pos]
		if cell.is_revealed() and cell.neighbor_mines > 0:
			revealed_positions.append(pos)
	
	for pos in revealed_positions:
		var cell: CellData = board.cells[pos]
		var neighbors := board.get_neighbors(pos)
		
		var hidden_unflagged: Array[Vector2i] = []
		var flagged_count := 0
		
		for n_pos in neighbors:
			var n_cell: CellData = board.cells[n_pos]
			if n_cell.is_flagged():
				flagged_count += 1
			elif n_cell.is_hidden():
				hidden_unflagged.append(n_pos)
		
		if hidden_unflagged.is_empty():
			continue
		
		var required_mines := cell.neighbor_mines - flagged_count
		
		# Regla 1: Si faltan minas exactamente igual al número de ocultas -> Todas son minas
		if required_mines == hidden_unflagged.size():
			for mine_pos in hidden_unflagged:
				var m_cell: CellData = board.cells[mine_pos]
				m_cell.state = CellData.State.FLAGGED
			progress = true
			result.trivial_deductions_count += hidden_unflagged.size()
		
		# Regla 2: Si ya se encontraron todas las minas -> Todas las demás ocultas son seguras
		elif required_mines == 0:
			for safe_pos in hidden_unflagged:
				board.reveal(safe_pos)
			progress = true
			result.trivial_deductions_count += hidden_unflagged.size()
	
	return progress

## Nivel 2: Sistema de Ecuaciones y Gauss-Jordan RREF
func _apply_gauss_jordan(board: BoardData, result: SolverResult) -> bool:
	# 1. Identificar frontera de celdas ocultas y celdas reveladas que imponen restricciones
	var frontier_map: Dictionary = {} # Vector2i -> int (variable index)
	var frontier_cells: Array[Vector2i] = []
	var constraint_cells: Array[Vector2i] = []
	
	for pos: Vector2i in board.cells.keys():
		var cell: CellData = board.cells[pos]
		if cell.is_revealed() and cell.neighbor_mines > 0:
			var neighbors := board.get_neighbors(pos)
			var has_hidden := false
			for n_pos in neighbors:
				var n_cell: CellData = board.cells[n_pos]
				if n_cell.is_hidden():
					has_hidden = true
					if not frontier_map.has(n_pos):
						frontier_map[n_pos] = frontier_cells.size()
						frontier_cells.append(n_pos)
			if has_hidden:
				constraint_cells.append(pos)
	
	var num_vars := frontier_cells.size()
	if num_vars == 0 or constraint_cells.is_empty():
		return false
	
	# 2. Construir la matriz aumentada [A | b]
	var matrix: Array = []
	for c_pos in constraint_cells:
		var c_cell: CellData = board.cells[c_pos]
		var neighbors := board.get_neighbors(c_pos)
		
		var flagged_count := 0
		var row: Array[float] = []
		row.resize(num_vars + 1)
		row.fill(0.0)
		
		for n_pos in neighbors:
			var n_cell: CellData = board.cells[n_pos]
			if n_cell.is_flagged():
				flagged_count += 1
			elif n_cell.is_hidden() and frontier_map.has(n_pos):
				var var_idx: int = frontier_map[n_pos]
				row[var_idx] = 1.0
		
		row[num_vars] = float(c_cell.neighbor_mines - flagged_count)
		matrix.append(row)
	
	# 3. Resolver RREF y extraer certezas
	var rref := GaussJordanSolver.to_rref(matrix, num_vars)
	var certainties := GaussJordanSolver.find_certainties(rref, num_vars)
	
	var safe_indices: Array[int] = certainties["safe_vars"]
	var mine_indices: Array[int] = certainties["mine_vars"]
	
	var progress := false
	
	for s_idx in safe_indices:
		var s_pos: Vector2i = frontier_cells[s_idx]
		board.reveal(s_pos)
		progress = true
		result.gauss_deductions_count += 1
	
	for m_idx in mine_indices:
		var m_pos: Vector2i = frontier_cells[m_idx]
		var m_cell: CellData = board.cells[m_pos]
		if m_cell.is_hidden():
			m_cell.state = CellData.State.FLAGGED
			progress = true
			result.gauss_deductions_count += 1
	
	return progress

## Nivel 3: Descomposición en Componentes Conexas y Backtracking Local (Tank Solver)
func _apply_connected_components_backtracking(board: BoardData, result: SolverResult) -> bool:
	# 1. Obtener frontera de variables y restricciones
	var frontier_map: Dictionary = {} # Vector2i -> int
	var frontier_cells: Array[Vector2i] = []
	var constraints: Array[Dictionary] = [] # Array de { "pos": Vector2i, "vars": Array[int], "mines_needed": int }
	
	for pos: Vector2i in board.cells.keys():
		var cell: CellData = board.cells[pos]
		if cell.is_revealed() and cell.neighbor_mines > 0:
			var neighbors := board.get_neighbors(pos)
			var flagged_count := 0
			var local_vars: Array[int] = []
			
			for n_pos in neighbors:
				var n_cell: CellData = board.cells[n_pos]
				if n_cell.is_flagged():
					flagged_count += 1
				elif n_cell.is_hidden():
					if not frontier_map.has(n_pos):
						frontier_map[n_pos] = frontier_cells.size()
						frontier_cells.append(n_pos)
					local_vars.append(frontier_map[n_pos])
			
			if not local_vars.is_empty():
				constraints.append({
					"pos": pos,
					"vars": local_vars,
					"mines_needed": cell.neighbor_mines - flagged_count
				})
	
	var num_vars := frontier_cells.size()
	if num_vars == 0 or constraints.is_empty():
		return false
	
	# 2. Construir grafo de adyacencia entre variables de frontera
	var adj: Array[Array] = []
	for i in range(num_vars):
		adj.append([])
	
	for c in constraints:
		var vars: Array = c["vars"]
		for i in range(vars.size()):
			for j in range(i + 1, vars.size()):
				var u: int = vars[i]
				var v: int = vars[j]
				if not adj[u].has(v):
					adj[u].append(v)
				if not adj[v].has(u):
					adj[v].append(u)
	
	# 3. Separar en componentes conexas
	var visited: Array[bool] = []
	visited.resize(num_vars)
	visited.fill(false)
	var components: Array[Array] = []
	
	for i in range(num_vars):
		if not visited[i]:
			var component: Array[int] = []
			var queue: Array[int] = [i]
			visited[i] = true
			
			while not queue.is_empty():
				var curr: int = queue.pop_front()
				component.append(curr)
				for neighbor: int in adj[curr]:
					if not visited[neighbor]:
						visited[neighbor] = true
						queue.append(neighbor)
			
			components.append(component)
	
	var remaining_mines_global := board.total_mines - board.get_flagged_count()
	var progress := false
	
	# 4. Procesar cada componente conexa por backtracking
	for comp in components:
		if comp.size() > MAX_COMPONENT_BACKTRACK_VARS:
			continue # Saltear componentes excesivamente grandes para no colgar CPU
		
		# Filtrar restricciones que pertenecen a esta componente
		var comp_set: Dictionary = {}
		for var_idx in comp:
			comp_set[var_idx] = true
		
		var comp_constraints: Array[Dictionary] = []
		for c in constraints:
			var belongs := false
			for v in c["vars"]:
				if comp_set.has(v):
					belongs = true
					break
			if belongs:
				comp_constraints.append(c)
		
		# Ejecutar búsqueda exhaustiva de soluciones válidas
		var valid_configs: Array[Dictionary] = [] # Array de configuraciones { var_idx: 0 ó 1 }
		var current_assignment: Dictionary = {}
		_backtrack_component(comp, 0, current_assignment, comp_constraints, remaining_mines_global, valid_configs)
		
		if valid_configs.is_empty():
			continue
		
		var total_valid := valid_configs.size()
		for var_idx in comp:
			var count_ones := 0
			for config in valid_configs:
				if config.get(var_idx, 0) == 1:
					count_ones += 1
			
			# Si en el 100% de las configuraciones es 0 -> Es 100% SEGURA
			if count_ones == 0:
				var s_pos: Vector2i = frontier_cells[var_idx]
				board.reveal(s_pos)
				progress = true
				result.backtracking_deductions_count += 1
			# Si en el 100% de las configuraciones es 1 -> Es 100% MINA
			elif count_ones == total_valid:
				var m_pos: Vector2i = frontier_cells[var_idx]
				var m_cell: CellData = board.cells[m_pos]
				if m_cell.is_hidden():
					m_cell.state = CellData.State.FLAGGED
					progress = true
					result.backtracking_deductions_count += 1
	
	return progress

func _backtrack_component(
	comp: Array[int],
	index: int,
	current_assignment: Dictionary,
	constraints: Array[Dictionary],
	max_mines_allowed: int,
	valid_configs: Array[Dictionary]
) -> void:
	if index == comp.size():
		# Verificar que todas las restricciones asociadas se cumplan exactamente
		for c in constraints:
			var sum := 0
			var all_assigned := true
			for v in c["vars"]:
				if current_assignment.has(v):
					sum += current_assignment[v]
				else:
					all_assigned = false
			
			if all_assigned and sum != c["mines_needed"]:
				return
		
		valid_configs.append(current_assignment.duplicate())
		return
	
	var var_idx: int = comp[index]
	
	# Probar asignación 0 (Libre) y 1 (Mina)
	for value in [0, 1]:
		current_assignment[var_idx] = value
		
		# Poda rápida: verificar si alguna restricción ya se viola
		var possible := true
		var current_mines := 0
		for v in current_assignment.values():
			current_mines += v
		
		if current_mines > max_mines_allowed:
			possible = false
		
		if possible:
			for c in constraints:
				var sum := 0
				var unassigned := 0
				for v in c["vars"]:
					if current_assignment.has(v):
						sum += current_assignment[v]
					else:
						unassigned += 1
				
				# Si ya pusimos más minas de las requeridas -> podar
				if sum > c["mines_needed"]:
					possible = false
					break
				# Si ni aun poniendo minas en todas las restantes alcanzamos -> podar
				if sum + unassigned < c["mines_needed"]:
					possible = false
					break
		
		if possible:
			_backtrack_component(comp, index + 1, current_assignment, constraints, max_mines_allowed, valid_configs)
	
	current_assignment.erase(var_idx)
