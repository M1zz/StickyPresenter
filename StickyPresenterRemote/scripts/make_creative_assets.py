#!/usr/bin/env python3
"""App Store 크리에이티브 자산(제품 페이지 헤더 · 검색 결과) 생성: HTML → 헤드리스 Chrome.

사용법: python3 scripts/make_creative_assets.py [언어 ...]     (없으면 전부)

자리
  docs/screenshots/creative/<스토어 로케일>/header.png   3840x1646  제품 페이지 맨 위
  docs/screenshots/creative/<스토어 로케일>/search.png   3840x2560  검색 결과 (없으면 스크린샷이 대신 보인다)

⚠️ 안전 영역 밖은 기기에 따라 잘린다. 글은 **반드시** 안전 영역 안에 둔다(배경 · 기기 그림은 넘쳐도 된다).
   수치는 Apple 공식 PSD 템플릿에서 잰 값이다(https://developer.apple.com/app-store/asset-best-practices/).
   아이폰에서 헤더는 가운데만 남고, 검색 결과는 약 385pt 폭으로 줄어 보인다. 그래서 글이 크다.

⚠️ 가격 · 할인 · 주소(URL) · 수상 · 다른 플랫폼 이름은 넣지 않는다(Apple 가이드).
"""
import subprocess, sys, pathlib, tempfile

ROOT = pathlib.Path(__file__).resolve().parent.parent   # 리모컨 앱 폴더 (DeployBar 의 앱 경로)
RAW = ROOT / "docs" / "screenshots" / "raw" / "creative"
OUT = ROOT / "docs" / "screenshots" / "creative"
ICON = ROOT / "Sources" / "Assets.xcassets" / "AppIcon.appiconset" / "icon_1024.png"
CHROME = "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome"

# 앱 언어 코드 → App Store Connect 로케일 (deploy.env LOCALES=ko,en-US)
STORE = {"en": "en-US"}

# ⚠️ 리모컨 화면은 한국어로만 그려진다(Sources/RemoteApp.swift 에 문구가 박혀 있다).
#    영어 그림에 한국어 화면을 넣으면 글자가 섞이므로, 영어는 기기 화면 대신
#    앱 아이콘과 Mac 위젯 모양(숫자만)으로 꾸민다. 앱이 영어를 갖추면 캡처를 넣고 이 표를 지운다.
DEVICE_LANGS = {"ko"}

# (가로, 세로, 안전 영역 left, top, right, bottom)
SPEC = {
    "header": (3840, 1646, (1097, 493, 2743, 1154)),
    "search": (3840, 2560, (836, 765, 3004, 1795)),
}

# 검색 결과: 눈썹글은 그 나라 사람이 검색창에 칠 말. 앱의 약속은 하나다 -
# 발표 중 손이 닿지 않는 Mac 의 타이머를 iPhone 에서 다룬다(리모컨은 타이머만 다룬다, 슬라이드 넘기기는 없다).
SEARCH = {
    "ko": ("발표 타이머 리모컨", "발표 타이머를<br>iPhone으로", "시작·일시정지, 30초 더하기까지<br>Mac에 손대지 않고"),
    "en": ("Presentation timer", "Run your talk timer<br>from your iPhone", "Start, pause, add 30 seconds<br>without touching your Mac"),
}

# 헤더: 처음 온 사람에게 한 가지 약속.
HEADER = {
    "ko": ("Mac 발표 리모컨", "Mac은 멀리 두고<br>타이머는 손안에"),
    "en": ("Remote for your Mac talks", "Your Mac stays put.<br>The timer's in your hand."),
}

