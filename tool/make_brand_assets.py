"""BibleBlocks 브랜드 에셋 생성 — 딥와인 브랜딩.
make_logo.py의 mark()/팔레트를 그대로 재사용해 두 에셋을 재제작한다.
  1) web/share_card.png         768×1216  카카오톡 공유 카드 (세로형)
  2) assets/feature_graphic.png 1024×500  Google Play 피처 그래픽 (가로형)
렌더링 방식은 make_logo.py와 동일 —
  SVG 문자열 생성 → 헤드리스 크롬 래스터화(투명 배경) → PIL LANCZOS 다운스케일.
2x 고해상도로 래스터 후 목표 크기로 줄여 AA 품질 확보. 사용: python3 tool/make_brand_assets.py"""
import os
import subprocess
import sys
import tempfile

from PIL import Image

# make_logo.py의 mark()/팔레트/DEFS를 동일 디렉터리에서 import (sys.path 조작)
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import make_logo as ml  # noqa: E402

ROOT = ml.ROOT
CHROME = ml.CHROME
SCALE = 2  # 2x 고해상도 래스터 후 다운스케일

# --- 딥와인 팔레트 (make_logo.py에서 재사용) ---
BG = ml.BG            # ('#260c14', '#451826') — 배경 그라데이션 세로
GLOW = ml.GLOW        # '#5e2233' — 라디얼 글로우
GOLD = ml.GOLD        # '#eec559'
PAGE = ml.PAGE        # ('#f3e7cd', ...) — 아이보리 텍스트 톤
INK = PAGE[0]         # 제목 아이보리 #f3e7cd
INK_SUB = '#e6c9b8'   # 보조 텍스트 — 살짝 낮춘 따뜻한 톤
INK_MUTE = '#c79aa1'  # 캡션 — 더 낮춘 와인-로즈 톤

FONT = '\'Apple SD Gothic Neo\', \'Noto Sans KR\', sans-serif'

# 카피 (두 에셋 공통)
TITLE = '바이블블록'
SUB = '체크할수록 완성되는 3D 성경책'
CAP = '66권 1,189장 읽기 시각화'


def bg_defs(w, h):
    """캔버스 크기에 맞춘 배경 그라데이션 + 라디얼 글로우 + 글로우 필터 정의."""
    return (f'<defs>'
            f'<linearGradient id="bg" x1="0" y1="0" x2="0" y2="1">'
            f'<stop offset="0" stop-color="{BG[0]}"/><stop offset="1" stop-color="{BG[1]}"/>'
            f'</linearGradient>'
            f'<radialGradient id="glow" gradientUnits="userSpaceOnUse" '
            f'cx="{GLOW_CX}" cy="{GLOW_CY}" r="{GLOW_R}">'
            f'<stop offset="0" stop-color="{GLOW}" stop-opacity=".85"/>'
            f'<stop offset="100%" stop-color="{GLOW}" stop-opacity="0"/>'
            f'</radialGradient>'
            f'</defs>')


def mark_group(cx, cy, size):
    """make_logo.mark() (viewBox 0..100)를 (cx,cy) 중심·size 폭으로 배치.
    마크는 viewBox 100 좌표계에서 그려지므로 중첩 <svg>로 스케일·이동한다."""
    x = cx - size / 2
    y = cy - size / 2
    return (f'<svg x="{x:.2f}" y="{y:.2f}" width="{size:.2f}" height="{size:.2f}" '
            f'viewBox="0 0 100 100">{ml.DEFS}{ml.mark()}</svg>')


def text_el(x, y, txt, fs, weight, fill, anchor='start', ls='0', op='1'):
    return (f'<text x="{x}" y="{y}" font-family="{FONT}" font-size="{fs}" '
            f'font-weight="{weight}" fill="{fill}" text-anchor="{anchor}" '
            f'letter-spacing="{ls}" opacity="{op}" '
            f'style="dominant-baseline:alphabetic">{txt}</text>')


def rasterize(svg_str, out_png, w, h):
    """헤드리스 크롬으로 SVG를 PNG 래스터화 (투명 배경)."""
    with tempfile.NamedTemporaryFile('w', suffix='.svg', delete=False) as f:
        f.write(svg_str)
        path = f.name
    subprocess.run([CHROME, '--headless=new', '--disable-gpu', '--hide-scrollbars',
                    f'--screenshot={out_png}', f'--window-size={w},{h}',
                    '--force-device-scale-factor=1',
                    '--default-background-color=00000000', f'file://{path}'],
                   check=True, capture_output=True)
    os.unlink(path)


