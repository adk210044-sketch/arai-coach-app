import sys
sys.path.insert(0, '/home/user/flutter_app/assets/badges_mockup/feedback_v2/mockup')
from PIL import Image, ImageDraw, ImageFont
import numpy as np

FONT_BOLD = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
FONT_MED  = "/usr/share/fonts/opentype/noto/NotoSansCJK-Medium.ttc"

# Colors (from tokens.dart)
C_BG_SOFT       = (244,247,251,255)
C_BG_CARD       = (255,255,255,255)
C_PRIMARY_FAINT = (240,247,255,255)
C_TEXT          = (15,23,42,255)
C_TEXT_MUTE     = (148,163,184,255)
C_BORDER_SOFT   = (238,242,247,255)

PROD = "/home/user/flutter_app/assets/badges"
FB2  = "/home/user/flutter_app/assets/badges_mockup/feedback_v2"

SCALE = 3  # 1dp = 3px

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
                 show_tag=False, tag_text="未達成", show_lock_label=True,
                 name_font_size=12.5, medal_top_dp=8):
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

    if show_tag:
        tag_font = ImageFont.truetype(FONT_BOLD, dp(10.5))
        tw, th = text_wh(draw, tag_text, tag_font)
        pad_x, pad_y = dp(6), dp(2.5)
        pill_w, pill_h = tw+pad_x*2, th+pad_y*2
        px = mx + md - pill_w + dp(8)
        py = my + md - pill_h + dp(6)
        draw.rounded_rectangle([px, py, px+pill_w, py+pill_h], radius=pill_h/2,
                                fill=(148,163,184,255), outline=(255,255,255,255), width=dp(1.2))
        draw.text((px+pad_x, py+pad_y-dp(0.5)), tag_text, font=tag_font, fill=(255,255,255,255))

    name_font = ImageFont.truetype(FONT_BOLD, dp(name_font_size))
    name_color = C_TEXT if unlocked else C_TEXT_MUTE
    max_w = cw - dp(6)
    lines = wrap_lines(draw, name, name_font, max_w, max_lines=2)
    ly = my + md + dp(7)
    for line in lines:
        w,h = text_wh(draw, line, name_font)
        draw.text(((cw-w)/2, ly), line, font=name_font, fill=name_color)
        ly += h + dp(2)

    if not unlocked and show_lock_label:
        lock_font = ImageFont.truetype(FONT_BOLD, dp(10.5))
        w,h = text_wh(draw, "未達成", lock_font)
        draw.text(((cw-w)/2, ly+dp(1)), "未達成", font=lock_font, fill=C_TEXT_MUTE)
        ly += h

    return cell

def build_grid(cells, cols, cell_w_dp, cell_h_dp, title=None, spacing_dp=8,
                container_pad_dp=12, outer_pad_dp=18, cell_kwargs=None):
    cell_kwargs = cell_kwargs or {}
    rows = (len(cells)+cols-1)//cols
    grid_w = cols*cell_w_dp + (cols-1)*spacing_dp
    grid_h = rows*cell_h_dp + (rows-1)*spacing_dp
    container_w = grid_w + container_pad_dp*2
    container_h = grid_h + container_pad_dp*2
    title_h = 34 if title else 0
    canvas_w = dp(container_w + outer_pad_dp*2)
    canvas_h = dp(container_h + outer_pad_dp*2 + title_h)
    canvas = Image.new('RGBA', (canvas_w, canvas_h), C_BG_SOFT)
    draw = ImageDraw.Draw(canvas)

    ty = dp(outer_pad_dp)
    if title:
        tfont = ImageFont.truetype(FONT_BOLD, dp(14.5))
        draw.text((dp(outer_pad_dp), ty), title, font=tfont, fill=C_TEXT)
        ty += dp(title_h)

    ox = dp(outer_pad_dp)
    draw.rounded_rectangle([ox, ty, ox+dp(container_w), ty+dp(container_h)],
                            radius=dp(16), fill=C_BG_CARD, outline=C_BORDER_SOFT, width=dp(1))

    gx0 = ox + dp(container_pad_dp)
    gy0 = ty + dp(container_pad_dp)
    for i, cdata in enumerate(cells):
        r, c = divmod(i, cols)
        x = gx0 + c*dp(cell_w_dp+spacing_dp)
        y = gy0 + r*dp(cell_h_dp+spacing_dp)
        cell_img = render_cell(cell_w_dp, cell_h_dp, cdata['medal_path'], cdata['medal_d'],
                                cdata['name'], cdata['unlocked'],
                                show_tag=cdata.get('show_tag', False), **cell_kwargs)
        canvas.alpha_composite(cell_img, (x, y))
    return canvas

