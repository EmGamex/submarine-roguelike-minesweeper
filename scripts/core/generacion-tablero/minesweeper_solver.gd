class_name MinesweeperSolver
extends RefCounted

const MAX_COMPONENT_BACKTRACK_VARS: int = 18

class FrontierConstraint extends RefCounted:
	var cell_pos: Vector2i
	var var_indices: Array[int] = []
	var mines_needed: int = 0
	
	func _init(p_pos: Vector2i, p_vars: Array[int], p_mines: int) -> void:
		cell_pos = p_pos
		var_indices = p_vars
		mines_needed = p_mines

class FrontierData extends RefCounted:
	var cells: Array[Vector2i] = []
	var map: Dictionary = {}
	var constraints: Array[FrontierConstraint] = []
	
	func is_empty() -> bool:
		return cells.is_empty() or constraints.is_empty()
	
	func get_num_vars() -> int:
		return cells.size()

func solve(board: BoardData, start_pos: Vector2i) -> SolverResult:
	var result := SolverResult.new()
	var sim_board := board.clone()
	
	var opened := sim_board.reveal(start_pos)
	if opened.is_empty():
		result.is_solvable = false
		result.unsolved_reason = "No se pudo revelar la celda inicial"
		return result
	
	result.steps += 1
	
	var max_iterations := sim_board.width * sim_board.height * 2
	var iteration := 0
	
	var deduction_pipeline: Array[Callable] = [
		_apply_trivial_logic,
		_apply_gauss_jordan,
		_apply_connected_components_backtracking
	]
	
	while not sim_board.is_solved() and iteration < max_iterations:
		iteration += 1
		result.steps += 1
		
		var progress_made := false
		for strategy: Callable in deduction_pipeline:
			if strategy.call(sim_board, result):
				progress_made = true
				break
		
		if not progress_made:
			
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

func _extract_frontier(board: BoardData) -> FrontierData:
	var frontier := FrontierData.new()
	
	for pos: Vector2i in board.cells.keys():
		var cell: CellData = board.cells[pos]
		if not cell.is_revealed() or cell.neighbor_mines == 0:
			continue
		
		var neighbors := board.get_neighbors(pos)
		var flagged_count := 0
		var local_vars: Array[int] = []
		
		for n_pos: Vector2i in neighbors:
			var n_cell: CellData = board.cells[n_pos]
			if n_cell.is_flagged():
				flagged_count += 1
			elif n_cell.is_hidden():
				if not frontier.map.has(n_pos):
					frontier.map[n_pos] = frontier.cells.size()
					frontier.cells.append(n_pos)
				local_vars.append(frontier.map[n_pos])
		
		if not local_vars.is_empty():
			var mines_needed := cell.neighbor_mines - flagged_count
			frontier.constraints.append(FrontierConstraint.new(pos, local_vars, mines_needed))
	
	return frontier

func _apply_trivial_logic(board: BoardData, result: SolverResult) -> bool:
	var progress := false
	var revealed_positions: Array[Vector2i] = []
	
	for pos: Vector2i in board.cells.keys():
		var cell: CellData = board.cells[pos]
		if cell.is_revealed() and cell.neighbor_mines > 0:
			revealed_positions.append(pos)
	
	for pos: Vector2i in revealed_positions:
		var cell: CellData = board.cells[pos]
		var neighbors := board.get_neighbors(pos)
		
		var hidden_unflagged: Array[Vector2i] = []
		var flagged_count := 0
		
		for n_pos: Vector2i in neighbors:
			var n_cell: CellData = board.cells[n_pos]
			if n_cell.is_flagged():
				flagged_count += 1
			elif n_cell.is_hidden():
				hidden_unflagged.append(n_pos)
		
		if hidden_unflagged.is_empty():
			continue
		
		var required_mines := cell.neighbor_mines - flagged_count
		
		if required_mines == hidden_unflagged.size():
			for mine_pos: Vector2i in hidden_unflagged:
				var m_cell: CellData = board.cells[mine_pos]
				m_cell.state = CellData.State.FLAGGED
			progress = true
			result.trivial_deductions_count += hidden_unflagged.size()
		
		elif required_mines == 0:
			for safe_pos: Vector2i in hidden_unflagged:
				board.reveal(safe_pos)
			progress = true
			result.trivial_deductions_count += hidden_unflagged.size()
	
	return progress

