"""3色メダル(シルバー/ライトブルー/ビビッドブルー)の最終比較シートを作成する。
ランクルール(silver < light < vivid の順に評価が高い)に合わせ、
左から下位→上位の順で並べ、ラベルを付ける。
"""
from PIL import Image, ImageDraw, ImageFont

FONT_PATH_BOLD = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
FONT_PATH_REG = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"

CELL_W = 320
CELL_H = 420
PAD = 20

items = [
    ("final_silver.png", "シルバー", "下位(3-10日 / 合格可能性40-50%)"),
    ("final_light.png", "ライトブルー", "中位(20-40日 / 合格可能性60-70%)"),
    ("final_vivid.png", "ビビッドブルー", "上位・最高評価(60-90日 / 合格可能性80%)"),
]

sheet = Image.new("RGB", (CELL_W * 3 + PAD * 4, CELL_H + PAD * 2), (245, 247, 250))
draw = ImageDraw.Draw(sheet)
font_title = ImageFont.truetype(FONT_PATH_BOLD, 22)
font_sub = ImageFont.truetype(FONT_PATH_REG, 14)

for i, (fname, title, sub) in enumerate(items):
    x0 = PAD + i * (CELL_W + PAD)
    y0 = PAD

    # セル背景(白カード)
    draw.rounded_rectangle(
        [x0, y0, x0 + CELL_W, y0 + CELL_H], radius=16, fill=(255, 255, 255)
    )

    medal = Image.open(fname).convert("RGBA")
    # メダルをセル幅に収まるようリサイズ
    max_medal_w = CELL_W - 60
    scale = max_medal_w / medal.width
    new_size = (int(medal.width * scale), int(medal.height * scale))
    medal_resized = medal.resize(new_size, Image.LANCZOS)

    mx = x0 + (CELL_W - new_size[0]) // 2
    my = y0 + 30
    sheet.paste(medal_resized, (mx, my), medal_resized)

    # タイトル
    tb = draw.textbbox((0, 0), title, font=font_title)
    tw = tb[2] - tb[0]
    draw.text(
        (x0 + (CELL_W - tw) / 2, y0 + new_size[1] + 45),
        title,
        font=font_title,
        fill=(30, 40, 60),
    )

    # サブラベル(複数行対応)
    sub_y = y0 + new_size[1] + 80
    sb = draw.textbbox((0, 0), sub, font=font_sub)
    sw = sb[2] - sb[0]
    draw.text(
        (x0 + (CELL_W - sw) / 2, sub_y),
        sub,
        font=font_sub,
        fill=(100, 110, 130),
    )

sheet.save("mockup_final_3colors.jpg", quality=92)
print("saved mockup_final_3colors.jpg", sheet.size)
