class_name RangeEditWindow
extends Window

signal range_submitted

const MIN_SIZE: int = 300
const WINDOW_TOOLBAR_OVERHEAD: int = 23

@onready var min_x = $VSplitContainer/GridContainer/MinX
@onready var min_y = $VSplitContainer/GridContainer/MinY
@onready var max_x = $VSplitContainer/GridContainer/MaxX
@onready var max_y = $VSplitContainer/GridContainer/MaxY

@onready var match_window: CheckBox = $VSplitContainer/GridContainer/MatchWindow

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _process(delta):
	if visible:
		_refresh_size_ui()

func _refresh_size_ui():
	if !match_window.button_pressed:
		return
	min_x.value = position.x
	min_y.value = position.y - _get_min_y_modifier()
	max_x.value = position.x + size.x
	max_y.value = position.y + size.y

func _get_min_y_modifier() -> int:
	if is_fullscreen():
		return 0
	else:
		return WINDOW_TOOLBAR_OVERHEAD

func _on_full_screen_pressed():
	if is_fullscreen():
		_set_windowed()
	else:
		_set_fullscreen()

func is_fullscreen() -> bool:
	return mode == Window.MODE_EXCLUSIVE_FULLSCREEN || mode == Window.MODE_FULLSCREEN

func _set_windowed():
	if is_fullscreen():
		mode = Window.MODE_WINDOWED

func _set_fullscreen():
	mode = Window.MODE_EXCLUSIVE_FULLSCREEN
	#Use Exclusive to prevent 1 pixel size margin
	#Cannot be popup window, as that breaks the full screen transition

func _should_update_fields() -> bool:
	return !is_fullscreen() && match_window.button_pressed

func _on_min_x_value_changed(value):
	if !_should_update_fields():
		return
	var diff = position.x - min_x.value
	position.x -= diff
	size.x += diff


func _on_max_x_value_changed(value):
	if !_should_update_fields():
		return
	var diff = position.x + size.x - max_x.value
	size.x -= diff


func _on_min_y_value_changed(value):
	if !_should_update_fields():
		return
	var diff = position.y - min_y.value - _get_min_y_modifier()
	position.y -= diff
	size.y += diff


func _on_max_y_value_changed(value):
	if !_should_update_fields():
		return
	var diff = position.y + size.y - max_y.value
	size.y -= diff

func _on_submit_range_pressed():
	hide()
	range_submitted.emit()

func _on_close_requested():
	_on_cancel_pressed()

func _on_cancel_pressed():
	hide()
