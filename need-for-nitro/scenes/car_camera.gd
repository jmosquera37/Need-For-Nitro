extends Camera3D

# ── CONFIGURACIÓN ────────────────────────────────────────────
@export var target: NodePath          # arrastra el nodo Car aquí en el Inspector
@export var follow_speed: float = 5.0 # qué tan rápido sigue al carro
@export var rotate_speed: float = 5.0 # qué tan rápido rota

# Offset = posición relativa al carro (atrás y arriba)
@export var offset_distance: float = 6.0  # distancia hacia atrás
@export var offset_height: float = 2.5    # altura

# FOV dinámico
@export var fov_normal: float = 70.0
@export var fov_max: float = 95.0
@export var max_speed_ref: float = 60.0   # velocidad a la que se alcanza FOV máximo

var target_node: VehicleBody3D

func _ready() -> void:
	target_node = get_node(target)

func _physics_process(delta: float) -> void:
	if not target_node:
		return
	
	_follow_target(delta)
	_update_fov(delta)

func _follow_target(delta: float) -> void:
	# Posición deseada: detrás y arriba del carro
	var back_dir = -target_node.global_transform.basis.z  # dirección trasera del carro
	var desired_pos = target_node.global_position \
					+ back_dir * offset_distance \
					+ Vector3.UP * offset_height
	
	# Mover la cámara suavemente hacia esa posición
	global_position = global_position.lerp(desired_pos, follow_speed * delta)
	
	# Rotar para mirar al carro (un poco por encima)
	var look_target = target_node.global_position + Vector3.UP * 0.5
	var current_transform = global_transform.looking_at(look_target, Vector3.UP)
	global_transform = global_transform.interpolate_with(current_transform, rotate_speed * delta)

func _update_fov(delta: float) -> void:
	var speed = target_node.linear_velocity.length()
	var speed_ratio = clamp(speed / max_speed_ref, 0.0, 1.0)
	var desired_fov = lerp(fov_normal, fov_max, speed_ratio)
	fov = lerp(fov, desired_fov, delta * 3.0)
