# PixelGenerator.gd
class_name PixelGenerator

static func create_ninja_texture(is_running: bool = false, is_left: bool = false) -> ImageTexture:
	var img = Image.create(48, 48, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var base_c = Color("#2c3e50")
	var headband_c = Color("#e74c3c")
	var skin_c = Color("#f39c12")
	var eye_c = Color("#ffffff")

	# Head (x: 12..36, y: 6..24)
	for x in range(12, 36):
		for y in range(6, 24):
			img.set_pixel(x, y, base_c)

	# Headband
	for x in range(12, 36):
		for y in range(10, 15):
			img.set_pixel(x, y, headband_c)

	# Face cutout / eyes
	var eye_start_x = 16 if not is_left else 24
	for x in range(eye_start_x, eye_start_x + 8):
		for y in range(15, 19):
			img.set_pixel(x, y, skin_c)
	img.set_pixel(eye_start_x + 2, 16, eye_c)
	img.set_pixel(eye_start_x + 5, 16, eye_c)

	# Body (x: 10..38, y: 24..42)
	for x in range(10, 38):
		for y in range(24, 42):
			img.set_pixel(x, y, base_c)

	# Belt
	for x in range(10, 38):
		for y in range(32, 35):
			img.set_pixel(x, y, headband_c)

	# Running Legs offset
	if is_running:
		for x in range(6, 18):
			for y in range(38, 48):
				img.set_pixel(x, y, base_c)
		for x in range(30, 42):
			for y in range(38, 48):
				img.set_pixel(x, y, base_c)
	else:
		for x in range(12, 22):
			for y in range(40, 48):
				img.set_pixel(x, y, base_c)
		for x in range(26, 36):
			for y in range(40, 48):
				img.set_pixel(x, y, base_c)

	return ImageTexture.create_from_image(img)

static func create_shuriken_texture() -> ImageTexture:
	var img = Image.create(16, 16, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c = Color("#f1c40f")
	# 4-pointed star
	for i in range(16):
		img.set_pixel(i, 8, c)
		img.set_pixel(8, i, c)
		img.set_pixel(i, i, c)
		img.set_pixel(i, 15 - i, c)
	return ImageTexture.create_from_image(img)

static func create_tower_texture(width: int = 80, height: int = 140) -> ImageTexture:
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	var stone_c = Color("#34495e")
	var roof_c = Color("#c0392b")
	var wood_c = Color("#d35400")

	# Base tower structure
	for x in range(10, width - 10):
		for y in range(30, height):
			img.set_pixel(x, y, stone_c)

	# Pagoda Roof top
	for y in range(0, 30):
		var w_offset = y * 1.3
		for x in range(int(width / 2.0 - w_offset), int(width / 2.0 + w_offset)):
			if x >= 0 and x < width:
				img.set_pixel(x, y, roof_c)

	# Door
	for x in range(int(width / 2.0 - 10), int(width / 2.0 + 10)):
		for y in range(height - 35, height):
			img.set_pixel(x, y, wood_c)

	return ImageTexture.create_from_image(img)

static func create_arrow_texture() -> ImageTexture:
	var img = Image.create(24, 8, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	var c = Color("#f39c12")
	for x in range(0, 20):
		img.set_pixel(x, 4, c)
	# Arrow tip
	img.set_pixel(20, 3, c)
	img.set_pixel(21, 4, c)
	img.set_pixel(20, 5, c)
	return ImageTexture.create_from_image(img)

static func create_enemy_texture(main_c: Color, sub_c: Color, width: int = 42, height: int = 42, is_left: bool = false) -> ImageTexture:
	var img = Image.create(width, height, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))

	# Body fill
	for x in range(4, width - 4):
		for y in range(4, height - 4):
			img.set_pixel(x, y, main_c)

	# Eye stripe
	for x in range(6, width - 6):
		for y in range(12, 20):
			img.set_pixel(x, y, sub_c)

	# Glowing Eye
	var eye_x = 10 if is_left else width - 14
	for x in range(eye_x, eye_x + 5):
		for y in range(14, 18):
			img.set_pixel(x, y, Color("#ffffff"))

	return ImageTexture.create_from_image(img)
