extends VehicleBody3D

# ── CONFIGURACIÓN DEL VEHÍCULO ──────────────────────────────
@export var max_speed: float = 90.0        # m/s (~324 km/h)
@export var engine_force_value: float = 5000.0
@export var brake_force: float = 80.0
@export var max_steer_angle: float = 0.45  # radianes

# ── TURBO ────────────────────────────────────────────────────
@export var turbo_max: float = 100.0
@export var turbo_boost_force: float = 15000.0
@export var turbo_duration: float = 2.0    # segundos que dura el boost

var turbo_current: float = 0.0
var turbo_active: bool = false
var turbo_timer: float = 0.0

# ── DRIFT ────────────────────────────────────────────────────
@export var drift_friction: float = 0.4    # fricción lateral al driftar
@export var turbo_fill_drift: float = 18.0 # turbo por segundo driftando
@export var turbo_fill_oncoming: float = 35.0 # turbo por segundo en sentido contrario

var is_drifting: bool = false
var normal_friction: float = 1.0

# ── ESTADO INTERNO ───────────────────────────────────────────
var current_speed: float = 0.0
var speed_kmh: float = 0.0

# ── SEÑALES (para el HUD) ─────────────────────────────────────
signal turbo_changed(value: float, max_value: float)
signal speed_changed(kmh: float)
signal drift_started
signal drift_ended

func _ready() -> void:
	# Configuración inicial de físicas del VehicleBody3D
	mass = 1200.0
	turbo_current = 100.0
	
func _physics_process(delta: float) -> void:
	_handle_input(delta)
	_handle_drift(delta)
	_handle_turbo(delta)
	_update_speed()
	_handle_sounds()

# ────────────────────────────────────────────────────────────
func _handle_input(delta: float) -> void:
	var speed = linear_velocity.length()

	# W = acelerar
	if Input.is_key_pressed(KEY_W):
		if speed < max_speed:
			engine_force = engine_force_value
		else:
			engine_force = 0.0

		brake = 0.0

	# S = reversa
	elif Input.is_key_pressed(KEY_S):
		engine_force = -engine_force_value * 0.5
		brake = 0.0

	else:
		engine_force = 0.0
		brake = 10.0

	# Espacio = freno
	if Input.is_key_pressed(KEY_SPACE):
		brake = brake_force
		engine_force = 0.0

	# A y D = dirección
	var steer_input := 0.0

	if Input.is_key_pressed(KEY_A):
		steer_input = 1.0
	elif Input.is_key_pressed(KEY_D):
		steer_input = -1.0

	var speed_factor = clamp(speed / max_speed, 0.0, 1.0)
	var steer_limit = lerp(max_steer_angle, max_steer_angle * 0.4, speed_factor)

	steering = move_toward(
		steering,
		steer_input * steer_limit,
		delta * 3.0
	)

	# Shift = turbo
	if Input.is_key_pressed(KEY_SHIFT) and turbo_current >= 20.0 and not turbo_active:
		_activate_turbo()

# ────────────────────────────────────────────────────────────
func _handle_drift(delta: float) -> void:
	var drifting = Input.is_key_pressed(KEY_CTRL) and \
				   abs(steering) > 0.1 and \
				   linear_velocity.length() > 8.0
	
	if drifting and not is_drifting:
		is_drifting = true
		_set_drift_friction(drift_friction)
		emit_signal("drift_started")
	elif not drifting and is_drifting:
		is_drifting = false
		_set_drift_friction(normal_friction)
		emit_signal("drift_ended")
	
	# Llenar turbo al driftear
	if is_drifting:
		turbo_current = min(turbo_current + turbo_fill_drift * delta, turbo_max)
		emit_signal("turbo_changed", turbo_current, turbo_max)
	
	# Llenar turbo en sentido contrario (velocidad en Z negativa del mundo)
	# Detectamos si vamos "contra" la dirección principal de la pista
	var forward = -global_transform.basis.z
	if forward.z > 0.3 and linear_velocity.length() > 5.0:
		turbo_current = min(turbo_current + turbo_fill_oncoming * delta, turbo_max)
		emit_signal("turbo_changed", turbo_current, turbo_max)

func _set_drift_friction(value: float) -> void:
	# Cambia el grip lateral de las ruedas traseras
	for wheel_name in ["VehicleWheel3D RL", "VehicleWheel3D RR"]:
		var wheel = get_node_or_null(wheel_name)
		if wheel:
			wheel.wheel_friction_slip = value

# ────────────────────────────────────────────────────────────
func _handle_turbo(delta: float) -> void:
	if turbo_active:
		turbo_timer -= delta
		engine_force = engine_force_value + turbo_boost_force
		if turbo_timer <= 0.0:
			turbo_active = false
			turbo_timer = 0.0
	
	# Consumir turbo mientras está activo
	if turbo_active:
		turbo_current = max(turbo_current - (turbo_max / turbo_duration) * delta, 0.0)
		emit_signal("turbo_changed", turbo_current, turbo_max)
		if turbo_current <= 0.0:
			turbo_active = false

func _activate_turbo() -> void:
	turbo_active = true
	turbo_timer = turbo_duration

# ────────────────────────────────────────────────────────────
func _update_speed() -> void:
	speed_kmh = linear_velocity.length() * 3.6
	print("Velocidad: ", round(speed_kmh), " km/h")
	emit_signal("speed_changed", speed_kmh)

# Getter para el HUD
func get_turbo_percent() -> float:
	return turbo_current / turbo_max

# ── SONIDOS ──────────────────────────────────────────────────
@onready var audio_motor = $AudioMotor
@onready var audio_drift = $AudioDrift
@onready var audio_turbo = $AudioTurbo
func _handle_sounds() -> void:
	# Motor — cambia el pitch según la velocidad
	var speed_ratio = clamp(linear_velocity.length() / max_speed, 0.0, 1.0)
	audio_motor.pitch_scale = lerp(0.8, 2.0, speed_ratio)
	
	# Derrape — suena solo al driftar
	if is_drifting and not audio_drift.playing:
		audio_drift.play()
	elif not is_drifting and audio_drift.playing:
		audio_drift.stop()
	
	# Turbo — suena una vez al activarse
	if turbo_active and not audio_turbo.playing:
		audio_turbo.play()
