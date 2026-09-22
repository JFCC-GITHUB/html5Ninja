# PixelGenerator.gd
class_name PixelGenerator
extends RefCounted

static var NINJA_PALETTE = {
	'B': Color("#1a1a24"),
	'D': Color("#2d2d44"),
	'S': Color("#f1c40f"),
	'F': Color("#ffdbac"),
	'E': Color("#000000"),
	'R': Color("#e74c3c")
}

static var NINJA_IDLE_MATRIX = [
	"......RRRRRR......", ".....RRRRRRRR.....", "....BBBBBBBBBB....", "...BBBBBBBBBBBB...",
	"...BBFFFFFFBBBB...", "...BBFEFFEFEBBB...", "...BBFFFFFFBBBB...", "...SSSSSSSSSSSS...",
	"....BBBBBBBBBB....", "....BDDDDDBBBB....", "...BBDDDDDDBBBB...", "...BBDDDDDDBBBB...",
	"...BDDDDDDDDBBB...", "...BDDDDDDDDBBB...", "...BDDDDDDDDBBB...", "....BDDDDDDDDB....",
	"....BBBB..BBBB....", "....BBBB..BBBB....", "....BBBB..BBBB....", "....BBBB..BBBB....",
	"....BBBB..BBBB....", "...BBBBB..BBBBB...", "...BBBBB..BBBBB..."
]

static var NINJA_RUN_MATRIX = [
	"......RRRRRR......", ".....RRRRRRRR.....", "....BBBBBBBBBB....", "...BBBBBBBBBBBB...",
	"...BBFFFFFFBBBB...", "...BBFEFFEFEBBB...", "...BBFFFFFFBBBB...", "...SSSSSSSSSSSS...",
	"....BBBBBBBBBB....", "....BDDDDDBBBB....", "...BBDDDDDDBBBB...", "...BBDDDDDDBBBB...",
	"...BDDDDDDDDBBB...", "...BDDDDDDDDBBB...", "....BDDDDDDDDB....", ".....BBBBBBBB.....",
	"....BBBB...BBBB...", "...BBBB.....BBBB..", "..BBBB.......BBBB.", "..BBBB.......BBBB.",
	".BBBBB.......BBBBB", ".BBBBB.......BBBBB"
]

static func draw_matrix_to_image(img: Image, matrix: Array, palette: Dictionary, w: int, h: int, flip_x: bool = false):
	img.fill(Color(0, 0, 0, 0))
	var rows = matrix.size()
	var cols = matrix[0].length()
	var pixel_size_x = float(w) / cols
	var pixel_size_y = float(h) / rows

	for r in range(rows):
		var row_str = matrix[r]
		for c in range(row_str.length()):
			var ch = row_str[c]
			if ch != '.' and palette.has(ch):
				var color = palette[ch]
				var start_c = cols - 1 - c if flip_x else c
				var x_start = int(start_c * pixel_size_x)
				var y_start = int(r * pixel_size_y)
				var x_end = int((start_c + 1) * pixel_size_x)
				var y_end = int((r + 1) * pixel_size_y)
				for px in range(x_start, x_end):
					for py in range(y_start, y_end):
						if px >= 0 and px < w and py >= 0 and py < h:
							img.set_pixel(px, py, color)

static func create_ninja_texture(is_run: bool, is_left: bool) -> ImageTexture:
	var w = int(Config.PLAYER["WIDTH"])
	var h = int(Config.PLAYER["HEIGHT"])
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	var matrix = NINJA_RUN_MATRIX if is_run else NINJA_IDLE_MATRIX
	draw_matrix_to_image(img, matrix, NINJA_PALETTE, w, h, is_left)
	return ImageTexture.create_from_image(img)

