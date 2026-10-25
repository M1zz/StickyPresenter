#!/usr/bin/env python3
"""마케팅 스크린샷 목업 생성: HTML 생성 → 헤드리스 Chrome 렌더링.

슬라이드마다 layout 이 달라 배치가 다양함:
  hero-bleed  : 헤드라인 상단 중앙 + 정면 대형 폰, 하단 블리드
  left-text   : 좌측 정렬 텍스트 + 오른쪽으로 기운 폰
  text-bottom : 폰 상단 + 텍스트 하단
  flat-rotate : 평면 회전(-5°) 폰, 하단 블리드
  dark        : 다크 배경 반전 + 정면 폰
"""
import subprocess, sys, pathlib

# 리모컨 앱(StickyPresenterRemote) 제출본. 사용법: python3 scripts/make_marketing_screenshots.py [로케일 ...]
#   원본: docs/screenshots/raw/<로케일>/NN-….png  (시뮬레이터 6.9" 캡처, 그 언어 화면)
#   제출: docs/screenshots/marketing/<로케일>/NN-….png  (1242x2688, DeployBar 가 올린다)
# 원본은 Mac 이 붙어 있어야 화면이 차므로, 실제 Mac 앱(또는 같은 규약을 말하는 가짜 호스트)과 연결해 찍는다.
ROOT = pathlib.Path(__file__).resolve().parent.parent
RAW = ROOT / "docs" / "screenshots" / "raw"
OUTROOT = ROOT / "docs" / "screenshots" / "marketing"
WORK = pathlib.Path("/tmp")
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"
W, H = 1242, 2688   # 이 계정의 아이폰 제출 규격

# 헤드라인은 언어마다 따로 쓴다(직역 금지) — 원문은 scripts/store_copy.py 한 곳에 둔다.
# 리모컨은 타이머만 다룬다 - 슬라이드 넘기기는 없다.
sys.path.insert(0, str(pathlib.Path(__file__).resolve().parent))
from store_copy import SHOT_FILES, SHOTS as COPY
SHOTS = {loc: [(f, layout, h, sub) for (f, layout), (h, sub) in zip(SHOT_FILES, texts)]
         for loc, texts in COPY.items()}

BASE_CSS = f"""
* {{ margin:0; padding:0; box-sizing:border-box; }}
html,body {{ width:{W}px; height:{H}px; overflow:hidden; }}
body {{ background:#faf8f4; font-family:-apple-system, "Apple SD Gothic Neo", sans-serif; position:relative; }}
.headline {{ font-size:96px; font-weight:800; color:#1c1c1e; letter-spacing:-2px; line-height:1.18; word-break:keep-all; }}
.headline, .sub {{ white-space:nowrap; }}
.sub {{ font-size:48px; font-weight:500; color:#6b6b70; letter-spacing:-1px; line-height:1.35; word-break:keep-all; }}
.phone {{ background:#17171a; border-radius:116px; border:3px solid #3a3a3e; padding:25px;
  box-shadow: 60px 90px 120px rgba(0,0,0,.28), 20px 30px 50px rgba(0,0,0,.18); }}
.phone img {{ width:100%; display:block; border-radius:92px; }}
"""

