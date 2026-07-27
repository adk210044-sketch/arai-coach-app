from PIL import Image, ImageDraw

# light+silver: compare production vs normalized (where normalized exists)
pairs = ['light_bookmark','light_brain','light_chart','light_chat','light_lightning','light_memo','light_star','silver_flame']

cell = 200
cols_per_row = 2
canvas = Image.new('RGB', (cell*2+60, cell*len(pairs)+ (30*len(pairs)) + 40), 'white')
draw = ImageDraw.Draw(canvas)
draw.text((10,5), "A: /assets/badges/ (production, mtime 11:38)", fill='black')
draw.text((cell+40,5), "B: /assets/badges_new/normalized/ (mtime 15:42)", fill='black')

y = 30
for name in pairs:
    a = Image.open(f'/home/user/flutter_app/assets/badges/{name}.png').convert('RGBA').resize((cell-20,cell-20))
    b = Image.open(f'/home/user/flutter_app/assets/badges_new/normalized/{name}.png').convert('RGBA').resize((cell-20,cell-20))
    bg_a = Image.new('RGBA', (cell,cell), (240,240,240,255)); bg_a.paste(a,(10,10),a)
    bg_b = Image.new('RGBA', (cell,cell), (240,240,240,255)); bg_b.paste(b,(10,10),b)
    canvas.paste(bg_a.convert('RGB'), (10,y))
    canvas.paste(bg_b.convert('RGB'), (cell+40,y))
    draw.text((10,y+cell), name, fill='red')
    y += cell + 30

canvas.save('compare_all_light_silver_sources.png')
print("saved")
