extends CanvasLayer
## Main HUD displaying credits, phase, timer, and mech health

@onready var credits_label: Label = %CreditsLabel
@onready var phase_label: Label = %PhaseLabel
@onready var timer_label: Label = %TimerLabel
@onready var wave_label: Label = %WaveLabel
@onready var health_bar: ProgressBar = %HealthBar


func _ready() -> void:
	# Validate UI nodes exist
	assert(credits_label != null, "CreditsLabel not found in HUD")
	assert(phase_label != null, "PhaseLabel not found in HUD")
	assert(timer_label != null, "TimerLabel not found in HUD")
	assert(wave_label != null, "WaveLabel not found in HUD")
	assert(health_bar != null, "HealthBar not found in HUD")
	
	# Connect to TimeManager signals
	TimeManager.day_started.connect(_on_day_started)
	TimeManager.night_started.connect(_on_night_started)
	TimeManager.phase_time_remaining.connect(_on_phase_time_remaining)

	# TODO: Connect to EconomyManager when it exists (Step 5)
	# EconomyManager.credits_changed.connect(_on_credits_changed)

	# Initialize display
	_update_credits_display(100)  # Starting credits
	_update_health_display(100.0, 100.0)
	# Connect to TimeManager signals
	TimeManager.day_started.connect(_on_day_started)
	TimeManager.night_started.connect(_on_night_started)
	TimeManager.phase_time_remaining.connect(_on_phase_time_remaining)

	# TODO: Connect to EconomyManager when it exists (Step 5)
	# EconomyManager.credits_changed.connect(_on_credits_changed)

	# Initialize display
	_update_credits_display(100)  # Starting credits
	_update_health_display(100.0, 100.0)


func _on_day_started(day_number: int) -> void:
	phase_label.text = "DAY %d" % day_number
	phase_label.add_theme_color_override("font_color", Color.YELLOW)
	wave_label.visible = false


func _on_night_started(night_number: int) -> void:
	phase_label.text = "NIGHT %d" % night_number
	phase_label.add_theme_color_override("font_color", Color.CYAN)
	wave_label.visible = true
	wave_label.text = "Wave: %d" % night_number


func _on_phase_time_remaining(seconds_left: float) -> void:
	timer_label.text = TimeManager.format_time(seconds_left)

	# Flash timer when low (last 10 seconds)
	if seconds_left <= 10.0:
		var flash: bool = int(seconds_left * 2) % 2 == 0
		timer_label.add_theme_color_override("font_color", Color.RED if flash else Color.WHITE)
	else:
		timer_label.add_theme_color_override("font_color", Color.WHITE)


func _update_credits_display(amount: int) -> void:
	credits_label.text = "Credits: %d" % amount


func _update_health_display(current_hp: float, max_hp: float) -> void:
	health_bar.max_value = max_hp
	health_bar.value = current_hp

	# Color-code health bar
	var health_percent: float = current_hp / max_hp
	if health_percent > 0.6:
		health_bar.add_theme_color_override("fill", Color.GREEN)
	elif health_percent > 0.3:
		health_bar.add_theme_color_override("fill", Color.YELLOW)
	else:
		health_bar.add_theme_color_override("fill", Color.RED)


## Called by mech when health changes
func update_mech_health(current_hp: float, max_hp: float) -> void:
	_update_health_display(current_hp, max_hp)


## Called by economy manager when credits change (Step 5)
func update_credits(amount: int) -> void:
	_update_credits_display(amount)