static func create_shuriken_texture() -> ImageTexture:
	var size = 32
	var img = Image.create(size, size, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var center = Vector2(16, 16)
	var points = [
		Vector2(16, 0), Vector2(20, 12), Vector2(32, 16), Vector2(20, 20),
		Vector2(16, 32), Vector2(12, 20), Vector2(0, 16), Vector2(12, 12)
	]
	# Draw filled polygon manually or rasterize shuriken shape
	for x in range(size):
		for y in range(size):
			var pos = Vector2(x, y)
			if _is_point_in_star(pos):
				if pos.distance_to(center) <= 5.0:
					img.set_pixel(x, y, Color("#111111"))
				else:
					img.set_pixel(x, y, Color("#bdc3c7"))
	return ImageTexture.create_from_image(img)

static func _is_point_in_star(p: Vector2) -> bool:
	var center = Vector2(16, 16)
	var dir = p - center
	var dist = dir.length()
	if dist > 16.0: return false
	var angle = fmod(dir.angle() + PI * 2.0, PI / 2.0)
	var norm_angle = abs(angle - PI / 4.0)
	var max_r = lerp(16.0, 5.0, norm_angle / (PI / 4.0))
	return dist <= max_r

static func create_enemy_texture(color_main: Color, color_sub: Color, w: int, h: int, is_left: bool) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var p_size = max(1, int(w / 16.0))

	# Body background
	_fill_rect(img, p_size * 2, p_size * 2, w - p_size * 4, h - p_size * 4, color_main)
	# Headband / Eye mask
	_fill_rect(img, p_size * 3, p_size * 3, w - p_size * 6, p_size * 6, Color("#111111"))
	# Eyes
	_fill_rect(img, p_size * 4, p_size * 5, p_size * 2, p_size * 2, Color("#ffffff"))
	_fill_rect(img, w - p_size * 6, p_size * 5, p_size * 2, p_size * 2, Color("#ffffff"))
	_fill_rect(img, p_size * 5, p_size * 5, p_size, p_size * 2, Color("#e74c3c"))
	_fill_rect(img, w - p_size * 5, p_size * 5, p_size, p_size * 2, Color("#e74c3c"))
	# Hat / Sub color
	_fill_rect(img, p_size * 2, p_size * 2, w - p_size * 4, p_size * 2, color_sub)
	# Belt
	_fill_rect(img, p_size * 2, int(h / 2.0), w - p_size * 4, p_size * 3, Color("#2c3e50"))
	# Legs
	_fill_rect(img, p_size * 3, h - p_size * 5, p_size * 4, p_size * 5, color_main)
	_fill_rect(img, w - p_size * 7, h - p_size * 5, p_size * 4, p_size * 5, color_main)

	if is_left:
		img.flip_x()

	return ImageTexture.create_from_image(img)

static func create_tower_texture(w: int, h: int) -> ImageTexture:
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_rect(img, 0, 0, w, h, Color("#2c3e50"))
	_fill_rect(img, 4, 4, w - 8, h - 8, Color("#34495e"))
	# Roof / Tower top decoration
	_fill_rect(img, 0, 0, w, 16, Color("#e74c3c"))
	_fill_rect(img, 8, 20, w - 16, 20, Color("#f39c12"))
	_fill_rect(img, 12, 60, w - 24, 30, Color("#16a085"))
	return ImageTexture.create_from_image(img)

static func create_arrow_texture() -> ImageTexture:
	var w = 24
	var h = 8
	var img = Image.create(w, h, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	_fill_rect(img, 0, 3, 18, 2, Color("#7f8c8d"))
	_fill_rect(img, 18, 1, 6, 6, Color("#f1c40f"))
	_fill_rect(img, 0, 1, 4, 6, Color("#e74c3c"))
	return ImageTexture.create_from_image(img)

static func _fill_rect(img: Image, x: int, y: int, w: int, h: int, color: Color):
	var max_x = min(img.get_width(), x + w)
	var max_y = min(img.get_height(), y + h)
	for px in range(max(0, x), max_x):
		for py in range(max(0, y), max_y):
			img.set_pixel(px, py, color)