# ---- Data: 初操作カテゴリ 6バッジ (light系) ----
badges_first_action = [
    {'id':'first_answer', 'name':'はじめの一問', 'asset':'light_seedling', 'unlocked':True},
    {'id':'first_gap_study', 'name':'スキマ学習デビュー', 'asset':'light_chat', 'unlocked':True},
    {'id':'first_weak_review', 'name':'苦手復習デビュー', 'asset':'light_brain', 'unlocked':False},
    {'id':'first_mock_exam', 'name':'模擬試験デビュー', 'asset':'light_memo', 'unlocked':False},
    {'id':'first_coach_chat', 'name':'あらいコーチに初相談', 'asset':'light_chat', 'unlocked':False},
    {'id':'first_bookmark', 'name':'保存デビュー', 'asset':'light_bookmark', 'unlocked':False},
]

OLD_LOCK_GRAY_SIMPLE = f"{FB2}/lock_transparent_v2.png"

def cells_before():
    cells = []
    for b in badges_first_action:
        if b['unlocked']:
            path = f"{PROD}/{b['asset']}.png"
        else:
            path = f"{FB2}/mockup/old_locked_{b['asset']}.png"
            # generate old-style grayscale+opacity version if not exists
            import os
            if not os.path.exists(path):
                im = Image.open(f"{PROD}/{b['asset']}.png").convert('RGBA')
                arr = np.array(im).astype(float)
                r,g,bl,a = arr[:,:,0],arr[:,:,1],arr[:,:,2],arr[:,:,3]
                gray = 0.2126*r+0.7152*g+0.0722*bl
                out = np.stack([gray,gray,gray,a*0.5],axis=2).astype(np.uint8)
                Image.fromarray(out,'RGBA').save(path)
        cells.append({'medal_path': path, 'medal_d': 46*0.8, 'name': b['name'], 'unlocked': b['unlocked']})
    return cells

def cells_after():
    cells = []
    for b in badges_first_action:
        if b['unlocked']:
            path = f"{PROD}/{b['asset']}.png"
            cells.append({'medal_path': path, 'medal_d': 90*0.8, 'name': b['name'], 'unlocked': True})
        else:
            path = OLD_LOCK_GRAY_SIMPLE
            cells.append({'medal_path': path, 'medal_d': 90*0.8, 'name': b['name'], 'unlocked': False, 'show_tag': False})
    return cells

# NOTE: medal_d values above use *0.8 as a display-size conversion since BadgeMedal
# size= param maps roughly 1:1 to widget box, medal circle itself has small internal padding.
# For mockup purposes we treat "size" directly as the visual diameter shown.

def cells_before_v2():
    cells = []
    for b in badges_first_action:
        if b['unlocked']:
            path = f"{PROD}/{b['asset']}.png"
        else:
            path = f"{FB2}/mockup/old_locked_{b['asset']}.png"
        cells.append({'medal_path': path, 'medal_d': 46, 'name': b['name'], 'unlocked': b['unlocked']})
    return cells

def cells_after_v2():
    cells = []
    for b in badges_first_action:
        if b['unlocked']:
            path = f"{PROD}/{b['asset']}.png"
        else:
            path = OLD_LOCK_GRAY_SIMPLE
        cells.append({'medal_path': path, 'medal_d': 90, 'name': b['name'], 'unlocked': b['unlocked']})
    return cells

if __name__ == "__main__":
    # BEFORE grid (current design: size=46, old lock design, no tag label)
    before = build_grid(cells_before_v2(), cols=3, cell_w_dp=99.7, cell_h_dp=128,
                         title="Before（現行デザイン）",
                         cell_kwargs=dict(name_font_size=9, show_lock_label=False, medal_top_dp=6))
    before.convert('RGB').save(f"{FB2}/mockup/mockup_before.png", quality=95)
    print("before size", before.size)

    # AFTER grid (new design: size=90 approx, new gray simple lock, tag label "未達成", gray text)
    after = build_grid(cells_after_v2(), cols=3, cell_w_dp=128, cell_h_dp=178,
                        title="After（修正後イメージ）",
                        cell_kwargs=dict(name_font_size=11.5, show_lock_label=True, medal_top_dp=8))
    after.convert('RGB').save(f"{FB2}/mockup/mockup_after.png", quality=95)
    print("after size", after.size)
