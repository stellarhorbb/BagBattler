extends Control

@onready var label_title:      Label          = $ContentVBox/LabelTitle
@onready var label_desc:       Label          = $ContentVBox/LabelDesc
@onready var token_piles_row:  HBoxContainer  = $ContentVBox/ContentRow/BagPanel/BagVBox/TokenPilesRow
@onready var label_atk_value:  Label          = $ContentVBox/ContentRow/StatsColumn/StatRow/BaseATKPanel/ATKVBox/ATKValueRow/LabelATKValue
@onready var label_def_value:  Label          = $ContentVBox/ContentRow/StatsColumn/StatRow/BaseDEFPanel/DEFVBox/DEFValueRow/LabelDEFValue
@onready var label_slots_value: Label         = $ContentVBox/ContentRow/StatsColumn/SlotsPanel/SlotsVBox/LabelSlotsValue
@onready var button_start:     Button         = $ContentVBox/ButtonStart
@onready var button_prev:      Button         = $ButtonPrev
@onready var button_next:      Button         = $ButtonNext

var _font = preload("res://font/LondrinaSolid-Black.ttf")
var _token_card = preload("res://token_card.tscn")

# Each entry: { resource: path_or_null, locked: bool }
# Locked entries use name/desc from dict directly.
const CLASSES = [
	{ "resource": "res://resources/jobs/knight.tres", "locked": false },
	{ "resource": null, "name": "THE DIVER", "desc": "To be announced.", "locked": true },
]

var _index := 0

func _ready() -> void:
	RunHUD.visible = false
	_refresh()

func _on_prev_pressed() -> void:
	_index = (_index - 1 + CLASSES.size()) % CLASSES.size()
	_refresh()

func _on_next_pressed() -> void:
	_index = (_index + 1) % CLASSES.size()
	_refresh()

func _on_start_pressed() -> void:
	var entry = CLASSES[_index]
	if entry["locked"]:
		return
	GameManager.selected_job = load(entry["resource"])
	get_tree().change_scene_to_file("res://battle_scene.tscn")

func _refresh() -> void:
	var entry = CLASSES[_index]
	if entry["locked"]:
		_show_locked(entry)
	else:
		_show_job(load(entry["resource"]))
	button_prev.visible = _index > 0
	button_next.visible = _index < CLASSES.size() - 1

func _show_job(job: JobResource) -> void:
	label_title.text = "THE %s" % job.job_name.to_upper()
	label_desc.text = job.description
	label_atk_value.text = "%d" % job.base_damage
	label_def_value.text = "%d" % job.base_defense
	label_slots_value.text = "%d" % job.slot_count
	button_start.disabled = false
	_build_token_piles(job.starting_bag)

func _show_locked(entry: Dictionary) -> void:
	label_title.text = entry["name"]
	label_desc.text = entry["desc"]
	label_atk_value.text = "?"
	label_def_value.text = "?"
	label_slots_value.text = "?"
	button_start.disabled = true
	_clear_token_piles()
	_build_lock_placeholder()

func _build_token_piles(bag: Array) -> void:
	_clear_token_piles()
	for entry in bag:
		token_piles_row.add_child(_make_pile(entry.token, entry.count))

func _clear_token_piles() -> void:
	for child in token_piles_row.get_children():
		child.queue_free()

func _make_pile(token: TokenResource, count: int) -> VBoxContainer:
	var col = VBoxContainer.new()
	col.add_theme_constant_override("separation", 4)

	var lbl_name = Label.new()
	lbl_name.text = token.token_name.to_upper()
	lbl_name.add_theme_font_override("font", _font)
	lbl_name.add_theme_font_size_override("font_size", 18)
	lbl_name.add_theme_color_override("font_color", Color.WHITE)
	lbl_name.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl_name)

	var lbl_count = Label.new()
	lbl_count.text = "x%d" % count
	lbl_count.add_theme_font_override("font", _font)
	lbl_count.add_theme_font_size_override("font_size", 18)
	lbl_count.add_theme_color_override("font_color", Color(1, 1, 1, 0.7))
	lbl_count.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	col.add_child(lbl_count)

	# Stack cards using negative separation — background cards first, front card last
	var pile = VBoxContainer.new()
	pile.add_theme_constant_override("separation", -74)
	pile.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	col.add_child(pile)

	for i in count:
		var card = _token_card.instantiate()
		pile.add_child(card)
		card.call_deferred("setup", token)
		# Only the front card (last added) keeps hover; others ignore mouse
		if i < count - 1:
			card.mouse_filter = Control.MOUSE_FILTER_IGNORE

	return col

func _build_lock_placeholder() -> void:
	var lbl = Label.new()
	lbl.text = "🔒"
	lbl.add_theme_font_size_override("font_size", 72)
	lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	lbl.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	token_piles_row.add_child(lbl)
