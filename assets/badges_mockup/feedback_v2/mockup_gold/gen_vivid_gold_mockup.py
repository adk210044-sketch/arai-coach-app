from PIL import Image, ImageDraw, ImageFont
import numpy as np

FONT_BOLD = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"

C_TEXT = (15,23,42,255)
C_TEXT_MUTE = (100,110,130,255)
C_BG_CARD = (244,247,251,255)

PROD = "/home/user/flutter_app/assets/badges"
NORM = "/home/user/flutter_app/assets/badges_new/normalized"
GOLD = "/home/user/flutter_app/assets/badges_new/gold_final"

SCALE = 3
def dp(v): return int(round(v*SCALE))

def text_wh(draw, text, font):
    b = draw.textbbox((0,0), text, font=font)
    return b[2]-b[0], b[3]-b[1]

def render_pair(name, before_path, after_path, badge_name):
    cell_w, cell_h = dp(150), dp(210)
    canvas = Image.new('RGBA', (cell_w*2 + dp(20), cell_h), (0,0,0,0))
    draw = ImageDraw.Draw(canvas)

    font_label = ImageFont.truetype(FONT_BOLD, dp(11))
    font_name = ImageFont.truetype(FONT_BOLD, dp(12))

    for i, (path, label) in enumerate([(before_path,"Before（青線）"),(after_path,"After（金線）")]):
        x0 = i*(cell_w+dp(20))
        draw.rounded_rectangle([x0,0,x0+cell_w,cell_h], radius=dp(14), fill=C_BG_CARD)
        im = Image.open(path).convert('RGBA')
        d = dp(100)
        im = im.resize((d,d), Image.LANCZOS)
        mx = x0 + (cell_w-d)//2
        my = dp(14)
        canvas.alpha_composite(im, (mx,my))
        w,h = text_wh(draw, label, font_label)
        draw.text((x0+(cell_w-w)//2, my+d+dp(8)), label, font=font_label, fill=C_TEXT_MUTE)
        if i==1:
            w2,h2 = text_wh(draw, badge_name, font_name)
            draw.text((x0+(cell_w-w2)//2, my+d+dp(8)+h+dp(6)), badge_name, font=font_name, fill=C_TEXT)
    return canvas

items = [
    ("vivid_crown",  f"{PROD}/vivid_crown.png",  f"{GOLD}/vivid_crown.png",  "90日連続"),
    ("vivid_star",   f"{NORM}/vivid_star.png",   f"{GOLD}/vivid_star.png",   "60日連続"),
    ("vivid_trophy", f"{NORM}/vivid_trophy.png", f"{GOLD}/vivid_trophy.png", "合格可能性80%"),
    ("vivid_tanuki", f"{NORM}/vivid_tanuki.png", f"{GOLD}/vivid_tanuki.png", "あらいコーチAI連携"),
]

rows = [render_pair(*it) for it in items]
pad = dp(20)
gap = dp(14)
W = max(r.width for r in rows) + pad*2
H = sum(r.height for r in rows) + gap*(len(rows)-1) + pad*2 + dp(40)

canvas = Image.new('RGB', (W,H), (255,255,255))
draw = ImageDraw.Draw(canvas)
title_font = ImageFont.truetype(FONT_BOLD, dp(16))
draw.text((pad, dp(10)), "濃いブルー(vivid)バッジ — アイコンの溝を金色に変更", font=title_font, fill=(30,60,140))

y = dp(40)
for r in rows:
    canvas.paste(r.convert('RGB'), (pad, y), r.split()[3])
    y += r.height + gap

canvas.save("/home/user/flutter_app/assets/badges_mockup/feedback_v2/mockup_gold/vivid_gold_comparison.png")
print("saved", canvas.size)
