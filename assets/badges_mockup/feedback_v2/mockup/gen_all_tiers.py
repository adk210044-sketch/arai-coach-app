import sys
sys.path.insert(0, '/home/user/flutter_app/assets/badges_mockup/feedback_v2/mockup')
from PIL import Image, ImageDraw, ImageFont
import numpy as np

FONT_BOLD = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
FONT_MED  = "/usr/share/fonts/opentype/noto/NotoSansCJK-Medium.ttc"

C_BG_SOFT       = (244,247,251,255)
C_BG_CARD       = (255,255,255,255)
C_PRIMARY_FAINT = (240,247,255,255)
C_TEXT          = (15,23,42,255)
C_TEXT_MUTE     = (148,163,184,255)
C_BORDER_SOFT   = (238,242,247,255)
C_TIER_LIGHT    = (46,127,224,255)
C_TIER_SILVER   = (107,118,134,255)
C_TIER_VIVID    = (26,58,138,255)
C_BAD           = (214,60,60,255)

PROD = "/home/user/flutter_app/assets/badges"
NORM = "/home/user/flutter_app/assets/badges_new/normalized"
FB2  = "/home/user/flutter_app/assets/badges_mockup/feedback_v2"

SCALE = 3

def dp(v):
    return int(round(v*SCALE))

def load_medal(path, diameter_dp):
    im = Image.open(path).convert('RGBA')
    d = dp(diameter_dp)
    return im.resize((d, d), Image.LANCZOS)

def text_wh(draw, text, font):
    b = draw.textbbox((0,0), text, font=font)
    return b[2]-b[0], b[3]-b[1]

def render_cell(cell_w_dp, cell_h_dp, medal_path, medal_d_dp, name, tier_label, tier_color,
                 name_font_size=10, medal_top_dp=8):
    cw, ch = dp(cell_w_dp), dp(cell_h_dp)
    cell = Image.new('RGBA', (cw, ch), (0,0,0,0))
    draw = ImageDraw.Draw(cell)
    draw.rounded_rectangle([0,0,cw,ch], radius=dp(12), fill=C_BG_CARD, outline=C_BORDER_SOFT, width=dp(1))

    medal = load_medal(medal_path, medal_d_dp)
    md = medal.size[0]
    mx = (cw - md)//2
    my = dp(medal_top_dp)
    cell.alpha_composite(medal, (mx, my))

    name_font = ImageFont.truetype(FONT_BOLD, dp(name_font_size))
    lines = [name] if len(name) <= 8 else [name[:6], name[6:]]
    ly = my + md + dp(6)
    for line in lines:
        w,h = text_wh(draw, line, name_font)
        draw.text(((cw-w)/2, ly), line, font=name_font, fill=C_TEXT)
        ly += h + dp(1)

    return cell

def build_tier_row(items, cols, cell_w_dp, cell_h_dp, section_title, tier_color,
                     medal_d_dp, is_before, spacing_dp=10, container_pad_dp=14):
    rows = (len(items)+cols-1)//cols
    grid_w = cols*cell_w_dp + (cols-1)*spacing_dp
    grid_h = rows*cell_h_dp + (rows-1)*spacing_dp
    title_h = 26

    canvas_w = dp(grid_w + container_pad_dp*2)
    canvas_h = dp(grid_h + container_pad_dp*2 + title_h)
    canvas = Image.new('RGBA', (canvas_w, canvas_h), (0,0,0,0))
    draw = ImageDraw.Draw(canvas)

    tfont = ImageFont.truetype(FONT_BOLD, dp(12.5))
    draw.rounded_rectangle([0,0,dp(10),dp(10)], radius=dp(2), fill=tier_color)
    draw.text((dp(14), dp(2)), section_title, font=tfont, fill=C_TEXT)

    ty = dp(title_h)
    gx0, gy0 = 0, ty
    for i, item in enumerate(items):
        r, c = divmod(i, cols)
        x = gx0 + c*dp(cell_w_dp+spacing_dp)
        y = gy0 + r*dp(cell_h_dp+spacing_dp)
        folder = item['before_folder'] if is_before else item['after_folder']
        path = f"{folder}/{item['asset']}.png"
        cell_img = render_cell(cell_w_dp, cell_h_dp, path, medal_d_dp, item['name'], section_title, tier_color)
        canvas.alpha_composite(cell_img, (x, y))
    return canvas