# ⚠️ 바탕 · 글자색은 기존 스크린샷(make_marketing_screenshots.py)과 같다. 다르면 페이지에서
#    헤더만 남의 앱처럼 보인다.
BASE_CSS = """
* { margin:0; padding:0; box-sizing:border-box; }
html,body { width:%(W)dpx; height:%(H)dpx; overflow:hidden; }
body { background:#faf8f4; position:relative;
  font-family:-apple-system, "SF Pro Display", "Apple SD Gothic Neo", sans-serif; }
.glow { position:absolute; border-radius:50%%; filter:blur(160px); pointer-events:none; }
.text { position:absolute; display:flex; flex-direction:column; justify-content:center; }
.eyebrow { font-weight:700; color:#e07b00; letter-spacing:-0.01em; line-height:1.15; }
.headline { font-weight:800; color:#1c1c1e; letter-spacing:-0.03em; line-height:1.12; text-wrap:balance; }
.sub { font-weight:500; color:#6b6b70; letter-spacing:-0.01em; line-height:1.35; text-wrap:balance; }
/* 한국어는 낱말 중간에서 끊지 않는다. */
:lang(ko) .headline, :lang(ko) .sub, :lang(ko) .eyebrow { word-break:keep-all; }
.phone { position:absolute; background:#1c1c1e; border:6px solid #3a3a3c; padding:40px; border-radius:190px;
  box-shadow: 0 60px 140px rgba(120,70,0,.22), 0 0 0 2px #2c2c2e inset; }
.phone img { width:100%%; display:block; border-radius:152px; }
.icon { position:absolute; border-radius:22.5%%; box-shadow:0 50px 120px rgba(224,123,0,.28); }
/* Mac 쪽 타이머 위젯 모양 - 바깥 고리가 진행률, 가운데는 숫자만(언어 없음). */
.widget { position:absolute; border-radius:22%%;
  box-shadow:0 50px 120px rgba(60,40,0,.18); }
.widget .face { width:100%%; height:100%%; border-radius:18%%; background:#ffffff; display:flex;
  align-items:center; justify-content:center; font-weight:700; color:#1c1c1e;
  font-family:"SF Pro Rounded", -apple-system, sans-serif; font-variant-numeric:tabular-nums; letter-spacing:-0.02em; }
.dot { position:absolute; border-radius:50%%; background:#ffcf40; opacity:.35; }
"""

# 글이 상자를 넘지 않을 때까지 줄인다. 잘리는 글은 없다 - 끝까지 안 맞으면 표시하고 멈춘다.
FIT_JS = """
<script>
// 문구에 적은 줄(<br>)보다 더 쪼개지면 "Rispondi / con un / tocco" 처럼 읽기가 끊긴다.
// 적은 줄 수를 지킬 때까지 줄인다.
function lines(el) {
  return Math.round(el.getBoundingClientRect().height / parseFloat(getComputedStyle(el).lineHeight));
}
function fit(box, el, max, min) {
  const want = el.querySelectorAll('br').length + 1;
  let size = max;
  el.style.fontSize = size + 'px';
  while (size > min && (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 ||
         lines(el) > want)) {
    size -= 4; el.style.fontSize = size + 'px';
  }
  if (box.scrollHeight > box.clientHeight + 1 || box.scrollWidth > box.clientWidth + 1 || lines(el) > want)
    document.body.dataset.overflow = '1';
}
document.fonts.ready.then(() => {
  const box = document.querySelector('.text');
  const h = document.querySelector('.headline');
  fit(box, h, +h.dataset.max, +h.dataset.min);
  document.body.dataset.done = '1';
});
</script>
"""


def phone(img, left, top, width, rotate=0):
    return (f'<div class="phone" style="left:{left}px;top:{top}px;width:{width}px;'
            f'transform:rotate({rotate}deg)"><img src="{img}"></div>')


def icon(left, top, size, rotate=0):
    return (f'<img class="icon" src="{ICON.as_uri()}" style="left:{left}px;top:{top}px;width:{size}px;'
            f'height:{size}px;transform:rotate({rotate}deg)">')


def widget(left, top, size, time, progress, color, rotate=0):
    deg = int(progress * 360)
    # 여백은 px 로 준다. % 로 주면 상자가 아니라 페이지 폭을 기준으로 잡혀 고리가 두꺼워진다.
    return (f'<div class="widget" style="left:{left}px;top:{top}px;width:{size}px;height:{size}px;padding:{int(size * 0.07)}px;'
            f'background:conic-gradient({color} 0 {deg}deg, #e5e5ea {deg}deg 360deg);transform:rotate({rotate}deg)">'
            f'<div class="face" style="font-size:{int(size * 0.24)}px">{time}</div></div>')


def search_html(lang):
    W, H, (l, t, r, b) = SPEC["search"]
    eyebrow, headline, sub = SEARCH[lang]
    sw, sh = r - l, b - t
    col = int(sw * 0.56)
    ph_w = 1040
    ph_left = l + col + int(sw * 0.04)
    if lang in DEVICE_LANGS:
        # 연결된 리모컨의 첫 화면: 남은 시간, 시작/일시정지, 30초 더하기·빼기, 위젯 옮기기 판.
        art = phone((RAW / lang / "01-timer.png").as_uri(), ph_left, t - 360, ph_w, 0)
    else:
        art = (widget(ph_left + 40, t - 120, 900, "08:42", 0.58, "#ff9f0a", 4)
               + icon(ph_left + 620, t + 640, 560, -8))
    return f"""
<div class="glow" style="left:{ph_left - 300}px;top:400px;width:1700px;height:1700px;background:rgba(255,159,10,.22)"></div>
<div class="glow" style="left:{l - 700}px;top:{t - 500}px;width:1400px;height:1000px;background:rgba(255,219,84,.18)"></div>
{art}
<div class="text" style="left:{l}px;top:{t}px;width:{col}px;height:{sh}px">
  <div class="eyebrow" style="font-size:96px">{eyebrow}</div>
  <div class="headline" data-max="250" data-min="140" style="margin-top:36px">{headline}</div>
  <div class="sub" style="font-size:84px;margin-top:52px">{sub}</div>
</div>"""


