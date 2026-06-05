extends CanvasLayer

@onready var speed_label: Label = $Control/SpeedPanel/SpeedLabel
@onready var turbo_bar: ProgressBar = $Control/TurboPanel/TurboBar
@onready var drift_label: Label = $Control/DriftLabel

var drift_timer: float = 0.0

func _process(delta: float) -> void:
	if drift_label.visible:
		drift_timer -= delta
		if drift_timer <= 0.0:
			drift_label.visible = false

func update_speed(kmh: float) -> void:
	speed_label.text = str(int(kmh)) + " km/h"

func update_turbo(value: float, max_value: float) -> void:
	turbo_bar.value = (value / max_value) * 100.0

func show_drift() -> void:
	drift_label.visible = true
	drift_timer = 0.5

func hide_drift() -> void:
	pass
