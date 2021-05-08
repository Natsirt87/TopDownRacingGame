extends Node2D


export(Curve) var pitch_curve
export(Curve) var volume_curve
export var transition_time = 0.05

var under_load
var rev_value = 0


var _engine_load
var _engine_idle

var _tween_load_in
var _tween_load_out
var _tween_idle_in
var _tween_idle_out

var _load_vol = 0.001
var _idle_vol = 1

# Called when the node enters the scene tree for the first time.
func _ready():
	_engine_load = $EngineLoad
	_engine_idle = $EngineIdle


func _process(delta):
	_engine_load.pitch_scale = pitch_curve.interpolate(rev_value)
	_engine_idle.pitch_scale = pitch_curve.interpolate(rev_value)


func _physics_process(delta):
	var lerp_speed = 1
	
	if under_load:
		_load_vol = lerp(_load_vol, 1 * volume_curve.interpolate(rev_value), lerp_speed)
		_idle_vol = lerp(_idle_vol, 0.05 * volume_curve.interpolate(rev_value), lerp_speed)
	else:
		_load_vol = lerp(_load_vol, 0.05 * volume_curve.interpolate(rev_value), lerp_speed)
		_idle_vol = lerp(_idle_vol, 1 * volume_curve.interpolate(rev_value), lerp_speed)
	
	_engine_load.volume_db = linear2db(_load_vol)
	_engine_idle.volume_db = linear2db(_idle_vol)
	

func set_engine_values(eng_load, rev):
	under_load = eng_load
	rev_value = rev


