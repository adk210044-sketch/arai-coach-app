from PIL import Image, ImageDraw

groups = [
    ('light系 (8種) - マスター1種+派生7種、変更なし', ['light_seedling','light_chat','light_brain','light_memo','light_bookmark','light_lightning','light_star','light_chart']),
    ('silver系 (2種) - マスター1種+派生1種、変更なし', ['silver_target','silver_flame']),
    ('vivid系 (4種) - 王冠のみ金色(承認済)、他3種は変更なし', ['vivid_crown','vivid_star','vivid_trophy','vivid_tanuki']),
]

cell = 180
cols = 8
pad = 10
label_h = 30
title_h = 30
group_gap = 30

canvas_w = cols*(cell+pad)+pad

total_h = 20
for title, items in groups:
    rows = -(-len(items)//cols)
    total_h += title_h + rows*(cell+label_h+pad) + group_gap

canvas = Image.new('RGB', (canvas_w, total_h), 'white')
draw = ImageDraw.Draw(canvas)

y = 20
for title, items in groups:
    draw.text((pad, y), title, fill='black')
    y += title_h
    x = pad
    for i, name in enumerate(items):
        img = Image.open(f'{name}.png').convert('RGBA').resize((cell-20, cell-20))
        bg = Image.new('RGBA', (cell, cell), (245,245,245,255))
        bg.paste(img, (10,10), img)
        canvas.paste(bg.convert('RGB'), (x, y))
        draw.text((x, y+cell), name, fill='gray')
        x += cell+pad
        if (i+1) % cols == 0:
            x = pad
            y += cell + pad + label_h
    if len(items) % cols != 0:
        y += cell + pad + label_h
    y += group_gap

canvas.save('FINAL_CONFIRMED_ALL_14_v2.png')
print("saved, size:", canvas.size)
