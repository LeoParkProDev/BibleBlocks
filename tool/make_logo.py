"""BibleBlocks 로고/아이콘 생성 — logo_v7.html 갤러리 #44 채택안.
E5 변형(아이소 5층 블록 3/5 채움 + 좌측 골드 진척 게이지 + 커버/십자가) × 딥와인 팔레트.
logo_v7.html의 SVG 지오메트리를 그대로 포팅한 뒤 헤드리스 크롬으로 래스터화 —
갤러리에서 본 것과 동일한 렌더링 보장. 사용: python3 tool/make_logo.py"""
import os
import subprocess
import tempfile

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
CHROME = '/Applications/Google Chrome.app/Contents/MacOS/Google Chrome'
RASTER = 2048          # 크롬 래스터 크기 (1024로 다운스케일해 AA 품질 확보)
OUT = 1024

# --- 딥와인 팔레트 (logo_v7.html PAL[3] 'wine') ---
BG = ('#260c14', '#451826')
GLOW = '#5e2233'
COVER = ('#9c3a4c', '#7d2a3a', '#5e1d2a')
PAGE = ('#f3e7cd', '#e6d2ab', '#d3bb8c')
GOLD = '#eec559'
GOLD_D = '#b3852a'
SHADOW = 'rgba(0,0,0,.42)'
CROSS = '#f3d06a'
EMPTY = '#5a2433'

# --- E5 지오메트리 (logo_v7.html과 동일) ---
R, S, U = 0.866, 0.5, 12.4
W, D, LAYERS, LH, GAP = 3.4, 2.3, 5, 0.22, 0.045
FILLED = 3                                   # stage 0.6 → 3/5 채움
TOP_Z = LAYERS * (LH + GAP)
COVER_T = 0.30
HC = TOP_Z + COVER_T
OX = 50 - ((W / 2 - D / 2) * R * U)
OY = 58 - ((W / 2 + D / 2) * S * U - HC * U)


def P(x, y, z):
    return (OX + (x - y) * R * U, OY + (x + y) * S * U - z * U)


def poly(pts, fill, extra=''):
    p = ' '.join(f'{a:.2f},{b:.2f}' for a, b in pts)
    return f'<polygon points="{p}" fill="{fill}" {extra}/>'


def box(x, y, z0, dx, dy, z1, top, left, right, extra=''):
    t = [P(x, y, z1), P(x + dx, y, z1), P(x + dx, y + dy, z1), P(x, y + dy, z1)]
    l = [P(x, y + dy, z1), P(x, y + dy, z0), P(x + dx, y + dy, z0), P(x + dx, y + dy, z1)]
    r = [P(x + dx, y, z1), P(x + dx, y, z0), P(x + dx, y + dy, z0), P(x + dx, y + dy, z1)]
    return poly(l, left, extra) + poly(r, right, extra) + poly(t, top, extra)


def box_filled(x, y, z0, dx, dy, z1, gold_edge):
    s = box(x, y, z0, dx, dy, z1, PAGE[0], PAGE[2], PAGE[1])
    if gold_edge:
        a, b, c = P(x + dx, y, z1), P(x + dx, y + dy, z1), P(x, y + dy, z1)
        pts = f'{a[0]:.1f},{a[1]:.1f} {b[0]:.1f},{b[1]:.1f} {c[0]:.1f},{c[1]:.1f}'
        s += f'<polyline points="{pts}" fill="none" stroke="{GOLD}" stroke-width="1" opacity=".85"/>'
    return s


def box_empty(x, y, z0, dx, dy, z1, gold_stroke):
    t = [P(x, y, z1), P(x + dx, y, z1), P(x + dx, y + dy, z1), P(x, y + dy, z1)]
    l = [P(x, y + dy, z1), P(x, y + dy, z0), P(x + dx, y + dy, z0), P(x + dx, y + dy, z1)]
    r = [P(x + dx, y, z1), P(x + dx, y, z0), P(x + dx, y + dy, z0), P(x + dx, y + dy, z1)]
    stroke = GOLD if gold_stroke else PAGE[2]
    sw, op = (1.1, '.95') if gold_stroke else (0.9, '.8')
    s = poly(t, EMPTY, 'opacity=".55"') + poly(l, EMPTY, 'opacity=".75"') + poly(r, EMPTY, 'opacity=".65"')
    e = f'stroke="{stroke}" stroke-width="{sw}" stroke-linejoin="round" opacity="{op}"'
    return s + poly(l, 'none', e) + poly(r, 'none', e) + poly(t, 'none', e)


def iso_cross(cx, cy, z, length, t, fill, extra=''):
    a = t / 2
    g = [(cx - a, cy - length), (cx + a, cy - length), (cx + a, cy - a), (cx + length, cy - a),
         (cx + length, cy + a), (cx + a, cy + a), (cx + a, cy + length), (cx - a, cy + length),
         (cx - a, cy + a), (cx - length, cy + a), (cx - length, cy - a), (cx - a, cy - a)]
    return poly([P(px, py, z) for px, py in g], fill, extra)


