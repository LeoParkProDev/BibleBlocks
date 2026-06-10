"""BibleBlocks 로고/아이콘 생성 — 아이소메트릭 성경책 + 골드 십자가 + 부유 블록.
브랜드: 테라코타(#C47B5A) 커버, 골드(#D4A843) 십자가/블록, 다크 네이비(#0a0a1a) 배경.
4x 슈퍼샘플링 후 1024로 다운스케일.  사용: python3 tool/make_logo.py"""
import math
from PIL import Image, ImageDraw, ImageFilter

SS = 4
N = 1024 * SS
COS30, SIN30 = 0.866, 0.5
S = 60 * SS                      # iso unit(px)
OX, OY = N / 2, N / 2 - 18 * SS  # 원점(화면 중앙)

# --- 색상 ---
COVER_TOP = (210, 132, 96)
COVER_L = (150, 84, 58)
COVER_R = (178, 104, 74)
PAGE = (255, 248, 231)
PAGE_EDGE = (212, 168, 67)
GOLD = (212, 168, 67)
GOLD_HI = (245, 222, 140)
IVORY = (255, 248, 231)


def proj(x, y, z):
    return (OX + (x - y) * COS30 * S, OY + (x + y) * SIN30 * S - z * S)


def shade(c, f):
    return tuple(max(0, min(255, int(v * f))) for v in c)


def box(d, x, y, z, dx, dy, dz, ctop, cl, cr):
    p = {k: proj(*v) for k, v in {
        'tA': (x, y, z + dz), 'tB': (x + dx, y, z + dz),
        'tC': (x + dx, y + dy, z + dz), 'tD': (x, y + dy, z + dz),
        'lA': (x, y + dy, z), 'lB': (x + dx, y + dy, z),
        'rA': (x + dx, y, z), 'rB': (x + dx, y + dy, z),
    }.items()}
    # 왼쪽 면(y+dy), 오른쪽 면(x+dx), 윗면 순서로
    d.polygon([p['lA'], p['lB'], p['tC'], p['tD']], fill=cl)
    d.polygon([p['rA'], p['rB'], p['tC'], p['tB']], fill=cr)
    d.polygon([p['tA'], p['tB'], p['tC'], p['tD']], fill=ctop)


img = Image.new('RGBA', (N, N), (0, 0, 0, 0))
d = ImageDraw.Draw(img)

# 배경: 다크 네이비 + 따뜻한 라디얼 글로우 (정사각 풀블리드, 플랫폼이 마스킹)
d.rectangle([0, 0, N, N], fill=(10, 10, 26, 255))
glow = Image.new('RGBA', (N, N), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gr = int(N * 0.42)
gc = (OX, OY - 40 * SS)
for i in range(gr, 0, -SS * 3):
    a = int(60 * (1 - i / gr))
    gd.ellipse([gc[0] - i, gc[1] - i, gc[0] + i, gc[1] + i], fill=(196, 123, 90, a))
glow = glow.filter(ImageFilter.GaussianBlur(SS * 18))
img = Image.alpha_composite(img, glow)
d = ImageDraw.Draw(img)

# 바닥 그림자
sh = Image.new('RGBA', (N, N), (0, 0, 0, 0))
sd = ImageDraw.Draw(sh)
sc = proj(2.5, 3.0, 0)
sd.ellipse([sc[0] - 3.6 * S, sc[1] - 1.1 * S, sc[0] + 3.6 * S, sc[1] + 1.1 * S],
           fill=(0, 0, 0, 130))
sh = sh.filter(ImageFilter.GaussianBlur(SS * 9))
img = Image.alpha_composite(img, sh)
d = ImageDraw.Draw(img)

# 책 본체 (두꺼운 책, 가로로 누움)  x:0..5  y:0..6
W, D = 5.0, 6.0
# 아래쪽 페이지 더미(아이보리/골드 페이지 단면) → 그 위에 커버
box(d, 0.18, 0.18, 0.0, W - 0.36, D - 0.36, 0.6, IVORY,
    shade(PAGE_EDGE, 0.78), shade(PAGE_EDGE, 0.92))
box(d, 0.0, 0.0, 0.55, W, D, 1.0, COVER_TOP, COVER_L, COVER_R)

# 커버 윗면 골드 인셋 테두리 (프리미엄한 책 느낌)
tz = 1.55
inset = [proj(0.5, 0.5, tz), proj(W - 0.5, 0.5, tz),
         proj(W - 0.5, D - 0.5, tz), proj(0.5, D - 0.5, tz)]
d.line(inset + [inset[0]], fill=shade(GOLD, 0.95), width=int(0.07 * S), joint='curve')

# 윗면 골드 십자가 (화면공간, 입체 그림자 + 하이라이트) — 크고 중앙
cx, cy = proj(W / 2, D / 2, tz)
vw, vh = 0.46 * S, 1.85 * S   # 세로 기둥
hw, hh = 1.25 * S, 0.46 * S   # 가로 기둥
hy = cy - 0.34 * S            # 가로대(위쪽 1/3)
for off, col in [(0.12 * S, (0, 0, 0, 95)), (0, GOLD)]:
    d.rectangle([cx - vw / 2 + off, cy - vh / 2 + off,
                 cx + vw / 2 + off, cy + vh / 2 + off], fill=col)
    d.rectangle([cx - hw / 2 + off, hy - hh / 2 + off,
                 cx + hw / 2 + off, hy + hh / 2 + off], fill=col)
d.rectangle([cx - vw / 2, cy - vh / 2, cx - vw / 2 + 0.12 * S, cy + vh / 2], fill=GOLD_HI)
d.rectangle([cx - hw / 2, hy - hh / 2, cx + hw / 2, hy - hh / 2 + 0.1 * S], fill=GOLD_HI)

# 부유 블록 3개 — 오른쪽 위로 깔끔히 상승 ("블록이 채워진다")
blocks = [(5.4, 0.2, 1.9, GOLD), (6.0, -0.5, 2.8, IVORY), (6.6, -1.2, 3.7, GOLD)]
for bx, by, bz, col in sorted(blocks, key=lambda b: b[2]):
    box(d, bx, by, bz, 0.85, 0.85, 0.85, col, shade(col, 0.6), shade(col, 0.8))
# 최상단 골드 블록 글로우
gb = Image.new('RGBA', (N, N), (0, 0, 0, 0))
gbd = ImageDraw.Draw(gb)
tc = proj(6.6 + 0.42, -1.2 + 0.42, 3.7 + 0.85)
gbd.ellipse([tc[0] - 1.1 * S, tc[1] - 1.1 * S, tc[0] + 1.1 * S, tc[1] + 1.1 * S],
            fill=(212, 168, 67, 90))
gb = gb.filter(ImageFilter.GaussianBlur(SS * 10))
img = Image.alpha_composite(img, gb)
d = ImageDraw.Draw(img)

# 다운스케일
final = img.resize((1024, 1024), Image.LANCZOS)
final.save('assets/icon/icon.png')

# Android 적응형 아이콘 전경: 배경 투명, 안전영역(약 66%) 안에 마크만
fg = Image.new('RGBA', (1024, 1024), (0, 0, 0, 0))
# icon.png에서 배경 제외한 마크를 다시 그리기엔 복잡 → 전체를 축소해 중앙 배치(투명 캔버스)
mark = final.crop((150, 150, 874, 874)).resize((620, 620), Image.LANCZOS)
fg.paste(mark, (202, 202), mark)
fg.save('assets/icon/icon_foreground.png')
print('생성 완료: assets/icon/icon.png, icon_foreground.png')
