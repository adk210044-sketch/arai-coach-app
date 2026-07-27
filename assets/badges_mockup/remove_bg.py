"""白背景除去+クロップ処理。四隅ピクセル平均色を背景として除去。
中央の空白プレートを誤って透過しないよう、画像境界に接続した連結成分のみ除去する。
"""
import sys
import numpy as np
from PIL import Image, ImageFilter
from scipy import ndimage


def remove_bg_and_crop(src_path, dst_path, tol=18, pad=20, blur_radius=2):
    img = Image.open(src_path).convert("RGB")
    arr = np.array(img).astype(np.int32)
    h, w, _ = arr.shape

    # 四隅ピクセル平均色を背景色として算出
    corner_size = 10
    corners = np.concatenate([
        arr[:corner_size, :corner_size].reshape(-1, 3),
        arr[:corner_size, -corner_size:].reshape(-1, 3),
        arr[-corner_size:, :corner_size].reshape(-1, 3),
        arr[-corner_size:, -corner_size:].reshape(-1, 3),
    ], axis=0)
    bg_color = corners.mean(axis=0)
    print(f"  bg_color estimated: {bg_color}")

    # 色距離で背景候補マスクを作成
    dist = np.sqrt(((arr - bg_color) ** 2).sum(axis=2))
    bg_candidate = dist < tol

    # 連結成分ラベリング、画像境界に接続したラベルのみ「本当の背景」として除去
    labeled, num_features = ndimage.label(bg_candidate)
    border_labels = set()
    border_labels.update(labeled[0, :].tolist())
    border_labels.update(labeled[-1, :].tolist())
    border_labels.update(labeled[:, 0].tolist())
    border_labels.update(labeled[:, -1].tolist())
    border_labels.discard(0)

    real_bg_mask = np.isin(labeled, list(border_labels))

    # アルファチャンネル作成(背景=0, 前景=255)
    alpha = np.where(real_bg_mask, 0, 255).astype(np.uint8)
    alpha_img = Image.fromarray(alpha, mode="L")
    alpha_img = alpha_img.filter(ImageFilter.GaussianBlur(blur_radius))

    rgba = img.convert("RGBA")
    rgba.putalpha(alpha_img)

    # バウンディングボックス+パディングで自動クロップ
    alpha_arr = np.array(alpha_img)
    ys, xs = np.where(alpha_arr > 10)
    if len(ys) == 0:
        print("  WARNING: no foreground detected!")
        rgba.save(dst_path)
        return
    y0, y1 = max(0, ys.min() - pad), min(h, ys.max() + pad)
    x0, x1 = max(0, xs.min() - pad), min(w, xs.max() + pad)
    cropped = rgba.crop((x0, y0, x1, y1))
    cropped.save(dst_path)
    print(f"  saved {dst_path} size={cropped.size}")


if __name__ == "__main__":
    pairs = [
        ("variant_laurel_light.png", "variant_laurel_light_clean.png"),
        ("variant_laurel_silver.png", "variant_laurel_silver_clean.png"),
    ]
    for src, dst in pairs:
        print(f"Processing {src} -> {dst}")
        remove_bg_and_crop(src, dst)
