extends CanvasLayer
## Main HUD displaying credits, phase, timer, mech health, and crop info

@onready var credits_label: Label = %CreditsLabel
@onready var phase_label: Label = %PhaseLabel
@onready var timer_label: Label = %TimerLabel
@onready var wave_label: Label = %WaveLabel
@onready var health_bar: ProgressBar = %HealthBar

#region Crop System UI
var _placement_mode_label: Label
var _crop_planted_feedback_label: Label
const PLACEMENT_MODE_DISPLAY_DURATION: float = 3.0
#endregion


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

	# Connect to EconomyManager for credit updates
	if EconomyManager:
		EconomyManager.credits_changed.connect(_on_credits_changed)
		print("[HUD] Connected to EconomyManager.credits_changed signal")
		# Initialize with current credits
		_update_credits_display(EconomyManager.get_credits())
	else:
		push_error("[HUD] EconomyManager autoload not found!")

	# Setup crop system UI
	_setup_crop_ui()

	# Initialize display
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


func _on_credits_changed(new_amount: int) -> void:
	"""Handle credits changed signal from EconomyManager"""
	_update_credits_display(new_amount)


func _setup_crop_ui() -> void:
	"""Setup UI elements for crop system feedback"""
	# Create placement mode indicator
	_placement_mode_label = Label.new()
	_placement_mode_label.text = ""
	_placement_mode_label.add_theme_font_size_override("font_size", 16)
	_placement_mode_label.add_theme_color_override("font_color", Color.YELLOW)
	_placement_mode_label.visible = false
	add_child(_placement_mode_label)

	# Create crop planted feedback label
	_crop_planted_feedback_label = Label.new()
	_crop_planted_feedback_label.text = ""
	_crop_planted_feedback_label.add_theme_font_size_override("font_size", 18)
	_crop_planted_feedback_label.add_theme_color_override("font_color", Color.GREEN)
	_crop_planted_feedback_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_crop_planted_feedback_label.visible = false
	add_child(_crop_planted_feedback_label)


func on_crop_planted(crop_type: CropDatabase.CropType) -> void:
	"""Display feedback when crop is successfully planted"""
	if not _crop_planted_feedback_label:
		return

	var crop_data := CropDatabase.get_crop(crop_type)
	if not crop_data:
		return

	# Show planted feedback
	_crop_planted_feedback_label.text = "✓ %s Planted!" % crop_data.name
	_crop_planted_feedback_label.add_theme_color_override("font_color", Color.GREEN)
	_crop_planted_feedback_label.visible = true
	_crop_planted_feedback_label.modulate = Color(1, 1, 1, 1.0)

	# Fade out after 2 seconds
	var tween = create_tween()
	tween.set_trans(Tween.TRANS_LINEAR)
	tween.set_ease(Tween.EASE_IN)
	tween.tween_property(_crop_planted_feedback_label, "modulate:a", 0.3, 1.5)
	tween.tween_callback(func(): _crop_planted_feedback_label.visible = false)
	tween.tween_property(_crop_planted_feedback_label, "modulate:a", 1.0, 0.0)


func on_placement_mode_changed(active: bool, crop_type: CropDatabase.CropType) -> void:
	"""Update HUD when crop placement mode changes"""
	if not _placement_mode_label:
		return

	if active:
		var crop_data := CropDatabase.get_crop(crop_type)
		if crop_data:
			_placement_mode_label.text = "[PLANTING MODE] %s - %d credits" % [crop_data.name, crop_data.cost]
			_placement_mode_label.add_theme_color_override("font_color", Color.YELLOW)
			_placement_mode_label.visible = true
	else:
		_placement_mode_label.text = ""
		_placement_mode_label.visible = false


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
