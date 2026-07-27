"""参考画像(SILVER/CVIVID ROYAL BLUE/R-SKY-BLUE)と全く同じ配色・彫刻処理で
アイコンを合成する。

方針:
- アイコンは「塗り」ではなく「線画(outlined)」を使う。参考画像のアイコンは
  すべて月桂冠と同じ色調のアウトラインで描かれている。
- 色は月桂冠から実測サンプリングした色(月桂冠と完全に同じ色)を使う。
- 彫刻処理も月桂冠のリーフと同じロジック: 線の輪郭に沿って左上=暗い影、
  右下=明るいハイライトのベベルを薄く入れる(浮き出しでも沈み込みでもない、
  ラインエングレービング)。
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
import numpy as np

FONT_PATH = "/opt/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf"

# アイコンコードポイント (material_fonts/codepoints の outlined 版 = 線画スタイル)
ICONS = {
    "local_fire_department": 0xF17A,
    "military_tech": 0xF1CD,
    "school": 0xF33C,
    "bolt": 0xEEDD,
    "emoji_events": 0xF01A,
    "menu_book": 0xF1C2,
}

# 月桂冠から実測サンプリングした色(このアイコン色をそのまま使う)
PALETTES = {
    "silver": {
        "color": (150, 150, 148),
        "edge_dark": (70, 72, 76),
        "edge_light": (255, 255, 255),
    },
    "light": {
        "color": (110, 160, 200),
        "edge_dark": (40, 80, 120),
        "edge_light": (225, 245, 255),
    },
    "vivid": {
        "color": (35, 65, 140),
        "edge_dark": (5, 15, 45),
        "edge_light": (150, 190, 235),
    },
}


def render_icon_mask(codepoint, size):
    """Material Icons フォントでグレースケールマスク(L mode)画像を生成。
    outlinedスタイルは線が細いため、少し太らせて視認性を確保する。
    """
    font_size = int(size * 1.05)
    font = ImageFont.truetype(FONT_PATH, font_size)
    canvas = Image.new("L", (size, size), 0)
    draw = ImageDraw.Draw(canvas)
    text = chr(codepoint)
    bbox = draw.textbbox((0, 0), text, font=font)
    tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
    x = (size - tw) / 2 - bbox[0]
    y = (size - th) / 2 - bbox[1]
    draw.text((x, y), text, font=font, fill=255)
    return canvas


def _edge_ring_mask(icon_mask, erode_px):
    """アイコンマスクを収縮させ、元マスクとの差分から輪郭リング(縁取り)マスクを作る。"""
    eroded = icon_mask.filter(ImageFilter.MinFilter(erode_px * 2 + 1))
    arr_outer = np.array(icon_mask, dtype=np.int16)
    arr_inner = np.array(eroded, dtype=np.int16)
    ring = np.clip(arr_outer - arr_inner, 0, 255).astype(np.uint8)
    return Image.fromarray(ring, mode="L")


def engrave_line_icon(icon_mask, palette, size, edge_alpha=210, blur=1.0):
    """線画アイコンを、月桂冠と同じ色+同じ彫刻(薄いベベル)で描く。"""
    color = palette["color"]

    # ベース: アイコン色の単色塗り(線画なので細い線のみ)
    base = Image.new("RGBA", (size, size), color + (255,))
    base.putalpha(icon_mask)

    # 輪郭に沿って左上=暗い影/右下=明るいハイライトの薄いベベルを入れる
    erode_px = max(1, size // 90)
    ring_mask = _edge_ring_mask(icon_mask, erode_px)
    ring_arr = np.array(ring_mask, dtype=np.float32) / 255.0

    yy, xx = np.mgrid[0:size, 0:size]
    diag = (xx - yy) / size
    top_edge_w = np.clip(diag, 0, 1)
    bottom_edge_w = np.clip(-diag, 0, 1)

    dark_alpha = (ring_arr * top_edge_w * edge_alpha).astype(np.uint8)
    light_alpha = (ring_arr * bottom_edge_w * edge_alpha).astype(np.uint8)

    dark_layer = Image.new("RGBA", (size, size), palette["edge_dark"] + (255,))
    dark_layer.putalpha(Image.fromarray(dark_alpha, mode="L"))
    light_layer = Image.new("RGBA", (size, size), palette["edge_light"] + (255,))
    light_layer.putalpha(Image.fromarray(light_alpha, mode="L"))

    dark_layer = dark_layer.filter(ImageFilter.GaussianBlur(blur))
    light_layer = light_layer.filter(ImageFilter.GaussianBlur(blur))

    result = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    result = Image.alpha_composite(result, base)
    result = Image.alpha_composite(result, dark_layer)
    result = Image.alpha_composite(result, light_layer)
    return result


def compose_medal_with_icon(medal_path, icon_name, palette_key, out_path,
                              icon_scale=0.47, y_offset_ratio=0.0,
                              stroke_boost=1.6):
    medal = Image.open(medal_path).convert("RGBA")
    mw, mh = medal.size
    icon_size = int(min(mw, mh) * icon_scale)

    icon_mask = render_icon_mask(ICONS[icon_name], icon_size)
    # outlinedスタイルは線が細いため、MaxFilterで少し太らせて視認性を上げる
    k = max(1, int(icon_size * 0.012))
    if k % 2 == 0:
        k += 1
    icon_mask = icon_mask.filter(ImageFilter.MaxFilter(k))

    icon_img = engrave_line_icon(icon_mask, PALETTES[palette_key], icon_size)

    canvas = medal.copy()
    cx = (mw - icon_size) // 2
    cy = (mh - icon_size) // 2 + int(mh * y_offset_ratio)
    canvas.alpha_composite(icon_img, (cx, cy))
    canvas.save(out_path)
    print(f"  saved {out_path}")


if __name__ == "__main__":
    combos = [
        ("variant_laurel_silver_clean.png", "silver", "military_tech", "final_silver.png"),
        ("variant_laurel_light_clean.png", "light", "local_fire_department", "final_light.png"),
        ("variant_laurel_clean.png", "vivid", "emoji_events", "final_vivid.png"),
    ]
    for medal_path, palette_key, icon_name, out_name in combos:
        print(f"Composing {out_name} ({palette_key} / {icon_name})")
        compose_medal_with_icon(medal_path, icon_name, palette_key, out_name)
