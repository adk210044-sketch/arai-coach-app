from PIL import Image, ImageDraw

items = ['vivid_star', 'vivid_trophy', 'vivid_tanuki']
cell = 220
canvas = Image.new('RGB', (cell*2+40, cell*3+120), 'white')
draw = ImageDraw.Draw(canvas)
draw.text((10,5), "A: /assets/badges/ (production)", fill='black')
draw.text((cell+30,5), "B: /assets/badges_new/normalized/", fill='black')

y = 30
for name in items:
    a = Image.open(f'/home/user/flutter_app/assets/badges/{name}.png').convert('RGBA').resize((cell-20,cell-20))
    b = Image.open(f'/home/user/flutter_app/assets/badges_new/normalized/{name}.png').convert('RGBA').resize((cell-20,cell-20))
    bg_a = Image.new('RGBA', (cell,cell), (240,240,240,255))
    bg_a.paste(a, (10,10), a)
    bg_b = Image.new('RGBA', (cell,cell), (240,240,240,255))
    bg_b.paste(b, (10,10), b)
    canvas.paste(bg_a.convert('RGB'), (10, y))
    canvas.paste(bg_b.convert('RGB'), (cell+30, y))
    draw.text((10, y+cell), name, fill='gray')
    y += cell + 40

canvas.save('compare_two_sources.png')
print("saved")