# ---- 14 unique assets, tier-grouped ----
LIGHT_ITEMS = [
    {'asset':'light_seedling', 'name':'はじめの一問', 'before_folder':PROD, 'after_folder':PROD},
    {'asset':'light_chat', 'name':'スキマ学習デビュー', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'light_brain', 'name':'苦手復習デビュー', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'light_memo', 'name':'模擬試験デビュー', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'light_bookmark', 'name':'保存デビュー', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'light_lightning', 'name':'20日連続', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'light_star', 'name':'40日連続', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'light_chart', 'name':'合格可能性60%', 'before_folder':PROD, 'after_folder':NORM},
]
SILVER_ITEMS = [
    {'asset':'silver_target', 'name':'合格可能性40%', 'before_folder':PROD, 'after_folder':PROD},
    {'asset':'silver_flame', 'name':'3日連続', 'before_folder':PROD, 'after_folder':NORM},
]
VIVID_ITEMS = [
    {'asset':'vivid_crown', 'name':'90日連続', 'before_folder':PROD, 'after_folder':PROD},
    {'asset':'vivid_star', 'name':'60日連続', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'vivid_trophy', 'name':'合格可能性80%', 'before_folder':PROD, 'after_folder':NORM},
    {'asset':'vivid_tanuki', 'name':'あらいコーチAI連携', 'before_folder':PROD, 'after_folder':NORM},
]

def build_full_sheet(is_before, title):
    row1 = build_tier_row(LIGHT_ITEMS, cols=4, cell_w_dp=88, cell_h_dp=104, section_title="薄いブルー (light) 8種", tier_color=C_TIER_LIGHT, medal_d_dp=64, is_before=is_before)
    row2 = build_tier_row(SILVER_ITEMS, cols=4, cell_w_dp=88, cell_h_dp=104, section_title="シルバー (silver) 2種", tier_color=C_TIER_SILVER, medal_d_dp=64, is_before=is_before)
    row3 = build_tier_row(VIVID_ITEMS, cols=4, cell_w_dp=88, cell_h_dp=104, section_title="濃いブルー (vivid) 4種", tier_color=C_TIER_VIVID, medal_d_dp=64, is_before=is_before)

    pad = dp(20)
    title_h = dp(30)
    gap = dp(16)
    W = max(row1.width, row2.width, row3.width) + pad*2
    H = title_h + row1.height + gap + row2.height + gap + row3.height + pad*2

    canvas = Image.new('RGB', (W, H), (255 if not is_before else 250,) * 1 + ((255,255) if False else (0,0)))
    canvas = Image.new('RGB', (W, H), (244,247,251))
    draw = ImageDraw.Draw(canvas)

    title_font = ImageFont.truetype(FONT_BOLD, dp(17))
    title_color = C_BAD if is_before else (30,140,70,255)
    draw.text((pad, dp(6)), title, font=title_font, fill=title_color[:3] if isinstance(title_color, tuple) else title_color)

    y = title_h
    canvas.paste(row1.convert('RGB'), (pad, y), row1.split()[3])
    y += row1.height + gap
    canvas.paste(row2.convert('RGB'), (pad, y), row2.split()[3])
    y += row2.height + gap
    canvas.paste(row3.convert('RGB'), (pad, y), row3.split()[3])
    return canvas

def render_alpha_over(canvas, layer, xy):
    # paste with alpha as mask, but keep canvas RGB
    canvas.paste(layer.convert('RGB'), xy, layer.split()[3])

if __name__ == "__main__":
    before = build_full_sheet(True, "Before：色味・光沢がバッジごとにバラバラ（現行）")
    before.save(f"{FB2}/mockup/mockup_all_tiers_before.png", quality=95)
    print("before", before.size)

    after = build_full_sheet(False, "After：テンプレート複製方式で全ティア色味統一")
    after.save(f"{FB2}/mockup/mockup_all_tiers_after.png", quality=95)
    print("after", after.size)

    # Stack vertically for comparison
    gap = 24
    w = max(before.width, after.width)
    h = before.height + gap + after.height
    stack = Image.new('RGB', (w, h), (255,255,255))
    stack.paste(before, (0,0))
    stack.paste(after, (0, before.height+gap))
    stack.save(f"{FB2}/mockup/mockup_all_tiers_stack.png", quality=95)
    print("stack", stack.size)
