class_name CombatSystemDemo
extends Node2D
## Demo for testing the weapon system and combat mechanics
## Shows bullet firing, projectile pooling, enemy damage, and wave progression

#region Variables
var mech: Node2D = null
var weapon_system: WeaponSystem = null
var hex_grid: Node = null
var bullets_fired_count: int = 0
var enemies_killed_count: int = 0
var total_damage_dealt: float = 0.0
var demo_state: String = "waiting_for_input"

#endregion

#region Nodes
@onready var time_label: Label = $HUD/TimePanel/VBoxContainer/TimeLabel
@onready var phase_label: Label = $HUD/TimePanel/VBoxContainer/PhaseLabel
@onready var wave_label: Label = $HUD/WavePanel/VBoxContainer/WaveLabel
@onready var enemy_label: Label = $HUD/WavePanel/VBoxContainer/EnemyLabel
@onready var breakdown_label: Label = $HUD/WavePanel/VBoxContainer/BreakdownLabel
@onready var mech_health_label: Label = $HUD/MechPanel/VBoxContainer/HealthLabel
@onready var mech_position_label: Label = $HUD/MechPanel/VBoxContainer/PositionLabel
@onready var weapon_label: Label = $HUD/WeaponPanel/VBoxContainer/WeaponLabel
@onready var fire_rate_label: Label = $HUD/WeaponPanel/VBoxContainer/FireRateLabel
@onready var damage_label: Label = $HUD/WeaponPanel/VBoxContainer/DamageLabel
@onready var cooldown_label: Label = $HUD/WeaponPanel/VBoxContainer/CooldownLabel
@onready var instructions_label: RichTextLabel = $HUD/InstructionsPanel/VBoxContainer/InstructionsLabel
@onready var day_night_tint: CanvasModulate = $DayNightTint

#endregion

#region Initialization
func _ready() -> void:
	mech = get_tree().get_first_node_in_group("player_mech")
	hex_grid = $HexGrid

	# Wait for all nodes to initialize their _ready() methods
	await get_tree().process_frame

	if mech and mech.has_node("WeaponSystem"):
		weapon_system = mech.get_node("WeaponSystem")

	_setup_instructions()
	_connect_signals()
	_update_ui()

	print("CombatSystemDemo: Initialized")
	if weapon_system:
		print("CombatSystemDemo: WeaponSystem found with %d bullet pool size" % weapon_system.pool_size)
	else:
		print("CombatSystemDemo: WARNING - WeaponSystem not found!")


func _setup_instructions() -> void:
	"""Display instructions in the demo"""
	var instructions = """[b]COMBAT SYSTEM DEMO[/b]

[color=ffff99]OBJECTIVE:[/color]
Test weapon firing, projectile pooling, and damage system

[color=ffff99]HOW TO USE:[/color]
• WASD: Move mech
• Mouse: Aim (mech rotates toward cursor)
• Left-Click: Fire weapon (0.3s cooldown)
• Watch bullets damage enemies

[color=ffff99]WHAT TO TEST:[/color]
1. Fire rate cooldown (0.3s between shots)
2. Projectile pooling (bullets reuse from pool)
3. Enemy collision detection
4. Damage application (10 per bullet)
5. Wave progression (enemies get stronger)
6. Particle effects on hit
7. Bullet lifetime (3 seconds)

[color=ffff99]DEBUG INFO:[/color]
Bullets Fired: 0
Enemies Killed: 0
Total Damage: 0.0

[color=ffff99]CONTROLS:[/color]
• N: Skip to night time
• E: Spawn extra enemy
• D: Increase weapon damage 50%
• ESC: Return to main menu
"""
	self.instructions_label.text = instructions


func _connect_signals() -> void:
	"""Connect to weapon and wave systems"""
	if TimeManager:
		TimeManager.day_started.connect(_on_day_started)
		TimeManager.night_started.connect(_on_night_started)
		TimeManager.phase_time_remaining.connect(_on_phase_time_remaining)

	if WaveManager:
		WaveManager.wave_started.connect(_on_wave_started)
		WaveManager.wave_completed.connect(_on_wave_completed)

	if weapon_system:
		if weapon_system.bullet_fired.is_connected(_on_bullet_fired):
			print("CombatSystemDemo: Bullet fired signal already connected")
		else:
			weapon_system.bullet_fired.connect(_on_bullet_fired)
			print("CombatSystemDemo: Connected to bullet_fired signal")
	else:
		print("CombatSystemDemo: WARNING - Cannot connect to bullet_fired, weapon_system is null")

	# Monitor mech health if available
	if mech and mech.has_signal("health_changed"):
		mech.health_changed.connect(_on_mech_health_changed)

