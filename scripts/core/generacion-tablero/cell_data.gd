class_name CellData
extends RefCounted

## Estados posibles de una celda
enum State {
	HIDDEN,    ## Oculta / Cubierta
	REVEALED,  ## Revelada / Descubierta
	FLAGGED    ## Marcada con bandera de mina
}

var pos: Vector2i = Vector2i.ZERO
var is_mine: bool = false
var neighbor_mines: int = 0
var state: State = State.HIDDEN

func _init(p_pos: Vector2i = Vector2i.ZERO, p_is_mine: bool = false) -> void:
	pos = p_pos
	is_mine = p_is_mine
	neighbor_mines = 0
	state = State.HIDDEN

func is_hidden() -> bool:
	return state == State.HIDDEN

func is_revealed() -> bool:
	return state == State.REVEALED

func is_flagged() -> bool:
	return state == State.FLAGGED

func reveal() -> void:
	state = State.REVEALED

func toggle_flag() -> bool:
	if state == State.HIDDEN:
		state = State.FLAGGED
		return true
	elif state == State.FLAGGED:
		state = State.HIDDEN
		return true
	return false

func clone() -> CellData:
	var copy := CellData.new(pos, is_mine)
	copy.neighbor_mines = neighbor_mines
	copy.state = state
	return copy
