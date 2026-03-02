extends RefCounted
class_name Stat

signal on_value_changed(new_value: float)

var _base_value: float
var _modifiers: Array[StatModifier] = []
var _is_dirty: bool = true
var _cached_value: float

func _init(base: float = 0.0):
	_base_value = base

func set_base_value(val: float):
	_base_value = val
	_is_dirty = true
	on_value_changed.emit(get_value())

func get_value() -> float:
	if _is_dirty:
		_cached_value = calculate_final_value()
		_is_dirty = false
	return _cached_value

func add_modifier(mod: StatModifier):
	_modifiers.append(mod)
	# Sort so Flat runs first, then Additive %, then Multiplicative %
	_modifiers.sort_custom(func(a, b): return a.type < b.type)
	_is_dirty = true
	on_value_changed.emit(get_value())

func remove_modifier(mod: StatModifier):
	_modifiers.erase(mod)
	_is_dirty = true
	on_value_changed.emit(get_value())

func calculate_final_value() -> float:
	var final_val = _base_value
	var sum_percent_add = 0.0
	
	for mod in _modifiers:
		if mod.type == StatModifier.Type.FLAT:
			final_val += mod.value
		elif mod.type == StatModifier.Type.PERCENT_ADD:
			sum_percent_add += mod.value
			
	final_val *= (1.0 + sum_percent_add)
	
	for mod in _modifiers:
		if mod.type == StatModifier.Type.PERCENT_MULT:
			final_val *= mod.value
			
	return round(final_val) # Standardize to whole numbers for classic RPG stats