#endregion

#region Signal Handlers - Time
func _on_day_started(day_number: int) -> void:
	"""Called when day starts"""
	self.day_night_tint.color = GameConfig.DAY_TINT
	self.demo_state = "day_phase"
	print("CombatSystemDemo: Day %d started" % day_number)


func _on_night_started(night_number: int) -> void:
	"""Called when night starts"""
	self.day_night_tint.color = GameConfig.NIGHT_TINT
	self.demo_state = "combat_phase"
	print("CombatSystemDemo: Night %d started - enemies spawning!" % night_number)


func _on_phase_time_remaining(seconds_left: float) -> void:
	"""Update time display"""
	var minutes: int = int(seconds_left) / 60
	var secs: int = int(seconds_left) % 60
	self.time_label.text = "⏱️ Time: %02d:%02d" % [minutes, secs]

#endregion

#region Signal Handlers - Combat
func _on_bullet_fired(bullet: Bullet, position: Vector2, direction: Vector2) -> void:
	"""Called when a bullet is fired"""
	self.bullets_fired_count += 1

	# Connect to bullet signals to track damage
	if not bullet.hit_enemy.is_connected(_on_bullet_hit_enemy):
		bullet.hit_enemy.connect(_on_bullet_hit_enemy)

	print("CombatSystemDemo: Bullet #%d fired from %.0f towards %.0f°" % [
		self.bullets_fired_count,
		position.length(),
		rad_to_deg(direction.angle())
	])


func _on_bullet_hit_enemy(enemy: BaseEnemy, damage: float) -> void:
	"""Called when a bullet hits an enemy"""
	self.total_damage_dealt += damage
	print("CombatSystemDemo: Hit! Dealt %.0f damage to enemy" % damage)


func _on_wave_started(wave_number: int) -> void:
	"""Called when a wave starts"""
	print("CombatSystemDemo: Wave %d started - get ready to fight!" % wave_number)


func _on_wave_completed(wave_number: int) -> void:
	"""Called when all enemies in a wave are defeated"""
	print("CombatSystemDemo: Wave %d complete! Total damage dealt: %.0f" % [
		wave_number,
		self.total_damage_dealt
	])


func _on_mech_health_changed(current_hp: float, max_hp: float) -> void:
	"""Update mech health display"""
	self.mech_health_label.text = "Health: %.0f / %.0f" % [current_hp, max_hp]

#endregion

#region Input & Controls
func _input(event: InputEvent) -> void:
	"""Handle keyboard input for demo shortcuts"""
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_N:
				# Skip to night time
				if TimeManager and not TimeManager.is_night():
					TimeManager.time_remaining = 0.0
					get_tree().root.set_input_as_handled()

			KEY_E:
				# Spawn extra enemy for testing
				_spawn_test_enemy()
				get_tree().root.set_input_as_handled()

			KEY_D:
				# Increase weapon damage
				if weapon_system:
					weapon_system.upgrade_damage(5.0)
					print("CombatSystemDemo: Weapon damage increased to %.0f" % weapon_system.get_current_damage())
				get_tree().root.set_input_as_handled()

#endregion

#region Test Utilities
func _spawn_test_enemy() -> void:
	"""Spawn a single test enemy for combat testing"""
	if not WaveManager:
		return

	# Spawn at a random position around the mech
	var spawn_angle: float = randf() * TAU
	var spawn_distance: float = 300.0
	var spawn_pos: Vector2 = mech.global_position + Vector2.from_angle(spawn_angle) * spawn_distance

	# Use WaveManager's enemy scene
	var enemy_scene = WaveManager.enemy_rusher_scene
	if randf() > 0.7:
		enemy_scene = WaveManager.enemy_shooter_scene

	var enemy = enemy_scene.instantiate() as Node2D
	enemy.global_position = spawn_pos
	get_parent().add_child(enemy)

	print("CombatSystemDemo: Test enemy spawned at %.0f, %.0f" % [spawn_pos.x, spawn_pos.y])

