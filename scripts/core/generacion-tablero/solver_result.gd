class_name SolverResult
extends RefCounted

var is_solvable: bool = false
var steps: int = 0
var revealed_count: int = 0
var flagged_count: int = 0
var unsolved_reason: String = ""
var trivial_deductions_count: int = 0
var gauss_deductions_count: int = 0
var backtracking_deductions_count: int = 0

func _to_string() -> String:
	return "SolverResult(solvable=%s, steps=%d, revealed=%d, flagged=%d, reason='%s')" % [
		is_solvable, steps, revealed_count, flagged_count, unsolved_reason
	]
