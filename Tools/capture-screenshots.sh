#!/bin/bash
# 언어마다 앱을 스크린샷 무대(Debug 의 ScreenshotStage.swift)로 띄워 창 그림을 받는다.
#
#   bash Tools/capture-screenshots.sh <StickyPresenter.app(Debug)> <로케일...>
#
# 결과: docs/screenshots/raw/<로케일>_{guide,note,panel,pomo,widget,prompter,menu}.png
# 그다음 합성: swift Tools/MakeScreenshots.swift docs/screenshots/raw docs/screenshots/marketing <로케일...>
#
# 앱은 샌드박스라 파일로 주고받지 않는다 — 데모 글은 실행 인자로 넣고, 창 그림은 앱이 직접 그려
# 표준 출력(base64)으로 보낸다. 메뉴 막대 메뉴만 screencapture 로 찍는다(15초 제한).
# 모든 대기는 시간 제한이 있다. 한 번에 앱 하나만 띄운다.
set -uo pipefail
cd "$(dirname "$0")/.."
APP="$1"; shift
RAW="docs/screenshots/raw"
mkdir -p "$RAW"
TMPBASE="$(mktemp -d -t spshots)"
FINDER="$TMPBASE/findmenu"
swiftc -O Tools/FindMenuWindow.swift -o "$FINDER" || exit 1
limit() { local s="$1"; shift; perl -e 'alarm shift; exec @ARGV' "$s" "$@"; }

wait_line() {  # 로그 · 찾을 글 · 최대 초
  local f="$1" pat="$2" max="$3" i=0
  while ! grep -q "$pat" "$f" 2>/dev/null && [ $i -lt $max ]; do sleep 1; i=$((i+1)); done
  grep -q "$pat" "$f" 2>/dev/null
}
demo() { /usr/bin/python3 -c "import json,sys;d=json.load(open('Tools/screenshot-demo.json'));l=sys.argv[1];print((d.get(l) or d.get(l.split('-')[0]) or d['en'])[sys.argv[2]],end='')" "$1" "$2"; }

for loc in "$@"; do
  log="$TMPBASE/$loc.log"
  case "$loc" in zh-Hans) applocale=zh_CN;; zh-Hant) applocale=zh_TW;; ko) applocale=ko_KR;; ja) applocale=ja_JP;;
    en-US) applocale=en_US;; en-GB) applocale=en_GB;; de) applocale=de_DE;; fr) applocale=fr_FR;; es) applocale=es_ES;;
    it) applocale=it_IT;; pt-BR) applocale=pt_BR;; ru) applocale=ru_RU;; th) applocale=th_TH;; vi) applocale=vi_VN;;
    cs) applocale=cs_CZ;; da) applocale=da_DK;; el) applocale=el_GR;; fi) applocale=fi_FI;; id) applocale=id_ID;;
    nb) applocale=nb_NO;; nl) applocale=nl_NL;; pl) applocale=pl_PL;; sv) applocale=sv_SE;; tr) applocale=tr_TR;;
    *) applocale="$(echo "$loc" | tr '-' '_')";; esac
  lang="$loc"; [ "$loc" = "en-US" ] && lang="en"
  perl -e 'alarm shift; exec @ARGV' 120 "$APP/Contents/MacOS/StickyPresenter" -SPScreenshotStage YES \
     -SPDemoChecklist "$(demo "$loc" checklist)" -SPDemoScript "$(demo "$loc" script)" \
     -AppleLanguages "($lang)" -AppleLocale "$applocale" > "$log" 2>/dev/null &
  pid=$!
  if wait_line "$log" "SPSHOT windows done" 90; then
    /usr/bin/python3 - "$log" "$RAW" "$loc" <<'PY'
import sys,base64
log,raw,loc=sys.argv[1:4]
for line in open(log):
    if line.startswith('SPSHOT png '):
        _,_,key,b64=line.strip().split(' ',3)
        open(f'{raw}/{loc}_{key}.png','wb').write(base64.b64decode(b64))
PY
    if wait_line "$log" "SPSHOT menu" 20; then
      sleep 3
      if mid="$(limit 10 "$FINDER" "$pid")"; then limit 25 screencapture -x -o -l "$mid" "$RAW/${loc}_menu.png" || echo "⚠️ $loc 메뉴 캡처 실패"; else echo "⚠️ $loc 메뉴 못 찾음"; fi
    fi
  else
    echo "⚠️ $loc 무대가 뜨지 않음"
  fi
  i=0; while kill -0 $pid 2>/dev/null && [ $i -lt 20 ]; do sleep 1; i=$((i+1)); done
  kill $pid 2>/dev/null
  echo "✅ $loc"
done
rm -rf "$TMPBASE"