LAYOUTS = {
    # 1) 정면 대형, 하단 블리드
    "hero-bleed": """
.headline { text-align:center; margin-top:290px; padding:0 70px; }
.sub { text-align:center; margin-top:52px; }
.wrap { display:flex; justify-content:center; margin-top:150px; }
.phone { width:1000px; }
""",
    # 2) 좌측 정렬 텍스트 + 오른쪽 기울기, 오른쪽 블리드
    "left-text": """
.headline { text-align:left; margin:300px 0 0 110px; padding-right:70px; }
.sub { text-align:left; margin:48px 0 0 114px; padding-right:70px; }
.wrap { perspective:2600px; perspective-origin:30% 30%; position:absolute; left:300px; top:990px; }
.phone { width:840px; transform:rotateY(16deg) rotateX(2deg); }
""",
    # 3) 폰 상단, 텍스트 하단
    "text-bottom": """
.wrap { perspective:2800px; perspective-origin:50% 40%; display:flex; justify-content:center; margin-top:170px; }
.phone { width:880px; transform:rotateY(-10deg) rotateX(2deg); }
.headline { text-align:center; margin-top:120px; padding:0 70px; }
.sub { text-align:center; margin-top:48px; }
""",
    # 4) 평면 회전, 좌측 치우침 + 하단 블리드
    "flat-rotate": """
.headline { text-align:center; margin-top:270px; padding:0 70px; }
.sub { text-align:center; margin-top:52px; }
.wrap { position:absolute; left:120px; top:1010px; }
.phone { width:1010px; transform:rotate(-6deg); }
""",
    # 5) 다크 배경 반전 + 정면
    "dark": """
body { background:#131316; }
.headline { color:#f5f5f7; text-align:center; margin-top:290px; padding:0 70px; }
.sub { color:#77777d; text-align:center; margin-top:52px; }
.wrap { display:flex; justify-content:center; margin-top:150px; }
.phone { width:930px; border-color:#48484e;
  box-shadow: 0 0 160px rgba(80,140,255,.22), 40px 70px 110px rgba(0,0,0,.55); }
""",
}

# text-bottom 은 폰이 먼저 오는 DOM 순서
BODY_TEXT_FIRST = '<div class="headline">{headline}</div><div class="sub">{sub}</div><div class="wrap"><div class="phone"><img src="{img}"></div></div>'
BODY_PHONE_FIRST = '<div class="wrap"><div class="phone"><img src="{img}"></div></div><div class="headline">{headline}</div><div class="sub">{sub}</div>'

HTML = """<!doctype html><html lang="{lang}"><head><meta charset="utf-8"><style>
{base}{layout}
</style></head><body>{body}
<script>
// 독일어·그리스어처럼 긴 말은 한 줄이 화면을 넘는다. 줄을 더 쪼개지 않고 글자를 줄인다.
for (const el of document.querySelectorAll('.headline, .sub')) {{
  let size = parseFloat(getComputedStyle(el).fontSize);
  while (el.scrollWidth > el.clientWidth && size > 24) {{ size -= 2; el.style.fontSize = size + 'px'; }}
}}
</script></body></html>"""

def main(only=None):
    for loc, shots in SHOTS.items():
        if only and loc not in only:
            continue
        out = OUTROOT / loc
        out.mkdir(parents=True, exist_ok=True)
        for fname, layout, headline, sub in shots:
            body_tpl = BODY_PHONE_FIRST if layout == "text-bottom" else BODY_TEXT_FIRST
            body = body_tpl.format(headline=headline, sub=sub, img=(RAW / loc / fname).as_uri())
            html_path = WORK / f"sp-remote-{loc}-{fname.replace('.png', '.html')}"
            html_path.write_text(HTML.format(lang=loc, base=BASE_CSS, layout=LAYOUTS[layout], body=body),
                                 encoding="utf-8")
            out_png = out / fname
            # 다른 Chrome 이 떠 있으면 가끔 그리지 못하고 끝난다. 몇 번 다시 한다.
            for _ in range(4):
                try:
                    r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                                        f"--window-size={W},{H}", "--force-device-scale-factor=1",
                                        "--hide-scrollbars", "--disable-gpu", "--virtual-time-budget=2000",
                                        "--allow-file-access-from-files", html_path.as_uri()],
                                       capture_output=True, timeout=90)
                except subprocess.TimeoutExpired:
                    continue
                if r.returncode == 0:
                    break
            else:
                raise SystemExit(f"Chrome 이 그리지 못했다: {out_png}")
            print(f"rendered {out_png}")

if __name__ == "__main__":
    main(sys.argv[1:] or None)
