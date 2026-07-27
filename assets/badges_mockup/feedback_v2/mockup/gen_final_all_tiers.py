import sys
sys.path.insert(0, '/home/user/flutter_app/assets/badges_mockup/feedback_v2/mockup')
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import os

FONT_BOLD = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"

C_BG_SOFT       = (244,247,251,255)
C_BG_CARD       = (255,255,255,255)
C_PRIMARY_FAINT = (240,247,255,255)
C_TEXT          = (15,23,42,255)
C_TEXT_MUTE     = (148,163,184,255)
C_BORDER_SOFT   = (238,242,247,255)
C_TIER_LIGHT    = (46,127,224,255)
C_TIER_SILVER   = (107,118,134,255)
C_TIER_VIVID    = (26,58,138,255)

PROD = "/home/user/flutter_app/assets/badges"
NORM = "/home/user/flutter_app/assets/badges_new/normalized"
FB2  = "/home/user/flutter_app/assets/badges_mockup/feedback_v2"
LOCK = f"{FB2}/lock_transparent_v2.png"

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

def wrap_lines(draw, text, font, max_w_px, max_lines=2):
    lines = []
    cur = ""
    for ch in text:
        test = cur + ch
        w,_ = text_wh(draw, test, font)
        if w > max_w_px and cur:
            lines.append(cur)
            cur = ch
        else:
            cur = test
    if cur:
        lines.append(cur)
    if len(lines) > max_lines:
        lines = lines[:max_lines]
    return lines

def render_cell(cell_w_dp, cell_h_dp, medal_path, medal_d_dp, name, unlocked,
                 name_font_size=11.5, lock_font_size=13.5, medal_top_dp=8, is_before=False):
    cw, ch = dp(cell_w_dp), dp(cell_h_dp)
    cell = Image.new('RGBA', (cw, ch), (0,0,0,0))
    draw = ImageDraw.Draw(cell)
    bg = C_PRIMARY_FAINT if unlocked else C_BG_SOFT
    draw.rounded_rectangle([0,0,cw,ch], radius=dp(14), fill=bg)

    medal = load_medal(medal_path, medal_d_dp)
    md = medal.size[0]
    mx = (cw - md)//2
    my = dp(medal_top_dp)
    cell.alpha_composite(medal, (mx, my))

    name_font = ImageFont.truetype(FONT_BOLD, dp(name_font_size))
    name_color = C_TEXT if unlocked else C_TEXT_MUTE
    max_w = cw - dp(6)
    lines = wrap_lines(draw, name, name_font, max_w, max_lines=2)
    ly = my + md + dp(8)
    for line in lines:
        w,h = text_wh(draw, line, name_font)
        draw.text(((cw-w)/2, ly), line, font=name_font, fill=name_color)
        ly += h + dp(3)

    if not unlocked and not is_before:
        lock_font = ImageFont.truetype(FONT_BOLD, dp(lock_font_size))
        w,h = text_wh(draw, "未達成", lock_font)
        draw.text(((cw-w)/2, ly+dp(1)), "未達成", font=lock_font, fill=C_TEXT_MUTE)
        ly += h

    return cell

def build_tier_row(items, cols, cell_w_dp, cell_h_dp, section_title, tier_color,
                     medal_d_dp, is_before, name_font_size, lock_font_size, spacing_dp=10):
    rows = (len(items)+cols-1)//cols
    grid_w = cols*cell_w_dp + (cols-1)*spacing_dp
    grid_h = rows*cell_h_dp + (rows-1)*spacing_dp
    title_h = 26

    canvas_w = dp(grid_w)
    canvas_h = dp(grid_h + title_h)
    canvas = Image.new('RGBA', (canvas_w, canvas_h), (0,0,0,0))
    draw = ImageDraw.Draw(canvas)

    tfont = ImageFont.truetype(FONT_BOLD, dp(13))
    draw.rounded_rectangle([0,0,dp(10),dp(10)], radius=dp(2), fill=tier_color)
    draw.text((dp(14), dp(1)), section_title, font=tfont, fill=C_TEXT)

    ty = dp(title_h)
    for i, item in enumerate(items):
        r, c = divmod(i, cols)
        x = c*dp(cell_w_dp+spacing_dp)
        y = ty + r*dp(cell_h_dp+spacing_dp)
        folder = item['folder_before'] if is_before else item['folder_after']
        unlocked = item['unlocked']
        if unlocked:
            path = f"{folder}/{item['asset']}.png"
        else:
            if is_before:
                path = f"{FB2}/mockup/old_locked_{item['asset']}.png"
                if not os.path.exists(path):
                    im = Image.open(f"{item['folder_before']}/{item['asset']}.png").convert('RGBA')
                    arr = np.array(im).astype(float)
                    r2,g2,bl2,a2 = arr[:,:,0],arr[:,:,1],arr[:,:,2],arr[:,:,3]
                    gray = 0.2126*r2+0.7152*g2+0.0722*bl2
                    out = np.stack([gray,gray,gray,a2*0.5],axis=2).astype(np.uint8)
                    Image.fromarray(out,'RGBA').save(path)
            else:
                path = LOCK
        cell_img = render_cell(cell_w_dp, cell_h_dp, path, medal_d_dp, item['name'], unlocked,
                                name_font_size=name_font_size, lock_font_size=lock_font_size,
                                medal_top_dp=8, is_before=is_before)
        canvas.alpha_composite(cell_img, (x, y))
    return canvas