def build(svg_w, svg_h, inner):
    """배경(그라데이션+글로우) 위에 inner를 얹은 풀 SVG."""
    return (f'<svg xmlns="http://www.w3.org/2000/svg" '
            f'width="{svg_w}" height="{svg_h}" viewBox="0 0 {svg_w} {svg_h}">'
            f'{bg_defs(svg_w, svg_h)}'
            f'<rect width="{svg_w}" height="{svg_h}" fill="url(#bg)"/>'
            f'<rect width="{svg_w}" height="{svg_h}" fill="url(#glow)"/>'
            f'{inner}</svg>')


# 글로우 좌표는 bg_defs에서 참조 — 에셋별로 main()에서 갱신
GLOW_CX = GLOW_CY = GLOW_R = 0


def make_share_card():
    """768×1216 세로형 공유 카드 — 상단 마크 크게 + 중앙/하단 카피."""
    global GLOW_CX, GLOW_CY, GLOW_R
    W, H = 768, 1216
    sw, sh = W * SCALE, H * SCALE
    # 글로우: 마크 뒤 상단 중앙
    GLOW_CX, GLOW_CY, GLOW_R = sw / 2, sh * 0.34, sw * 0.62

    cx = sw / 2
    mark_size = sw * 0.66
    mark_cy = sh * 0.345
    inner = mark_group(cx, mark_cy, mark_size)

    # 텍스트 블록 (마크 아래)
    ty = sh * 0.665
    inner += text_el(cx, ty, TITLE, fs=int(112 * SCALE), weight=800,
                     fill=INK, anchor='middle', ls='2')
    inner += text_el(cx, ty + 86 * SCALE, SUB, fs=int(40 * SCALE), weight=600,
                     fill=INK_SUB, anchor='middle', ls='0.5')
    inner += text_el(cx, ty + 150 * SCALE, CAP, fs=int(33 * SCALE), weight=500,
                     fill=INK_MUTE, anchor='middle', ls='0.5')

    out = os.path.join(ROOT, 'web/share_card.png')
    with tempfile.TemporaryDirectory() as tmp:
        raw = os.path.join(tmp, 'share.png')
        rasterize(build(sw, sh, inner), raw, sw, sh)
        Image.open(raw).convert('RGBA').resize((W, H), Image.LANCZOS).save(out)
    return out, (W, H)


def make_feature_graphic():
    """1024×500 가로형 피처 그래픽 — 좌측 카피 + 우측 마크 (기존 구도 유지)."""
    global GLOW_CX, GLOW_CY, GLOW_R
    W, H = 1024, 500
    sw, sh = W * SCALE, H * SCALE
    # 글로우: 우측 마크 뒤
    GLOW_CX, GLOW_CY, GLOW_R = sw * 0.79, sh * 0.5, sh * 0.85

    # 우측 마크
    mark_cx = sw * 0.79
    mark_cy = sh * 0.5
    mark_size = sh * 0.92
    inner = mark_group(mark_cx, mark_cy, mark_size)

    # 좌측 텍스트 (세로 중앙 정렬 느낌으로 배치)
    tx = sw * 0.06
    inner += text_el(tx, sh * 0.40, TITLE, fs=int(92 * SCALE), weight=800,
                     fill=INK, anchor='start', ls='1')
    inner += text_el(tx + 4 * SCALE, sh * 0.555, SUB, fs=int(36 * SCALE), weight=600,
                     fill=INK_SUB, anchor='start', ls='0.5')
    inner += text_el(tx + 4 * SCALE, sh * 0.665, CAP, fs=int(31 * SCALE), weight=500,
                     fill=INK_MUTE, anchor='start', ls='0.5')

    out = os.path.join(ROOT, 'assets/feature_graphic.png')
    with tempfile.TemporaryDirectory() as tmp:
        raw = os.path.join(tmp, 'fg.png')
        rasterize(build(sw, sh, inner), raw, sw, sh)
        Image.open(raw).convert('RGBA').resize((W, H), Image.LANCZOS).save(out)
    return out, (W, H)


def main():
    p1, s1 = make_share_card()
    p2, s2 = make_feature_graphic()
    print(f'생성 완료: {p1} {s1[0]}x{s1[1]}')
    print(f'생성 완료: {p2} {s2[0]}x{s2[1]}')


if __name__ == '__main__':
    main()
