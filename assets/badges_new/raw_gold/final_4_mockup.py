from PIL import Image, ImageDraw, ImageFont

items = [
    ('vivid_crown', '/home/user/flutter_app/assets/badges/vivid_crown.png', 'crown_colorize_v3.png', '王冠'),
    ('vivid_star', '/home/user/flutter_app/assets/badges/vivid_star.png', 'star_colorize_v3.png', '星'),
    ('vivid_trophy', '/home/user/flutter_app/assets/badges/vivid_trophy.png', 'trophy_colorize_v3.png', 'トロフィー'),
    ('vivid_tanuki', '/home/user/flutter_app/assets/badges/vivid_tanuki.png', 'tanuki_colorize_v3.png', 'タヌキ'),
]

cell_w, cell_h = 260, 320
canvas = Image.new('RGB', (cell_w*4, cell_h), 'white')
draw = ImageDraw.Draw(canvas)

for i, (key, orig_path, col_path, label) in enumerate(items):
    col = Image.open(col_path).convert('RGBA').resize((240,240))
    bg = Image.new('RGB', (240,240), 'white')
    bg.paste(col, (0,0), col)
    x = i*cell_w + 10
    canvas.paste(bg, (x, 40))
    draw.text((x+80, 10), label, fill='black')
    draw.text((x+30, 290), '溝=金色ゴールド', fill='gray')

canvas.save('FINAL_4_vivid_gold_mockup.png')
print("saved FINAL_4_vivid_gold_mockup.png")