# ---- 14 badges across all tiers, mix of unlocked/locked for realistic preview ----
LIGHT_ITEMS = [
    {'asset':'light_seedling', 'name':'はじめの一問',      'folder_before':PROD, 'folder_after':PROD, 'unlocked':True},
    {'asset':'light_chat',     'name':'スキマ学習デビュー', 'folder_before':PROD, 'folder_after':NORM, 'unlocked':True},
    {'asset':'light_brain',    'name':'苦手復習デビュー',   'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
    {'asset':'light_memo',     'name':'模擬試験デビュー',   'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
    {'asset':'light_bookmark', 'name':'保存デビュー',      'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
    {'asset':'light_lightning','name':'20日連続',         'folder_before':PROD, 'folder_after':NORM, 'unlocked':True},
    {'asset':'light_star',     'name':'40日連続',         'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
    {'asset':'light_chart',    'name':'合格可能性60%',     'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
]
SILVER_ITEMS = [
    {'asset':'silver_target', 'name':'合格可能性40%', 'folder_before':PROD, 'folder_after':PROD, 'unlocked':True},
    {'asset':'silver_flame',  'name':'3日連続',       'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
]
VIVID_ITEMS = [
    {'asset':'vivid_crown',  'name':'90日連続',          'folder_before':PROD, 'folder_after':PROD, 'unlocked':True},
    {'asset':'vivid_star',   'name':'60日連続',          'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
    {'asset':'vivid_trophy', 'name':'合格可能性80%',      'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
    {'asset':'vivid_tanuki', 'name':'あらいコーチAI連携', 'folder_before':PROD, 'folder_after':NORM, 'unlocked':False},
]

def build_full_sheet(is_before, title, name_font_size, lock_font_size):
    row1 = build_tier_row(LIGHT_ITEMS, cols=4, cell_w_dp=128, cell_h_dp=155, section_title="薄いブルー (light) — 8種", tier_color=C_TIER_LIGHT, medal_d_dp=80, is_before=is_before, name_font_size=name_font_size, lock_font_size=lock_font_size)
    row2 = build_tier_row(SILVER_ITEMS, cols=4, cell_w_dp=128, cell_h_dp=155, section_title="シルバー (silver) — 2種", tier_color=C_TIER_SILVER, medal_d_dp=80, is_before=is_before, name_font_size=name_font_size, lock_font_size=lock_font_size)
    row3 = build_tier_row(VIVID_ITEMS, cols=4, cell_w_dp=128, cell_h_dp=155, section_title="濃いブルー (vivid) — 4種", tier_color=C_TIER_VIVID, medal_d_dp=80, is_before=is_before, name_font_size=name_font_size, lock_font_size=lock_font_size)

    pad = dp(20)
    title_h = dp(46)
    gap = dp(18)
    W = max(row1.width, row2.width, row3.width) + pad*2
    H = title_h + row1.height + gap + row2.height + gap + row3.height + pad*2

    canvas = Image.new('RGB', (W, H), (244,247,251))
    draw = ImageDraw.Draw(canvas)

    title_font = ImageFont.truetype(FONT_BOLD, dp(15))
    title_color = (214,60,60) if is_before else (30,140,70)
    # タイトルが枠を超える場合は自動で折り返す
    tb = draw.textbbox((0,0), title, font=title_font)
    if tb[2]-tb[0] > W - pad*2:
        mid = len(title) // 2
        # 句読点や記号付近で分割を試みる
        split_at = title.rfind("・", 0, mid+8)
        if split_at == -1:
            split_at = mid
        draw.text((pad, dp(3)), title[:split_at+1], font=title_font, fill=title_color)
        draw.text((pad, dp(3)+dp(17)), title[split_at+1:], font=title_font, fill=title_color)
    else:
        draw.text((pad, dp(10)), title, font=title_font, fill=title_color)

    y = title_h
    canvas.paste(row1.convert('RGB'), (pad, y), row1.split()[3])
    y += row1.height + gap
    canvas.paste(row2.convert('RGB'), (pad, y), row2.split()[3])
    y += row2.height + gap
    canvas.paste(row3.convert('RGB'), (pad, y), row3.split()[3])
    return canvas

if __name__ == "__main__":
    before = build_full_sheet(True, "Before（現行：色味バラバラ・ロックはグレースケール半透明・未達成表記なし）",
                               name_font_size=9.5, lock_font_size=9.5)
    before.save(f"{FB2}/mockup/mockup_final_before.png", quality=95)
    print("before", before.size)

    after = build_full_sheet(False, "After（修正後：全ティア色味統一・専用ロック画像・「未達成」文字を拡大）",
                              name_font_size=12, lock_font_size=15)
    after.save(f"{FB2}/mockup/mockup_final_after.png", quality=95)
    print("after", after.size)
