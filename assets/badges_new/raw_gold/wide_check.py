from PIL import Image, ImageDraw

def wide_view(orig_path, col_path, bbox, name):
    orig = Image.open(orig_path).convert('RGBA')
    col = Image.open(col_path).convert('RGBA')
    canvas = Image.new('RGB', (1040, 520), 'white')
    o_draw = orig.copy()
    d = ImageDraw.Draw(o_draw)
    d.rectangle(bbox, outline='red', width=3)
    canvas.paste(o_draw.convert('RGB'), (0,0))
    canvas.paste(col.convert('RGB'), (520,0))
    canvas.save(f'{name}_wide_bbox_check.png')
    print(f"saved {name}_wide_bbox_check.png")

wide_view('/home/user/flutter_app/assets/badges/vivid_trophy.png', 'trophy_colorize_v3.png', (150,155,370,365), 'trophy')
wide_view('/home/user/flutter_app/assets/badges/vivid_tanuki.png', 'tanuki_colorize_v3.png', (140,155,375,350), 'tanuki')
