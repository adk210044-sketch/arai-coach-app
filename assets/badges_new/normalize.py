from PIL import Image
import numpy as np, os

RAW = "/home/user/flutter_app/assets/badges_new/raw"
PROD = "/home/user/flutter_app/assets/badges"
OUT = "/home/user/flutter_app/assets/badges_new/normalized"

TEMPLATE_MAP = {
    'light_chat_new.png': 'light_seedling.png',
    'light_brain_new.png': 'light_seedling.png',
    'light_memo_new.png': 'light_seedling.png',
    'light_bookmark_new.png': 'light_seedling.png',
    'light_lightning_new.png': 'light_seedling.png',
    'light_star_new.png': 'light_seedling.png',
    'light_chart_new.png': 'light_seedling.png',
    'silver_flame_new.png': 'silver_target.png',
    'vivid_star_new.png': 'vivid_crown.png',
    'vivid_trophy_new.png': 'vivid_crown.png',
    'vivid_tanuki_new.png': 'vivid_crown.png',
}

def detect_circle_bbox_white_bg(arr):
    dist = np.abs(arr[:,:,0].astype(int)-255)+np.abs(arr[:,:,1].astype(int)-255)+np.abs(arr[:,:,2].astype(int)-255)
    mask = dist > 15
    ys, xs = np.where(mask)
    return xs.min(), xs.max(), ys.min(), ys.max()

def detect_alpha_bbox(alpha):
    ys, xs = np.where(alpha > 10)
    return xs.min(), xs.max(), ys.min(), ys.max()

for raw_name, template_name in TEMPLATE_MAP.items():
    raw_path = f"{RAW}/{raw_name}"
    template_path = f"{PROD}/{template_name}"

    # Load template to get target bbox/center/alpha
    tmpl = Image.open(template_path).convert('RGBA')
    tmpl_arr = np.array(tmpl)
    tmpl_alpha = tmpl_arr[:,:,3]
    tx0, tx1, ty0, ty1 = detect_alpha_bbox(tmpl_alpha)
    t_cx = (tx0+tx1)/2
    t_cy = (ty0+ty1)/2
    t_w = tx1-tx0
    t_h = ty1-ty0
    t_diam = (t_w+t_h)/2  # 512 canvas

    # Load raw new image (RGB, white bg, 2048x2048)
    raw = Image.open(raw_path).convert('RGB')
    raw_arr = np.array(raw)
    rx0, rx1, ry0, ry1 = detect_circle_bbox_white_bg(raw_arr)
    r_cx = (rx0+rx1)/2
    r_cy = (ry0+ry1)/2
    r_w = rx1-rx0
    r_h = ry1-ry0
    r_diam = (r_w+r_h)/2

    scale = t_diam / r_diam

    # Resize raw image by scale
    new_w = int(round(raw.width * scale))
    new_h = int(round(raw.height * scale))
    resized = raw.resize((new_w, new_h), Image.LANCZOS)

    # New center after resize
    new_cx = r_cx * scale
    new_cy = r_cy * scale

    # We want new_cx,new_cy to align with t_cx,t_cy in a 512x512 canvas
    # crop box: left = new_cx - t_cx, top = new_cy - t_cy, size 512x512
    left = int(round(new_cx - t_cx))
    top = int(round(new_cy - t_cy))
    right = left + 512
    bottom = top + 512

    # Pad if needed
    canvas = Image.new('RGB', (512,512), (255,255,255))
    # compute overlap region
    src_left = max(left, 0)
    src_top = max(top, 0)
    src_right = min(right, resized.width)
    src_bottom = min(bottom, resized.height)
    dst_left = src_left - left
    dst_top = src_top - top
    if src_right > src_left and src_bottom > src_top:
        crop = resized.crop((src_left, src_top, src_right, src_bottom))
        canvas.paste(crop, (dst_left, dst_top))

    canvas_arr = np.array(canvas.convert('RGBA'))
    # Apply template's alpha channel (identical coin shape since it's a template clone)
    canvas_arr[:,:,3] = tmpl_alpha

    out_name = raw_name.replace('_new.png', '.png')
    out_path = f"{OUT}/{out_name}"
    Image.fromarray(canvas_arr, 'RGBA').save(out_path)
    print(f"{raw_name} -> {out_name}  scale={scale:.4f}  size={canvas_arr.shape}")

print("Done.")