def mark():
    """배경 제외 마크 전체 — 그림자·블록 스택·게이지·커버·십자가."""
    s = ''
    # 바닥 그림자
    base = [P(-0.25, D + 0.25, 0), P(W + 0.25, D + 0.25, 0), P(W + 0.25, -0.25, 0), P(-0.25, -0.25, 0)]
    s += poly([(x, y + 3.0) for x, y in base], SHADOW)
    # 5층 블록 (3 채움 / 2 빈칸, 다음 칸은 골드 스트로크)
    for i in range(LAYERS):
        z0 = i * (LH + GAP)
        z1 = z0 + LH
        if i < FILLED:
            s += box_filled(0, 0, z0, W, D, z1, i == FILLED - 1)
        else:
            s += box_empty(0, 0, z0, W, D, z1, i == FILLED)
    # 좌측 진척 게이지 (3/5 골드)
    gx, gy_b, gh, gw = 12, 72, 40, 5
    s += (f'<rect x="{gx}" y="{gy_b - gh}" width="{gw}" height="{gh}" rx="2.5" '
          f'fill="{EMPTY}" fill-opacity=".55" stroke="{PAGE[2]}" stroke-width=".8" stroke-opacity=".6"/>')
    fh = gh * FILLED / LAYERS
    s += f'<rect x="{gx}" y="{gy_b - fh}" width="{gw}" height="{fh}" rx="2.5" fill="{GOLD}" filter="url(#cg)"/>'
    # 커버 + 윗면 골드 테두리
    s += box(-0.10, -0.10, TOP_Z, W + 0.20, D + 0.20, HC, COVER[0], COVER[2], COVER[1])
    tp = [P(-0.10, -0.10, HC), P(W + 0.10, -0.10, HC), P(W + 0.10, D + 0.10, HC), P(-0.10, D + 0.10, HC)]
    s += poly(tp, 'none', f'stroke="{GOLD}" stroke-width=".7" opacity=".55"')
    # 입체 십자가 (골드다크 베이스 + 글로우 골드)
    s += iso_cross(W / 2, D / 2, HC, 0.95, 0.46, GOLD_D)
    s += iso_cross(W / 2, D / 2, HC + 0.16, 0.95, 0.46, CROSS, 'filter="url(#cg)"')
    return s


DEFS = (f'<defs>'
        f'<linearGradient id="g" x1="0" y1="0" x2="0" y2="1">'
        f'<stop offset="0" stop-color="{BG[0]}"/><stop offset="1" stop-color="{BG[1]}"/></linearGradient>'
        f'<radialGradient id="r" cx="50%" cy="40%" r="60%">'
        f'<stop offset="0" stop-color="{GLOW}" stop-opacity=".95"/>'
        f'<stop offset="100%" stop-color="{GLOW}" stop-opacity="0"/></radialGradient>'
        f'<filter id="cg" x="-60%" y="-60%" width="220%" height="220%">'
        f'<feGaussianBlur stdDeviation=".9" result="b"/>'
        f'<feMerge><feMergeNode in="b"/><feMergeNode in="SourceGraphic"/></feMerge></filter>'
        f'</defs>')


def svg(inner):
    return (f'<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 100 100" '
            f'width="{RASTER}" height="{RASTER}">{DEFS}{inner}</svg>')


def rasterize(svg_str, out_png):
    with tempfile.NamedTemporaryFile('w', suffix='.svg', delete=False) as f:
        f.write(svg_str)
        path = f.name
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    f'--screenshot={out_png}', f'--window-size={RASTER},{RASTER}',
                    '--default-background-color=00000000', f'file://{path}'],
                   check=True, capture_output=True)
    os.unlink(path)


def main():
    icon_path = os.path.join(ROOT, 'assets/icon/icon.png')
    fg_path = os.path.join(ROOT, 'assets/icon/icon_foreground.png')
    with tempfile.TemporaryDirectory() as tmp:
        # 1) 풀블리드 아이콘: 와인 그라데이션 배경 + 글로우 + 마크 (플랫폼이 코너 마스킹)
        full = f'<rect width="100" height="100" fill="url(#g)"/><rect width="100" height="100" fill="url(#r)"/>{mark()}'
        raw = os.path.join(tmp, 'icon.png')
        rasterize(svg(full), raw)
        Image.open(raw).convert('RGBA').resize((OUT, OUT), Image.LANCZOS).save(icon_path)
        # 2) 적응형/로그인용 전경: 투명 배경에 마크만 → 안전영역(약 66%)에 맞춰 중앙 배치
        raw_fg = os.path.join(tmp, 'fg.png')
        rasterize(svg(mark()), raw_fg)
        m = Image.open(raw_fg).convert('RGBA')
        m = m.crop(m.getbbox())
        safe = 660
        scale = min(safe / m.width, safe / m.height)
        m = m.resize((round(m.width * scale), round(m.height * scale)), Image.LANCZOS)
        fg = Image.new('RGBA', (OUT, OUT), (0, 0, 0, 0))
        fg.paste(m, ((OUT - m.width) // 2, (OUT - m.height) // 2), m)
        fg.save(fg_path)
    print(f'생성 완료: {icon_path}, {fg_path}')


if __name__ == '__main__':
    main()
