import numpy as np
from PIL import Image, ImageFilter, ImageDraw
from scipy import ndimage
import colorsys

def get_keep_mask(image_path, bbox, ratio_thresh=0.68, blur_radius=10, center_dist_thresh=60):
    orig = Image.open(image_path).convert('RGBA')
    o = np.array(orig).astype(float)
    H, W = o.shape[0], o.shape[1]
    cy, cx = H/2, W/2
    r_full,g_full,b_full = o[:,:,0], o[:,:,1], o[:,:,2]
    lum_full = 0.299*r_full + 0.587*g_full + 0.114*b_full
    lum_img_full = Image.fromarray(np.clip(lum_full,0,255).astype(np.uint8))
    local_mean_full = np.array(lum_img_full.filter(ImageFilter.GaussianBlur(blur_radius))).astype(float)
    ratio_full = lum_full / (local_mean_full + 1e-5)
    groove_hard = ratio_full < ratio_thresh
    labeled, num = ndimage.label(groove_hard, structure=np.ones((3,3)))
    x0,y0,x1,y1 = bbox
    keep_mask = np.zeros((H,W), dtype=bool)
    for i in range(1, num+1):
        ys, xs = np.where(labeled==i)
        if len(ys) < 3:
            continue
        cyi, cxi = ys.mean(), xs.mean()
        dist = ((cyi-cy)**2+(cxi-cx)**2)**0.5
        overlap = ((xs>=x0)&(xs<x1)&(ys>=y0)&(ys<y1)).mean()
        if dist < center_dist_thresh and overlap > 0.3:
            keep_mask[ys,xs] = True
    return keep_mask, orig

for name, path, bbox, thresh in [
    ('trophy', '/home/user/flutter_app/assets/badges/vivid_trophy.png', (150,155,370,365), 95),
    ('tanuki', '/home/user/flutter_app/assets/badges/vivid_tanuki.png', (140,155,375,350), 115),
]:
    keep_mask, orig = get_keep_mask(path, bbox, center_dist_thresh=thresh)
    mask_vis = Image.fromarray((keep_mask*255).astype(np.uint8)).convert('RGB')
    orig_rgb = orig.convert('RGB')
    overlay = Image.blend(orig_rgb, Image.new('RGB', orig_rgb.size, 'red'), 0.0)
    overlay_arr = np.array(orig_rgb).copy()
    overlay_arr[keep_mask] = [255, 0, 0]
    overlay_img = Image.fromarray(overlay_arr)
    canvas = Image.new('RGB', (1040, 520), 'white')
    canvas.paste(mask_vis, (0,0))
    canvas.paste(overlay_img, (520,0))
    canvas.save(f'{name}_keepmask_check.png')
    print(f"{name}: keep_mask pixel count = {keep_mask.sum()}")
