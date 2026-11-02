extends Node2D
# Menggambar blok level memakai tekstur batu.

var size := Vector2(32, 32)
var kind := ""
var tex_top: Texture2D
var tex_fill: Texture2D
const TS := 64   # 1 piksel gambar = 2 piksel layar (sama dengan sprite)

func _ready() -> void:
	match kind:
		"wall":
			tex_top = load("res://art_tile_wall.png")
			tex_fill = tex_top
		"fragile":
			tex_top = load("res://art_tile_fragile.png")
			tex_fill = tex_top
		_:
			tex_top = load("res://art_tile_top.png")
			tex_fill = load("res://art_tile_fill.png")
	queue_redraw()

func _draw() -> void:
	var w := int(size.x)
	var h := int(size.y)
	var y := 0
	while y < h:
		var th := mini(TS, h - y)
		var tex: Texture2D = tex_top if y == 0 else tex_fill
		var x := 0
		while x < w:
			var tw := mini(TS, w - x)
			draw_texture_rect_region(tex, Rect2(x, y, tw, th), Rect2(0, 0, tw / 2.0, th / 2.0))
			x += TS
		y += TS
