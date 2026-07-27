from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

FONT_BOLD = "/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc"
FONT_MED  = "/usr/share/fonts/opentype/noto/NotoSansCJK-Medium.ttc"
FONT_REG  = "/usr/share/fonts/opentype/noto/NotoSansCJK-Regular.ttc"

# Colors from tokens.dart
C_BG_SOFT      = (244,247,251)
C_BG_CARD      = (255,255,255)
C_PRIMARY      = (3,105,229)
C_PRIMARY_DARK = (0,87,194)
C_PRIMARY_FAINT= (240,247,255)
C_TEXT         = (15,23,42)
C_TEXT_DIM     = (100,116,139)
C_TEXT_MUTE    = (148,163,184)
C_BORDER_SOFT  = (238,242,247)
C_BADGE_BG     = (245,247,250)  # slight gray for locked tag bg

BASE = "/home/user/flutter_app/assets/badges_mockup/feedback_v2"
PROD = "/home/user/flutter_app/assets/badges"

def load_medal(path, diameter):
    im = Image.open(path).convert('RGBA')
    im = im.resize((diameter, diameter), Image.LANCZOS)
    return im

def rounded_rect(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)

def text_size(draw, text, font):
    bbox = draw.textbbox((0,0), text, font=font)
    return bbox[2]-bbox[0], bbox[3]-bbox[1]

def draw_center_text(draw, cx, top_y, text, font, fill, max_width=None):
    w, h = text_size(draw, text, font)
    draw.text((cx - w/2, top_y), text, font=font, fill=fill)
    return h

SCALE = 3  # render scale for crispness

def render_cell(cell_w, cell_h, medal_path, medal_diameter, name, unlocked, show_tag, tag_text="未達成"):
    """Render one badge grid cell at given size (already scaled)."""
    cell = Image.new('RGBA', (cell_w, cell_h), (0,0,0,0))
    draw = ImageDraw.Draw(cell)
    bg = C_PRIMARY_FAINT if unlocked else C_BG_SOFT
    rounded_rect(draw, [0,0,cell_w,cell_h], radius=14*SCALE, fill=bg)

    medal = load_medal(medal_path, medal_diameter)
    mx = (cell_w - medal_diameter)//2
    my = 10*SCALE
    cell.alpha_composite(medal, (mx, my))

    # tag pill "未達成" - place near bottom-right of medal, slightly overlapping
    if show_tag:
        tag_font = ImageFont.truetype(FONT_BOLD, int(11*SCALE))
        tw, th = text_size(draw, tag_text, tag_font)
        pad_x, pad_y = 7*SCALE, 3*SCALE
        pill_w, pill_h = tw+pad_x*2, th+pad_y*2
        px = mx + medal_diameter - pill_w + 6*SCALE
        py = my + medal_diameter - pill_h + 2*SCALE
        # pill shadow-ish outline via slightly darker border
        draw.rounded_rectangle([px, py, px+pill_w, py+pill_h], radius=pill_h/2,
                                fill=(148,163,184,255), outline=(255,255,255,255), width=int(1.5*SCALE))
        draw.text((px+pad_x, py+pad_y-int(1*SCALE)), tag_text, font=tag_font, fill=(255,255,255,255))

    # name text
    name_font = ImageFont.truetype(FONT_BOLD, int(12.5*SCALE))
    name_color = C_TEXT if unlocked else C_TEXT_MUTE
    text_top = my + medal_diameter + 8*SCALE
    # wrap into max 2 lines manually (simple char wrap since JP has no spaces)
    max_w = cell_w - 6*SCALE
    lines = []
    cur = ""
    for ch in name:
        test = cur + ch
        w,_ = text_size(draw, test, name_font)
        if w > max_w and cur:
            lines.append(cur)
            cur = ch
        else:
            cur = test
    if cur:
        lines.append(cur)
    lines = lines[:2]
    ly = text_top
    for line in lines:
        h = draw_center_text(draw, cell_w/2, ly, line, name_font, name_color)
        ly += h + int(2*SCALE)

    # "未達成" text label below name (explicit label as requested)
    if not unlocked:
        lock_font = ImageFont.truetype(FONT_BOLD, int(11*SCALE))
        draw_center_text(draw, cell_w/2, ly + int(1*SCALE), "未達成", lock_font, C_TEXT_MUTE)

    return cell

def build_grid(cells_data, cols=3, cell_w=None, cell_h=None, spacing=8*SCALE,
                container_pad=12*SCALE, outer_pad=18*SCALE, title=None, title_color=C_TEXT):
    rows = (len(cells_data)+cols-1)//cols
    grid_w = cols*cell_w + (cols-1)*spacing
    grid_h = rows*cell_h + (rows-1)*spacing
    container_w = grid_w + container_pad*2
    container_h = grid_h + container_pad*2
    title_h = 0
    if title:
        title_h = 40*SCALE
    canvas_w = container_w + outer_pad*2
    canvas_h = container_h + outer_pad*2 + title_h
    canvas = Image.new('RGBA', (canvas_w, canvas_h), C_BG_SOFT+(255,))
    draw = ImageDraw.Draw(canvas)

    ty = outer_pad
    if title:
        tfont = ImageFont.truetype(FONT_BOLD, int(15*SCALE))
        draw.text((outer_pad, ty), title, font=tfont, fill=title_color)
        ty += title_h

    # container white card
    draw.rounded_rectangle([outer_pad, ty, outer_pad+container_w, ty+container_h],
                            radius=16*SCALE, fill=C_BG_CARD, outline=C_BORDER_SOFT, width=int(1*SCALE))

    gx0 = outer_pad + container_pad
    gy0 = ty + container_pad
    for idx, cd in enumerate(cells_data):
        r = idx // cols
        c = idx % cols
        x = gx0 + c*(cell_w+spacing)
        y = gy0 + r*(cell_h+spacing)
        cell_img = render_cell(cell_w, cell_h, cd['medal_path'], cd['medal_diameter'],
                                cd['name'], cd['unlocked'], cd.get('show_tag', False))
        canvas.alpha_composite(cell_img, (x,y))
    return canvas

if __name__ == "__main__":
    pass
