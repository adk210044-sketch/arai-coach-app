import numpy as np
from PIL import Image

def diff_stats(orig_path, colorized_path, bbox, name):
    orig = np.array(Image.open(orig_path).convert('RGBA')).astype(float)
    col = np.array(Image.open(colorized_path).convert('RGBA')).astype(float)
    H, W = orig.shape[0], orig.shape[1]
    x0,y0,x1,y1 = bbox

    diff = np.abs(orig - col).sum(axis=2)  # per-pixel sum over RGBA channels

    # Full mask for bbox region
    mask_in = np.zeros((H,W), dtype=bool)
    mask_in[y0:y1, x0:x1] = True
    mask_out = ~mask_in

    out_diff = diff[mask_out]
    in_diff = diff[mask_in]

    print(f"=== {name} ===")
    print(f"Image size: {W}x{H}, bbox: {bbox}")
    print(f"OUTSIDE bbox -> max diff: {out_diff.max():.2f}, mean diff: {out_diff.mean():.4f}, nonzero pixels(>1): {(out_diff>1).sum()}")
    print(f"INSIDE bbox  -> max diff: {in_diff.max():.2f}, mean diff: {in_diff.mean():.4f}, changed pixels(>5): {(in_diff>5).sum()} / {in_diff.size}")
    print()
    return diff, mask_in

# Trophy
diff_t, mask_t = diff_stats(
    '/home/user/flutter_app/assets/badges/vivid_trophy.png',
    'trophy_colorize_v3.png',
    (150,155,370,365),
    'TROPHY'
)

# Tanuki
diff_ta, mask_ta = diff_stats(
    '/home/user/flutter_app/assets/badges/vivid_tanuki.png',
    'tanuki_colorize_v3.png',
    (140,155,375,350),
    'TANUKI'
)