def header_html(lang):
    W, H, (l, t, r, b) = SPEC["header"]
    eyebrow, headline = HEADER[lang]
    sw, sh = r - l, b - t
    # 안전 영역 바깥에 흩는 점은 아이폰에서 잘려도 되는 장식이다.
    dots = [(120, 120, 120), (880, 1380, 90), (3480, 160, 110), (3700, 1300, 140), (2860, 80, 70)]
    dots_html = "".join(f'<div class="dot" style="left:{x}px;top:{y}px;width:{d}px;height:{d}px"></div>'
                        for x, y, d in dots)
    if lang in DEVICE_LANGS:
        # 왼쪽은 발표용 15분 타이머, 오른쪽은 뽀모도로 - 둘 다 실제 리모컨 화면이다.
        art = (phone((RAW / lang / "01-timer.png").as_uri(), 300, 360, 640, -9)
               + phone((RAW / lang / "02-pomodoro.png").as_uri(), 2900, 360, 640, 9))
    else:
        art = (icon(330, 470, 640, -10)
               + widget(2880, 400, 700, "08:42", 0.58, "#ff9f0a", 8))
    return f"""
<div class="glow" style="left:{l - 200}px;top:{t - 400}px;width:{sw + 400}px;height:{sh + 800}px;background:rgba(255,191,64,.20)"></div>
{dots_html}
{art}
<div class="text" style="left:{l}px;top:{t}px;width:{sw}px;height:{sh}px;align-items:center;text-align:center">
  <div class="eyebrow" style="font-size:76px">{eyebrow}</div>
  <div class="headline" data-max="210" data-min="110" style="margin-top:22px">{headline}</div>
</div>"""


def html_lang(lang):
    return {"zh-Hans": "zh-Hans", "zh-Hant": "zh-Hant"}.get(lang, lang)


def render(lang, kind):
    W, H, _ = SPEC[kind]
    body = search_html(lang) if kind == "search" else header_html(lang)
    page = (f'<!doctype html><html lang="{html_lang(lang)}"><head><meta charset="utf-8"><style>'
            f'{BASE_CSS % {"W": W, "H": H}}</style></head><body>{body}{FIT_JS}</body></html>')
    html_path = pathlib.Path(tempfile.gettempdir()) / f"sp-remote-creative-{lang}-{kind}.html"
    html_path.write_text(page, encoding="utf-8")
    # 글이 끝까지 안 맞으면 그림을 만들지 않는다(잘린 글이 스토어에 올라가는 것보다 낫다).
    dom = subprocess.run([CHROME, "--headless=new", "--dump-dom", f"--window-size={W},{H}",
                          "--force-device-scale-factor=1", "--disable-gpu", "--virtual-time-budget=3000",
                          html_path.as_uri()], capture_output=True, text=True, timeout=90).stdout
    if 'data-done="1"' not in dom:
        raise SystemExit(f"글 맞추기가 끝나지 않았다: {lang} {kind}")
    if 'data-overflow="1"' in dom:
        raise SystemExit(f"글이 안전 영역을 넘는다: {lang} {kind} - 문구를 줄일 것")
    out_dir = OUT / STORE.get(lang, lang)
    out_dir.mkdir(parents=True, exist_ok=True)
    out_png = out_dir / f"{kind}.png"
    # ⚠️ Chrome 은 가끔 아무것도 안 그리고 끝나거나 멈춘다. 세 번까지 한다.
    for _ in range(3):
        try:
            r = subprocess.run([CHROME, "--headless=new", f"--screenshot={out_png}",
                                f"--window-size={W},{H}", "--force-device-scale-factor=1",
                                "--hide-scrollbars", "--disable-gpu", "--virtual-time-budget=3000",
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
    langs = sys.argv[1:] or list(SEARCH)
    for lang in langs:
        if lang not in SEARCH:
            raise SystemExit(f"모르는 언어: {lang} (아는 것: {', '.join(SEARCH)})")
        for kind in ("header", "search"):
            render(lang, kind)
