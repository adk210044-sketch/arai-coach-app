import numpy as np
from PIL import Image, ImageDraw

def make_corner_compare(orig_path, colorized_path, bbox, name, corner_size=80):
    orig = Image.open(orig_path).convert('RGBA')
    col = Image.open(colorized_path).convert('RGBA')
    o = np.array(orig).astype(float)
    c = np.array(col).astype(float)
    diff = np.abs(o - c).sum(axis=2)

    x0,y0,x1,y1 = bbox
    corners = {
        'TL': (x0, y0),
        'TR': (x1-corner_size, y0),
        'BL': (x0, y1-corner_size),
        'BR': (x1-corner_size, y1-corner_size),
    }

    scale = 4
    tiles = []
    for label, (cx, cy) in corners.items():
        cx = max(0, cx); cy = max(0, cy)
        o_crop = orig.crop((cx, cy, cx+corner_size, cy+corner_size)).resize((corner_size*scale, corner_size*scale), Image.NEAREST)
        c_crop = col.crop((cx, cy, cx+corner_size, cy+corner_size)).resize((corner_size*scale, corner_size*scale), Image.NEAREST)
        d_crop = diff[cy:cy+corner_size, cx:cx+corner_size]
        d_norm = np.clip(d_crop*2, 0, 255).astype(np.uint8)
        d_img = Image.fromarray(d_norm).resize((corner_size*scale, corner_size*scale), Image.NEAREST).convert('RGB')

        row = Image.new('RGB', (corner_size*scale*3+20, corner_size*scale+30), 'white')
        row.paste(o_crop.convert('RGB'), (0,30))
        row.paste(c_crop.convert('RGB'), (corner_size*scale+10,30))
        row.paste(d_img, (corner_size*scale*2+20,30))
        draw = ImageDraw.Draw(row)
        draw.text((5,5), f"{label}: orig | colorized | diff(x2)", fill='black')
        nonzero = (d_crop>5).sum()
        draw.text((5,15), f"changed px(>5): {nonzero}", fill='red')
        tiles.append(row)

    total_h = sum(t.height for t in tiles) + 10*len(tiles)
    max_w = max(t.width for t in tiles)
    canvas = Image.new('RGB', (max_w, total_h), 'white')
    y = 0
    for t in tiles:
        canvas.paste(t, (0, y))
        y += t.height + 10
    canvas.save(f'{name}_corners_v3_check.png')
    print(f"Saved {name}_corners_v3_check.png")
    for label,(cx,cy) in corners.items():
        cx = max(0,cx); cy=max(0,cy)
        d_crop = diff[cy:cy+corner_size, cx:cx+corner_size]
        print(f"  {label}: changed px(>5)={int((d_crop>5).sum())}, max={d_crop.max():.1f}")

make_corner_compare(
    '/home/user/flutter_app/assets/badges/vivid_trophy.png',
    'trophy_colorize_v3.png',
    (150,155,370,365),
    'trophy'
)
print()
make_corner_compare(
    '/home/user/flutter_app/assets/badges/vivid_tanuki.png',
    'tanuki_colorize_v3.png',
    (140,155,375,350),
    'tanuki'
)