func _apply_gauss_jordan(board: BoardData, result: SolverResult) -> bool:
	var frontier := _extract_frontier(board)
	if frontier.is_empty():
		return false
	
	var num_vars := frontier.get_num_vars()
	
	var matrix: Array = []
	for constraint: FrontierConstraint in frontier.constraints:
		var row: Array[float] = []
		row.resize(num_vars + 1)
		row.fill(0.0)
		
		for var_idx: int in constraint.var_indices:
			row[var_idx] = 1.0
		
		row[num_vars] = float(constraint.mines_needed)
		matrix.append(row)
	
	var rref := GaussJordanSolver.to_rref(matrix, num_vars)
	var certainties := GaussJordanSolver.find_certainties(rref, num_vars)
	
	var safe_indices: Array[int] = certainties["safe_vars"]
	var mine_indices: Array[int] = certainties["mine_vars"]
	
	var progress := false
	
	for s_idx: int in safe_indices:
		var s_pos: Vector2i = frontier.cells[s_idx]
		board.reveal(s_pos)
		progress = true
		result.gauss_deductions_count += 1
	
	for m_idx: int in mine_indices:
		var m_pos: Vector2i = frontier.cells[m_idx]
		var m_cell: CellData = board.cells[m_pos]
		if m_cell.is_hidden():
			m_cell.state = CellData.State.FLAGGED
			progress = true
			result.gauss_deductions_count += 1
	
	return progress

func _apply_connected_components_backtracking(board: BoardData, result: SolverResult) -> bool:
	var frontier := _extract_frontier(board)
	if frontier.is_empty():
		return false
	
	var num_vars := frontier.get_num_vars()
	
	var adj_sets: Array[Dictionary] = []
	adj_sets.resize(num_vars)
	for i in range(num_vars):
		adj_sets[i] = {}
	
	for c: FrontierConstraint in frontier.constraints:
		var vars := c.var_indices
		var count := vars.size()
		for i in range(count):
			var u: int = vars[i]
			for j in range(i + 1, count):
				var v: int = vars[j]
				adj_sets[u][v] = true
				adj_sets[v][u] = true
	
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
				for neighbor: int in adj_sets[curr].keys():
					if not visited[neighbor]:
						visited[neighbor] = true
						queue.append(neighbor)
			
			components.append(component)
	
	var remaining_mines_global := board.total_mines - board.get_flagged_count()
	var progress := false
	
	for comp: Array in components:
		if comp.size() > MAX_COMPONENT_BACKTRACK_VARS:
			continue # Saltear componentes excesivamente grandes para proteger CPU
		
		var comp_typed: Array[int] = []
		var comp_set: Dictionary = {}
		for item in comp:
			var var_idx: int = item
			comp_typed.append(var_idx)
			comp_set[var_idx] = true
		
		var comp_constraints: Array[FrontierConstraint] = []
		for c: FrontierConstraint in frontier.constraints:
			for v: int in c.var_indices:
				if comp_set.has(v):
					comp_constraints.append(c)
					break
		
		var valid_configs: Array[Dictionary] = []
		var current_assignment: Dictionary = {}
		_backtrack_component(comp_typed, 0, current_assignment, 0, comp_constraints, remaining_mines_global, valid_configs)
		
		if valid_configs.is_empty():
			continue
		
		var total_valid := valid_configs.size()
		for var_idx: int in comp_typed:
			var count_ones := 0
			for config in valid_configs:
				if config.get(var_idx, 0) == 1:
					count_ones += 1
			
			if count_ones == 0:
				var s_pos: Vector2i = frontier.cells[var_idx]
				board.reveal(s_pos)
				progress = true
				result.backtracking_deductions_count += 1
			elif count_ones == total_valid:
				var m_pos: Vector2i = frontier.cells[var_idx]
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
	current_mines: int,
	constraints: Array[FrontierConstraint],
	max_mines_allowed: int,
	valid_configs: Array[Dictionary]
) -> void:
	if index == comp.size():
		for c: FrontierConstraint in constraints:
			var sum := 0
			for v: int in c.var_indices:
				sum += current_assignment.get(v, 0)
			
			if sum != c.mines_needed:
				return
		
		valid_configs.append(current_assignment.duplicate())
		return
	
	var var_idx: int = comp[index]
	
	for value: int in [0, 1]:
		var new_mines := current_mines + value
		if new_mines > max_mines_allowed:
			continue
		
		current_assignment[var_idx] = value
		
		var possible := true
		for c: FrontierConstraint in constraints:
			var sum := 0
			var unassigned := 0
			for v: int in c.var_indices:
				if current_assignment.has(v):
					sum += current_assignment[v]
				else:
					unassigned += 1
			
			if sum > c.mines_needed:
				possible = false
				break
			if sum + unassigned < c.mines_needed:
				possible = false
				break
		
		if possible:
			_backtrack_component(comp, index + 1, current_assignment, new_mines, constraints, max_mines_allowed, valid_configs)
	
	current_assignment.erase(var_idx)
