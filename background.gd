extends CanvasLayer
# Latar berlapis (parallax): langit + bulan merah, struktur lab, kanopi sakura.

const LAYERS := [
	["res://art_bg_far.png", 0.04],
	["res://art_bg_mid.png", 0.18],
	["res://art_bg_near.png", 0.45],
]
var canvas: Node2D
var texs: Array = []

func _ready() -> void:
	layer = -10
	for l in LAYERS:
		texs.append(load(l[0]))
	canvas = Node2D.new()
	canvas.draw.connect(_draw_bg)
	add_child(canvas)

func _process(_delta: float) -> void:
	canvas.queue_redraw()

func _draw_bg() -> void:
	var vp := get_viewport().get_visible_rect().size
	var cam := get_viewport().get_camera_2d()
	var cx := 0.0
	if cam:
		cx = cam.get_screen_center_position().x
	var hgt := vp.y
	var wd := 1600.0 * (hgt / 720.0)
	for i in texs.size():
		var f: float = LAYERS[i][1]
		var off := fposmod(-cx * f, wd)
		var x := off - wd
		while x < vp.x:
			var mod := Color(0.7, 0.64, 0.78, 0.92) if i == 2 else Color.WHITE
			canvas.draw_texture_rect(texs[i], Rect2(x, 0.0, wd, hgt), false, mod)
			x += wd