#endregion

#region UI Updates
func _process(_delta: float) -> void:
	"""Update UI every frame"""
	_update_ui()


func _update_ui() -> void:
	"""Update all UI elements"""
	_update_phase_info()
	_update_wave_info()
	_update_mech_info()
	_update_weapon_info()
	_update_debug_info()


func _update_phase_info() -> void:
	"""Update time and phase display"""
	if not TimeManager:
		return

	var phase_name: String = "DAY" if TimeManager.is_day() else "NIGHT"
	var day_num: int = TimeManager.current_day if TimeManager.is_day() else TimeManager.current_night
	self.phase_label.text = "Phase: %s %d" % [phase_name, day_num]


func _update_wave_info() -> void:
	"""Update wave and enemy display"""
	if not WaveManager:
		return

	if WaveManager.is_wave_active:
		var wave_num: int = WaveManager.current_wave
		var enemy_count: int = WaveManager.get_active_enemy_count()
		var rusher_count: int = 0
		var shooter_count: int = 0

		for enemy in WaveManager.enemies_in_wave:
			if enemy.enemy_type == EnemyDatabase.EnemyType.RUSHER:
				rusher_count += 1
			else:
				shooter_count += 1

		self.wave_label.text = "🌊 WAVE: %d" % wave_num
		self.enemy_label.text = "Enemies: %d" % enemy_count
		self.breakdown_label.text = "Rushers: %d | Shooters: %d" % [rusher_count, shooter_count]
	else:
		self.wave_label.text = "🌊 WAVE: NONE"
		self.enemy_label.text = "Enemies: 0"
		self.breakdown_label.text = "Rushers: 0 | Shooters: 0"


func _update_mech_info() -> void:
	"""Update mech information"""
	if not mech:
		return

	self.mech_position_label.text = "Position: (%.0f, %.0f)" % [mech.global_position.x, mech.global_position.y]


func _update_weapon_info() -> void:
	"""Update weapon system information"""
	if not weapon_system:
		self.weapon_label.text = "⚠️ Weapon System: NOT FOUND"
		return

	var can_fire: bool = weapon_system.can_fire()
	var cooldown: float = weapon_system.get_cooldown_remaining()
	var fire_rate: float = weapon_system.get_fire_rate()
	var damage: float = weapon_system.get_current_damage()

	self.weapon_label.text = "⚙️ Weapon: %s" % ("READY ✓" if can_fire else "COOLDOWN")
	self.fire_rate_label.text = "Fire Rate: %.1f shots/sec" % fire_rate
	self.damage_label.text = "Damage: %.0f per bullet" % damage
	self.cooldown_label.text = "Cooldown: %.2fs" % cooldown


func _update_debug_info() -> void:
	"""Update debug statistics in instructions panel"""
	var instructions = """[b]COMBAT SYSTEM DEMO[/b]

[color=ffff99]OBJECTIVE:[/color]
Test weapon firing, projectile pooling, and damage system

[color=ffff99]HOW TO USE:[/color]
• WASD: Move mech
• Mouse: Aim (mech rotates toward cursor)
• Left-Click: Fire weapon (0.3s cooldown)
• Watch bullets damage enemies

[color=ffff99]WHAT TO TEST:[/color]
1. Fire rate cooldown (0.3s between shots)
2. Projectile pooling (bullets reuse from pool)
3. Enemy collision detection
4. Damage application (10 per bullet)
5. Wave progression (enemies get stronger)
6. Particle effects on hit
7. Bullet lifetime (3 seconds)

[color=ffff99]DEBUG INFO:[/color]
Bullets Fired: %d
Enemies Killed: %d
Total Damage: %.0f

[color=ffff99]CONTROLS:[/color]
• N: Skip to night time
• E: Spawn extra enemy
• D: Increase weapon damage 50%%
• ESC: Return to main menu
""" % [self.bullets_fired_count, self.enemies_killed_count, self.total_damage_dealt]
	self.instructions_label.text = instructions

#endregion
