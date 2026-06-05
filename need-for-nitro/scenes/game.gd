extends Node3D

@onready var car = $Car
@onready var hud = $HUD

func _ready() -> void:
	print("Car: ", car)
	print("HUD: ", hud)
	car.speed_changed.connect(hud.update_speed)
	car.turbo_changed.connect(hud.update_turbo)
	car.drift_started.connect(hud.show_drift)
	car.drift_ended.connect(hud.hide_drift)
